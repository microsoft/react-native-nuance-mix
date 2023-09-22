//
//  AudioPlayer.m
//  AigwSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayer.h"
#import "AudioAdditions.h"
#import "TPCircularBuffer.h"

typedef NS_ENUM(NSInteger, AudioQueueState) {
    AudioQueueStateEmpty,
    AudioQueueStateHasData
};

@interface AudioStruct : NSObject

@property (atomic, readonly) NSData *audio;
@property (atomic, readonly) BOOL isFinal;
- (id)initWithData:(NSData*)audio isFinal:(BOOL)isFinal;

@end

@implementation AudioStruct

- (id)initWithData:(NSData*)audio isFinal:(BOOL)isFinal
{
    if (self = [super init]) {
        _audio = audio;
        _isFinal = isFinal;
    }
    return self;
}

@end

@interface AudioPlayer ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) AUGraph graph;
@property (nonatomic, assign) AudioUnit player;
@property (nonatomic, assign) AudioStreamBasicDescription ioFormat;
@property (nonatomic, assign) AudioStreamBasicDescription fileFormat;
@property (nonatomic, assign) AudioFileID audioFile;
@property (nonatomic, strong) NSString *oldCategory;
@property NSMutableArray* audioQueue;
@property (readonly) NSConditionLock* audioQueueCondLock;
@property (assign, readwrite) BOOL isPlaying;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) float graphSampleRate;

- (void) enqueue:(AudioStruct *)audio;
- (AudioStruct *)dequeue;

@end

OSStatus AudioPlayerCallback(void                        *inRefCon,
                             AudioUnitRenderActionFlags  *ioActionFlags,
                             const AudioTimeStamp        *inTimeStamp,
                             UInt32                      inBusNumber,
                             UInt32                      inNumberFrames,
                             AudioBufferList             *ioData)
{
    /**
     This is the reference to the object who owns the callback.
     */
    AudioPlayer *player = (__bridge AudioPlayer *) inRefCon;

    // iterate over incoming stream and copy to output stream
    for (int i=0; i < ioData->mNumberBuffers; i++) {
        
        AudioBuffer buffer = ioData->mBuffers[i];
        uint8_t *p = buffer.mData;
        int bytesRequired = buffer.mDataByteSize;
        while (bytesRequired > 0) {
            [[player audioQueueCondLock] lock];
            NSUInteger count = [[player audioQueue] count];
            [[player audioQueueCondLock] unlock];

//            NSLog(@"playing %d", count);
            if (count > 0 && [player isPlaying]) {
                
                // dequeue audio from audio player's queue
                AudioStruct *audioBuffer = [player dequeue];
                
                // copy buffer to audio buffer which gets played after function return
                UInt32 size = (int)[[audioBuffer audio] length];
                memcpy(p, [[audioBuffer audio] bytes], size);
                p += size;
                bytesRequired -= size;
            }
            else {
                // if this is the last audio packet notify delegate that processing of audio stream is complete
                if ([[player delegate] respondsToSelector:@selector(onAudioStreamingFinished)]) {
                    [[player delegate] onAudioStreamingFinished];
                }
                // Either there's no audio to play, or the player has been requested to stop playing
                return AVErrorOperationInterrupted;
            }
        }
    }
    
    return noErr;
}

@implementation AudioPlayer

@synthesize isPlaying = _isPlaying;
@synthesize isPaused = _isPaused;
@synthesize delegate = _delegate;
@synthesize audioQueue = _audioQueue;
@synthesize audioQueueCondLock = _audioQueueCondLock;

- (void)dealloc
{
    if (_graph) {
        AUGraphUninitialize(_graph);
        AUGraphClearConnections(_graph);
        AUGraphClose(_graph);
        DisposeAUGraph(_graph);
        _graph = nil;
    }

    if (_audioQueue) {
        [_audioQueue removeAllObjects];
        _audioQueue = nil;
    }
    _player = nil;
    _dispatchQueue = nil;
}

- (void)initialize
{
    [self initWithDelegate: _delegate];
}

- (id)initWithDelegate:(id<AudioPlayerDelegate>)delegate
{
    return [self initWithURL:nil withDelegate:delegate];
}

- (id)initWithURL:(NSURL *)url withDelegate:(id<AudioPlayerDelegate>)delegate
{
    if (self = [super init]) {
        self.url = url;
        
        _audioQueue = [[NSMutableArray alloc] init];
        _audioQueueCondLock = [[NSConditionLock alloc] initWithCondition:AudioQueueStateEmpty];
        _isPlaying = NO;
        _isPaused = NO;
        _delegate = delegate;
        
        self.dispatchQueue = dispatch_queue_create("AudioPlayerQueue", DISPATCH_QUEUE_SERIAL);
//        dispatch_set_target_queue(self.dispatchQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

        if (noErr != [self prepareGraph])
            return nil;
    }
    return self;
}

- (OSStatus)prepareGraph
{
    OSStatus status = 0;
    NSError* error;
    
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                          withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                                error:&error]) {
        goto error;
    }
    
    /* Prepare graph */
    AACheckStatus(NewAUGraph(&_graph),
                  error);
    
    AudioComponentDescription playerDescription = {
        .componentType          = kAudioUnitType_Output,
        .componentSubType       = kAudioUnitSubType_RemoteIO,
        .componentManufacturer  = kAudioUnitManufacturer_Apple,
    };
    
    AUNode playerNode;
    AACheckStatus(AUGraphAddNode(_graph, &playerDescription, &playerNode),
                  error);
    
    AACheckStatus(AUGraphOpen(_graph), error);
    
    AACheckStatus(AUGraphNodeInfo(_graph, playerNode, NULL, &_player),
                  error);
    
    /* Prepare RemoteIO */
    _ioFormat.mSampleRate       = SAMPLE_RATE;
    _ioFormat.mFormatID         = kAudioFormatLinearPCM;
    _ioFormat.mFormatFlags      = kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    _ioFormat.mBytesPerPacket   = BYTES_PER_SAMPLE * CHANNELS;
    _ioFormat.mFramesPerPacket  = 1;
    _ioFormat.mBytesPerFrame    = BYTES_PER_SAMPLE * CHANNELS;
    _ioFormat.mChannelsPerFrame = 1;
    _ioFormat.mBitsPerChannel   = BYTES_PER_SAMPLE * 8;
    
    
    AACheckStatus(AudioUnitSetProperty(_player,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       kAudioUnitRemoteIO_OutputBus,
                                       &_ioFormat,
                                       sizeof(_ioFormat)),
                  error);
    
    AURenderCallbackStruct playerCallbackStruct = {
        .inputProc          = AudioPlayerCallback,
        .inputProcRefCon    = (__bridge void * _Nullable)(self),
    };
    
    AACheckStatus(AudioUnitSetProperty(_player,
                                       kAudioUnitProperty_SetRenderCallback,
                                       kAudioUnitScope_Global,
                                       kAudioUnitRemoteIO_OutputBus,
                                       &playerCallbackStruct,
                                       sizeof(playerCallbackStruct)),
                  error);
    
    AACheckStatus(AUGraphInitialize(_graph), error);
    
    AADebugAudioRoute();
    
    if ([_delegate respondsToSelector:@selector(onPlayerStarted)])
        [_delegate onPlayerStarted];
    
    NSLog(@"Audio Graph Initialized");
    return noErr;
    
error:
    return status;
}

- (void)startGraph
{
    NSLog(@"In startGraph: isPlaying = %d", _isPlaying);
    if (!_isPlaying) {
        _isPlaying = YES;
        
        OSStatus status = 0;
        
        AADebugAudioRoute();
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        _oldCategory = [[AVAudioSession sharedInstance] category];
        if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                              withOptions:AUDIO_CATEGORY
                                                    error:nil]) {
            goto error;
        }
        
        if (![[AVAudioSession sharedInstance] setActive:YES error:nil]) {
            goto error;
        }
        
        AACheckStatus(AUGraphStart(_graph), error);
        
        AADebugAudioRoute();
        
    error:
        if (status) {
            _isPlaying = NO;
            NSLog(@"Starting Audio Graph Failed");
            if ([_delegate respondsToSelector:@selector(onPlayerError)])
                [_delegate onPlayerError];
        }
        
        NSLog(@"Audio Graph Started");
        
        if ([_delegate respondsToSelector:@selector(onPlayerStarted)])
            [_delegate onPlayerStarted];
    }
}

- (void)stopGraph
{
    NSLog(@"In stopGraph: isPlaying = %d", _isPlaying);
    
    if (_isPlaying) {
        _isPlaying = NO;
        AUGraphStop(_graph);
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
        [[AVAudioSession sharedInstance] setCategory:_oldCategory error:nil];
        
        if ([_delegate respondsToSelector:@selector(onPlayerStopped)])
            [_delegate onPlayerStopped];
        
        NSLog(@"Audio playback Graph Stopped");
    }
}

- (void)play
{
    [self startGraph];
}

- (void)pause
{
    NSLog(@"In pause: isPlaying = %d", _isPlaying);
    [self stopGraph];
    _isPaused = YES;
}

- (void)resume
{
    [self startGraph];
    _isPaused = NO;
}

- (void)stopPlayingImmediately
{
    [self stopGraph];
    [_audioQueueCondLock lock];
    [_audioQueue removeAllObjects];
    [_audioQueueCondLock unlockWithCondition:AudioQueueStateEmpty];
}

- (void)enqueue:(AudioStruct *)audio
{
    [_audioQueueCondLock lock];
    [_audioQueue addObject:audio];
    [_audioQueueCondLock unlockWithCondition:AudioQueueStateHasData];
    
}

- (AudioStruct *)dequeue
{
    AudioStruct *audio = nil;
    
    [_audioQueueCondLock lock];
    if ([_audioQueue count] > 0) {
        audio = [_audioQueue firstObject];
        [_audioQueue removeObjectAtIndex:0];
    }
    [_audioQueueCondLock unlockWithCondition:[_audioQueue count] > 0 ? AudioQueueStateHasData : AudioQueueStateEmpty];
    
    return audio;
}

- (void)enqueueAudio:(NSData *)audio
{
    if ([_delegate respondsToSelector:@selector(onAudioStreamingStarted)])
        [_delegate onAudioStreamingStarted];

    NSLog(@"enqueuing audio %lu", [audio length]);
    dispatch_async(self.dispatchQueue, ^{
        UInt32 length = (int)[audio length];
        UInt32 consumed = 0;
        char *buffer = (char *)[audio bytes];
        
        while (consumed < length) {
            NSData *frame = [[NSData alloc] initWithBytes:buffer+consumed length:BYTES_PER_SAMPLE];
            consumed += BYTES_PER_SAMPLE;
            [self enqueue:[[AudioStruct alloc] initWithData:frame isFinal:NO]];
        }
        [self enqueue:[[AudioStruct alloc] initWithData:nil isFinal:YES]];
    });
}

- (void)cancel
{
    AUGraphStop(_graph);

    if (_audioQueue ) {
        [_audioQueueCondLock lockWhenCondition:AudioQueueStateHasData];
        while ([_audioQueue count] > 0 && ![ (AudioStruct *)[_audioQueue firstObject] isFinal]) {
            [_audioQueue removeObjectAtIndex:0];
            continue;
        }
        [_audioQueueCondLock unlockWithCondition:[_audioQueue count] > 0 ? AudioQueueStateHasData : AudioQueueStateEmpty];
    }
}

@end

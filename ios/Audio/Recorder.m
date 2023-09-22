//
//  Recorder.m
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "Recorder.h"
#import "AudioAdditions.h"
#import "Defines.h"
#import "TPCircularBuffer.h"


typedef struct RecorderStruct {
    AudioUnit recorder;
    AudioStreamBasicDescription format;
    TPCircularBuffer *buffer;
    UInt32 frameDelay;
} RecorderStruct;


dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}


OSStatus RecorderCallback(void                        *inRefCon,
                               AudioUnitRenderActionFlags  *ioActionFlags,
                               const AudioTimeStamp        *inTimeStamp,
                               UInt32                      inBusNumber,
                               UInt32                      inNumberFrames,
                               AudioBufferList             *ioData)
{
    OSStatus status;
    int32_t bytes;
    UInt32 validFrames = 0;
    
    RecorderStruct *audio = (RecorderStruct *) inRefCon;
    
    if (audio->frameDelay >= inNumberFrames) {
        audio->frameDelay -= inNumberFrames;
        return noErr;
    } else if (audio->frameDelay > 0) {
        validFrames = inNumberFrames - audio->frameDelay;
        audio->frameDelay = 0;
    }
    
    void *buffer = TPCircularBufferHead(audio->buffer, &bytes);
    if (inNumberFrames * audio->format.mBytesPerFrame > bytes) {
        NSLog(@"Audio unit buffer overflow");
        status = -1;
        goto error;
    }
    
    AudioBufferList data = {
        .mNumberBuffers = 1,
        .mBuffers = {{
            .mNumberChannels = audio->format.mChannelsPerFrame,
            .mDataByteSize = inNumberFrames * audio->format.mBytesPerFrame,
            .mData = buffer
        }}
    };
    
    AACheckStatus(AudioUnitRender(audio->recorder,
                                  ioActionFlags,
                                  inTimeStamp,
                                  inBusNumber,
                                  inNumberFrames,
                                  &data),
                  error);
    
    bytes = data.mBuffers[0].mDataByteSize;
    
    if (validFrames) {
        int32_t size = validFrames * audio->format.mBytesPerFrame;
        memmove(buffer, buffer+bytes-size, size);
        bytes = size;
    }
    
    TPCircularBufferProduce(audio->buffer, bytes);
    return noErr;
    
error:
    return status;
}


@interface Recorder ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) AUGraph graph;
@property (nonatomic, assign) AudioUnit recorder;
@property (nonatomic, assign) AudioUnit player;
@property (nonatomic, assign) AudioStreamBasicDescription ioFormat;
@property (nonatomic, assign) AudioStreamBasicDescription fileFormat;
@property (nonatomic, assign) AudioFileID audioFile;
@property (nonatomic, assign) UInt32 audioFrames;
@property (nonatomic, assign) RecorderStruct *audio;
@property (nonatomic, strong) NSString *oldCategory;
@property (nonatomic, assign) TPCircularBuffer *buffer;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_source_t timer;
@property (weak, nonatomic, readonly) id<RecorderDelegate> delegate;

@property (atomic, assign, readwrite) BOOL isRecording;

@end


@implementation Recorder

- (void)dealloc
{
    if (_graph) {
        AUGraphUninitialize(_graph);
        AUGraphClearConnections(_graph);
        AUGraphClose(_graph);
        DisposeAUGraph(_graph);
        _graph = nil;
    }
    
    if (_buffer) {
        TPCircularBufferCleanup(_buffer);
        free(_buffer);
    }
    
    free(_audio);
    
    _player = nil;
    _queue = nil;
    _timer = nil;
}

- (id)initWithURL:(NSURL *)url
{
    if (self = [super init]) {
        self.url = url;
        
        _buffer = malloc(sizeof(*_buffer));
        TPCircularBufferInit(_buffer, 2 * SAMPLE_RATE * BYTES_PER_SAMPLE);
        _audio = malloc(sizeof(*_audio));
        
        self.isRecording = NO;
        self.queue = dispatch_queue_create("RecorderQueue", DISPATCH_QUEUE_SERIAL);
        
        if (noErr != [self prepareGraph])
            return nil;

    }
    return self;
}

- (OSStatus)prepareGraph
{
    OSStatus status = 0;
    NSError* error;
    UInt32 propSize;
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];

    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                          withOptions:AUDIO_CATEGORY
                                                error:&error]) {
        goto error;
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    /* Prepare graph */
    AACheckStatus(NewAUGraph(&_graph),
                  error);
    
    AudioComponentDescription playerDescription = {
        .componentType          = kAudioUnitType_Generator,
        .componentSubType       = kAudioUnitSubType_AudioFilePlayer,
        .componentManufacturer  = kAudioUnitManufacturer_Apple,
    };
    
    AudioComponentDescription ioDescription = {
        .componentType          = kAudioUnitType_Output,
        .componentSubType       = kAudioUnitSubType_RemoteIO,
        .componentManufacturer  = kAudioUnitManufacturer_Apple,
    };
    
    AUNode playerNode;
    AACheckStatus(AUGraphAddNode(_graph, &playerDescription, &playerNode),
                  error);
    
    AUNode ioNode;
    AACheckStatus(AUGraphAddNode(_graph, &ioDescription, &ioNode),
                  error);
    
    AACheckStatus(AUGraphOpen(_graph), error);
    
    AACheckStatus(AUGraphNodeInfo(_graph, playerNode, NULL, &_player),
                  error);
    
    AACheckStatus(AUGraphNodeInfo(_graph, ioNode, NULL, &_recorder),
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
    
    AACheckStatus(AudioUnitSetProperty(_recorder,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Output,
                                       kAudioUnitRemoteIO_InputBus,
                                       &_ioFormat,
                                       sizeof(_ioFormat)),
                  error);
    
    AACheckStatus(AudioUnitSetProperty(_recorder,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       kAudioUnitRemoteIO_OutputBus,
                                       &_ioFormat,
                                       sizeof(_ioFormat)),
                  error);
    
    AACheckStatus(AudioUnitSetProperty(_recorder,
                                       kAudioOutputUnitProperty_EnableIO,
                                       kAudioUnitScope_Output,
                                       kAudioUnitRemoteIO_OutputBus,
                                       &kAudioUnitProperty_Enabled,
                                       sizeof(kAudioUnitProperty_Enabled)),
                  error);
    
    AACheckStatus(AudioUnitSetProperty(_recorder,
                                       kAudioOutputUnitProperty_EnableIO,
                                       kAudioUnitScope_Input,
                                       kAudioUnitRemoteIO_InputBus,
                                       &kAudioUnitProperty_Enabled,
                                       sizeof(kAudioUnitProperty_Enabled)),
                  error);
    
    AURenderCallbackStruct recorderCallbackStruct = {
        .inputProc          = RecorderCallback,
        .inputProcRefCon    = _audio,
    };
    
    AACheckStatus(AudioUnitSetProperty(_recorder,
                                       kAudioOutputUnitProperty_SetInputCallback,
                                       kAudioUnitScope_Global,
                                       kAudioUnitRemoteIO_InputBus,
                                       &recorderCallbackStruct,
                                       sizeof(recorderCallbackStruct)),
                  error);
    
    // Only set up a player node if audio has been specified for a start recording earcon
    if (self.url) {
        NSLog(@"Audio File URL: %@", self.url);
        AACheckStatus(AudioFileOpenURL((__bridge CFURLRef) self.url,
                                       kAudioFileReadPermission,
                                       0,
                                       &_audioFile),
                      error);
        
        propSize = sizeof(_fileFormat);
        AACheckStatus(AudioFileGetProperty(_audioFile,
                                           kAudioFilePropertyDataFormat,
                                           &propSize,
                                           &_fileFormat),
                      error);
        
        UInt64 packets;
        propSize = sizeof(packets);
        AACheckStatus(AudioFileGetProperty(_audioFile,
                                           kAudioFilePropertyAudioDataPacketCount,
                                           &propSize,
                                           &packets),
                      error);
        
        AACheckStatus(AUGraphConnectNodeInput(_graph, playerNode, 0, ioNode, kAudioUnitRemoteIO_OutputBus),
                      error);
      
        _audioFrames = (UInt32) packets * _fileFormat.mFramesPerPacket;
    }
    
    AACheckStatus(AUGraphInitialize(_graph), error);
    
    AADebugAudioRoute();
    
    _audio->recorder = _recorder;
    _audio->format = _ioFormat;
    _audio->buffer = _buffer;
    
    return noErr;
    
error:
    return status;
}

- (OSStatus)startGraph
{
    if (!_isRecording) {
        _isRecording = YES;
        
        OSStatus status;
        
        AADebugAudioRoute();
        
        _oldCategory = [[AVAudioSession sharedInstance] category];
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];

        if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                              withOptions:AUDIO_CATEGORY
                                                    error:nil]) {
            goto error;
        }
        
        if (![[AVAudioSession sharedInstance] setActive:YES error:nil]) {
            goto error;
        }
        
        // Play a recording started earcon if one was specified during initialization
        if (self.url) {
            AACheckStatus(AudioUnitSetProperty(_player,
                                               kAudioUnitProperty_ScheduledFileIDs,
                                               kAudioUnitScope_Global,
                                               0,
                                               &_audioFile,
                                               sizeof(_audioFile)),
                          error);
            
            AudioTimeStamp startTime = {
                .mFlags = kAudioTimeStampSampleTimeValid,
                .mSampleTime = -1
            };
            
            AACheckStatus(AudioUnitSetProperty(_player,
                                               kAudioUnitProperty_ScheduleStartTimeStamp,
                                               kAudioUnitScope_Global,
                                               0,
                                               &startTime,
                                               sizeof(startTime)),
                          error);
            
            ScheduledAudioFileRegion region = {
                .mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid,
                .mTimeStamp.mSampleTime = 0,
                .mCompletionProc = NULL,
                .mCompletionProcUserData = NULL,
                .mAudioFile = _audioFile,
                .mLoopCount = 0,
                .mStartFrame = 0,
                .mFramesToPlay = _audioFrames
            };
            
            AACheckStatus(AudioUnitSetProperty(_player,
                                               kAudioUnitProperty_ScheduledFileRegion,
                                               kAudioUnitScope_Global,
                                               0,
                                               &region,
                                               sizeof(region)),
                          error);
            
        }
        
        TPCircularBufferClear(_buffer);
        _audio->frameDelay = _audioFrames * _ioFormat.mSampleRate / _fileFormat.mSampleRate;
        
        AACheckStatus(AUGraphStart(_graph), error);
        
        AADebugAudioRoute();
        
    error:
        if (status) {
            _isRecording = NO;
            NSLog(@"Starting Audio Graph Failed");
            if ([_delegate respondsToSelector:@selector(onRecorderError)])
                [_delegate onRecorderError];
            
            return status;
        }

        NSLog(@"Audio Graph Started");
        if ([_delegate respondsToSelector:@selector(onRecorderStarted)])
            [_delegate onRecorderStarted];

        return noErr;
    }
    
    return AVErrorRecordingAlreadyInProgress;
}

- (void)stopGraph
{
    if (_isRecording) {
        _isRecording = NO;
        AUGraphStop(_graph);
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
        [[AVAudioSession sharedInstance] setCategory:_oldCategory error:nil];
        
        if ([_delegate respondsToSelector:@selector(onRecorderStopped)])
            [_delegate onRecorderStopped];
        
        NSLog(@"Audio recorder Graph Stopped");
    }
   
}

- (void)recordWithDelegate:(id<RecorderDelegate>)delegate
{
    _delegate = delegate;
    
    [self recordWithInterval:.02 * NSEC_PER_SEC];
}

- (OSStatus)recordWithInterval:(uint64_t)interval
{
    OSStatus status = [self startGraph];
    if (status == noErr)
    {
        self.timer = CreateDispatchTimer(interval, interval, self.queue, ^{
            int32_t size;
            void *buffer = TPCircularBufferTail(self.buffer, &size);
            if ([_delegate respondsToSelector:@selector(onAudio:final:)]) {
                NSData *packet = [[NSData alloc] initWithBytesNoCopy:buffer length:size freeWhenDone:NO];
                [_delegate onAudio:packet final:!self.isRecording];
            }
            TPCircularBufferConsume(self.buffer, size);
            
            if (!self.isRecording) {
                dispatch_source_cancel(self.timer);
            }
        });
    }
    return status;
    
}

- (void)cancel
{
    [self stopGraph];
}

@end

//
//  AudioRecorder.m
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//
#import "AudioRecorder.h"

#define INSAMPLESIZE 2

@interface AudioRecorder () <AudioRecorderDelegate>

- (OpusVAD *)initVAD;
- (void)releaseVAD;

@property (nonatomic, strong) Recorder *recorder;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign) UInt32 frameSize;
@property (nonatomic, assign) UInt32 frameBytes;
@property (nonatomic, assign) UInt32 maxPacketSize;
@property (nonatomic, assign) TPCircularBuffer *buffer;

@property (nonatomic, assign) OpusVAD *vad;
@property (nonatomic, assign) UInt32 vadFrameSize;
@property (nonatomic, assign) void *overflowBuffer;
@property (nonatomic, assign) UInt32 overflowSize;


@property BOOL stopOnEndOfSpeech;
@end


@implementation AudioRecorder

@synthesize delegate = _delegate;

#pragma mark - Constants

/** The Constant MAX_16_BITS_SIGNED. Used in the algorithm to detect audio energy level. */
static float MAX_16_BITS_SIGNED = 32768;

#pragma mark - Public Methods
- (void)initialize
{
    [self initWithURL:nil withDelegate: _delegate];
}

void onSos(const void * ctx, unsigned int pos) {
    AudioRecorder *p = (__bridge AudioRecorder *)ctx;
    NSLog(@"Found SOS %ul", pos);
    [p->_delegate onStartOfSpeechDetected];
}

void onEos(const void * ctx, unsigned int pos) {
    AudioRecorder *p = (__bridge AudioRecorder *)ctx;
    [p->_delegate onEndOfSpeechDetected];

}

- (id)initWithURL:(NSURL *)url withDelegate:(id<AudioRecorderDelegate>)delegate
{
    if (self = [super init]) {
        int error;
                
        self.recorder = [[Recorder alloc] initWithURL:url];
        /* 20ms segments */
        self.frameSize = 20 * SAMPLE_RATE / 1000;
        self.frameBytes = BYTES_PER_SAMPLE * self.frameSize;
        self.maxPacketSize = 1024;
        OpusVADOptions opts;
        opts.bit_rate_type = 1;
        opts.complexity = 3;
        opts.ctx = (__bridge void *)self;
        opts.sos = 180;
        opts.eos = 600;
        opts.speech_detection_sensitivity = 20;
        opts.onSOS = onSos;
        opts.onEOS = onEos;

        self.vad = opusvad_create(&error, &opts);
        if (error != OPUSVAD_OK)
        {
            NSLog(@"Error with opusvad_create: %d\n", error);
            return nil;
        }
        self.vadFrameSize = opusvad_get_frame_size(self.vad);

        NSLog(@"frameSize: %d, vadFrameSize: %d", (unsigned int)self.frameSize, (unsigned int)self.vadFrameSize);
        self.overflowBuffer = nil;
        self.overflowSize = 0;
        
        self.buffer = malloc(sizeof(*self.buffer));
        TPCircularBufferInit(self.buffer, 64 * 1024 * 1024);
        
        self.queue = dispatch_queue_create("VoiceRecorder", DISPATCH_QUEUE_SERIAL);
//        dispatch_set_target_queue(self.queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

        _delegate = delegate;

    }
    return self;
}

- (void)start {
    [self start:TRUE];
}

- (void)start:(BOOL)stopOnEndOfSpeech {

    _stopOnEndOfSpeech = stopOnEndOfSpeech;
    
    if (_vad == nil)
        _vad = [self initVAD];
  
    [self.recorder recordWithDelegate:(id<RecorderDelegate>)self];
}

- (void)stop {
    [self.recorder cancel];
}

#pragma mark - Private Methods

- (OpusVAD *)initVAD {
    if (_vad == nil) {
        int error;
        OpusVADOptions opts;
        opts.bit_rate_type = 1;
        opts.complexity = 3;
        opts.ctx = (__bridge void *)self;
        opts.sos = 180;
        opts.eos = 600;
        opts.speech_detection_sensitivity = 20;
        opts.onSOS = onSos;
        opts.onEOS = onEos;

        _vad = opusvad_create(&error, &opts);
        if (error != OPUSVAD_OK)
        {
            NSLog(@"Error with opusvad_create: %d\n", error);
            return nil;
        }
    }
    _vadFrameSize = opusvad_get_frame_size(_vad);
    
    NSLog(@"frameSize: %d, vadFrameSize: %d", (unsigned int)_frameSize, (unsigned int)_vadFrameSize);
    
    return _vad;
}

- (void)releaseVAD {
    
    if (_vad != nil) {
        opusvad_destroy(_vad);
        _vad = nil;
    }
}

- (void)dealloc {
    TPCircularBufferCleanup(_buffer);
    free(_buffer);
    [self releaseVAD];
}

- (float)getAmplitudeWithAudioBuffer:(int16_t[]) buffer withSize:(int32_t)size {
    
    short max = 0;
    float energyLevel = 0.0F;
    
    for( int i = 0; i < size; i += 1 ) {
        short sample = buffer[i];
        max = (max > sample) ? max : sample;
    }
    
    energyLevel = max / MAX_16_BITS_SIGNED;
    return energyLevel * 100;
    
}

- (void) passAudioToDelegate:(unsigned char *)pcm size:(uint32_t)size final:(BOOL)final
{
    // Pass the audio to the delegate in the format requested during initialization
    NSData *data = [NSData dataWithBytes:pcm length:size];
    if( [_delegate respondsToSelector:@selector(onAudio:withFinal:)]) {
        [_delegate onAudio:data withFinal:final];
    }
}

#pragma mark - AudioRecorder handlers

- (void)onRecorderStarted
{
    if( [_delegate respondsToSelector:@selector(onRecorderStarted)])
        [_delegate onRecorderStarted];
}

- (void)onRecorderStopped
{
        if( [_delegate respondsToSelector:@selector(onRecorderStopped)])
            [_delegate onRecorderStopped];
}

- (void)onEndOfSpeechDetected {
    
}


- (void)onStartOfSpeechDetected {
    
}


- (void)onAudio:(NSData *)packet final:(BOOL)final
{
    // Place audio into a queue and process asynchronously...
    int32_t size = (int32_t)[packet length];
    void *audio = TPCircularBufferHead(self.buffer, &size);
    memcpy(audio, (void *)[packet bytes], (int32_t)[packet length]);
    TPCircularBufferProduce(self.buffer, (int32_t)[packet length]);

    // Process the audio
    dispatch_async(self.queue, ^{
        void *_audio;
        int32_t _size;
        void *_packet = TPCircularBufferTail(self.buffer, &_size);
        int32_t _bufferSizeConsumed = _size;

        // Using opus requires working on PCM audio in 20ms frames (640 bytes) at a time. But the audio provided from the recorder
        //  is of variable length. So the following routine will place any trailing bytes that don't fit into a 20ms frame into an
        //  overflow buffer which will be processed as part of the next buffer of audio pulled off the queue.
        
        _audio = malloc((self.overflowSize+_size));
        
        // Prepend any audio in the overflow buffer
        if( self.overflowSize > 0 && self.overflowBuffer)
            memcpy(_audio, self.overflowBuffer, self.overflowSize);
        
        memcpy(_audio+self.overflowSize, _packet, _size);
        _size += self.overflowSize;
        self.overflowSize = 0;
        
        // Process the audio buffer 20ms frames at a time...
        int32_t frameSize = 640;
        if( _size > 0 ) {

            int32_t consumed = 0;
            
            // While we have a buffer with at least 640 bytes of audio available for processing...
            while(consumed <= _size && (_size - consumed) >= frameSize) {

                unsigned char *pcm = malloc(frameSize * 2);
                memcpy(pcm, _audio+consumed, frameSize);
                consumed += frameSize;
                
                // Calculate and notify delegate of audio energy for the current audio packet
                //if( [_delegate respondsToSelector:@selector(onAudioEnergyLevel:)])
                //    [_delegate onAudioEnergyLevel:[self getAmplitudeWithAudioBuffer:(short *)pcm withSize:frameSize]];
                    // Run the audio thru opusvad
                    int error = opusvad_process_audio(self.vad, (short*)pcm, frameSize/2);
                    if (error != OPUSVAD_OK)
                    {
                        NSLog(@"Error with opusvad_process_audio: %d\n", error);
                        free(_audio);
                        free(pcm);
                        return;
                    }
                // Percolate start and end of speech events
                // Pass the audio to the delegate
                [self passAudioToDelegate:pcm size:frameSize final:final];
                free(pcm);
            }
            
            // Save any overflow audio...
            if( _size > consumed ) {
                if (self.overflowBuffer) {
                    free(self.overflowBuffer);
                    self.overflowBuffer = nil;
                }                
                self.overflowBuffer =  malloc((_size - consumed)*2);
                memcpy(self.overflowBuffer, _audio+consumed, _size-consumed);
                self.overflowSize = (_size - consumed);
            }
        }
        
        // Send any remaining audio in the overflow buffer and release opusvad
        if (final && self.vad != nil) {
            if (self.overflowSize > 0) {
                // Run the audio thru opusvad
                int error = opusvad_process_audio(self.vad, (short*)self.overflowBuffer, self.overflowSize/2);
                if (error != OPUSVAD_OK)
                    NSLog(@"Error with opusvad_process_audio: %d\n", error);
                else
                    [self passAudioToDelegate:self.overflowBuffer size:self.overflowSize final:final];
            }
            [self releaseVAD];
            if (self.overflowBuffer) {
                free(self.overflowBuffer);
                self.overflowBuffer = nil;
            }
        }
        
        // Release audio
        if (_audio)
            free(_audio);
        
        TPCircularBufferConsume(self.buffer, _bufferSizeConsumed);
    });
}


@end

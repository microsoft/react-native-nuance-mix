//
//  AudioRecorder.h
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import <Foundation/Foundation.h>
#import "Defines.h"
#import "TPCircularBuffer.h"
#import "Recorder.h"
#import "opus/opusvad.h"

//typedef void (^AudioRecorderBlock)(NSData *packet, BOOL final);
@protocol AudioRecorderDelegate;

@interface AudioRecorder : NSObject

@property (weak, nonatomic) id<AudioRecorderDelegate> delegate;

- (id)initWithURL:(NSURL *)url withDelegate:(id<AudioRecorderDelegate>)delegate;
- (void)initialize;
- (void)start;
- (void)start:(BOOL)stopOnEndOfSpeech;
- (void)stop;
- (void)onSos:(void*)ctx int:pos;
- (void)onEos:(void*)ctx int:pos;

@end

@protocol AudioRecorderDelegate <NSObject>
    - (void)onRecorderStarted;
    - (void)onRecorderStopped;
    - (void)onStartOfSpeechDetected;
    - (void)onEndOfSpeechDetected;
    - (void)onAudio:(NSData *)packet withFinal:(BOOL)final;
@end

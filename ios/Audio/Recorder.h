//
//  Recorder.h
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//



#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"


typedef int32_t (^RecordBlock)(void *buffer, int32_t bytes, BOOL final);
@protocol RecorderDelegate;

@interface Recorder : NSObject

@property (atomic, assign, readonly) BOOL isRecording;

- (id)initWithURL:(NSURL *)url;
- (void)recordWithDelegate:(id<RecorderDelegate>)delegate;
- (void)cancel;

@end

@protocol RecorderDelegate <NSObject>
- (void)onRecorderStarted;
- (void)onRecorderStopped;
- (void)onRecorderError;
- (void)onAudio:(NSData *)packet final:(BOOL)final;

@end

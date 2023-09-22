//
//  AudioPlayer.h
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#ifndef AudioPlayer_h
#define AudioPlayer_h

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"
#import "Defines.h"


@protocol AudioPlayerDelegate;

@interface AudioPlayer : NSObject

@property (atomic, assign, readonly) BOOL isPlaying;
@property (atomic, assign, readonly) BOOL isPaused;
@property (weak, nonatomic) id<AudioPlayerDelegate> delegate;

- (id)initWithURL:(NSURL *)url withDelegate:(id<AudioPlayerDelegate>)delegate;
- (id)initWithDelegate:(id<AudioPlayerDelegate>)delegate;
- (void) initialize;

- (void)play;
- (void)pause;
- (void)resume;
- (void)stopPlayingImmediately;
- (void)cancel;
- (void)enqueueAudio:(NSData *)audio;

@end

@protocol AudioPlayerDelegate <NSObject>
- (void)onPlayerStarted;
- (void)onPlayerStopped;
- (void)onAudioStreamingStarted;
- (void)onAudioStreamingFinished;
- (void)onPlayerError;
@end


#endif /* AudioPlayer_h */

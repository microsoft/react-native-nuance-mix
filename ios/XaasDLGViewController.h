//
//  XaasDLGViewController.h
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//
#import "NuanceMix/NuanceAsr.pbrpc.h"
#import "NuanceMix/NuanceTts.pbrpc.h"
#import "NuanceMix/DlgInterface.pbrpc.h"
#import "NuanceMix/DlgMessages.pbobjc.h"
#import "NuanceMix/DlgCommonMessages.pbobjc.h"
#import "Audio/AudioPlayer.h"
#import "Audio/AudioRecorder.h"
#import "NuanceMix.h"

@interface XaasDLGViewController : NSObject <GRPCProtoResponseHandler, AudioPlayerDelegate, AudioRecorderDelegate>

// User interface
- (void)loadDialog:(NuanceMix *)bridge;
- (void)toggleRecognition:(NSString *)textInput context:(NSString *)contextTag;
- (void)stop;

@end

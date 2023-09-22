//
//  XaasASRViewController.h
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//
#import "NuanceMix/NuanceAsr.pbrpc.h"
#import "NuanceMix/NuanceAsr.pbobjc.h"
#import "Audio/AudioRecorder.h"
#import "NuanceMix.h"


@interface XaasASRViewController : NSObject <GRPCProtoResponseHandler, AudioRecorderDelegate>

- (void)loadAsr:(NuanceMix *)bridge;
- (void)toggleRecognition:(NSString *)language;

// User interface
@end

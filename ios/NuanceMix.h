//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNNuanceXaasSpec.h"

@interface NuanceMix : NSObject <NativeNuanceMixSpec>
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface NuanceMix : RCTEventEmitter <RCTBridgeModule>

-(void)recognitionResultAvailable:(NSString *)result;
-(void)recordingDone;
-(void)playbackDone;
-(void)dialogRequest:(NSString *)request;
-(void)dialogResponse:(NSString *)response;
-(void)dialogPartial:(NSString *)partial;
-(void)dialogEnded;
-(void)dialogRecordingDone;
#endif

@end

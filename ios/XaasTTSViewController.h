//
//  XaasTTSViewController.h
//  XaasSample
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import "NuanceMix/NuanceTts.pbrpc.h"
#import "NuanceMix/NuanceTts.pbobjc.h"
#import "Audio/AudioPlayer.h"
#import "NuanceMix.h"

@interface XaasTTSViewController : NSObject <GRPCProtoResponseHandler, AudioPlayerDelegate>

-(void)loadTts:(NuanceMix *)bridge;
-(void)toggleTts:(NSString *)ttsText ssml:(NSString *)ssml voice:(NSString *)voice language:(NSString *)language model:(NSString *)model;
-(BOOL)findMyVoice:(NSString *)voice lang:(NSString *)lang model:(NSString *)model;
@end

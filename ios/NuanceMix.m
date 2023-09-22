//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

#import "NuanceMix.h"
#import <React/RCTLog.h>
#import "XaasTTSViewController.h"
#import "XaasASRViewController.h"
#import "XaasDLGViewController.h"

@interface NuanceMix () {
    XaasTTSViewController *t;
    XaasASRViewController *a;
    XaasDLGViewController *d;
}

@end



@implementation NuanceMix
{
    bool hasListeners;
}

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

-(void)removeListeners {
    hasListeners = NO;
}

RCT_EXPORT_MODULE(NuanceMix)

-(NSArray<NSString *> *)supportedEvents {
    return @[@"NuanceMixRecognitionResult", 
                @"NuanceMixRecordingDone", 
                @"NuanceMixPlaybackDone", 
                @"NuanceMixDialogRequest",
                @"NuanceMixDialogResponse", 
                @"NuanceMixDialogRecordingDone", 
                @"NuanceMixDialogEnded",
                @"NuanceMixDialogPartial"];
}

-(void) recognitionResultAvailable:(NSString *)result {
    [self sendEventWithName:@"NuanceMixRecognitionResult" body:result];
}

-(void) recordingDone {
    [self sendEventWithName:@"NuanceMixRecordingDone" body:nil];
    [a release];
    a = nil;
}

-(void) playbackDone {
    [self sendEventWithName:@"NuanceMixPlaybackDone" body:nil];
    [t release];
    t = nil;
}

-(void) dialogRequest:(NSString *)request {
    [self sendEventWithName:@"NuanceMixDialogRequest" body:request];
}

-(void) dialogResponse:(NSString *)response {
    [self sendEventWithName:@"NuanceMixDialogResponse" body:response];
}

-(void) dialogRecordingDone {
    [self sendEventWithName:@"NuanceMixDialogRecordingDone" body:nil];
}

-(void) dialogEnded {
    [self sendEventWithName:@"NuanceMixDialogEnded" body:nil];
}

-(void) dialogPartial:(NSString *)response {
    [self sendEventWithName:@"NuanceMixDialogPartial" body:response];
}


RCT_EXPORT_METHOD(recognize:(NSString *)language
                  recognize:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self startObserving];
    [a toggleRecognition: language];

    resolve(@"finished");
}
// Example method
RCT_EXPORT_METHOD(synthesize:(NSString *)tts
                  ssml:(NSString *)ssml
                  voice:(NSString *)voice
                  language:(NSString *)language
                  model:(NSString *)model
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [t toggleTts: tts ssml:ssml voice:voice language:language model:model];

    resolve(@"finished");
}

// Example method
RCT_EXPORT_METHOD(converse:(NSString *)textInput
                  context:(NSString *)contextTag
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [d toggleRecognition: textInput context:contextTag];

    resolve(@"finished");
}

RCT_EXPORT_METHOD(stopDialog:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (d != nil) {
        [d stop];
        [d release];
        d = nil;
    }
    resolve(@"finished");
}

RCT_EXPORT_METHOD(init:(NSString *)scope
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([scope containsString:@"tts"] && t == nil) {
        t = [XaasTTSViewController alloc];
        [t loadTts:self];
        [t retain];
    }
    if ([scope containsString:@"asr"] && a == nil) {
        a = [XaasASRViewController alloc];
        [a loadAsr:self];
        [a retain];
    }
    if ([scope containsString:@"dlg"] && d == nil) {
        d = [XaasDLGViewController alloc];
        [d loadDialog:self];
        [d retain];
    }

    resolve(@"finished");
}

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeNuanceMixSpecJSI>(params);
}
#endif

@end

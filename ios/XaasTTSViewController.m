//
//  XaasTTSViewController.m
//  XaasSample
//
//  This Controller is built to demonstrate how to perform TTS.
//
//  TTS is the transformation of text into speech.
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import "XaasTTSViewController.h"
#import "Utils/Authenticator.h"
#import "Utils/ConfigFile.h"
#import "Utils/TtsParams.h"

// State Logic: IDLE -> PROCESSING -> PLAYING -> repeat
enum {
    XaasIdle = 1,
    XaasProcessing = 2,
    XaasPlaying = 3
};
typedef NSUInteger XaasState;


@interface XaasTTSViewController () {
    TTSSynthesizer *tts;
    GRPCMutableCallOptions *options;
    NSMutableArray<TTSVoice*> *voiceList;
    AudioPlayer *playa;
    XaasState _state;
    BOOL _ignoreFutureAudio;
    unsigned long numSamplesToPlay;
    NSString *ttsText;
    NSString *ttsSsml;
    NuanceMix *bridge;
    TTSVoice *myVoice;
}

@end



@implementation XaasTTSViewController {}

#pragma mark - GRPCProtoResponseHandler

@synthesize dispatchQueue;

- (dispatch_queue_t)dispatchQueue {
  return dispatch_get_main_queue();
}

- (void)didReceiveProtoMessage:(GPBMessage *)message {
    if ([message isKindOfClass:[TTSGetVoicesResponse class]]) {
        // Handle TTSGetVoicesResponse message
        TTSGetVoicesResponse *response = (TTSGetVoicesResponse *)message;
        voiceList = [response voicesArray];
        [voiceList retain];
    } 
    if ([message isKindOfClass:[TTSSynthesisResponse class]]) {
        // Handle TTSSynthesisResponse message
        TTSSynthesisResponse *response = (TTSSynthesisResponse *)message;
        if ([response audio] != NULL) {
            [playa play];
            numSamplesToPlay += [[response audio] length];
            [playa enqueueAudio:[response audio]];
        }
    }
}
- (void)didCloseWithTrailingMetadata:(NSDictionary *)trailingMetadata error:(NSError *)error {
    if (error) {
        NSLog(@"RPC error: %@", error);
    } else if (_state == XaasPlaying) {
        _ignoreFutureAudio = false;
    }
}

#pragma mark - TTS Transactions

- (void)createTtsChannel:(NSString *) ttsHost withToken:(NSString *) token withTokenType:(NSString *)tokenType {
    
    options = [[GRPCMutableCallOptions alloc] init];
    options.transportType = GRPCTransportTypeDefault;
    options.oauth2AccessToken = token;
    NSDictionary *dict = @{ @"authorization": [NSString stringWithFormat:@"%@ %@", tokenType, token] };
    options.initialMetadata = dict;

    tts = [TTSSynthesizer serviceWithHost:ttsHost callOptions:options];
    [tts retain];
    [options retain];
}

- (void)getVoices {
    TTSGetVoicesRequest *request = [[TTSGetVoicesRequest alloc] init];
    GRPCUnaryProtoCall * call = [tts getVoicesWithMessage:request responseHandler:self callOptions: options];
    [call start];
}

- (void)synthesize {
    numSamplesToPlay = 0;
    TTSSynthesisRequest *request = [[TTSSynthesisRequest alloc] init];
    [request setVoice:myVoice];
    if (ttsSsml == NULL) {
        TTSText *ttstext = [[TTSText alloc] init];
        [ttstext setText:ttsText];
        TTSInput *input = [[TTSInput alloc] init];
        [input setText:ttstext];
        [request setInput:input];
    } else {
        TTSSSML *ssml = [[TTSSSML alloc] init];
        [ssml setText:ttsSsml];
        TTSInput *input = [[TTSInput alloc] init];
        [input setSsml:ssml];
        [request setInput:input];
    }
    TTSAudioParameters *aParams = [[TTSAudioParameters alloc] init];
    TTSAudioFormat *format = [[TTSAudioFormat alloc] init];
    TTSPCM *pcm = [[TTSPCM alloc] init];
    [pcm setSampleRateHz:SAMPLE_RATE];
    [format setPcm:pcm];
    [aParams setAudioFormat:format];
    [request setAudioParams:aParams];
    GRPCUnaryProtoCall * call = [tts synthesizeWithMessage:request responseHandler:self callOptions: options];
    [call start];
}

- (void)loadTts:(NuanceMix *)pMix
{
    bridge = pMix;
    
    _state = XaasIdle;
    _ignoreFutureAudio = false;
    playa = [[AudioPlayer alloc] initWithDelegate:self];
    [playa retain];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Do any additional setup after loading the view.
            Authenticator *a = [Authenticator alloc];
            NSString *token = [a Authenticate:@"tts"];
            NSString *tokenType = [a getTokenType];
            ConfigFile *c = [ConfigFile alloc];
            [c loadConfig];
            [self createTtsChannel:[c getUrl:@"tts"] withToken:token withTokenType:tokenType];
            [self getVoices];
        }];
    });
}

- (BOOL)findMyVoice:(NSString *)voice lang:(NSString *)lang model:(NSString *)model {

    if ([voice caseInsensitiveCompare:@"not-specified"] == NSOrderedSame) {
        // Use the voice from the params file if it's not specified
        TtsParams *params = [TtsParams alloc];
        [params loadParams];
        id p = [params getParams];
        id v = [p valueForKey:@"voice"];

        voice = [v valueForKey:@"name"];
        model = [v valueForKey:@"model"];
        lang = [v valueForKey:@"language"];
    }

    NSLog(@"Looking for voice %@ %@ %@", voice, lang, model);

    for (int i=0; i<[voiceList count]; i++) {
        if (([voice caseInsensitiveCompare:[[voiceList objectAtIndex:i] name]] == NSOrderedSame) &&
            ([lang caseInsensitiveCompare:[[voiceList objectAtIndex:i] language]] == NSOrderedSame) &&
            ([model caseInsensitiveCompare:[[voiceList objectAtIndex:i] model]] == NSOrderedSame)) {
                myVoice = [voiceList objectAtIndex:i];
                [myVoice retain];
                NSLog(@"Voice Found %@", myVoice);
                return YES;
            }
    }
    return NO;
}

- (void)toggleTts:(NSString *)text ssml:(NSString *)ssml voice:(NSString *)voice language:(NSString *)language model:(NSString *)model {
    ttsText = text;
    ttsSsml = ssml;
    [ttsText retain];
    [ttsSsml retain];

    if (_state == XaasIdle) {
        _ignoreFutureAudio = false;
        _state = XaasProcessing;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (![self findMyVoice:voice lang:language model:model]) {
                if (![self findMyVoice:@"Ava-Ml" lang:@"en-US" model:@"enhanced"]) {
                    myVoice = [voiceList objectAtIndex:0];
                    [myVoice retain];
                    NSLog(@"Voice NOT Found using %@", myVoice);
                }
            }
            [self synthesize];
         }];
    } else if (_state == XaasPlaying) {
        [playa stopPlayingImmediately];
        _state = XaasIdle;
    } else if (_state == XaasProcessing) {
        _ignoreFutureAudio = true;
        _state = XaasIdle;
    }
}

- (void)dealloc {
    [super dealloc];
    if (tts != nil) {
        [tts release];
    }
    if (voiceList != nil) {
        [voiceList release];
    }
    if (playa != nil) {
        [playa release];
    }
    if (options != nil) {
        [options release];
    }
    if (ttsText != nil) {
        [ttsText release];
    }
}

#pragma AudioPlayerDelegate

- (void)onAudioStreamingFinished {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, SAMPLE_RATE/2 + numSamplesToPlay*SAMPLE_RATE);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
              _state = XaasIdle;
              [playa stopPlayingImmediately];
          }];
     });
}

- (void)onAudioStreamingStarted {
    _state = XaasPlaying;
}

- (void)onPlayerError {
    _state = XaasIdle;
    [bridge playbackDone];
}

- (void)onPlayerStarted {

}

- (void)onPlayerStopped {
    _state = XaasIdle;
    [bridge playbackDone];
}

@end

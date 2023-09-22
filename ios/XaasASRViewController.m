//
//  XaasASRViewController.m
//  XaasSample
//
//  This Controller is built to demonstrate how to perform ASR (Automatic Speech Recognition).
//
//  This Controller is very similar to XaasNLUViewController. Much of the code is duplicated for clarity.
//
//  ASR is the transformation of speech into text.
//
//  Created by Chris LeBlanc 1/9/2020
//
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
//

#import "XaasASRViewController.h"
#import "Utils/Authenticator.h"
#import "Utils/ConfigFile.h"
#import "Utils/AsrParams.h"
#import "NuanceMix.h"

// State Logic: IDLE -> LISTENING -> PROCESSING -> repeat
enum {
    XaasIdle = 1,
    XaasListening = 2,
    XaasProcessing = 3
};
typedef NSUInteger XaasState;


@interface XaasASRViewController () {
    
    ASRRecognizer *asr;
    GRPCStreamingProtoCall *call;
    GRPCMutableCallOptions *options;
    AudioRecorder *recorder;
    XaasState _state;
    NSTimer *_volumePollTimer;
    float level;
    BOOL endpointingEnabled;
    NuanceMix *bridge;
    AsrParams *params;
    BOOL isRecording;
}

@end

@implementation XaasASRViewController {}

#pragma mark - GRPCProtoResponseHandler

@synthesize dispatchQueue;

- (dispatch_queue_t)dispatchQueue {
  return dispatch_get_main_queue();
}

- (void)didReceiveInitialMetadata:(nullable NSDictionary *)initialMetadata {
    NSLog(@"didReceiveInitilaMetadata %@", [initialMetadata description]);
}

- (void)didWriteMessage {
}

- (void)didReceiveProtoMessage:(GPBMessage *)message {
    ASRRecognitionResponse *response = (ASRRecognitionResponse *)message;
    if (response != NULL) {
        if ([response responseUnionOneOfCase] == ASRRecognitionResponse_ResponseUnion_OneOfCase_Status) {
            ASRStatus *status = [response status];
            if (status != NULL) {
                if ([status code] != 100) {
                    [self stopRecording];
                }
            }
        }
        if ([response responseUnionOneOfCase] == ASRRecognitionResponse_ResponseUnion_OneOfCase_StartOfSpeech) {
            ASRStartOfSpeech *sos = [response startOfSpeech];
            if (sos != NULL) {
            }
        }
        if ([response responseUnionOneOfCase] == ASRRecognitionResponse_ResponseUnion_OneOfCase_Result) {
            ASRResult *result = [response result];
            if (result != NULL) {
                NSMutableArray<ASRHypothesis*> *hypArray = [result hypothesesArray];
                ASRHypothesis *hyp = [hypArray objectAtIndex:0];
                if ([hyp formattedText] != NULL) {
                    NSLog(@"Got result %@", [hyp formattedText]);
                    [bridge recognitionResultAvailable:[hyp formattedText]];
                }
            }
        }
    }
}

- (void)didCloseWithTrailingMetadata:(NSDictionary *)trailingMetadata error:(NSError *)error {
    if (error) {
        NSLog(@"RPC error: %@", error);
    } else {
        NSLog(@"Status OK");
    }
}

#pragma mark - ASR Transactions

- (void)createAsrChannel:(NSString *) asrHost withToken:(NSString *) token withTokenType:(NSString *)tokenType {
    
    options = [[GRPCMutableCallOptions alloc] init];
    options.transportType = GRPCTransportTypeDefault;
    options.oauth2AccessToken = token;
    NSDictionary *dict = @{ @"authorization": [NSString stringWithFormat:@"%@ %@", tokenType, token] };
    options.initialMetadata = dict;

    asr = [ASRRecognizer serviceWithHost:asrHost callOptions:options];
    [asr retain];
    [options retain];
}

- (void)recognize:(NSString *)language {    
    // Setup this recognition service...
    params = [AsrParams alloc];
    [params loadParams];
    id p = [params getParams];
    id f = [p valueForKey:@"recognition_flags"];
    
    NSString *lang;
    if (language == NULL) {
        lang = [p valueForKey:@"language"];
    } else {
        lang = language;
    }

    ASRRecognitionParameters *params = [[ASRRecognitionParameters alloc] init];
    ASRAudioFormat *format = [[ASRAudioFormat alloc] init];
    ASRPCM *pcm = [[ASRPCM alloc] init];
    [pcm setSampleRateHz:SAMPLE_RATE];
    [format setPcm:pcm];
    [params setLanguage:lang];
    [params setTopic:[p  valueForKey:@"topic"]];
    [params setAudioFormat:format];
    [params setResultType:ASREnumResultType_Partial];
    ASRRecognitionFlags *recoFlags = [[ASRRecognitionFlags alloc] initWithData:f error:nil];
    [params setRecognitionFlags:recoFlags];
    ASRRecognitionInitMessage *initRequest = [[ASRRecognitionInitMessage alloc] init];
    [initRequest setParameters:params];
    ASRRecognitionRequest *request = [[ASRRecognitionRequest alloc] init];
    [request setRecognitionInitMessage:initRequest];

    call = [asr recognizeWithResponseHandler:self callOptions:options];
    [call retain];
    [call start];
    [call writeMessage:request];
    
    
    // Now start listening...
    recorder = [[AudioRecorder alloc] initWithURL:nil withDelegate:self];
    [recorder start];
    isRecording = YES;
    [self startPollingVolume];
}

- (void)loadAsr:(NuanceMix *)pMix
{
    bridge = pMix;
    AsrParams *params = [AsrParams alloc];
    [params loadParams];
    id p = [params getParams];
    
    _state = XaasIdle;
    endpointingEnabled = true;
    recorder = [[AudioRecorder alloc] init];
    [recorder retain];
    level = 5.0;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Do any additional setup after loading the view.
            Authenticator *a = [Authenticator alloc];
            NSString *token = [a Authenticate:@"asr"];
            NSString *tokenType = [a getTokenType];
            ConfigFile *c = [ConfigFile alloc];
            [c loadConfig];
            [self createAsrChannel:[c getUrl:@"asr"] withToken:token withTokenType:tokenType];
        }];
    });
}

#pragma mark - Other Actions

- (void)toggleRecognition:(NSString *)language
{
    switch (_state) {
        case XaasIdle:
            [self recognize:language];
            break;
        case XaasListening:
            [self stopRecording];
            break;
        case XaasProcessing:
            [self cancel];
            break;
        default:
            break;
    }
}

- (void)stopRecording
{
    // Stop recording the user.
    [recorder stop];
    [self stopPollingVolume];
}

- (void)cancel
{
    // Cancel the Reco transaction.
    [self stopRecording];
}

# pragma mark - Volume level

- (void)startPollingVolume
{
    // Every 50 milliseconds we should update the volume meter in our UI.
    _volumePollTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                        target:self
                                                      selector:@selector(pollVolume)
                                                      userInfo:nil repeats:YES];
}

- (void) pollVolume
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        [self.volumeLevelProgressView setProgress:level/100.0];
    }];
}

- (void) stopPollingVolume
{
    [_volumePollTimer invalidate];
    _volumePollTimer = nil;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        [self.volumeLevelProgressView setProgress:0.f];
    }];
}

#pragma mark - AudioRecorderDelegate
- (void)onStartOfSpeechDetected {
    if (endpointingEnabled) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"OpusVAD speech confirmed");
        }];
    }
}
- (void)onEndOfSpeechDetected {
    if (endpointingEnabled) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"OpusVAD end of speech");
        }];
        [self stopRecording];
    }
}

- (void)onRecorderStarted {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _state = XaasListening;
    }];
}
- (void)onRecorderStopped {
    if (isRecording) {
        isRecording = NO;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _state = XaasIdle;
            [bridge recordingDone];
        }];
    }
}

- (void)onAudio:(NSData *)packet withFinal:(BOOL)final {
    if ([packet bytes]) {
        short sample = *(short *)[packet bytes];
        level = abs(sample)/128;
        ASRRecognitionRequest *request = [[ASRRecognitionRequest alloc] init];
        [request setAudio:packet];
        [call writeMessage:request];
    }
}

- (void)dealloc {
    [super dealloc];
    if (asr != nil) {
        [asr release];
    }
    if (recorder != nil) {
        [recorder release];
    }
    if (options != nil) {
        [options release];
    }
    if (call != nil) {
        [call release];
    }
}

@end

    

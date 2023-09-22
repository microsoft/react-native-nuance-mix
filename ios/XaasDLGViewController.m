//
//  XaasDLGViewController.m
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

#import "XaasDLGViewController.h"
#import "Utils/Authenticator.h"
#import "Utils/ConfigFile.h"
#import "Utils/NluParams.h"
#import "NuanceMix.h"


// State Logic: IDLE -> RESPONDING -> LISTENING -> PLAYING -> PROCESSING ->
enum {
    XaasIdle = 1,
    XaasResponding = 2,
    XaasListening = 3,
    XaasPlaying = 4,
    XaasProcessing = 5,
    XaasInterpreting = 6
};
typedef NSUInteger XaasState;


@interface XaasDLGViewController () {

    // Common controller vars
    XaasState _state;
    GRPCMutableCallOptions *options;
    // ASR controller vars
    AudioRecorder *recorder;
    NSTimer *_volumePollTimer;
    float level;
    BOOL endpointingEnabled;
    // TTS Controller vars
    AudioPlayer *playa;
    BOOL _ignoreFutureAudio;
    unsigned long numSamplesToPlay;
    // DLG Controller vars
    DLGDialogService *dlg;
    GRPCUnaryProtoCall *dlgStartCall;
    GRPCStreamingProtoCall *dlgCall;
    DLGSelector *dlgSelector;
    DLGRequestData *requestData;
    DLGTtsParamsV1 *ttsParams;
    DLGAsrParamsV1 *asrParams;
    
    NSString *sessionId;
    NSString *inputText;
    NSString *promptString;
    NSString *_contextTag;
    BOOL useSpeech;
    
    NSCondition *condition;
    NSCondition *setCondition;
    BOOL questionAnswered;
    NSCondition *promptCondition;
    BOOL promptFinished;
    BOOL dialogEnded;

    NuanceMix *bridge;
}

@end

@implementation XaasDLGViewController {}

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
    if ([message isKindOfClass:[DLGStartResponse class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            DLGStartResponse *response = (DLGStartResponse *)message;
            DLGStartResponsePayload *payload = [response payload];
            sessionId = [payload sessionId];
            NSLog([NSString stringWithFormat:@"Dialogue started %@", sessionId]);
            [sessionId retain];
            DLGExecuteRequestPayload *reqPayload = [[DLGExecuteRequestPayload alloc] init];
            DLGExecuteRequest *request = [[DLGExecuteRequest alloc] init];
            [request setPayload:reqPayload];
            [request setSelector:dlgSelector];
            [request setSessionId:sessionId];
            DLGStreamInput *stream = [[DLGStreamInput alloc] init];
            [stream setRequest:request];
            [stream setTtsControlV1: ttsParams];
            dlgCall = [dlg executeStreamWithResponseHandler: self callOptions:options];
            [dlgCall retain];
            [dlgCall start];
            [dlgCall writeMessage: stream];
            [dlgCall finish];
        });
    }
    if ([message isKindOfClass:[DLGStreamOutput class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            DLGStreamOutput *response = (DLGStreamOutput *)message;
            if ([response hasAudio]) {
                TTSSynthesisResponse * ttsresp = [response audio];
                switch ([ttsresp responseOneOfCase]) {
                    case TTSSynthesisResponse_Response_OneOfCase_GPBUnsetOneOfCase:
                        
                        break;
                    case TTSSynthesisResponse_Response_OneOfCase_Status:
                        
                        break;
                    case TTSSynthesisResponse_Response_OneOfCase_Events:
                        
                        break;
                    case TTSSynthesisResponse_Response_OneOfCase_Audio:
                        // Playback tts
                        _state = XaasPlaying;
                        numSamplesToPlay += [[ttsresp audio] length];
                        [playa enqueueAudio:[ttsresp audio]];
                        [playa play];
                        break;
                }
            }
            if ([response hasResponse]) {
                DLGExecuteResponse *resp = [response response];
                [self handleExecuteResponse:resp];
            }
            if ([response hasAsrResult]) {
                ASRResult *result = [response asrResult];
                if (result != NULL) {
                    NSMutableArray<ASRHypothesis*> *hypArray = [result hypothesesArray];
                    ASRHypothesis *hyp = [hypArray objectAtIndex:0];
                    if ([hyp formattedText] != NULL) {
                        inputText = [[NSString alloc] initWithString:[hyp formattedText]];
                        [bridge dialogPartial:inputText];
                        if ([result resultType] == ASREnumResultType_Final) {
                            NSLog([NSString stringWithFormat:@"<== %@", inputText]);
                            [bridge dialogRequest:inputText];
                            [inputText retain];
                            [self stopRecording];
                        }
                    }
                }
            }
        });
    }
}

- (void)didCloseWithTrailingMetadata:(NSDictionary *)trailingMetadata error:(NSError *)error {
    if (error) {
        NSLog(@"RPC error: %@", error);
    } else {
        if (_state == XaasPlaying) {
            _ignoreFutureAudio = NO;
        }
        NSLog(@"Status OK");
    }
}

#pragma mark - DLG Transactions
-(void)handleExecuteResponse:(DLGExecuteResponse *) resp {
    DLGExecuteResponsePayload *payload = [resp payload];
    NSString *promptText = NULL;
//    [self log:[NSString stringWithFormat:@"response %@", payload]];
    for (int i=0; i<payload.messagesArray_Count; i++) {
        for (int j=0; j<payload.messagesArray[i].visualArray_Count; j++) {
            if (promptText == NULL) {
                promptText = payload.messagesArray[i].visualArray[j].text;
            } else {
                promptText = [NSString stringWithFormat:@"%@ %@", promptText, payload.messagesArray[i].visualArray[j].text];
            }
        }
    }
    if (payload.qaAction != NULL && payload.qaAction.hasMessage) {
        for (int j=0; j<payload.qaAction.message.visualArray_Count; j++) {
            if (promptText == NULL) {
                promptText = payload.qaAction.message.visualArray[j].text;
            } else {
                promptText = [NSString stringWithFormat:@"%@ %@", promptText, payload.qaAction.message.visualArray[j].text];
            }
        }
    }
    if (promptText != NULL) {
        NSLog([NSString stringWithFormat:@"==> %@", promptText]);
        [bridge dialogResponse:promptText];
    }
    if (payload.daAction != NULL) {
        [self collectRequestData:payload.daAction];
    }
    if (payload.endAction != NULL && payload.endAction.hasData_p) {
        dialogEnded = YES;
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (_state != XaasPlaying) {
            if (dialogEnded) {
                _state = XaasIdle;
            } else {
                _state = XaasResponding;
            }
        }
    }];
}

-(void)createDlgChannel:(NSString *) dlgHost withToken:(NSString *) token withTokenType:(NSString *)tokenType {
    options = [[GRPCMutableCallOptions alloc] init];
    options.transportType = GRPCTransportTypeDefault;
    options.oauth2AccessToken = token;
    NSDictionary *dict = @{ @"authorization": [NSString stringWithFormat:@"%@ %@", tokenType, token] };
    options.initialMetadata = dict;

    dlg = [DLGDialogService serviceWithHost:dlgHost callOptions:options];
    [dlg retain];
    [options retain];
}

-(void)startDialog:(NSString *)contextTag {
    // Strating a new session
    dialogEnded = NO;
    sessionId = NULL;

    if (contextTag != NULL) {
        _contextTag = contextTag;
    }

    DLGStartRequestPayload *payload = [[DLGStartRequestPayload alloc] init];
    DLGResourceReference *ref = [[DLGResourceReference alloc] init];
    [ref setUri:[NSString stringWithFormat:@"urn:nuance-mix:tag:model/%@/mix.dialog", _contextTag]];
    payload.modelRef = ref;
    dlgSelector = [[DLGSelector alloc] init];
    [dlgSelector setLanguage:@"en-US"];
    [dlgSelector setChannel:@"default"];
    [dlgSelector setLibrary:@"default"];
    [dlgSelector retain];
    
    DLGStartRequest *request = [[DLGStartRequest alloc] init];
    [request setPayload:payload];
    [request setSelector:dlgSelector];
    dlgStartCall = [dlg startWithMessage:request responseHandler:self callOptions:options];
    [dlgStartCall retain];
    [dlgStartCall start];
}

-(void)respondText:(NSString *)response {
    DLGExecuteRequest *request = [[DLGExecuteRequest alloc] init];
    DLGExecuteRequestPayload *payload = [[DLGExecuteRequestPayload alloc] init];
    DLGUserInput *input = [[DLGUserInput alloc] init];
    [input setUserText:response];
    [payload setUserInput:input];
    [request setPayload:payload];
    [request setSessionId:sessionId];

    DLGStreamInput *stream = [[DLGStreamInput alloc] init];
    [stream setRequest:request];
    [stream setTtsControlV1: ttsParams];

    dlgCall = [dlg executeStreamWithResponseHandler:self callOptions:options];
    [dlgCall start];
    
    [dlgCall writeMessage:stream];
    [dlgCall finish];
}

-(void)respondData:(DLGRequestData *)data {
    DLGExecuteRequest *request = [[DLGExecuteRequest alloc] init];
    DLGExecuteRequestPayload *payload = [[DLGExecuteRequestPayload alloc] init];
    [payload setRequestedData:data];
    [request setPayload:payload];
    [request setSessionId:sessionId];

    DLGStreamInput *stream = [[DLGStreamInput alloc] init];
    [stream setRequest:request];
    [stream setTtsControlV1: ttsParams];

    dlgCall = [dlg executeStreamWithResponseHandler:self callOptions:options];
    [dlgCall start];
    
    [dlgCall writeMessage:stream];
    [dlgCall finish];
}

-(void)collectRequestData:(DLGDAAction *)data {
    NSString *id = [data id_p];
    NSArray *toks = [id componentsSeparatedByString: @"_"];
    NSString *action = [toks objectAtIndex:0];

    requestData = [[DLGRequestData alloc] init];
    requestData.id_p = id;
    [requestData retain];

    if ([action isEqualToString:@"get"]) {
        // NOT Supported
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self respondData:requestData];
        });
    } else if ([action isEqualToString:@"set"]) {
        for (int i = 2; i < toks.count; i++) {
            NSString *tok = [toks objectAtIndex:i++];
            if ([tok isEqualToString:@"endDialog"]) {
                dialogEnded = YES;
                _state = XaasIdle;
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // NOT Supported
                    [self respondData:requestData];
                });
            }
        }
    } else {
//        [self log:[NSString stringWithFormat:@"Error invalid data token ID %@", action]];
    }
}

#pragma mark - ASR Transactions

- (void)recognize {
    // Setup this recognition service...
    DLGExecuteRequest *request = [[DLGExecuteRequest alloc] init];
    DLGExecuteRequestPayload *payload = [[DLGExecuteRequestPayload alloc] init];
    [request setPayload:payload];
    [request setSessionId:sessionId];

    DLGStreamInput *stream = [[DLGStreamInput alloc] init];
    [stream setRequest:request];
    [stream setTtsControlV1: ttsParams];
    [stream setAsrControlV1: asrParams];

    dlgCall = [dlg executeStreamWithResponseHandler:self callOptions:options];
    [dlgCall start];
    
    [dlgCall writeMessage:stream];
    // Play the earcon...
    numSamplesToPlay = 0;
    // Now start listening...
    recorder = [[AudioRecorder alloc] initWithURL:nil withDelegate:self];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, numSamplesToPlay*SAMPLE_RATE);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
              [recorder start];
          }];
    });
    [self startPollingVolume];
}

-(void)initTtsParams {
    TTSPCM *pcm = [[TTSPCM alloc] init];
    [pcm setSampleRateHz:16000];
    TTSAudioFormat *format = [[TTSAudioFormat alloc] init];
    [format setPcm:pcm];
    TTSAudioParameters *ttsparams = [[TTSAudioParameters alloc] init];
    [ttsparams setAudioFormat:format];
    ttsParams = [[DLGTtsParamsV1 alloc] init];
    [ttsParams setAudioParams:ttsparams];
    [ttsParams retain];
}

-(void)initAsrParams {
    ASRPCM *pcm = [[ASRPCM alloc] init];
    [pcm setSampleRateHz:16000];
    ASRAudioFormat *format = [[ASRAudioFormat alloc] init];
    [format setPcm:pcm];
    asrParams = [[DLGAsrParamsV1 alloc] init];
    [asrParams setAudioFormat:format];
    [asrParams setUtteranceDetectionMode: ASREnumUtteranceDetectionMode_Multiple];
    [asrParams setResultType: ASREnumResultType_Partial];
    [asrParams retain];
}

- (void)loadDialog:(NuanceMix *)pMix
{
    bridge = pMix;

    NluParams *params = [NluParams alloc];
    [params loadParams];
    id p = [params getParams];

    _contextTag = [p valueForKey:@"context"];
    _state = XaasIdle;
    endpointingEnabled = YES;
    useSpeech = YES;
    recorder = [[AudioRecorder alloc] init];
    [recorder retain];
    level = 5.0;

    playa = [[AudioPlayer alloc] initWithDelegate:self];
    [playa retain];

    [self initTtsParams];
    [self initAsrParams];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // Do any additional setup after loading the view.
        Authenticator *a = [Authenticator alloc];
        NSString *dlgToken = [a Authenticate:@"dlg"];
        NSString *tokenType = [a getTokenType];
        ConfigFile *c = [ConfigFile alloc];
        [c loadConfig];
        [self createDlgChannel:[c getUrl:@"dlg"] withToken:dlgToken withTokenType:tokenType];
    }];
}

#pragma mark - Other Actions

- (IBAction)toggleRecognition:(NSString *)textInput context:(NSString *)contextTag
{
    if (textInput != nil) {
        NSLog(@"%@", [NSString stringWithFormat:@"toggleRecognition with state %lu and input %@", (unsigned long)_state, textInput]);
    } else {
        NSLog(@"%@", [NSString stringWithFormat:@"toggleRecognition with state %lu and no input", (unsigned long)_state]);
    }
    switch (_state) {
        case XaasIdle:
            dialogEnded = NO;
            [self startDialog:contextTag];
            break;
        case XaasResponding:
            if (textInput == NULL) {
                _state = XaasListening;
                [self recognize];
            } else {
                [bridge dialogRequest:textInput];
                [self respondText:textInput];
                _state = XaasResponding;
            }
            break;
        case XaasListening:
            [self stopRecording];
            _state = XaasProcessing;
            break;
        case XaasPlaying:
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                  if (dialogEnded) {
                    [bridge dialogEnded];
                      _state = XaasIdle;
                  } else {
                      _state = XaasResponding;
                  }
                  promptFinished = YES;
                  [promptCondition signal];
                  [playa stopPlayingImmediately];
              }];
            break;
        case XaasProcessing:
            [self stopRecording];
            _state = XaasResponding;
            break;
        default:
            break;
    }
}

- (void)stop
{
    [playa stopPlayingImmediately];
    [recorder stop];
    [self stopPollingVolume];
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
//    _volumePollTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
//                                                        target:self
//                                                      selector:@selector(pollVolume)
//                                                      userInfo:nil repeats:YES];
}

- (void) pollVolume
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        [self.volumeLevelProgressView setProgress:level/100.0];
    }];    
}

- (void) stopPollingVolume
{
    
//    [_volumePollTimer invalidate];
//    _volumePollTimer = nil;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        [self.volumeLevelProgressView setProgress:0.f];
    }];
}

#pragma mark - Helpers


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
    _state = XaasListening;
}
- (void)onRecorderStopped {
    _state = XaasResponding;
    [bridge dialogRecordingDone];
    [dlgCall finish];
}

- (void)onAudio:(NSData *)packet withFinal:(BOOL)final {
    if ([packet bytes]) {
        short sample = *(short *)[packet bytes];
        level = abs(sample)/128;
        DLGStreamInput *stream = [[DLGStreamInput alloc] init];
        [stream setAudio:packet];
        [dlgCall writeMessage:stream];
    }
}

#pragma mark - AudioPlayerDelegate

- (void)onAudioStreamingFinished {
    if (_state == XaasPlaying) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, numSamplesToPlay);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                  if (dialogEnded) {
                    [bridge dialogEnded];
                      _state = XaasIdle;
                  } else {
                      _state = XaasResponding;
                  }
                  promptFinished = YES;
                  [promptCondition signal];
                  [playa stopPlayingImmediately];
              }];
         });
    }
}

- (void)onAudioStreamingStarted {
    if (_state == XaasPlaying) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        }];
    }
}

- (void)onPlayerError {
}

- (void)onPlayerStarted {
}

- (void)onPlayerStopped {
}

- (void)dealloc {
    [super dealloc];
    if (recorder != nil) {
        [recorder release];
    }
    if (playa != nil) {
        [playa release];
    }
    [options release];
    if (dlgCall != nil) {
        [dlgCall release];
    }
    if (dlgStartCall != nil) {
        [dlgStartCall release];
    }
    if (ttsParams != nil) {
        [ttsParams release];
    }
    if (asrParams != nil) {
        [asrParams release];
    }
    if (inputText != nil) {
        [inputText release];
    }
    if (sessionId != nil) {
        [sessionId release];
    }
    if (condition != nil) {
        [condition release];
    }
    if (setCondition != nil) {
        [setCondition release];
    }
}

@end

    

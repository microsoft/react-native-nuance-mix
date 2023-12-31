// Code generated by gRPC proto compiler.  DO NOT EDIT!
// source: nuance_asr.proto

#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import "NuanceAsr.pbrpc.h"
#import "NuanceAsr.pbobjc.h"
#import <ProtoRPC/ProtoRPCLegacy.h>
#import <RxLibrary/GRXWriter+Immediate.h>

#import "NuanceAsrResource.pbobjc.h"
#import "NuanceAsrResult.pbobjc.h"

@implementation ASRRecognizer

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

// Designated initializer
- (instancetype)initWithHost:(NSString *)host callOptions:(GRPCCallOptions *_Nullable)callOptions {
  return [super initWithHost:host
                 packageName:@"nuance.asr.v1"
                 serviceName:@"Recognizer"
                 callOptions:callOptions];
}

- (instancetype)initWithHost:(NSString *)host {
  return [super initWithHost:host
                 packageName:@"nuance.asr.v1"
                 serviceName:@"Recognizer"];
}

#pragma clang diagnostic pop

// Override superclass initializer to disallow different package and service names.
- (instancetype)initWithHost:(NSString *)host
                 packageName:(NSString *)packageName
                 serviceName:(NSString *)serviceName {
  return [self initWithHost:host];
}

- (instancetype)initWithHost:(NSString *)host
                 packageName:(NSString *)packageName
                 serviceName:(NSString *)serviceName
                 callOptions:(GRPCCallOptions *)callOptions {
  return [self initWithHost:host callOptions:callOptions];
}

#pragma mark - Class Methods

+ (instancetype)serviceWithHost:(NSString *)host {
  return [[self alloc] initWithHost:host];
}

+ (instancetype)serviceWithHost:(NSString *)host callOptions:(GRPCCallOptions *_Nullable)callOptions {
  return [[self alloc] initWithHost:host callOptions:callOptions];
}

#pragma mark - Method Implementations

#pragma mark Recognize(stream RecognitionRequest) returns (stream RecognitionResponse)

/**
 * Starts a recognition request and returns a response. 
 *
 * This method belongs to a set of APIs that have been deprecated. Using the v2 API is recommended.
 */
- (void)recognizeWithRequestsWriter:(GRXWriter *)requestWriter eventHandler:(void(^)(BOOL done, ASRRecognitionResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  [[self RPCToRecognizeWithRequestsWriter:requestWriter eventHandler:eventHandler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Starts a recognition request and returns a response. 
 *
 * This method belongs to a set of APIs that have been deprecated. Using the v2 API is recommended.
 */
- (GRPCProtoCall *)RPCToRecognizeWithRequestsWriter:(GRXWriter *)requestWriter eventHandler:(void(^)(BOOL done, ASRRecognitionResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  return [self RPCToMethod:@"Recognize"
            requestsWriter:requestWriter
             responseClass:[ASRRecognitionResponse class]
        responsesWriteable:[GRXWriteable writeableWithEventHandler:eventHandler]];
}
/**
 * Starts a recognition request and returns a response. 
 */
- (GRPCStreamingProtoCall *)recognizeWithResponseHandler:(id<GRPCProtoResponseHandler>)handler callOptions:(GRPCCallOptions *_Nullable)callOptions {
  return [self RPCToMethod:@"Recognize"
           responseHandler:handler
               callOptions:callOptions
             responseClass:[ASRRecognitionResponse class]];
}

@end
#endif

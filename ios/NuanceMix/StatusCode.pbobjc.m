// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: status_code.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers_RuntimeSupport.h>
#else
 #import "GPBProtocolBuffers_RuntimeSupport.h"
#endif

#import <stdatomic.h>

#import "StatusCode.pbobjc.h"
// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - StatusCodeRoot

@implementation StatusCodeRoot

// No extensions in the file and no imports, so no need to generate
// +extensionRegistry.

@end

#pragma mark - Enum StatusCode

GPBEnumDescriptor *StatusCode_EnumDescriptor(void) {
  static _Atomic(GPBEnumDescriptor*) descriptor = nil;
  if (!descriptor) {
    static const char *valueNames =
        "Unspecified\000Ok\000BadRequest\000InvalidRequest"
        "\000CancelledClient\000CancelledServer\000Deadlin"
        "eExceeded\000NotAuthorized\000PermissionDenied"
        "\000NotFound\000AlreadyExists\000NotImplemented\000U"
        "nknown\000TooLarge\000Busy\000Obsolete\000RateExceed"
        "ed\000QuotaExceeded\000InternalError\000";
    static const int32_t values[] = {
        StatusCode_Unspecified,
        StatusCode_Ok,
        StatusCode_BadRequest,
        StatusCode_InvalidRequest,
        StatusCode_CancelledClient,
        StatusCode_CancelledServer,
        StatusCode_DeadlineExceeded,
        StatusCode_NotAuthorized,
        StatusCode_PermissionDenied,
        StatusCode_NotFound,
        StatusCode_AlreadyExists,
        StatusCode_NotImplemented,
        StatusCode_Unknown,
        StatusCode_TooLarge,
        StatusCode_Busy,
        StatusCode_Obsolete,
        StatusCode_RateExceeded,
        StatusCode_QuotaExceeded,
        StatusCode_InternalError,
    };
    GPBEnumDescriptor *worker =
        [GPBEnumDescriptor allocDescriptorForName:GPBNSStringifySymbol(StatusCode)
                                       valueNames:valueNames
                                           values:values
                                            count:(uint32_t)(sizeof(values) / sizeof(int32_t))
                                     enumVerifier:StatusCode_IsValidValue];
    GPBEnumDescriptor *expected = nil;
    if (!atomic_compare_exchange_strong(&descriptor, &expected, worker)) {
      [worker release];
    }
  }
  return descriptor;
}

BOOL StatusCode_IsValidValue(int32_t value__) {
  switch (value__) {
    case StatusCode_Unspecified:
    case StatusCode_Ok:
    case StatusCode_BadRequest:
    case StatusCode_InvalidRequest:
    case StatusCode_CancelledClient:
    case StatusCode_CancelledServer:
    case StatusCode_DeadlineExceeded:
    case StatusCode_NotAuthorized:
    case StatusCode_PermissionDenied:
    case StatusCode_NotFound:
    case StatusCode_AlreadyExists:
    case StatusCode_NotImplemented:
    case StatusCode_Unknown:
    case StatusCode_TooLarge:
    case StatusCode_Busy:
    case StatusCode_Obsolete:
    case StatusCode_RateExceeded:
    case StatusCode_QuotaExceeded:
    case StatusCode_InternalError:
      return YES;
    default:
      return NO;
  }
}


#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
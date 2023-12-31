// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: nuance_asr_resource.proto

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

#import "NuanceAsrResource.pbobjc.h"
// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Wdollar-in-identifier-extension"

#pragma mark - Objective C Class declarations
// Forward declarations of Objective C classes that we can use as
// static values in struct initializers.
// We don't use [Foo class] because it is not a static value.
GPBObjCClassDeclaration(ASRResourceReference);
GPBObjCClassDeclaration(ASRWakeupWord);

#pragma mark - ASRNuanceAsrResourceRoot

@implementation ASRNuanceAsrResourceRoot

// No extensions in the file and no imports, so no need to generate
// +extensionRegistry.

@end

#pragma mark - ASRNuanceAsrResourceRoot_FileDescriptor

static GPBFileDescriptor *ASRNuanceAsrResourceRoot_FileDescriptor(void) {
  // This is called by +initialize so there is no need to worry
  // about thread safety of the singleton.
  static GPBFileDescriptor *descriptor = NULL;
  if (!descriptor) {
    GPB_DEBUG_CHECK_RUNTIME_VERSIONS();
    descriptor = [[GPBFileDescriptor alloc] initWithPackage:@"nuance.asr.v1"
                                                 objcPrefix:@"ASR"
                                                     syntax:GPBFileSyntaxProto3];
  }
  return descriptor;
}

#pragma mark - Enum ASREnumResourceType

GPBEnumDescriptor *ASREnumResourceType_EnumDescriptor(void) {
  static _Atomic(GPBEnumDescriptor*) descriptor = nil;
  if (!descriptor) {
    static const char *valueNames =
        "UndefinedResourceType\000Wordset\000CompiledWo"
        "rdset\000DomainLm\000SpeakerProfile\000Grammar\000Se"
        "ttings\000";
    static const int32_t values[] = {
        ASREnumResourceType_UndefinedResourceType,
        ASREnumResourceType_Wordset,
        ASREnumResourceType_CompiledWordset,
        ASREnumResourceType_DomainLm,
        ASREnumResourceType_SpeakerProfile,
        ASREnumResourceType_Grammar,
        ASREnumResourceType_Settings,
    };
    GPBEnumDescriptor *worker =
        [GPBEnumDescriptor allocDescriptorForName:GPBNSStringifySymbol(ASREnumResourceType)
                                       valueNames:valueNames
                                           values:values
                                            count:(uint32_t)(sizeof(values) / sizeof(int32_t))
                                     enumVerifier:ASREnumResourceType_IsValidValue];
    GPBEnumDescriptor *expected = nil;
    if (!atomic_compare_exchange_strong(&descriptor, &expected, worker)) {
      [worker release];
    }
  }
  return descriptor;
}

BOOL ASREnumResourceType_IsValidValue(int32_t value__) {
  switch (value__) {
    case ASREnumResourceType_UndefinedResourceType:
    case ASREnumResourceType_Wordset:
    case ASREnumResourceType_CompiledWordset:
    case ASREnumResourceType_DomainLm:
    case ASREnumResourceType_SpeakerProfile:
    case ASREnumResourceType_Grammar:
    case ASREnumResourceType_Settings:
      return YES;
    default:
      return NO;
  }
}

#pragma mark - Enum ASREnumResourceReuse

GPBEnumDescriptor *ASREnumResourceReuse_EnumDescriptor(void) {
  static _Atomic(GPBEnumDescriptor*) descriptor = nil;
  if (!descriptor) {
    static const char *valueNames =
        "UndefinedReuse\000LowReuse\000HighReuse\000";
    static const int32_t values[] = {
        ASREnumResourceReuse_UndefinedReuse,
        ASREnumResourceReuse_LowReuse,
        ASREnumResourceReuse_HighReuse,
    };
    GPBEnumDescriptor *worker =
        [GPBEnumDescriptor allocDescriptorForName:GPBNSStringifySymbol(ASREnumResourceReuse)
                                       valueNames:valueNames
                                           values:values
                                            count:(uint32_t)(sizeof(values) / sizeof(int32_t))
                                     enumVerifier:ASREnumResourceReuse_IsValidValue];
    GPBEnumDescriptor *expected = nil;
    if (!atomic_compare_exchange_strong(&descriptor, &expected, worker)) {
      [worker release];
    }
  }
  return descriptor;
}

BOOL ASREnumResourceReuse_IsValidValue(int32_t value__) {
  switch (value__) {
    case ASREnumResourceReuse_UndefinedReuse:
    case ASREnumResourceReuse_LowReuse:
    case ASREnumResourceReuse_HighReuse:
      return YES;
    default:
      return NO;
  }
}

#pragma mark - Enum ASREnumWeight

GPBEnumDescriptor *ASREnumWeight_EnumDescriptor(void) {
  static _Atomic(GPBEnumDescriptor*) descriptor = nil;
  if (!descriptor) {
    static const char *valueNames =
        "DefaultWeight\000Lowest\000Low\000Medium\000High\000Hig"
        "hest\000";
    static const int32_t values[] = {
        ASREnumWeight_DefaultWeight,
        ASREnumWeight_Lowest,
        ASREnumWeight_Low,
        ASREnumWeight_Medium,
        ASREnumWeight_High,
        ASREnumWeight_Highest,
    };
    GPBEnumDescriptor *worker =
        [GPBEnumDescriptor allocDescriptorForName:GPBNSStringifySymbol(ASREnumWeight)
                                       valueNames:valueNames
                                           values:values
                                            count:(uint32_t)(sizeof(values) / sizeof(int32_t))
                                     enumVerifier:ASREnumWeight_IsValidValue];
    GPBEnumDescriptor *expected = nil;
    if (!atomic_compare_exchange_strong(&descriptor, &expected, worker)) {
      [worker release];
    }
  }
  return descriptor;
}

BOOL ASREnumWeight_IsValidValue(int32_t value__) {
  switch (value__) {
    case ASREnumWeight_DefaultWeight:
    case ASREnumWeight_Lowest:
    case ASREnumWeight_Low:
    case ASREnumWeight_Medium:
    case ASREnumWeight_High:
    case ASREnumWeight_Highest:
      return YES;
    default:
      return NO;
  }
}

#pragma mark - ASRRecognitionResource

@implementation ASRRecognitionResource

@dynamic resourceUnionOneOfCase;
@dynamic weightUnionOneOfCase;
@dynamic externalReference;
@dynamic inlineWordset;
@dynamic builtin;
@dynamic inlineGrammar;
@dynamic wakeupWord;
@dynamic weightEnum;
@dynamic weightValue;
@dynamic reuse;

typedef struct ASRRecognitionResource__storage_ {
  uint32_t _has_storage_[3];
  ASREnumWeight weightEnum;
  float weightValue;
  ASREnumResourceReuse reuse;
  ASRResourceReference *externalReference;
  NSString *inlineWordset;
  NSString *builtin;
  NSString *inlineGrammar;
  ASRWakeupWord *wakeupWord;
} ASRRecognitionResource__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "externalReference",
        .dataTypeSpecific.clazz = GPBObjCClass(ASRResourceReference),
        .number = ASRRecognitionResource_FieldNumber_ExternalReference,
        .hasIndex = -1,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, externalReference),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeMessage,
      },
      {
        .name = "inlineWordset",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRRecognitionResource_FieldNumber_InlineWordset,
        .hasIndex = -1,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, inlineWordset),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "builtin",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRRecognitionResource_FieldNumber_Builtin,
        .hasIndex = -1,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, builtin),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "inlineGrammar",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRRecognitionResource_FieldNumber_InlineGrammar,
        .hasIndex = -1,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, inlineGrammar),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "weightEnum",
        .dataTypeSpecific.enumDescFunc = ASREnumWeight_EnumDescriptor,
        .number = ASRRecognitionResource_FieldNumber_WeightEnum,
        .hasIndex = -2,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, weightEnum),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldHasEnumDescriptor),
        .dataType = GPBDataTypeEnum,
      },
      {
        .name = "weightValue",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRRecognitionResource_FieldNumber_WeightValue,
        .hasIndex = -2,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, weightValue),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeFloat,
      },
      {
        .name = "reuse",
        .dataTypeSpecific.enumDescFunc = ASREnumResourceReuse_EnumDescriptor,
        .number = ASRRecognitionResource_FieldNumber_Reuse,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, reuse),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldHasEnumDescriptor | GPBFieldClearHasIvarOnZero),
        .dataType = GPBDataTypeEnum,
      },
      {
        .name = "wakeupWord",
        .dataTypeSpecific.clazz = GPBObjCClass(ASRWakeupWord),
        .number = ASRRecognitionResource_FieldNumber_WakeupWord,
        .hasIndex = -1,
        .offset = (uint32_t)offsetof(ASRRecognitionResource__storage_, wakeupWord),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeMessage,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[ASRRecognitionResource class]
                                     rootClass:[ASRNuanceAsrResourceRoot class]
                                          file:ASRNuanceAsrResourceRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(ASRRecognitionResource__storage_)
                                         flags:(GPBDescriptorInitializationFlags)(GPBDescriptorInitializationFlag_UsesClassRefs | GPBDescriptorInitializationFlag_Proto3OptionalKnown)];
    static const char *oneofs[] = {
      "resourceUnion",
      "weightUnion",
    };
    [localDescriptor setupOneofs:oneofs
                           count:(uint32_t)(sizeof(oneofs) / sizeof(char*))
                   firstHasIndex:-1];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end

int32_t ASRRecognitionResource_WeightEnum_RawValue(ASRRecognitionResource *message) {
  GPBDescriptor *descriptor = [ASRRecognitionResource descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ASRRecognitionResource_FieldNumber_WeightEnum];
  return GPBGetMessageRawEnumField(message, field);
}

void SetASRRecognitionResource_WeightEnum_RawValue(ASRRecognitionResource *message, int32_t value) {
  GPBDescriptor *descriptor = [ASRRecognitionResource descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ASRRecognitionResource_FieldNumber_WeightEnum];
  GPBSetMessageRawEnumField(message, field, value);
}

int32_t ASRRecognitionResource_Reuse_RawValue(ASRRecognitionResource *message) {
  GPBDescriptor *descriptor = [ASRRecognitionResource descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ASRRecognitionResource_FieldNumber_Reuse];
  return GPBGetMessageRawEnumField(message, field);
}

void SetASRRecognitionResource_Reuse_RawValue(ASRRecognitionResource *message, int32_t value) {
  GPBDescriptor *descriptor = [ASRRecognitionResource descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ASRRecognitionResource_FieldNumber_Reuse];
  GPBSetMessageRawEnumField(message, field, value);
}

void ASRRecognitionResource_ClearResourceUnionOneOfCase(ASRRecognitionResource *message) {
  GPBDescriptor *descriptor = [ASRRecognitionResource descriptor];
  GPBOneofDescriptor *oneof = [descriptor.oneofs objectAtIndex:0];
  GPBClearOneof(message, oneof);
}
void ASRRecognitionResource_ClearWeightUnionOneOfCase(ASRRecognitionResource *message) {
  GPBDescriptor *descriptor = [ASRRecognitionResource descriptor];
  GPBOneofDescriptor *oneof = [descriptor.oneofs objectAtIndex:1];
  GPBClearOneof(message, oneof);
}
#pragma mark - ASRResourceReference

@implementation ASRResourceReference

@dynamic type;
@dynamic uri;
@dynamic maskLoadFailures;
@dynamic requestTimeoutMs;
@dynamic headers, headers_Count;

typedef struct ASRResourceReference__storage_ {
  uint32_t _has_storage_[1];
  ASREnumResourceType type;
  uint32_t requestTimeoutMs;
  NSString *uri;
  NSMutableDictionary *headers;
} ASRResourceReference__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "type",
        .dataTypeSpecific.enumDescFunc = ASREnumResourceType_EnumDescriptor,
        .number = ASRResourceReference_FieldNumber_Type,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(ASRResourceReference__storage_, type),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldHasEnumDescriptor | GPBFieldClearHasIvarOnZero),
        .dataType = GPBDataTypeEnum,
      },
      {
        .name = "uri",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRResourceReference_FieldNumber_Uri,
        .hasIndex = 1,
        .offset = (uint32_t)offsetof(ASRResourceReference__storage_, uri),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldClearHasIvarOnZero),
        .dataType = GPBDataTypeString,
      },
      {
        .name = "maskLoadFailures",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRResourceReference_FieldNumber_MaskLoadFailures,
        .hasIndex = 2,
        .offset = 3,  // Stored in _has_storage_ to save space.
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldClearHasIvarOnZero),
        .dataType = GPBDataTypeBool,
      },
      {
        .name = "requestTimeoutMs",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRResourceReference_FieldNumber_RequestTimeoutMs,
        .hasIndex = 4,
        .offset = (uint32_t)offsetof(ASRResourceReference__storage_, requestTimeoutMs),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldClearHasIvarOnZero),
        .dataType = GPBDataTypeUInt32,
      },
      {
        .name = "headers",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRResourceReference_FieldNumber_Headers,
        .hasIndex = GPBNoHasBit,
        .offset = (uint32_t)offsetof(ASRResourceReference__storage_, headers),
        .flags = GPBFieldMapKeyString,
        .dataType = GPBDataTypeString,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[ASRResourceReference class]
                                     rootClass:[ASRNuanceAsrResourceRoot class]
                                          file:ASRNuanceAsrResourceRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(ASRResourceReference__storage_)
                                         flags:(GPBDescriptorInitializationFlags)(GPBDescriptorInitializationFlag_UsesClassRefs | GPBDescriptorInitializationFlag_Proto3OptionalKnown)];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end

int32_t ASRResourceReference_Type_RawValue(ASRResourceReference *message) {
  GPBDescriptor *descriptor = [ASRResourceReference descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ASRResourceReference_FieldNumber_Type];
  return GPBGetMessageRawEnumField(message, field);
}

void SetASRResourceReference_Type_RawValue(ASRResourceReference *message, int32_t value) {
  GPBDescriptor *descriptor = [ASRResourceReference descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ASRResourceReference_FieldNumber_Type];
  GPBSetMessageRawEnumField(message, field, value);
}

#pragma mark - ASRWakeupWord

@implementation ASRWakeupWord

@dynamic wordsArray, wordsArray_Count;

typedef struct ASRWakeupWord__storage_ {
  uint32_t _has_storage_[1];
  NSMutableArray *wordsArray;
} ASRWakeupWord__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "wordsArray",
        .dataTypeSpecific.clazz = Nil,
        .number = ASRWakeupWord_FieldNumber_WordsArray,
        .hasIndex = GPBNoHasBit,
        .offset = (uint32_t)offsetof(ASRWakeupWord__storage_, wordsArray),
        .flags = GPBFieldRepeated,
        .dataType = GPBDataTypeString,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[ASRWakeupWord class]
                                     rootClass:[ASRNuanceAsrResourceRoot class]
                                          file:ASRNuanceAsrResourceRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(ASRWakeupWord__storage_)
                                         flags:(GPBDescriptorInitializationFlags)(GPBDescriptorInitializationFlag_UsesClassRefs | GPBDescriptorInitializationFlag_Proto3OptionalKnown)];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end


#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)

// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: interpretation-common.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30004
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30004 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum EnumOrigin

/**
 * *
 * Origin of an intent or entity. Included in
 * [IntentNode](#intentnode), [EntityNode](#entitynode), and
 * [SingleIntentEntity](#singleintententity).
 **/
typedef GPB_ENUM(EnumOrigin) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  EnumOrigin_GPBUnrecognizedEnumeratorValue = kGPBUnrecognizedEnumeratorValue,
  EnumOrigin_Unknown = 0,

  /** Determined from an exact match with a grammar file in the model. */
  EnumOrigin_Grammar = 1,

  /** Determined statistically from the SSM file in the model. */
  EnumOrigin_Statistical = 2,
};

GPBEnumDescriptor *EnumOrigin_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL EnumOrigin_IsValidValue(int32_t value);

#pragma mark - InterpretationCommonRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
GPB_FINAL @interface InterpretationCommonRoot : GPBRootObject
@end

#pragma mark - TextRange

typedef GPB_ENUM(TextRange_FieldNumber) {
  TextRange_FieldNumber_StartIndex = 1,
  TextRange_FieldNumber_EndIndex = 2,
};

/**
 * *
 * Range of text in the input literal. Included in
 * [OperatorNode](#operatornode), [IntentNode](#intentnode),
 * [EntityNode](#entitynode), and
 * [SingleIntentEntity](#singleintententity).
 **/
GPB_FINAL @interface TextRange : GPBMessage

/** Inclusive, 0-based character position. */
@property(nonatomic, readwrite) uint32_t startIndex;

/** Exclusive, 0-based character position. */
@property(nonatomic, readwrite) uint32_t endIndex;

@end

#pragma mark - AudioRange

typedef GPB_ENUM(AudioRange_FieldNumber) {
  AudioRange_FieldNumber_StartTimeMs = 1,
  AudioRange_FieldNumber_EndTimeMs = 2,
};

/**
 * *
 * Range of time in the input audio. Included in
 * [OperatorNode](#operatornode), [IntentNode](#intentnode),
 * [EntityNode](#entitynode), and
 * [SingleIntentEntity](#singleintententity).  Available only when
 * interpreting a recognition result from ASR as a Service.
 **/
GPB_FINAL @interface AudioRange : GPBMessage

/** Inclusive start time in milliseconds. */
@property(nonatomic, readwrite) uint32_t startTimeMs;

/** Exclusive end time in milliseconds. */
@property(nonatomic, readwrite) uint32_t endTimeMs;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)

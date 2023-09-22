// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: single-intent-interpretation.proto

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

@class AudioRange;
@class GPBAny;
@class GPBStruct;
@class SingleIntentEntity;
@class SingleIntentEntityList;
@class TextRange;
GPB_ENUM_FWD_DECLARE(EnumOrigin);

NS_ASSUME_NONNULL_BEGIN

#pragma mark - SingleIntentInterpretationRoot

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
GPB_FINAL @interface SingleIntentInterpretationRoot : GPBRootObject
@end

#pragma mark - SingleIntentInterpretation

typedef GPB_ENUM(SingleIntentInterpretation_FieldNumber) {
  SingleIntentInterpretation_FieldNumber_Intent = 2,
  SingleIntentInterpretation_FieldNumber_Confidence = 3,
  SingleIntentInterpretation_FieldNumber_Origin = 4,
  SingleIntentInterpretation_FieldNumber_Entities = 5,
  SingleIntentInterpretation_FieldNumber_Metadata = 13,
};

/**
 * *
 * Single-intent interpretation. Included in [Interpretation](#interpretation).
 **/
GPB_FINAL @interface SingleIntentInterpretation : GPBMessage

/** Intent name, as specified in the semantic model. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *intent;

/** Confidence score (between 0.0 and 1.0 inclusive). The higher the score, the likelier the detected intent is correct. */
@property(nonatomic, readwrite) float confidence;

/** How the intent was detected. */
@property(nonatomic, readwrite) enum EnumOrigin origin;

/** Map of entity names to lists of entities. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableDictionary<NSString*, SingleIntentEntityList*> *entities;
/** The number of items in @c entities without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger entities_Count;

/** Optional metadata attached to this interpretation. For internal use only. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableDictionary<NSString*, GPBAny*> *metadata;
/** The number of items in @c metadata without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger metadata_Count;

@end

/**
 * Fetches the raw value of a @c SingleIntentInterpretation's @c origin property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t SingleIntentInterpretation_Origin_RawValue(SingleIntentInterpretation *message);
/**
 * Sets the raw value of an @c SingleIntentInterpretation's @c origin property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetSingleIntentInterpretation_Origin_RawValue(SingleIntentInterpretation *message, int32_t value);

#pragma mark - SingleIntentEntityList

typedef GPB_ENUM(SingleIntentEntityList_FieldNumber) {
  SingleIntentEntityList_FieldNumber_EntitiesArray = 1,
};

/**
 *
 * List of entities.  Included in
 * [SingleIntentInterpretation](#singleintentinterpretation).
 **/
GPB_FINAL @interface SingleIntentEntityList : GPBMessage

/** Repeated. An entity match for the intent, for single-intent interpretation. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<SingleIntentEntity*> *entitiesArray;
/** The number of items in @c entitiesArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger entitiesArray_Count;

@end

#pragma mark - SingleIntentEntity

typedef GPB_ENUM(SingleIntentEntity_FieldNumber) {
  SingleIntentEntity_FieldNumber_TextRange = 1,
  SingleIntentEntity_FieldNumber_Confidence = 3,
  SingleIntentEntity_FieldNumber_Origin = 4,
  SingleIntentEntity_FieldNumber_Entities = 5,
  SingleIntentEntity_FieldNumber_StringValue = 6,
  SingleIntentEntity_FieldNumber_StructValue = 7,
  SingleIntentEntity_FieldNumber_Literal = 8,
  SingleIntentEntity_FieldNumber_Sensitive = 9,
  SingleIntentEntity_FieldNumber_FormattedLiteral = 11,
  SingleIntentEntity_FieldNumber_FormattedTextRange = 12,
  SingleIntentEntity_FieldNumber_Metadata = 13,
  SingleIntentEntity_FieldNumber_AudioRange = 15,
};

typedef GPB_ENUM(SingleIntentEntity_ValueUnion_OneOfCase) {
  SingleIntentEntity_ValueUnion_OneOfCase_GPBUnsetOneOfCase = 0,
  SingleIntentEntity_ValueUnion_OneOfCase_StringValue = 6,
  SingleIntentEntity_ValueUnion_OneOfCase_StructValue = 7,
};

/**
 *
 * Entity in the intent. Included in
 * [SingleIntentEntityList](#singleintententitylist).
 **/
GPB_FINAL @interface SingleIntentEntity : GPBMessage

/** Range of literal text for which this entity applies. */
@property(nonatomic, readwrite, strong, null_resettable) TextRange *textRange;
/** Test to see if @c textRange has been set. */
@property(nonatomic, readwrite) BOOL hasTextRange;

/** Confidence score between 0.0 and 1.0 inclusive. The higher the score, the likelier the entity detection is correct. */
@property(nonatomic, readwrite) float confidence;

/** How the entity was detected. */
@property(nonatomic, readwrite) enum EnumOrigin origin;

/** For hierarchical entities, the child entities of the entity. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableDictionary<NSString*, SingleIntentEntityList*> *entities;
/** The number of items in @c entities without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger entities_Count;

@property(nonatomic, readonly) SingleIntentEntity_ValueUnion_OneOfCase valueUnionOneOfCase;

/** The canonical value as a string. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *stringValue;

/** The entity value as an object. This object may be directly converted to a JSON representation. */
@property(nonatomic, readwrite, strong, null_resettable) GPBStruct *structValue;

/** The input literal associated with this entity. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *literal;

/** Indicates whether the entity has been flagged as sensitive. */
@property(nonatomic, readwrite) BOOL sensitive;

/** The input formatted literal associated with this entity. When InterpretationInput is text, it's the same as literal. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *formattedLiteral;

/** Range of the formatted literal text this entity applies to. When InterpretationInput is ASR result, it can be missing in misalignments cases. */
@property(nonatomic, readwrite, strong, null_resettable) TextRange *formattedTextRange;
/** Test to see if @c formattedTextRange has been set. */
@property(nonatomic, readwrite) BOOL hasFormattedTextRange;

/** Optional metadata attached to this entity. For internal use only. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableDictionary<NSString*, GPBAny*> *metadata;
/** The number of items in @c metadata without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger metadata_Count;

/** Range of audio input this entity applies to. Available only when interpreting a recognition result from ASR as a Service. */
@property(nonatomic, readwrite, strong, null_resettable) AudioRange *audioRange;
/** Test to see if @c audioRange has been set. */
@property(nonatomic, readwrite) BOOL hasAudioRange;

@end

/**
 * Fetches the raw value of a @c SingleIntentEntity's @c origin property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t SingleIntentEntity_Origin_RawValue(SingleIntentEntity *message);
/**
 * Sets the raw value of an @c SingleIntentEntity's @c origin property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetSingleIntentEntity_Origin_RawValue(SingleIntentEntity *message, int32_t value);

/**
 * Clears whatever value was set for the oneof 'valueUnion'.
 **/
void SingleIntentEntity_ClearValueUnionOneOfCase(SingleIntentEntity *message);

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
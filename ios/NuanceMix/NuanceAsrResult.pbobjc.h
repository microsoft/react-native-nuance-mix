// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: nuance_asr_result.proto

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

@class ASRDataPack;
@class ASRDsp;
@class ASRHypothesis;
@class ASRNotification;
@class ASRUtteranceInfo;
@class ASRWord;
@class LocalizedMessage;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum ASREnumResultType

/**
 *
 * Input and output field specifying how transcription results for each utterance are returned. See [Result type](#result-type) for examples. In a request [RecognitionParameters](#recognitionparameters), it specifies the desired result type. In a response [Result](#result), it indicates the actual result type that was returned.
 **/
typedef GPB_ENUM(ASREnumResultType) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  ASREnumResultType_GPBUnrecognizedEnumeratorValue = kGPBUnrecognizedEnumeratorValue,
  /** Only the final version of each utterance is returned. */
  ASREnumResultType_Final = 0,

  /** Variable partial results are returned, followed by a final result. */
  ASREnumResultType_Partial = 1,

  /** Stabilized partial results are returned, followed by a final result. */
  ASREnumResultType_ImmutablePartial = 2,
};

GPBEnumDescriptor *ASREnumResultType_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL ASREnumResultType_IsValidValue(int32_t value);

#pragma mark - Enum ASREnumSeverityType

typedef GPB_ENUM(ASREnumSeverityType) {
  /**
   * Value used if any message's field encounters a value that is not defined
   * by this enum. The message will also have C functions to get/set the rawValue
   * of the field.
   **/
  ASREnumSeverityType_GPBUnrecognizedEnumeratorValue = kGPBUnrecognizedEnumeratorValue,
  ASREnumSeverityType_SeverityUnknown = 0,
  ASREnumSeverityType_SeverityError = 10,
  ASREnumSeverityType_SeverityWarning = 20,
  ASREnumSeverityType_SeverityInfo = 30,
};

GPBEnumDescriptor *ASREnumSeverityType_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL ASREnumSeverityType_IsValidValue(int32_t value);

#pragma mark - ASRNuanceAsrResultRoot

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
GPB_FINAL @interface ASRNuanceAsrResultRoot : GPBRootObject
@end

#pragma mark - ASRResult

typedef GPB_ENUM(ASRResult_FieldNumber) {
  ASRResult_FieldNumber_ResultType = 1,
  ASRResult_FieldNumber_AbsStartMs = 2,
  ASRResult_FieldNumber_AbsEndMs = 3,
  ASRResult_FieldNumber_UtteranceInfo = 4,
  ASRResult_FieldNumber_HypothesesArray = 5,
  ASRResult_FieldNumber_DataPack = 6,
  ASRResult_FieldNumber_NotificationsArray = 7,
};

/**
 *
 * Output message containing the transcription result, including the result type, the start and end times, metadata about the transcription, and one or more transcription hypotheses. Included in [RecognitionResponse](#recognitionresponse).
 **/
GPB_FINAL @interface ASRResult : GPBMessage

/** Whether final, partial, or immutable results are returned. */
@property(nonatomic, readwrite) ASREnumResultType resultType;

/** Audio stream start time. */
@property(nonatomic, readwrite) uint32_t absStartMs;

/** Audio stream end time. */
@property(nonatomic, readwrite) uint32_t absEndMs;

/** Information about each sentence. */
@property(nonatomic, readwrite, strong, null_resettable) ASRUtteranceInfo *utteranceInfo;
/** Test to see if @c utteranceInfo has been set. */
@property(nonatomic, readwrite) BOOL hasUtteranceInfo;

/** Repeated. One or more transcription variations. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<ASRHypothesis*> *hypothesesArray;
/** The number of items in @c hypothesesArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger hypothesesArray_Count;

/** Data pack information */
@property(nonatomic, readwrite, strong, null_resettable) ASRDataPack *dataPack;
/** Test to see if @c dataPack has been set. */
@property(nonatomic, readwrite) BOOL hasDataPack;

/** List of notifications,  if any */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<ASRNotification*> *notificationsArray;
/** The number of items in @c notificationsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger notificationsArray_Count;

@end

/**
 * Fetches the raw value of a @c ASRResult's @c resultType property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t ASRResult_ResultType_RawValue(ASRResult *message);
/**
 * Sets the raw value of an @c ASRResult's @c resultType property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetASRResult_ResultType_RawValue(ASRResult *message, int32_t value);

#pragma mark - ASRUtteranceInfo

typedef GPB_ENUM(ASRUtteranceInfo_FieldNumber) {
  ASRUtteranceInfo_FieldNumber_DurationMs = 1,
  ASRUtteranceInfo_FieldNumber_ClippingDurationMs = 2,
  ASRUtteranceInfo_FieldNumber_DroppedSpeechPackets = 3,
  ASRUtteranceInfo_FieldNumber_DroppedNonspeechPackets = 4,
  ASRUtteranceInfo_FieldNumber_Dsp = 5,
};

/**
 *
 * Output message containing information about the recognized sentence in the  transcription result. Included in [Result](#result).
 **/
GPB_FINAL @interface ASRUtteranceInfo : GPBMessage

/** Utterance duration in milliseconds. */
@property(nonatomic, readwrite) uint32_t durationMs;

/** Milliseconds of clipping detected. */
@property(nonatomic, readwrite) uint32_t clippingDurationMs;

/** Number of speech audio buffers discarded during processing. */
@property(nonatomic, readwrite) uint32_t droppedSpeechPackets;

/** Number of non-speech audio buffers discarded during processing. */
@property(nonatomic, readwrite) uint32_t droppedNonspeechPackets;

/** Digital signal processing results. */
@property(nonatomic, readwrite, strong, null_resettable) ASRDsp *dsp;
/** Test to see if @c dsp has been set. */
@property(nonatomic, readwrite) BOOL hasDsp;

@end

#pragma mark - ASRDsp

typedef GPB_ENUM(ASRDsp_FieldNumber) {
  ASRDsp_FieldNumber_SnrEstimateDb = 1,
  ASRDsp_FieldNumber_Level = 2,
  ASRDsp_FieldNumber_NumChannels = 3,
  ASRDsp_FieldNumber_InitialSilenceMs = 4,
  ASRDsp_FieldNumber_InitialEnergy = 5,
  ASRDsp_FieldNumber_FinalEnergy = 6,
  ASRDsp_FieldNumber_MeanEnergy = 7,
};

/**
 *
 * Output message containing digital signal processing results. Included in [UtteranceInfo](#utteranceinfo).
 **/
GPB_FINAL @interface ASRDsp : GPBMessage

/** The estimated speech-to-noise ratio. */
@property(nonatomic, readwrite) float snrEstimateDb;

/** Estimated speech signal level. */
@property(nonatomic, readwrite) float level;

/** Number of audio channels. Always 1, meaning mono. */
@property(nonatomic, readwrite) uint32_t numChannels;

/** Milliseconds of silence observed before start of utterance. */
@property(nonatomic, readwrite) uint32_t initialSilenceMs;

/** Energy feature value of first speech frame. */
@property(nonatomic, readwrite) float initialEnergy;

/** Energy feature value of last speech frame. */
@property(nonatomic, readwrite) float finalEnergy;

/** Average energy feature value of utterance. */
@property(nonatomic, readwrite) float meanEnergy;

@end

#pragma mark - ASRHypothesis

typedef GPB_ENUM(ASRHypothesis_FieldNumber) {
  ASRHypothesis_FieldNumber_Confidence = 1,
  ASRHypothesis_FieldNumber_AverageConfidence = 2,
  ASRHypothesis_FieldNumber_Rejected = 3,
  ASRHypothesis_FieldNumber_FormattedText = 4,
  ASRHypothesis_FieldNumber_MinimallyFormattedText = 5,
  ASRHypothesis_FieldNumber_WordsArray = 6,
  ASRHypothesis_FieldNumber_EncryptedTokenization = 7,
  ASRHypothesis_FieldNumber_GrammarId = 9,
  ASRHypothesis_FieldNumber_DetectedWakeupWord = 10,
};

typedef GPB_ENUM(ASRHypothesis_OptionalHypothesisConfidence_OneOfCase) {
  ASRHypothesis_OptionalHypothesisConfidence_OneOfCase_GPBUnsetOneOfCase = 0,
  ASRHypothesis_OptionalHypothesisConfidence_OneOfCase_Confidence = 1,
};

typedef GPB_ENUM(ASRHypothesis_OptionalHypothesisAverageConfidence_OneOfCase) {
  ASRHypothesis_OptionalHypothesisAverageConfidence_OneOfCase_GPBUnsetOneOfCase = 0,
  ASRHypothesis_OptionalHypothesisAverageConfidence_OneOfCase_AverageConfidence = 2,
};

typedef GPB_ENUM(ASRHypothesis_OptionalHypothesisGrammarId_OneOfCase) {
  ASRHypothesis_OptionalHypothesisGrammarId_OneOfCase_GPBUnsetOneOfCase = 0,
  ASRHypothesis_OptionalHypothesisGrammarId_OneOfCase_GrammarId = 9,
};

typedef GPB_ENUM(ASRHypothesis_OptionalDetectedWuw_OneOfCase) {
  ASRHypothesis_OptionalDetectedWuw_OneOfCase_GPBUnsetOneOfCase = 0,
  ASRHypothesis_OptionalDetectedWuw_OneOfCase_DetectedWakeupWord = 10,
};

/**
 *
 * Output message containing one or more proposed transcriptions of the audio stream. Included in [Result](#result). Each variation has its own confidence level along with the text in two levels of formatting. See [Formatting](#formatting).
 **/
GPB_FINAL @interface ASRHypothesis : GPBMessage

@property(nonatomic, readonly) ASRHypothesis_OptionalHypothesisConfidence_OneOfCase optionalHypothesisConfidenceOneOfCase;

/** The confidence score for the entire transcription, 0 to 1. */
@property(nonatomic, readwrite) float confidence;

@property(nonatomic, readonly) ASRHypothesis_OptionalHypothesisAverageConfidence_OneOfCase optionalHypothesisAverageConfidenceOneOfCase;

/** The confidence score for the hypothesis, 0 to 1: the average of all word confidence scores based on their duration. */
@property(nonatomic, readwrite) float averageConfidence;

/** Whether the hypothesis was rejected. */
@property(nonatomic, readwrite) BOOL rejected;

/** Formatted text of the result, e.g. $500. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *formattedText;

/** Slightly formatted text of the result, e.g. Five hundred dollars. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *minimallyFormattedText;

/** Repeated. One or more recognized words in the result. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<ASRWord*> *wordsArray;
/** The number of items in @c wordsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger wordsArray_Count;

/** Nuance-internal representation of the recognition result. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *encryptedTokenization;

@property(nonatomic, readonly) ASRHypothesis_OptionalHypothesisGrammarId_OneOfCase optionalHypothesisGrammarIdOneOfCase;

/** Identifier of the matching grammar. Returned when result is originated by SRGS grammar rather than generic dictation. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *grammarId;

@property(nonatomic, readonly) ASRHypothesis_OptionalDetectedWuw_OneOfCase optionalDetectedWuwOneOfCase;

/** The detected wakeup word when using a wuw resource. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *detectedWakeupWord;

@end

/**
 * Clears whatever value was set for the oneof 'optionalHypothesisConfidence'.
 **/
void ASRHypothesis_ClearOptionalHypothesisConfidenceOneOfCase(ASRHypothesis *message);
/**
 * Clears whatever value was set for the oneof 'optionalHypothesisAverageConfidence'.
 **/
void ASRHypothesis_ClearOptionalHypothesisAverageConfidenceOneOfCase(ASRHypothesis *message);
/**
 * Clears whatever value was set for the oneof 'optionalHypothesisGrammarId'.
 **/
void ASRHypothesis_ClearOptionalHypothesisGrammarIdOneOfCase(ASRHypothesis *message);
/**
 * Clears whatever value was set for the oneof 'optionalDetectedWuw'.
 **/
void ASRHypothesis_ClearOptionalDetectedWuwOneOfCase(ASRHypothesis *message);

#pragma mark - ASRWord

typedef GPB_ENUM(ASRWord_FieldNumber) {
  ASRWord_FieldNumber_Text = 1,
  ASRWord_FieldNumber_Confidence = 2,
  ASRWord_FieldNumber_StartMs = 3,
  ASRWord_FieldNumber_EndMs = 4,
  ASRWord_FieldNumber_SilenceAfterWordMs = 5,
  ASRWord_FieldNumber_GrammarRule = 6,
};

typedef GPB_ENUM(ASRWord_OptionalWordConfidence_OneOfCase) {
  ASRWord_OptionalWordConfidence_OneOfCase_GPBUnsetOneOfCase = 0,
  ASRWord_OptionalWordConfidence_OneOfCase_Confidence = 2,
};

typedef GPB_ENUM(ASRWord_OptionalWordGrammarRule_OneOfCase) {
  ASRWord_OptionalWordGrammarRule_OneOfCase_GPBUnsetOneOfCase = 0,
  ASRWord_OptionalWordGrammarRule_OneOfCase_GrammarRule = 6,
};

/**
 *
 * Output message containing one or more recognized words in the hypothesis, including the text, confidence score, and timing information. Included in [Hypothesis](#hypothesis).
 **/
GPB_FINAL @interface ASRWord : GPBMessage

/** The recognized word. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *text;

@property(nonatomic, readonly) ASRWord_OptionalWordConfidence_OneOfCase optionalWordConfidenceOneOfCase;

/** The confidence score of the recognized word, 0 to 1. */
@property(nonatomic, readwrite) float confidence;

/** Word start offset in the audio stream. */
@property(nonatomic, readwrite) uint32_t startMs;

/** Word end offset in the audio stream. */
@property(nonatomic, readwrite) uint32_t endMs;

/** The amount of silence, in ms, detected after the word. */
@property(nonatomic, readwrite) uint32_t silenceAfterWordMs;

@property(nonatomic, readonly) ASRWord_OptionalWordGrammarRule_OneOfCase optionalWordGrammarRuleOneOfCase;

/** The grammar rule that recognized the word text. Returned when result is originated by SRGS grammar rather than generic dictation. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *grammarRule;

@end

/**
 * Clears whatever value was set for the oneof 'optionalWordConfidence'.
 **/
void ASRWord_ClearOptionalWordConfidenceOneOfCase(ASRWord *message);
/**
 * Clears whatever value was set for the oneof 'optionalWordGrammarRule'.
 **/
void ASRWord_ClearOptionalWordGrammarRuleOneOfCase(ASRWord *message);

#pragma mark - ASRDataPack

typedef GPB_ENUM(ASRDataPack_FieldNumber) {
  ASRDataPack_FieldNumber_Language = 1,
  ASRDataPack_FieldNumber_Topic = 2,
  ASRDataPack_FieldNumber_Version = 3,
  ASRDataPack_FieldNumber_Id_p = 4,
};

/**
 *
 * Output message containing information about the data pack used in the recognition. Included in [Result](#result).
 **/
GPB_FINAL @interface ASRDataPack : GPBMessage

/** Data pack language. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *language;

/** Data pack topic. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *topic;

/** Data pack version. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *version;

/** Data pack identifier string, including nightly build information if applicable. */
@property(nonatomic, readwrite, copy, null_resettable) NSString *id_p;

@end

#pragma mark - ASRNotification

typedef GPB_ENUM(ASRNotification_FieldNumber) {
  ASRNotification_FieldNumber_Code = 1,
  ASRNotification_FieldNumber_Severity = 2,
  ASRNotification_FieldNumber_Message = 3,
  ASRNotification_FieldNumber_Data_p = 4,
};

GPB_FINAL @interface ASRNotification : GPBMessage

/** Notification unique code */
@property(nonatomic, readwrite) int32_t code;

/** Severity (see below) */
@property(nonatomic, readwrite) ASREnumSeverityType severity;

/** Notification message */
@property(nonatomic, readwrite, strong, null_resettable) LocalizedMessage *message;
/** Test to see if @c message has been set. */
@property(nonatomic, readwrite) BOOL hasMessage;

/** Additional key/value pairs */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableDictionary<NSString*, NSString*> *data_p;
/** The number of items in @c data_p without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger data_p_Count;

@end

/**
 * Fetches the raw value of a @c ASRNotification's @c severity property, even
 * if the value was not defined by the enum at the time the code was generated.
 **/
int32_t ASRNotification_Severity_RawValue(ASRNotification *message);
/**
 * Sets the raw value of an @c ASRNotification's @c severity property, allowing
 * it to be set to a value that was not defined by the enum at the time the code
 * was generated.
 **/
void SetASRNotification_Severity_RawValue(ASRNotification *message, int32_t value);

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)

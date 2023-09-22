package com.nuance.utils;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.FileNotFoundException;
import java.io.IOException;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import com.google.gson.GsonBuilder;

import android.content.Context;
import android.app.Activity;

/**
 * Config
 */
public class AsrParams {

    public class RecognitionFlags {
        @SerializedName("auto_punctuate")
        boolean autoPunctuate;

        @SerializedName("filter_profanity")
        boolean filterProfanity;

        @SerializedName("include_tokenization")
        boolean includeTokenization;

        @SerializedName("small_timers")
        boolean smallTimers;

        @SerializedName("discard_speaker_adaptation")
        boolean discardSpeakerAdaptation;

        @SerializedName("suppress_call_recording")
        boolean suppressCallRecording;

        @SerializedName("mask_load_failures")
        boolean maskLoadFailures;

        public boolean isAutoPunctuate() {
            return autoPunctuate;
        }

        public void setAutoPunctuate(boolean autoPunctuate) {
            this.autoPunctuate = autoPunctuate;
        }

        public boolean isFilterProfanity() {
            return filterProfanity;
        }

        public void setFilterProfanity(boolean filterProfanity) {
            this.filterProfanity = filterProfanity;
        }

        public boolean isIncludeTokenization() {
            return includeTokenization;
        }

        public void setIncludeTokenization(boolean includeTokenization) {
            this.includeTokenization = includeTokenization;
        }

        public boolean isSmallTimers() {
            return smallTimers;
        }

        public void setSmallTimers(boolean smallTimers) {
            this.smallTimers = smallTimers;
        }

        public boolean isDiscardSpeakerAdaptation() {
            return discardSpeakerAdaptation;
        }

        public void setDiscardSpeakerAdaptation(boolean discardSpeakerAdaptation) {
            this.discardSpeakerAdaptation = discardSpeakerAdaptation;
        }

        public boolean isSuppressCallRecording() {
            return suppressCallRecording;
        }

        public void setSuppressCallRecording(boolean suppressCallRecording) {
            this.suppressCallRecording = suppressCallRecording;
        }

        public boolean isMaskLoadFailures() {
            return maskLoadFailures;
        }

        public void setMaskLoadFailures(boolean maskLoadFailures) {
            this.maskLoadFailures = maskLoadFailures;
        }
    }
    
    public class Parameters {
        @SerializedName("language")
        String language;

        @SerializedName("topic")
        String topic;

        @SerializedName("utterance_detection_mode")
        int utteranceDetectionMode;

        @SerializedName("result_type")
        int resultType;

        @SerializedName("recognition_flags")
        RecognitionFlags recognitionFlags;

        @SerializedName("no_input_timeout_ms")
        int noInputTimeoutMs;

        @SerializedName("recognition_timeout_ms")
        int recognitionTimeoutMs;

        @SerializedName("utterance_end_silence_ms")
        int utteranceEndSilenceMs;

        @SerializedName("max_hypotheses")
        int maxHypotheses;

        public String getLanguage() {
            return this.language;
        }

        public void setLanguage(String language) {
            this.language = language;
        }

        public String getTopic() {
            return topic;
        }

        public void setTopic(String topic) {
            this.topic = topic;
        }

        public int getUtteranceDetectionMode() {
            return utteranceDetectionMode;
        }

        public void setUtteranceDetectionMode(int utteranceDetectionMode) {
            this.utteranceDetectionMode = utteranceDetectionMode;
        }

        public int getResultType() {
            return resultType;
        }

        public void setResultType(int resultType) {
            this.resultType = resultType;
        }

        public int getNoInputTimeoutMs() {
            return noInputTimeoutMs;
        }

        public void setNoInputTimeoutMs(int noInputTimeoutMs) {
            this.noInputTimeoutMs = noInputTimeoutMs;
        }

        public int getRecognitionTimeoutMs() {
            return recognitionTimeoutMs;
        }

        public void setRecognitionTimeoutMs(int recognitionTimeoutMs) {
            this.recognitionTimeoutMs = recognitionTimeoutMs;
        }

        public int getUtteranceEndSilenceMs() {
            return utteranceEndSilenceMs;
        }

        public void setUtteranceEndSilenceMs(int utteranceEndSilenceMs) {
            this.utteranceEndSilenceMs = utteranceEndSilenceMs;
        }

        public int getMaxHypotheses() {
            return maxHypotheses;
        }

        public void setMaxHypotheses(int maxHypotheses) {
            this.maxHypotheses = maxHypotheses;
        }

        public RecognitionFlags getRecognitionFlags() {
            return recognitionFlags;
        }

        public void setRecognitionFlags(RecognitionFlags recognitionFlags) {
            this.recognitionFlags = recognitionFlags;
        }

    }

    Parameters parameters;

    public AsrParams(String paramsFile, Context ctx) {
        loadParams(paramsFile, ctx);
    }

    private boolean isEmpty(String var) {
        if (var == null) {
            return true;
        }
        return false;
    }

    private boolean loadParams(String paramsFile, Context appContext) {

        try {
            Gson gson = new Gson();

            BufferedReader reader = new BufferedReader(new InputStreamReader(appContext.getAssets().open(paramsFile)));

            // Parse the configuration parameters...
            parameters = gson.fromJson(reader, Parameters.class);
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
            return false;
        }
        catch (IOException ioe) {
            ioe.printStackTrace();
            return false;
        }

        return true;
    }

    @Override
    public String toString() {
        Gson gson = new GsonBuilder().setPrettyPrinting().create();

        return gson.toJson(parameters);
    }

    public Parameters getParameters() {
        return parameters;
    }
}
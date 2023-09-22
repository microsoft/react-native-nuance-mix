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
public class TtsParams {

    public class VoiceParams {
        @SerializedName("name")
        String name;
        @SerializedName("model")
        String model;
        @SerializedName("language")
        String language;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public String getLanguage() {
            return language;
        }

        public void setLanguage(String language) {
            this.language = language;
        }

    }

    public class InputData {
        @SerializedName("Body")
        String body;

        public String getBody() {
            return body;
        }

        public void setBody(String body) {
            this.body = body;
        }
    }

    public class InputParams {
        @SerializedName("type")
        String type;
        @SerializedName("InputData")
        InputData inputData;

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        public InputData getInputData() {
            return inputData;
        }

        public void setInputData(InputData data) {
            this.inputData = data;
        }
    }

    public class Parameters {
        @SerializedName("voice")
        VoiceParams voice;
        @SerializedName("input")
        InputParams input;

        public VoiceParams getVoiceParams() {
            return this.voice;
        }

        public void setVoiceParams(VoiceParams params) {
            this.voice = params;
        }

        public InputParams getInputParams() {
            return this.input;
        }

        public void setInputParams(InputParams params) {
            this.input = params;
        }

    }

    Parameters parameters;

    public TtsParams(String paramsFile, Context ctx) {
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
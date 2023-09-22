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
public class NluParams {

    public class Parameters {
        @SerializedName("language")
        String language;

        @SerializedName("context")
        String context;

        @SerializedName("input_text")
        String input_text;

        public String getLanguage() {
            return this.language;
        }

        public void setLanguage(String language) {
            this.language = language;
        }

        public String getContext() {
            return context;
        }

        public void setContext(String context) {
            this.context = context;
        }

        public String getInputText() {
            return input_text;
        }

        public void setInputText(String text) {
            this.input_text = text;
        }

    }

    Parameters parameters;

    public NluParams(String paramsFile, Context ctx) {
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
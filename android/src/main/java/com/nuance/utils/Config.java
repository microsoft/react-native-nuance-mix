package com.nuance.utils;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.io.BufferedReader;
import java.io.InputStreamReader;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import com.google.gson.GsonBuilder;

import android.content.Context;
import android.app.Activity;

/**
 * Config
 */
public class Config {

    private class Urls {
        @SerializedName("asr")
        String asrUrl;
        @SerializedName("tts")
        String ttsUrl;
        @SerializedName("nlu")
        String nluUrl;
        @SerializedName("dlg")
        String dlgUrl;

        public String getAsrUrl() {
            return asrUrl;
        }

        public String getTtsUrl() {
            return ttsUrl;
        }

        public String getNluUrl() {
            return nluUrl;
        }

        public String getDialogUrl() {
            return dlgUrl;
        }

    }

    public class Configuration {
        @SerializedName("xaas_urls")
        Urls urls;
        @SerializedName("client_id")
        String clientID;
        @SerializedName("client_secret")
        String clientSecret;
        @SerializedName("token_url")
        String tokenURL;

        public Urls getUrls() {
            return urls;
        }

        public String getClientID() {
            return clientID;
        }

        public void setClientID(String clientID) {
            this.clientID = clientID;
        }

        public String getClientSecret() {
            return clientSecret;
        }

        public void setClientSecret(String clientSecret) {
            this.clientSecret = clientSecret;
        }

        public String getTokenURL() {
            return tokenURL;
        }

        public void setTokenURL(String tokenURL) {
            this.tokenURL = tokenURL;
        }
    }

    Configuration configuration;

    public Config(String configFile, Context ctx) throws Exception {
        loadConfig(configFile, ctx);
    }

    private boolean isEmpty(String var) {
        if (var == null) {
            return true;
        }
        return false;
    }

    private boolean loadConfig(String configFile, Context appContext) throws Exception {

        Gson gson = new Gson();

        BufferedReader reader = new BufferedReader(new InputStreamReader(appContext.getAssets().open(configFile)));

        // Parse the configuration parameters...
        configuration = gson.fromJson(reader, Configuration.class);
        if (isEmpty(configuration.clientID) || isEmpty(configuration.clientSecret) || isEmpty(configuration.tokenURL)) {
            throw new IllegalArgumentException("Invalid configuration file.");
        }
        return true;
    }

    @Override
    public String toString() {
        //Gson gson = new Gson();
        Gson gson = new GsonBuilder().setPrettyPrinting().create();

        return gson.toJson(configuration);
    }

    public Configuration getConfiguration() {
        return configuration;
    }

    public String getAsrUrl() {
        return configuration.getUrls().getAsrUrl();
    }
    public String getTtsUrl() {
        return configuration.getUrls().getTtsUrl();
    }
    public String getNluUrl() {
        return configuration.getUrls().getNluUrl();
    }
    public String getDialogUrl() {
        return configuration.getUrls().getDialogUrl();
    }
}
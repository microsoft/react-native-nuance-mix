package com.nuance.utils;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import com.google.gson.GsonBuilder;

/**
 * Token
 */
public class Token {
    @SerializedName("access_token")
    String accessToken;
    
    @SerializedName("expires_in")
    int expiresIn;
    
    @SerializedName("scope")
    String scope;

    @SerializedName("token_type")
    String tokenType;

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public int getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(int expiresIn) {
        this.expiresIn = expiresIn;
    }

    public String getScope() {
        return scope;
    }

    public void setScope(String scope) {
        this.scope = scope;
    }

    public String getTokenType() {
        return tokenType;
    }

    public void setTokenType(String tokenType) {
        this.tokenType = tokenType;
    }

    public String toString() {
            Gson gson = new GsonBuilder().setPrettyPrinting().create();

            return gson.toJson(this);
    }
}
package com.nuance.utils;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import android.util.Log;
import android.content.Context;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Base64;

import javax.net.ssl.HttpsURLConnection;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import com.google.gson.GsonBuilder;

import com.nuance.utils.Config.Configuration;

/**
 * Authenticator
 */
public class Authenticator {

    Context context;
    static final String GRANT_TYPE = "client_credentials";
    static final String TOKEN_CACHE = "token.%s.cache";

    Configuration config;
    Token token;

    public Authenticator(Configuration config, Context appContext) {
        this.config = config;
        this.context = appContext.getApplicationContext();
    }

    private Token generateToken(String scope) throws Exception {
        token = null;

        String auth = URLEncoder.encode(config.getClientID(), "UTF-8") + ":" + config.getClientSecret();
        String authentication = Base64.getEncoder().encodeToString(auth.getBytes());
        
        String content = String.format("grant_type=%s&scope=%s", GRANT_TYPE, scope);
        
        URL url = new URL(config.getTokenURL());

        HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
        connection.setRequestMethod("POST");
        connection.setDoOutput(true);

        connection.setRequestProperty("Authorization", "Basic " + authentication);
        connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        connection.setRequestProperty("Accept", "application/json");

        PrintStream os = new PrintStream(connection.getOutputStream());
        os.print(content);
        os.close();

        Gson gson = new Gson();

        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));

        // Parse the configuration parameters...
        token = gson.fromJson(reader, Token.class);
        return token;
}

    private boolean isTokenValid(String scope) {
        File f = new File(context.getCacheDir(), String.format(TOKEN_CACHE, scope));
        if(!f.exists() || f.isDirectory() || !f.canRead()) { 
            return false;
        }

        Gson gson = new Gson();
        try {
            BufferedReader reader = new BufferedReader(new FileReader(f.getAbsolutePath()));
            Token t = gson.fromJson(reader, Token.class);
            if (t.accessToken == null || t.accessToken.isEmpty()) {
                return false;
            }
    
            if ((System.currentTimeMillis() - f.lastModified()) > t.getExpiresIn()) {
                return false;
            }
            
            token = t;                
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    private void cacheToken(String scope) {
        // Create a new Gson object
        Gson gson = new Gson();

        try {
            String jsonString = gson.toJson(token);
            File file = new File(context.getCacheDir(), String.format(TOKEN_CACHE, scope));
            FileWriter fileWriter = new FileWriter(file.getAbsolutePath());
            fileWriter.write(jsonString);
            fileWriter.close();                
        } catch (Exception e) {
            // Ignore...
            Log.e("TAG-Authenticator", e.getMessage(), e);
        }
    }

    public Token Authenticate(String scope) throws Exception {
        if (isTokenValid(scope)) {
            return token;
        }

        if (generateToken(scope) != null) {
            cacheToken(scope);
        }

        return token;
    }

    @Override
    public String toString() {
        return super.toString();
    }
}
package com.nuancemix;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.lang.System;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import android.content.Context;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.ReactApplication;

import android.util.Log;

import com.nuancemix.activity.ASRActivity;
import com.nuancemix.activity.TTSActivity;
import com.nuancemix.activity.DialogActivity;

@ReactModule(name = NuanceMixModule.NAME)
public class NuanceMixModule extends ReactContextBaseJavaModule {
  public static final String NAME = "NuanceMix";

  private static Context ctx;
  private static ASRActivity asr;
  private static TTSActivity tts;
  private static DialogActivity dlg;
  private static ReactContext reactCtx;

  static {
    System.loadLibrary("opus"); //this loads the library when the class is loaded
    System.loadLibrary("opusvadjava"); //this loads the library when the class is loaded
  }

  public NuanceMixModule(ReactApplicationContext reactContext) {
    super(reactContext);

    ctx = reactContext.getApplicationContext();
    reactCtx = (ReactContext)reactContext;
  }

  private static void sendEvent(ReactContext reactContext,
                        String eventName,
                        @Nullable WritableMap params) {
    reactCtx
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params.getString("body"));
  }
  
  public static void recognitionResultsAvailable(String results) {
    WritableMap map = Arguments.createMap();
    map.putString("body", results);
    
    sendEvent(reactCtx, "NuanceMixRecognitionResult", map);
  }

  public static void recordingDone() {
    WritableMap map = Arguments.createMap();
    map.putString("body", "");
    
    sendEvent(reactCtx, "NuanceMixRecordingDone", map);
  }

  public static void playbackDone() {
    WritableMap map = Arguments.createMap();
    map.putString("body", "");
    
    sendEvent(reactCtx, "NuanceMixPlaybackDone", map);
  }

  public static void dialogRequest(String results) {
    WritableMap map = Arguments.createMap();
    map.putString("body", results);
    
    sendEvent(reactCtx, "NuanceMixDialogRequest", map);
  }

  public static void dialogResponse(String results) {
    WritableMap map = Arguments.createMap();
    map.putString("body", results);
    
    sendEvent(reactCtx, "NuanceMixDialogResponse", map);
  }

  public static void dialogPartial(String results) {
    WritableMap map = Arguments.createMap();
    map.putString("body", results);
    
    sendEvent(reactCtx, "NuanceMixDialogPartial", map);
  }

  public static void dialogRecordingDone() {
    WritableMap map = Arguments.createMap();
    map.putString("body", "");
    
    sendEvent(reactCtx, "NuanceMixDialogRecordingDone", map);
  }

  public static void dialogEnded() {
    WritableMap map = Arguments.createMap();
    map.putString("body", "");
    
    sendEvent(reactCtx, "NuanceMixDialogEnded", map);
  }



  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  // Required for rn built in EventEmitter Calls.
  @ReactMethod
  public void addListener(String eventName) {
  }

  @ReactMethod
  public void removeListeners(Integer count) {
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  public void init(String scope, Promise promise) {

    if (scope.contains("tts") && tts == null) {
        tts = new TTSActivity(ctx);
        tts.loadTts(ctx);        
    }
    if (scope.contains("asr") && asr == null) {
        asr = new ASRActivity(ctx);
        asr.loadAsr(ctx);        
    }
    if (scope.contains("dlg") && dlg == null) {
      dlg = new DialogActivity(ctx);
      dlg.loadDialog(ctx);
    } 
    promise.resolve(true);
  }

  @ReactMethod
  public void stopDialog(Promise promise) {
    if (dlg != null) {
      dlg.stop();
    }
    dlg = null;
    promise.resolve(true);
  }

  @ReactMethod
  public void synthesize(String textInput, String ssml, String voice, String language, String model, Promise promise) {
    tts.toggleTTS(textInput, ssml, voice, language, model);
    promise.resolve(true);    
  }

  @ReactMethod
  public void recognize(String lang, Promise promise) {
    asr.toggleReco(lang);
    promise.resolve(true);    
  }

  @ReactMethod
  public void converse(String textInput, String contextTag, Promise promise) {
    dlg.toggleReco(textInput, contextTag);
    promise.resolve(true);    
  }

}

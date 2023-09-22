package com.nuancemix.activity;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import android.os.Bundle;
import android.util.Log;
import android.content.Context;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

import com.nuance.utils.*;
import com.nuance.audio.*;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

import io.grpc.CallCredentials;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.Metadata;
import io.grpc.stub.StreamObserver;
import nuance.tts.v1.NuanceTtsV1.AudioFormat;
import nuance.tts.v1.NuanceTtsV1.AudioParameters;
import nuance.tts.v1.NuanceTtsV1.EventParameters;
import nuance.tts.v1.NuanceTtsV1.GetVoicesRequest;
import nuance.tts.v1.NuanceTtsV1.GetVoicesResponse;
import nuance.tts.v1.NuanceTtsV1.Input;
import nuance.tts.v1.NuanceTtsV1.PCM;
import nuance.tts.v1.NuanceTtsV1.SynthesisRequest;
import nuance.tts.v1.NuanceTtsV1.SynthesisResponse;
import nuance.tts.v1.NuanceTtsV1.Text;
import nuance.tts.v1.NuanceTtsV1.SSML;
import nuance.tts.v1.NuanceTtsV1.Voice;
import nuance.tts.v1.SynthesizerGrpc;

import com.nuancemix.NuanceMixModule;
/**
 * This Activity is built to demonstrate how to perform TTS.
 *
 * TTS is the transformation of text into speech.
 *
 * When performing speech synthesis with SpeechKit, you have a variety of options. Here we demonstrate
 * Language. But you can also specify the Voice. If you do not, then the default voice will be used
 * for the given language.
 *
 * Supported languages and voices can be found here:
 * http://developer.nuance.com/public/index.php?task=supportedLanguages
 *
 * Copyright (c) 2015 Nuance Communications. All rights reserved.
 */
public class TTSActivity {

    private final String TAG = "TAG-TTSActivity";
    private static Context ctx;

    private int mSampleRate;

    private enum State {
        IDLE,
        PLAYING,
        PROCESSING
    }
    private State mState = State.IDLE;

    public class Defaults {
        static final String CONFIG_FILE = "config.json";
        static final String PARAMS_FILE = "params.tts.json";
        static final String AUDIO_SOURCE = "speaker";
    }

    private SynthesizerGrpc.SynthesizerStub conn;
    private IAudioSink mAudioSink = null;
    private long bytesWritten = 0;
    private CountDownLatch done;
    private CountDownLatch voicesDone;
    private TtsParams mParams;
    private Voice myVoice;

    public TTSActivity(Context ctx) {
        loadTts(ctx);
    }

    public void loadTts(Context context) {

        ctx = context;
        mParams = new TtsParams(Defaults.PARAMS_FILE, ctx);

        ArrayList<String> voicesList = new ArrayList<String>();

        if (DataHolder.getInstance().getData() == null) {
            Thread loadVoiceThread = new Thread(new Runnable() {
                public void run() {
                    try {
                        voicesDone = new CountDownLatch(1);
                        getVoices();
                        voicesDone.await();
                    } catch (InterruptedException e) 
                    { }
                    if (DataHolder.getInstance().getData() != null) {
                        // Must updateVoices from the UI thread
                    }            
                }
            });
            loadVoiceThread.start();
        }
        setState(State.IDLE);
    }

    public void toggleTTS(String textInput, String ssml, String voice, String lang, String model) {

        switch (mState) {
            case IDLE:
                setState(State.PROCESSING);
                if (!findMyVoice(voice, lang, model)) {
                    if (!findMyVoice("Ava-Ml", "en-US", "enhanced")) {
                        myVoice = DataHolder.getInstance().getData().get(0);
                        Log.e(TAG, "VOICE NOT Found using" + myVoice.getName() + " " + myVoice.getLanguage() + " " + myVoice.getModel());
                    }
                }
                synthesize(textInput, ssml);
                break;
            case PLAYING:
                stopPlaying();
                break;
            case PROCESSING:
                cancel();
                break;
        }
    }

    private boolean findMyVoice(String voice, String lang, String model) {
        List<Voice> voiceList = DataHolder.getInstance().getData();

        if (voice.equalsIgnoreCase("not-specified")) {
            // Use the params file first if the voice is unspecified
            voice = mParams.getParameters().getVoiceParams().getName();
            model = mParams.getParameters().getVoiceParams().getModel();
            lang = mParams.getParameters().getVoiceParams().getLanguage();
        }

        Log.d(TAG, "Looking for voice " + voice + " " + lang + " " + model);
        for (int i=0; i<voiceList.size(); i++) {
            if (voiceList.get(i).getName().equalsIgnoreCase(voice) &&
                voiceList.get(i).getLanguage().equalsIgnoreCase(lang) && 
                voiceList.get(i).getModel().equalsIgnoreCase(model)) {
                    myVoice = voiceList.get(i);
                    Log.d(TAG, "Found " + myVoice.getName() + " " + myVoice.getLanguage() + " " + myVoice.getModel());
                    return true;
                }
        }
        return false;
    }

    private ManagedChannel createChannel(String server) {
        ManagedChannel chan = ManagedChannelBuilder.forTarget(server)
                .useTransportSecurity()
                .build();

        return chan;
    }

    private SynthesizerGrpc.SynthesizerStub createConnection(ManagedChannel chan, final String accessToken) {
        SynthesizerGrpc.SynthesizerStub stub = SynthesizerGrpc.newStub(chan).withCallCredentials(new CallCredentials() {
            @Override
            public void applyRequestMetadata(RequestInfo r, Executor e, final MetadataApplier m) {
                e.execute(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            Metadata headers = new Metadata();
                            Metadata.Key<String> clientIdKey =
                                    Metadata.Key.of("Authorization", Metadata.ASCII_STRING_MARSHALLER);
                            headers.put(clientIdKey, accessToken);
                            m.apply(headers);
                        } catch (Throwable ex) {
                            //log the exception
                            ex.printStackTrace(System.out);
                        }
                    }
                });
            }

            @Override
            public void thisUsesUnstableApi() {
            }
        });
        return stub;
    }

    private void shutdown(ManagedChannel chan) throws InterruptedException {
        chan.shutdown().awaitTermination(2, TimeUnit.SECONDS);
    }

    private SynthesisRequest initializeSynthesisRequest(String textInput, String ssml) {
        TtsParams.Parameters parameters = mParams.getParameters();

        mSampleRate = myVoice.getSampleRateHz();
        AudioFormat audioFormat = AudioFormat.newBuilder()
        .setPcm(PCM.newBuilder().setSampleRateHz(mSampleRate).build())
        .build();
        Input ttsInput;
        if (ssml == null) {
            Text text = Text.newBuilder().setText(textInput).build();
            ttsInput = Input.newBuilder().setText(text).build();
        } else {
            SSML s = SSML.newBuilder().setText(ssml).build();
            ttsInput = Input.newBuilder().setSsml(s).build();
        }

        return SynthesisRequest.newBuilder()
                .setVoice(myVoice)
                .setAudioParams(AudioParameters.newBuilder()
                                .setAudioFormat(audioFormat))
                .setInput(ttsInput)
                .setEventParams(EventParameters.newBuilder()) // For simplicity, events not implemented...
                .build();
    }

    private IAudioSink.Listener mAudioListener = new IAudioSink.Listener() {
        @Override
        public void onPlayingStarted() {
            setState(State.PLAYING);
        }
        @Override
        public void onPlayingStopped() {
        }
        @Override
        public void onPlayingError(String s) {
        }
        @Override
        public void onPlay(byte[] data, int size) {
            bytesWritten -= size;
        }
    };

    private void synthesize(SynthesisRequest req) {

        try {
            mAudioSink = (IAudioSink)new Speaker(mAudioListener);
            done = new CountDownLatch(1);
            mAudioSink.start(mSampleRate);
            bytesWritten = 0;

            conn.synthesize(req, new StreamObserver<SynthesisResponse>() {
                @Override
                public void onCompleted() {
                    done.countDown();
                }
                @Override
                public void onError(Throwable T) {
                    Log.d(TAG, "onError " + T.toString());
                    done.countDown();
                }
                @Override
                public void onNext(SynthesisResponse resp) {
                    if (mState == State.IDLE) {
                        done.countDown();
                        return;
                    }
                    switch (resp.getResponseCase()) {
                        case STATUS:
                            Log.d(TAG, "received status");
                            Log.d(TAG, resp.getStatus().toString());
                            break;
                        case EVENTS:
                            Log.d(TAG, "received events");
                            Log.d(TAG, resp.getEvents().toString());
                            break;
                        case AUDIO:
                            Log.d(TAG, "received audio");
                            try {
                                mAudioSink.put(resp.getAudio().toByteArray(), resp.getAudio().toByteArray().length);
                                bytesWritten += resp.getAudio().toByteArray().length;
                            } catch (Exception e) {
                                e.printStackTrace(System.out);
                            }
                            break;
                        default:
                            break;
                    }
                }
            });
            /* Wait till we're finished
            */
            try {
                done.await();
            }
            catch(InterruptedException ie) {
                ie.printStackTrace();
            } finally {
                while (bytesWritten>0) Thread.sleep(100);
                stopPlaying();
            }
        } catch (Exception e) {
            stopPlaying();
            Log.d(TAG, "Error: %s" + e.getMessage());
            e.printStackTrace(System.out);
        }
    }    

    private void stopPlaying() {
        bytesWritten = 0;
        if (mAudioSink != null) {
            mAudioSink.stopPlayback();
            mAudioSink = null;
        }
        NuanceMixModule.playbackDone();
        setState(State.IDLE);
    }

    /**
     * Cancel the TTS transaction.
     */
    private void cancel() {
        stopPlaying();
    }

    /**
     * Set the mState and update the button text.
     */
    private void setState(final State newState) {
        mState = newState;
    }

    /**
     * Speak the text that is in the ttsText EditText, using the language in the language EditText.
     */
    private void getVoices() {
        final String configFile = Defaults.CONFIG_FILE;
        final String voicesList = null;

        try {
            // Load credentials from config file
            final Config c = new Config(configFile, ctx);
            final String server = c.getTtsUrl();
            Thread voicesThread = new Thread(new Runnable() {
                public void run() {
                    try {
                        // Authenticate and create a token
                        Authenticator a = new Authenticator(c.getConfiguration(), ctx);
                        Token t = a.Authenticate("tts");

                        // Create a connection
                        ManagedChannel chan = createChannel(server);
                        conn = createConnection(chan, String.format("%s %s", t.getTokenType(), t.getAccessToken()));
                        GetVoicesRequest req = GetVoicesRequest.newBuilder().build();

                        done = new CountDownLatch(1);
                        conn.getVoices(req, new StreamObserver<GetVoicesResponse>() {
                            @Override
                            public void onCompleted() {
                                done.countDown();
                            }
                            @Override
                            public void onError(Throwable T) {
                                Log.d(TAG, "onError getting voices " + T.toString());
                                done.countDown();
                            }
                            @Override
                            public void onNext(GetVoicesResponse response) {
                                DataHolder.getInstance().setData(response.getVoicesList());
                            }
                        });
                        /* Wait till we're finished
                        */
                        try {
                            done.await();
                        }
                        catch(InterruptedException ie) {
                            ie.printStackTrace();
                        } finally {
                
                        }
                        shutdown(chan);
                        voicesDone.countDown();
                    }
                    catch (Exception e) {
                        Log.d(TAG, e.toString());
                        setState(State.IDLE);
                        e.printStackTrace();
                        voicesDone.countDown();

                    }
                }
            });
            voicesThread.start();
        }
        catch (Exception e) {
            Log.d(TAG, "Error: %s" + e.getMessage());
            setState(State.IDLE);
            e.printStackTrace();
        }
    }

    private void synthesize(String textInput, String ssml) {
        final String configFile = Defaults.CONFIG_FILE;

        try {
            // Load credentials from config file
            final Config c = new Config(configFile, ctx);
            final String server = c.getTtsUrl();

            Thread ttsThread = new Thread(new Runnable() {
                public void run() {
                    try {
            
                        // Authenticate and create a token
                        Authenticator a = new Authenticator(c.getConfiguration(), ctx);
                        Token t = a.Authenticate("tts");

                        // Create a connection
                        ManagedChannel chan = createChannel(server);
                        conn = createConnection(chan, String.format("%s %s", t.getTokenType(), t.getAccessToken()));
                        SynthesisRequest req = initializeSynthesisRequest(textInput, ssml);
                        synthesize(req);
                        shutdown(chan);
                    }
                    catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            });
            ttsThread.start();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }
}

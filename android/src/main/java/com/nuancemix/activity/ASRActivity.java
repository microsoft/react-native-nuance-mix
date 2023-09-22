package com.nuancemix.activity;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.content.Context;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

import com.nuance.utils.*;
import com.nuance.audio.*;

import com.google.protobuf.ByteString;
import nuance.asr.v1.NuanceAsr.*;
import nuance.asr.v1.NuanceAsrResource.*;
import nuance.asr.v1.NuanceAsrResult.*;
import nuance.asr.v1.RecognizerGrpc;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

import io.grpc.CallCredentials;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.Metadata;
import io.grpc.stub.StreamObserver;

import com.nuancemix.NuanceMixModule;
/**
 */
public class ASRActivity {
    private final String TAG = "TAG-ASRActivity";
    private static Context ctx;

    private enum State {
        IDLE,
        LISTENING,
        PROCESSING
    }
    private State mState = State.IDLE;

    public class Defaults {
        static final String CONFIG_FILE = "config.json";
        static final String PARAMS_FILE = "params.asr.json";
    }

    private static class VADEvent {
        private static final int NO_EVENT = 0;
        private static final int SPEECH_DETECTED = 1;
        private static final int END_OF_SPEECH_DETECTED = 2;
        private static final int SPEECH_CONFIRMED = 3;
    }

    private RecognizerGrpc.RecognizerStub conn;
    private StreamObserver<RecognitionRequest> mRecoRequests;
    private static IAudioSource mAudioSource = null;
    private CountDownLatch done;
    private AsrParams mParams;
    private String myLanguage;

    public ASRActivity(Context ctx) {
        loadAsr(ctx);
    }

    public void loadAsr(Context context) {
        ctx = context;

        mParams = new AsrParams(Defaults.PARAMS_FILE, ctx);

        setState(State.IDLE);
    }

    /* State Logic: IDLE -> LISTENING -> PROCESSING -> repeat */
    public void toggleReco(String language) {
        switch (mState) {
            case IDLE:
                if (language != null) {
                    myLanguage = language;
                } else {
                    myLanguage = mParams.getParameters().getLanguage();
                }
                recognize();
                setState(State.LISTENING);
                break;
            case LISTENING:
                if (mAudioSource != null) {
                    mAudioSource.stop();
                }
                setState(State.PROCESSING);
                break;
            case PROCESSING:
                if (mAudioSource != null) {
                    mAudioSource.stop();
                }
                setState(State.IDLE);
                break;
        }
    }

    /**
     * Set the mState and update the button text.
     */
    private void setState(final State newState) {
        mState = newState;

        switch (newState) {
            case IDLE:
                break;
            case LISTENING:
                startAudioLevelPoll();
                break;
            case PROCESSING:
                stopAudioLevelPoll();
                break;
        }
    }

    private ManagedChannel createChannel(String server) {
        ManagedChannel chan = ManagedChannelBuilder.forTarget(server)
                                                    .useTransportSecurity()
                                                    .build();

        return chan;
    }

    private RecognizerGrpc.RecognizerStub createConnection(ManagedChannel chan, final String accessToken) {
        RecognizerGrpc.RecognizerStub stub = RecognizerGrpc.newStub(chan).withCallCredentials(new CallCredentials() {
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

    private void recognize() {
        try {
            final Config c = new Config(Defaults.CONFIG_FILE, ctx);

            Thread asrThread = new Thread(new Runnable() {
                public void run() {
                    try {
            
                        // Authenticate and create a token
                        Authenticator a = new Authenticator(c.getConfiguration(), ctx);
                        Token t = a.Authenticate("asr");
                        
                        // Create a connection
                        ManagedChannel chan = createChannel(c.getAsrUrl());
                        conn = createConnection(chan, String.format("%s %s", t.getTokenType(), t.getAccessToken()));
                        
                        // Run the ASR request
                        RecognitionParameters params = initializeRecognitionRequest();
                        recognize(params);
                        shutdown(chan);
                    }
                    catch (Exception e) {
                        Log.d(TAG, e.toString());
                        e.printStackTrace();
                    }
                }
            });
            asrThread.start();
        } catch (Exception e) {
            Log.d(TAG, e.toString());
            e.printStackTrace();
        }
    }

    private void shutdown(ManagedChannel chan) throws InterruptedException {
        chan.shutdown().awaitTermination(2, TimeUnit.SECONDS);
    }

    private final IAudioSource.Listener mAudioListener = new IAudioSource.Listener() {
        @Override
        public void onRecordingStarted() {
            Log.d(TAG, "Recording started");
            setState(State.LISTENING);
        }

        @Override
        public void onRecordingStopped(boolean timedOut) {
            Log.d(TAG, "Recording stopped.");
            mRecoRequests.onCompleted();
            setState(State.PROCESSING);
        }

        @Override
        public void onRecordingError(String s) {
            Log.d(TAG, "Recording error: " + s);
            mRecoRequests.onCompleted();
        }

        @Override
        public void onRecord(final byte[] data, final int size, int vad_event) {

            Log.d(TAG, "onRecord");
            switch (vad_event) {
                case VADEvent.SPEECH_DETECTED:
                    Log.d(TAG, "OpusVAD maybe speech");
                break;
                case VADEvent.END_OF_SPEECH_DETECTED:
                    Log.d(TAG, "OpusVAD end of speech");
                    mAudioSource.stop();
                return;
                case VADEvent.SPEECH_CONFIRMED:
                    Log.d(TAG, "OpusVAD speech Confirmed");
                break;
            }
            RecognitionRequest req = RecognitionRequest.newBuilder()
                                                    .setAudio(ByteString.copyFrom(data)).build();
            mRecoRequests.onNext(req);
        }
    };

    private RecognitionParameters initializeRecognitionRequest() {
        AsrParams.Parameters parameters = mParams.getParameters();
        AsrParams.RecognitionFlags flags = parameters.getRecognitionFlags();

        AudioFormat audioFormat = AudioFormat.newBuilder()
        .setPcm(PCM.newBuilder().setSampleRateHz(16000).build())
        .build();
        return RecognitionParameters.newBuilder()
                                    .setAudioFormat(audioFormat)
                                    .setLanguage(myLanguage)
                                    .setTopic(parameters.getTopic())
                                    .setUtteranceDetectionMode(EnumUtteranceDetectionMode.forNumber(parameters.getUtteranceDetectionMode()))
                                    .setResultType(EnumResultType.forNumber(parameters.getUtteranceDetectionMode()))
                                    .setNoInputTimeoutMs(parameters.getNoInputTimeoutMs())
                                    .setRecognitionTimeoutMs(parameters.getRecognitionTimeoutMs())
                                    .setUtteranceEndSilenceMs(parameters.getUtteranceEndSilenceMs())
                                    .setMaxHypotheses(parameters.getMaxHypotheses())
                                    .setRecognitionFlags(RecognitionFlags.newBuilder()
                                                                    .setAutoPunctuate(flags.isAutoPunctuate())
                                                                    .setFilterProfanity(flags.isFilterProfanity())
                                                                    .setIncludeTokenization(flags.isIncludeTokenization())
                                                                    .setStallTimers(flags.isSmallTimers())
                                                                    .setDiscardSpeakerAdaptation(flags.isDiscardSpeakerAdaptation())
                                                                    .setSuppressCallRecording(flags.isSuppressCallRecording())
                                                                    .setMaskLoadFailures(flags.isMaskLoadFailures())
                                                                    .build())
                                    .build();
    }

    private void recognize(RecognitionParameters params) {
        RecognitionInitMessage init = RecognitionInitMessage.newBuilder()
                                                        .setParameters(params)
                                                        .build();
        RecognitionRequest request = RecognitionRequest.newBuilder()
                                                    .setRecognitionInitMessage(init)
                                                    .build();
        done = new CountDownLatch(1);
        mRecoRequests = conn.recognize(new StreamObserver<RecognitionResponse>() {
            @Override
            public void onCompleted() {
                Log.d(TAG, "onCompleted");
                NuanceMixModule.recordingDone();
                done.countDown();
            }
            @Override
            public void onError(Throwable T) {
                T.printStackTrace(System.out);
                done.countDown();
            }
            @Override
            public void onNext(RecognitionResponse response) {
                switch (response.getResponseUnionCase()) {
                    case RESULT:
                        Result result = response.getResult();
                        Log.d(TAG, String.format("Transcription [%s]: [conf: %f] %s", 
                        result.getResultType(), 
                        result.getHypotheses(0).getAverageConfidence(),
                        result.getHypotheses(0).getFormattedText()));
                        NuanceMixModule.recognitionResultsAvailable(result.getHypotheses(0).getFormattedText());
                        if (result.getResultTypeValue() == EnumResultType.FINAL_VALUE) {
                            done.countDown();
                        }
                        break;
                    case START_OF_SPEECH:
                        StartOfSpeech sos = response.getStartOfSpeech();
                        Log.d(TAG, String.format("Start of Speech detected: %dms", sos.getFirstAudioToStartOfSpeechMs()));
                        break;
                    case STATUS:
                        Status status = response.getStatus();
                        Log.d(TAG, String.format("Recognition Status: %d %s", status.getCode(), status.getMessage()));
                        break;
                    default:
                        break;
                }
            }
        });

        mRecoRequests.onNext(request);

        try {
            mAudioSource = new Microphone(mAudioListener, Microphone.Codecs.PCM);
            mAudioSource.start();
        }
        catch (Exception e) {
            e.printStackTrace();
            done.countDown();
        }

        try {
            done.await();
        } catch (Exception e) {
            Log.d(TAG, e.getMessage());
        } finally {
            if (mAudioSource != null) {
                mAudioSource.stop();
            }
        }
        setState(State.IDLE);        
    }

     /* Audio Level Polling */
     private static final Handler handler = new Handler();
     /**
      * Every 50 milliseconds we should update the volume meter in our UI.
      */
     private static final Runnable audioPoller = new Runnable() {
         @Override
         public void run() {
             try {
                 float level = (float)mAudioSource.getEnergyLevel();
//                 volumeBar.setProgress((int)level);
                 handler.postDelayed(audioPoller, 50);
             } catch (Exception e) {
                 // ignore...
             }
         }
     };
 
     /**
      * Start polling the users audio level.
      */
     private static void startAudioLevelPoll() {
         audioPoller.run();
     }
 
     /**
      * Stop polling the users audio level.
      */
     private static void stopAudioLevelPoll() {
         handler.removeCallbacks(audioPoller);
//         volumeBar.setProgress(0);
     }
}

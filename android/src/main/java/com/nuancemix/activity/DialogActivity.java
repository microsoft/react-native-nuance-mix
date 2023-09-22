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

import com.google.protobuf.ByteString;
import com.google.protobuf.Struct;
import com.google.protobuf.Value.Builder;

import com.nuance.coretech.dialog.v1.common.messages.DAAction;
import com.nuance.coretech.dialog.v1.common.messages.ExecuteRequestPayload;
import com.nuance.coretech.dialog.v1.common.messages.ExecuteResponsePayload;
import com.nuance.coretech.dialog.v1.common.messages.Message;
import com.nuance.coretech.dialog.v1.common.messages.RequestData;
import com.nuance.coretech.dialog.v1.common.messages.Selector;
import com.nuance.coretech.dialog.v1.common.messages.StartRequestPayload;
import com.nuance.coretech.dialog.v1.common.messages.StartResponsePayload;
import com.nuance.coretech.dialog.v1.common.messages.UserInput;
import com.nuance.coretech.dialog.v1.service.messages.AsrParamsV1;
import com.nuance.coretech.dialog.v1.service.messages.ExecuteRequest;
import com.nuance.coretech.dialog.v1.service.messages.ExecuteResponse;
import com.nuance.coretech.dialog.v1.service.messages.StartRequest;
import com.nuance.coretech.dialog.v1.service.messages.StartResponse;
import com.nuance.coretech.dialog.v1.service.messages.StopRequest;
import com.nuance.coretech.dialog.v1.service.messages.StopResponse;
import com.nuance.coretech.dialog.v1.service.messages.StreamInput;
import com.nuance.coretech.dialog.v1.service.messages.StreamOutput;
import com.nuance.coretech.dialog.v1.service.messages.TtsParamsV1;
import com.nuance.coretech.dialog.v1.service.DialogServiceGrpc;

import com.nuance.utils.*;
import com.nuance.audio.*;

import java.util.StringTokenizer;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

import io.grpc.CallCredentials;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.Metadata;
import io.grpc.stub.StreamObserver;
import nuance.asr.v1.NuanceAsr;
import nuance.asr.v1.NuanceAsrResult;
import nuance.asr.v1.NuanceAsrResult.Result;
import nuance.tts.v1.NuanceTtsV1.AudioParameters;
import nuance.tts.v1.NuanceTtsV1.SynthesisResponse;

import com.nuancemix.NuanceMixModule;

/**
 * Created by peter_freshman on 9/21/16.
 */
public class DialogActivity {
    private final String TAG = "TAG-DialogActivity";
    private static Context ctx;

    public enum State {
        IDLE, RESPONDING, LISTENING, PLAYING, PROCESSING
    }
    private State mState = State.IDLE;

    private enum PayloadCase {
        PROMPT,
        DATA,
        PAYLOAD_NOT_SET
    }

    public class Defaults {
        static final String CONFIG_FILE = "config.json";
        static final String ASR_PARAMS_FILE = "params.asr.json";
        static final String NLU_PARAMS_FILE = "params.nlu.json";
        static final String TTS_PARAMS_FILE = "params.tts.json";
    }

    private static class VADEvent {
        private static final int NO_EVENT = 0;
        private static final int SPEECH_DETECTED = 1;
        private static final int END_OF_SPEECH_DETECTED = 2;
        private static final int SPEECH_CONFIRMED = 3;
    }

    private DialogServiceGrpc.DialogServiceStub dlgConn;
    private StreamObserver<StreamInput> mRecoRequests;
    private Selector selector;

    private IAudioSink mAudioSink = null;
    private long bytesWritten = 0;
    private final int mSampleRate = 22050;
    private static IAudioSource mAudioSource = null;
    private CountDownLatch done;
    private CountDownLatch ttsDone;
    private CountDownLatch alertDone;

    private AsrParams mAsrParams;
    private NluParams mNluParams;
    private TtsParams mTtsParams;

    private static String mTopResult;
    private static String prompt;
    private boolean dialogEnding;
    private String sessionId;

    private String contextTag;
    private String language;

    public DialogActivity(Context context) {
        loadDialog(context);
    }

    public void loadDialog(Context context) {
        ctx = context;

        mAsrParams = new AsrParams(Defaults.ASR_PARAMS_FILE, ctx);
        mNluParams = new NluParams(Defaults.NLU_PARAMS_FILE, ctx);
        mTtsParams = new TtsParams(Defaults.TTS_PARAMS_FILE, ctx);

        contextTag = mNluParams.getParameters().getContext();
        language = mNluParams.getParameters().getLanguage();

        setState(State.IDLE);
    }

    /* State Logic: IDLE -> RESPONDING -> PLAYING -> LISTENING -> PROCESSING -> RESPONDING repeat */
    public void toggleReco(String input, String contextTag) {
        Log.d(TAG, "toggleReco state " + mState.toString() + " with input " + input + " and contextTag " + contextTag);
        switch (mState) {
        case IDLE:
            dialogEnding = false;
            setState(State.PROCESSING);
            StartDialog(contextTag);
            break;
        case RESPONDING:
            final Thread dlgThread = new Thread(new Runnable() {
                public void run() {
                    if (input == null || input.isEmpty()) {
                        setState(State.LISTENING);
                        recognize(initializeRecognitionParameters());
                    } else {
                        NuanceMixModule.dialogRequest(input);
                        setState(State.RESPONDING);
                        Respond(input, PayloadCase.PROMPT, null);
                    }
                }
            });
            dlgThread.start();
        case PLAYING:
            stopPlaying();
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
            setState(State.RESPONDING);
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
        case RESPONDING:
            break;
        case PLAYING:
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
        return ManagedChannelBuilder.forTarget(server).useTransportSecurity().build();
    }

    private void shutdown(final ManagedChannel chan) throws InterruptedException {
        chan.shutdown().awaitTermination(2, TimeUnit.SECONDS);
    }

    private DialogServiceGrpc.DialogServiceStub createDlgConnection(final ManagedChannel chan,
            final String accessToken) {
        final DialogServiceGrpc.DialogServiceStub stub = DialogServiceGrpc.newStub(chan)
                .withCallCredentials(new CallCredentials() {
                    @Override
                    public void applyRequestMetadata(final RequestInfo r, final Executor e, final MetadataApplier m) {
                        e.execute(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    final Metadata headers = new Metadata();
                                    Metadata.Key<String> clientIdKey = Metadata.Key.of("Authorization",
                                            Metadata.ASCII_STRING_MARSHALLER);
                                    headers.put(clientIdKey, accessToken);
                                    m.apply(headers);
                                } catch (final Throwable ex) {
                                    // log the exception
                                    // ex.printStackTrace(System.out);
                                    Log.d(TAG, ex.toString());
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

    private void StartDialog(String context) {
        sessionId = null;

        try {
            String ctxTag = contextTag;
            if (context != null) {
                ctxTag = context;
            }
            final String lang = language;

            final String modelUrn = String.format("urn:nuance-mix:tag:model/%s/mix.dialog", ctxTag);
            // Load credentials from config file
            final Config c = new Config(Defaults.CONFIG_FILE, ctx);

            final Thread dlgThread = new Thread(new Runnable() {
                public void run() {
                    try {
                        // Authenticate and create a token
                        final Authenticator a = new Authenticator(c.getConfiguration(), ctx);
                        final Token t = a.Authenticate("dlg");

                        // Create a connection
                        final ManagedChannel chan = createChannel(c.getDialogUrl());
                        dlgConn = createDlgConnection(chan,
                                String.format("%s %s", t.getTokenType(), t.getAccessToken()));

                        final StartRequestPayload payload = StartRequestPayload.newBuilder()
                                .setModelRef(com.nuance.coretech.dialog.v1.common.messages.ResourceReference.newBuilder().setUri(modelUrn))
                                .build();
                        selector = Selector.newBuilder().setLanguage("en-US").setChannel("default")
                                .setLibrary("default").build();

                        final StartRequest start = StartRequest.newBuilder().setPayload(payload).setSelector(selector)
                                .build();

                        done = new CountDownLatch(1);
                        dlgConn.start(start, new StreamObserver<StartResponse>() {
                            @Override
                            public void onCompleted() {
                                done.countDown();
                            }

                            @Override
                            public void onError(final Throwable T) {
                                Log.d(TAG, T.toString());
                                done.countDown();
                            }

                            @Override
                            public void onNext(final StartResponse response) {
                                final StartResponsePayload payload = response.getPayload();
                                sessionId = payload.getSessionId();
                                Log.d(TAG, String.format("Dialog started [session id: %s]", sessionId));
                            }
                        });

                        try {
                            done.await();
                        } catch (final InterruptedException e) {
                            // ignore
                        }
                        InitializeDialog();
                        setState(State.RESPONDING);
                    } catch (final Exception e) {
                        setState(State.IDLE);
                        Log.d(TAG, "StartDialog exception " + e.toString());
                    }
                }
            });
            dlgThread.start();
        } catch (final Exception e) {
            Log.d(TAG, "StartDialog outer exception " + e.toString());
        }
        return;
    }

    private void ExecuteStream(StreamInput streamInput, boolean play, boolean record) {
        try {
            if (play) {
                mAudioSink = (IAudioSink)new Speaker(mAudioSinkListener);
                mAudioSink.start(mSampleRate);
                bytesWritten = 0;
            }

            done = new CountDownLatch(1);
            mRecoRequests = dlgConn.executeStream(new StreamObserver<StreamOutput>() {

                @Override
                public void onCompleted() {
                    done.countDown();
                }

                @Override
                public void onError(final Throwable T) {
                    Log.d(TAG, "onError " + T.getMessage());
                    done.countDown();
                }

                @Override
                public void onNext(final StreamOutput response) {
                    if (response.hasAsrResult()) {
                        final Result result;
                        result = response.getAsrResult();
                        Log.d(TAG, String.format("Transcription [%s]: [conf: %f] %s", 
                                            result.getResultType(), 
                                            result.getHypotheses(0).getAverageConfidence(),
                                            result.getHypotheses(0).getFormattedText()));
                        NuanceMixModule.dialogPartial(result.getHypotheses(0).getFormattedText());
                        if (result.getResultType() == NuanceAsrResult.EnumResultType.FINAL) {
                            mAudioSource.stop();
                            NuanceMixModule.dialogRequest(result.getHypotheses(0).getFormattedText());
                        }
                    }
                    if (response.hasResponse()) {
                        HandleExecuteResponse(response.getResponse());                        
                    }
                    if (response.hasAudio()) {
                        setState(State.PLAYING);
                        SynthesisResponse resp = response.getAudio();
                        switch (resp.getResponseCase()) {
                            case STATUS:
                                break;
                            case EVENTS:
                                break;
                            case AUDIO:
                                try {
                                    Log.d(TAG, resp.toString());
                                    Log.d(TAG, resp.getStatus().toString());
                                    Log.d(TAG, resp.getEvents().toString());
                                    Log.d(TAG, resp.toString());
                                    mAudioSink.put(resp.getAudio().toByteArray(), resp.getAudio().toByteArray().length);
                                    bytesWritten += resp.getAudio().toByteArray().length;
                                } catch (Exception e) {
                                    Log.d(TAG, "onNext exception " + e.toString());
                                    e.printStackTrace(System.out);
                                }
                                break;
                            default:
                                break;
                        }
                    }
                }
            });

            mRecoRequests.onNext(streamInput);
            if (record) {
                try {
                    mAudioSource = new Microphone(mAudioSourceListener, Microphone.Codecs.PCM);
                    mAudioSource.start();
                } catch (final Exception e) {
                    Log.d(TAG, "Microphone exceptiosn " + e.toString());
                    done.countDown();
                }    
            } else {
                mRecoRequests.onCompleted();
            }

            try {
                done.await();
            } catch (InterruptedException e) {
                // ignore
            } finally {
                if (record) {
                    if (mAudioSource != null) {
                        mAudioSource.stop();
                    }
                }
            }

        } catch (Exception e) {
            if (play) {
                stopPlaying();
            }
            Log.d(TAG, "Error: " + e.getMessage());
        } finally {
            try {
                if (play) {
                    while (bytesWritten>0) Thread.sleep(100);
                    stopPlaying();
                }
            } catch (InterruptedException ie) {
            }
        }
    }

    private void InitializeDialog() {
        // send Execute request
        ExecuteRequestPayload payload = ExecuteRequestPayload.newBuilder().build();

        final ExecuteRequest request = ExecuteRequest.newBuilder().setPayload(payload).setSelector(selector)
                .setSessionId(sessionId).build();
        final StreamInput streamInput = StreamInput.newBuilder().setTtsControlV1(initializeSynthesisParameters()).setRequest(request).build();

        ExecuteStream(streamInput, true, false);
    }


    // Currently no indication of when the dialog ends...
    public void StopDialog() {
        final StopRequest stop = StopRequest.newBuilder().build();

        stopPlaying();

        done = new CountDownLatch(1);
        dlgConn.stop(stop, new StreamObserver<StopResponse>() {
            @Override
            public void onCompleted() {
                done.countDown();
            }

            @Override
            public void onError(final Throwable T) {
                Log.d(TAG, T.toString());
                done.countDown();
            }

            @Override
            public void onNext(final StopResponse response) {
            }
        });

        try {
            done.await();
        } catch (final InterruptedException ie) {
            // ignore
        }
    }

    private void HandleExecuteResponse(final ExecuteResponse response) {
        RequestData.Builder requestData = RequestData.newBuilder();
        Builder ret = com.google.protobuf.Value.newBuilder();
        ret.setStringValue("0");
        boolean hasData = false;
        final ExecuteResponsePayload payload = response.getPayload();
        prompt = null;
        if (payload.hasDaAction()) {
            DAAction action = payload.getDaAction();
            hasData = true;
            // Starting with a 'get' indicates we should return data
            StringTokenizer toks = new StringTokenizer(action.getId().toString(), "_");
            if (toks.nextToken().equals("get")) {
                Log.d(TAG, "Data requested " + action.getId());
            } else {
                // Otherwise we're being provided data
                if (action.getId().toString().equals("set_s_endDialog")) {
                    dialogEnding = true;
                }  
                Struct.Builder struct = Struct.newBuilder();
                struct.putFields("returnCode", ret.build());
                requestData.mergeData(struct.build());
            }
        } 
        for (Message msg : payload.getMessagesList()) {
            for (int i=0; i < msg.getVisualCount(); i++) {
                if (prompt == null) {
                    prompt = msg.getVisual(i).getText();
                } else {
                    prompt = String.format("%s %s", prompt, msg.getVisual(i).getText());
                }
            }
        }
        if (payload.hasQaAction()) {
            if( payload.getQaAction().getMessage().getVisualCount() > 0) {
                if (prompt == null) {
                    prompt = payload.getQaAction().getMessage().getVisual(0).getText();
                } else {
                    prompt = String.format("%s %s", prompt, payload.getQaAction().getMessage().getVisual(0).getText());
                }
            }
        }
        if (hasData && !dialogEnding) {
            Respond(null, PayloadCase.DATA, requestData.build());
        } else if (prompt != null) {
            NuanceMixModule.dialogResponse(prompt);
            Log.d(TAG, prompt);
        }
        if (payload.hasEndAction()) {
            dialogEnding = true;
        }
        if (dialogEnding) {
            NuanceMixModule.dialogEnded();
            setState(State.IDLE);
        }
    }

    private void Respond(final String inputText, final PayloadCase payloadType, final RequestData requestData) {
        ExecuteRequestPayload payload = null;

        switch (payloadType) {
            case PROMPT:
                final UserInput input = UserInput
                        .newBuilder().setUserText(inputText).build();
                payload = ExecuteRequestPayload.newBuilder().setUserInput(input).build();
                break;
            case DATA:
                payload = ExecuteRequestPayload.newBuilder().setRequestedData(requestData).build();
            break;
            default:
                payload = ExecuteRequestPayload.newBuilder().build();
                break;
        }

        final ExecuteRequest request = ExecuteRequest.newBuilder().setPayload(payload).setSelector(selector)
                .setSessionId(sessionId).build();

        final StreamInput streamInput = StreamInput.newBuilder()
                .setTtsControlV1(initializeSynthesisParameters()).setRequest(request).build();

        ExecuteStream(streamInput, true, false);
    }

    private TtsParamsV1 initializeSynthesisParameters() {
        final TtsParams.Parameters parameters = mTtsParams.getParameters();

        final nuance.tts.v1.NuanceTtsV1.AudioFormat audioFormat = nuance.tts.v1.NuanceTtsV1.AudioFormat.newBuilder()
                .setPcm(nuance.tts.v1.NuanceTtsV1.PCM.newBuilder().setSampleRateHz(mSampleRate).build()).build();

        return TtsParamsV1.newBuilder()
                            .setAudioParams(AudioParameters.newBuilder()
                            .setAudioFormat(audioFormat))
                .build();
    }

    private final IAudioSink.Listener mAudioSinkListener = new IAudioSink.Listener() {
        @Override
        public void onPlayingStarted() {
        }

        @Override
        public void onPlayingStopped() {
            if (dialogEnding) {
                setState(State.IDLE);
            } else {
                setState(State.RESPONDING);
            }
        }

        @Override
        public void onPlayingError(final String s) {
        }

        @Override
        public void onPlay(final byte[] data, final int size) {
            bytesWritten -= size;
        }
    };

    public void stopRecording() {
        if (mAudioSource != null) {
            stopAudioLevelPoll();
            mAudioSource.stop();
            mAudioSource = null;
        }
    }

    public void stopPlaying() {
        bytesWritten = 0;
        if (mAudioSink != null) {
            mAudioSink.stopPlayback();
            mAudioSink = null;
        }
        if (dialogEnding) {
            setState(State.IDLE);
        } else {
            setState(State.RESPONDING);
        }
    }

    /**
     * Cancel the TTS transaction.
     */
    private void cancel() {
        stopPlaying();
    }

    private final IAudioSource.Listener mAudioSourceListener = new IAudioSource.Listener() {
        @Override
        public void onRecordingStarted() {
            setState(State.LISTENING);
        }

        @Override
        public void onRecordingStopped(final boolean timedOut) {
            mRecoRequests.onCompleted();
            setState(State.PROCESSING);
            NuanceMixModule.dialogRecordingDone();
        }

        @Override
        public void onRecordingError(final String s) {
            mRecoRequests.onCompleted();
        }

        @Override
        public void onRecord(final byte[] data, final int size, final int vad_event) {

                switch (vad_event) {
                case VADEvent.SPEECH_DETECTED:
                    break;
                case VADEvent.END_OF_SPEECH_DETECTED:
                    mAudioSource.stop();
                    return;
                case VADEvent.SPEECH_CONFIRMED:
                    break;
                }
            StreamInput streamInput = StreamInput.newBuilder().setAudio(ByteString.copyFrom(data)).build();
            mRecoRequests.onNext(streamInput);
        }
    };

    private AsrParamsV1 initializeRecognitionParameters() {
        final AsrParams.Parameters parameters = mAsrParams.getParameters();
        final AsrParams.RecognitionFlags flags = parameters.getRecognitionFlags();

        final NuanceAsr.AudioFormat audioFormat = NuanceAsr.AudioFormat.newBuilder()
                .setPcm(NuanceAsr.PCM.newBuilder().setSampleRateHz(16000).build()).build();
        
        return AsrParamsV1.newBuilder()
                                    .setAudioFormat(audioFormat)
                                    .setUtteranceDetectionMode(NuanceAsr.EnumUtteranceDetectionMode.forNumber(parameters.getUtteranceDetectionMode()))
                                    .setResultType(NuanceAsrResult.EnumResultType.forNumber(parameters.getResultType()))
                                    .setRecognitionFlags(NuanceAsr.RecognitionFlags.newBuilder()
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

    private void recognize(final AsrParamsV1 params) {
        ExecuteRequestPayload payload;

        payload = ExecuteRequestPayload.newBuilder().build();        
        final ExecuteRequest request = ExecuteRequest.newBuilder().setPayload(payload).setSelector(selector)
                .setSessionId(sessionId).build();
        final StreamInput streamInput = StreamInput.newBuilder()
                                            .setAsrControlV1(params)
                                            .setTtsControlV1(initializeSynthesisParameters())
                                            .setRequest(request).build();

        ExecuteStream(streamInput, true, true);
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
                final float level = (float) mAudioSource.getEnergyLevel();
                handler.postDelayed(audioPoller, 50);
            } catch (final Exception e) {
                // ignore...
            }
        }
    };

    public void stop() {
        stopRecording();
        stopPlaying();
    }

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
    }
}

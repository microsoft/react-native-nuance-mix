package com.nuance.audio;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.media.ToneGenerator;
import android.util.Log;

import com.nuance.opusvad.jni.OpusVAD;
import com.nuance.opusvad.jni.OpusVADResult;
import com.nuance.utils.Timer;

/**
 * The Class Microphone. A concrete implementation of AbstractAudioSource.
 *
 * <p>Use this class to stream audio from the microphone.
 */
public class Microphone extends AbstractAudioSource {

  private final String TAG = "TAG-Microphone";

  /** The built-in speaker data line that audio will be read from. */
  private AudioRecord mRecorder = null;

  public static class VADEvent {
    public static final int NO_EVENT = 0;
    public static final int SPEECH_DETECTED = 1;
    public static final int END_OF_SPEECH_DETECTED = 2;
    public static final int SPEECH_CONFIRMED = 3;
  }

  public enum Codecs {
    PCM,
    OPUS
  }

  private Timer mRecordingTimer = null;
  private long mRecordingTimeout = 0;
  private boolean mRecordingTimedOut = false;

  private final int mSampleRate = 16000;
  private final int mChannelConfig = AudioFormat.CHANNEL_IN_MONO;
  private final int mAudioFormat = AudioFormat.ENCODING_PCM_16BIT;
  private final int mAudioBufferSize = 640;//AudioRecord.getMinBufferSize(mSampleRate, mChannelConfig, mAudioFormat) / 2;

  private boolean mRecording = false;

  private double mEnergyLevel = 0.0;

  OpusVAD vad = null;
  OpusVADResult vadResult = null;
  private Codecs codec = Codecs.PCM;

  public boolean isRecording() {
      return mRecording;
  }

  /**
   * Instantiates a new microphone.
   *
   * @param listener the listener
   * @throws Exception the exception
   */
  public Microphone(final Listener listener, Codecs codec) throws Exception {
    super(listener);
    this.mRecorderListener = listener;
    Log.d(TAG, "AudioRecorder audio buffer size: " + mAudioBufferSize);

    this.codec = codec;
    try {
        vad = new OpusVAD();
        vadResult = new OpusVADResult();

        Log.d(TAG, "VAD Leading buffer sample size: " + vad.getMaxBufferSamples());
        Log.d(TAG, "VAD Frame samples: " + vad.getFrameSamples());
        Log.d(TAG, "VAD Frame bytes: " + vad.getFrameBytes());
        Log.d(TAG, "VAD Opus audio frequency: " + OpusVAD.AUDIO_FREQ);
        Log.d(TAG, "VAD Opus sample bytes: " + OpusVAD.SAMPLE_BYTES);
        Log.d(TAG, "VAD Leading buffer sample count: " + vad.getMaxBufferSamples() / vad.getFrameBytes());
    } catch (Exception e) {
        e.printStackTrace();
    }

  }


  private double getSNR(double RMS) {
    return ( 20 * Math.log10(RMS) );
  }

  private double calculateSimpleRMS(byte[] buffer, int size) {
      double rms = 0.0;

      for(int i=0; i < size; i++) {
          rms += buffer[i] * buffer[i];
      }

      rms = Math.sqrt((rms/buffer.length));

      return rms;
  }
  private void calculateEnergyLevel(byte[] audio, int size) {
      double rms = calculateSimpleRMS(audio, size);
      mEnergyLevel = rms - getSNR(rms);
  }

  public double getEnergyLevel() {
      return mEnergyLevel;
  }

  private void startRecordingTimer() {
      if( mRecordingTimer != null && mRecordingTimeout > 0 )
          mRecordingTimer.start(mRecordingTimeout, new Timer.Listener() {

              @Override
              public void onStarted(long start) {
                  Log.d(TAG, "Recording timer started!");
              }

              @Override
              public void onCancelled(long duration) {
                  Log.d(TAG, "Recording timer cancelled!");
              }

              @Override
              public void onExpired(long duration) {
                  Log.d(TAG, "Recording timer expired! " + (duration / 1000F));
                  mRecordingTimedOut = true;
                  stopListening();
              }
          });
  }

  public void startListening() {
      startListening(0);
  }

  public void startListening(long timeoutInMs) {
      mRecordingTimeout = timeoutInMs;
      mRecordingTimedOut = false;

      if( timeoutInMs > 0 )
          mRecordingTimer = new Timer();
      else
          mRecordingTimer = null;

      start();
  }

  public void resetRecordingTimer(long timeoutInMs) {
      mRecordingTimeout = (timeoutInMs == 0) ? mRecordingTimeout : timeoutInMs;
      if( mRecordingTimer != null ) {

          mRecordingTimedOut = false;
          mRecordingTimer.cancel();
          if( timeoutInMs == 0 )
              mRecordingTimer.reset();
          else
              mRecordingTimer.reset(mRecordingTimeout);
      }
  }

  public void resetRecordingTimer() {
      resetRecordingTimer(0);
  }

  public void stop() {
    stopListening();
  }

  public void stopListening() {
      Log.d(TAG, "AudioRecord is being stopped");

      mRecording = false;

      if( mRecorder == null || mRecorder.getRecordingState() != AudioRecord.RECORDSTATE_RECORDING ) {
          Log.v(TAG, "Recorder cannot be stopped.");
          return;
      }

      mRecorder.stop();
      mRecorderListener.onRecordingStopped(mRecordingTimedOut);

      if( mRecordingTimer != null )
          mRecordingTimer.cancel();

      mRecordingTimer = null;
      mRecorder.release();
  }

  private final AudioRecord.OnRecordPositionUpdateListener mListener = new AudioRecord.OnRecordPositionUpdateListener() {

    public void onPeriodicNotification(AudioRecord recorder) {
        Log.v(TAG, "in onPeriodicNotification");
    }

    public void onMarkerReached(AudioRecord recorder) {
        Log.v(TAG, "in onMarkerReached");
    }
};

  /*
   * (non-Javadoc)
   */
  @Override
  protected void record() {
    mRecording = true;
    byte[] buffer = new byte[mAudioBufferSize];
    byte[] opusEncodedBuffer = new byte[mAudioBufferSize];

    mRecorder = new AudioRecord(MediaRecorder.AudioSource.MIC,
            mSampleRate,
            mChannelConfig,
            mAudioFormat,
            mAudioBufferSize);
    Log.d(TAG, "Recorder initialized");

    mRecorder.setNotificationMarkerPosition(10000);
    mRecorder.setPositionNotificationPeriod(1000);
    mRecorder.setRecordPositionUpdateListener(mListener);

    int audioRecordState = mRecorder.getState();
    if (audioRecordState != AudioRecord.STATE_INITIALIZED) {
        Log.e(TAG, "AudioRecord is not properly initialized "+ audioRecordState);
        mRecording = false;
        mRecorderListener.onRecordingError("AudioRecord is not properly initialized");
        return;
    } else {
        Log.v(TAG, "AudioRecord is initialized");
    }

    mRecorder.startRecording();

    if( mRecorder.getRecordingState() != AudioRecord.RECORDSTATE_RECORDING ) {
        Log.v(TAG, "AudioRecord is is not recording");
        mRecorderListener.onRecordingError("AudioRecord is not recording");
        return;
    } else {
        Log.v(TAG, "AudioRecorder has started recording...");

        // Notify user with a beep...
        final ToneGenerator tg = new ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100);
        tg.startTone(ToneGenerator.TONE_PROP_BEEP);

        startRecordingTimer();
        mRecorderListener.onRecordingStarted();
    }


    while(mRecording) {
        //reading data from MIC into buffer
        int nRead = mRecorder.read(buffer, 0, buffer.length);
        Log.d(TAG, "Bytes Read: " + nRead);

        if( nRead > 0 ) {
            calculateEnergyLevel(buffer, nRead);
            int res = vad.processAudioByteArray(buffer, 0, nRead);
            res = vad.getVADResult(vadResult);
            if( codec == Codecs.OPUS ) {
                int len = vad.getOpusEncodedBytes(opusEncodedBuffer, 0, opusEncodedBuffer.length);
                Log.d(TAG, "Encoded length: " + len);
                mRecorderListener.onRecord(opusEncodedBuffer, len, vadResult.result);
            } else
                mRecorderListener.onRecord(buffer, nRead, vadResult.result);
        }
    }
  }
}

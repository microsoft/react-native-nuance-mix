package com.nuance.audio;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.BlockingQueue;
import android.os.Build;
import android.util.Log;

/** Class AbstractAudioSink. An abstract implementation of IAudioSink. */
public abstract class AbstractAudioSink implements IAudioSink {

  private final String TAG = "TAG-AudioSink";

  protected IAudioSink.Listener mPlayerListener = null;
  protected AtomicBoolean mPlaying = new AtomicBoolean(false);
  protected Thread playbackThread = null;
  protected BlockingQueue<AudioPacket> queue = null;
  protected static int mSampleRate;

  class AudioPacket {
    byte[] audio;
    
    public AudioPacket(byte[] audio) {
      this.audio = audio;
    }
  }

  // ******************************
  // CONSTRUCTOR
  // ******************************

  /**
   * Instantiates a new abstract audio sink.
   *
   * @param listener the listener
   * @throws Exception the exception
   */
  public AbstractAudioSink(IAudioSink.Listener listener) throws Exception {
    if (listener == null) {
      throw new Exception("ERROR: Null listener provided to AudioSink!");
    }

    this.mPlayerListener = listener;
  }

  /** Create a concrete implementation for AudioSink.play() */
  protected abstract void play(int sampleRate);

  // ******************************
  // PUBLIC METHODS
  // ******************************
  /* (non-Javadoc)
   */
  @Override
  public boolean isPlaying() {
    return mPlaying.get();
  }
  /* (non-Javadoc)
   */
  @Override
  public void start(final int sampleRate) {

    mSampleRate = sampleRate;
    if (!mPlaying.compareAndSet(false, true)) {
      Log.w(TAG, "Audio Sink already started.");
      return;
    }

    try {
      Runnable myRunnable =
          new Runnable() {
            @Override
            public void run() {
              Log.d(TAG, "AudioSink started");
              play(mSampleRate);
            }
          };
      playbackThread = new Thread(myRunnable);
      playbackThread.start();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  /* (non-Javadoc)
   */
  @Override
  public void stopPlayback() {

    if (!mPlaying.compareAndSet(true, false)) {
      Log.e(TAG, "AudioSink cannot be stopped. ");
      return;
    }

    try {
      playbackThread.join(0); // wait forever?
    } catch (InterruptedException e) {
      e.printStackTrace();
    } finally {
      Log.d(TAG, "AudioSink stopped");
    }
  }

  @Override
  public void put(final byte[] audio, int size) {
      if (queue == null) {
          play(mSampleRate);
          while(queue == null) {
              continue;
          }
      }
      
      queue.add(new AudioPacket(audio));
  }
}

package com.nuance.audio;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.util.concurrent.atomic.AtomicBoolean;

/** Class AbstractAudioSource. An abstract implementation of IAudioSource. */
public abstract class AbstractAudioSource implements IAudioSource {

  protected IAudioSource.Listener mRecorderListener = null;
  protected AtomicBoolean mRecording = new AtomicBoolean(false);
  protected static final int mAudioBufferSize =
      640; // 640 bytes is 20ms frames of PCM 16kHz 16bit mono
  protected Thread recordingThread = null;

  // ******************************
  // CONSTRUCTOR
  // ******************************

  /**
   * Instantiates a new abstract audio source.
   *
   * @param listener the listener
   * @throws Exception the exception
   */
  public AbstractAudioSource(IAudioSource.Listener listener) throws Exception {
    if (listener == null) {
      throw new Exception("ERROR: Null listener provided to AudioRecorder!");
    }

    this.mRecorderListener = listener;
  }

  /** Record. Create a concrete implementation for AudioSource.record() */
  protected abstract void record();

  // ******************************
  // PUBLIC METHODS
  // ******************************
  /* (non-Javadoc)
   */
  @Override
  public boolean isRecording() {
    return mRecording.get();
  }
  /* (non-Javadoc)
   */
  @Override
  public void start() {

    if (!mRecording.compareAndSet(false, true)) {
      return;
    }

    try {
      Runnable myRunnable =
          new Runnable() {
            @Override
            public void run() {
              record();
            }
          };
      recordingThread = new Thread(myRunnable);
      recordingThread.start();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  /* (non-Javadoc)
   */
  @Override
  public void stop() {
    if (!mRecording.compareAndSet(true, false)) {
      return;
    }

    try {
      recordingThread.join(150);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}

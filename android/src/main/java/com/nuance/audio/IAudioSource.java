package com.nuance.audio;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

/** The Interface IAudioSource. */
public interface IAudioSource {

  /**
   * Checks if is recording.
   *
   * @return true, if is recording
   */
  public boolean isRecording();

  /** Start. */
  public void start();

  /** Stop. */
  public void stop();

  /** Get Energy Levels */
  public double getEnergyLevel();

  /** The Interface Listener. */
  public interface Listener {

    /** On recording started. */
    void onRecordingStarted();

    /**
     * On recording stopped.
     *
     */
    void onRecordingStopped(boolean timedOut);

    /**
     * On recording error.
     *
     * @param error the error message
     */
    void onRecordingError(String error);

    /**
     * On record.
     *
     * @param data the data
     * @param size the size
     */
    void onRecord(byte[] data, int size, int vad_event);
  }
}

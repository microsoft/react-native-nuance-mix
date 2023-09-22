package com.nuance.audio;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

/** The Interface IAudioSink. */
public interface IAudioSink {

  /**
   * Checks if is playing.
   *
   * @return true, if is playing
   */
  public boolean isPlaying();

  /** Start. */
  public void start(final int sampleRate);

  /** Put data. */
  public void put(byte[] data, int size);

  /** Stop. */
  public void stopPlayback();

  /** The Interface Listener. */
  public interface Listener {

    /** On playing started. */
    void onPlayingStarted();

    /**
     * On playing stopped.
     *
     */
    void onPlayingStopped();

    /**
     * On playing error.
     *
     * @param error the error message
     */
    void onPlayingError(String error);

    /**
     * On play.
     *
     * @param data the data
     * @param size the size
     */
    void onPlay(byte[] data, int size);
  }
}

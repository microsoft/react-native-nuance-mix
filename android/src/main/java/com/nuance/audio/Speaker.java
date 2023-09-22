package com.nuance.audio;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.os.Build;
import android.util.Log;

public class Speaker extends AbstractAudioSink {

    private final String TAG = "TAG-Speaker";
    private AudioTrack mPlayer = null;
    private final int mChannelConfig = AudioFormat.CHANNEL_OUT_MONO;
    private final int mAudioFormat = AudioFormat.ENCODING_PCM_16BIT;
    private byte[] mAudio;

    public Speaker(Listener listener) throws Exception {
        super(listener);
    }

    @Override
    protected void play(final int sampleRate) {
        final int mAudioBufferSize = AudioTrack.getMinBufferSize(sampleRate, mChannelConfig, mAudioFormat) / 2;

        mPlayer = new AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
                                    mChannelConfig, mAudioFormat,
                                    mAudioBufferSize, AudioTrack.MODE_STREAM);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            mPlayer.setVolume(80F);
        }
        mPlayer.setNotificationMarkerPosition(10000);
        mPlayer.setPositionNotificationPeriod(1000);

        queue = new ArrayBlockingQueue<AudioPacket>(500);

        int audioTrackState = mPlayer.getState();
        if (audioTrackState != AudioTrack.STATE_INITIALIZED) {
            Log.e(TAG, "AudioTrack is not properly initialized");
            mPlayerListener.onPlayingError("AudioTrack is not properly initialized");
            return;
        } else {
            Log.v(TAG, "AudioTrack is initialized");
        }

        mPlayer.play();
        mPlayerListener.onPlayingStarted();

        if( mPlayer.getPlayState() != AudioTrack.PLAYSTATE_PLAYING ) {
            Log.v(TAG, "AudioTrack is is not playing");
            mPlayerListener.onPlayingError("AudioTrack is not playing");
            return;
        } else {
            Log.v(TAG, "AudioTrack has started playing...");
            mPlayerListener.onPlayingStarted();
        }

        while(isPlaying()) {
        	int length = 0;
        	try {
                AudioPacket p = queue.poll(1, TimeUnit.MILLISECONDS);
                if (p == null)
                    continue;
				mAudio = p.audio;

				int chunkSize = mAudioBufferSize;
				length = mAudio.length;
				int pos = 0;
	        	while( chunkSize > 0 ) {
		            chunkSize = (chunkSize > (length - pos)) ? (length - pos) : mAudioBufferSize;
		            
		            if( (chunkSize & 1) != 0 ) chunkSize -= 1;
		            
		            if( chunkSize <= 0 ) break;

		            mPlayer.write(mAudio, pos, chunkSize);
		            pos += chunkSize;
		            mPlayerListener.onPlay(mAudio, chunkSize);
                }
			} catch (InterruptedException e) {
				e.printStackTrace();
            }
        }
        
        stopPlayback();
        mPlayerListener.onPlayingStopped();
    }
}

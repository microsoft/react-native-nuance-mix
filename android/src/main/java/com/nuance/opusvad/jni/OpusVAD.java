package com.nuance.opusvad.jni;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

/* IMPORTANT NOTE:
 * The native functions in this class will expect the functions
 * prefixed with "Java_com_nuance_opusvad_jni_OpusVAD_".
 * If you move this class to another package, you much change
 * the function signatures in the native library.
 */

import java.nio.ByteBuffer;

public class OpusVAD {
    public static final int SAMPLE_BYTES = 2;
    public static final int AUDIO_FREQ = 16000;
    
    ByteBuffer ctx = null; // Will be modified by native init()
    final ByteBuffer audioBuffer;
    final ByteBuffer encodedBuffer;
    final int frame_size;
    
    native final int init();
    public native final int processAudio(ByteBuffer audiobuf, int num_samples);
    public native final int getVADResult(OpusVADResult outResult);
    native final int getFrameSize();
    public native final int getMaxBufferSamples();
    native final int getOpusEncoded(ByteBuffer outbuf);
    
    public OpusVAD() throws Exception {
        int res = init();
        if (res != 0) {
            throw new Exception("Error with Init: " + res);
        }
        frame_size = getFrameSize();
        audioBuffer = ByteBuffer.allocateDirect(frame_size * SAMPLE_BYTES);
        encodedBuffer = ByteBuffer.allocateDirect(frame_size * SAMPLE_BYTES);
    }
    
    public int processAudioByteArray(byte[] audiobuf, int offset, int len)
    {
        audioBuffer.position(0);
        audioBuffer.put(audiobuf, offset, len);
        return processAudio(audioBuffer, len / SAMPLE_BYTES);
    }
    
    public int getFrameSamples()
    {
        return frame_size;
    }
    
    public int getFrameBytes() {
        return getFrameSamples() * SAMPLE_BYTES;
    }

    public int getOpusEncodedBytes(byte[] out, int pos, int maxlen) {
       encodedBuffer.position(0);
       int res = getOpusEncoded(encodedBuffer);
       if (res >= 0) {
           if (maxlen < res) {
               return -1;
           }
           encodedBuffer.get(out, pos, res);
       }
       return res;
    }
}

package com.nuance.opusvad.jni;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

public class OpusVADResult {
    public int result;
    public long pos;
    
    public long getPosInMs() {
        return ( pos / ( OpusVAD.AUDIO_FREQ / 1000 ));
    }
}

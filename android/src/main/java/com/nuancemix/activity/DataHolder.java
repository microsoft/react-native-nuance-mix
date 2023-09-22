package com.nuancemix.activity;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import java.util.List;
import nuance.tts.v1.NuanceTtsV1.*;

public class DataHolder {
    private List<Voice> data = null;
    public List<Voice> getData() {return data;}
    public void setData(List<Voice> data) {
        this.data = data;
    }
  
    private static final DataHolder holder = new DataHolder();
    public static DataHolder getInstance() { 
        return holder; 
    }
}  

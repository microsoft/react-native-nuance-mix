package com.nuance.utils;
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import android.util.Log;

/**
 * Created by peter_freshman on 10/17/16.
 */
public class Timer {

    private final String TAG = "TAG-Timer";

    Thread t;
    long timeout;
    long t_start;
    long t_end;
    Timer.Listener listener;

    public interface Listener {
        void onStarted(long start);
        void onCancelled(long duration);
        void onExpired(long duration);
    }

    public Timer() {
    }

    private void run() {
        t = new Thread() {
            synchronized public void run() {
                try {
                    t_start = System.currentTimeMillis();
                    Log.d(TAG, "Timer started");
                    listener.onStarted(t_start);

                    Log.d(TAG, "Timer thread running...");
                    this.wait(timeout);

                    Log.d(TAG, "Timer thread done waiting...");
                    t_end = System.currentTimeMillis();
                    listener.onExpired((t_end - t_start));

                } catch (InterruptedException e) {
                    Log.d(TAG, "Timer thread interrupted...");
                    t_end = System.currentTimeMillis();
                    listener.onCancelled((t_end - t_start));
                }
            }
        };
        t.start();
    }

    public void start(long ms, Timer.Listener listener) {
        this.listener = listener;
        this.timeout = ms;
        this.run();
    }
    public void cancel() {
        Log.d(TAG, "Timer cancelled");
        if( t != null && (t.getState() == Thread.State.WAITING || t.getState() == Thread.State.TIMED_WAITING) )
            t.interrupt();
    }
    public void reset() {
        Log.d(TAG, "Timer reset");
        this.cancel();
        this.start(this.timeout, this.listener);
    }
    public void reset(long ms) {
        Log.d(TAG, "Timer reset");
        this.cancel();
        this.start(ms, this.listener);
    }
}

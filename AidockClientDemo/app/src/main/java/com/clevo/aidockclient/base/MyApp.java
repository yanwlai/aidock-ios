package com.clevo.aidockclient.base;

import android.app.Application;
import android.content.Context;

import com.clevo.aidockclient.utils.NetworkUtils;

public class MyApp extends Application {
    private static MyApp instance;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
    }

    public static Context getContext() {
        return instance.getApplicationContext();
    }

    public static boolean isWifiAvailable() {
        return NetworkUtils.isNetworkAvailable(getContext());
    }

    public static MyApp getInstance() {
        return instance;
    }
}
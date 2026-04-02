package com.clevo.aidockclient.network.agora.listener;

public interface OnRTMEventListener {
    void onMessage(Object msg);
    void onPresence(String msg);
}

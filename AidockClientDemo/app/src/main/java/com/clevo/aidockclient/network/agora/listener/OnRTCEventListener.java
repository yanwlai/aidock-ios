package com.clevo.aidockclient.network.agora.listener;

public interface OnRTCEventListener {
    void onError(int err, String msg);
    void onJoinChannelSuccess(String channel, int uid);
    void onUserJoined(int uid);
    void onUserOffline(int uid);
}

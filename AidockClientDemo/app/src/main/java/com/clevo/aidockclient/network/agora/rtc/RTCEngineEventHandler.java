package com.clevo.aidockclient.network.agora.rtc;

import com.clevo.aidockclient.network.agora.listener.OnRTCEventListener;
import com.clevo.aidockclient.utils.LogUtils;

import io.agora.rtc2.Constants;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;

/**
 * 客户端 RTC 事件处理
 */
public class RTCEngineEventHandler extends IRtcEngineEventHandler {
    private static final String TAG = "rtc event-> ";
    private final OnRTCEventListener listener;

    public RTCEngineEventHandler(OnRTCEventListener listener) {
        this.listener = listener;
    }

    @Override
    public void onError(int err) {
        String msg = String.format("onError code %d message %s", err, RtcEngine.getErrorDescription(err));
        LogUtils.e(TAG + msg);
        if (listener != null) {
            listener.onError(err, RtcEngine.getErrorDescription(err));
        }
    }

    @Override
    public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
        LogUtils.d(TAG + String.format("onJoinChannelSuccess channel %s uid %d", channel, uid));
        if (listener != null) {
            listener.onJoinChannelSuccess(channel, uid);
        }
    }

    @Override
    public void onUserJoined(int uid, int elapsed) {
        LogUtils.d(TAG + "onUserJoined uid=" + uid);
        if (listener != null) {
            listener.onUserJoined(uid);
        }
    }

    @Override
    public void onUserOffline(int uid, int reason) {
        LogUtils.d(TAG + String.format("onUserOffline uid=%d reason=%d", uid, reason));
        if (listener != null) {
            listener.onUserOffline(uid);
        }
    }

    @Override
    public void onRemoteVideoStateChanged(int uid, int state, int reason, int elapsed) {
        super.onRemoteVideoStateChanged(uid, state, reason, elapsed);
        LogUtils.d(TAG + "onRemoteVideoStateChanged uid=" + uid + " state=" + state + " reason=" + reason);
    }

    @Override
    public void onRemoteVideoStats(RemoteVideoStats stats) {
        super.onRemoteVideoStats(stats);
        LogUtils.d(TAG + "onRemoteVideoStats: " + stats.width + "x" + stats.height);
    }

    @Override
    public void onLocalVideoStateChanged(Constants.VideoSourceType source, int state, int error) {
        super.onLocalVideoStateChanged(source, state, error);
        LogUtils.d(TAG + "onLocalVideoStateChanged source=" + source + " state=" + state + " error=" + error);
    }

    @Override
    public void onRemoteAudioStateChanged(int uid, int state, int reason, int elapsed) {
        LogUtils.d(TAG + "onRemoteAudioStateChanged uid=" + uid + " state=" + state + " reason=" + reason);
    }

    @Override
    public void onLocalAudioStateChanged(int state, int reason) {
        LogUtils.d(TAG + "onLocalAudioStateChanged state=" + state + " reason=" + reason);
    }

    @Override
    public void onStreamMessage(int uid, int streamId, byte[] data) {
        LogUtils.d(TAG + "onStreamMessage from uid=" + uid + " data=" + new String(data));
    }

    @Override
    public void onStreamMessageError(int uid, int streamId, int error, int missed, int cached) {
        LogUtils.e(TAG + "onStreamMessageError uid=" + uid + " error=" + error + " missed=" + missed);
    }
}

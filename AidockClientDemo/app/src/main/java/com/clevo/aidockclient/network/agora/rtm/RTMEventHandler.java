package com.clevo.aidockclient.network.agora.rtm;

import com.clevo.aidockclient.network.agora.listener.OnRTMEventListener;
import com.clevo.aidockclient.utils.LogUtils;

import io.agora.rtm.MessageEvent;
import io.agora.rtm.PresenceEvent;
import io.agora.rtm.RtmEventListener;

public class RTMEventHandler implements RtmEventListener {
    private static final String LOG_MSG_PREFIX = "rtm event-> ";

    private final OnRTMEventListener onRTMEventListener;

    public RTMEventHandler(OnRTMEventListener onRTMEventListener) {
        this.onRTMEventListener = onRTMEventListener;
    }

    @Override
    public void onMessageEvent(MessageEvent event) {
        String text = "Message received from " + event.getPublisherId() + " Message: " + event.getMessage().getData();
        LogUtils.e(LOG_MSG_PREFIX + text);
        onRTMEventListener.onMessage(event.getMessage().getData());
    }

    @Override
    public void onPresenceEvent(PresenceEvent event) {
        String text = "receive presence event, user: " + event.getPublisherId() + " event: " + event.getEventType();
        LogUtils.e(LOG_MSG_PREFIX + text);
        onRTMEventListener.onPresence(text);
    }
}

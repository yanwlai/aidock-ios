package com.clevo.aidockclient.helper.listener;

import okio.ByteString;

public interface OnWebSocketListener {
    void onOpen(); // 打开

    void onMessage(String text); // 普通文本

    void onMessage(ByteString bytes); // 字节流

    void onClosing(int code, String msg); // 关闭中

    void onClosed(int code, String msg); // 已关闭

    void onFailed(); // 失败
}

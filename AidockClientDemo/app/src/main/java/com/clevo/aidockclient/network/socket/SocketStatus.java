package com.clevo.aidockclient.network.socket;

public enum SocketStatus {
    CONNECTING, // 连接中
    OPEN, // 已连接
    CLOSING, // 关闭中
    CLOSED, // 已关闭
    CANCELED, // 已取消
    FAILED // 连接失败
}

package com.clevo.aidockclient.network.agora.rtc;

import com.clevo.aidockclient.utils.LogUtils;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.agora.rtc2.video.EncodedVideoFrameInfo;
import io.agora.rtc2.video.IVideoEncodedFrameObserver;

/**
 * 远端 H.264 编码帧观察者。
 * <p>
 * 功能：将 Agora 推送的远端 H.264 编码帧，通过 Unix 抽象命名空间 Socket
 * 发送给本地消费端（socket name: "aidock_cam_h264"）。
 * <p>
 * 帧协议：
 * <pre>
 *  ┌────────────────────────────────────────┐
 *  │  Length (4 bytes, little-endian)        │
 *  ├────────────────────────────────────────┤
 *  │  Raw H264 data                         │
 *  └────────────────────────────────────────┘
 * </pre>
 */
public class RTCVideoEncodedFrameObserver implements IVideoEncodedFrameObserver {
    private static final String LOG_MSG_PREFIX = "rtc video encode frame-> ";
    private static final String SOCKET_NAME = "aidock_cam_h264";

    private final byte[] mLengthBuf = new byte[4];
    private final ByteBuffer mLengthWrapper = ByteBuffer.wrap(mLengthBuf).order(ByteOrder.LITTLE_ENDIAN);

    private LocalSocket mLocalSocket;

    private final ExecutorService mSendExecutor = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "h264-socket-sender");
        t.setDaemon(true);
        return t;
    });

    @Override
    public boolean onEncodedVideoFrameReceived(String channelId, int remoteUid, ByteBuffer buffer, EncodedVideoFrameInfo info) {
        if (buffer == null) return true;

        // 复制数据，避免 ByteBuffer 被 Agora 回收
        int size = buffer.remaining();
        byte[] data = new byte[size];
        buffer.get(data);

        mSendExecutor.execute(() -> sendFrame(data));
        return true;
    }

    private void sendFrame(byte[] data) {
        if (!ensureConnected()) return;

        try {
            OutputStream out = mLocalSocket.getOutputStream();

            // 1. 写帧长度（4字节，little-endian）
            mLengthWrapper.clear();
            mLengthWrapper.putInt(data.length);
            out.write(mLengthBuf);

            // 2. 写 H264 数据
            out.write(data);
        } catch (IOException e) {
            LogUtils.e(LOG_MSG_PREFIX + "send frame failed, closing socket: " + e.getMessage());
            closeSocket();
        }
    }

    private boolean ensureConnected() {
        if (mLocalSocket != null && mLocalSocket.isConnected()) return true;

        closeSocket();

        try {
            mLocalSocket = new LocalSocket(SOCKET_NAME);
            LogUtils.e(LOG_MSG_PREFIX + "connected to socket: " + SOCKET_NAME);
            return true;
        } catch (IOException e) {
            // 静默失败，避免频繁打印连接失败日志
            mLocalSocket = null;
            return false;
        }
    }

    private void closeSocket() {
        if (mLocalSocket != null) {
            try {
                mLocalSocket.close();
            } catch (IOException ignored) {}
            mLocalSocket = null;
        }
    }

    public void release() {
        mSendExecutor.shutdown();
        closeSocket();
    }

    /**
     * Unix 抽象命名空间 Socket 封装
     */
    private static class LocalSocket {
        private final android.net.LocalSocket mSocket;

        LocalSocket(String abstractName) throws IOException {
            mSocket = new android.net.LocalSocket();
            android.net.LocalSocketAddress addr = new android.net.LocalSocketAddress(
                    abstractName,
                    android.net.LocalSocketAddress.Namespace.ABSTRACT);
            mSocket.connect(addr);
        }

        OutputStream getOutputStream() throws IOException {
            return mSocket.getOutputStream();
        }

        boolean isConnected() {
            return mSocket.isConnected();
        }

        void close() throws IOException {
            mSocket.close();
        }
    }
}

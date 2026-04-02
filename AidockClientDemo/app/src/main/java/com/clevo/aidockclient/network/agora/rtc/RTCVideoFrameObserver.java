package com.clevo.aidockclient.network.agora.rtc;

import androidx.annotation.Keep;

import com.clevo.aidockclient.utils.LogUtils;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import io.agora.base.VideoFrame;
import io.agora.rtc2.video.IVideoFrameObserver;

/**
 * 远端视频帧观察者。
 * <p>
 * 功能：将 Agora 推送的远端原始 NV21 视频帧，通过 Unix 抽象命名空间 Socket
 * 发送给本地 C++ 消费端（socket name: "aidock_cam_yuv"）。
 * <p>
 * 帧协议（与 C++ 端 YuvSocketClient 对齐）：
 * 
 * <pre>
 *  ┌────────────────────────────────────────┐
 *  │  Header (16 bytes, little-endian)      │
 *  │    width     : uint32 (4 bytes)        │
 *  │    height    : uint32 (4 bytes)        │
 *  │    timestamp : uint64 (8 bytes, ns)    │
 *  ├────────────────────────────────────────┤
 *  │  NV21 YUV data  (width * height * 3/2) │
 *  └────────────────────────────────────────┘
 * </pre>
 * <p>
 * 注意：onRenderVideoFrame 运行在 RTC 内部工作线程，已通过专用单线程 Executor
 * 异步转发，避免阻塞 RTC 管道。
 */
@Keep
public class RTCVideoFrameObserver implements IVideoFrameObserver {
    private static final String LOG_MSG_PREFIX = "rtc video frame-> ";

    /**
     * Unix 抽象命名空间 socket 名称（与 C++ 端一致）。
     */
    private static final String SOCKET_NAME = "aidock_cam_yuv";

    /**
     * 帧头大小：4(width) + 4(height) + 8(timestamp) = 16 bytes。
     */
    private static final int HEADER_SIZE = 16;

    /**
     * 帧头字节缓冲（复用，仅在 sender 线程访问，线程安全）。
     */
    private final byte[] mHeaderBuf = new byte[HEADER_SIZE];
    private final ByteBuffer mHeaderWrapper = ByteBuffer.wrap(mHeaderBuf).order(ByteOrder.LITTLE_ENDIAN);

    // -------------------------------------------------------------------------
    // Socket 状态（仅在 mSendExecutor 单线程中访问，无需加锁）
    // -------------------------------------------------------------------------
    private LocalSocket mLocalSocket;

    /**
     * 单线程 Executor，所有 socket 写操作均在此线程执行，
     * 避免阻塞 RTC 内部回调线程，同时保证写操作串行无竞争。
     */
    private final java.util.concurrent.ExecutorService mSendExecutor = java.util.concurrent.Executors
            .newSingleThreadExecutor(r -> {
                Thread t = new Thread(r, "yuv-socket-sender");
                t.setDaemon(true);
                return t;
            });

    // =========================================================================
    // IVideoFrameObserver 配置
    // =========================================================================

    @Override
    public int getVideoFrameProcessMode() {
        // 使用 READ_WRITE 模式：部分 Agora SDK 版本在 READ_ONLY + POSITION_PRE_RENDERER
        // 组合下会跳过帧回调，READ_WRITE 可确保回调正常触发
        return PROCESS_MODE_READ_WRITE;
    }

    @Override
    public int getVideoFormatPreference() {
        // 直接向 Agora 请求 NV21 格式，省去 I420→NV21 的手动转换开销
        return VIDEO_PIXEL_NV21;
    }

    @Override
    public boolean getRotationApplied() {
        // 不旋转，裸流直接发给 C++ 端，由 C++ 侧自行处理旋转
        return false;
    }

    @Override
    public boolean getMirrorApplied() {
        return false;
    }

    @Override
    public int getObservedFramePosition() {
        return POSITION_PRE_RENDERER;
    }

    @Override
    public boolean onCaptureVideoFrame(int sourceType, VideoFrame videoFrame) {
        return true;
    }

    @Override
    public boolean onPreEncodeVideoFrame(int sourceType, VideoFrame videoFrame) {
        return true;
    }

    @Override
    public boolean onMediaPlayerVideoFrame(VideoFrame videoFrame, int mediaPlayerId) {
        return true;
    }

    /**
     * 远端视频帧回调（运行在 RTC 内部工作线程）。
     * 将帧数据复制后异步投递到 sender 线程，立即返回，不阻塞 RTC。
     */
    @Override
    public boolean onRenderVideoFrame(String channelId, int uid, VideoFrame videoFrame) {
        LogUtils.e(LOG_MSG_PREFIX + "onRenderVideoFrame: channelId=" + channelId + ", uid=" + uid + ", videoFrame="
                + videoFrame);
        if (videoFrame == null)
            return true;

        VideoFrame.Buffer buffer = videoFrame.getBuffer();
        if (!(buffer instanceof VideoFrame.I420Buffer)) {
            // Agora 在某些设备上可能回退到 I420，做兼容处理
            LogUtils.e(LOG_MSG_PREFIX + "unexpected buffer type: " + buffer.getClass().getSimpleName());
            return true;
        }

        // NV21 格式：Y 平面 + 交错 VU 平面，总大小 = width * height * 3 / 2
        // 注意：实际获取到的 buffer 类型根据 getVideoFormatPreference() 返回值决定，
        // Agora 保证此处为 NV21。使用 I420Buffer 接口读取 Y/U/V 三平面后手动拼接。
        VideoFrame.I420Buffer i420 = (VideoFrame.I420Buffer) buffer;

        final int width = i420.getWidth();
        final int height = i420.getHeight();
        final int ySize = width * height;
        final int uvSize = ySize / 2; // NV21 VU 交错 = UV 总像素
        final int totalSize = ySize + uvSize;

        // ---- 在 RTC 线程中复制数据（避免 buffer 被 Agora 回收）----
        final byte[] yuvData = new byte[totalSize];

        // Y 平面直接拷贝
        ByteBuffer yPlane = i420.getDataY();
        int yStride = i420.getStrideY();
        copyPlane(yPlane, yStride, yuvData, 0, width, height);

        // NV21 要求 VU 交错（先 V 后 U），Agora 请求 NV21 时 U/V 平面已经是交错格式
        // 但 I420Buffer 接口暴露的是分离的 U/V，需手动交错
        ByteBuffer uPlane = i420.getDataU();
        ByteBuffer vPlane = i420.getDataV();
        int uStride = i420.getStrideU();
        int vStride = i420.getStrideV();
        interleaveVU(vPlane, vStride, uPlane, uStride, yuvData, ySize, width / 2, height / 2);

        final long timestampNs = System.nanoTime();

        LogUtils.e(LOG_MSG_PREFIX + "send frame prepare!");
        // ---- 异步发送，不阻塞 RTC 线程 ----
        mSendExecutor.execute(() -> sendFrame(width, height, timestampNs, yuvData));

        return true;
    }

    // =========================================================================
    // 内部工具方法
    // =========================================================================

    /**
     * 将单个 YUV 平面按行拷贝到目标字节数组，处理 stride 与 width 不一致的情况。
     */
    private static void copyPlane(ByteBuffer src, int stride,
            byte[] dst, int dstOffset,
            int width, int height) {
        src = src.duplicate();
        src.rewind();
        if (stride == width) {
            // 快速路径：内存连续，整块拷贝
            src.get(dst, dstOffset, width * height);
        } else {
            // 逐行拷贝，跳过 stride padding
            for (int row = 0; row < height; row++) {
                src.position(row * stride);
                src.get(dst, dstOffset + row * width, width);
            }
        }
    }

    /**
     * 将分离的 V、U 平面交错合并为 NV21 格式的 VU 数据（先 V 后 U）。
     */
    private static void interleaveVU(ByteBuffer vSrc, int vStride,
            ByteBuffer uSrc, int uStride,
            byte[] dst, int dstOffset,
            int uvWidth, int uvHeight) {
        vSrc = vSrc.duplicate();
        uSrc = uSrc.duplicate();
        vSrc.rewind();
        uSrc.rewind();
        int idx = dstOffset;
        for (int row = 0; row < uvHeight; row++) {
            for (int col = 0; col < uvWidth; col++) {
                dst[idx++] = vSrc.get(row * vStride + col);
                dst[idx++] = uSrc.get(row * uStride + col);
            }
        }
    }

    /**
     * 将一帧数据通过 Unix 抽象 Socket 发送给 C++ 端。
     * 仅在 mSendExecutor 单线程中调用。
     */
    private void sendFrame(int width, int height, long timestampNs, byte[] yuvData) {
        LogUtils.e(LOG_MSG_PREFIX + "init socket if needed");
        if (!ensureConnected())
            return;

        try {
            OutputStream out = mLocalSocket.getOutputStream();

            // 1. 写帧头（16 字节，little-endian）
            mHeaderWrapper.clear();
            mHeaderWrapper.putInt(width);
            mHeaderWrapper.putInt(height);
            mHeaderWrapper.putLong(timestampNs);
            out.write(mHeaderBuf, 0, HEADER_SIZE);

            // 2. 写 NV21 数据
            out.write(yuvData);
            // 不 flush（OutputStream over LocalSocket 本身会写入内核缓冲区，
            // flush 仅对带 BufferedOutputStream 的场景有意义）
        } catch (IOException e) {
            LogUtils.e(LOG_MSG_PREFIX + "send frame failed, closing socket: " + e.getMessage());
            closeSocket();
        }
    }

    /**
     * 确保 socket 已连接，断线后自动尝试重连一次。
     *
     * @return true 表示 socket 可用
     */
    private boolean ensureConnected() {
        if (mLocalSocket != null && mLocalSocket.isConnected())
            return true;

        closeSocket(); // 清理旧的

        try {
            mLocalSocket = new LocalSocket(SOCKET_NAME);
            LogUtils.e(LOG_MSG_PREFIX + "connected to local socket: " + SOCKET_NAME);
            return true;
        } catch (IOException e) {
            LogUtils.e(LOG_MSG_PREFIX + "connect failed: " + e.getMessage());
            mLocalSocket = null;
            return false;
        }
    }

    private void closeSocket() {
        if (mLocalSocket != null) {
            try {
                mLocalSocket.close();
            } catch (IOException ignored) {
            }
            mLocalSocket = null;
        }
    }

    /**
     * 资源释放，在 Service 销毁时调用。
     */
    public void release() {
        mSendExecutor.shutdown();
        closeSocket();
    }

    // =========================================================================
    // Unix 抽象命名空间 Socket 封装
    //
    // Android 内置的 android.net.LocalSocket 支持抽象命名空间，
    // 是比 java.net.Socket 更合适的选择（java.net.Socket 无法连接 AF_UNIX）。
    // =========================================================================

    /**
     * 对 {@link android.net.LocalSocket} 的轻量封装，统一接口。
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

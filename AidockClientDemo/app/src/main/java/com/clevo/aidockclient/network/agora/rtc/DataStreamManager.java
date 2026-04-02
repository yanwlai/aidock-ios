package com.clevo.aidockclient.network.agora.rtc;

import com.clevo.aidockclient.utils.LogUtils;

import io.agora.rtc2.DataStreamConfig;
import io.agora.rtc2.RtcEngineEx;

/**
 * 管理 RTC Data Stream 的创建和消息发送
 * 用于向云机发送控制指令（触摸、按键、文本）
 */
public class DataStreamManager {
    private static final String TAG = "DataStreamManager";
    private final RtcEngineEx engine;
    private int streamId = -1;

    public DataStreamManager(RtcEngineEx engine) {
        this.engine = engine;
    }

    /**
     * 创建数据通道，应在 onJoinChannelSuccess 后调用
     *
     * @return true 创建成功
     */
    public boolean createStream() {
        if (engine == null) {
            LogUtils.e(TAG + " engine is null");
            return false;
        }
        DataStreamConfig config = new DataStreamConfig();
        config.syncWithAudio = false;
        config.ordered = true;
        streamId = engine.createDataStream(config);
        LogUtils.d(TAG + " createStream id=" + streamId);
        return streamId >= 0;
    }

    /**
     * 发送控制指令
     *
     * @return 0 成功，负数为错误码
     */
    public int sendCommand(InputCommand command) {
        if (streamId < 0 || engine == null) {
            return -1;
        }
        byte[] data = command.toBytes();
        return engine.sendStreamMessage(streamId, data);
    }

    public boolean isReady() {
        return streamId >= 0;
    }

    public void reset() {
        streamId = -1;
    }
}

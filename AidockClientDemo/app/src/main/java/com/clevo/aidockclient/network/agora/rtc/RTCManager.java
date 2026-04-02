package com.clevo.aidockclient.network.agora.rtc;

import android.content.Context;
import android.view.SurfaceView;

import com.clevo.aidockclient.R;
import com.clevo.aidockclient.network.agora.listener.OnRTCEventListener;
import com.clevo.aidockclient.network.agora.utils.TokenUtils;
import com.clevo.aidockclient.utils.CommonUtils;
import com.clevo.aidockclient.utils.LogUtils;
import com.clevo.aidockclient.utils.UserInfoUtils;

import io.agora.rtc2.ChannelMediaOptions;
import io.agora.rtc2.Constants;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.RtcEngineConfig;
import io.agora.rtc2.RtcEngineEx;
import io.agora.rtc2.video.VideoCanvas;
import io.agora.rtc2.video.VideoEncoderConfiguration;

/**
 * 客户端 RTC 管理器
 * 负责：引擎初始化、频道加入/离开、远端视频渲染、DataStream 控制指令
 */
public class RTCManager {
    private static final String TAG = "rtc manager-> ";
    private final Context mContext;
    private final String channelId = UserInfoUtils.getSerialNumber();

    private RtcEngineEx engine;
    private DataStreamManager mDataStreamManager;
    private boolean joined = false;
    private boolean localMediaEnabled = false;

    public RTCManager(Context context) {
        mContext = context;
    }

    /**
     * 初始化 RTC 引擎
     */
    public void init(OnRTCEventListener listener) {
        try {
            RTCEngineEventHandler eventHandler = new RTCEngineEventHandler(listener);

            RtcEngineConfig config = new RtcEngineConfig();
            config.mContext = mContext.getApplicationContext();
            config.mAppId = mContext.getString(R.string.agora_app_id);
            config.mChannelProfile = Constants.CHANNEL_PROFILE_LIVE_BROADCASTING;
            config.mEventHandler = eventHandler;
            config.mAudioScenario = Constants.AudioScenario.getValue(Constants.AudioScenario.DEFAULT);
            engine = (RtcEngineEx) RtcEngine.create(config);
            engine.setParameters("{"
                    + "\"rtc.report_app_scenario\":"
                    + "{"
                    + "\"appScenario\":" + 100 + ","
                    + "\"serviceType\":" + 11 + ","
                    + "\"appVersion\":\"" + RtcEngine.getSdkVersion() + "\""
                    + "}"
                    + "}");
        } catch (Exception e) {
            LogUtils.e(TAG + "初始化失败: " + e.getMessage());
        }
    }

    /**
     * 获取 Token 并加入频道
     */
    public void joinChannel() {
        if (engine == null) {
            LogUtils.e(TAG + "engine is null");
            return;
        }

        engine.setClientRole(Constants.CLIENT_ROLE_BROADCASTER);
        engine.enableAudio();
        engine.enableVideo();

        VideoEncoderConfiguration videoConfig = new VideoEncoderConfiguration(
                VideoEncoderConfiguration.VD_640x360,
                VideoEncoderConfiguration.FRAME_RATE.FRAME_RATE_FPS_15,
                VideoEncoderConfiguration.STANDARD_BITRATE,
                VideoEncoderConfiguration.ORIENTATION_MODE.ORIENTATION_MODE_ADAPTIVE
        );
        videoConfig.codecType = VideoEncoderConfiguration.VIDEO_CODEC_TYPE.VIDEO_CODEC_H264;
        engine.setVideoEncoderConfiguration(videoConfig);
        engine.setDefaultAudioRoutetoSpeakerphone(true);

        TokenUtils.gen(mContext, channelId, 0, accessToken -> {
            ChannelMediaOptions options = new ChannelMediaOptions();
            options.clientRoleType = Constants.CLIENT_ROLE_BROADCASTER;
            options.autoSubscribeVideo = true;
            options.autoSubscribeAudio = true;
            options.publishCameraTrack = false;
            options.publishMicrophoneTrack = false;
            options.publishScreenCaptureVideo = false;
            options.publishScreenCaptureAudio = false;
            int res = engine.joinChannel(accessToken, channelId, 0, options);
            if (res != 0) {
                LogUtils.e(TAG + "joinChannel failed: " + RtcEngine.getErrorDescription(Math.abs(res)));
            }
        });
    }

    /**
     * 创建 DataStream 用于发送控制指令，应在 onJoinChannelSuccess 后调用
     */
    public void createDataStream() {
        if (engine == null) {
            LogUtils.e(TAG + "engine is null, cannot create DataStream");
            return;
        }
        mDataStreamManager = new DataStreamManager(engine);
        if (mDataStreamManager.createStream()) {
            LogUtils.d(TAG + "DataStream created");
        } else {
            LogUtils.e(TAG + "DataStream creation failed");
        }
    }

    /**
     * 发送控制指令到云机
     */
    public void sendCommand(InputCommand command) {
        if (mDataStreamManager == null || !mDataStreamManager.isReady()) {
            LogUtils.e(TAG + "DataStream not ready");
            return;
        }
        int ret = mDataStreamManager.sendCommand(command);
        if (ret < 0) {
            LogUtils.e(TAG + "sendCommand failed: " + ret);
        }
    }

    /**
     * 获取 DataStreamManager，供 TouchEventHandler 使用
     */
    public DataStreamManager getDataStreamManager() {
        return mDataStreamManager;
    }

    /**
     * 是否可以发送控制指令
     */
    public boolean isControlReady() {
        return mDataStreamManager != null && mDataStreamManager.isReady();
    }

    /**
     * 设置远端视频渲染
     */
    public void setupRemoteVideo(SurfaceView surfaceView, int uid) {
        if (engine == null) return;
        engine.setupRemoteVideo(new VideoCanvas(surfaceView, Constants.RENDER_MODE_FIT, uid));
    }

    /**
     * 移除远端视频渲染
     */
    public void removeRemoteVideo(int uid) {
        if (engine == null) return;
        engine.setupRemoteVideo(new VideoCanvas(null, Constants.RENDER_MODE_FIT, uid));
    }

    /**
     * 离开频道
     */
    public void leaveChannel() {
        joined = false;
        if (mDataStreamManager != null) {
            mDataStreamManager.reset();
        }
        if (engine != null) {
            engine.leaveChannel();
            engine.stopPreview();
        }
    }

    /**
     * 释放资源
     */
    public void destroy() {
        leaveChannel();
        engine = null;
        RtcEngine.destroy();
    }

    /**
     * 开启/关闭本地音视频推流
     */
    public void setLocalMediaEnabled(boolean enabled) {
        if (engine == null) return;
        localMediaEnabled = enabled;
        ChannelMediaOptions options = new ChannelMediaOptions();
        options.publishCameraTrack = enabled;
        options.publishMicrophoneTrack = enabled;
        engine.updateChannelMediaOptions(options);
        engine.muteLocalAudioStream(!enabled);
        engine.muteLocalVideoStream(!enabled);
        LogUtils.d(TAG + "本地音视频推流: " + (enabled ? "开启" : "关闭"));
    }

    public boolean isLocalMediaEnabled() {
        return localMediaEnabled;
    }

    public RtcEngineEx getEngine() {
        return engine;
    }

    public boolean isJoined() {
        return joined;
    }

    public void setJoined(boolean joined) {
        this.joined = joined;
    }
}

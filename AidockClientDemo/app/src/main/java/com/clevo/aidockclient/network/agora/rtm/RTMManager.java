package com.clevo.aidockclient.network.agora.rtm;

import android.content.Context;

import com.clevo.aidockclient.R;
import com.clevo.aidockclient.network.agora.listener.OnRTMLoginListener;
import com.clevo.aidockclient.network.agora.listener.OnTokenResultListener;
import com.clevo.aidockclient.network.agora.utils.TokenUtils;
import com.clevo.aidockclient.utils.CommonUtils;
import com.clevo.aidockclient.utils.LogUtils;
import com.clevo.aidockclient.utils.UserInfoUtils;

import io.agora.rtm.ErrorInfo;
import io.agora.rtm.PublishOptions;
import io.agora.rtm.ResultCallback;
import io.agora.rtm.RtmClient;
import io.agora.rtm.RtmConfig;
import io.agora.rtm.SubscribeOptions;

public class RTMManager {
    private static final String LOG_MSG_PREFIX = "rtm manager-> ";
    private final Context mContext;
    private final String mUserId = "clevo-test";
    private final String mChannelName = UserInfoUtils.getSerialNumber();
    private RtmClient mRtmClient;
    private boolean isLogin;
    private boolean isSubscribed;

    public RTMManager(Context mContext) {
        this.mContext = mContext;
    }

    public void init(RTMEventHandler eventHandler) {
        try {
            if (mUserId == null || mUserId.isEmpty()) {
                LogUtils.e(LOG_MSG_PREFIX + "userId为空");
                return;
            }
            RtmConfig config = new RtmConfig.Builder(mContext.getString(R.string.agora_app_id), mUserId)
                    .eventListener(eventHandler)
                    .build();
            mRtmClient = RtmClient.create(config);
        } catch (Exception e) {
            LogUtils.e(LOG_MSG_PREFIX + "client create 异常: " + e.getMessage());
        }
    }

    /**
     * 未获取到重新获取，系统app监听到了网络开启，但是要延迟一段时间才能访问api获取到token
     *
     */
    public void getToken(OnTokenResultListener listener) {
        TokenUtils.genRtmToken(mContext, mUserId, token -> {
            boolean success = token != null && !token.isEmpty();
            if (!success) {
                LogUtils.e(LOG_MSG_PREFIX + "获取token为空");
            }
            if (listener != null) {
                listener.onResult(success, token);
            }
        });
    }

    public void login(String token, OnRTMLoginListener listener) {
        if (mRtmClient == null) {
            LogUtils.e(LOG_MSG_PREFIX + "client is null");
            return;
        }

        mRtmClient.login(token, new ResultCallback<>() {
            @Override
            public void onSuccess(Void responseInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "登录rtm服务器成功");
                isLogin = true;
                if (listener != null) {
                    listener.onSuccess();
                }
            }

            @Override
            public void onFailure(ErrorInfo errorInfo) {
                CharSequence text = "user: " + mUserId + " 登录rtm服务器失败, " + errorInfo.toString();
                LogUtils.e(LOG_MSG_PREFIX + text);
            }
        });
    }

    public void subscribe() {
        if (mRtmClient == null) {
            LogUtils.e(LOG_MSG_PREFIX + "client is null");
            return;
        }

        SubscribeOptions options = new SubscribeOptions();
        options.setWithMessage(true);
        mRtmClient.subscribe(mChannelName, options, new ResultCallback<>() {
            @Override
            public void onSuccess(Void responseInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "加入频道成功");
                isSubscribed = true;
                sendMsg("join");
            }

            @Override
            public void onFailure(ErrorInfo errorInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "加入频道失败: " + errorInfo);
            }
        });
    }

    private void unsubscribe() {
        if (mRtmClient == null) {
            LogUtils.e(LOG_MSG_PREFIX + "client is null");
            return;
        }

        if (!isSubscribed) {
            return;
        }

        mRtmClient.unsubscribe(mChannelName, new ResultCallback<>() {
            @Override
            public void onSuccess(Void responseInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "离开频道成功");
                isSubscribed = false;
            }

            @Override
            public void onFailure(ErrorInfo errorInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "离开频道失败: " + errorInfo);
            }
        });
    }

    private void logout() {
        if (mRtmClient == null) {
            LogUtils.e(LOG_MSG_PREFIX + "client is null");
            return;
        }

        if (!isLogin) {
            return;
        }

        mRtmClient.logout(new ResultCallback<>() {
            @Override
            public void onSuccess(Void responseInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "退出rtm服务器成功");
                isLogin = false;
            }

            @Override
            public void onFailure(ErrorInfo errorInfo) {
                LogUtils.e(LOG_MSG_PREFIX + "退出rtm服务器失败: " + errorInfo);
            }
        });
    }

    public void sendMsg(String message) {
        if (mRtmClient == null) {
            LogUtils.e(LOG_MSG_PREFIX + "client is null");
            return;
        }

        PublishOptions options = new PublishOptions();
        options.setCustomType("");
        mRtmClient.publish(mChannelName, message, options, new ResultCallback<>() {
            @Override
            public void onSuccess(Void responseInfo) {
                String text = "Message sent to channel " + mChannelName + " : " + message + "\n";
                LogUtils.e(LOG_MSG_PREFIX + text);
            }

            @Override
            public void onFailure(ErrorInfo errorInfo) {
                String text = "Message fails to send to channel " + mChannelName + " Error: " + errorInfo + "\n";
                LogUtils.e(LOG_MSG_PREFIX + text);
            }
        });
    }

    public void stop() {
        try {
            if (mRtmClient != null) {
                unsubscribe();
                logout();
                mRtmClient = null;
            }
        } catch (Exception e) {
            LogUtils.e(LOG_MSG_PREFIX + "rtm 清理异常: " + e.getMessage());
        }
    }
}

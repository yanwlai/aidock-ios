package com.clevo.aidockclient.network.agora.utils;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.clevo.aidockclient.R;
import com.clevo.aidockclient.utils.LogUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.Objects;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;

/**
 * The type Token utils.
 */
public final class TokenUtils {
    private final static OkHttpClient CLIENT;

    private TokenUtils() {

    }

    static {
        CLIENT = new OkHttpClient.Builder()
                .build();
    }

    /**
     * 生成 RTC Token（频道通话用）。
     */
    public static void genToken(Context context, String channelName, int uid, OnTokenGenCallback<String> onGetToken) {
        String cert = context.getString(R.string.agora_app_certificate);
        if (cert.isEmpty()) {
            onGetToken.onTokenGen("");
        } else {
            gen(context.getString(R.string.agora_app_id), context.getString(R.string.agora_app_certificate), channelName, uid, ret -> {
                if (onGetToken != null) {
                    runOnUiThread(() -> {
                        onGetToken.onTokenGen(ret);
                    });
                }
            }, ret -> {
                LogUtils.e("请求rtc token异常: " + ret.getMessage());
                if (onGetToken != null) {
                    runOnUiThread(() -> {
                        onGetToken.onTokenGen(null);
                    });
                }
            });
        }
    }

    /**
     * Gen.
     *
     * @param context     the context
     * @param channelName the channel name
     * @param uid         the uid
     * @param onGetToken  the on get token
     */
    public static void gen(Context context, String channelName, int uid, OnTokenGenCallback<String> onGetToken) {
        gen(context.getString(R.string.agora_app_id), context.getString(R.string.agora_app_certificate), channelName, uid, ret -> {
            if (onGetToken != null) {
                runOnUiThread(() -> {
                    onGetToken.onTokenGen(ret);
                });
            }
        }, ret -> {
            LogUtils.e("请求rtc token异常: " + ret.getMessage());
            if (onGetToken != null) {
                runOnUiThread(() -> {
                    onGetToken.onTokenGen(null);
                });
            }
        });
    }

    /**
     * 生成 RTM Token（信令/消息用），只依赖 RTM 用户 ID。
     *
     * @param context    上下文
     * @param rtmUserId  RTM 用户 ID（字符串）
     * @param onGetToken 回调
     */
    public static void genRtmToken(Context context, String rtmUserId, OnTokenGenCallback<String> onGetToken) {
        String appId = context.getString(R.string.agora_app_id);
        String certificate = context.getString(R.string.agora_app_certificate);
        if (TextUtils.isEmpty(certificate)) {
            if (onGetToken != null) {
                runOnUiThread(() -> onGetToken.onTokenGen(""));
            }
            return;
        }
        genRtm(appId, certificate, rtmUserId, ret -> {
            if (onGetToken != null) {
                runOnUiThread(() -> onGetToken.onTokenGen(ret));
            }
        }, e -> {
            LogUtils.e("请求rtm token异常: " + e.getMessage());
            if (onGetToken != null) {
                runOnUiThread(() -> onGetToken.onTokenGen(null));
            }
        });
    }

    private static void runOnUiThread(@NonNull Runnable runnable) {
        if (Thread.currentThread() == Looper.getMainLooper().getThread()) {
            runnable.run();
        } else {
            new Handler(Looper.getMainLooper()).post(runnable);
        }
    }

    private static void gen(String appId, String certificate, String channelName, int uid, OnTokenGenCallback<String> onGetToken, OnTokenGenCallback<Exception> onError) {
        if (TextUtils.isEmpty(appId) || TextUtils.isEmpty(certificate) || TextUtils.isEmpty(channelName)) {
            LogUtils.e("请求rtc token参数异常: appId=" + appId + ", certificate=" + certificate + ", channelName=" + channelName);
            if (onError != null) {
                onError.onTokenGen(new IllegalArgumentException("appId=" + appId + ", certificate=" + certificate + ", channelName=" + channelName));
            }
            return;
        }
        JSONObject postBody = new JSONObject();
        try {
            postBody.put("appId", appId);
            postBody.put("appCertificate", certificate);
            postBody.put("channelName", channelName);
            postBody.put("expire", 43200); // s
            postBody.put("src", "Android");
            postBody.put("ts", System.currentTimeMillis() + "");
            postBody.put("type", 1); // 1: RTC Token ; 2: RTM Token
            postBody.put("uid", uid + "");
        } catch (JSONException e) {
            LogUtils.e("请求rtc token Json解析异常: " + e.getMessage());
            if (onError != null) {
                onError.onTokenGen(e);
            }
        }

        Request request = new Request.Builder()
                .url("https://service.agora.io/toolbox-global/v1/token/generate")
                .addHeader("Content-Type", "application/json")
                .post(RequestBody.create(postBody.toString(), null))
                .build();
        CLIENT.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                LogUtils.e("请求rtc token，onFailure: " + e.getMessage());
                if (onError != null) {
                    onError.onTokenGen(e);
                }
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                ResponseBody body = response.body();
                if (body != null) {
                    try {
                        JSONObject jsonObject = new JSONObject(body.string());
                        JSONObject data = jsonObject.optJSONObject("data");
                        String token = Objects.requireNonNull(data).optString("token");
                        if (onGetToken != null) {
                            onGetToken.onTokenGen(token);
                        }
                    } catch (Exception e) {
                        LogUtils.e("请求rtc token，onResponse: " + e.getMessage());
                        if (onError != null) {
                            onError.onTokenGen(e);
                        }
                    }
                }
            }
        });
    }

    /**
     * 内部方法：生成 RTM Token。
     */
    private static void genRtm(String appId,
                               String certificate,
                               String rtmUserId,
                               OnTokenGenCallback<String> onGetToken,
                               OnTokenGenCallback<Exception> onError) {
        if (TextUtils.isEmpty(appId) || TextUtils.isEmpty(certificate) || TextUtils.isEmpty(rtmUserId)) {
            if (onError != null) {
                LogUtils.e("请求rtm token参数异常: appId=" + appId + ", certificate=" + certificate + ", rtmUserId=" + rtmUserId);
                onError.onTokenGen(new IllegalArgumentException("appId=" + appId + ", certificate=" + certificate + ", rtmUserId=" + rtmUserId));
            }
            return;
        }

        JSONObject postBody = new JSONObject();
        try {
            postBody.put("appId", appId);
            postBody.put("appCertificate", certificate);
            // RTM 不依赖频道，这里给空字符串
            postBody.put("channelName", "");
            postBody.put("expire", 43200); // s
            postBody.put("src", "Android");
            postBody.put("ts", System.currentTimeMillis() + "");
            postBody.put("type", 2); // 2: RTM Token
            postBody.put("uid", rtmUserId);
        } catch (JSONException e) {
            LogUtils.e("请求rtm token Json解析异常: " + e.getMessage());
            if (onError != null) {
                onError.onTokenGen(e);
            }
        }

        Request request = new Request.Builder()
                .url("https://service.agora.io/toolbox-global/v1/token/generate")
                .addHeader("Content-Type", "application/json")
                .post(RequestBody.create(postBody.toString(), null))
                .build();
        CLIENT.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                LogUtils.e("请求rtm token，onFailure: " + e.getMessage());
                if (onError != null) {
                    onError.onTokenGen(e);
                }
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                ResponseBody body = response.body();
                if (body != null) {
                    try {
                        JSONObject jsonObject = new JSONObject(body.string());
                        JSONObject data = jsonObject.optJSONObject("data");
                        String token = Objects.requireNonNull(data).optString("token");
                        if (onGetToken != null) {
                            onGetToken.onTokenGen(token);
                        }
                    } catch (Exception e) {
                        LogUtils.e("请求rtm token，onResponse: " + e.getMessage());
                        if (onError != null) {
                            onError.onTokenGen(e);
                        }
                    }
                }
            }
        });
    }

    /**
     * The interface On token gen callback.
     *
     * @param <T> the type parameter
     */
    public interface OnTokenGenCallback<T> {
        /**
         * On token gen.
         *
         * @param token the token
         */
        void onTokenGen(T token);
    }

}

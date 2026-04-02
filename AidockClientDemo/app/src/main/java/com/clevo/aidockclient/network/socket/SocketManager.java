package com.clevo.aidockclient.network.socket;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.clevo.aidockclient.helper.listener.OnWebSocketListener;
import com.clevo.aidockclient.utils.LogUtils;

import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import okio.ByteString;

public class SocketManager extends WebSocketListener {
    private final OkHttpClient client;
    private WebSocket socket;
    private OnWebSocketListener listener;
    private SocketStatus status;
    private Timer timer; // 心跳定时器
    private String heartCheckMsg = "HEART_CHECK"; // 发给服务端的心跳消息
    private Map<String, String> headers = new HashMap<>(); // 请求头

    public SocketManager() {
        client = new OkHttpClient.Builder().build();
    }

    public Map<String, String> getHeaders() {
        return headers;
    }

    public void setHeaders(Map<String, String> headers) {
        this.headers = headers;
    }

    public void connect(String clientId, String useId, OnWebSocketListener listener) {
        this.listener = listener;

        Request.Builder builder = new Request.Builder();
        if (headers != null && !headers.isEmpty()) {
            headers.forEach(builder::addHeader);
        }
        String url = SocketUrl.BASE_URL + SocketUrl.CONNECT + "";
        Request req = builder.url(url).build();
        socket = client.newWebSocket(req, this);
        status = SocketStatus.CONNECTING;
    }

    public void reConnect() {
        if (socket != null) {
            socket = client.newWebSocket(socket.request(), this);
            status = SocketStatus.CONNECTING;
        }
    }

    public boolean isOpen() {
        return socket != null && status == SocketStatus.OPEN;
    }

    public void send(String text) {
        if (isOpen()) socket.send(text);
    }

    public void sendBytes(ByteString bytes) {
        if (isOpen()) socket.send(bytes);
    }

    public void cancel() {
        if (socket != null) socket.cancel();
    }

    public void close(int code, String msg) {
        if (socket != null) socket.close(code, msg);
    }

    public SocketStatus getStatus() {
        return status;
    }

    public void setStatus(SocketStatus status) {
        this.status = status;
    }

    @Override
    public void onClosed(@NonNull WebSocket webSocket, int code, @NonNull String reason) {
        super.onClosed(webSocket, code, reason);
        LogUtils.e("onClosed", reason);
        status = SocketStatus.CLOSED;
        if (listener != null) listener.onClosed(code, reason);
    }

    @Override
    public void onClosing(@NonNull WebSocket webSocket, int code, @NonNull String reason) {
        super.onClosing(webSocket, code, reason);
        LogUtils.e("onClosing", reason);
        status = SocketStatus.CLOSING;
        if (listener != null) listener.onClosing(code, reason);
    }

    @Override
    public void onFailure(@NonNull WebSocket webSocket, @NonNull Throwable t, @Nullable Response response) {
        super.onFailure(webSocket, t, response);
        status = SocketStatus.FAILED;
        if (listener != null) listener.onFailed();
    }

    @Override
    public void onMessage(@NonNull WebSocket webSocket, @NonNull String text) {
        super.onMessage(webSocket, text);
        if (listener != null) listener.onMessage(text);
    }

    @Override
    public void onMessage(@NonNull WebSocket webSocket, @NonNull ByteString bytes) {
        super.onMessage(webSocket, bytes);
        if (listener != null) listener.onMessage(bytes);
    }

    @Override
    public void onOpen(@NonNull WebSocket webSocket, @NonNull Response response) {
        super.onOpen(webSocket, response);
        status = SocketStatus.OPEN;
        if (listener != null) listener.onOpen();
    }

    // 开启心跳检测,delay单位毫秒
    public void startHeartCheck(long period) {
        if (timer != null) timer.cancel();
        timer = new Timer();
        TimerTask task = new TimerTask() {
            @Override
            public void run() {
                if (isOpen()) socket.send(heartCheckMsg);
            }
        };
        timer.schedule(task, 0, period);
    }

    public void closeHeartCheck() {
        if (timer != null) {
            timer.cancel();
            timer = null;
        }
    }

    public void setHeartCheckMsg(String heartCheckMsg) {
        this.heartCheckMsg = heartCheckMsg;
    }
}

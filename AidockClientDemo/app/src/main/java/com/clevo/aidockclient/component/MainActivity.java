package com.clevo.aidockclient.component;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.view.SurfaceView;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.Toast;
import android.widget.ToggleButton;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.clevo.aidockclient.R;
import com.clevo.aidockclient.network.agora.listener.OnRTCEventListener;
import com.clevo.aidockclient.network.agora.listener.OnRTMEventListener;
import com.clevo.aidockclient.network.agora.rtc.InputCommand;
import com.clevo.aidockclient.network.agora.rtc.RTCManager;
import com.clevo.aidockclient.network.agora.rtc.TouchEventHandler;
import com.clevo.aidockclient.network.agora.rtm.RTMEventHandler;
import com.clevo.aidockclient.network.agora.rtm.RTMManager;
import com.clevo.aidockclient.utils.LogUtils;
import com.clevo.aidockclient.utils.PermissionUtils;
import com.hjq.permissions.permission.PermissionLists;

import java.util.List;

public class MainActivity extends AppCompatActivity {
    private FrameLayout fl_remote;
    private int remoteUid = -1;
    private Handler handler;
    private RTCManager mRtcManager;
    private RTMManager mRtmManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_root), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
        handler = new Handler(Looper.getMainLooper());

        fl_remote = findViewById(R.id.fl_screenshare);

        initNavBar();

        PermissionUtils.checkPermission(this,
                List.of(PermissionLists.getCameraPermission(), PermissionLists.getRecordAudioPermission()),
                () -> {
                    initRTC();
                    initRTM();
                });
    }

    private void initNavBar() {
        ImageButton btnBack = findViewById(R.id.btn_back);
        ImageButton btnHome = findViewById(R.id.btn_home);
        ImageButton btnRecents = findViewById(R.id.btn_recents);

        btnBack.setOnClickListener(v -> sendKeyCommand(KeyEvent.KEYCODE_BACK));
        btnHome.setOnClickListener(v -> sendKeyCommand(KeyEvent.KEYCODE_HOME));
        btnRecents.setOnClickListener(v -> sendKeyCommand(KeyEvent.KEYCODE_APP_SWITCH));

        ToggleButton btnToggleMedia = findViewById(R.id.btn_toggle_media);
        btnToggleMedia.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (mRtcManager != null) {
                mRtcManager.setLocalMediaEnabled(isChecked);
            }
        });
    }

    /**
     * 发送按键指令到云机（DOWN + UP 组合）
     */
    private void sendKeyCommand(int keyCode) {
        if (mRtcManager == null || !mRtcManager.isControlReady()) {
            LogUtils.e("DataStream not ready, cannot send key command");
            return;
        }
        mRtcManager.sendCommand(InputCommand.key(keyCode, KeyEvent.ACTION_DOWN));
        mRtcManager.sendCommand(InputCommand.key(keyCode, KeyEvent.ACTION_UP));
    }

    private void initRTC() {
        mRtcManager = new RTCManager(this);
        mRtcManager.init(new OnRTCEventListener() {
            @Override
            public void onError(int err, String msg) {
                showLongToast(String.format("onError code %d message %s", err, msg));
            }

            @Override
            public void onJoinChannelSuccess(String channel, int uid) {
                showLongToast(String.format("onJoinChannelSuccess channel %s uid %d", channel, uid));
                mRtcManager.setJoined(true);
                // 加入频道成功后创建 DataStream 并绑定触摸
                handler.post(() -> setupRemoteControl());
            }

            @Override
            public void onUserJoined(int uid) {
                showLongToast(String.format("user %d joined!", uid));
                if (remoteUid > 0) return;
                remoteUid = uid;
                runOnUiThread(() -> {
                    SurfaceView renderView = new SurfaceView(MainActivity.this);
                    mRtcManager.setupRemoteVideo(renderView, uid);
                    fl_remote.removeAllViews();
                    fl_remote.addView(renderView);
                });
            }

            @Override
            public void onUserOffline(int uid) {
                showLongToast(String.format("user %d offline!", uid));
                if (remoteUid == uid) {
                    remoteUid = -1;
                    runOnUiThread(() -> {
                        fl_remote.removeAllViews();
                        mRtcManager.removeRemoteVideo(uid);
                    });
                }
            }
        });

        mRtcManager.joinChannel();
    }

    /**
     * 创建 DataStream 并绑定触摸事件到远端屏幕视图
     */
    private void setupRemoteControl() {
        mRtcManager.createDataStream();
        if (mRtcManager.isControlReady()) {
            LogUtils.d("DataStream created, bindind touch handler to remote view");
            TouchEventHandler touchHandler = new TouchEventHandler(mRtcManager.getDataStreamManager());
            fl_remote.setOnTouchListener(touchHandler);
        } else {
            LogUtils.e("Failed to create DataStream");
        }
    }

    private void initRTM() {
        mRtmManager = new RTMManager(this);
        mRtmManager.init(new RTMEventHandler(new OnRTMEventListener() {
            @Override
            public void onMessage(Object msg) {
            }

            @Override
            public void onPresence(String msg) {
            }
        }));

        mRtmManager.getToken((success, token) -> {
            if (success) {
                if (handler != null) {
                    handler.post(() -> mRtmManager.login(token, () -> {
                        mRtmManager.subscribe();
                        showLongToast("登录rtm服务器成功");
                    }));
                }
            }
        });
    }

    private void showLongToast(final String msg) {
        if (handler == null) return;
        handler.post(() -> Toast.makeText(getApplicationContext(), msg, Toast.LENGTH_LONG).show());
    }

    @Override
    protected void onDestroy() {
        LogUtils.e("onDestroy");
        if (mRtmManager != null) {
            mRtmManager.sendMsg("leave");
            mRtmManager.stop();
        }
        if (mRtcManager != null) {
            mRtcManager.destroy();
        }
        super.onDestroy();
    }
}

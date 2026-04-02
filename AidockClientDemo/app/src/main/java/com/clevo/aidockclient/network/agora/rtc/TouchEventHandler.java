package com.clevo.aidockclient.network.agora.rtc;

import android.view.MotionEvent;
import android.view.View;

import com.clevo.aidockclient.utils.LogUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * 捕获远端屏幕视图上的触摸事件，归一化坐标后通过 DataStream 发送到云机
 * <p>
 * 内置节流：MOVE 事件最小间隔 16ms（~60fps），防止超出 Data Stream 包频率限制
 */
public class TouchEventHandler implements View.OnTouchListener {
    private static final String TAG = "TouchEventHandler";
    private static final long MOVE_THROTTLE_MS = 16; // ~60fps

    private final DataStreamManager dataStreamManager;
    private long lastMoveTime = 0;

    public TouchEventHandler(DataStreamManager dataStreamManager) {
        this.dataStreamManager = dataStreamManager;
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        if (dataStreamManager == null || !dataStreamManager.isReady()) {
            return false;
        }

        int actionMasked = event.getActionMasked();

        // MOVE 事件节流
        if (actionMasked == MotionEvent.ACTION_MOVE) {
            long now = System.currentTimeMillis();
            if (now - lastMoveTime < MOVE_THROTTLE_MS) {
                return true; // 消费事件但不发送
            }
            lastMoveTime = now;
        }

        // 收集所有触点的归一化坐标
        int width = v.getWidth();
        int height = v.getHeight();
        if (width <= 0 || height <= 0) {
            return false;
        }

        List<InputCommand.Pointer> pointers = new ArrayList<>(event.getPointerCount());
        for (int i = 0; i < event.getPointerCount(); i++) {
            float normX = clamp(event.getX(i) / width, 0f, 1f);
            float normY = clamp(event.getY(i) / height, 0f, 1f);
            pointers.add(new InputCommand.Pointer(event.getPointerId(i), normX, normY));
        }

        InputCommand cmd = InputCommand.touch(actionMasked, pointers);
        int ret = dataStreamManager.sendCommand(cmd);
        if (ret < 0) {
            LogUtils.e(TAG + " sendCommand failed: " + ret);
        }
        return true;
    }

    private static float clamp(float val, float min, float max) {
        return Math.max(min, Math.min(max, val));
    }
}

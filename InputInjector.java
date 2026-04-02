package com.clevo.aidockserviceapp.network.agora.rtc;

import android.content.Context;
import android.hardware.input.InputManager;
import android.os.SystemClock;
import android.util.DisplayMetrics;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.KeyEvent;
import android.view.MotionEvent;

import com.clevo.aidockserviceapp.utils.LogUtils;

import java.lang.reflect.Method;
import java.util.List;

/**
 * 系统级输入注入器
 * 利用系统签名权限通过 InputManager.injectInputEvent 注入触摸/按键事件
 */
public class InputInjector {
    private static final String TAG = "InputInjector";

    private final int screenWidth;
    private final int screenHeight;
    private Method injectMethod;
    private InputManager inputManager;

    // 多点触控状态跟踪
    private MotionEvent.PointerProperties[] lastProperties;
    private MotionEvent.PointerCoords[] lastCoords;
    private long downTime = 0;

    public InputInjector(Context context) {
        DisplayMetrics metrics = context.getResources().getDisplayMetrics();
        screenWidth = metrics.widthPixels;
        screenHeight = metrics.heightPixels;

        try {
            inputManager = (InputManager) context.getSystemService(Context.INPUT_SERVICE);
            injectMethod = InputManager.class.getMethod(
                    "injectInputEvent", InputEvent.class, int.class);
        } catch (Exception e) {
            LogUtils.e(TAG + " init failed: " + e.getMessage());
        }
    }

    /**
     * 分发控制指令
     */
    public void dispatch(InputCommand cmd) {
        if (cmd == null) return;
        switch (cmd.getType()) {
            case InputCommand.TYPE_TOUCH:
                injectTouch(cmd.getAction(), cmd.getPointers());
                break;
            case InputCommand.TYPE_KEY:
                injectKey(cmd.getKeyCode(), cmd.getAction());
                break;
            case InputCommand.TYPE_TEXT:
                injectText(cmd.getContent());
                break;
        }
    }

    private void injectTouch(int action, List<InputCommand.Pointer> pointers) {
        if (pointers == null || pointers.isEmpty()) return;

        long now = SystemClock.uptimeMillis();

        // ACTION_DOWN 时记录按下时间
        if (action == MotionEvent.ACTION_DOWN) {
            downTime = now;
        }

        int pointerCount = pointers.size();
        MotionEvent.PointerProperties[] properties = new MotionEvent.PointerProperties[pointerCount];
        MotionEvent.PointerCoords[] coords = new MotionEvent.PointerCoords[pointerCount];

        for (int i = 0; i < pointerCount; i++) {
            InputCommand.Pointer p = pointers.get(i);

            MotionEvent.PointerProperties prop = new MotionEvent.PointerProperties();
            prop.id = p.id;
            prop.toolType = MotionEvent.TOOL_TYPE_FINGER;
            properties[i] = prop;

            MotionEvent.PointerCoords coord = new MotionEvent.PointerCoords();
            coord.x = p.x * screenWidth;
            coord.y = p.y * screenHeight;
            coord.pressure = 1.0f;
            coord.size = 1.0f;
            coords[i] = coord;
        }

        lastProperties = properties;
        lastCoords = coords;

        MotionEvent event = MotionEvent.obtain(
                downTime, now, action,
                pointerCount, properties, coords,
                0, 0, 1.0f, 1.0f,
                0, 0,
                InputDevice.SOURCE_TOUCHSCREEN, 0
        );

        injectEvent(event);
        event.recycle();
    }

    private void injectKey(int keyCode, int action) {
        long now = SystemClock.uptimeMillis();
        KeyEvent event = new KeyEvent(
                now, now, action, keyCode, 0,
                0, -1, 0, 0,
                InputDevice.SOURCE_KEYBOARD
        );
        injectEvent(event);
    }

    private void injectText(String text) {
        if (text == null || text.isEmpty()) return;
        // 逐字符通过 KeyCharacterMap 注入
        for (char c : text.toCharArray()) {
            // 使用 KeyEvent 的 dispatch 方式逐字符输入
            long now = SystemClock.uptimeMillis();
            KeyEvent downEvent = new KeyEvent(now, String.valueOf(c),
                    0, 0);
            injectEvent(downEvent);
        }
    }

    private void injectEvent(InputEvent event) {
        if (injectMethod == null || inputManager == null) {
            LogUtils.e(TAG + " injectMethod or inputManager is null");
            return;
        }
        try {
            // INJECT_INPUT_EVENT_MODE_ASYNC = 0
            injectMethod.invoke(inputManager, event, 0);
        } catch (Exception e) {
            LogUtils.e(TAG + " inject failed: " + e.getMessage());
        }
    }
}

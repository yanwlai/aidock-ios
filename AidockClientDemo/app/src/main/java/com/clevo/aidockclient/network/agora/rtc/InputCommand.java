package com.clevo.aidockclient.network.agora.rtc;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * 控制指令协议，客户端 → 云机
 * 通过 RTC Data Stream 传输
 */
public class InputCommand {

    public static final String TYPE_TOUCH = "touch";
    public static final String TYPE_KEY = "key";
    public static final String TYPE_TEXT = "text";

    private String type;
    private int action;
    private List<Pointer> pointers;
    private int keyCode;
    private String content;
    private long ts;

    public static class Pointer {
        public int id;
        public float x; // 归一化坐标 0~1
        public float y; // 归一化坐标 0~1

        public Pointer(int id, float x, float y) {
            this.id = id;
            this.x = x;
            this.y = y;
        }
    }

    private InputCommand(String type) {
        this.type = type;
        this.ts = System.currentTimeMillis();
    }

    /**
     * 构建触摸指令
     *
     * @param action   MotionEvent.getActionMasked()
     * @param pointers 所有触点的归一化坐标
     */
    public static InputCommand touch(int action, List<Pointer> pointers) {
        InputCommand cmd = new InputCommand(TYPE_TOUCH);
        cmd.action = action;
        cmd.pointers = pointers;
        return cmd;
    }

    /**
     * 构建按键指令
     *
     * @param keyCode Android KeyEvent keyCode
     * @param action  0=DOWN, 1=UP
     */
    public static InputCommand key(int keyCode, int action) {
        InputCommand cmd = new InputCommand(TYPE_KEY);
        cmd.keyCode = keyCode;
        cmd.action = action;
        return cmd;
    }

    /**
     * 构建文本输入指令
     */
    public static InputCommand text(String content) {
        InputCommand cmd = new InputCommand(TYPE_TEXT);
        cmd.content = content;
        return cmd;
    }

    /**
     * 序列化为 JSON bytes，用于 sendStreamMessage
     */
    public byte[] toBytes() {
        JSONObject json = new JSONObject();
        json.put("type", type);
        json.put("ts", ts);

        switch (type) {
            case TYPE_TOUCH:
                json.put("action", action);
                JSONArray arr = new JSONArray();
                if (pointers != null) {
                    for (Pointer p : pointers) {
                        JSONObject pObj = new JSONObject();
                        pObj.put("id", p.id);
                        pObj.put("x", p.x);
                        pObj.put("y", p.y);
                        arr.add(pObj);
                    }
                }
                json.put("pointers", arr);
                break;
            case TYPE_KEY:
                json.put("keyCode", keyCode);
                json.put("action", action);
                break;
            case TYPE_TEXT:
                json.put("content", content);
                break;
        }
        return json.toJSONString().getBytes(StandardCharsets.UTF_8);
    }
}

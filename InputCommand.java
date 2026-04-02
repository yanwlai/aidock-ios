package com.clevo.aidockserviceapp.network.agora.rtc;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * 控制指令协议：客户端 → 云机
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

    public String getType() {
        return type;
    }

    public int getAction() {
        return action;
    }

    public List<Pointer> getPointers() {
        return pointers;
    }

    public int getKeyCode() {
        return keyCode;
    }

    public String getContent() {
        return content;
    }

    /**
     * 从 Data Stream 接收的 bytes 反序列化
     */
    public static InputCommand fromBytes(byte[] data) {
        String json = new String(data, StandardCharsets.UTF_8);
        JSONObject obj = JSON.parseObject(json);
        if (obj == null) return null;

        String type = obj.getString("type");
        if (type == null) return null;

        InputCommand cmd = new InputCommand();
        cmd.type = type;
        cmd.ts = obj.getLongValue("ts");

        switch (type) {
            case TYPE_TOUCH:
                cmd.action = obj.getIntValue("action");
                JSONArray arr = obj.getJSONArray("pointers");
                cmd.pointers = new ArrayList<>();
                if (arr != null) {
                    for (int i = 0; i < arr.size(); i++) {
                        JSONObject p = arr.getJSONObject(i);
                        cmd.pointers.add(new Pointer(
                                p.getIntValue("id"),
                                p.getFloatValue("x"),
                                p.getFloatValue("y")
                        ));
                    }
                }
                break;
            case TYPE_KEY:
                cmd.keyCode = obj.getIntValue("keyCode");
                cmd.action = obj.getIntValue("action");
                break;
            case TYPE_TEXT:
                cmd.content = obj.getString("content");
                break;
        }
        return cmd;
    }

    private InputCommand() {
    }
}

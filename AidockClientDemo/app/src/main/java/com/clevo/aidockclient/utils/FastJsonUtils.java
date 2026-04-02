package com.clevo.aidockclient.utils;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class FastJsonUtils {
    public static <T> T getObject(Object jsonString, Class<T> cls) {
        T t = null;
        try {
            if (jsonString != null) {
                if (jsonString instanceof String)
                    t = JSON.parseObject(jsonString.toString(), cls);
                else
                    t = JSON.parseObject(JSONObject.toJSONString(jsonString), cls);
            }
        } catch (Exception e) {
            LogUtils.e(e);
        }
        return t;
    }

    public static <T> List<T> getArray(Object jsonString, Class<T> cls) {
        List<T> list = new ArrayList<>();
        try {
            if (jsonString != null) {
                if (jsonString instanceof String)
                    list = JSON.parseArray(jsonString.toString(), cls);
                else
                    list = JSON.parseArray(JSONObject.toJSONString(jsonString), cls);
            }
        } catch (Exception e) {
            LogUtils.e(e);
        }
        return list;
    }

    /**
     * get格式转json
     *
     * @param string limit=10&page=1&category=1
     */
    public static JSONObject getJSONObject(String string) {
        JSONObject object = new JSONObject();
        try {
            if (string.contains("&")) {
                String[] array = string.split("&");
                for (String s : array) {
                    String[] data = s.split("=");
                    if (data.length > 1)
                        object.put(data[0], data[1]);
                    else
                        object.put(data[0], "");
                }
            } else {
                String[] data = string.split("=");
                if (data.length > 1)
                    object.put(data[0], data[1]);
                else
                    object.put(data[0], "");
            }
        } catch (Exception e) {
            object = new JSONObject();
        }
        return object;
    }
}

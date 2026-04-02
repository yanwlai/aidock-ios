package com.clevo.aidockclient.utils;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.List;

/**
 * Gson
 */
public class GsUtils {
    /**
     * 对象转换为Json字符串
     */
    public static <T> String toJson(T t) {
        Gson gson = new Gson();
        return gson.toJson(t, t.getClass());
    }

    /**
     * 集合转换为Json字符串
     *
     * @param ts  需要转换的集合
     * @param <T> 集合中的对象类型
     * @return json字符串
     */
    public static <T> String toJson(List<T> ts) {
        Gson gson = new Gson();
        Type type = new TypeToken<List<T>>() {
        }.getType();
        return gson.toJson(ts, type);
    }


    /**
     * 将json字符串转换为指定的类型
     *
     * @param json json字符串
     * @param type 转换结果类型
     * @param <T>  转换结果
     * @return 返回转换的结果
     */
    public static <T> T fromJson(String json, Type type) {
        Gson gson = new Gson();
        return gson.fromJson(json, type);
    }
}

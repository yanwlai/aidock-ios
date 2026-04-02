package com.clevo.aidockclient.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Base64;

import com.clevo.aidockclient.base.MyApp;
import com.clevo.aidockclient.helper.ConstantHelper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

public class SharePUtils {
    private SharedPreferences sp;
    private final SharedPreferences.Editor editor;
    private static volatile SharePUtils mshareUtils; // 私人
    private static volatile SharePUtils cshareUtils; // 公共

    public SharePUtils(int type) {
        if (type == ConstantHelper.SHARED_PUBLIC_CODE) { // 公共数据
            sp = MyApp.getInstance().getSharedPreferences("common_info", Context.MODE_PRIVATE);
        } else if (type == ConstantHelper.SHARED_PRIVATE_CODE) { // 个人登录数据
            sp = MyApp.getInstance().getSharedPreferences("info", Context.MODE_PRIVATE);
        }
        editor = sp.edit();
    }

    public static SharePUtils getInstance(int type) {
        if (type == 0) {
            if (cshareUtils == null) {
                synchronized (SharePUtils.class) {
                    if (cshareUtils == null) {
                        cshareUtils = new SharePUtils(type);
                    }
                }
            }
            return cshareUtils;
        } else {
            if (mshareUtils == null)
                synchronized (SharePUtils.class) {
                    if (mshareUtils == null) {
                        mshareUtils = new SharePUtils(type);
                    }
                }
            return mshareUtils;
        }
    }

    /**
     * 保存数据的方法，我们需要拿到保存数据的具体类型，然后根据类型调用不同的保存方法
     */
    public void put(String key, Object object) {
        try {
            if (object instanceof String) {
                editor.putString(key, (String) object);
            } else if (object instanceof Integer) {
                editor.putInt(key, (Integer) object);
            } else if (object instanceof Boolean) {
                editor.putBoolean(key, (Boolean) object);
            } else if (object instanceof Float) {
                editor.putFloat(key, (Float) object);
            } else if (object instanceof Long) {
                editor.putLong(key, (Long) object);
            } else {
                if (object == null) {
                    editor.putString(key, "");
                } else {
                    editor.putString(key, object.toString());
                }
            }
            editor.commit();
        } catch (Exception e) {
            LogUtils.e(e);
        }
    }

    /**
     * 得到保存数据的方法，我们根据默认值得到保存的数据的具体类型，然后调用相对于的方法获取值
     */
    public Object get(String key, Object defaultObject) {
        try {
            if (defaultObject instanceof String) {
                return sp.getString(key, (String) defaultObject);
            } else if (defaultObject instanceof Integer) {
                return sp.getInt(key, (Integer) defaultObject);
            } else if (defaultObject instanceof Boolean) {
                return sp.getBoolean(key, (Boolean) defaultObject);
            } else if (defaultObject instanceof Float) {
                return sp.getFloat(key, (Float) defaultObject);
            } else if (defaultObject instanceof Long) {
                return sp.getLong(key, (Long) defaultObject);
            }
            return defaultObject;
        } catch (Exception e) {
            return defaultObject;
        }
    }

    /**
     * 针对复杂类型存储<对象>
     */
    public void setObject(String key, Object object) {
        //创建字节输出流
        //创建字节对象输出流
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream(); ObjectOutputStream out = new ObjectOutputStream(baos)) {
            try {
                //然后通过将字对象进行64转码，写入key值为key的sp中
                out.writeObject(object);
                String objectVal = new String(Base64.encode(baos.toByteArray(), Base64.DEFAULT));
                editor.putString(key, objectVal);
                editor.commit();
            } catch (IOException e) {
                LogUtils.e(e);
            }
        } catch (IOException e) {
            LogUtils.e(e);
        }
    }

    @SuppressWarnings("unchecked")
    public <T> T getObject(String key, Class<T> clazz) {
        if (sp.contains(key)) {
            String objectVal = sp.getString(key, null);
            byte[] buffer = Base64.decode(objectVal, Base64.DEFAULT);
            try (ByteArrayInputStream bais = new ByteArrayInputStream(buffer); ObjectInputStream ois = new ObjectInputStream(bais)) {
                try {
                    return (T) ois.readObject();
                } catch (IOException | ClassNotFoundException e) {
                    LogUtils.e(e);
                }
            } catch (IOException e) {
                LogUtils.e(e);
            }
        }
        return null;
    }

    public void removeKey(String key) {
        editor.remove(key);
        editor.commit();
    }

    public void clearInfo() {
        editor.clear();
        editor.commit();
    }
}


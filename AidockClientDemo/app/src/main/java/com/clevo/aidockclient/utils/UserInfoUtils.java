package com.clevo.aidockclient.utils;

import com.clevo.aidockclient.helper.ConstantHelper;

public class UserInfoUtils {
    /**
     * 保存账户token
     */
    public static void saveAccountToken(String token, Integer userId) {
        SharePUtils.getInstance(ConstantHelper.SHARED_PRIVATE_CODE).put("account_token", token);
        SharePUtils.getInstance(ConstantHelper.SHARED_PRIVATE_CODE).put("user_id", userId);
        SharePUtils.getInstance(ConstantHelper.SHARED_PRIVATE_CODE).put("is_bind_account", true);
    }

    /**
     * 获取账户token
     */
    public static String getAccountToken() {
        return (String) SharePUtils.getInstance(ConstantHelper.SHARED_PRIVATE_CODE).get("account_token", "");
    }

    /**
     * 是否绑定账户
     */
    public static boolean isBindAccount() {
        return (boolean) SharePUtils.getInstance(ConstantHelper.SHARED_PRIVATE_CODE).get("is_bind_account", false);
    }

    /**
     * 获取连接设备的用户id
     */
    public static int getConnectUserId() {
        return (int) SharePUtils.getInstance(ConstantHelper.SHARED_PRIVATE_CODE).get("user_id", 0);
    }

    public static String getSerialNumber() {
        return "29231JEGR08100";
    }
}

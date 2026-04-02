package com.clevo.aidockclient.utils;

import android.app.Activity;

import com.clevo.aidockclient.helper.listener.OnPermissionListener;
import com.hjq.permissions.XXPermissions;
import com.hjq.permissions.permission.base.IPermission;

import java.util.List;

public class PermissionUtils {
    public static void checkPermission(Activity activity, List<IPermission> permissions, OnPermissionListener listener) {
        XXPermissions.with(activity)
                .permissions(permissions)
                .request((grantedList, deniedList) -> {
                    boolean allGranted = deniedList.isEmpty();
                    if (!allGranted) {
                        // 判断请求失败的权限是否被用户勾选了不再询问的选项
                        boolean doNotAskAgain = XXPermissions.isDoNotAskAgainPermissions(activity, deniedList);
                        if (doNotAskAgain) {
                            // 如果是被永久拒绝就跳转到应用权限系统设置页面
                            XXPermissions.startPermissionActivity(activity, deniedList);
                        }
                        return;
                    }
                    listener.onGranted();
                });
    }
}
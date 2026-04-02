package com.clevo.aidockclient.network.agora.utils;

import android.content.Context;
import android.media.projection.MediaProjection;
import android.os.IBinder;

import com.clevo.aidockclient.utils.LogUtils;

public class MediaProjectionUtils {
    public static MediaProjection createSilentMediaProjection(Context context) {
        try {
            Class<?> serviceManagerClass = Class.forName("android.os.ServiceManager");
            java.lang.reflect.Method getServiceMethod = serviceManagerClass.getMethod("getService", String.class);
            IBinder mpBinder = (IBinder) getServiceMethod.invoke(null, "media_projection");
            if (mpBinder == null) {
                LogUtils.e("media_projection service is null");
                return null;
            }

            Class<?> stubClass = Class.forName("android.media.projection.IMediaProjectionManager$Stub");
            java.lang.reflect.Method asInterfaceMethod = stubClass.getMethod("asInterface", IBinder.class);
            Object iMediaProjectionManager = asInterfaceMethod.invoke(null, mpBinder);
            if (iMediaProjectionManager == null) {
                LogUtils.e("IMediaProjectionManager is null");
                return null;
            }

            java.lang.reflect.Method createProjectionMethod = iMediaProjectionManager.getClass()
                    .getMethod("createProjection", int.class, String.class, int.class, boolean.class, int.class);
            Object projectionToken = createProjectionMethod.invoke(
                    iMediaProjectionManager,
                    android.os.Process.myUid(),
                    context.getPackageName(),
                    0,
                    true,
                    0
            );
            if (projectionToken == null) {
                LogUtils.e("projectionToken is null");
                return null;
            }

            Class<?> mediaProjectionClass = Class.forName("android.media.projection.MediaProjection");
            Object mediaProjection = null;
            for (java.lang.reflect.Constructor<?> ctor : mediaProjectionClass.getDeclaredConstructors()) {
                Class<?>[] paramTypes = ctor.getParameterTypes();
                if (paramTypes.length == 2
                        && Context.class.isAssignableFrom(paramTypes[0])
                        && paramTypes[1].isAssignableFrom(projectionToken.getClass())) {
                    ctor.setAccessible(true);
                    mediaProjection = ctor.newInstance(context.getApplicationContext(), projectionToken);
                    break;
                }
                if (paramTypes.length == 3
                        && Context.class.isAssignableFrom(paramTypes[0])
                        && (paramTypes[1] == int.class || paramTypes[1] == Integer.class)
                        && paramTypes[2].isAssignableFrom(projectionToken.getClass())) {
                    ctor.setAccessible(true);
                    mediaProjection = ctor.newInstance(context.getApplicationContext(), 0, projectionToken);
                    break;
                }
            }
            if (mediaProjection instanceof MediaProjection) {
                LogUtils.e("createSilentMediaProjection success");
                return (MediaProjection) mediaProjection;
            }
            LogUtils.e("createSilentMediaProjection: no matching MediaProjection constructor");
            return null;
        } catch (Throwable t) {
            LogUtils.e("createSilentMediaProjection failed" + t.getMessage());
            return null;
        }
    }
}

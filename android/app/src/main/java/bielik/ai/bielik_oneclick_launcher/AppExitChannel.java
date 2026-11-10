package bielik.ai.bielik_oneclick_launcher;

import android.app.ActivityManager;
import android.app.ApplicationExitInfo;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

final class AppExitChannel {
    static void register(Context context, BinaryMessenger messenger) {
        SharedPreferences preferences = context.getSharedPreferences("app_exit", Context.MODE_PRIVATE);
        new MethodChannel(
            messenger, "bielik/app_exit",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler((call, result) -> {
            try {
                if (call.method.equals("acknowledgeExit")) {
                    long timestamp = Long.parseLong((String) call.arguments);
                    long previous = preferences.getLong("acknowledged", 0);
                    if (!preferences.edit().putLong("acknowledged", Math.max(previous, timestamp)).commit()) {
                        result.error("SAVE_FAILED", "Could not acknowledge app exit.", null);
                        return;
                    }
                    result.success(null);
                } else if (call.method.equals("readPreviousExit")) {
                    result.success(read(context, preferences));
                } else {
                    result.notImplemented();
                }
            } catch (RuntimeException error) {
                result.error("EXIT_INFO_UNAVAILABLE", "Could not read app exit diagnostics.", null);
            }
        });
    }

    private static Map<String, Object> read(Context context, SharedPreferences preferences) {
        if (Build.VERSION.SDK_INT < 30) return null;
        ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        if (manager == null) return null;
        // Only the most recent exit of the main process matters, not downloader workers.
        for (ApplicationExitInfo info : manager.getHistoricalProcessExitReasons(null, 0, 32)) {
            if (!context.getPackageName().equals(info.getProcessName())) continue;
            if (info.getTimestamp() <= preferences.getLong("acknowledged", 0)) return null;
            int reason = info.getReason();
            if (reason == ApplicationExitInfo.REASON_EXIT_SELF
                || reason == ApplicationExitInfo.REASON_USER_REQUESTED
                || reason == ApplicationExitInfo.REASON_USER_STOPPED
                || reason == ApplicationExitInfo.REASON_PERMISSION_CHANGE
                || reason == ApplicationExitInfo.REASON_FREEZER
                || reason == ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE
                || reason == ApplicationExitInfo.REASON_PACKAGE_UPDATED) return null;
            Map<String, Object> values = new HashMap<>();
            values.put("id", Long.toString(info.getTimestamp()));
            values.put("lowMemory", reason == ApplicationExitInfo.REASON_LOW_MEMORY);
            values.put("code", "ANDROID_EXIT_" + reason + "_STATUS_" + info.getStatus());
            return values;
        }
        return null;
    }
}

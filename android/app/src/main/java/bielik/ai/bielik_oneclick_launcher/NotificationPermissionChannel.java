package bielik.ai.bielik_oneclick_launcher;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Build;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/**
 * Asks for POST_NOTIFICATIONS, which Android 13+ grants only at runtime. Without it the
 * progress notification of a model download is never shown.
 */
final class NotificationPermissionChannel {
    private static final int REQUEST_CODE = 0x6e70;
    private final Activity activity;
    private MethodChannel.Result pending;

    NotificationPermissionChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        new MethodChannel(messenger, "bielik/notification_permission").setMethodCallHandler((call, result) -> {
            if (!call.method.equals("request")) { result.notImplemented(); return; }
            request(result);
        });
    }

    private void request(MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < 33
            || activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            result.success(true);
            return;
        }
        if (pending != null) {
            result.success(false);
            return;
        }
        pending = result;
        try {
            activity.requestPermissions(new String[] {Manifest.permission.POST_NOTIFICATIONS}, REQUEST_CODE);
        } catch (RuntimeException error) {
            pending = null;
            result.success(false);
        }
    }

    /** Returns true when the result belonged to this channel. */
    boolean onResult(int requestCode, int[] grantResults) {
        if (requestCode != REQUEST_CODE) return false;
        MethodChannel.Result result = pending;
        pending = null;
        if (result != null) {
            result.success(grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED);
        }
        return true;
    }
}

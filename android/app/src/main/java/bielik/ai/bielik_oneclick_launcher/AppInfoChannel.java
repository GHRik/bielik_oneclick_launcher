package bielik.ai.bielik_oneclick_launcher;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.os.Build;
import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

final class AppInfoChannel {
    static void register(Context context, BinaryMessenger messenger) {
        new MethodChannel(messenger, "bielik/app_info").setMethodCallHandler((call, result) -> {
            if (!call.method.equals("version")) { result.notImplemented(); return; }
            try {
                PackageInfo info = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
                Map<String, Object> data = new HashMap<>();
                data.put("name", info.versionName);
                data.put("build", Build.VERSION.SDK_INT >= 28 ? info.getLongVersionCode() : (long) info.versionCode);
                String installer = null;
                try {
                    installer = Build.VERSION.SDK_INT >= 30
                        ? context.getPackageManager().getInstallSourceInfo(context.getPackageName()).getInstallingPackageName()
                        : context.getPackageManager().getInstallerPackageName(context.getPackageName());
                } catch (Exception ignored) {
                    // Missing installer metadata must not hide the installed version.
                }
                data.put("installedFromGooglePlay", "com.android.vending".equals(installer));
                result.success(data);
            } catch (Exception error) {
                result.error("APP_INFO", error.getMessage(), null);
            }
        });
    }
}

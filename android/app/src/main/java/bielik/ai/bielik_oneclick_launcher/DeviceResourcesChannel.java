package bielik.ai.bielik_oneclick_launcher;

import android.app.ActivityManager;
import android.content.Context;
import android.os.StatFs;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

final class DeviceResourcesChannel {
    static void register(Context context, BinaryMessenger messenger) {
        new MethodChannel(
            messenger,
            "bielik/device_resources",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler((call, result) -> {
            if (!call.method.equals("read")) {
                result.notImplemented();
                return;
            }
            Map<String, Object> values = new HashMap<>();
            try {
                ActivityManager manager =
                    (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
                if (manager != null) {
                    ActivityManager.MemoryInfo memory = new ActivityManager.MemoryInfo();
                    manager.getMemoryInfo(memory);
                    values.put("totalRamBytes", memory.totalMem);
                    values.put("availableRamBytes", memory.availMem);
                }
            } catch (RuntimeException ignored) {
            }
            try {
                String storagePath = call.argument("storagePath");
                if (storagePath != null) {
                    values.put("freeStorageBytes", new StatFs(storagePath).getAvailableBytes());
                }
            } catch (RuntimeException ignored) {
            }
            result.success(values);
        });
    }
}

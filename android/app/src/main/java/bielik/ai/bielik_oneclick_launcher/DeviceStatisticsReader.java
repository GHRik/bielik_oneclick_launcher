package bielik.ai.bielik_oneclick_launcher;

import android.content.Context;
import android.os.Build;
import android.os.Debug;
import android.os.HardwarePropertiesManager;
import android.os.Process;
import android.os.SystemClock;

import java.util.HashMap;
import java.util.Map;

final class DeviceStatisticsReader {
    private long previousWall = -1;
    private long previousCpu = -1;

    Map<String, Object> read(Context context) {
        Map<String, Object> values = new HashMap<>();
        try {
            values.put("appRamBytes", Debug.getPss() * 1024L);
        } catch (RuntimeException ignored) {
        }
        long wall = SystemClock.elapsedRealtime();
        long cpu = Process.getElapsedCpuTime();
        if (previousWall >= 0 && wall > previousWall && wall - previousWall <= 3000 && cpu >= previousCpu) {
            double percent = 100.0 * (cpu - previousCpu) / (wall - previousWall)
                / Runtime.getRuntime().availableProcessors();
            values.put("appCpuPercent", Math.max(0, Math.min(100, percent)));
        }
        previousWall = wall;
        previousCpu = cpu;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                HardwarePropertiesManager manager = (HardwarePropertiesManager)
                    context.getSystemService(Context.HARDWARE_PROPERTIES_SERVICE);
                if (manager != null) {
                    float[] readings = manager.getDeviceTemperatures(
                        HardwarePropertiesManager.DEVICE_TEMPERATURE_CPU,
                        HardwarePropertiesManager.TEMPERATURE_CURRENT);
                    double hottest = Double.NEGATIVE_INFINITY;
                    for (float reading : readings) {
                        if (!Float.isNaN(reading) && !Float.isInfinite(reading) && reading > -100 && reading < 200) {
                            hottest = Math.max(hottest, reading);
                        }
                    }
                    if (hottest != Double.NEGATIVE_INFINITY) values.put("cpuTemperature", hottest);
                }
            } catch (RuntimeException ignored) {
            }
        }
        return values;
    }
}

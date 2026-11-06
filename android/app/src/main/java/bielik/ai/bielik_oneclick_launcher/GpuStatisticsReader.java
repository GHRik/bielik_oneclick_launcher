package bielik.ai.bielik_oneclick_launcher;

import android.content.Context;
import android.os.Build;
import android.os.HardwarePropertiesManager;

import java.util.Map;

final class GpuStatisticsReader {
    private final GpuSysfsReader sysfs = new GpuSysfsReader();

    void read(Context context, Map<String, Object> values) {
        Double usage = sysfs.usagePercent();
        if (usage != null) values.put("gpuUsagePercent", usage);
        Double temperature = hardwareTemperature(context);
        if (temperature == null) temperature = sysfs.temperatureCelsius();
        if (temperature != null) values.put("gpuTemperature", temperature);
    }

    private Double hardwareTemperature(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null;
        try {
            HardwarePropertiesManager manager = (HardwarePropertiesManager)
                context.getSystemService(Context.HARDWARE_PROPERTIES_SERVICE);
            if (manager == null) return null;
            float[] temperatures = manager.getDeviceTemperatures(
                HardwarePropertiesManager.DEVICE_TEMPERATURE_GPU,
                HardwarePropertiesManager.TEMPERATURE_CURRENT);
            Double hottest = null;
            for (float temperature : temperatures) {
                if (!Float.isNaN(temperature) && !Float.isInfinite(temperature)
                    && temperature >= 0 && temperature <= 200
                    && (hottest == null || temperature > hottest)) {
                    hottest = (double) temperature;
                }
            }
            return hottest;
        } catch (RuntimeException ignored) {
            return null;
        }
    }
}

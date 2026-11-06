package bielik.ai.bielik_oneclick_launcher;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

final class GpuSysfsReader {
    private final File kgsl;
    private final File devfreq;
    private final File thermal;
    private List<File> utilisationFiles;
    private List<File> temperatureFiles;

    GpuSysfsReader() {
        this(new File("/sys/class/kgsl/kgsl-3d0"),
            new File("/sys/class/devfreq"), new File("/sys/class/thermal"));
    }

    GpuSysfsReader(File kgsl, File devfreq, File thermal) {
        this.kgsl = kgsl;
        this.devfreq = devfreq;
        this.thermal = thermal;
    }

    Double usagePercent() {
        Double percent = percentage(read(new File(kgsl, "gpu_busy_percentage")));
        if (percent != null) return percent;
        String busy = read(new File(kgsl, "gpubusy"));
        if (busy != null) {
            String[] parts = busy.split("\\s+");
            if (parts.length == 2) {
                Double used = number(parts[0]);
                Double total = number(parts[1]);
                if (used != null && total != null && used >= 0 && total > 0 && used <= total) {
                    return 100.0 * used / total;
                }
            }
        }
        if (utilisationFiles == null) {
            utilisationFiles = new ArrayList<>();
            for (File device : list(devfreq)) {
                String name = device.getName().toLowerCase(Locale.ROOT);
                if (name.contains("gpu") || name.contains("mali")) {
                    utilisationFiles.add(new File(device, "utilisation"));
                    utilisationFiles.add(new File(device, "device/utilisation"));
                }
            }
        }
        for (File file : utilisationFiles) {
            percent = percentage(read(file));
            if (percent != null) return percent;
        }
        return null;
    }

    Double temperatureCelsius() {
        if (temperatureFiles == null) {
            temperatureFiles = new ArrayList<>();
            for (File zone : list(thermal)) {
                if (!zone.getName().startsWith("thermal_zone")) continue;
                String type = read(new File(zone, "type"));
                if (type != null && type.toLowerCase(Locale.ROOT).matches("(gpu|gpuss)([0-9]*|[-_].*)")) {
                    temperatureFiles.add(new File(zone, "temp"));
                }
            }
        }
        Double hottest = null;
        for (File file : temperatureFiles) {
            Double millidegrees = number(read(file));
            if (millidegrees == null) continue;
            double celsius = millidegrees / 1000.0;
            if (celsius >= 0 && celsius <= 200 && (hottest == null || celsius > hottest)) {
                hottest = celsius;
            }
        }
        return hottest;
    }

    private static Double percentage(String raw) {
        if (raw == null) return null;
        Double value = number(raw.replaceFirst("\\s*%$", "").trim());
        return value != null && value >= 0 && value <= 100 ? value : null;
    }

    private static Double number(String raw) {
        if (raw == null) return null;
        try {
            double value = Double.parseDouble(raw);
            return Double.isNaN(value) || Double.isInfinite(value) ? null : value;
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private static String read(File file) {
        try (FileReader reader = new FileReader(file)) {
            char[] buffer = new char[256];
            int size = reader.read(buffer);
            return size <= 0 ? null : new String(buffer, 0, size).trim();
        } catch (IOException | SecurityException ignored) {
            return null;
        }
    }

    private static File[] list(File directory) {
        try {
            File[] files = directory.listFiles();
            return files == null ? new File[0] : files;
        } catch (SecurityException ignored) {
            return new File[0];
        }
    }
}

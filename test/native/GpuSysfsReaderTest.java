package bielik.ai.bielik_oneclick_launcher;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.charset.StandardCharsets;
import java.util.Comparator;

public final class GpuSysfsReaderTest {
    private static void write(Path file, String value) throws Exception {
        Files.createDirectories(file.getParent());
        Files.write(file, value.getBytes(StandardCharsets.UTF_8));
    }

    private static void expect(Double actual, Double expected) {
        if (expected == null ? actual != null : actual == null || Math.abs(actual - expected) > 0.0001) {
            throw new AssertionError("Expected " + expected + ", received " + actual);
        }
    }

    public static void main(String[] args) throws Exception {
        Path root = Files.createTempDirectory("bielik-gpu-sysfs-test");
        try {
            Path kgsl = root.resolve("kgsl");
            Path devfreq = root.resolve("devfreq");
            Path thermal = root.resolve("thermal");
            GpuSysfsReader reader = new GpuSysfsReader(kgsl.toFile(), devfreq.toFile(), thermal.toFile());
            expect(reader.usagePercent(), null);
            expect(reader.temperatureCelsius(), null);
            write(kgsl.resolve("gpu_busy_percentage"), "37 %\n");
            expect(reader.usagePercent(), 37.0);
            write(kgsl.resolve("gpu_busy_percentage"), "0 %");
            expect(reader.usagePercent(), 0.0);
            write(kgsl.resolve("gpu_busy_percentage"), "101");
            write(kgsl.resolve("gpubusy"), "25 100");
            expect(reader.usagePercent(), 25.0);
            write(kgsl.resolve("gpubusy"), "0 0");
            expect(reader.usagePercent(), null);
            write(kgsl.resolve("gpubusy"), "200 100");
            expect(reader.usagePercent(), null);
            write(kgsl.resolve("gpu_busy_percentage"), "NaN");
            write(kgsl.resolve("gpubusy"), "invalid");
            expect(reader.usagePercent(), null);

            write(devfreq.resolve("13000000.mali/utilisation"), "62");
            reader = new GpuSysfsReader(kgsl.toFile(), devfreq.toFile(), thermal.toFile());
            expect(reader.usagePercent(), 62.0);
            write(thermal.resolve("thermal_zone0/type"), "battery");
            write(thermal.resolve("thermal_zone0/temp"), "95000");
            write(thermal.resolve("thermal_zone1/type"), "gpu-thermal");
            write(thermal.resolve("thermal_zone1/temp"), "56250");
            write(thermal.resolve("thermal_zone2/type"), "gpu1");
            write(thermal.resolve("thermal_zone2/temp"), "61000");
            reader = new GpuSysfsReader(kgsl.toFile(), devfreq.toFile(), thermal.toFile());
            expect(reader.temperatureCelsius(), 61.0);
            write(thermal.resolve("thermal_zone2/temp"), "-999999");
            expect(reader.temperatureCelsius(), 56.25);
            write(thermal.resolve("thermal_zone1/temp"), "NaN");
            expect(reader.temperatureCelsius(), null);
            System.out.println("GPU sysfs tests passed: missing files, percentages, ratios, Mali and GPU-only thermal sensors.");
        } finally {
            try (java.util.stream.Stream<Path> files = Files.walk(root)) {
                for (Path file : (Iterable<Path>) files.sorted(Comparator.reverseOrder())::iterator) {
                    Files.deleteIfExists(file);
                }
            }
        }
    }
}

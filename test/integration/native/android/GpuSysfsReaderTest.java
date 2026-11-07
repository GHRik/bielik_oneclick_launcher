package bielik.ai.bielik_oneclick_launcher;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.charset.StandardCharsets;
import java.util.Comparator;

public final class GpuSysfsReaderTest {
    @FunctionalInterface
    private interface Scenario {
        void run(Fixture fixture) throws Exception;
    }

    private static final class Fixture {
        final Path root;
        final Path kgsl;
        final Path devfreq;
        final Path thermal;
        final GpuSysfsReader reader;

        Fixture() throws Exception {
            root = Files.createTempDirectory("bielik-gpu-sysfs-test");
            kgsl = root.resolve("kgsl");
            devfreq = root.resolve("devfreq");
            thermal = root.resolve("thermal");
            reader = new GpuSysfsReader(kgsl.toFile(), devfreq.toFile(), thermal.toFile());
        }

        void sensor(int index, String type, String temperature) throws Exception {
            write(thermal.resolve("thermal_zone" + index + "/type"), type);
            write(thermal.resolve("thermal_zone" + index + "/temp"), temperature);
        }

        void close() throws Exception {
            try (java.util.stream.Stream<Path> files = Files.walk(root)) {
                for (Path file : (Iterable<Path>) files.sorted(Comparator.reverseOrder())::iterator) {
                    Files.deleteIfExists(file);
                }
            }
        }
    }

    private static void write(Path file, String value) throws Exception {
        Files.createDirectories(file.getParent());
        Files.write(file, value.getBytes(StandardCharsets.UTF_8));
    }

    private static void expect(Double actual, Double expected) {
        if (expected == null ? actual != null : actual == null || Math.abs(actual - expected) > 0.0001) {
            throw new AssertionError("Expected " + expected + ", received " + actual);
        }
    }

    private static void test(String name, Scenario scenario) throws Exception {
        Fixture fixture = new Fixture();
        try {
            scenario.run(fixture);
            System.out.println("PASS: " + name);
        } catch (Throwable error) {
            throw new AssertionError(name, error);
        } finally {
            fixture.close();
        }
    }

    public static void main(String[] args) throws Exception {
        test("Missing usage files produce an unknown reading", f ->
            expect(f.reader.usagePercent(), null));
        test("Missing temperature files produce an unknown reading", f ->
            expect(f.reader.temperatureCelsius(), null));
        test("Reads a KGSL percentage with a percent suffix", f -> {
            write(f.kgsl.resolve("gpu_busy_percentage"), "37 %\n");
            expect(f.reader.usagePercent(), 37.0);
        });
        test("Preserves zero GPU usage", f -> {
            write(f.kgsl.resolve("gpu_busy_percentage"), "0 %");
            expect(f.reader.usagePercent(), 0.0);
        });
        test("Falls back to the busy ratio for an invalid percentage", f -> {
            write(f.kgsl.resolve("gpu_busy_percentage"), "101");
            write(f.kgsl.resolve("gpubusy"), "25 100");
            expect(f.reader.usagePercent(), 25.0);
        });
        test("Rejects a ratio with a zero denominator", f -> {
            write(f.kgsl.resolve("gpubusy"), "0 0");
            expect(f.reader.usagePercent(), null);
        });
        test("Rejects a ratio above one hundred percent", f -> {
            write(f.kgsl.resolve("gpubusy"), "200 100");
            expect(f.reader.usagePercent(), null);
        });
        test("Rejects non-numeric usage data", f -> {
            write(f.kgsl.resolve("gpu_busy_percentage"), "NaN");
            write(f.kgsl.resolve("gpubusy"), "invalid");
            expect(f.reader.usagePercent(), null);
        });
        test("Reads Mali utilisation through devfreq", f -> {
            write(f.devfreq.resolve("13000000.mali/utilisation"), "62");
            expect(f.reader.usagePercent(), 62.0);
        });
        test("Excludes battery sensors from GPU temperature", f -> {
            f.sensor(0, "battery", "95000");
            f.sensor(1, "gpu-thermal", "56250");
            expect(f.reader.temperatureCelsius(), 56.25);
        });
        test("Uses the hottest valid GPU sensor", f -> {
            f.sensor(0, "gpu-thermal", "56250");
            f.sensor(1, "gpu1", "61000");
            expect(f.reader.temperatureCelsius(), 61.0);
        });
        test("Ignores an out-of-range GPU temperature", f -> {
            f.sensor(0, "gpu-thermal", "56250");
            f.sensor(1, "gpu1", "-999999");
            expect(f.reader.temperatureCelsius(), 56.25);
        });
        test("Treats a non-numeric GPU temperature as unknown", f -> {
            f.sensor(0, "gpu-thermal", "NaN");
            expect(f.reader.temperatureCelsius(), null);
        });
    }
}

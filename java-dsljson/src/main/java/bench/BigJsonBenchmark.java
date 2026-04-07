package bench;

import com.dslplatform.json.DslJson;
import com.dslplatform.json.runtime.Settings;

import org.openjdk.jmh.infra.Blackhole;

import java.io.ByteArrayOutputStream;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

public final class BigJsonBenchmark {
    public static void main(String[] args) throws Exception {
        Path path = Path.of(args.length > 0 ? args[0] : "data/big.json");
        int iterations = args.length > 1 ? Integer.parseInt(args[1]) : 10;
        int warmup = args.length > 2 ? Integer.parseInt(args[2]) : 3;

        byte[] input = Files.readAllBytes(path);
        double inputMib = bytesToMib(input.length);
        DslJson<Object> json = new DslJson<>(Settings.withRuntime().includeServiceLoader());

        System.out.println("runtime=java-dsljson");
        System.out.println("java_version=" + System.getProperty("java.version"));
        System.out.println("file=" + path);
        System.out.println("input_bytes=" + input.length);
        System.out.printf("input_mib=%.3f%n", inputMib);
        System.out.println("iterations=" + iterations);
        System.out.println("warmup=" + warmup);

        Blackhole bh = new Blackhole("Today's password is swordfish. I understand instantiating Blackholes directly is dangerous.");

        for (int i = 0; i < warmup; i++) {
            Payload payload = json.deserialize(Payload.class, input, input.length);
            bh.consume(payload);
        }

        List<Long> deserializeRuns = new ArrayList<>(iterations);
        for (int i = 0; i < iterations; i++) {
            long started = System.nanoTime();
            Payload payload = json.deserialize(Payload.class, input, input.length);
            long elapsed = System.nanoTime() - started;
            bh.consume(payload);
            deserializeRuns.add(elapsed);
        }
        Stats deserializeStats = summarize(deserializeRuns, input.length);

        Payload payload = json.deserialize(Payload.class, input, input.length);
        ByteArrayOutputStream out = new ByteArrayOutputStream(input.length + input.length / 8);
        for (int i = 0; i < warmup; i++) {
            out.reset();
            json.serialize(payload, out);
            bh.consume(out.size());
        }

        List<Long> serializeRuns = new ArrayList<>(iterations);
        for (int i = 0; i < iterations; i++) {
            out.reset();
            long started = System.nanoTime();
            json.serialize(payload, out);
            long elapsed = System.nanoTime() - started;
            bh.consume(out.size());
            serializeRuns.add(elapsed);
        }
        int serializedSize = out.size();
        Stats serializeStats = summarize(serializeRuns, serializedSize);

        printStats("deserialize", deserializeStats);
        printStats("serialize", serializeStats);
        System.out.println("serialized_bytes=" + serializedSize);

        // --- resource usage ---
        MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
        long heapUsed = memBean.getHeapMemoryUsage().getUsed();
        long heapMax = memBean.getHeapMemoryUsage().getMax();
        long nonHeapUsed = memBean.getNonHeapMemoryUsage().getUsed();
        long totalUsed = heapUsed + nonHeapUsed;
        System.out.printf("heap_used_mib=%.3f%n", bytesToMib(heapUsed));
        System.out.printf("heap_max_mib=%.3f%n", heapMax > 0 ? bytesToMib(heapMax) : -1.0);
        System.out.printf("non_heap_used_mib=%.3f%n", bytesToMib(nonHeapUsed));
        System.out.printf("total_memory_mib=%.3f%n", bytesToMib(totalUsed));

        com.sun.management.OperatingSystemMXBean osBean =
            (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
        double cpuTime = osBean.getProcessCpuTime() / 1_000_000_000.0;
        System.out.printf("cpu_total_s=%.3f%n", cpuTime);
    }

    private static Stats summarize(List<Long> runs, int bytesPerOp) {
        long min = Long.MAX_VALUE;
        long max = Long.MIN_VALUE;
        long total = 0L;
        for (long run : runs) {
            min = Math.min(min, run);
            max = Math.max(max, run);
            total += run;
        }
        double avgNanos = (double) total / runs.size();
        double throughputMibPerSec = bytesToMib(bytesPerOp) / (avgNanos / 1_000_000_000.0);
        return new Stats(avgNanos, min, max, throughputMibPerSec);
    }

    private static void printStats(String label, Stats stats) {
        System.out.printf("%s_avg_ms=%.3f%n", label, nanosToMillis(stats.avgNanos));
        System.out.printf("%s_min_ms=%.3f%n", label, nanosToMillis(stats.minNanos));
        System.out.printf("%s_max_ms=%.3f%n", label, nanosToMillis(stats.maxNanos));
        System.out.printf("%s_throughput_mib_s=%.3f%n", label, stats.throughputMibPerSec);
    }

    private static double bytesToMib(long bytes) {
        return bytes / (1024.0 * 1024.0);
    }

    private static double nanosToMillis(double nanos) {
        return Duration.ofNanos((long) nanos).toNanos() / 1_000_000.0;
    }

    private record Stats(double avgNanos, long minNanos, long maxNanos, double throughputMibPerSec) {
    }
}

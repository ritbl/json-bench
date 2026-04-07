#!/usr/bin/env bash

set -euo pipefail
# set -x # debugging

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JSON_PATH="${1:-$ROOT_DIR/data/big.json}"
ITERATIONS="${2:-50}"
WARMUP="${3:-10}"

if [[ ! -f "$JSON_PATH" ]]; then
  "$ROOT_DIR/scripts/generate_big_json.sh" --output "data/big.json" \
      --items 5000 \
      --variants 6 \
      --reviews 10 \
      --seed 100500
fi

# --- run benchmarks and capture output ---
rust_output=$("$ROOT_DIR/scripts/run_rust.sh" "$JSON_PATH" "$ITERATIONS" "$WARMUP")
java_output=$("$ROOT_DIR/scripts/run_java.sh" "$JSON_PATH" "$ITERATIONS" "$WARMUP")

echo "$rust_output"
echo ""
echo "$java_output"

# --- helper: extract a key=value metric from output ---
extract() {
  local output="$1" key="$2"
  echo "$output" | grep "^${key}=" | head -1 | cut -d= -f2
}

rust_runtime=$(extract "$rust_output" "runtime")
java_runtime=$(extract "$java_output" "runtime")

rust_deser=$(extract "$rust_output" "deserialize_avg_ms")
java_deser=$(extract "$java_output" "deserialize_avg_ms")

rust_ser=$(extract "$rust_output" "serialize_avg_ms")
java_ser=$(extract "$java_output" "serialize_avg_ms")

rust_peak_rss=$(extract "$rust_output" "peak_rss_mib")
java_heap_used=$(extract "$java_output" "heap_used_mib")
java_total_mem=$(extract "$java_output" "total_memory_mib")

rust_cpu=$(extract "$rust_output" "cpu_total_s")
java_cpu=$(extract "$java_output" "cpu_total_s")

# --- compare and print summary ---
compare() {
  local label="$1" rust_val="$2" java_val="$3" unit="$4"

  local winner fast slow ratio pct
  if awk "BEGIN { exit ($rust_val < $java_val) ? 0 : 1 }"; then
    winner="$rust_runtime"
    fast="$rust_val"
    slow="$java_val"
  else
    winner="$java_runtime"
    fast="$java_val"
    slow="$rust_val"
  fi

  ratio=$(awk "BEGIN { printf \"%.2f\", $slow / $fast }")
  pct=$(awk "BEGIN { printf \"%.1f\", ($slow - $fast) / $slow * 100 }")

  printf "  %-15s  %s wins — %s %s vs %s %s  (%.2fx, %s%% less)\n" \
    "$label:" "$winner" "$fast" "$unit" "$slow" "$unit" "$ratio" "$pct"
}

echo ""
echo "=============================="
echo "        COMPARISON"
echo "=============================="

echo ""
echo "  --- Speed ---"
printf "  %-15s  %s = %.3f ms   %s = %.3f ms\n" \
  "deserialize:" "$rust_runtime" "$rust_deser" "$java_runtime" "$java_deser"
printf "  %-15s  %s = %.3f ms   %s = %.3f ms\n" \
  "serialize:" "$rust_runtime" "$rust_ser" "$java_runtime" "$java_ser"

echo ""
echo "  --- Memory ---"
printf "  %-15s  %s peak RSS = %s MiB\n" \
  "rust:" "$rust_runtime" "$rust_peak_rss"
printf "  %-15s  %s heap used = %s MiB   total (heap+non-heap) = %s MiB\n" \
  "java:" "$java_runtime" "$java_heap_used" "$java_total_mem"

echo ""
echo "  --- CPU time ---"
printf "  %-15s  %s = %s s\n" "rust:" "$rust_runtime" "$rust_cpu"
printf "  %-15s  %s = %s s\n" "java:" "$java_runtime" "$java_cpu"

echo ""
echo "  Winner:"
compare "deserialize" "$rust_deser" "$java_deser" "ms"
compare "serialize"   "$rust_ser"   "$java_ser"   "ms"
compare "memory"      "$rust_peak_rss" "$java_total_mem" "MiB"
compare "cpu_time"    "$rust_cpu"   "$java_cpu"   "s"
echo ""

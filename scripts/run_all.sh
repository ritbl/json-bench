#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JSON_PATH="${1:-$ROOT_DIR/data/big.json}"
ITERATIONS="${2:-50}"
WARMUP="${3:-10}"

if [[ ! -f "$JSON_PATH" ]]; then
  "$ROOT_DIR/scripts/generate_big_json.sh" --output "$JSON_PATH"
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

# --- compare and print summary ---
compare() {
  local label="$1" rust_ms="$2" java_ms="$3"

  # determine winner and compute ratio
  local winner loser fast slow ratio pct
  if awk "BEGIN { exit ($rust_ms < $java_ms) ? 0 : 1 }"; then
    winner="$rust_runtime"
    loser="$java_runtime"
    fast="$rust_ms"
    slow="$java_ms"
  else
    winner="$java_runtime"
    loser="$rust_runtime"
    fast="$java_ms"
    slow="$rust_ms"
  fi

  ratio=$(awk "BEGIN { printf \"%.2f\", $slow / $fast }")
  pct=$(awk "BEGIN { printf \"%.1f\", ($slow - $fast) / $slow * 100 }")

  printf "  %-15s  %s is faster — %.3f ms vs %.3f ms  (%.2fx, %s%% less time)\n" \
    "$label:" "$winner" "$fast" "$slow" "$ratio" "$pct"
}

echo ""
echo "=============================="
echo "        COMPARISON"
echo "=============================="
echo ""
printf "  %-15s  %s = %.3f ms   %s = %.3f ms\n" \
  "deserialize:" "$rust_runtime" "$rust_deser" "$java_runtime" "$java_deser"
printf "  %-15s  %s = %.3f ms   %s = %.3f ms\n" \
  "serialize:" "$rust_runtime" "$rust_ser" "$java_runtime" "$java_ser"
echo ""
echo "  Winner:"
compare "deserialize" "$rust_deser" "$java_deser"
compare "serialize"   "$rust_ser"   "$java_ser"
echo ""

#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JSON_PATH="${1:-$ROOT_DIR/data/big.json}"
ITERATIONS="${2:-50}"
WARMUP="${3:-10}"

cargo run --release --manifest-path "$ROOT_DIR/rust-sonic/Cargo.toml" -- "$JSON_PATH" "$ITERATIONS" "$WARMUP"

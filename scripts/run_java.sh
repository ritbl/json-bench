#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JAVA_DIR="$ROOT_DIR/java-dsljson"
JSON_PATH="${1:-$ROOT_DIR/data/big.json}"
ITERATIONS="${2:-50}"
WARMUP="${3:-10}"
JAVA_RELEASE="${JAVA_RELEASE:-25}"

if [[ -x "$JAVA_DIR/gradlew" ]]; then
  GRADLE_CMD=("$JAVA_DIR/gradlew")
elif command -v gradle >/dev/null 2>&1; then
  GRADLE_CMD=("gradle")
else
  echo "Gradle is not available."
  echo "Install Gradle or add a Gradle wrapper under $JAVA_DIR."
  exit 1
fi

(
  cd "$JAVA_DIR"
  "${GRADLE_CMD[@]}" run \
    -PjsonPath="$JSON_PATH" \
    -Piterations="$ITERATIONS" \
    -Pwarmup="$WARMUP" \
    -PjavaRelease="$JAVA_RELEASE"
)

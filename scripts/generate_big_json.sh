#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not available."
  exit 1
fi

docker compose -f "$ROOT_DIR/compose.yaml" run --rm datagen "$@"

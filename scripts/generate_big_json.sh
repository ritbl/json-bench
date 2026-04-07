#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not available."
  exit 1
fi

# If no arguments provided, use defaults: generate 20k items with 6 variants and 10 reviews each
if [[ $# -eq 0 ]]; then
  set -- --output data/big.json --items 20000 --variants 6 --reviews 10
fi

docker compose -f "$ROOT_DIR/compose.yaml" run --rm datagen "$@"

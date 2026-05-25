#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v node >/dev/null 2>&1; then
  printf 'ERROR: node is required for mmwavelab-flash UI.\n' >&2
  exit 2
fi

node "$repo_dir/flash-ui/server.js"

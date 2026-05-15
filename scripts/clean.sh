#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

rm -rf \
  "$BUILD_ROOT" \
  "$repo_dir/perf" \
  "$repo_dir/work" \
  "$repo_dir/work-user" \
  "$repo_dir/work-smoke" \
  "$repo_dir/packages"

printf 'Cleaned generated build/work directories under %s\n' "$repo_dir"

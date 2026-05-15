#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$repo_dir"/scripts/*.sh
cmake -S "$repo_dir" -B "$repo_dir/build/ci-configure" -G Ninja
ctest --test-dir "$repo_dir/build/ci-configure" --output-on-failure -R configure_xwr68xx_mss_dss

if [[ "${CI_FULL_BUILD:-0}" == "1" ]]; then
  "$repo_dir/scripts/benchmark.sh"
else
  "$repo_dir/scripts/test.sh"
fi

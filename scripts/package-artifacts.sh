#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
package_dir="$repo_dir/packages"
package="$package_dir/ti-mmwave-xwr68xx-artifacts-$timestamp.tar.gz"
mkdir -p "$package_dir" "$ARTIFACT_DIR" "$REPORT_DIR"

if ! compgen -G "$ARTIFACT_DIR/*.bin" >/dev/null; then
  printf 'No firmware binaries found in %s. Run make docker-cmake or make benchmark first.\n' "$ARTIFACT_DIR" >&2
  exit 2
fi

tar -czf "$package" \
  -C "$repo_dir" \
  config/sdk-manifest.json \
  artifacts \
  reports

sha256sum "$package"
ls -lh "$package"

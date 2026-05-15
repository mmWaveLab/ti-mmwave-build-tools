#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

sdk_image="${SDK_FULL_IMAGE:-meowkj/ti-mmwave-sdk:03.06.02-local}"
context_dir="${SDK_IMAGE_CONTEXT:-$repo_dir/build/sdk-full-image-context}"

require_host_ti_root

rm -rf "$context_dir"
mkdir -p "$context_dir"

rsync -a --delete \
  --exclude '.git' \
  --exclude 'build' \
  --exclude 'artifacts' \
  --exclude 'perf' \
  --exclude 'packages' \
  --exclude 'work' \
  --exclude 'work-*' \
  --exclude '.DS_Store' \
  "$repo_dir/" "$context_dir/tools/"

rsync -a --delete \
  --exclude '*/obj_*' \
  --exclude '*/mmw_configPkg_*' \
  --exclude '*.oer4f' \
  --exclude '*.oe674' \
  --exclude '*.xer4f' \
  --exclude '*.xe674' \
  --exclude '*.map' \
  --exclude '*.tmp' \
  --exclude '*.rov.xs' \
  --exclude '*.dep' \
  --exclude '*.pp' \
  --exclude 'xwr*_mmw*_demo*.bin' \
  "$HOST_TI_ROOT/" "$context_dir/ti/"
cp "$repo_dir/docker/Dockerfile.sdk-full" "$context_dir/Dockerfile"

docker build -t "$sdk_image" "$context_dir"

printf 'Built SDK-full Docker image: %s\n' "$sdk_image"
printf 'Smoke:\n'
printf '  docker run --rm %s check-ti-linux\n' "$sdk_image"

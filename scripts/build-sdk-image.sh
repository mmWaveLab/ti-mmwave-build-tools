#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

sdk_image="${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}"
context_dir="${SDK_IMAGE_CONTEXT:-$repo_dir/build/sdk-full-image-context}"

require_docker
require_host_ti_root

rm -rf "$context_dir"
mkdir -p "$context_dir"

cp "$repo_dir/scripts/check-ti-linux.sh" "$context_dir/check-ti-linux.sh"
cp "$repo_dir/scripts/ti-sdk-env.sh" "$context_dir/ti-sdk-env.sh"

rsync -a --delete \
  --exclude 'docs/' \
  --exclude 'doc/' \
  --exclude '*.chm' \
  --exclude '*.html' \
  --exclude '*.pdf' \
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

if [[ -e "$context_dir/tools" ]]; then
  printf 'SDK-full image context must not include repository tools or demos: %s\n' "$context_dir/tools" >&2
  exit 2
fi

printf 'Building SDK-full Docker image: %s\n' "$sdk_image"
printf 'Context: %s\n' "$context_dir"
docker build -t "$sdk_image" "$context_dir"

printf 'Built SDK-full Docker image: %s\n' "$sdk_image"
printf 'Smoke:\n'
printf '  docker run --rm %s check-ti-linux\n' "$sdk_image"

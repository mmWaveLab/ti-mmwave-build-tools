#!/usr/bin/env bash
set -euo pipefail

image="${SDK_FULL_IMAGE:-meowkj/ti-mmwave-sdk:03.06.02-local}"
work_dir="${SDK_SMOKE_WORK:-$(pwd)/build/sdk-image-smoke}"
devices="${SDK_SMOKE_DEVICES:-xwr68xx xwr18xx}"

mkdir -p "$work_dir"
docker run --rm \
  -v "$work_dir":/work \
  "$image" \
  bash -lc 'rm -rf /work/*'

docker run --rm "$image" check-ti-linux

for device in $devices; do
  case "$device" in
    xwr16xx) output_bin="xwr16xx_mmw_demo.bin" ;;
    xwr18xx) output_bin="xwr18xx_mmw_demo.bin" ;;
    xwr64xx) output_bin="xwr64xx_mmw_demo.bin" ;;
    xwr64xx_compression) output_bin="xwr64xx_compression_mmw_demo.bin" ;;
    xwr68xx) output_bin="xwr68xx_mmw_demo.bin" ;;
    *)
      printf 'Unsupported smoke device: %s\n' "$device" >&2
      exit 2
      ;;
  esac

  project="smoke-$device"
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$work_dir":/work \
    -w /work \
    "$image" \
    create-mmwave-app "$project" --device "$device" --image "$image"
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$work_dir/$project":/work/app \
    -w /work/app \
    "$image" \
    bash -lc 'cmake -S . -B build -G Ninja -DTI_ROOT=/home/kj/ti && cmake --build build --target firmware'
  sha256sum "$work_dir/$project/build/app/$output_bin"
done

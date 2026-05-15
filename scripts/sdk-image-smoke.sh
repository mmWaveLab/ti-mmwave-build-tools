#!/usr/bin/env bash
set -euo pipefail

image="${SDK_FULL_IMAGE:-meowkj/ti-mmwave-sdk:03.06.02-local}"
work_dir="${SDK_SMOKE_WORK:-$(pwd)/build/sdk-image-smoke}"
profiles="${SDK_SMOKE_PROFILES:-iwr6843isk-oob iwr1843boost-oob}"
profiles_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/demo-profiles.tsv"

profile_output_bin() {
  local requested="$1"
  while IFS=$'\t' read -r profile _device _demo _sdk_device output_bin _cores _configs _summary; do
    [[ -z "${profile:-}" || "$profile" == \#* ]] && continue
    if [[ "$profile" == "$requested" ]]; then
      printf '%s\n' "$output_bin"
      return 0
    fi
  done < "$profiles_file"
  printf 'Unsupported smoke profile: %s\n' "$requested" >&2
  return 2
}

mkdir -p "$work_dir"
docker run --rm \
  -v "$work_dir":/work \
  "$image" \
  bash -lc 'rm -rf /work/*'

docker run --rm "$image" check-ti-linux

for profile in $profiles; do
  output_bin="$(profile_output_bin "$profile")"

  project="smoke-$profile"
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$work_dir":/work \
    -w /work \
    "$image" \
    create-mmwave-app "$project" --profile "$profile" --image "$image"
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$work_dir/$project":/work/app \
    -w /work/app \
    "$image" \
    bash -lc 'cmake -S . -B build -G Ninja -DTI_ROOT=/opt/ti && cmake --build build --target firmware'
  (cd "$work_dir/$project/build/app" && sha256sum "$output_bin")
done

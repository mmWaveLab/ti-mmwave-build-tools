#!/usr/bin/env bash
set -euo pipefail

image="${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}"
work_dir="${SDK_SMOKE_WORK:-$(pwd)/build/sdk-image-smoke}"
profiles="${SDK_SMOKE_PROFILES:-xwr6843isk-mss-dss xwr1843boost-mss-dss xwr6843aop-mss-only}"
profiles_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/demo-profiles.tsv"
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"

require_docker

profile_output_bin() {
  local requested="$1"
  while IFS=$'\t' read -r profile _board _mode source_kind _source _device _sdk_device output_bin _cores _entry_kind _entry _clean _vars _configs status _summary; do
    [[ -z "${profile:-}" || "$profile" == \#* ]] && continue
    if [[ "$profile" == "$requested" ]]; then
      if [[ "$source_kind" != "sdk-make" || "$status" != "validated" ]]; then
        printf 'Smoke profile is not SDK-make validated: %s\n' "$requested" >&2
        return 3
      fi
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
  python3 "$repo_dir/docs/install.py" \
    --name "$project" \
    --profile "$profile" \
    --dir "$work_dir/$project" \
    --image "$image" \
    --pull never \
    --force \
    --build
  (cd "$work_dir/$project/build/app" && sha256sum "$output_bin")
done

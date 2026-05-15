#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/new-project.sh NAME [--profile iwr6843isk-oob] [--out DIR] [--image IMAGE] [--force]

This compatibility wrapper creates a fork-mode project under this repository.
For standalone projects, prefer scripts/create-mmwave-app.sh.
USAGE
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

name="$1"
shift
profile=""
device="xwr68xx"
device_was_set=0
out_dir=""
image="${SDK_IMAGE:-meowkj/ti-mmwave-sdk:03.06.02-local}"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --device)
      device="${2:-}"
      device_was_set=1
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --image)
      image="${2:-}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$profile" && "$device_was_set" -eq 1 ]]; then
  printf 'Use either --profile or legacy --device, not both.\n' >&2
  exit 2
fi

if [[ -z "$out_dir" ]]; then
  out_dir="examples/$name"
fi

case "$out_dir" in
  /*) abs_out="$out_dir" ;;
  *) abs_out="$repo_dir/$out_dir" ;;
esac

if [[ -n "$profile" ]]; then
  "$repo_dir/scripts/create-mmwave-app.sh" "$name" --profile "$profile" --dir "$abs_out" --image "$image" ${force:+--force}
else
  "$repo_dir/scripts/create-mmwave-app.sh" "$name" --device "$device" --dir "$abs_out" --image "$image" ${force:+--force}
fi

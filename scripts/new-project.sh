#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/new-project.sh NAME [--device xwr68xx] [--out DIR] [--image IMAGE] [--force]

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
device="xwr68xx"
out_dir=""
image="${SDK_IMAGE:-meowkj/ti-mmwave-sdk:03.06.02-local}"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      device="${2:-}"
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

if [[ -z "$out_dir" ]]; then
  out_dir="examples/$name"
fi

case "$out_dir" in
  /*) abs_out="$out_dir" ;;
  *) abs_out="$repo_dir/$out_dir" ;;
esac

"$repo_dir/scripts/create-mmwave-app.sh" "$name" --device "$device" --dir "$abs_out" --image "$image" ${force:+--force}

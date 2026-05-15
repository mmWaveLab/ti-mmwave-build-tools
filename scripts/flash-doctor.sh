#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/flash-common.sh"

status=0

printf 'UniFlash integration doctor\n'
printf 'repo: %s\n\n' "$repo_dir"

printf 'Serial devices:\n'
"$repo_dir/scripts/flash-list.sh" || true

printf '\nUniFlash / DSLite:\n'
if dslite="$(flash_find_dslite)"; then
  printf 'ok      DSLite: %s\n' "$dslite"
  "$dslite" --listMode 2>/tmp/uniflash-dslite-listmode.log | sed -n '1,80p' || cat /tmp/uniflash-dslite-listmode.log
else
  printf 'missing DSLite. Install TI UniFlash for Linux or set DSLITE=/path/to/dslite.sh.\n'
  status=1
fi

printf '\nInputs:\n'
if bin="$(flash_resolve_default_bin "$repo_dir")"; then
  printf 'ok      BIN: %s\n' "$bin"
else
  printf 'missing BIN. Build firmware first or pass BIN=/path/to/file.bin.\n'
  status=1
fi

if [[ -n "${PORT:-}" ]]; then
  if [[ -e "$PORT" ]]; then
    printf 'ok      PORT: %s\n' "$PORT"
  else
    printf 'missing PORT: %s\n' "$PORT"
    status=1
  fi
else
  printf 'info    PORT not set. Required for flash-dry-run and flash.\n'
fi

if ccxml="$(flash_resolve_ccxml)" && [[ -n "$ccxml" ]]; then
  printf 'ok      CCXML: %s\n' "$ccxml"
else
  printf 'info    CCXML not set. Required for generic DSLite flash unless using a generated CLI package wrapper.\n'
fi

if settings="$(flash_resolve_ufsettings)" && [[ -n "$settings" ]]; then
  printf 'ok      UFSETTINGS: %s\n' "$settings"
else
  printf 'info    UFSETTINGS not set. Recommended for mmWave UniFlash generated packages.\n'
fi

exit "$status"

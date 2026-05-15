#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${1:-$repo_dir/examples/official-sdk-demos/devices-ci.tsv}"

if [[ ! -f "$manifest" ]]; then
  printf 'ERROR: manifest not found: %s\n' "$manifest" >&2
  exit 2
fi

python3 - "$manifest" <<'PY'
import csv
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
rows = []
errors = []
ids = set()

with manifest.open(newline="", encoding="utf-8") as fh:
    reader = csv.reader(fh, delimiter="\t")
    for line_no, row in enumerate(reader, start=1):
        if not row or row[0].startswith("#"):
            continue
        if len(row) != 6:
            errors.append(f"line {line_no}: expected 6 columns, got {len(row)}")
            continue
        demo_id, sdk_demo, sdk_device, common_devices, ci_profile, notes = row
        if demo_id in ids:
            errors.append(f"line {line_no}: duplicate id {demo_id}")
        ids.add(demo_id)
        if not sdk_demo.startswith("ti/demo/") or not sdk_demo.endswith("/mmw"):
            errors.append(f"line {line_no}: unexpected SDK demo path {sdk_demo}")
        if sdk_device not in {"iwr16xx", "iwr18xx", "iwr68xx"}:
            errors.append(f"line {line_no}: unexpected SDK device {sdk_device}")
        if ci_profile != "full":
            errors.append(f"line {line_no}: unexpected ci_profile {ci_profile}")
        if not common_devices:
            errors.append(f"line {line_no}: common_devices must not be empty")
        if not notes:
            errors.append(f"line {line_no}: notes must not be empty")
        rows.append((demo_id, sdk_demo, sdk_device))

if not rows:
    errors.append("manifest has no demo rows")

required = {"xwr16xx", "xwr18xx", "xwr64xx", "xwr64xx_compression", "xwr68xx"}
missing = required - ids
if missing:
    errors.append("missing required ids: " + ", ".join(sorted(missing)))

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(2)

for demo_id, sdk_demo, sdk_device in rows:
    print(f"ok {demo_id}: {sdk_demo} [{sdk_device}]")
PY

if [[ -n "${HOST_TI_ROOT:-}" ]]; then
  status=0
  while IFS=$'\t' read -r demo_id sdk_demo sdk_device _rest; do
    [[ -z "${demo_id:-}" || "$demo_id" == \#* ]] && continue
    path="$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/$sdk_demo/makefile"
    if [[ -f "$path" ]]; then
      printf 'ok SDK path %s -> %s\n' "$demo_id" "$path"
    else
      printf 'missing SDK path %s -> %s\n' "$demo_id" "$path" >&2
      status=1
    fi
  done <"$manifest"
  exit "$status"
fi

printf 'PASS: official demo manifest is valid.\n'

#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'GitHub Actions smoke test\n'
printf 'repo: %s\n\n' "$repo_dir"

printf 'Shell syntax\n'
bash -n "$repo_dir"/scripts/*.sh

printf 'Workflow YAML syntax\n'
python3 - "$repo_dir/.github/workflows/ci.yml" <<'PY'
import sys
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError:
    yaml = None

workflow = Path(sys.argv[1])
if not workflow.is_file():
    raise SystemExit(f"missing workflow: {workflow}")

if yaml is None:
    # Minimal fallback: the runner image usually has PyYAML absent, but we still
    # want a useful existence check without adding a dependency.
    text = workflow.read_text(encoding="utf-8")
    for token in ("name:", "on:", "jobs:"):
        if token not in text:
            raise SystemExit(f"workflow missing required token: {token}")
else:
    yaml.safe_load(workflow.read_text(encoding="utf-8"))

print("workflow ok")
PY

printf 'Root CMake configure without TI SDK\n'
rm -rf "$repo_dir/build/github-actions-smoke"
cmake -S "$repo_dir" -B "$repo_dir/build/github-actions-smoke" -G "Unix Makefiles"

printf 'Public artifact paths\n'
test -f "$repo_dir/README.md"
test -f "$repo_dir/docs/ABOUT.md"
test -f "$repo_dir/docs/CI.md"
test -f "$repo_dir/docs/UNIFLASH.md"
test -f "$repo_dir/config/devices.tsv"
test -f "$repo_dir/examples/official-sdk-demos/README.md"
test -f "$repo_dir/examples/official-sdk-demos/devices-ci.tsv"

printf 'Official demo manifest\n'
"$repo_dir/scripts/check-official-demo-manifest.sh"

printf 'PASS: GitHub Actions smoke test succeeded.\n'

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
test -f "$repo_dir/docs/CI.md"
test -f "$repo_dir/docs/UNIFLASH.md"
test -f "$repo_dir/docs/PROJECT_OVERVIEW.md"
test -f "$repo_dir/docs/PROJECT_TEMPLATE.md"
test -f "$repo_dir/docs/DOCKER_IMAGE.md"
test -f "$repo_dir/config/demo-profiles.tsv"
test -f "$repo_dir/config/toolbox-oob-profiles.tsv"
test -f "$repo_dir/config/toolbox-application-profiles.tsv"
test -f "$repo_dir/scripts/validate-demo-profiles.sh"
test -f "$repo_dir/scripts/mmwave-run.sh"
test -f "$repo_dir/scripts/validate-cmake-portability.sh"
test -f "$repo_dir/templates/mmwave-cmake-project/CMakeLists.txt.in"
test -f "$repo_dir/templates/mmwave-cmake-project/gitignore.in"
test -f "$repo_dir/docker/Dockerfile.sdk-full"

printf 'Project template static checks\n'
grep -q 'cmake --build' "$repo_dir/templates/mmwave-cmake-project/Makefile.in"
grep -q 'copy_directory.*APP_SOURCE_DIR' "$repo_dir/templates/mmwave-cmake-project/CMakeLists.txt.in"
grep -q 'create-mmwave-app' "$repo_dir/docker/Dockerfile.sdk-full"
"$repo_dir/scripts/create-mmwave-app.sh" --help >/dev/null
"$repo_dir/scripts/create-mmwave-app.sh" --list-profiles >/dev/null

printf 'Demo profile manifest\n'
python3 - "$repo_dir/config/demo-profiles.tsv" <<'PY'
import csv
import sys
from pathlib import Path

path = Path(sys.argv[1])
required = {
    "iwr1843boost-oob",
    "iwr6843isk-oob",
}
ids = set()
errors = []
with path.open(encoding="utf-8", newline="") as f:
    for line_no, row in enumerate(csv.reader(f, delimiter="\t"), 1):
        if not row or row[0].startswith("#"):
            continue
        if len(row) != 8:
            errors.append(f"line {line_no}: expected 8 columns, got {len(row)}")
            continue
        profile, sdk_device_type, sdk_demo, sdk_device, output_bin, cores, configs, summary = row
        if profile in ids:
            errors.append(f"line {line_no}: duplicate profile {profile}")
        ids.add(profile)
        if not sdk_demo.startswith("ti/demo/") or not sdk_demo.endswith("/mmw"):
            errors.append(f"line {line_no}: unexpected SDK demo path {sdk_demo}")
        if sdk_device_type not in {"xwr18xx", "xwr68xx"}:
            errors.append(f"line {line_no}: unexpected SDK device type {sdk_device_type}")
        if sdk_device not in {"iwr18xx", "iwr68xx"}:
            errors.append(f"line {line_no}: unexpected SDK device {sdk_device}")
        if not output_bin.endswith(".bin"):
            errors.append(f"line {line_no}: output is not a bin file {output_bin}")
        if cores not in {"MSS", "MSS+DSS"}:
            errors.append(f"line {line_no}: unexpected core set {cores}")
        if not configs:
            errors.append(f"line {line_no}: missing profile config list")
        if not summary:
            errors.append(f"line {line_no}: missing summary")
missing = sorted(required - ids)
if missing:
    errors.append(f"missing required profiles: {', '.join(missing)}")
if errors:
    raise SystemExit("\n".join(errors))
print(f"demo profiles ok: {len(ids)}")
PY

printf 'Toolbox profile manifest\n'
python3 - "$repo_dir/config/toolbox-oob-profiles.tsv" <<'PY'
import csv
import sys
from pathlib import Path

path = Path(sys.argv[1])
errors = []
ids = set()
with path.open(encoding="utf-8", newline="") as f:
    for line_no, row in enumerate(csv.reader(f, delimiter="\t"), 1):
        if not row or row[0].startswith("#"):
            continue
        if len(row) != 12:
            errors.append(f"line {line_no}: expected 12 columns, got {len(row)}")
            continue
        profile, toolbox, version, source_dir, sdk_family, cores, ti_target, prebuilt, projects, suitability, status, summary = row
        if profile in ids:
            errors.append(f"line {line_no}: duplicate profile {profile}")
        ids.add(profile)
        if toolbox not in {"radar_toolbox", "mmwave_industrial_toolbox"}:
            errors.append(f"line {line_no}: unexpected toolbox {toolbox}")
        if sdk_family not in {"SDK3", "L-SDK", "MCU+"}:
            errors.append(f"line {line_no}: unexpected SDK family {sdk_family}")
        if cores not in {"MSS", "MSS+DSS", "MSS+DSS+CM4", "MSS+CM4", "APPSS", "APPIMAGE"}:
            errors.append(f"line {line_no}: unexpected core set {cores}")
        if suitability not in {"starter-sdk3", "starter-other-sdk", "defer"}:
            errors.append(f"line {line_no}: unexpected suitability {suitability}")
        if status not in {"analysis-only", "validated"}:
            errors.append(f"line {line_no}: unexpected status {status}")
        if not source_dir or not prebuilt or not projects or not ti_target or not summary:
            errors.append(f"line {line_no}: missing required descriptive fields")
if errors:
    raise SystemExit("\n".join(errors))
print(f"toolbox profiles ok: {len(ids)}")
PY

printf 'Toolbox application manifest\n'
python3 - "$repo_dir/config/toolbox-application-profiles.tsv" <<'PY'
import csv
import sys
from pathlib import Path

path = Path(sys.argv[1])
errors = []
ids = set()
required = {
    "iwr6843aop-3d-people-tracking",
    "iwr6843aop-area-scanner",
}
with path.open(encoding="utf-8", newline="") as f:
    for line_no, row in enumerate(csv.reader(f, delimiter="\t"), 1):
        if not row or row[0].startswith("#"):
            continue
        if len(row) != 13:
            errors.append(f"line {line_no}: expected 13 columns, got {len(row)}")
            continue
        profile, toolbox, version, source_dir, sdk_family, cores, ti_targets, prebuilt, projects, config_profiles, suitability, status, summary = row
        if profile in ids:
            errors.append(f"line {line_no}: duplicate profile {profile}")
        ids.add(profile)
        if toolbox not in {"radar_toolbox", "mmwave_industrial_toolbox"}:
            errors.append(f"line {line_no}: unexpected toolbox {toolbox}")
        if sdk_family != "SDK3":
            errors.append(f"line {line_no}: unexpected SDK family {sdk_family}")
        if cores != "MSS+DSS":
            errors.append(f"line {line_no}: unexpected core set {cores}")
        if "IWR6843AOP" not in ti_targets.split(","):
            errors.append(f"line {line_no}: missing IWR6843AOP target")
        if suitability != "starter-application":
            errors.append(f"line {line_no}: unexpected suitability {suitability}")
        if status not in {"analysis-only", "validated"}:
            errors.append(f"line {line_no}: unexpected status {status}")
        if not all((source_dir, prebuilt, projects, config_profiles, summary)):
            errors.append(f"line {line_no}: missing required descriptive fields")
missing = sorted(required - ids)
if missing:
    errors.append(f"missing required application profiles: {', '.join(missing)}")
if errors:
    raise SystemExit("\n".join(errors))
print(f"toolbox application profiles ok: {len(ids)}")
PY

printf 'PASS: GitHub Actions smoke test succeeded.\n'

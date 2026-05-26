#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'GitHub Actions smoke test\n'
printf 'repo: %s\n\n' "$repo_dir"

printf 'Shell syntax\n'
bash -n "$repo_dir"/scripts/*.sh

printf 'Workflow YAML syntax\n'
python3 - "$repo_dir/.github/workflows"/*.yml <<'PY'
import sys
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError:
    yaml = None

workflows = [Path(arg) for arg in sys.argv[1:]]
if not workflows:
    raise SystemExit("missing workflow files")

for workflow in workflows:
    if not workflow.is_file():
        raise SystemExit(f"missing workflow: {workflow}")
    text = workflow.read_text(encoding="utf-8")
    if yaml is None:
        # Minimal fallback: the runner image usually has PyYAML absent, but we
        # still want a useful existence check without adding a dependency.
        for token in ("name:", "on:", "jobs:"):
            if token not in text:
                raise SystemExit(f"{workflow}: missing required token: {token}")
    else:
        yaml.safe_load(text)

print(f"workflow ok: {len(workflows)}")
PY

printf 'Root CMake configure without TI SDK\n'
rm -rf "$repo_dir/build/github-actions-smoke"
cmake -S "$repo_dir" -B "$repo_dir/build/github-actions-smoke" -G "Unix Makefiles"

printf 'Public artifact paths\n'
test -f "$repo_dir/README.md"
test -f "$repo_dir/README.zh-CN.md"
test -f "$repo_dir/docs/CI.md"
test -f "$repo_dir/docs/UNIFLASH.md"
test -f "$repo_dir/docs/DOCKER_IMAGE.md"
test -f "$repo_dir/docs/STARTER_DEMOS.md"
test -f "$repo_dir/docs/AI_CONVERSION.md"
test -f "$repo_dir/docs/install.py"
test -f "$repo_dir/flash-ui/server.js"
test -f "$repo_dir/flash-ui/core.js"
test -f "$repo_dir/flash-ui/cli.js"
test -f "$repo_dir/flash-ui/public/index.html"
test -f "$repo_dir/flash-ui/public/styles.css"
test -f "$repo_dir/flash-ui/public/app.js"
test -x "$repo_dir/scripts/mmwavelab-flash"
test -f "$repo_dir/config/starter-demo-profiles.tsv"
test -f "$repo_dir/docs/catalog/toolbox-oob-demo-profiles.tsv"
test -f "$repo_dir/docs/catalog/toolbox-application-demo-profiles.tsv"
test -f "$repo_dir/scripts/validate-demo-profiles.sh"
test -f "$repo_dir/scripts/mmwave-run.sh"
test -f "$repo_dir/scripts/validate-cmake-portability.sh"
test -x "$repo_dir/scripts/validate-install-profiles.sh"
test -f "$repo_dir/templates/mmwave-cmake-project/CMakeLists.txt.in"
test -f "$repo_dir/templates/mmwave-cmake-project/gitignore.in"
test -f "$repo_dir/Dockerfile"
test -f "$repo_dir/demos/xwr1843boost-mss-only/CMakeLists.txt"
test -f "$repo_dir/demos/xwr1843boost-mss-dss/CMakeLists.txt"
test -f "$repo_dir/demos/xwr6843isk-mss-only/CMakeLists.txt"
test -f "$repo_dir/demos/xwr6843isk-mss-dss/CMakeLists.txt"
test -f "$repo_dir/demos/xwr6843aop-mss-only/CMakeLists.txt"
test -f "$repo_dir/demos/xwr6843aop-mss-dss/CMakeLists.txt"
test ! -d "$repo_dir/demos/sdk"

printf 'Project template static checks\n'
grep -q 'cmake --build' "$repo_dir/templates/mmwave-cmake-project/Makefile.in"
grep -q 'README.zh-CN.md' "$repo_dir/README.md"
grep -q 'README.md' "$repo_dir/README.zh-CN.md"
grep -q 'copy_directory.*APP_SOURCE_DIR' "$repo_dir/templates/mmwave-cmake-project/CMakeLists.txt.in"
grep -q 'project-specific AI-assisted conversion' "$repo_dir/docs/AI_CONVERSION.md"
grep -q '^demos$' "$repo_dir/.dockerignore"
grep -q '^\.git$' "$repo_dir/.dockerignore"
grep -q 'COPY ti /opt/ti' "$repo_dir/Dockerfile"
grep -q 'COPY check-ti-linux.sh' "$repo_dir/Dockerfile"
grep -q 'COPY run-repo-smoke.sh' "$repo_dir/Dockerfile"
grep -q 'COPY ti-sdk-env.sh' "$repo_dir/Dockerfile"
grep -q 'CMAKE_CURRENT_LIST_DIR.*/tools' "$repo_dir/templates/mmwave-cmake-project/CMakeLists.txt.in"
grep -q 'CMAKE_CURRENT_LIST_DIR.*/../..' "$repo_dir/demos/xwr6843isk-mss-dss/CMakeLists.txt"
grep -q '../../scripts/mmwave-run.sh' "$repo_dir/demos/xwr6843isk-mss-dss/Makefile"
! grep -q 'COPY tools' "$repo_dir/Dockerfile"
! grep -q 'create-mmwave-app' "$repo_dir/Dockerfile"
grep -q 'sdk-full-sha256' "$repo_dir/.github/workflows/ci.yml"
grep -q 'SDK_CI_PROFILES' "$repo_dir/.github/workflows/ci.yml"
grep -q 'DEMO_PROFILES="$SDK_CI_PROFILES" SDK_FULL_IMAGE="$SDK_FULL_IMAGE" make sdk-profile-validate' "$repo_dir/.github/workflows/ci.yml"
grep -q 'actions/upload-artifact@v4' "$repo_dir/.github/workflows/ci.yml"
grep -q 'make flash-ui' "$repo_dir/README.md"
grep -q 'make flash-ui' "$repo_dir/README.zh-CN.md"
grep -q 'scripts/mmwavelab-flash state --json' "$repo_dir/README.md"
grep -q 'scripts/mmwavelab-flash state --json' "$repo_dir/README.zh-CN.md"
node --check "$repo_dir/flash-ui/core.js"
node --check "$repo_dir/flash-ui/cli.js"
node --check "$repo_dir/flash-ui/server.js"
node --check "$repo_dir/flash-ui/public/app.js"
"$repo_dir/scripts/mmwavelab-flash" state --json >/dev/null
"$repo_dir/scripts/mmwavelab-flash" --help >/dev/null
grep -q 'measure_command' "$repo_dir/scripts/benchmark.sh"
! grep -q '/usr/bin/time -f' "$repo_dir/scripts/benchmark.sh"
"$repo_dir/scripts/create-mmwave-app.sh" --help >/dev/null
"$repo_dir/scripts/create-mmwave-app.sh" --list-profiles >/dev/null
rm -rf "$repo_dir/build/github-actions-generated"
"$repo_dir/scripts/create-mmwave-app.sh" smoke-project \
  --profile xwr6843isk-mss-dss \
  --dir "$repo_dir/build/github-actions-generated" \
  --cmake-name smoke_project \
  --force >/dev/null
grep -q 'project(smoke_project NONE)' "$repo_dir/build/github-actions-generated/CMakeLists.txt"
grep -q -- '--pull' "$repo_dir/build/github-actions-generated/tools/mmwave-run"
grep -q 'Docker is required for this command' "$repo_dir/build/github-actions-generated/tools/mmwave-run"
rm -rf "$repo_dir/build/github-actions-generated-aop"
"$repo_dir/scripts/create-mmwave-app.sh" smoke-aop-project \
  --profile xwr6843aop-mss-dss \
  --dir "$repo_dir/build/github-actions-generated-aop" \
  --cmake-name smoke_aop_project \
  --force >/dev/null
test -f "$repo_dir/build/github-actions-generated-aop/app/dpu/trackerproc_overhead/packages/ti/alg/gtrack/lib/libgtrack3D.aer4f"
grep -q 'Radar Toolbox' "$repo_dir/build/github-actions-generated-aop/THIRD_PARTY_NOTICES.md"
python3 "$repo_dir/docs/install.py" --list-profiles >/dev/null
python3 "$repo_dir/docs/install.py" --name smoke-project --profile xwr6843isk-mss-dss --dry-run --pull never >/dev/null
rm -rf "$repo_dir/build/github-actions-install-aop"
python3 "$repo_dir/docs/install.py" \
  --name smoke-aop-install \
  --profile xwr6843aop-mss-dss \
  --dir "$repo_dir/build/github-actions-install-aop" \
  --pull never \
  --force >/dev/null
test -f "$repo_dir/build/github-actions-install-aop/app/dpu/trackerproc_overhead/packages/ti/alg/gtrack/lib/libgtrack3D.aer4f"
grep -q 'Radar Toolbox' "$repo_dir/build/github-actions-install-aop/THIRD_PARTY_NOTICES.md"
python3 "$repo_dir/scripts/validate-starter-demos.py" >/dev/null

printf 'Demo profile manifest\n'
python3 - "$repo_dir/config/starter-demo-profiles.tsv" <<'PY'
import csv
import sys
from pathlib import Path

path = Path(sys.argv[1])
required = {
    "xwr1843boost-mss-only",
    "xwr1843boost-mss-dss",
    "xwr6843isk-mss-only",
    "xwr6843isk-mss-dss",
    "xwr6843aop-mss-only",
    "xwr6843aop-mss-dss",
}
required_boards = {"xwr1843boost", "xwr6843isk", "xwr6843aop"}
required_modes = {"mss-only", "mss-dss"}
ids = set()
matrix = set()
errors = []
with path.open(encoding="utf-8", newline="") as f:
    for line_no, row in enumerate(csv.reader(f, delimiter="\t"), 1):
        if not row or row[0].startswith("#"):
            continue
        if len(row) != 16:
            errors.append(f"line {line_no}: expected 16 columns, got {len(row)}")
            continue
        profile, board, core_mode, source_kind, source_rel, sdk_device_type, sdk_device, output_artifact, cores, build_entry_kind, build_entry, clean_target, make_vars, configs, status, summary = row
        if profile in ids:
            errors.append(f"line {line_no}: duplicate profile {profile}")
        ids.add(profile)
        matrix.add((board, core_mode))
        if board not in required_boards:
            errors.append(f"line {line_no}: unexpected board {board}")
        if core_mode not in required_modes:
            errors.append(f"line {line_no}: unexpected core mode {core_mode}")
        if source_kind not in {"sdk-make", "toolbox-make", "toolbox-projectspec"}:
            errors.append(f"line {line_no}: unexpected source kind {source_kind}")
        if source_kind == "sdk-make" and not source_rel.startswith("ti/demo/"):
            errors.append(f"line {line_no}: unexpected SDK demo path {source_rel}")
        if build_entry_kind not in {"make-target", "ccs-projectspecs"}:
            errors.append(f"line {line_no}: unexpected build entry kind {build_entry_kind}")
        if source_kind in {"sdk-make", "toolbox-make"} and build_entry_kind != "make-target":
            errors.append(f"line {line_no}: make rows must use make-target entries")
        if source_kind == "toolbox-projectspec" and build_entry_kind != "ccs-projectspecs":
            errors.append(f"line {line_no}: toolbox rows must use ccs-projectspecs entries")
        if build_entry_kind == "ccs-projectspecs" and ".projectspec" not in build_entry:
            errors.append(f"line {line_no}: projectspec entry must list .projectspec files")
        if sdk_device_type not in {"xwr18xx", "xwr68xx"}:
            errors.append(f"line {line_no}: unexpected SDK device type {sdk_device_type}")
        if sdk_device not in {"iwr18xx", "iwr68xx"}:
            errors.append(f"line {line_no}: unexpected SDK device {sdk_device}")
        if cores not in {"MSS", "MSS+DSS"}:
            errors.append(f"line {line_no}: unexpected core set {cores}")
        if core_mode == "mss-only" and cores != "MSS":
            errors.append(f"line {line_no}: mss-only row must use MSS cores")
        if core_mode == "mss-dss" and cores != "MSS+DSS":
            errors.append(f"line {line_no}: mss-dss row must use MSS+DSS cores")
        if status not in {"validated", "cataloged"}:
            errors.append(f"line {line_no}: unexpected status {status}")
        if not output_artifact.endswith(".bin"):
            errors.append(f"line {line_no}: starter output must be a flashable .bin")
        if not configs:
            errors.append(f"line {line_no}: missing profile config list")
        if not all((output_artifact, build_entry, clean_target, make_vars, summary)):
            errors.append(f"line {line_no}: missing summary")
        if source_kind in {"sdk-make", "toolbox-make"}:
            demo_dir = path.parents[1] / "demos" / profile / "app"
            if not (demo_dir / "makefile").is_file():
                errors.append(f"line {line_no}: missing converted demo source {demo_dir}")
missing = sorted(required - ids)
if missing:
    errors.append(f"missing required profiles: {', '.join(missing)}")
missing_matrix = sorted((board, mode) for board in required_boards for mode in required_modes if (board, mode) not in matrix)
if missing_matrix:
    errors.append(f"missing board/mode cells: {missing_matrix}")
if errors:
    raise SystemExit("\n".join(errors))
print(f"demo profiles ok: {len(ids)}")
PY

printf 'Toolbox profile manifest\n'
python3 - "$repo_dir/docs/catalog/toolbox-oob-demo-profiles.tsv" <<'PY'
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
python3 - "$repo_dir/docs/catalog/toolbox-application-demo-profiles.tsv" <<'PY'
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

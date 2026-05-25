#!/usr/bin/env python3
"""Create a standalone TI mmWave CMake project without cloning this repo."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path


DEFAULT_IMAGE = os.environ.get("SDK_FULL_IMAGE", "meowpas/ti-mmwave-sdk:03.06.02")
DEFAULT_TOOLS_ARCHIVE_URL = os.environ.get(
    "MMWAVE_TOOLS_ARCHIVE_URL",
    "https://github.com/mmWaveLab/ti-mmwave-build-tools/archive/refs/heads/main.tar.gz",
)


@dataclass(frozen=True)
class Profile:
    name: str
    board: str
    mode: str
    source_kind: str
    source_rel: str
    sdk_device_type: str
    sdk_device: str
    artifact: str
    cores: str
    build_entry_kind: str
    build_entry: str
    clean_target: str
    configs: tuple[str, ...]
    status: str
    summary: str

    @property
    def build_target(self) -> str:
        return self.build_entry


PROFILES = {
    "xwr1843boost-mss-only": Profile("xwr1843boost-mss-only", "xwr1843boost", "mss-only", "sdk-make", "ti/demo/xwr18xx/mmw", "xwr18xx", "iwr18xx", "xwr18xx_mmw_demo.bin", "MSS", "make-target", "mssDemo", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR1843BOOST MSS-only OOB"),
    "xwr1843boost-mss-dss": Profile("xwr1843boost-mss-dss", "xwr1843boost", "mss-dss", "sdk-make", "ti/demo/xwr18xx/mmw", "xwr18xx", "iwr18xx", "xwr18xx_mmw_demo.bin", "MSS+DSS", "make-target", "mmwDemo", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR1843BOOST MSS+DSS OOB"),
    "xwr6843isk-mss-only": Profile("xwr6843isk-mss-only", "xwr6843isk", "mss-only", "sdk-make", "ti/demo/xwr68xx/mmw", "xwr68xx", "iwr68xx", "xwr68xx_mmw_demo.bin", "MSS", "make-target", "mssDemo", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR6843ISK MSS-only OOB"),
    "xwr6843isk-mss-dss": Profile("xwr6843isk-mss-dss", "xwr6843isk", "mss-dss", "sdk-make", "ti/demo/xwr68xx/mmw", "xwr68xx", "iwr68xx", "xwr68xx_mmw_demo.bin", "MSS+DSS", "make-target", "all", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR6843ISK MSS+DSS OOB"),
    "xwr6843aop-mss-only": Profile("xwr6843aop-mss-only", "xwr6843aop", "mss-only", "sdk-make", "ti/demo/xwr64xx/mmw", "xwr68xx", "iwr68xx", "xwr64xxAOP_mmw_demo.bin", "MSS", "make-target", "all", "clean", ("profile_3d_aop.cfg",), "validated", "xWR6843AOP MSS-only OOB"),
    "xwr6843aop-mss-dss": Profile("xwr6843aop-mss-dss", "xwr6843aop", "mss-dss", "toolbox-make", "source/ti/examples/Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking", "xwr68xx", "iwr68xx", "3D_people_track_6843_demo.bin", "MSS+DSS", "make-target", "all", "clean", ("AOP_6m_default.cfg", "AOP_9m_default.cfg"), "validated", "xWR6843AOP MSS+DSS 3D People Tracking"),
}


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(2)


def q(value: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9_./:=@%+-]+", value):
        return value
    return "'" + value.replace("'", "'\"'\"'") + "'"


def run(cmd: list[str], *, cwd: Path | None = None, dry_run: bool = False) -> None:
    print("+ " + " ".join(q(part) for part in cmd))
    if not dry_run:
        subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)


def cmake_name_from(project_name: str) -> str:
    name = re.sub(r"[^A-Za-z0-9_]", "_", project_name).strip("_")
    name = re.sub(r"_+", "_", name) or "mmwave_app"
    return f"app_{name}" if name[0].isdigit() else name


def list_profiles() -> None:
    print("Available profiles:\n")
    for profile in PROFILES.values():
        print(f"  {profile.name:<26} {profile.board:<12} {profile.mode:<8} {profile.status:<9} {profile.summary}")
        print(f"  {'':<26} entry={profile.build_entry_kind}:{profile.build_entry} output={profile.artifact} configs={','.join(profile.configs)}")


def cmakelists(project: str, profile: Profile) -> str:
    return f"""cmake_minimum_required(VERSION 3.20)
project({project} NONE)

set(TI_ROOT "$ENV{{TI_ROOT}}" CACHE PATH "TI SDK root inside Docker")
if(NOT TI_ROOT)
  set(TI_ROOT "/opt/ti" CACHE PATH "TI SDK root inside Docker" FORCE)
endif()
set(MMWAVE_SDK_PACKAGES "${{TI_ROOT}}/mmwave_sdk_03_06_02_00-LTS/packages" CACHE PATH "TI mmWave SDK packages")

set(MMWAVE_SDK_DEVICE "{profile.sdk_device}" CACHE STRING "SDK device")
set(MMWAVE_SDK_DEVICE_TYPE "{profile.sdk_device_type}" CACHE STRING "SDK device type")
set(MMWAVE_PROFILE "{profile.name}" CACHE STRING "Starter profile")
set(MMWAVE_SDK_DEMO_REL "{profile.source_rel}" CACHE STRING "SDK package-relative demo source path")
set(MMWAVE_BUILD_TARGET "{profile.build_target}" CACHE STRING "TI make build target")
set(MMWAVE_CLEAN_TARGET "{profile.clean_target}" CACHE STRING "TI make clean target")
option(MMWAVE_USE_SDK_OVERLAY "Build through a temporary SDK package overlay instead of the canonical SDK packages path" OFF)

set(APP_SOURCE_DIR "${{CMAKE_CURRENT_LIST_DIR}}/app")
set(APP_BUILD_DIR "${{CMAKE_BINARY_DIR}}/app")
set(SDK_PACKAGES_OVERLAY "${{CMAKE_BINARY_DIR}}/sdk-packages-overlay")
set(MMWAVE_BUILD_SDK_PACKAGES "${{MMWAVE_SDK_PACKAGES}}")
if(MMWAVE_USE_SDK_OVERLAY)
  set(MMWAVE_BUILD_SDK_PACKAGES "${{SDK_PACKAGES_OVERLAY}}")
endif()
set(OUTPUT_ARTIFACT "${{APP_BUILD_DIR}}/{profile.artifact}")
set(MSS_METAIMAGE_HELPER "${{CMAKE_BINARY_DIR}}/mss-metaimage-if-needed.sh")
set(SDK_OVERLAY_HELPER "${{CMAKE_BINARY_DIR}}/sdk-packages-overlay.sh")

file(WRITE "${{SDK_OVERLAY_HELPER}}" [=[
#!/usr/bin/env bash
set -euo pipefail

real="${{MMWAVE_SDK_PACKAGES:?}}"
overlay="${{SDK_PACKAGES_OVERLAY:?}}"
app="${{APP_BUILD_DIR:?}}"
demo_rel="${{MMWAVE_SDK_DEMO_REL:?}}"

rm -rf "$overlay"
mkdir -p "$overlay" "$overlay/ti"

for item in "$real"/*; do
  base="$(basename "$item")"
  [[ "$base" == "ti" ]] && continue
  ln -s "$item" "$overlay/$base"
done

for item in "$real"/ti/*; do
  base="$(basename "$item")"
  [[ "$base" == "demo" ]] && continue
  ln -s "$item" "$overlay/ti/$base"
done

mkdir -p "$overlay/ti/demo"
if [[ -d "$app/utils" ]]; then
  ln -s "$app/utils" "$overlay/ti/demo/utils"
elif [[ -d "$real/ti/demo/utils" ]]; then
  ln -s "$real/ti/demo/utils" "$overlay/ti/demo/utils"
fi

mkdir -p "$overlay/$(dirname "$demo_rel")"
ln -s "$app" "$overlay/$demo_rel"
test -f "$overlay/$demo_rel/makefile"
]=])

file(WRITE "${{MSS_METAIMAGE_HELPER}}" [=[
#!/usr/bin/env bash
set -euo pipefail

if [[ -f "$OUTPUT_BIN" || "$OUTPUT_BIN" != *.bin ]]; then
  test -f "$OUTPUT_BIN"
  exit 0
fi

case "$MMWAVE_SDK_DEVICE_TYPE" in
  xwr18xx)
    shmem_alloc="0x00000008"
    radarss="$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/firmware/radarss/xwr18xx_radarss_rprc.bin"
    ;;
  *)
    shmem_alloc="0x00000006"
    radarss="$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/firmware/radarss/xwr6xxx_radarss_rprc.bin"
    ;;
esac

mss_out="${{OUTPUT_BIN%.bin}}_mss.xer4f"
test -f "$mss_out"
test -f "$radarss"
MMWAVE_SDK_INSTALL_PATH="${{MMWAVE_SDK_INSTALL_PATH:-$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages}}" \
  "$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/generateMetaImage.sh" \
  "$OUTPUT_BIN" "$shmem_alloc" "$mss_out" "$radarss" NULL
test -f "$OUTPUT_BIN"
]=])

foreach(required_path
    "${{APP_SOURCE_DIR}}/makefile"
    "${{MMWAVE_SDK_PACKAGES}}/scripts/unix/generateMetaImage.sh")
  if(NOT EXISTS "${{required_path}}")
    message(FATAL_ERROR "Required path not found: ${{required_path}}")
  endif()
endforeach()

add_custom_command(
  OUTPUT "${{OUTPUT_ARTIFACT}}"
  COMMAND "${{CMAKE_COMMAND}}" -E rm -rf "${{APP_BUILD_DIR}}"
  COMMAND "${{CMAKE_COMMAND}}" -E copy_directory "${{APP_SOURCE_DIR}}" "${{APP_BUILD_DIR}}"
  COMMAND "${{CMAKE_COMMAND}}" -E env
    "MMWAVE_SDK_PACKAGES=${{MMWAVE_SDK_PACKAGES}}"
    "SDK_PACKAGES_OVERLAY=${{SDK_PACKAGES_OVERLAY}}"
    "APP_BUILD_DIR=${{APP_BUILD_DIR}}"
    "MMWAVE_SDK_DEMO_REL=${{MMWAVE_SDK_DEMO_REL}}"
    /bin/bash "${{SDK_OVERLAY_HELPER}}"
  COMMAND "${{CMAKE_COMMAND}}" -E env
    "CCS_MAKEFILE_BASED_BUILD=1"
    "MMWAVE_SDK_DEVICE=${{MMWAVE_SDK_DEVICE}}"
    "MMWAVE_SDK_DEVICE_TYPE=${{MMWAVE_SDK_DEVICE_TYPE}}"
    "MMWAVE_SDK_TOOLS_INSTALL_PATH=${{TI_ROOT}}"
    "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_BUILD_SDK_PACKAGES}}"
    "${{CMAKE_COMMAND}}" -E chdir "${{APP_BUILD_DIR}}"
    make -f makefile "${{MMWAVE_CLEAN_TARGET}}"
      "MMWAVE_SDK_TOOLS_INSTALL_PATH=${{TI_ROOT}}"
      "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_BUILD_SDK_PACKAGES}}"
  COMMAND "${{CMAKE_COMMAND}}" -E env
    "CCS_MAKEFILE_BASED_BUILD=1"
    "MMWAVE_SDK_DEVICE=${{MMWAVE_SDK_DEVICE}}"
    "MMWAVE_SDK_DEVICE_TYPE=${{MMWAVE_SDK_DEVICE_TYPE}}"
    "MMWAVE_SDK_TOOLS_INSTALL_PATH=${{TI_ROOT}}"
    "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_BUILD_SDK_PACKAGES}}"
    "${{CMAKE_COMMAND}}" -E chdir "${{APP_BUILD_DIR}}"
    make -f makefile "${{MMWAVE_BUILD_TARGET}}"
      "MMWAVE_SDK_TOOLS_INSTALL_PATH=${{TI_ROOT}}"
      "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_BUILD_SDK_PACKAGES}}"
  COMMAND "${{CMAKE_COMMAND}}" -E env
    "OUTPUT_BIN=${{OUTPUT_ARTIFACT}}"
    "TI_ROOT=${{TI_ROOT}}"
    "MMWAVE_SDK_DEVICE_TYPE=${{MMWAVE_SDK_DEVICE_TYPE}}"
    "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_BUILD_SDK_PACKAGES}}"
    /bin/bash "${{MSS_METAIMAGE_HELPER}}"
  WORKING_DIRECTORY "${{CMAKE_BINARY_DIR}}"
  VERBATIM
  COMMENT "Building {profile.name}"
)

add_custom_target(firmware ALL DEPENDS "${{OUTPUT_ARTIFACT}}")
install(FILES "${{OUTPUT_ARTIFACT}}" DESTINATION .)
"""


def makefile(image: str) -> str:
    return f"""IMAGE ?= {image}
BUILD_DIR ?= build
MMWAVE_RUN ?= tools/mmwave-run

.PHONY: pull configure build shell clean

pull:
\tdocker pull $(IMAGE)

configure:
\t$(MMWAVE_RUN) --image $(IMAGE) --workdir . -- cmake -S . -B $(BUILD_DIR) -G Ninja -DTI_ROOT=/opt/ti

build: configure
\t$(MMWAVE_RUN) --image $(IMAGE) --workdir . -- cmake --build $(BUILD_DIR) --target firmware

shell:
\t$(MMWAVE_RUN) --image $(IMAGE) --workdir . --shell

clean:
\trm -rf $(BUILD_DIR)
"""


def runner(default_image: str) -> str:
    return f"""#!/usr/bin/env bash
set -euo pipefail

usage() {{
  cat <<'USAGE'
Usage:
  mmwave-run [--image IMAGE] [--workdir DIR] [--pull] -- COMMAND [ARG...]
  mmwave-run [--image IMAGE] [--workdir DIR] --shell
USAGE
}}

need_value() {{
  local opt="$1"
  local value="${{2:-}}"
  if [[ -z "$value" || "$value" == --* ]]; then
    printf 'Missing value for %s.\\n\\n' "$opt" >&2
    usage >&2
    exit 2
  fi
}}

require_docker() {{
  if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker is required for this command, but the docker executable was not found in PATH.\\n' >&2
    printf 'Install Docker or run this command on a machine with Docker access.\\n' >&2
    exit 2
  fi
}}

image="${{SDK_FULL_IMAGE:-${{IMAGE:-{default_image}}}}}"
workdir="$PWD"
pull=0
shell_mode=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) need_value "$1" "${{2:-}}"; image="$2"; shift 2 ;;
    --workdir|-w) need_value "$1" "${{2:-}}"; workdir="$2"; shift 2 ;;
    --pull) pull=1; shift ;;
    --shell) shell_mode=1; shift ;;
    --) shift; break ;;
    -h|--help) usage; exit 0 ;;
    *)
      printf 'Unknown argument: %s\\n\\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$image" ]]; then
  printf 'IMAGE is required.\\n' >&2
  exit 2
fi

case "$workdir" in
  /*) abs_workdir="$workdir" ;;
  *) abs_workdir="$PWD/$workdir" ;;
esac

if [[ ! -d "$abs_workdir" ]]; then
  printf 'Workdir does not exist: %s\\n' "$abs_workdir" >&2
  exit 2
fi

if [[ ! -w "$abs_workdir" ]]; then
  printf 'Workdir is not writable by the current user: %s\\n' "$abs_workdir" >&2
  exit 2
fi

if (( pull )); then
  require_docker
  docker pull "$image"
fi

docker_args=(--rm -e HOME=/tmp/mmwave-home -v "$abs_workdir":/work/app -w /work/app)
if [[ "$(uname -s)" != MINGW* && "$(uname -s)" != MSYS* && "$(uname -s)" != CYGWIN* ]]; then
  docker_args+=(--user "$(id -u):$(id -g)")
fi

clean_env=(env -i
  HOME=/tmp/mmwave-home
  USER=mmwave
  LOGNAME=mmwave
  PATH=/opt/ti/ti-cgt-arm_16.9.6.LTS/bin:/opt/ti/ti-cgt-c6000_8.3.3/bin:/opt/ti/xdctools_3_50_08_24_core:/usr/local/bin:/usr/bin:/bin
  TI_ROOT=/opt/ti
)

if [[ "$shell_mode" -eq 1 ]]; then
  require_docker
  exec docker run -it "${{docker_args[@]}}" "$image" "${{clean_env[@]}}" bash --noprofile --norc
fi

if [[ $# -eq 0 ]]; then
  printf 'COMMAND is required unless --shell is used.\\n\\n' >&2
  usage >&2
  exit 2
fi

require_docker
exec docker run "${{docker_args[@]}}" "$image" "${{clean_env[@]}}" "$@"
"""


def readme(name: str, cmake_project: str, profile: Profile, image: str) -> str:
    if profile.source_kind == "toolbox-make":
        source_label = "selected TI Radar Toolbox source"
        license_note = """This project contains source and one vendor runtime library copied from TI
Radar Toolbox 4.00.00.05. Preserve the upstream copyright and limited license
notices in source files. See this project's `THIRD_PARTY_NOTICES.md` for the TI
notice text."""
    else:
        source_label = "TI's canonical SDK package path"
        license_note = """This project contains source copied from TI mmWave SDK `packages/ti/demo`,
which TI's SDK 03.06.02 software manifest lists under BSD-3-Clause. Preserve
the upstream copyright and license notices in source files. See this project's
`THIRD_PARTY_NOTICES.md` for the TI notice text."""
    return f"""# {name}

Standalone TI mmWave CMake/Ninja project generated by `install.py`.

- CMake project: `{cmake_project}`
- Profile: `{profile.name}`
- Board: `{profile.board}`
- Core mode: `{profile.mode}`
- Artifact: `{profile.artifact}`
- Docker image: `{image}`
- Configs: `{", ".join(profile.configs)}`

```bash
make build
```

The build runs inside the SDK-full Docker image. The host machine does not need
a TI SDK install. The default CMake path preserves byte-identical SHA-256 output
against {source_label}; set `MMWAVE_USE_SDK_OVERLAY=ON` only for slim-image
experiments.

## License Note

{license_note}
"""


def third_party_notices(profile: Profile) -> str:
    if profile.source_kind == "toolbox-make":
        return """# Third-Party Notices

This generated project contains source and one vendor runtime library copied
from Texas Instruments Radar Toolbox.

- Upstream package: TI Radar Toolbox 4.00.00.05
- Upstream demo path: `source/ti/examples/Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking`
- Upstream support path: `source/ti/custom_sdk_files/sdk3`
- Vendored binary dependency: `app/dpu/trackerproc_overhead/packages/ti/alg/gtrack/lib/libgtrack3D.aer4f`

The upstream TI copyright and license notices inside source files are preserved
verbatim. Do not remove or normalize those notices when updating the generated
project.

Limited License text used by the TI Radar Toolbox demo source headers:

```text
All rights reserved not granted herein.
Limited License.

Redistributions must preserve existing copyright notices and reproduce this
license in the documentation and/or other materials provided with the
distribution.

Redistribution and use in binary form, without modification, are permitted for
use only with TI Devices and without reverse engineering, decompilation, or
disassembly of software provided in binary form.

If software source code is provided to you, modification and redistribution of
the source code and resulting object code are permitted for use only with TI
Devices.

Neither the name of Texas Instruments Incorporated nor the names of its suppliers
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY TI AND TI'S LICENSORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES ARE DISCLAIMED.
```
"""
    return """# Third-Party Notices

This generated project contains source copied from Texas Instruments mmWave SDK
`packages/ti/demo`.

- Upstream package: TI mmWave SDK 03.06.02.00-LTS
- Upstream manifest: https://dr-download.ti.com/software-development/software-development-kit-sdk/MD-PIrUeCYr3X/03.06.02.00-LTS/mmwave_sdk_software_manifest.html
- Manifest license for `packages/ti/demo`: BSD-3-Clause

The upstream TI copyright and license notices inside source files are preserved
verbatim. Do not remove or normalize those notices when updating the generated
project.

BSD-3-Clause text used by the TI demo source headers:

```text
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the
distribution.

Neither the name of Texas Instruments Incorporated nor the names of
its contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
"""


def write(path: Path, text: str, executable: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    if executable:
        path.chmod(path.stat().st_mode | 0o755)


def pull_image(image: str, policy: str, dry_run: bool) -> None:
    if policy == "never" or (policy == "auto" and image.endswith("-local")):
        return
    try:
        run(["docker", "pull", image], dry_run=dry_run)
    except subprocess.CalledProcessError:
        if policy == "always":
            raise
        print(f"warning: could not pull {image}; trying local image", file=sys.stderr)


def local_demo_source(profile: Profile) -> Path | None:
    try:
        repo_root = Path(__file__).resolve().parent.parent
    except OSError:
        return None
    source = repo_root / "demos" / profile.name / "app"
    return source if (source / "makefile").is_file() else None


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def safe_child(base: Path, rel: Path) -> Path:
    target = (base / rel).resolve()
    base_resolved = base.resolve()
    if target != base_resolved and base_resolved not in target.parents:
        fail(f"unsafe archive path: {rel}")
    return target


def copy_demo_from_archive(out_dir: Path, profile: Profile, archive_url: str) -> None:
    app_dir = out_dir / "app"
    requests = {
        f"demos/{profile.name}/app/": app_dir,
    }
    with tempfile.TemporaryDirectory(prefix="mmwave-tools-archive-") as tmp:
        archive = Path(tmp) / "tools.tar.gz"
        print(f"+ download {q(archive_url)}")
        with urllib.request.urlopen(archive_url, timeout=120) as response, archive.open("wb") as fh:
            shutil.copyfileobj(response, fh)
        for dst in requests.values():
            if dst.exists():
                shutil.rmtree(dst)
            dst.mkdir(parents=True, exist_ok=True)
        found = {suffix: False for suffix in requests}
        with tarfile.open(archive, "r:*") as tar:
            for member in tar:
                name = member.name
                matched_suffix = None
                for suffix in requests:
                    marker = "/" + suffix
                    if marker in name:
                        matched_suffix = suffix
                        break
                if matched_suffix is None:
                    continue
                rel_name = name.split("/" + matched_suffix, 1)[1]
                if not rel_name:
                    continue
                found[matched_suffix] = True
                dst = requests[matched_suffix]
                rel = Path(rel_name)
                target = safe_child(dst, rel)
                if member.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    src = tar.extractfile(member)
                    if src is None:
                        fail(f"could not read archive member: {name}")
                    with src, target.open("wb") as out:
                        shutil.copyfileobj(src, out)
        missing = [suffix for suffix, ok in found.items() if not ok]
        has_rfparser = (app_dir / "utils" / "mmwdemo_rfparser.c").is_file() or (app_dir / "common" / "mmwdemo_rfparser.c").is_file()
        if missing or not (app_dir / "makefile").is_file() or not has_rfparser:
            fail(f"demo source not found in tools archive: {', '.join(missing)}")


def copy_demo(out_dir: Path, profile: Profile, archive_url: str, dry_run: bool) -> None:
    app_dir = out_dir / "app"
    local_source = local_demo_source(profile)
    if dry_run:
        source = str(local_source) if local_source else archive_url
        print(f"+ copy demo {q(profile.name + '/app')} from {q(source)} to {q(str(app_dir))}")
        return
    if local_source is not None:
        copy_tree(local_source, app_dir)
        return
    copy_demo_from_archive(out_dir, profile, archive_url)


def create(args: argparse.Namespace) -> None:
    project_name = args.name_opt or args.name_pos
    if not project_name:
        fail("project name is required")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", project_name):
        fail("project name must use letters, numbers, dot, underscore, or hyphen")
    profile = PROFILES.get(args.profile)
    if profile is None:
        fail(f"unsupported profile: {args.profile}")
    if profile.source_kind not in {"sdk-make", "toolbox-make"}:
        fail(
            f"{profile.name} needs the Toolbox projectspec importer before install.py can generate it "
            f"(entry={profile.build_entry_kind}:{profile.build_entry})"
        )
    if profile.build_entry_kind != "make-target":
        fail(f"{profile.name} does not expose a TI make target: {profile.build_entry_kind}:{profile.build_entry}")
    docker_missing = shutil.which("docker") is None
    if docker_missing and not args.dry_run:
        if args.build or args.pull != "never":
            fail("docker command not found")
        print("warning: docker command not found; generating project without build validation", file=sys.stderr)

    cmake_project = args.cmake_name or cmake_name_from(project_name)
    out_dir = Path(args.dir or project_name).expanduser()
    if not out_dir.is_absolute():
        out_dir = Path.cwd() / out_dir
    if out_dir.exists() and any(out_dir.iterdir()) and not args.force:
        fail(f"output directory is not empty: {out_dir}")

    print(f"Project: {project_name}")
    print(f"CMake project: {cmake_project}")
    print(f"Profile: {profile.name}")
    print(f"Output: {out_dir}")

    if not args.dry_run:
        if args.force and out_dir.exists():
            shutil.rmtree(out_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        print("Dry run: no files will be written.")

    pull_image(args.image, args.pull, args.dry_run)
    copy_demo(out_dir, profile, args.tools_archive_url, args.dry_run)

    if not args.dry_run:
        write(out_dir / "CMakeLists.txt", cmakelists(cmake_project, profile))
        write(out_dir / "Makefile", makefile(args.image))
        write(out_dir / "README.md", readme(project_name, cmake_project, profile, args.image))
        write(out_dir / "THIRD_PARTY_NOTICES.md", third_party_notices(profile))
        write(out_dir / ".gitignore", "build/\nartifacts/\nreports/\n*.log\n.DS_Store\n")
        write(out_dir / "src" / "README.md", "Project-local sources can live here.\n")
        write(out_dir / "tools" / "mmwave-run", runner(args.image), executable=True)

    if args.build:
        run(["make", "build"], cwd=out_dir, dry_run=args.dry_run)

    print("\nDone.")
    print(f"  cd {q(str(out_dir))}")
    print("  make build")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a TI mmWave CMake project without cloning tools.")
    parser.add_argument("name_pos", nargs="?")
    parser.add_argument("--name", dest="name_opt")
    parser.add_argument("--dir")
    parser.add_argument("--cmake-name")
    parser.add_argument("--profile", default="xwr6843isk-mss-dss")
    parser.add_argument("--image", default=DEFAULT_IMAGE)
    parser.add_argument("--tools-archive-url", default=DEFAULT_TOOLS_ARCHIVE_URL)
    parser.add_argument("--pull", choices=("auto", "always", "never"), default="auto")
    parser.add_argument("--build", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--list-profiles", action="store_true")
    args = parser.parse_args()
    if args.list_profiles:
        list_profiles()
        raise SystemExit(0)
    return args


if __name__ == "__main__":
    create(parse_args())

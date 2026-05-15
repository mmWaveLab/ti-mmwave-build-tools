#!/usr/bin/env python3
"""Create a standalone TI mmWave CMake project without cloning this repo."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


DEFAULT_IMAGE = os.environ.get("SDK_FULL_IMAGE", "meowpas/ti-mmwave-sdk:03.06.02")
SDK_PACKAGES = "/opt/ti/mmwave_sdk_03_06_02_00-LTS/packages"


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
    build_target: str
    clean_target: str
    configs: tuple[str, ...]
    status: str
    summary: str


PROFILES = {
    "xwr1843boost-mss-only": Profile("xwr1843boost-mss-only", "xwr1843boost", "mss-only", "sdk-make", "ti/demo/xwr18xx/mmw", "xwr18xx", "iwr18xx", "xwr18xx_mmw_demo.bin", "MSS", "mssDemo", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR1843BOOST MSS-only OOB"),
    "xwr1843boost-mss-dss": Profile("xwr1843boost-mss-dss", "xwr1843boost", "mss-dss", "sdk-make", "ti/demo/xwr18xx/mmw", "xwr18xx", "iwr18xx", "xwr18xx_mmw_demo.bin", "MSS+DSS", "mmwDemo", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR1843BOOST MSS+DSS OOB"),
    "xwr6843isk-mss-only": Profile("xwr6843isk-mss-only", "xwr6843isk", "mss-only", "sdk-make", "ti/demo/xwr68xx/mmw", "xwr68xx", "iwr68xx", "xwr68xx_mmw_demo.bin", "MSS", "mssDemo", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR6843ISK MSS-only OOB"),
    "xwr6843isk-mss-dss": Profile("xwr6843isk-mss-dss", "xwr6843isk", "mss-dss", "sdk-make", "ti/demo/xwr68xx/mmw", "xwr68xx", "iwr68xx", "xwr68xx_mmw_demo.bin", "MSS+DSS", "all", "clean", ("profile_2d.cfg", "profile_3d.cfg"), "validated", "xWR6843ISK MSS+DSS OOB"),
    "xwr6843aop-mss-only": Profile("xwr6843aop-mss-only", "xwr6843aop", "mss-only", "sdk-make", "ti/demo/xwr64xx/mmw", "xwr68xx", "iwr68xx", "xwr64xxAOP_mmw_demo.bin", "MSS", "all", "clean", ("profile_3d_aop.cfg",), "validated", "xWR6843AOP MSS-only OOB"),
    "xwr6843aop-mss-dss": Profile("xwr6843aop-mss-dss", "xwr6843aop", "mss-dss", "toolbox-projectspec", "source/ti/examples/Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking", "xwr68xx", "iwr68xx", "prebuilt_binaries/3D_people_track_6843_demo.bin", "MSS+DSS", "src/6843/3D_people_track_6843_mss.projectspec,src/6843/3D_people_track_6843_dss.projectspec", "-", ("chirp_configs/AOP_6m_default.cfg", "chirp_configs/AOP_9m_default.cfg"), "cataloged", "xWR6843AOP MSS+DSS Toolbox application"),
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


def docker_run_base() -> list[str]:
    cmd = ["docker", "run", "--rm"]
    if os.name == "posix":
        cmd += ["--user", f"{os.getuid()}:{os.getgid()}"]
    return cmd


def list_profiles() -> None:
    print("Available profiles:\n")
    for profile in PROFILES.values():
        print(f"  {profile.name:<26} {profile.board:<12} {profile.mode:<8} {profile.status:<9} {profile.summary}")
        print(f"  {'':<26} output={profile.artifact} configs={','.join(profile.configs)}")


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
set(MMWAVE_BUILD_TARGET "{profile.build_target}" CACHE STRING "TI make build target")
set(MMWAVE_CLEAN_TARGET "{profile.clean_target}" CACHE STRING "TI make clean target")

set(APP_SOURCE_DIR "${{CMAKE_CURRENT_LIST_DIR}}/app")
set(APP_BUILD_DIR "${{CMAKE_BINARY_DIR}}/app")
set(OUTPUT_ARTIFACT "${{APP_BUILD_DIR}}/{profile.artifact}")
set(MSS_METAIMAGE_HELPER "${{CMAKE_BINARY_DIR}}/mss-metaimage-if-needed.sh")

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
MMWAVE_SDK_INSTALL_PATH="$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages" \
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
    "CCS_MAKEFILE_BASED_BUILD=1"
    "MMWAVE_SDK_DEVICE=${{MMWAVE_SDK_DEVICE}}"
    "MMWAVE_SDK_DEVICE_TYPE=${{MMWAVE_SDK_DEVICE_TYPE}}"
    "MMWAVE_SDK_TOOLS_INSTALL_PATH=${{TI_ROOT}}"
    "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_SDK_PACKAGES}}"
    "${{CMAKE_COMMAND}}" -E chdir "${{APP_BUILD_DIR}}"
    make -f makefile "${{MMWAVE_CLEAN_TARGET}}"
  COMMAND "${{CMAKE_COMMAND}}" -E env
    "CCS_MAKEFILE_BASED_BUILD=1"
    "MMWAVE_SDK_DEVICE=${{MMWAVE_SDK_DEVICE}}"
    "MMWAVE_SDK_DEVICE_TYPE=${{MMWAVE_SDK_DEVICE_TYPE}}"
    "MMWAVE_SDK_TOOLS_INSTALL_PATH=${{TI_ROOT}}"
    "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_SDK_PACKAGES}}"
    "${{CMAKE_COMMAND}}" -E chdir "${{APP_BUILD_DIR}}"
    make -f makefile "${{MMWAVE_BUILD_TARGET}}"
  COMMAND "${{CMAKE_COMMAND}}" -E env
    "OUTPUT_BIN=${{OUTPUT_ARTIFACT}}"
    "TI_ROOT=${{TI_ROOT}}"
    "MMWAVE_SDK_DEVICE_TYPE=${{MMWAVE_SDK_DEVICE_TYPE}}"
    "MMWAVE_SDK_INSTALL_PATH=${{MMWAVE_SDK_PACKAGES}}"
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

image="${{SDK_FULL_IMAGE:-${{IMAGE:-{default_image}}}}}"
workdir="$PWD"
shell_mode=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image="$2"; shift 2 ;;
    --workdir) workdir="$2"; shift 2 ;;
    --shell) shell_mode=1; shift ;;
    --) shift; break ;;
    *) break ;;
  esac
done

case "$workdir" in
  /*) abs_workdir="$workdir" ;;
  *) abs_workdir="$PWD/$workdir" ;;
esac

docker_args=(--rm -e HOME=/tmp/mmwave-home -v "$abs_workdir":/work/app -w /work/app)
if [[ "$(uname -s)" != MINGW* && "$(uname -s)" != MSYS* && "$(uname -s)" != CYGWIN* ]]; then
  docker_args+=(--user "$(id -u):$(id -g)")
fi

clean_env=(env -i
  HOME=/tmp/mmwave-home
  USER=mmwave
  LOGNAME=mmwave
  PATH=/opt/ti/ti-cgt-arm_16.9.6.LTS/bin:/opt/ti/ti-cgt-c6000_8.3.3/bin:/opt/ti/xdctools_3_50_08_24_core:/opt/ti-mmwave-build-tools/scripts:/usr/local/bin:/usr/bin:/bin
  TI_ROOT=/opt/ti
  TI_MMWAVE_TOOLS_ROOT=/opt/ti-mmwave-build-tools)

if [[ "$shell_mode" -eq 1 ]]; then
  exec docker run -it "${{docker_args[@]}}" "$image" "${{clean_env[@]}}" bash --noprofile --norc
fi

exec docker run "${{docker_args[@]}}" "$image" "${{clean_env[@]}}" "$@"
"""


def readme(name: str, cmake_project: str, profile: Profile, image: str) -> str:
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
a TI SDK install.
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


def copy_demo(out_dir: Path, profile: Profile, image: str, dry_run: bool) -> None:
    parent = out_dir.parent.resolve()
    container_out = f"/work/{out_dir.name}"
    source = f"{SDK_PACKAGES}/{profile.source_rel}"
    script = (
        "set -euo pipefail; "
        f"test -f {q(source + '/makefile')}; "
        f"rm -rf {q(container_out + '/app')}; "
        f"mkdir -p {q(container_out + '/app')}; "
        f"cp -a {q(source + '/.')} {q(container_out + '/app/')}"
    )
    run(docker_run_base() + ["-v", f"{parent}:/work", "-w", "/work", image, "bash", "-lc", script], dry_run=dry_run)


def create(args: argparse.Namespace) -> None:
    project_name = args.name_opt or args.name_pos
    if not project_name:
        fail("project name is required")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", project_name):
        fail("project name must use letters, numbers, dot, underscore, or hyphen")
    profile = PROFILES.get(args.profile)
    if profile is None:
        fail(f"unsupported profile: {args.profile}")
    if profile.source_kind != "sdk-make":
        fail(f"{profile.name} needs the Toolbox projectspec importer before install.py can generate it")
    if shutil.which("docker") is None and not args.dry_run:
        fail("docker command not found")

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
    copy_demo(out_dir, profile, args.image, args.dry_run)

    if not args.dry_run:
        write(out_dir / "CMakeLists.txt", cmakelists(cmake_project, profile))
        write(out_dir / "Makefile", makefile(args.image))
        write(out_dir / "README.md", readme(project_name, cmake_project, profile, args.image))
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

# TI mmWave SDK Docker Build Tools

Reproducible Linux build, validation, and flashing helpers for TI mmWave SDK
03.06 MSS+DSS demo firmware.

This repository packages the host glue around an existing TI SDK installation:
Docker for dependency isolation, CMake+Ninja entry points for firmware builds,
starter-project validation, native-vs-Docker benchmarks, and guarded UniFlash
command generation.

It does not redistribute TI SDKs, compilers, UniFlash, or device firmware owned
by TI. Bring your own TI installation and mount it into the build environment.

## What Works

- Build TI mmWave SDK 03.06 demo firmware on Linux.
- Build `xwr68xx/mmw` MSS+DSS through CMake and Ninja.
- Create forked mmWave CMake/Ninja firmware projects from TI SDK demos.
- Validate starter OOB demo forks in Docker.
- Compare direct TI OOB demo builds with generated starter projects by SHA-256.
- Compare Docker and native Ubuntu build time and output hashes.
- Generate safe UniFlash/DSLite commands with an explicit serial port.
- Keep generated build output under `build/`, `artifacts/`, and `reports/`.

## Current Status

| Area | Status | Evidence |
|---|---:|---|
| Docker SDK environment | Validated | `make doctor`, `make test`, `make ci` |
| CMake+Ninja MSS+DSS build | Validated | Docker/native SHA-256 match |
| Starter demo fork SHA comparison | Validated | `make sdk-profile-validate` |
| UniFlash integration layer | Guarded test available | `make flash-doctor`, `make flash-dry-run` |
| Real hardware flash | Pending | Requires TI UniFlash/DSLite and a board in download mode |

## Quick Start

On a Linux host with TI tools installed:

```bash
cp config/machine.env.example config/machine.env
```

Edit `config/machine.env`:

```bash
HOST_TI_ROOT=/path/to/ti
TI_ROOT=/path/to/ti
CONTAINER_TI_ROOT=/opt/ti
```

Build and test:

```bash
make docker-build
make doctor
make test
make sdk-profile-validate
```

Build the CMake+Ninja MSS+DSS example:

```bash
make docker-cmake
```

Create and build a new forked CMake project from the SDK-full image:

```bash
docker run --rm -it -v "$PWD":/work -w /work \
  meowkj/ti-mmwave-sdk:03.06.02-local \
  create-mmwave-app people-count-6843 --profile iwr6843isk-oob
cd people-count-6843
make build
```

List the common TI demo fork profiles:

```bash
docker run --rm meowkj/ti-mmwave-sdk:03.06.02-local create-mmwave-app --list-profiles
```

Check UniFlash readiness:

```bash
make flash-list
make flash-doctor
```

## SDK Path Contract

The container sees the TI install at `CONTAINER_TI_ROOT`, defaulting to
`/opt/ti`. This path is intentionally stable because TI XDC/configuro and
generated make fragments embed absolute SDK and toolchain paths.

The host path can still be different. Set `HOST_TI_ROOT` to the real local TI
installation, and the scripts mount it read-only into the container.

## Starter Profiles

The generator intentionally exposes only starter OOB projects, not every SDK
coverage target:

| Profile | SDK demo | Cores | Firmware artifact |
|---|---|---:|---|
| `iwr6843isk-oob` | `ti/demo/xwr68xx/mmw` | MSS+DSS | `xwr68xx_mmw_demo.bin` |
| `iwr1843boost-oob` | `ti/demo/xwr18xx/mmw` | MSS+DSS | `xwr18xx_mmw_demo.bin` |

IWR6843AOP is not aliased to IWR6843ISK. Add it only when the Radar Toolbox OOB
source package is included in the private SDK-full image.

Validation reports are generated under `reports/` when the relevant commands
run. The repository keeps only source, docs, templates, and lightweight
manifests under version control.

## Reusable CMake API

The original reusable CMake helper API remains available under `cmake/` for
firmware repositories that want to inherit common TI mmWave build rules through
a submodule, subtree, or `FetchContent`.

Key files:

- `cmake/TiMmwaveSdk.cmake`: reusable build API.
- `cmake/RunConfiguro.cmake`: XDC configuro wrapper.
- `cmake/RunMetaImage.cmake`: ImageCreator wrapper.
- `cmake/TiMmwaveSdkPaths.cmake`: Linux path discovery used by this Docker lab.
- `templates/mmwave-cmake-project`: project scaffold for new CMake/Ninja
  firmware projects.
- `config/demo-profiles.tsv`: starter TI OOB demo fork profiles used by
  `create-mmwave-app --profile`.
- `docker/Dockerfile.sdk-full`: private SDK-full image recipe for local or
  private-registry use.

The Docker validation flow in this README exercises the SDK reference demo
makefiles. Downstream firmware projects can still use the reusable CMake API
directly when they need finer-grained source-level build integration.

## Useful Commands

Validate the TI Linux tools directly inside the container:

```bash
docker run --rm \
  -v /opt/ti:/opt/ti:ro \
  ti-mmwave-build-tools:linux-smoke \
  check-ti-linux
```

Run the upstream repository smoke test:

```bash
docker run --rm \
  -v /opt/ti:/opt/ti:ro \
  -v "$PWD/work":/work \
  ti-mmwave-build-tools:linux-smoke \
  run-repo-smoke
```

The smoke test configures the upstream example with explicit Linux tool paths.
Use it when checking whether upstream `mmWaveLab/ti-mmwave-build-tools`
continues to work against the Linux SDK/toolchain profile.

Build the TI SDK xWR68xx demo with the reference SDK make flow:

```bash
scripts/build-xwr68xx-sdk-demo.sh
```

## Build MSS+DSS with CMake and Ninja

The CMake example at `examples/xwr68xx-sdk-mss-dss-cmake` builds the TI SDK
`xwr68xx/mmw` demo through Ninja. The Ninja target drives the official SDK
make rules, so MSS, DSS, SYS/BIOS RTSC configuro, and metaimage generation all
stay aligned with TI's reference build.

Docker:

```bash
scripts/cmake-build-xwr68xx-sdk-demo.sh
```

Native Ubuntu:

```bash
source scripts/ti-sdk-env.sh
cmake -S examples/xwr68xx-sdk-mss-dss-cmake -B perf/cmake-xwr68xx-native -G Ninja -DTI_ROOT=/opt/ti
cmake --build perf/cmake-xwr68xx-native --target firmware
```

## Test, Benchmark, Clean

```bash
make doctor
make github-actions-smoke
make test
make benchmark
make project-new PROJECT=name PROFILE=iwr6843isk-oob
make sdk-image
make sdk-image-smoke
make sdk-profile-validate
make flash-list
make flash-doctor
make package
make clean
```

Generated files are kept under:

- `build/`: CMake/Ninja build trees
- `artifacts/`: copied firmware binaries
- `reports/`: benchmark reports

The Docker commands use `--rm`, so stopped containers are removed
automatically. The SDK mount is read-only, so builds do not write into
`/opt/ti`.

## CI and Maintenance

- Portability guide: `docs/PORTABILITY.md`
- CI guide: `docs/CI.md`
- Maintenance guide: `docs/MAINTENANCE.md`
- Project template guide: `docs/PROJECT_TEMPLATE.md`
- Docker image guide: `docs/DOCKER_IMAGE.md`
- Project management: `docs/PROJECT_MANAGEMENT.md`
- UniFlash guide: `docs/UNIFLASH.md`
- GitHub About text: `docs/ABOUT.md`

CI entrypoint:

```bash
make ci
```

Full Docker/native firmware comparison:

```bash
CI_FULL_BUILD=1 scripts/ci.sh
```

## UniFlash Integration

UniFlash flashing is host-side only. Docker builds firmware; the host runs TI
UniFlash/DSLite against a user-selected serial download port.

List ports:

```bash
make flash-list
```

Check integration:

```bash
make flash-doctor
```

Dry-run command generation:

```bash
make flash-dry-run \
  PORT=/dev/ttyACM0 \
  BIN=build/sdk-image-smoke/smoke-iwr6843isk-oob/build/app/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings
```

Actual flashing requires an explicit confirmation flag:

```bash
make flash \
  PORT=/dev/ttyACM0 \
  BIN=build/sdk-image-smoke/smoke-iwr6843isk-oob/build/app/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings \
  CONFIRM_FLASH=YES
```

`PORT` is always required. The scripts never auto-select a serial port.

Verified on `labpc`:

- native Ubuntu clean build: `60.44s`
- Docker clean build: `62.58s`
- Docker CMake+Ninja MSS+DSS benchmark: `62.61s`
- native CMake+Ninja MSS+DSS benchmark: `62.47s`
- Docker/native CMake+Ninja output SHA-256: `4d37093668aa1106fdde282cc6e3eb22b6b823e6d73b93dbff908f8e1fc9d0b6`
- Docker overhead for the real SDK demo: about `3.5%`
- CMake tool-discovery smoke in Docker: about `0.30s`
- CMake tool-discovery smoke native: about `0.01s`

For maximum speed, run directly on Ubuntu. For repeatability, Docker is close
enough and avoids host dependency drift.

# TI mmWave SDK Docker Build Tools

Reproducible Linux build, validation, and flashing helpers for TI mmWave SDK
03.06 MSS+DSS demo firmware.

This repository packages the host glue around an existing TI SDK installation:
Docker for dependency isolation, CMake+Ninja entry points for firmware builds,
device-matrix validation, native-vs-Docker benchmarks, and guarded UniFlash
command generation.

It does not redistribute TI SDKs, compilers, UniFlash, or device firmware owned
by TI. Bring your own TI installation and mount it into the build environment.

## What Works

- Build TI mmWave SDK 03.06 demo firmware on Linux.
- Build `xwr68xx/mmw` MSS+DSS through CMake and Ninja.
- Create forked mmWave CMake/Ninja firmware projects from TI SDK demos.
- Validate first-generation SDK demo families in Docker.
- Track official TI SDK demo references without vendoring TI source files.
- Compare Docker and native Ubuntu build time and output hashes.
- Generate safe UniFlash/DSLite commands with an explicit serial port.
- Keep generated build output under `build/`, `artifacts/`, and `reports/`.

## Current Status

| Area | Status | Evidence |
|---|---:|---|
| Docker SDK environment | Validated | `make doctor`, `make test`, `make ci` |
| CMake+Ninja MSS+DSS build | Validated | Docker/native SHA-256 match |
| First-generation device matrix | Validated | `reports/device-validation-20260515T123503Z.md` |
| UniFlash integration layer | Guarded test passed | `reports/uniflash-integration-20260515T090526Z.md` |
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
make official-demo-manifest
make test
make validate-devices
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

## Support Matrix

Support levels:

- `Validated`: built in this Docker environment and produced firmware artifacts.
- `SDK-listed`: listed by TI SDK makefiles, but not represented by a demo folder
  validated by this repository yet.
- `Different SDK flow`: not covered by this mmWave SDK 03.06.02.00-LTS
  container, but support may exist through another TI SDK/package.

| Device family / demo | SDK device used | Support level | Validation | Firmware artifacts |
|---|---|---:|---|---|
| `xWR16xx` / `IWR1642` / `AWR1642` | `iwr16xx` | Validated | `make validate-devices`, `62.17s` | `xwr16xx_mmw_demo.bin` |
| `xWR18xx` / `IWR1843` / `AWR1843` | `iwr18xx` | Validated | `make validate-devices`, `77.92s` | `xwr18xx_mmw_demo.bin`, `xwr18xx_mmw_aop_demo.bin` |
| `xWR64xx` | `iwr68xx` | Validated | `make validate-devices`, `66.81s` | `xwr64xx_mmw_demo.bin`, `xwr64xxAOP_mmw_demo.bin` |
| `xWR64xx compression` | `iwr68xx` | Validated | `make validate-devices`, `33.26s` | `xwr64xx_compression_mmw_demo.bin` |
| `xWR68xx` / `IWR6843ISK` / `AWR6843` | `iwr68xx` | Validated | `make validate-devices`, `65.02s` | `xwr68xx_mmw_demo.bin` |
| `xWR14xx` / `IWR1443` / `AWR1443` | `iwr14xx` / `awr14xx` | SDK-listed | TI SDK common makefiles list the device family; no `ti/demo/xwr14xx/mmw` demo folder was validated here. | Not produced |
| `AWR2x44P`, `AWR2544`, `AWR294x` | N/A | Different SDK flow | Use TI MMWAVE-MCUPLUS-SDK, not this mmWave SDK 03.06 flow. | Not produced here |
| `AWR1243`, `AWR2243` RF transceiver/MMIC devices | N/A | Different SDK flow | Use TI MMWAVE-DFP / mmWaveLink-style flow, not this MSS/DSS demo build. | Not produced here |
| `xWRLx432`, `AWRL6432`, newer low-power L-SDK devices | N/A | Different SDK flow | Use the matching low-power / newer TI SDK flow. | Not produced here |

Latest device-validation report:

```text
reports/device-validation-20260515T123503Z.md
```

Latest UniFlash integration report:

```text
reports/uniflash-integration-20260515T090526Z.md
```

Latest GitHub Actions smoke report:

```text
reports/github-actions-smoke-20260515T0920Z.md
```

Latest project-template validation report:

```text
reports/project-template-validation-20260515T130010Z.md
```

Latest SDK-full private-image validation report:

```text
reports/sdk-full-image-validation-20260515T140042Z.md
```

Latest generated demo-profile smoke report:

```text
reports/demo-profile-smoke-20260515T160000Z.md
```

Validation here means the Docker SDK environment can compile the TI mmWave SDK
03.06 demo and produce `.bin` artifacts. It does not mean each binary was
flashed to hardware, and it does not imply other TI device generations are
unsupported in their own SDKs.

IWR6843AOP is handled as a separate AOP device/package profile, not as a synonym
for IWR6843ISK. It should be added to the demo profile manifest only when the
corresponding TI source package is present in the SDK-full image.

## Reusable CMake API

The original reusable CMake helper API remains available under `cmake/` for
firmware repositories that want to inherit common TI mmWave build rules through
a submodule, subtree, or `FetchContent`.

Key files:

- `cmake/TiMmwaveSdk.cmake`: reusable build API.
- `cmake/RunConfiguro.cmake`: XDC configuro wrapper.
- `cmake/RunMetaImage.cmake`: ImageCreator wrapper.
- `cmake/TiMmwaveSdkPaths.cmake`: Linux path discovery used by this Docker lab.
- `examples/official-sdk-demos/devices-ci.tsv`: official TI SDK demo matrix for
  CI builds.
- `templates/mmwave-cmake-project`: project scaffold for new CMake/Ninja
  firmware projects.
- `config/demo-profiles.tsv`: common TI SDK demo fork profiles used by
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
make validate-devices
make project-new PROJECT=name PROFILE=iwr6843isk-oob
make sdk-image
make sdk-image-smoke
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
- Device support: `docs/DEVICE_SUPPORT.md`
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
  BIN=artifacts/device-validation/xwr68xx/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings
```

Actual flashing requires an explicit confirmation flag:

```bash
make flash \
  PORT=/dev/ttyACM0 \
  BIN=artifacts/device-validation/xwr68xx/xwr68xx_mmw_demo.bin \
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

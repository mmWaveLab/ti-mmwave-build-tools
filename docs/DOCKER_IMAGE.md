# Docker Image Management

This repository uses one Docker image for firmware builds: `SDK_FULL_IMAGE`.
The default is:

```text
meowpas/ti-mmwave-sdk:03.06.02
```

The image contains the Linux build runtime, CMake, Ninja, helper entry points,
and the SDK/toolchain tree at `/opt/ti`. Repository demos, templates, and
CMake helper modules are intentionally kept outside the image and come from the
current checkout or repository archive.

## Build Or Pull

Pull an existing image:

```bash
docker pull meowpas/ti-mmwave-sdk:03.06.02
```

Build the image from a local TI install:

```bash
make sdk-image HOST_TI_ROOT=/opt/ti SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
make sdk-image-smoke SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
```

Push after `docker login`:

```bash
docker push meowpas/ti-mmwave-sdk:03.06.02
```

## Runtime Contract

| Item | Container path |
|---|---|
| SDK/toolchain root | `/opt/ti` |
| mmWave SDK packages | `/opt/ti/mmwave_sdk_03_06_02_00-LTS/packages` |
| Repository checkout | `/work/ti-mmwave-build-tools-docker` |

Normal Docker builds do not mount a host TI installation. `HOST_TI_ROOT` is
only used by `make sdk-image` while assembling the image build context.

## Common Commands

```bash
make doctor
make project-docker PROJECT=/path/to/generated-project
make docker-cmake
make sdk-profile-validate
make install-profile-validate
```

Open a shell:

```bash
docker run --rm -it \
  -v "$PWD":/work/ti-mmwave-build-tools-docker \
  -w /work/ti-mmwave-build-tools-docker \
  meowpas/ti-mmwave-sdk:03.06.02 \
  bash
```

## Cleanup

Containers are launched with `--rm`, so stopped containers do not remain after
normal builds. Generated files remain under repository-managed folders:

```text
build/
artifacts/
reports/
```

Remove generated build output:

```bash
make clean
```

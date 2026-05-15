# Docker Image Management

The Docker image is the stable SDK host shell. It contains Linux build
dependencies, CMake, Ninja, and helper entry points, but it does not contain TI
SDKs or compilers.

## Image Contract

Default image:

```text
ti-mmwave-build-tools:linux-smoke
```

Runtime mounts:

| Host path | Container path | Mode | Purpose |
|---|---|---|---|
| `HOST_TI_ROOT` | `CONTAINER_TI_ROOT` | read-only | TI SDK, compilers, XDC, BIOS |
| repository root | `/work/ti-mmwave-build-tools-docker` | read-write | build scripts, examples, artifacts |

Default path values:

```text
HOST_TI_ROOT=/home/kj/ti
CONTAINER_TI_ROOT=/home/kj/ti
```

Keeping the container TI path stable avoids surprises from TI generated
makefiles and XDC/configuro outputs that embed absolute paths.

## Common Commands

```bash
make docker-build
make doctor
make project-docker PROJECT=examples/name
make validate-devices
```

Open a shell in the image:

```bash
make docker-shell
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

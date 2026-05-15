# Docker Image Management

The Docker image is the stable SDK host shell. It contains Linux build
dependencies, CMake, Ninja, and helper entry points, but it does not contain TI
SDKs or compilers.

For day-to-day private development, use an SDK-full private image instead. That
image contains the TI SDK and is not meant for public redistribution.

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
HOST_TI_ROOT=/opt/ti
CONTAINER_TI_ROOT=/opt/ti
```

Keeping the container TI path stable avoids surprises from TI generated
makefiles and XDC/configuro outputs that embed absolute paths.

## Common Commands

```bash
make docker-build
make doctor
make project-docker PROJECT=examples/name
make sdk-profile-validate
```

Build the private SDK-full image on a machine that already has TI SDK installed:

```bash
make sdk-image HOST_TI_ROOT=/opt/ti SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
make sdk-image-smoke SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
```

Push it to a private registry after `docker login`:

```bash
docker push meowpas/ti-mmwave-sdk:03.06.02
```

Do not push SDK-full images to a public repository unless your TI license
explicitly permits redistribution.

The SDK-full image keeps TI tools at `/opt/ti` inside the container. This is
intentional: TI make/configuro fragments can embed the install path, so the
container standardizes that path even when the host is macOS, Windows, or a
different Linux distribution.

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

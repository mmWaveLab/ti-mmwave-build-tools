# Docker Image Management

The Docker image is the stable SDK host shell. It contains Linux build
dependencies, CMake, Ninja, and helper entry points, but it does not contain TI
SDKs or compilers.

The public image build context is intentionally slim: generated output,
catalogs, templates, converted demos, and Git metadata are excluded by
`.dockerignore` because the public image only needs the host shell helpers.

For day-to-day private development, use an SDK-full private image instead. That
image contains the TI SDK/toolchain runtime and is not meant for public
redistribution. It must not embed this repository's `demos/` tree; project demo
sources come from the repository archive or local checkout at project creation
time.

## Image Contract

Default image:

```text
ti-mmwave-build-tools:linux-smoke
```

Runtime mounts:

| Host path | Container path | Mode | Purpose |
|---|---|---|---|
| `HOST_TI_ROOT` | `CONTAINER_TI_ROOT` | read-only | TI SDK, compilers, XDC, BIOS |
| repository root | `/work/ti-mmwave-build-tools-docker` | read-write | build scripts, generated projects, artifacts |

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
make project-docker PROJECT=/path/to/generated-project
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
different Linux distribution. The image intentionally does not contain
`/opt/ti-mmwave-build-tools` or `create-mmwave-app`; keeping project templates
and converted demos outside the image prevents stale demo copies after
repository updates.

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

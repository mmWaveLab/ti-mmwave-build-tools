# AI Project Conversion Guide

This project intentionally does not try to be a universal TI Radar Toolbox
importer. The preferred workflow is project-specific AI-assisted conversion:
take one existing TI mmWave project, convert it into the repository's
CMake/Ninja project shape, and verify the result inside the SDK-full Docker
environment.

The goal is practical reproducibility, not broad automatic parsing of every
historical Toolbox layout.

## When To Use This

Use this guide when converting an existing TI project such as:

- a copied SDK `packages/ti/demo/...` project
- a Radar Toolbox / Industrial Toolbox application project
- a CCS project exported with `.projectspec`
- a hand-modified MSS-only or MSS+DSS firmware tree

Do not use this guide to remove the checked-in starter demos. The repository
keeps a small source-only SDK demo subset as stable fork points. AI conversion
is for additional projects that are not already covered by
`config/starter-demo-profiles.tsv`.

## Conversion Contract

A converted project should look like this:

```text
my-mmwave-app/
  CMakeLists.txt
  Makefile
  README.md
  .gitignore
  app/
    makefile or converted build inputs
    mss/
    dss/
    profiles/
    utils/
  src/
  tools/
    mmwave-run
    cmake/
  build/
```

The project must build through:

```bash
cmake -S . -B build -G Ninja -DTI_ROOT=/opt/ti
cmake --build build --target firmware
```

The primary output should be a flashable `.bin` image whenever the device flow
supports one.

## Source Handling Rules

- Preserve TI copyright notices and license headers.
- Keep upstream TI source files in `app/` as the fork point.
- Put new project-owned helper code under `src/` unless the TI make/project
  layout requires a file to live inside `app/`.
- Do not copy TI SDK binaries, compilers, UniFlash, radarss firmware, or
  prebuilt images into this repository.
- Do not bake demo sources into the Docker image. Docker provides the tool
  environment; project sources live in the repository or generated project.
- Do not rename TI chirp/profile `.cfg` files unless the application itself
  requires it. Their upstream names help users compare against TI documents.

## Choosing A Build Strategy

Prefer the smallest strategy that can be verified.

| Existing project shape | Recommended conversion |
|---|---|
| SDK demo with `makefile` | Use the starter template and set `build_entry_kind=make-target`. |
| Fork of an existing starter profile | Generate with `install.py` or `create-mmwave-app.sh`, then edit `app/`. |
| Toolbox project with generated makefiles | Wrap the generated make targets with CMake custom commands. |
| Toolbox/CCS `.projectspec` only | Convert that specific project by extracting MSS/DSS sources, include paths, linker files, and configuro inputs into explicit CMake custom commands. |
| Unknown custom project | First reproduce the original build in Docker, then convert one build step at a time. |

Avoid writing a generic importer before several real projects prove that the
formats are stable enough to justify it.

## MSS-Only And MSS+DSS Rules

For `mss-only` projects:

- Build the R4F image.
- Generate a flashable metaimage with TI `generateMetaImage.sh` when needed.
- Use `NULL` as the DSS image input when the TI flow expects it.

For `mss-dss` projects:

- Build MSS and DSS from the same source snapshot.
- Keep XDC/configuro output inside `build/`.
- Generate the final metaimage only after both core images exist.

If a board has a DSP core, both `mss-only` and `mss-dss` can be valid project
modes. Do not alias one board's demo to another board unless the source and
configuration difference has been reviewed explicitly.

## AI Conversion Checklist

Before editing:

```text
[ ] Identify the exact source project and TI package version.
[ ] Identify device family, board, and core mode.
[ ] Record original build command, output binary name, and config files.
[ ] Check whether a reference prebuilt binary exists.
[ ] Check whether the project has makefiles, generated makefiles, or only .projectspec files.
```

During conversion:

```text
[ ] Preserve upstream source layout under app/.
[ ] Keep generated output under build/.
[ ] Use tools/mmwave-run for standalone projects, or ../../scripts/mmwave-run.sh for in-repo demos.
[ ] Use CMake custom commands for build steps.
[ ] Keep the target name firmware for the primary firmware build.
[ ] Keep the Docker image configurable through IMAGE or SDK_FULL_IMAGE.
```

After conversion:

```text
[ ] Run cmake configure with Ninja inside Docker.
[ ] Run cmake --build build --target firmware inside Docker.
[ ] Verify the expected .bin exists.
[ ] If a reference binary exists, compare SHA-256.
[ ] If SHA-256 cannot match because the project changed, document why.
[ ] Run flash-dry-run before any real UniFlash command.
```

## Verification Commands

For a generated standalone project:

```bash
make build
```

For direct Docker execution:

```bash
tools/mmwave-run --image meowpas/ti-mmwave-sdk:03.06.02 --workdir . -- \
  cmake -S . -B build -G Ninja -DTI_ROOT=/opt/ti

tools/mmwave-run --image meowpas/ti-mmwave-sdk:03.06.02 --workdir . -- \
  cmake --build build --target firmware
```

For output checks:

```bash
test -f build/app/<expected-output>.bin
sha256sum build/app/<expected-output>.bin
```

## What Counts As Done

A conversion is complete only when the result is reproducible from a clean
checkout or generated project directory. A good final handoff should include:

- source project name and origin
- target board and core mode
- Docker image used for validation
- exact build command
- output artifact path
- SHA-256 result when available
- known differences from TI's original project

If those facts are missing, the conversion is still experimental.

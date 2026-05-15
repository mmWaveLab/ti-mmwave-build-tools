# mmWave CMake Project Template

This repository can create CMake/Ninja firmware projects by forking an official
TI mmWave SDK demo from an SDK-full Docker image. The generated project is a
normal source tree that developers can edit directly.

## Create A Project

```bash
make project-new PROJECT=people-count-6843 PROFILE=iwr6843isk-oob
```

Use a custom output directory or overwrite a generated scaffold:

```bash
make project-new PROJECT=vital-signs-1843 PROFILE=iwr1843boost-oob OUT=examples/vital-signs-1843
make project-new PROJECT=vital-signs-1843 PROFILE=iwr1843boost-oob OUT=examples/vital-signs-1843 FORCE=1
```

This creates:

```text
examples/people-count-6843/
  CMakeLists.txt
  Makefile
  README.md
  .gitignore
  app/
    makefile
    mss/
    dss/
  src/README.md
```

List available fork profiles:

```bash
docker run --rm meowkj/ti-mmwave-sdk:03.06.02-local create-mmwave-app --list-profiles
```

Common fork profiles:

| Profile | SDK demo | SDK device/type | Default output |
|---|---|---|---|
| `iwr1843boost-oob` | `ti/demo/xwr18xx/mmw` | `iwr18xx` / `xwr18xx` | `xwr18xx_mmw_demo.bin` |
| `iwr6843isk-oob` | `ti/demo/xwr68xx/mmw` | `iwr68xx` / `xwr68xx` | `xwr68xx_mmw_demo.bin` |

Legacy `DEVICE=xwr68xx` still works, but `PROFILE=...` is preferred because it
captures the expected board/demo variant and output artifact.

## Build A Project

Build with the SDK-full Docker image:

```bash
cd examples/people-count-6843
make build
```

## Validate The Fork

The repository can verify that every fork profile still matches TI's original
OOB demo build. The validation builds both sides:

- direct SDK demo copied from the SDK-full image
- generated fork project built through CMake+Ninja

Then it compares SHA-256 for the expected firmware binary:

```bash
make sdk-profile-validate
```

Use a subset while iterating:

```bash
DEMO_PROFILES="iwr6843isk-oob iwr1843boost-oob" make sdk-profile-validate
```

Use explicit profile-level parallelism on a stronger machine:

```bash
PROFILE_VALIDATION_JOBS=all make sdk-profile-validate
```

The script parallelizes independent profiles, not the internal TI makefile for
a single demo. TI's OOB makefiles use `.NOTPARALLEL`, so the safe acceleration
point is the profile matrix.

## Design Rules

- The generated project copies a TI SDK demo into `app/`.
- The build copies `app/` into the CMake build tree before invoking the
  original TI SDK makefile.
- The SDK-full Docker image provides TI SDK, compilers, CMake, Ninja, and
  helper scripts.
- SHA validation compares the generated fork output with a direct build of the
  original TI SDK demo inside the same SDK-full image.
- Generated build outputs stay under `build/`.

## When To Use This Template

Use it for board bring-up, regression projects, and real firmware development
starting from a known-good TI demo such as IWR1843 or IWR6843 out-of-box.

The SDK 03.06 `ti/demo/xwr68xx/mmw` folder is represented as
`iwr6843isk-oob`. IWR6843AOP should be tracked as a separate profile only after
the Radar Toolbox OOB source package is added to the SDK-full image; do not
treat it as the same fork target as IWR6843ISK.

## Profile Granularity

Profiles should follow TI SDK build boundaries, not marketing-level device names
alone. Add a new profile when the SDK has at least one of these differences:

- a different demo source directory
- a different make target or build option
- a different expected firmware binary
- a different OOB configuration set that maps to a distinct SDK output

For the current starter set:

| Profile | Cores | Source layout |
|---|---|---|
| `iwr6843isk-oob` | MSS+DSS | `app/mss/` and `app/dss/` |
| `iwr1843boost-oob` | MSS+DSS | `app/mss/` and `app/dss/` |

If two board/device names only differ in the profile `.cfg` used at runtime and
the SDK build output is byte-identical, keep them as one build profile and
document the runtime configuration variants separately.

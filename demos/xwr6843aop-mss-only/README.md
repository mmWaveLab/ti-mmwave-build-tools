# xwr6843aop-mss-only

Generated TI mmWave CMake/Ninja firmware project forked from a TI SDK demo.

Profile:

```text
xwr6843aop-mss-only
```

Summary:

```text
xWR6843AOP MSS-only OOB fork from TI SDK xwr64xx demo
```

CMake project:

```text
xwr6843aop_mss_only
```

This project contains a local copy of the TI SDK demo:

```text
app/
```

Original SDK demo path:

```text
ti/demo/xwr64xx/mmw
```

Device template:

```text
xwr68xx / iwr68xx
```

Expected cores:

```text
MSS
```

Build entry:

```text
make-target / all
```

Common profile configs:

```text
profile_3d_aop.cfg
```

Docker image:

```text
meowpas/ti-mmwave-sdk:03.06.02
```

## Build

```bash
make build
```

Open a container shell:

```bash
make shell
```

`make build` and `make shell` use the repository runner at `../../scripts/mmwave-run.sh`.
The runner starts a disposable Docker container with a clean environment, `HOME=/tmp/mmwave-home`,
and `bash --noprofile --norc` for interactive shells. It does not source or
modify host `.bashrc`, `.zshrc`, profile files, or host TI installs.

Clean generated output:

```bash
make clean
```

Output binary:

```text
build/app/xwr64xxAOP_mmw_demo.bin
```

## Source Layout

```text
app/
  makefile
  utils/    # copied TI demo utility sources
  mss/      # present when the forked demo has MSS sources
  dss/      # present when the forked demo has DSS sources
../../cmake/        # shared repository CMake helper modules
../../scripts/      # shared repository Docker runner
```

The build uses the forked demo's original TI makefile and the profile-selected
build entry. For SDK-make starter profiles that entry is a TI make target.
By default it keeps TI's canonical SDK package path to preserve
byte-identical SHA-256 output against the SDK reference build. An experimental
`MMWAVE_USE_SDK_OVERLAY=ON` CMake option can point `ti/demo/...` at this
project's `app/` sources for slim-image experiments. Both `mss-only` and
`mss-dss` profiles expose a flashable metaimage `.bin` as the primary artifact.
For 18xx/68xx MSS-only profiles, the wrapper builds the R4F image first and
then calls TI's `generateMetaImage.sh` with radarss and `NULL` DSS input.

## License Note

This project contains source copied from TI mmWave SDK `packages/ti/demo`,
which TI's SDK 03.06.02 software manifest lists under BSD-3-Clause. Preserve
the upstream copyright and license notices in source files. See this project's
`THIRD_PARTY_NOTICES.md` for the TI notice text.

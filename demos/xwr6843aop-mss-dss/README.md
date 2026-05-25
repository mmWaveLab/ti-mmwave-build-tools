# xwr6843aop-mss-dss

Generated TI mmWave CMake/Ninja firmware project forked from TI Radar Toolbox
3D People Tracking.

Profile:

```text
xwr6843aop-mss-dss
```

Summary:

```text
xWR6843AOP MSS+DSS 3D People Tracking fork from TI Radar Toolbox
```

CMake project:

```text
xwr6843aop_mss_dss
```

This project contains a local copy of the converted demo:

```text
app/
```

Original Radar Toolbox demo path:

```text
source/ti/examples/Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking
```

Device template:

```text
xwr68xx / iwr68xx
```

Expected cores:

```text
MSS+DSS
```

Build entry:

```text
make-target / all
```

Common profile configs:

```text
AOP_6m_default.cfg,AOP_9m_default.cfg
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

`make build` and `make shell` use the repository runner at
`../../scripts/mmwave-run.sh`. The runner starts a disposable Docker container
with a clean environment, `HOME=/tmp/mmwave-home`, and `bash --noprofile --norc`
for interactive shells. It does not source or modify host `.bashrc`, `.zshrc`,
profile files, or host TI installs.

Clean generated output:

```bash
make clean
```

Output binary:

```text
build/app/3D_people_track_6843_demo.bin
```

## Source Layout

```text
app/
  makefile
  common/   # shared MSS utility sources
  mss/      # R4F control, CLI, tracker wrapper, and config
  dss/      # C674x Capon/CFAR/matrix processing and config
  dpc/      # minimal Radar Toolbox DPC headers
  dpu/      # minimal Radar Toolbox DPU headers plus gtrack runtime library
  profiles/ # AOP chirp configs copied from the Toolbox demo
../../cmake/        # shared repository CMake helper modules
../../scripts/      # shared repository Docker runner
```

The build uses this demo's local `app/makefile` and profile-selected `all`
target. `all` builds MSS, builds DSS, and creates the flashable metaimage with
TI's `generateMetaImage.sh`.

## License Note

This project contains source and one vendor runtime library copied from TI
Radar Toolbox 4.00.00.05. Preserve the upstream copyright and limited license
notices in source files. See this project's `THIRD_PARTY_NOTICES.md` for the TI
notice text.

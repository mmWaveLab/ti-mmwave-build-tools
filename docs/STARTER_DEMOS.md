# Starter Demo Contract

This repository exposes one normalized starter surface: three boards, each with
an `mss-only` and an `mss-dss` profile. The profile name is the stable API used
by `install.py`, `create-mmwave-app`, CI, and generated project metadata.

## Profiles

| Board | Core mode | Profile | Source | Output |
|---|---|---|---|---|
| xWR1843BOOST | MSS only | `xwr1843boost-mss-only` | SDK `ti/demo/xwr18xx/mmw` | `xwr18xx_mmw_demo.bin` |
| xWR1843BOOST | MSS+DSS | `xwr1843boost-mss-dss` | SDK `ti/demo/xwr18xx/mmw` | `xwr18xx_mmw_demo.bin` |
| xWR6843ISK | MSS only | `xwr6843isk-mss-only` | SDK `ti/demo/xwr68xx/mmw` | `xwr68xx_mmw_demo.bin` |
| xWR6843ISK | MSS+DSS | `xwr6843isk-mss-dss` | SDK `ti/demo/xwr68xx/mmw` | `xwr68xx_mmw_demo.bin` |
| xWR6843AOP | MSS only | `xwr6843aop-mss-only` | SDK `ti/demo/xwr64xx/mmw` | `xwr64xxAOP_mmw_demo.bin` |
| xWR6843AOP | MSS+DSS | `xwr6843aop-mss-dss` | Radar Toolbox projectspec pair | `3D_people_track_6843_demo.bin` |

`xwr6843aop-mss-dss` is part of the public matrix but remains `cataloged`
until the Toolbox projectspec importer is implemented. The tools must reject
generation for this profile instead of silently aliasing it to ISK or AOP
MSS-only.

## Canonical Storage

- `config/demo-profiles.tsv` is the canonical in-repo profile manifest.
- `docs/install.py` is the public GitHub Pages installer and duplicates only the
  six starter profiles needed for no-clone project creation.
- `scripts/create-mmwave-app.sh` is the repo-local development entrypoint and
  reads `config/demo-profiles.tsv` directly.
- `scripts/validate-starter-demos.py` checks that `docs/install.py` and
  `config/demo-profiles.tsv` remain synchronized.

The repository does not store generated starter projects, TI SDK source copies,
Toolbox source trees, or firmware build outputs. Generated projects live in the
user's chosen destination directory.

## Unified Entrypoints

For new users, the primary entrypoint is the GitHub Pages installer:

```bash
python3 <(curl -fsSL https://mmwavelab.github.io/ti-mmwave-build-tools/install.py) \
  --name people-count-6843 \
  --cmake-name people_count_6843 \
  --profile xwr6843isk-mss-dss \
  --image meowpas/ti-mmwave-sdk:03.06.02 \
  --build
```

For repository development, use the local entrypoint:

```bash
scripts/create-mmwave-app.sh people-count-6843 --profile xwr6843isk-mss-dss
```

Both entrypoints create the same project shape and use the same profile names.

## Generated Project Layout

```text
my-project/
  CMakeLists.txt       # stable CMake/Ninja firmware wrapper
  Makefile             # pull/configure/build/shell/clean convenience targets
  README.md            # project-local profile and build notes
  .gitignore           # excludes generated build artifacts
  app/                 # copied TI SDK demo source; this is the fork point
    makefile
    mss/
    dss/               # present only when the selected source has DSS files
    profiles/
  src/                 # user-owned project-local source and notes
    README.md
  tools/
    mmwave-run         # clean Docker runner, no host shell profile pollution
  build/               # generated CMake and TI build output, ignored by git
```

The CMake project name is controlled by `--cmake-name`. If omitted, the
installer converts `--name` into a valid CMake identifier by replacing invalid
characters with underscores.

## Validation Policy

CI checks the six-profile matrix at the manifest level. Private SDK validation
builds the SDK-backed profiles in Docker:

- MSS-only and MSS+DSS profiles must produce byte-identical direct and
  generated `.bin` outputs when the TI SDK makefile path is available.
- Cataloged Toolbox projectspec profiles are listed but skipped until the
  importer exists.

# Vendored TI mmWave SDK OOB Demos

This directory contains the source-only starter demo fork points used by
`install.py` and `create-mmwave-app`.

Included paths mirror TI mmWave SDK 03.06.02.00-LTS package paths:

- `ti/demo/xwr18xx/mmw`
- `ti/demo/xwr68xx/mmw`
- `ti/demo/xwr64xx/mmw`
- `ti/demo/utils`

The vendored copy intentionally excludes generated build outputs and binary
images such as `.bin`, `.xer4f`, `.xe674`, `.map`, `obj_*`, and
`mmw_configPkg_*`. Generated projects copy `ti/demo/utils` into `app/utils`.
The default build keeps TI's canonical SDK package path to preserve
byte-identical SHA-256 output against the SDK reference build. An optional
CMake overlay mode can point `ti/demo/...` at project-local sources for future
slim-image experiments. The SDK-full Docker image still supplies the compiler,
libraries, scripts, and radarss firmware needed to build flashable metaimages.

TI's SDK software manifest for 03.06.02.00-LTS lists `packages/ti/demo` under
BSD-3-Clause. Keep upstream notices in source files intact when updating this
directory. The repository-level `THIRD_PARTY_NOTICES.md` records the upstream
source, version, and license text.

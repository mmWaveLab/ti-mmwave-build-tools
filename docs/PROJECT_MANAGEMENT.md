# Project Management

This repository is managed as a small SDK-environment product, not just a script
collection. Changes should keep three promises true:

- Public CI works without proprietary TI downloads.
- Full firmware validation works on a prepared TI SDK host.
- New firmware projects can be created from a stable CMake/Ninja template.

## Current Product Layers

| Layer | Purpose | Public CI | Self-hosted CI |
|---|---|---:|---:|
| Docker image | Host dependency shell with CMake, Ninja, and helpers | Build and entrypoint smoke | Full SDK build |
| Project template | Generate new mmWave CMake projects | Template generation smoke | Generated project firmware build |
| Official demo manifest | Track reasonable TI SDK demo build targets | Syntax and policy check | Path and makefile existence check |
| Device validation | Build all configured first-generation SDK demos | Not possible without TI SDK | Full validation and artifact upload |
| UniFlash wrapper | Guarded host-side flash command generation | Script smoke | Hardware flashing when serial is attached |

## Release Gates

Before tagging or merging to `main`, run:

```bash
make github-actions-smoke
make docker-build
make doctor
make project-new PROJECT=release-smoke DEVICE=xwr68xx OUT=build/release-smoke FORCE=1
make project-docker PROJECT=build/release-smoke
make validate-devices
```

For changes that touch flashing:

```bash
make flash-list
make flash-doctor PORT=/dev/ttyUSB0 BIN=artifacts/xwr68xx_mmw_demo.docker.bin
make flash-dry-run PORT=/dev/ttyUSB0 BIN=artifacts/xwr68xx_mmw_demo.docker.bin
```

## Docker Image Policy

- Keep the default tag `ti-mmwave-build-tools:linux-smoke` for local workflows.
- Do not bake TI SDKs, TI compilers, UniFlash, or generated firmware into the
  image.
- Keep `HOST_TI_ROOT` mounted read-only.
- Keep generated build outputs under `build/`, `artifacts/`, and `reports/`.
- Add image tags only when the base OS or SDK support contract changes.

## CI Roadmap

| Stage | Trigger | Runner | Status |
|---|---|---|---:|
| Public smoke | push, pull request | GitHub-hosted Ubuntu | Active |
| Docker image smoke | push, pull request | GitHub-hosted Ubuntu | Active |
| Device validation | manual dispatch | self-hosted `ti-mmwave` | Active design |
| Full firmware gate | main push or nightly | self-hosted `ti-mmwave` | Next |
| Flash hardware gate | manual dispatch only | lab bench host | Future |

The next operational step is to register the Ubuntu lab PC as a GitHub
self-hosted runner with labels:

```text
self-hosted
ti-mmwave
```

After that, device validation can move from manual dispatch to a scheduled or
branch-gated workflow.

## Maintenance Rhythm

- When adding a device family, update `config/devices.tsv`,
  `examples/official-sdk-demos/devices-ci.tsv`, `docs/DEVICE_SUPPORT.md`, and
  README support tables together.
- When changing Docker behavior, update `docs/DOCKER_IMAGE.md` and run
  `make docker-build`.
- When changing project scaffolding, update `templates/mmwave-cmake-project`,
  `scripts/new-project.sh`, and `docs/PROJECT_TEMPLATE.md`.
- Keep reports timestamped and keep Markdown reports in git only when they are
  useful evidence for support claims.

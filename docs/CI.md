# CI

GitHub Actions has three tiers.

## Public Smoke

The public smoke tier runs on `ubuntu-latest` and does not require TI SDK files:

```bash
make github-actions-smoke
```

It performs:

- shell syntax checks for scripts
- workflow YAML structure checks
- root CMake configure without a TI SDK
- public documentation and config path checks
- official TI SDK demo manifest checks without vendoring TI files

The public workflow also builds the Docker image and verifies that the container
contains the expected command-line tools.

Public jobs run on every push and pull request. They use workflow concurrency
per branch so a newer push cancels older in-progress runs, and each public job
has a timeout to avoid hanging on a transient Docker or runner issue.

## Self-Hosted Device Validation

The device-validation tier runs only on a self-hosted runner with TI SDK access:

```bash
make docker-build
make official-demo-manifest
make validate-devices
```

It builds every configured device row in `config/devices.tsv` and uploads:

- `reports/device-validation-*.md`
- `reports/device-validation-*.log`
- `artifacts/device-validation/**/*.bin`

The demo source mapping is documented in
`examples/official-sdk-demos/devices-ci.tsv`. That file points to TI SDK demo
folders on the runner; it does not vendor TI-owned source code.

Current configured device rows:

- `xwr16xx`
- `xwr18xx`
- `xwr64xx`
- `xwr64xx_compression`
- `xwr68xx`

## Self-Hosted Full SDK CI

The full SDK entrypoint is:

```bash
scripts/ci.sh
```

Default mode performs:

- shell syntax checks for scripts
- root CMake configure
- CTest configure-only check
- Docker toolchain smoke test
- CMake/Ninja configure check

Full build mode:

```bash
CI_FULL_BUILD=1 scripts/ci.sh
```

Full mode runs `scripts/benchmark.sh`, which builds both Docker and native
MSS+DSS firmware and verifies identical SHA-256 output.

Full SDK runner requirements:

- Docker
- CMake 3.20+
- Ninja
- GNU make
- TI SDK/toolchain installed on the runner
- `config/machine.env` or exported `HOST_TI_ROOT`

The self-hosted jobs are guarded behind `workflow_dispatch` and the
`self-hosted, ti-mmwave` runner labels because public GitHub-hosted runners
cannot legally or practically contain the TI SDK/toolchain.

If a permanently available licensed self-hosted runner is attached to the
repository, `self-hosted-device-validation` can be moved from manual dispatch to
push-based gating. Until then, push-based CI validates the official demo matrix
syntax and Docker environment, while lab/self-hosted runs perform the real
firmware builds.

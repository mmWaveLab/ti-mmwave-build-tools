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
- starter demo profile manifest checks without vendoring TI files

The public workflow also builds the Docker image and verifies that the container
contains the expected command-line tools.

Public jobs run on every push and pull request. They use workflow concurrency
per branch so a newer push cancels older in-progress runs, and each public job
has a timeout to avoid hanging on a transient Docker or runner issue.

## Robustness Loop

The local robustness loop repeats the public validation surface and then scores
the result by area:

```bash
ROBUSTNESS_ROUNDS=100 ROBUSTNESS_MIN_SCORE=90 ROBUSTNESS_MIN_AREA_GRADE=9 make robustness-loop
```

The loop currently scores repeat reliability, starter profile contract,
portability, Docker consistency, CI readiness, and maintainability. A run only
passes when the total score reaches the configured floor and every area reaches
the area floor. The score parser reads the loop summary plus every per-round
log, and the default formal threshold requires at least 10 scored rounds.

## Private SDK-full Image Smoke

The private-image tier runs on `ubuntu-latest` only when repository variable
`SDK_FULL_IMAGE` is configured. It pulls the private SDK-full Docker image,
forks demo projects from the SDK inside the image, and builds them with
CMake+Ninja, then compares direct SDK output with generated fork output by
SHA-256:

```bash
make sdk-profile-validate SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
```

Configure GitHub with:

```text
Repository variable:
  SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02

Repository secrets:
  DOCKERHUB_USERNAME
  DOCKERHUB_TOKEN
```

The private-image job is skipped for `pull_request` events so forked PRs do not
receive private Docker credentials.

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

Private SDK profile validation uses `scripts/validate-demo-profiles.sh`.
MSS-only and MSS+DSS profiles compare direct SDK and generated CMake fork
flashable `.bin` SHA-256 values. Cataloged Toolbox projectspec profiles are
listed but skipped until the projectspec importer is implemented.

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

Until a permanently available licensed self-hosted runner is attached, public
CI validates repository structure and Docker tooling, while the private
SDK-full image job validates real starter firmware forks when credentials are
available.

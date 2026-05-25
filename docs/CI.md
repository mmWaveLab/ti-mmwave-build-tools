# CI

GitHub Actions has two tiers.

## Repository Smoke

The repository smoke tier runs on `ubuntu-latest` and does not require the
SDK-full image:

```bash
make github-actions-smoke
```

It performs:

- shell syntax checks for scripts
- workflow YAML structure checks
- root CMake configure without a TI SDK
- public documentation and config path checks
- starter demo profile manifest and vendored SDK OOB source checks

Smoke jobs run on every push and pull request. They use workflow concurrency
per branch so a newer push cancels older in-progress runs, and each public job
has a timeout to avoid hanging on a transient Docker or runner issue.

## Every-Push SDK SHA-256 Gate

The full-image tier runs on every `push` and `workflow_dispatch` event. It
pulls `SDK_FULL_IMAGE`, builds the `SDK_CI_PROFILES` starter set twice, and
compares the two flashable `.bin` SHA-256 values:

- direct TI SDK makefile build
- generated fork project built through CMake+Ninja

The job is named `sdk-full-sha256`. It does not silently skip when Docker Hub
credentials are missing; missing credentials fail the run so every commit has a
visible SDK validation result. `pull_request` events are skipped because GitHub
does not expose Docker credentials to forked PRs.

```bash
make sdk-profile-validate SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
make install-profile-validate SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
```

The install validation simulates a no-clone new computer flow with
`docs/install.py`: validated SDK-backed and Toolbox-backed make profiles must
generate a standalone project, build through Docker+CMake+Ninja, and expose the
expected flashable binary. Cataloged Toolbox projectspec profiles must fail with
the explicit Toolbox importer message until that importer exists.

Configure GitHub with:

```text
Repository secrets:
  DOCKERHUB_USERNAME
  DOCKERHUB_TOKEN

Optional repository variable:
  SDK_FULL_IMAGE=meowpas/ti-mmwave-sdk:03.06.02
```

If `SDK_FULL_IMAGE` is not set, the workflow defaults to
`meowpas/ti-mmwave-sdk:03.06.02`. The job uploads the Markdown validation
reports and direct/fork/install logs as the
`demo-profile-sha256-validation` artifact.

`SDK_CI_PROFILES` in the workflow lists the starter profiles enabled in hosted
CI. Keep profiles out of that list until their vendored source tree builds
cleanly inside the SDK-full image.

## Local Full SDK CI

The full SDK entrypoint is:

```bash
scripts/ci.sh
```

Default mode performs:

- shell syntax checks for scripts
- root CMake configure
- CTest configure-only check
- SDK-full image smoke test
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
`scripts/validate-install-profiles.sh` separately checks the public installer
path from a clean work directory.

Full SDK runner requirements:

- Docker
- CMake 3.20+
- Ninja
- GNU make
- `SDK_FULL_IMAGE` available locally or pullable
- TI SDK/toolchain installed only when building the image with `make sdk-image`

The workflow keeps real firmware validation in the single SDK-full image job.
Repository smoke remains image-free and checks scripts, manifests, and docs.

# GitHub Actions Smoke Test

- Timestamp UTC: `20260515T0920Z`
- Local path: `/Volumes/DATA/Test/ti-mmwave-build-tools-docker`
- Lab PC path: `/opt/ti-mmwave-build-tools-docker`

## Workflow Changes

| Job | Runner | Purpose |
|---|---|---|
| `public-smoke` | `ubuntu-latest` | Run repository checks that do not require TI SDK files. |
| `docker-image` | `ubuntu-latest` | Build the Docker image and verify expected container commands. |
| `self-hosted-full` | `self-hosted`, `ti-mmwave` | Manually run full SDK CI on a licensed/provisioned machine. |

## Test Results

| Check | Environment | Result |
|---|---|---:|
| `scripts/github-actions-smoke.sh` | macOS local checkout | PASS |
| workflow YAML parse | macOS local checkout | PASS |
| `scripts/github-actions-smoke.sh` | lab PC Ubuntu | PASS |
| `docker build -t ti-mmwave-build-tools:ci .` | lab PC Ubuntu | PASS |
| container command probe | lab PC Ubuntu | PASS |
| self-hosted `make docker-build` | lab PC Ubuntu | PASS |
| self-hosted `make validate-devices` | lab PC Ubuntu | PASS |

## Notes

- The local directory is not a Git repository, and `gh` is not installed in the
  current macOS environment, so the workflow was tested through local-equivalent
  commands rather than a remote GitHub run.
- Public GitHub-hosted runners are intentionally limited to SDK-free checks.
- Full firmware builds stay on the self-hosted `ti-mmwave` runner profile.
- Latest full device validation report:
  `reports/device-validation-20260515T104422Z.md`.

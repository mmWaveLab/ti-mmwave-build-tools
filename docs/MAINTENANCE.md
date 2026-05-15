# Maintenance

Stable commands:

```bash
make doctor
make github-actions-smoke
make official-demo-manifest
make test
make docker-cmake
make native-cmake
make benchmark
make validate-devices
make flash-list
make flash-doctor
make package
make clean
```

Generated directories:

- `build/`: CMake/Ninja build trees
- `artifacts/`: copied firmware outputs
- `reports/`: benchmark reports
- `packages/`: distributable artifact bundles

The SDK mount is read-only for Docker builds. Build outputs should never appear
under the TI SDK root.

When changing Docker dependencies:

1. Update `Dockerfile`.
2. Run `make docker-build`.
3. Run `make doctor`.
4. Run `make benchmark`.
5. Confirm Docker/native SHA-256 values match.

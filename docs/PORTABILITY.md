# Portability

This repository keeps the container-internal TI path stable at `/opt/ti`
because TI XDC/configuro and generated make fragments embed absolute paths.

On a new Linux machine:

```bash
cp config/machine.env.example config/machine.env
```

Edit `config/machine.env`:

```bash
HOST_TI_ROOT=/path/to/ti
CONTAINER_TI_ROOT=/opt/ti
TI_ROOT=/path/to/ti
```

For Docker builds, `HOST_TI_ROOT` can be anywhere. The scripts mount it to
`CONTAINER_TI_ROOT` read-only.

For native builds, `TI_ROOT` must point to the real local TI installation.

Run:

```bash
make docker-build
make doctor
make test
```

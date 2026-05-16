#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  mmwave-run [--image IMAGE] [--workdir DIR] [--pull] -- COMMAND [ARG...]
  mmwave-run [--image IMAGE] [--workdir DIR] --shell

Run TI mmWave build commands inside an SDK Docker image without sourcing or
modifying the host shell environment.
USAGE
}

image="${SDK_FULL_IMAGE:-${IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}}"
workdir="$PWD"
pull=0
shell_mode=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      image="${2:-}"
      shift 2
      ;;
    --workdir|-w)
      workdir="${2:-}"
      shift 2
      ;;
    --pull)
      pull=1
      shift
      ;;
    --shell)
      shell_mode=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$image" ]]; then
  printf 'IMAGE is required.\n' >&2
  exit 2
fi

if [[ "$workdir" != /* ]]; then
  workdir="$PWD/$workdir"
fi

if [[ ! -d "$workdir" ]]; then
  printf 'Workdir does not exist: %s\n' "$workdir" >&2
  exit 2
fi

if [[ ! -w "$workdir" ]]; then
  printf 'Workdir is not writable by the current user: %s\n' "$workdir" >&2
  printf 'If it was created with raw Docker, recreate it with --user "$(id -u):$(id -g)".\n' >&2
  exit 2
fi

if (( pull )); then
  docker pull "$image"
fi

docker_args=(--rm
  --user "$(id -u):$(id -g)"
  -e HOME=/tmp/mmwave-home
  -e USER=mmwave
  -e LOGNAME=mmwave
  -e TI_ROOT=/opt/ti
  -v "$workdir":/work/app
  -w /work/app)

clean_env=(env -i
  HOME=/tmp/mmwave-home
  USER=mmwave
  LOGNAME=mmwave
  PATH=/opt/ti/ti-cgt-arm_16.9.6.LTS/bin:/opt/ti/ti-cgt-c6000_8.3.3/bin:/opt/ti/xdctools_3_50_08_24_core:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  TI_ROOT=/opt/ti)

if (( shell_mode )); then
  docker run -it "${docker_args[@]}" "$image" \
    "${clean_env[@]}" bash --noprofile --norc
  exit 0
fi

if [[ $# -eq 0 ]]; then
  printf 'COMMAND is required unless --shell is used.\n\n' >&2
  usage >&2
  exit 2
fi

docker run "${docker_args[@]}" "$image" "${clean_env[@]}" "$@"

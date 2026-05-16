#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib.sh
source "$repo_dir/scripts/lib.sh"

load_machine_env
require_docker

docker build -t "$IMAGE" "$repo_dir"

#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Buildroot rejects WSL PATH values that include Windows paths with spaces.
# Use a minimal Linux-only PATH for deterministic builds.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

git submodule sync --recursive
git submodule update --init --recursive

make XLEN=64 BOARD=atk_ku040 "$@"

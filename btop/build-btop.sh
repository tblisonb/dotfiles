#!/usr/bin/env bash
#
# build-btop.sh - build btop from source and install it to ~/.local (no root).
#
# Why: Debian 13/trixie ships btop 1.3.2, which has no switch to turn off
# AMD PCIe throughput sampling. On older AMD cards (e.g. RX 570/Polaris) every
# read of /sys/class/drm/card*/device/pcie_bw blocks for a full second, so
# with the GPU box enabled the whole UI (menus included) drops to ~1 update/s
# regardless of update_ms. btop >= 1.4.0 adds `rsmi_measure_pcie_speeds`,
# which btop.conf in this repo sets to False.
#
# Usage:
#   ./build-btop.sh            # build/update to the latest release tag
#   ./build-btop.sh v1.4.8     # build a specific tag
#
# Source lives in $BTOP_SRC (default ~/Applications/btop); re-running fetches
# new tags and rebuilds. Needs git, make and g++ >= 11 (no cmake needed).
# ~/.local/bin must come before /usr/bin on PATH (the bash config does this).
#
# AMD GPU stats also need the ROCm SMI runtime library, loaded at runtime:
#   sudo apt install librocm-smi64-1      # Debian/Ubuntu
# NVIDIA needs the driver's libnvidia-ml; Intel works without extras.

set -euo pipefail

SRC="${BTOP_SRC:-$HOME/Applications/btop}"
REPO_URL="https://github.com/aristocratos/btop.git"

if [ ! -d "$SRC/.git" ]; then
    git clone "$REPO_URL" "$SRC"
fi
cd "$SRC"
git fetch --tags --quiet origin

TAG="${1:-$(git tag --list 'v*' --sort=-v:refname | head -n1)}"
echo "==> building btop $TAG in $SRC"
git -c advice.detachedHead=false checkout --quiet "$TAG"

make clean >/dev/null
make -j"$(( $(nproc) > 12 ? 12 : $(nproc) ))" GPU_SUPPORT=true
make install PREFIX="$HOME/.local"

hash -r
echo "==> $(command -v btop): $("$HOME/.local/bin/btop" --version | head -n1)"

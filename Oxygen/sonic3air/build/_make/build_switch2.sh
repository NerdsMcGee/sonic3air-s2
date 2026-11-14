#!/bin/sh
# Build Sonic 3 AIR for Nintendo Switch 2 (devkitPro + libounce).
#
# Usage: ./build_switch2.sh [extra make args]      e.g.  ./build_switch2.sh clean
# Needs the devkitPro Switch toolchain plus the Switch 2 SDK (libounce, OunceVK).
# Output: bin/Switch/sonic3air.nro
set -e
export DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
export DEVKITA64="${DEVKITA64:-$DEVKITPRO/devkitA64}"
export PATH="$DEVKITPRO/tools/bin:$DEVKITA64/bin:$PATH"
cd "$(dirname "$0")"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)"
exec make PLATFORM=Switch -j"$JOBS" "$@"

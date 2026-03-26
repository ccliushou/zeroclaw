#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FEATURES="${FEATURES:-}"
PROFILE="${PROFILE:-release}"
OUTDIR="${OUTDIR:-dist}"
mkdir -p "$OUTDIR"
rustup target add aarch64-unknown-linux-gnu >/dev/null 2>&1 || true
rustup target add x86_64-unknown-linux-gnu >/dev/null 2>&1 || true
if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
  echo "ERROR: aarch64-linux-gnu-gcc not found. On Debian/Ubuntu: sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross"
  exit 1
fi
if [ -n "$FEATURES" ]; then
  CARGO_FEATURE_ARGS=(--features "$FEATURES")
else
  CARGO_FEATURE_ARGS=()
fi
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc \
CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++ \
cargo build --target aarch64-unknown-linux-gnu --profile "$PROFILE" "${CARGO_FEATURE_ARGS[@]}"
cargo build --target x86_64-unknown-linux-gnu --profile "$PROFILE" "${CARGO_FEATURE_ARGS[@]}"
BIN_A="target/aarch64-unknown-linux-gnu/${PROFILE}/zeroclaw"
BIN_X="target/x86_64-unknown-linux-gnu/${PROFILE}/zeroclaw"
OUT_A="${OUTDIR}/zeroclaw-aarch64-unknown-linux-gnu.tar.gz"
OUT_X="${OUTDIR}/zeroclaw-x86_64-unknown-linux-gnu.tar.gz"
tar -C "target/aarch64-unknown-linux-gnu/${PROFILE}" -czf "$OUT_A" zeroclaw
tar -C "target/x86_64-unknown-linux-gnu/${PROFILE}" -czf "$OUT_X" zeroclaw
sha256sum "$OUT_A" > "${OUT_A}.sha256"
sha256sum "$OUT_X" > "${OUT_X}.sha256"
echo "Artifacts:"
echo "  $OUT_A"
echo "  ${OUT_A}.sha256"
echo "  $OUT_X"
echo "  ${OUT_X}.sha256"

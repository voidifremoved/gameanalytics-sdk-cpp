#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build/macos"
OUTPUT_DIR="${SCRIPT_DIR}/output/macos"
CONFIG="${1:-Release}"

echo "=== Building GameAnalytics static library for macOS (${CONFIG}) ==="
echo "  Architectures: x86_64, arm64 (universal binary)"

mkdir -p "${BUILD_DIR}"

cmake -B "${BUILD_DIR}" -S "${SCRIPT_DIR}" \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="${CONFIG}" \
    -DPLATFORM=osx \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DGA_BUILD_SAMPLE=OFF \
    -DGA_BUILD_TESTS=OFF

cmake --build "${BUILD_DIR}" --config "${CONFIG}" -j "$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

mkdir -p "${OUTPUT_DIR}/lib"
mkdir -p "${OUTPUT_DIR}/include"

find "${BUILD_DIR}" -name "libGameAnalytics.a" -exec cp {} "${OUTPUT_DIR}/lib/" \;
cp -R "${SCRIPT_DIR}/include/GameAnalytics" "${OUTPUT_DIR}/include/"

echo ""
echo "=== macOS build complete ==="
echo "  Static library: ${OUTPUT_DIR}/lib/libGameAnalytics.a"
echo "  Headers:        ${OUTPUT_DIR}/include/GameAnalytics/"

if command -v lipo &>/dev/null; then
    echo ""
    echo "  Architecture info:"
    lipo -info "${OUTPUT_DIR}/lib/libGameAnalytics.a" 2>/dev/null || true
fi

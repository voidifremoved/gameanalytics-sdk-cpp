#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${1:-Release}"
ANDROID_MIN_SDK="${ANDROID_MIN_SDK:-24}"

# --- Locate the Android NDK ---
if [ -z "${ANDROID_NDK:-}" ]; then
    if [ -z "${ANDROID_NDK_HOME:-}" ]; then
        if [ -z "${ANDROID_HOME:-}" ]; then
            echo "Error: ANDROID_NDK, ANDROID_NDK_HOME, or ANDROID_HOME must be set."
            echo ""
            echo "Examples:"
            echo "  export ANDROID_NDK=\$HOME/Library/Android/sdk/ndk/<version>"
            echo "  export ANDROID_NDK_HOME=\$HOME/Library/Android/sdk/ndk/<version>"
            echo "  export ANDROID_HOME=\$HOME/Library/Android/sdk  (uses latest NDK)"
            exit 1
        fi
        # Find the latest NDK in ANDROID_HOME
        NDK_DIR=$(find "${ANDROID_HOME}/ndk" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -V | tail -1)
        if [ -z "${NDK_DIR}" ]; then
            echo "Error: No NDK found in ${ANDROID_HOME}/ndk/"
            exit 1
        fi
        ANDROID_NDK="${NDK_DIR}"
    else
        ANDROID_NDK="${ANDROID_NDK_HOME}"
    fi
fi

TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake"

if [ ! -f "${TOOLCHAIN_FILE}" ]; then
    echo "Error: NDK toolchain file not found at ${TOOLCHAIN_FILE}"
    echo "Please verify your ANDROID_NDK path: ${ANDROID_NDK}"
    exit 1
fi

echo "=== Building GameAnalytics static library for Android (${CONFIG}) ==="
echo "  NDK:             ${ANDROID_NDK}"
echo "  Min SDK:         ${ANDROID_MIN_SDK}"

ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")
OUTPUT_DIR="${SCRIPT_DIR}/output/android"

for ABI in "${ABIS[@]}"; do
    echo ""
    echo "--- Building for ${ABI} ---"

    BUILD_DIR="${SCRIPT_DIR}/build/android-${ABI}"
    mkdir -p "${BUILD_DIR}"

    cmake -B "${BUILD_DIR}" -S "${SCRIPT_DIR}" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}" \
        -DANDROID_ABI="${ABI}" \
        -DANDROID_NATIVE_API_LEVEL="${ANDROID_MIN_SDK}" \
        -DANDROID_STL=c++_static \
        -DCMAKE_BUILD_TYPE="${CONFIG}" \
        -DPLATFORM=android \
        -DGA_BUILD_SAMPLE=OFF \
        -DGA_BUILD_TESTS=OFF

    cmake --build "${BUILD_DIR}" --config "${CONFIG}" -j "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

    ABI_OUTPUT="${OUTPUT_DIR}/${ABI}/lib"
    mkdir -p "${ABI_OUTPUT}"

    find "${BUILD_DIR}" -name "libGameAnalytics.a" -exec cp {} "${ABI_OUTPUT}/" \;

    echo "  Built: ${ABI_OUTPUT}/libGameAnalytics.a"
done

# Copy headers
mkdir -p "${OUTPUT_DIR}/include"
cp -R "${SCRIPT_DIR}/include/GameAnalytics" "${OUTPUT_DIR}/include/"

echo ""
echo "=== Android build complete ==="
echo "  Output directory: ${OUTPUT_DIR}"
echo ""
echo "  Libraries:"
for ABI in "${ABIS[@]}"; do
    echo "    ${ABI}: ${OUTPUT_DIR}/${ABI}/lib/libGameAnalytics.a"
done
echo "  Headers: ${OUTPUT_DIR}/include/GameAnalytics/"

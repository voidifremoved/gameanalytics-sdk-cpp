#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${1:-Release}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"

BUILD_DIR_DEVICE="${SCRIPT_DIR}/build/ios-device"
BUILD_DIR_SIMULATOR="${SCRIPT_DIR}/build/ios-simulator"
OUTPUT_DIR="${SCRIPT_DIR}/output/ios"

echo "=== Building GameAnalytics static library for iOS (${CONFIG}) ==="
echo "  Deployment target: iOS ${IOS_DEPLOYMENT_TARGET}"

# --- Build for iOS device (arm64) ---
echo ""
echo "--- Building for iOS device (arm64) ---"

mkdir -p "${BUILD_DIR_DEVICE}"

cmake -B "${BUILD_DIR_DEVICE}" -S "${SCRIPT_DIR}" \
    -G "Xcode" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET}" \
    -DPLATFORM=ios \
    -DGA_BUILD_SAMPLE=OFF \
    -DGA_BUILD_TESTS=OFF

cmake --build "${BUILD_DIR_DEVICE}" --config "${CONFIG}" -- -quiet

# --- Build for iOS simulator (arm64 + x86_64) ---
echo ""
echo "--- Building for iOS simulator (arm64, x86_64) ---"

mkdir -p "${BUILD_DIR_SIMULATOR}"

cmake -B "${BUILD_DIR_SIMULATOR}" -S "${SCRIPT_DIR}" \
    -G "Xcode" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET}" \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DPLATFORM=ios \
    -DGA_BUILD_SAMPLE=OFF \
    -DGA_BUILD_TESTS=OFF

cmake --build "${BUILD_DIR_SIMULATOR}" --config "${CONFIG}" -- -quiet

# --- Locate built libraries ---
DEVICE_LIB=$(find "${BUILD_DIR_DEVICE}" -name "libGameAnalytics.a" -path "*${CONFIG}*" | head -1)
SIMULATOR_LIB=$(find "${BUILD_DIR_SIMULATOR}" -name "libGameAnalytics.a" -path "*${CONFIG}*" | head -1)

if [ -z "${DEVICE_LIB}" ]; then
    DEVICE_LIB=$(find "${BUILD_DIR_DEVICE}" -name "libGameAnalytics.a" | head -1)
fi

if [ -z "${SIMULATOR_LIB}" ]; then
    SIMULATOR_LIB=$(find "${BUILD_DIR_SIMULATOR}" -name "libGameAnalytics.a" | head -1)
fi

# --- Create XCFramework ---
echo ""
echo "--- Creating XCFramework ---"

mkdir -p "${OUTPUT_DIR}"
rm -rf "${OUTPUT_DIR}/GameAnalytics.xcframework"

xcodebuild -create-xcframework \
    -library "${DEVICE_LIB}" \
    -headers "${SCRIPT_DIR}/include" \
    -library "${SIMULATOR_LIB}" \
    -headers "${SCRIPT_DIR}/include" \
    -output "${OUTPUT_DIR}/GameAnalytics.xcframework"

# Also copy the individual static libraries for non-Xcode consumers
mkdir -p "${OUTPUT_DIR}/device/lib"
mkdir -p "${OUTPUT_DIR}/simulator/lib"
mkdir -p "${OUTPUT_DIR}/include"

cp "${DEVICE_LIB}" "${OUTPUT_DIR}/device/lib/"
cp "${SIMULATOR_LIB}" "${OUTPUT_DIR}/simulator/lib/"
cp -R "${SCRIPT_DIR}/include/GameAnalytics" "${OUTPUT_DIR}/include/"

echo ""
echo "=== iOS build complete ==="
echo "  XCFramework:       ${OUTPUT_DIR}/GameAnalytics.xcframework"
echo "  Device library:    ${OUTPUT_DIR}/device/lib/libGameAnalytics.a"
echo "  Simulator library: ${OUTPUT_DIR}/simulator/lib/libGameAnalytics.a"
echo "  Headers:           ${OUTPUT_DIR}/include/GameAnalytics/"
echo ""
echo "  Architecture info (device):"
lipo -info "${OUTPUT_DIR}/device/lib/libGameAnalytics.a" 2>/dev/null || true
echo "  Architecture info (simulator):"
lipo -info "${OUTPUT_DIR}/simulator/lib/libGameAnalytics.a" 2>/dev/null || true

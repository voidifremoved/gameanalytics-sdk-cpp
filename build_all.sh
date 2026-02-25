#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${1:-Release}"

echo "========================================================"
echo "  GameAnalytics C++ SDK - Multi-Platform Static Library"
echo "========================================================"
echo ""
echo "  Configuration: ${CONFIG}"
echo ""

FAILED=()

# --- macOS ---
echo "========================================================"
echo "  Building for macOS"
echo "========================================================"
if "${SCRIPT_DIR}/build_macos.sh" "${CONFIG}"; then
    echo ""
else
    echo "WARNING: macOS build failed"
    FAILED+=("macOS")
fi

# --- iOS ---
echo ""
echo "========================================================"
echo "  Building for iOS"
echo "========================================================"
if "${SCRIPT_DIR}/build_ios.sh" "${CONFIG}"; then
    echo ""
else
    echo "WARNING: iOS build failed"
    FAILED+=("iOS")
fi

# --- Android ---
echo ""
echo "========================================================"
echo "  Building for Android"
echo "========================================================"
if [ -n "${ANDROID_NDK:-}${ANDROID_NDK_HOME:-}${ANDROID_HOME:-}" ]; then
    if "${SCRIPT_DIR}/build_android.sh" "${CONFIG}"; then
        echo ""
    else
        echo "WARNING: Android build failed"
        FAILED+=("Android")
    fi
else
    echo "SKIPPED: Set ANDROID_NDK, ANDROID_NDK_HOME, or ANDROID_HOME to build for Android"
    FAILED+=("Android (skipped)")
fi

echo "========================================================"
echo "  Build Summary"
echo "========================================================"
echo ""
echo "  Output directory: ${SCRIPT_DIR}/output/"
echo ""

if [ ${#FAILED[@]} -eq 0 ]; then
    echo "  All platforms built successfully!"
else
    echo "  Failed/skipped platforms: ${FAILED[*]}"
fi

echo ""
echo "  Directory structure:"
if command -v tree &>/dev/null; then
    tree -L 3 "${SCRIPT_DIR}/output/" 2>/dev/null || ls -R "${SCRIPT_DIR}/output/" 2>/dev/null
else
    ls -R "${SCRIPT_DIR}/output/" 2>/dev/null || echo "  (no output yet)"
fi

#!/bin/bash
set -e

echo "[*] Starting build process..."

DYLIB_NAME="hook.dylib"
SRC="src/hook.mm"
OUT="build/$DYLIB_NAME"

mkdir -p build

xcrun --sdk iphoneos clang -arch arm64 \
  -isysroot "$(xcrun --sdk iphoneos --show-sdk-path)" \
  -miphoneos-version-min=11.0 \
  -dynamiclib \
  -fobjc-arc \
  -std=c++17 \
  -o "$OUT" "$SRC"

echo "[+] Built: $OUT"

echo "[*] Signing with ldid..."
toolchain/ldid -Stoolchain/ent.plist "$OUT"

echo "[✓] Final dylib: $OUT"

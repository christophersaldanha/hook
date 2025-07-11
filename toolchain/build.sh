#!/bin/bash
set -e
echo "[*] Starting build process..."

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
CLANG=$(xcrun --sdk iphoneos --find clang++)
CFLAGS="-isysroot $SDK -arch arm64 -fobjc-arc -miphoneos-version-min=13.0"
SRC="src/hook.mm"
OUT="build/hook.dylib"

mkdir -p build

$CLANG $SRC $CFLAGS -dynamiclib -o $OUT

echo "[+] Built dylib at $OUT"


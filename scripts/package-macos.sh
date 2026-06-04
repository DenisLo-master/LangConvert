#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/LangConvert.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
PKG_PATH="$BUILD_DIR/LangConvert.pkg"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_DIR" "$PKG_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/LangConvert" "$MACOS_DIR/LangConvert"
cp "$ROOT_DIR/packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

chmod +x "$MACOS_DIR/LangConvert"

productbuild \
  --component "$APP_DIR" /Applications \
  --identifier app.langconvert.desktop.pkg \
  --version 0.1.0 \
  "$PKG_PATH"

echo "$PKG_PATH"

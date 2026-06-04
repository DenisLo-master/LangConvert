#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/LangConvert.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
PKG_PATH="$BUILD_DIR/LangConvert.pkg"
APP_SIGN_IDENTITY="${APP_SIGN_IDENTITY:-}"
INSTALLER_SIGN_IDENTITY="${INSTALLER_SIGN_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_DIR" "$PKG_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/LangConvert" "$MACOS_DIR/LangConvert"
cp "$ROOT_DIR/packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

chmod +x "$MACOS_DIR/LangConvert"

if [[ -n "$APP_SIGN_IDENTITY" ]]; then
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$APP_SIGN_IDENTITY" \
    "$APP_DIR"
else
  echo "APP_SIGN_IDENTITY is not set; building an unsigned app for local testing."
fi

PRODUCTBUILD_ARGS=(
  --component "$APP_DIR" /Applications
  --identifier app.langconvert.desktop.pkg
  --version 0.1.0
)

if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
  PRODUCTBUILD_ARGS+=(--sign "$INSTALLER_SIGN_IDENTITY")
else
  echo "INSTALLER_SIGN_IDENTITY is not set; building an unsigned pkg for local testing."
fi

productbuild "${PRODUCTBUILD_ARGS[@]}" "$PKG_PATH"

if [[ "$NOTARIZE" == "1" ]]; then
  if [[ -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_SPECIFIC_PASSWORD" ]]; then
    echo "NOTARIZE=1 requires APPLE_ID, APPLE_TEAM_ID and APPLE_APP_SPECIFIC_PASSWORD." >&2
    exit 1
  fi

  xcrun notarytool submit "$PKG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait

  xcrun stapler staple "$PKG_PATH"
  spctl -a -vvv -t install "$PKG_PATH"
fi

echo "$PKG_PATH"

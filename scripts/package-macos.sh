#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/LangConvert.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
PKG_PATH="$BUILD_DIR/LangConvert.pkg"
PKG_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/langconvert-pkg-root.XXXXXX")"
PKG_SCRIPTS="$(mktemp -d "${TMPDIR:-/tmp}/langconvert-pkg-scripts.XXXXXX")"
APP_SIGN_IDENTITY="${APP_SIGN_IDENTITY:-}"
INSTALLER_SIGN_IDENTITY="${INSTALLER_SIGN_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_DIR" "$PKG_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$PKG_ROOT/Applications" "$PKG_SCRIPTS"

cp "$ROOT_DIR/.build/release/LangConvert" "$MACOS_DIR/LangConvert"
cp "$ROOT_DIR/packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/packaging/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

chmod +x "$MACOS_DIR/LangConvert"

if [[ -n "$APP_SIGN_IDENTITY" ]]; then
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$APP_SIGN_IDENTITY" \
    "$APP_DIR"
elif command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" >/dev/null
else
  echo "codesign is not available; building an unsigned app for local testing."
fi

COPYFILE_DISABLE=1 COPY_EXTENDED_ATTRIBUTES_DISABLE=1 /usr/bin/ditto --norsrc --noextattr "$APP_DIR" "$PKG_ROOT/Applications/LangConvert.app"
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$PKG_ROOT"
fi
find "$PKG_ROOT" -name '._*' -delete

cat > "$PKG_SCRIPTS/preinstall" <<'SCRIPT'
#!/bin/bash
set -euo pipefail

/usr/bin/osascript -e 'tell application id "app.langconvert.desktop" to quit' >/dev/null 2>&1 || true
/bin/sleep 1
/usr/bin/pkill -x LangConvert >/dev/null 2>&1 || true

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ] && [ -e "/Applications/LangConvert.app" ]; then
  "$LSREGISTER" -u "/Applications/LangConvert.app" >/dev/null 2>&1 || true
fi

for app in \
  "/Applications/LangConvert.app" \
  /Applications/LangConvert\ [0-9]*.app \
  /Applications/LangConvert\ copy*.app \
  /Applications/LangConvert\ копия*.app
do
  if [ -e "$app" ]; then
    /bin/rm -rf "$app"
  fi
done

exit 0
SCRIPT

cat > "$PKG_SCRIPTS/postinstall" <<'SCRIPT'
#!/bin/bash
set -euo pipefail

APP_PATH="/Applications/LangConvert.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

/usr/bin/touch "$APP_PATH" || true
/usr/bin/touch "$APP_PATH/Contents/Info.plist" "$APP_PATH/Contents/Resources/AppIcon.icns" >/dev/null 2>&1 || true
if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -f "$APP_PATH" >/dev/null 2>&1 || true
fi
/usr/bin/qlmanage -r >/dev/null 2>&1 || true
/usr/bin/qlmanage -r cache >/dev/null 2>&1 || true

logged_in_user="$(/usr/bin/stat -f %Su /dev/console)"
if [ -n "$logged_in_user" ] && [ "$logged_in_user" != "root" ]; then
  user_id="$(/usr/bin/id -u "$logged_in_user")"
  user_home="$(/usr/bin/dscl . -read "/Users/$logged_in_user" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
  if [ -n "$user_home" ]; then
    /bin/launchctl asuser "$user_id" /bin/rm -rf "$user_home/Library/Caches/com.apple.iconservices.store" >/dev/null 2>&1 || true
  fi
  /bin/launchctl asuser "$user_id" /usr/bin/osascript -e 'tell application "Finder" to update POSIX file "/Applications/LangConvert.app"' >/dev/null 2>&1 || true
  /bin/launchctl asuser "$user_id" /usr/bin/open -a "$APP_PATH" >/dev/null 2>&1 || true
fi

exit 0
SCRIPT

chmod +x "$PKG_SCRIPTS/preinstall" "$PKG_SCRIPTS/postinstall"

PKGBUILD_ARGS=(
  --root "$PKG_ROOT"
  --scripts "$PKG_SCRIPTS"
  --install-location "/"
  --identifier "app.langconvert.desktop.pkg"
  --version "0.1.1"
)

if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
  PKGBUILD_ARGS+=(--sign "$INSTALLER_SIGN_IDENTITY")
else
  echo "INSTALLER_SIGN_IDENTITY is not set; building an unsigned pkg for local testing."
fi

COPYFILE_DISABLE=1 COPY_EXTENDED_ATTRIBUTES_DISABLE=1 pkgbuild "${PKGBUILD_ARGS[@]}" "$PKG_PATH"

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

rm -rf "$PKG_ROOT" "$PKG_SCRIPTS" "$APP_DIR" 2>/dev/null || true

# LangConvert

Native macOS menu bar utility for converting selected text between English and
Russian keyboard layouts.

## Features

- macOS status bar app with keyboard icon.
- Configurable global hotkeys for selected text conversion and locale switch.
- Hotkey capture fields in the settings window.
- Launch at login toggle through a user LaunchAgent.
- Native AppKit/Swift implementation without Electron or Chromium.

## Requirements

- macOS 13 or newer.
- Xcode command line tools.
- Accessibility permission for LangConvert, required for simulated copy/paste
  in other applications.

## Build

```bash
swift build -c release
```

## Build installer

`pkgbuild` is available only on macOS. Without Developer ID signing and
Apple notarization, Gatekeeper can block the installer on another Mac.

```bash
bash scripts/package-macos.sh
```

The installer is written to:

```text
build/LangConvert.pkg
```

GitHub Actions workflow `Build Native macOS PKG` builds the same installer on
`macos-14` and uploads it as `LangConvert-native-macOS-pkg`.

## Signed and notarized installer

To build a distributable installer that Gatekeeper accepts, configure these
GitHub Actions secrets:

- `APPLE_CERTIFICATES_P12_BASE64`: base64 encoded `.p12` containing Developer ID
  Application and Developer ID Installer certificates.
- `APPLE_CERTIFICATES_PASSWORD`: password for that `.p12`.
- `KEYCHAIN_PASSWORD`: temporary CI keychain password.
- `APP_SIGN_IDENTITY`: for example `Developer ID Application: Name (TEAMID)`.
- `INSTALLER_SIGN_IDENTITY`: for example `Developer ID Installer: Name (TEAMID)`.
- `APPLE_ID`: Apple Developer account email.
- `APPLE_TEAM_ID`: 10-character Apple team ID.
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization.

With those secrets present, the workflow signs the `.app`, signs the `.pkg`
with `pkgbuild --sign`, submits it with `xcrun notarytool`, staples the ticket
and verifies the package with `spctl`.

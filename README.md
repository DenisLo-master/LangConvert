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

`productbuild` is available only on macOS:

```bash
bash scripts/package-macos.sh
```

The installer is written to:

```text
build/LangConvert.pkg
```

GitHub Actions workflow `Build Native macOS PKG` builds the same installer on
`macos-14` and uploads it as `LangConvert-native-macOS-pkg`.

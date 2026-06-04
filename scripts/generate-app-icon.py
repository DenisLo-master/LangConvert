#!/usr/bin/env python3
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PNG = ROOT / "packaging" / "AppIconSource.png"
OUTPUT_ICNS = ROOT / "packaging" / "AppIcon.icns"

ICONSET_FILES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]


def require_tool(name):
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"{name} is required to generate a macOS app icon")
    return path


def run(command):
    subprocess.run(command, check=True)


def validate_source(sips):
    width = subprocess.check_output([sips, "-g", "pixelWidth", str(SOURCE_PNG)], text=True)
    height = subprocess.check_output([sips, "-g", "pixelHeight", str(SOURCE_PNG)], text=True)
    if "1024" not in width or "1024" not in height:
        raise SystemExit("AppIconSource.png must be 1024x1024")


def main():
    sips = require_tool("sips")
    iconutil = require_tool("iconutil")
    validate_source(sips)

    with tempfile.TemporaryDirectory(prefix="langconvert-icon.") as tmp:
        tmp_path = Path(tmp)
        iconset = tmp_path / "AppIcon.iconset"
        iconset.mkdir()

        for filename, size in ICONSET_FILES:
            run([sips, "-z", str(size), str(size), str(SOURCE_PNG), "--out", str(iconset / filename)])

        run([iconutil, "-c", "icns", str(iconset), "-o", str(OUTPUT_ICNS)])

        roundtrip_iconset = tmp_path / "Roundtrip.iconset"
        run([iconutil, "-c", "iconset", str(OUTPUT_ICNS), "-o", str(roundtrip_iconset)])
        expected = roundtrip_iconset / "icon_512x512@2x.png"
        if not expected.exists():
            raise SystemExit("Generated AppIcon.icns is missing 512x512@2x representation")

    print(OUTPUT_ICNS)


if __name__ == "__main__":
    main()

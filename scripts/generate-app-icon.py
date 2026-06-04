#!/usr/bin/env python3
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PNG = ROOT / "packaging" / "AppIconSource.png"
OUTPUT_ICNS = ROOT / "packaging" / "AppIcon.icns"

SIZES = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024),
]


def png_chunk(kind, data):
    checksum = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)


def decode_png(path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG file")

    position = 8
    width = height = None
    compressed = []
    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        kind = data[position + 4:position + 8]
        payload = data[position + 8:position + 8 + length]
        position += 12 + length

        if kind == b"IHDR":
            width, height, bit_depth, color_type, *_ = struct.unpack(">IIBBBBB", payload)
            if bit_depth != 8 or color_type != 6:
                raise ValueError("AppIconSource.png must be an 8-bit RGBA PNG")
        elif kind == b"IDAT":
            compressed.append(payload)
        elif kind == b"IEND":
            break

    raw = zlib.decompress(b"".join(compressed))
    stride = width * 4
    pixels = bytearray(width * height * 4)
    previous = bytearray(stride)
    source = 0

    for y in range(height):
        filter_type = raw[source]
        source += 1
        row = bytearray(raw[source:source + stride])
        source += stride
        reconstructed = bytearray(stride)

        for index, value in enumerate(row):
            left = reconstructed[index - 4] if index >= 4 else 0
            up = previous[index]
            up_left = previous[index - 4] if index >= 4 else 0

            if filter_type == 0:
                byte = value
            elif filter_type == 1:
                byte = (value + left) & 0xFF
            elif filter_type == 2:
                byte = (value + up) & 0xFF
            elif filter_type == 3:
                byte = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                prediction = left + up - up_left
                distances = (
                    abs(prediction - left),
                    abs(prediction - up),
                    abs(prediction - up_left),
                )
                predictor = (left, up, up_left)[distances.index(min(distances))]
                byte = (value + predictor) & 0xFF
            else:
                raise ValueError(f"Unsupported PNG filter: {filter_type}")

            reconstructed[index] = byte

        pixels[y * stride:(y + 1) * stride] = reconstructed
        previous = reconstructed

    return width, height, pixels


def encode_png(width, height, rgba):
    stride = width * 4
    rows = []
    for y in range(height):
        rows.append(b"\x00" + rgba[y * stride:(y + 1) * stride])
    compressed = zlib.compress(b"".join(rows), 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + png_chunk(b"IDAT", compressed)
        + png_chunk(b"IEND", b"")
    )


def downsample(source, source_size, target_size):
    if source_size == target_size:
        return source

    factor = source_size // target_size
    if factor < 1 or source_size % target_size != 0:
        raise ValueError("Icon sizes must divide the source size exactly")

    result = bytearray(target_size * target_size * 4)
    samples = factor * factor
    for y in range(target_size):
        for x in range(target_size):
            totals = [0, 0, 0, 0]
            for sy in range(factor):
                for sx in range(factor):
                    index = (((y * factor + sy) * source_size) + (x * factor + sx)) * 4
                    for channel in range(4):
                        totals[channel] += source[index + channel]
            target = (y * target_size + x) * 4
            result[target:target + 4] = bytes(total // samples for total in totals)
    return result


def write_icns(source):
    chunks = []
    for icon_type, size in SIZES:
        png = encode_png(size, size, downsample(source, 1024, size))
        chunks.append(icon_type.encode("ascii") + struct.pack(">I", len(png) + 8) + png)

    body = b"".join(chunks)
    OUTPUT_ICNS.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)


def main():
    width, height, source = decode_png(SOURCE_PNG)
    if width != 1024 or height != 1024:
        raise SystemExit("AppIconSource.png must be exactly 1024x1024")
    write_icns(source)
    print(OUTPUT_ICNS)


if __name__ == "__main__":
    main()

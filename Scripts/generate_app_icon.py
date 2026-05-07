#!/usr/bin/env python3
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def blend(src, dst):
    sr, sg, sb, sa = src
    dr, dg, db, da = dst
    a = sa + da * (1.0 - sa)
    if a <= 1e-6:
        return (0.0, 0.0, 0.0, 0.0)
    r = (sr * sa + dr * da * (1.0 - sa)) / a
    g = (sg * sa + dg * da * (1.0 - sa)) / a
    b = (sb * sa + db * da * (1.0 - sa)) / a
    return (r, g, b, a)


def signed_distance_round_rect(x, y, cx, cy, hw, hh, r):
    qx = abs(x - cx) - (hw - r)
    qy = abs(y - cy) - (hh - r)
    ox = max(qx, 0.0)
    oy = max(qy, 0.0)
    outside = math.hypot(ox, oy) - r
    inside = min(max(qx, qy), 0.0)
    return outside + inside


def alpha_from_sd(sd, edge=1.2):
    return clamp(0.5 - sd / edge)


def draw_icon():
    px = [(0.0, 0.0, 0.0, 0.0)] * (SIZE * SIZE)

    cx = cy = SIZE / 2
    half = SIZE * 0.42
    radius = SIZE * 0.2

    # Multi-color palette: coral -> amber -> mint.
    c1 = (0xF4 / 255.0, 0x5D / 255.0, 0x6A / 255.0)
    c2 = (0xFF / 255.0, 0xC5 / 255.0, 0x4D / 255.0)
    c3 = (0x41 / 255.0, 0xD3 / 255.0, 0x9C / 255.0)

    for y in range(SIZE):
        fy = y / (SIZE - 1)
        for x in range(SIZE):
            fx = x / (SIZE - 1)
            idx = y * SIZE + x

            sd = signed_distance_round_rect(x + 0.5, y + 0.5, cx, cy, half, half, radius)
            a = alpha_from_sd(sd)
            if a <= 0.0:
                continue

            top_mix = fx * 0.52 + fy * 0.48
            base_r = c1[0] * (1.0 - top_mix) + c2[0] * top_mix
            base_g = c1[1] * (1.0 - top_mix) + c2[1] * top_mix
            base_b = c1[2] * (1.0 - top_mix) + c2[2] * top_mix

            diag = clamp((fx + fy - 0.9) * 1.3)
            base_r = base_r * (1.0 - diag) + c3[0] * diag
            base_g = base_g * (1.0 - diag) + c3[1] * diag
            base_b = base_b * (1.0 - diag) + c3[2] * diag

            gloss = math.exp(-((fx - 0.30) ** 2 + (fy - 0.22) ** 2) / 0.045)
            base_r = clamp(base_r + 0.20 * gloss)
            base_g = clamp(base_g + 0.20 * gloss)
            base_b = clamp(base_b + 0.20 * gloss)

            px[idx] = (base_r, base_g, base_b, a)

    # Center "captured text card".
    card_cx = cx
    card_cy = cy + SIZE * 0.02
    card_w = SIZE * 0.50
    card_h = SIZE * 0.38
    card_r = SIZE * 0.06
    card_fill = (1.0, 0.98, 0.95, 0.95)

    for y in range(SIZE):
        for x in range(SIZE):
            idx = y * SIZE + x
            sd = signed_distance_round_rect(x + 0.5, y + 0.5, card_cx, card_cy, card_w / 2, card_h / 2, card_r)
            a = alpha_from_sd(sd)
            if a > 0:
                px[idx] = blend((card_fill[0], card_fill[1], card_fill[2], a * card_fill[3]), px[idx])

    # Crop corners around card (to emphasize screenshot-region selection).
    corner_color = (1.0, 1.0, 1.0, 0.95)
    corner_len = SIZE * 0.085
    corner_thickness = SIZE * 0.016
    left = card_cx - card_w / 2
    right = card_cx + card_w / 2
    top = card_cy - card_h / 2
    bottom = card_cy + card_h / 2
    corner_segments = [
        # top-left
        (left, top, corner_len, corner_thickness),
        (left, top, corner_thickness, corner_len),
        # top-right
        (right - corner_len, top, corner_len, corner_thickness),
        (right - corner_thickness, top, corner_thickness, corner_len),
        # bottom-left
        (left, bottom - corner_thickness, corner_len, corner_thickness),
        (left, bottom - corner_len, corner_thickness, corner_len),
        # bottom-right
        (right - corner_len, bottom - corner_thickness, corner_len, corner_thickness),
        (right - corner_thickness, bottom - corner_len, corner_thickness, corner_len),
    ]
    for seg_x, seg_y, seg_w, seg_h in corner_segments:
        for y in range(SIZE):
            for x in range(SIZE):
                idx = y * SIZE + x
                sd = signed_distance_round_rect(
                    x + 0.5, y + 0.5, seg_x + seg_w / 2, seg_y + seg_h / 2, seg_w / 2, seg_h / 2, min(seg_h, seg_w) / 2
                )
                a = alpha_from_sd(sd)
                if a > 0:
                    px[idx] = blend((corner_color[0], corner_color[1], corner_color[2], a * corner_color[3]), px[idx])

    # Text rows on card to indicate OCR/text extraction.
    line_color = (0.23, 0.30, 0.36, 0.82)
    line_specs = [
        (SIZE * 0.36, SIZE * 0.50, SIZE * 0.28, SIZE * 0.017),
        (SIZE * 0.36, SIZE * 0.57, SIZE * 0.23, SIZE * 0.017),
        (SIZE * 0.36, SIZE * 0.64, SIZE * 0.18, SIZE * 0.017),
    ]
    for lx, ly, lw, lh in line_specs:
        for y in range(SIZE):
            for x in range(SIZE):
                idx = y * SIZE + x
                sd = signed_distance_round_rect(x + 0.5, y + 0.5, lx + lw / 2, ly + lh / 2, lw / 2, lh / 2, lh / 2)
                a = alpha_from_sd(sd)
                if a > 0:
                    px[idx] = blend((line_color[0], line_color[1], line_color[2], a * line_color[3]), px[idx])

    # Small output badge (copy result intent).
    badge_cx = SIZE * 0.64
    badge_cy = SIZE * 0.66
    badge_w = SIZE * 0.12
    badge_h = SIZE * 0.09
    badge_color = (0.98, 0.60, 0.22, 0.95)
    for y in range(SIZE):
        for x in range(SIZE):
            idx = y * SIZE + x
            sd = signed_distance_round_rect(x + 0.5, y + 0.5, badge_cx, badge_cy, badge_w / 2, badge_h / 2, SIZE * 0.02)
            a = alpha_from_sd(sd)
            if a > 0:
                px[idx] = blend((badge_color[0], badge_color[1], badge_color[2], a * badge_color[3]), px[idx])

    return px


def write_png(path: Path, pixels):
    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)
        for x in range(SIZE):
            r, g, b, a = pixels[y * SIZE + x]
            raw.extend(
                [
                    int(clamp(r) * 255 + 0.5),
                    int(clamp(g) * 255 + 0.5),
                    int(clamp(b) * 255 + 0.5),
                    int(clamp(a) * 255 + 0.5),
                ]
            )

    def chunk(tag: bytes, data: bytes):
        return (
            struct.pack("!I", len(data))
            + tag
            + data
            + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    png = bytearray()
    png.extend(b"\x89PNG\r\n\x1a\n")
    png.extend(chunk(b"IHDR", struct.pack("!2I5B", SIZE, SIZE, 8, 6, 0, 0, 0)))
    png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), level=9)))
    png.extend(chunk(b"IEND", b""))
    path.write_bytes(png)


def main():
    root = Path(__file__).resolve().parent.parent
    assets = root / "Assets"
    assets.mkdir(parents=True, exist_ok=True)
    output = assets / "AppIcon-1024.png"
    pixels = draw_icon()
    write_png(output, pixels)
    print(f"Generated {output}")


if __name__ == "__main__":
    main()

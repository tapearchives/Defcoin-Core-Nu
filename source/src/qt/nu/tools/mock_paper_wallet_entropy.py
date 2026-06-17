#!/usr/bin/env python3
"""Render a fast paper-wallet entropy mockup for layout iteration."""

from __future__ import annotations

import argparse
import math
import pathlib
import shutil
import subprocess


def svg_header(width: int, height: int) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n'
        "<defs>\n"
        '<linearGradient id="panel" x1="0" y1="0" x2="1" y2="1">'
        '<stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#f8f6fb"/>'
        "</linearGradient>\n"
        '<filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">'
        '<feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#180d25" flood-opacity=".18"/>'
        "</filter>\n"
        "</defs>\n"
    )


def hourglass_grains(
    progress: float, cx: float, top_y: float, neck_y: float, bottom_y: float, glass_w: float
) -> str:
    grains: list[str] = []
    count = 920
    top_fill = (neck_y - top_y - 30) * (1.0 - progress)
    bottom_fill = (bottom_y - neck_y - 30) * progress
    for i in range(count):
        seed = (i * 37 + 19) % 997
        s = seed / 997.0
        bottom = i < count * progress
        if bottom:
            spread = glass_w * (0.10 + 0.34 * progress) * math.sqrt(s)
            x = cx + math.sin(seed * 12.9898) * spread
            height_at_x = max(3.0, bottom_fill * (1.0 - abs(x - cx) / max(1.0, glass_w * 0.50)))
            y = bottom_y - 28 - abs(math.cos(seed * 7.1)) * height_at_x
        else:
            spread = glass_w * 0.31 * (1.0 - progress * 0.35)
            x = cx + math.sin(seed * 12.9898) * spread
            y = top_y + 38 + abs(math.cos(seed * 9.2)) * max(3.0, top_fill)
        r = 0.8 + (0.35 if s > 0.84 else 0.0)
        opacity = 0.32 + s * 0.42
        grains.append(
            f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r:.2f}" fill="#d8af38" opacity="{opacity:.2f}"/>'
        )
    return "\n".join(grains)


def render_svg(progress: float) -> str:
    width = 1120
    height = 720
    cx = 285
    top_y = 190
    neck_y = 380
    bottom_y = 610
    glass_w = 270
    pct = int(round(progress * 100))
    parts = [svg_header(width, height)]
    parts.append('<rect width="1120" height="720" rx="28" fill="#f5f3f0"/>')
    parts.append(
        '<rect x="28" y="30" width="676" height="660" rx="18" fill="#ffffff" stroke="#d9d4df"/>'
    )
    parts.append(
        '<rect x="42" y="44" width="648" height="58" rx="12" fill="#f1ecf8" stroke="#7653ad"/>'
    )
    parts.append(
        '<circle cx="72" cy="73" r="18" fill="#7db8ff"/><text x="72" y="79" text-anchor="middle" font-family="Helvetica" font-size="18" font-weight="700" fill="#fff">3</text>'
    )
    parts.append(
        '<text x="104" y="80" font-family="Helvetica" font-size="23" font-weight="700" fill="#151515">Create Entropy</text>'
    )
    parts.append(
        f'<text x="660" y="80" text-anchor="end" font-family="Helvetica" font-size="18" font-weight="700" fill="#555">{pct}%</text>'
    )
    parts.append(
        '<text x="48" y="128" font-family="Helvetica" font-size="17" fill="#4f5662">Move the mouse across this page and type random characters.</text>'
    )
    parts.append(
        '<text x="48" y="151" font-family="Helvetica" font-size="17" fill="#4f5662">Your input is mixed with system cryptographic randomness.</text>'
    )
    parts.append(
        f'<text x="48" y="184" font-family="Helvetica" font-size="17" fill="#4f5662">{int(progress * 3072)} / 3072 entropy points collected.</text>'
    )
    parts.append(
        '<rect x="48" y="202" width="620" height="14" rx="7" fill="#e4e2df" stroke="#cfccc8"/>'
    )
    parts.append(
        f'<rect x="48" y="202" width="{620 * progress:.1f}" height="14" rx="7" fill="#d8af38"/>'
    )
    parts.append(
        '<rect x="136" y="242" width="360" height="392" rx="15" fill="#fffdf8" stroke="#d9c177" filter="url(#softShadow)"/>'
    )
    left_points = [
        (cx - glass_w / 2, top_y),
        (cx - glass_w * 0.30, top_y + 92),
        (cx - glass_w * 0.18, neck_y - 20),
        (cx - 10, neck_y),
        (cx - glass_w * 0.18, neck_y + 20),
        (cx - glass_w * 0.30, bottom_y - 92),
        (cx - glass_w / 2, bottom_y),
    ]
    right_points = [
        (cx + glass_w / 2, top_y),
        (cx + glass_w * 0.30, top_y + 92),
        (cx + glass_w * 0.18, neck_y - 20),
        (cx + 10, neck_y),
        (cx + glass_w * 0.18, neck_y + 20),
        (cx + glass_w * 0.30, bottom_y - 92),
        (cx + glass_w / 2, bottom_y),
    ]
    for path_points in (left_points, right_points):
        for start, end in zip(path_points, path_points[1:], strict=False):
            parts.append(
                f'<line x1="{start[0]:.1f}" y1="{start[1]:.1f}" x2="{end[0]:.1f}" y2="{end[1]:.1f}" '
                'stroke="#c7a233" stroke-width="4" opacity=".86" stroke-linecap="round"/>'
            )
    parts.append(
        f'<line x1="{cx - glass_w / 2 - 24}" y1="{top_y}" x2="{cx + glass_w / 2 + 24}" y2="{top_y}" stroke="#d5b956" stroke-width="2"/>'
    )
    parts.append(
        f'<line x1="{cx - glass_w / 2 - 24}" y1="{bottom_y}" x2="{cx + glass_w / 2 + 24}" y2="{bottom_y}" stroke="#d5b956" stroke-width="2"/>'
    )
    mound_w = glass_w * (0.12 + 0.35 * progress)
    mound_h = max(4.0, (bottom_y - neck_y - 30) * progress * 0.52)
    top_w = glass_w * 0.34 * (1 - progress * 0.35)
    parts.append(
        f'<path d="M {cx - top_w:.1f} {top_y + 44:.1f} Q {cx:.1f} {top_y + 72:.1f} {cx + top_w:.1f} {top_y + 44:.1f} L {cx + max(8, glass_w * 0.075 * (1 - progress)):.1f} {neck_y - 22:.1f} Q {cx:.1f} {neck_y - 8:.1f} {cx - max(8, glass_w * 0.075 * (1 - progress)):.1f} {neck_y - 22:.1f} Z" fill="#edd16a" opacity=".34"/>'
    )
    parts.append(
        f'<path d="M {cx - mound_w:.1f} {bottom_y - 28:.1f} Q {cx:.1f} {bottom_y - 28 - mound_h:.1f} {cx + mound_w:.1f} {bottom_y - 28:.1f} L {cx + mound_w * 0.7:.1f} {bottom_y - 18:.1f} L {cx - mound_w * 0.7:.1f} {bottom_y - 18:.1f} Z" fill="#edd16a" opacity=".48"/>'
    )
    parts.append(hourglass_grains(progress, cx, top_y, neck_y, bottom_y, glass_w))
    parts.append(
        f'<line x1="{cx}" y1="{neck_y + 6}" x2="{cx}" y2="{bottom_y - 34}" stroke="#edc754" stroke-width="2" opacity=".8"/>'
    )
    parts.append(
        '<text x="345" y="663" text-anchor="middle" font-family="Helvetica" font-size="16" font-weight="700" fill="#7a5c1a">Move mouse anywhere in this page and type</text>'
    )
    parts.append(
        '<rect x="48" y="620" width="150" height="52" rx="8" fill="#fff" stroke="#111"/><text x="123" y="653" text-anchor="middle" font-family="Helvetica" font-size="17" font-weight="700">Reset Entropy</text>'
    )
    parts.append(
        '<rect x="735" y="30" width="357" height="660" rx="18" fill="#f8f7f5" stroke="#d9d4df"/>'
    )
    parts.append(
        '<text x="760" y="72" font-family="Helvetica" font-size="25" font-weight="700">Sheet Preview</text>'
    )
    parts.append(
        '<text x="760" y="101" font-family="Helvetica" font-size="16" fill="#667">Generating live print preview...</text>'
    )
    parts.append('<rect x="805" y="150" width="210" height="300" fill="#fff" stroke="#d3d9df"/>')
    parts.append(
        '<rect x="836" y="194" width="148" height="92" fill="#f1eaff"/><rect x="836" y="314" width="148" height="92" fill="#f1eaff"/>'
    )
    parts.append(
        '<text x="910" y="476" text-anchor="middle" font-family="Helvetica" font-size="14" fill="#667">Actual print renderer preview</text>'
    )
    parts.append("</svg>\n")
    return "\n".join(parts)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="/tmp/defcoin-entropy-mockup.svg")
    parser.add_argument("--progress", type=float, default=0.49)
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    out.write_text(render_svg(max(0.0, min(1.0, args.progress))), encoding="utf-8")
    magick = shutil.which("magick")
    if magick:
        font = "/System/Library/Fonts/Supplemental/Arial.ttf"
        subprocess.run([magick, "-font", font, str(out), str(out.with_suffix(".png"))], check=True)
    print(out)
    if magick:
        print(out.with_suffix(".png"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

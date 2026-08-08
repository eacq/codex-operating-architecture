#!/usr/bin/env python3
"""
Render a publication-ready line figure with:
- exact physical dimensions;
- Chinese text in SimSun/宋体;
- Latin, numbers, units, Greek symbols, and math in Times New Roman;
- configurable tolerance band, peak annotation, legend, and note;
- PNG, TIFF, PDF, and SVG outputs.

Input CSV must contain numeric x and y columns.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.font_manager import FontProperties, fontManager
from matplotlib.lines import Line2D
from matplotlib.patches import Patch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", required=True, type=Path)
    parser.add_argument("--x-column", default="x")
    parser.add_argument("--y-column", default="y")
    parser.add_argument("--output-dir", type=Path, default=Path("output"))

    parser.add_argument("--width-cm", type=float)
    parser.add_argument("--height-cm", type=float)
    parser.add_argument("--width-px", type=int)
    parser.add_argument("--height-px", type=int)
    parser.add_argument("--dpi", type=int, default=1200)
    parser.add_argument("--font-size-pt", type=float, default=7.5)

    parser.add_argument("--simsun", required=True, type=Path)
    parser.add_argument("--times", required=True, type=Path)

    parser.add_argument("--x-label-cn", default="砂轮轴向坐标")
    parser.add_argument("--x-label-math", default=r"$Z_w$ (mm)")
    parser.add_argument("--y-label-cn", default="径向偏差")
    parser.add_argument("--y-label-math", default=r"$\Delta r_w$ (μm)")

    parser.add_argument("--x-min", type=float, default=-25)
    parser.add_argument("--x-max", type=float, default=25)
    parser.add_argument("--y-min", type=float, default=-15)
    parser.add_argument("--y-max", type=float, default=15)

    parser.add_argument("--band-low", type=float, default=-5)
    parser.add_argument("--band-high", type=float, default=5)
    parser.add_argument("--band-label", default="±5 μm 精密磨削允差带")

    parser.add_argument("--peak-label", default="峰值偏差点")
    parser.add_argument(
        "--note",
        default="备注：阴影为 ±5 μm 精密允差；曲线为解析法相对离散法径向偏差",
    )
    parser.add_argument(
        "--formats",
        nargs="+",
        default=["png", "tif", "pdf", "svg"],
        help=(
            "Output formats accepted by the local Matplotlib/Pillow backend, "
            "for example png tif tiff pdf svg eps jpg jpeg bmp webp."
        ),
    )
    return parser.parse_args()


def validate_font(path: Path, label: str) -> None:
    if not path.exists():
        raise FileNotFoundError(f"{label} font file not found: {path}")


def register_fonts(simsun: Path, times: Path) -> tuple[str, str]:
    fontManager.addfont(str(simsun))
    fontManager.addfont(str(times))

    simsun_name = FontProperties(fname=str(simsun)).get_name()
    times_name = FontProperties(fname=str(times)).get_name()

    if "Times" not in times_name:
        raise RuntimeError(
            f"Expected Times New Roman, but font file reports: {times_name}"
        )
    # SimSun metadata varies by platform; validate conservatively.
    if simsun_name.lower() not in {"simsun", "宋体"} and "song" not in simsun_name.lower():
        print(
            f"WARNING: Chinese font file reports '{simsun_name}'. "
            "Manually verify that this is SimSun/宋体.",
            file=sys.stderr,
        )

    return simsun_name, times_name


def mixed_text(ax, x, y, cn, latin, *, rotation=0, ha="center", va="center",
               cn_font=None, latin_font=None, transform=None, zorder=10):
    """
    Draw adjacent Chinese and Latin spans with independent fonts.
    Uses renderer-based measurements for accurate centering.
    """
    transform = transform or ax.transAxes
    fig = ax.figure
    renderer = fig.canvas.get_renderer()

    t_cn = ax.text(
        0, 0, cn,
        fontproperties=cn_font,
        transform=transform,
        rotation=rotation,
        ha="left", va=va,
        alpha=0,
    )
    t_lat = ax.text(
        0, 0, latin,
        fontproperties=latin_font,
        transform=transform,
        rotation=rotation,
        ha="left", va=va,
        alpha=0,
    )
    fig.canvas.draw()
    bb_cn = t_cn.get_window_extent(renderer=renderer)
    bb_lat = t_lat.get_window_extent(renderer=renderer)
    t_cn.remove()
    t_lat.remove()

    total_px = (bb_cn.width + bb_lat.width) if rotation == 0 else (bb_cn.height + bb_lat.height)
    base_display = transform.transform((x, y))

    if ha == "center":
        offset_px = -total_px / 2
    elif ha == "right":
        offset_px = -total_px
    else:
        offset_px = 0

    if rotation == 0:
        cn_display = (base_display[0] + offset_px, base_display[1])
        lat_display = (cn_display[0] + bb_cn.width, base_display[1])
    else:
        cn_display = (base_display[0], base_display[1] + offset_px)
        lat_display = (base_display[0], cn_display[1] + bb_cn.height)

    inv = transform.inverted()
    cn_pos = inv.transform(cn_display)
    lat_pos = inv.transform(lat_display)

    ax.text(
        *cn_pos, cn,
        fontproperties=cn_font,
        transform=transform,
        rotation=rotation,
        ha="left", va=va,
        zorder=zorder,
    )
    ax.text(
        *lat_pos, latin,
        fontproperties=latin_font,
        transform=transform,
        rotation=rotation,
        ha="left", va=va,
        zorder=zorder,
    )


def main() -> None:
    args = parse_args()
    validate_font(args.simsun, "SimSun")
    validate_font(args.times, "Times New Roman")

    simsun_name, times_name = register_fonts(args.simsun, args.times)

    # Primary Latin font + Chinese fallback.
    matplotlib.rcParams["font.family"] = [times_name, simsun_name]
    matplotlib.rcParams["axes.unicode_minus"] = False
    matplotlib.rcParams["mathtext.fontset"] = "custom"
    matplotlib.rcParams["mathtext.rm"] = times_name
    matplotlib.rcParams["mathtext.it"] = f"{times_name}:italic"
    matplotlib.rcParams["mathtext.bf"] = f"{times_name}:bold"

    data = pd.read_csv(args.csv)
    if args.x_column not in data or args.y_column not in data:
        raise KeyError(
            f"CSV must contain columns '{args.x_column}' and '{args.y_column}'. "
            f"Available columns: {list(data.columns)}"
        )

    x = pd.to_numeric(data[args.x_column], errors="raise").to_numpy()
    y = pd.to_numeric(data[args.y_column], errors="raise").to_numpy()

    if len(x) < 2 or len(x) != len(y):
        raise ValueError("x and y must have the same length and contain at least 2 points.")

    order = np.argsort(x)
    x = x[order]
    y = y[order]

    if args.width_px is not None or args.height_px is not None:
        if args.width_px is None or args.height_px is None:
            raise ValueError("--width-px and --height-px must be provided together.")
        width_in = args.width_px / args.dpi
        height_in = args.height_px / args.dpi
        width_label = f"{args.width_px}px"
        height_label = f"{args.height_px}px"
    else:
        if args.width_cm is None or args.height_cm is None:
            args.width_cm = 17.13
            args.height_cm = 7.59
            print(
                "No size was provided; using the example journal-size canvas "
                "17.13 cm x 7.59 cm. Pass --width-cm/--height-cm or "
                "--width-px/--height-px for any other target.",
                file=sys.stderr,
            )
        width_in = args.width_cm / 2.54
        height_in = args.height_cm / 2.54
        width_label = f"{args.width_cm:.2f}cm"
        height_label = f"{args.height_cm:.2f}cm"

    cn_font = FontProperties(fname=str(args.simsun), size=args.font_size_pt)
    latin_font = FontProperties(fname=str(args.times), size=args.font_size_pt)

    fig, ax = plt.subplots(figsize=(width_in, height_in), dpi=args.dpi)
    fig.subplots_adjust(left=0.105, right=0.985, bottom=0.20, top=0.955)

    ax.axhspan(
        args.band_low,
        args.band_high,
        facecolor="#FAD6D6",
        edgecolor="#E98B8B",
        linewidth=0.55,
        alpha=0.72,
        zorder=0,
    )
    ax.plot(x, y, color="black", linewidth=0.75, zorder=3)

    peak_idx = int(np.nanargmax(y))
    peak_x = float(x[peak_idx])
    peak_y = float(y[peak_idx])
    ax.scatter(
        [peak_x], [peak_y],
        s=25,
        color="red",
        edgecolors="red",
        linewidths=0.4,
        zorder=5,
    )
    ax.annotate(
        args.peak_label,
        xy=(peak_x, peak_y),
        xytext=(peak_x - 4.5, min(args.y_max - 2.0, peak_y + 3.2)),
        fontproperties=cn_font,
        ha="left",
        va="center",
        arrowprops=dict(
            arrowstyle="->",
            color="red",
            linewidth=0.65,
            shrinkA=2,
            shrinkB=3,
        ),
        zorder=6,
    )

    ax.set_xlim(args.x_min, args.x_max)
    ax.set_ylim(args.y_min, args.y_max)
    ax.set_xticks(np.arange(math.ceil(args.x_min / 10) * 10, args.x_max + 0.1, 10))
    ax.set_yticks(np.arange(math.ceil(args.y_min / 5) * 5, args.y_max + 0.1, 5))

    # Mixed-font labels are manually composed.
    mixed_text(
        ax, 0.5, -0.135,
        args.x_label_cn + " ",
        args.x_label_math,
        rotation=0,
        cn_font=cn_font,
        latin_font=latin_font,
        transform=ax.transAxes,
    )
    mixed_text(
        ax, -0.078, 0.5,
        args.y_label_cn + " ",
        args.y_label_math,
        rotation=90,
        cn_font=cn_font,
        latin_font=latin_font,
        transform=ax.transAxes,
    )

    ax.tick_params(
        axis="both",
        which="major",
        labelsize=args.font_size_pt,
        width=0.55,
        length=3,
        direction="out",
    )
    for label in ax.get_xticklabels() + ax.get_yticklabels():
        label.set_fontproperties(latin_font)

    ax.grid(
        True,
        which="major",
        linestyle=":",
        linewidth=0.42,
        color="#BFBFBF",
        alpha=0.9,
    )
    for spine in ax.spines.values():
        spine.set_linewidth(0.65)
        spine.set_color("black")

    handles = [
        Patch(
            facecolor="#FAD6D6",
            edgecolor="#E98B8B",
            linewidth=0.55,
            alpha=0.72,
            label=args.band_label,
        ),
        Line2D(
            [0], [0],
            marker="o",
            linestyle="None",
            markerfacecolor="red",
            markeredgecolor="red",
            markersize=4.2,
            label=args.peak_label,
        ),
    ]
    legend = ax.legend(
        handles=handles,
        loc="upper right",
        prop=cn_font,
        frameon=True,
        borderpad=0.35,
        labelspacing=0.35,
        handlelength=1.45,
        handletextpad=0.55,
    )
    legend.get_frame().set_linewidth(0.55)
    legend.get_frame().set_edgecolor("#BFBFBF")
    legend.get_frame().set_facecolor("white")
    legend.get_frame().set_alpha(0.96)

    ax.text(
        args.x_min + 0.8,
        args.y_min + 1.8,
        args.note,
        fontproperties=cn_font,
        ha="left",
        va="center",
        bbox=dict(
            boxstyle="round,pad=0.22",
            facecolor="#FFFDF2",
            edgecolor="black",
            linewidth=0.55,
        ),
        zorder=7,
    )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    stem = (
        f"figure_{width_label}x{height_label}_"
        f"{args.font_size_pt:g}pt_SimSun_TNR_{args.dpi}dpi"
    )

    for fmt in args.formats:
        normalized_fmt = fmt.lower().lstrip(".")
        suffix = "tif" if normalized_fmt in {"tif", "tiff"} else normalized_fmt
        output = args.output_dir / f"{stem}.{suffix}"
        save_kwargs = dict(
            dpi=args.dpi,
            facecolor="white",
            metadata={
                "Title": "Academic scientific figure",
                "Description": (
                    f"{width_label} × {height_label}; {args.font_size_pt:g} pt; "
                    f"SimSun + Times New Roman; {args.dpi} dpi"
                ),
            },
        )
        if suffix == "tif":
            save_kwargs["pil_kwargs"] = {"compression": "tiff_lzw"}
        save_format = "tiff" if suffix == "tif" else suffix
        fig.savefig(output, format=save_format, **save_kwargs)
        print(output)

    plt.close(fig)

    expected_w = args.width_px if args.width_px is not None else round(args.width_cm / 2.54 * args.dpi)
    expected_h = args.height_px if args.height_px is not None else round(args.height_cm / 2.54 * args.dpi)
    print(f"Expected raster size: {expected_w} × {expected_h} px")
    print(f"Fonts: Chinese={simsun_name}; Latin/math={times_name}")


if __name__ == "__main__":
    main()

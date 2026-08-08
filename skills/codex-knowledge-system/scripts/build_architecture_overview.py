#!/usr/bin/env python3
"""Render the reproducible experience and knowledge architecture overview."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


WIDTH, HEIGHT = 1600, 900
COLORS = {
    "ink": "#17212B",
    "muted": "#536170",
    "line": "#8A98A8",
    "evidence": "#DCEBFA",
    "experience": "#E8F2DF",
    "knowledge": "#FFF0C7",
    "execution": "#F5DFE6",
    "tool": "#EEF1F4",
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        Path(r"C:\Windows\Fonts\msyhbd.ttc" if bold else r"C:\Windows\Fonts\msyh.ttc"),
        Path(r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def centered(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str, text_font, fill: str) -> None:
    bounds = draw.multiline_textbbox((0, 0), text, font=text_font, spacing=8, align="center")
    width, height = bounds[2] - bounds[0], bounds[3] - bounds[1]
    x = box[0] + (box[2] - box[0] - width) / 2
    y = box[1] + (box[3] - box[1] - height) / 2
    draw.multiline_text((x, y), text, font=text_font, fill=fill, spacing=8, align="center")


def arrow(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int]) -> None:
    draw.line((start, end), fill=COLORS["line"], width=5)
    draw.polygon([(end[0], end[1]), (end[0] - 18, end[1] - 11), (end[0] - 18, end[1] + 11)], fill=COLORS["line"])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    image = Image.new("RGB", (WIDTH, HEIGHT), "#FFFFFF")
    draw = ImageDraw.Draw(image)
    draw.text((80, 55), "Codex 经验与知识架构", font=font(46, True), fill=COLORS["ink"])
    draw.text((80, 120), "Evidence becomes reusable action, linked knowledge, visual understanding, and better execution.", font=font(23), fill=COLORS["muted"])

    boxes = [
        ((80, 240, 400, 480), COLORS["evidence"], "01 证据\n项目 · 历史 · 论文\n失败与验证结果"),
        ((470, 240, 790, 480), COLORS["experience"], "02 已验证经验\n行动 · 适用范围\n失效条件 · 来源"),
        ((860, 240, 1180, 480), COLORS["knowledge"], "03 权威知识\nMarkdown · 类型化链接\n模块 · 工作流 · 概念"),
        ((1250, 240, 1570, 480), COLORS["execution"], "04 执行闭环\nSkills · 项目流程\n复盘产生新证据"),
    ]
    for box, color, label in boxes:
        draw.rounded_rectangle(box, radius=8, fill=color, outline=COLORS["line"], width=2)
        centered(draw, box, label, font(27, True), COLORS["ink"])
    for index in range(3):
        arrow(draw, (boxes[index][0][2] + 14, 360), (boxes[index + 1][0][0] - 14, 360))

    draw.text((80, 570), "知识的派生视图与调用入口", font=font(29, True), fill=COLORS["ink"])
    tools = [
        ((80, 640, 420, 790), "Obsidian\n双向链接 · 检索"),
        ((460, 640, 800, 790), "MindMaster / Mermaid\n导图 · 结构理解"),
        ((840, 640, 1180, 790), "Anki\n精选主动回忆"),
        ((1220, 640, 1560, 790), "按需图床\nHTTPS · 清单 · 隔离"),
    ]
    for box, label in tools:
        draw.rounded_rectangle(box, radius=8, fill=COLORS["tool"], outline=COLORS["line"], width=2)
        centered(draw, box, label, font(25, True), COLORS["ink"])
    draw.text((80, 835), "原则：Markdown 是唯一权威源；导图、卡片与图片均可追溯、可验证、可替换。", font=font(24), fill=COLORS["muted"])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output, format="PNG", optimize=True)
    print(f"Rendered {args.output} ({WIDTH}x{HEIGHT}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

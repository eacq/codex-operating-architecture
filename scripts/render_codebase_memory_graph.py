"""Encode PNG frames exported from the Codebase Memory MCP Three.js canvas."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--png", type=Path, required=True)
    parser.add_argument("--gif", type=Path, required=True)
    parser.add_argument("--frames-dir", type=Path, required=True)
    parser.add_argument("--frame-duration-ms", type=int, default=1250)
    parser.add_argument("--loop-duration-ms", type=int)
    args = parser.parse_args()

    frames = sorted(args.frames_dir.glob("frame-*.png"))
    manifest = args.frames_dir / "capture.json"
    if manifest.exists():
        loop_frame_count = json.loads(manifest.read_text(encoding="utf-8"))["loop_frame_count"]
        frames = frames[:loop_frame_count]
    if not frames:
        raise SystemExit("No Three.js canvas frames were captured.")
    args.png.parent.mkdir(parents=True, exist_ok=True)
    args.gif.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(frames[0], args.png)
    images = [Image.open(frame).convert("RGB") for frame in frames]
    loop_duration = args.loop_duration_ms or args.frame_duration_ms * len(images)
    if loop_duration % 10 != 0:
        raise SystemExit("GIF loop duration must be divisible by 10 milliseconds.")
    duration_units = loop_duration // 10
    durations = [((index + 1) * duration_units // len(images) - index * duration_units // len(images)) * 10 for index in range(len(images))]
    images[0].save(args.gif, format="GIF", save_all=True, append_images=images[1:], duration=durations, loop=0, disposal=2, optimize=False)


if __name__ == "__main__":
    main()

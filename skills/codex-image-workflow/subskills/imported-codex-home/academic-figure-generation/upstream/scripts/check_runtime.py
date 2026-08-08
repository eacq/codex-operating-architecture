#!/usr/bin/env python3
"""Check Python dependencies needed by academic-figure-generation."""

from __future__ import annotations

import importlib.util
import json
import sys


REQUIRED_MODULES = [
    "yaml",
    "openai",
    "PIL",
    "matplotlib",
    "numpy",
    "pandas",
    "google.genai",
    "anthropic",
    "httpx",
    "aiofiles",
    "tqdm",
    "json_repair",
    "huggingface_hub",
    "dotenv",
]


def has_module(name: str) -> bool:
    root = name.split(".", 1)[0]
    return importlib.util.find_spec(root) is not None


def main() -> int:
    results = {name: has_module(name) for name in REQUIRED_MODULES}
    payload = {
        "python": sys.executable,
        "version": sys.version.split()[0],
        "modules": results,
        "ok": all(results.values()),
    }
    print(json.dumps(payload, ensure_ascii=True, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

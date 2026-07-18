#!/usr/bin/env python3
"""Reject placeholders and common secret-shaped content in tracked source files."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).parents[1]
EXCLUDED = {".git", ".history-cache", ".runtime", ".codex"}
PATTERNS = {
    "unfinished placeholder": re.compile(r"\[?TODO(?::|\])", re.IGNORECASE),
    "OpenAI-style secret": re.compile(r"\bsk-[A-Za-z0-9_-]{16,}"),
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "assigned secret": re.compile(r"(?i)(?:api[_-]?key|token|password|secret)\s*[:=]\s*['\"][^<\s'\"]{12,}"),
}


def is_imported_upstream(relative: Path) -> bool:
    """Imported source is reference material, not active canonical guidance."""
    parts = relative.parts
    return "imported-codex-home" in parts and "upstream" in parts


def is_placeholder_credential(match_text: str) -> bool:
    normalized = match_text.casefold()
    markers = ("redacted", "example", "your-", "your_", "new-key", "xxxxx", "<")
    return any(marker in normalized for marker in markers)


def main() -> int:
    findings = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in EXCLUDED for part in path.parts):
            continue
        relative = path.relative_to(ROOT)
        if any(relative.parts[index : index + 3] == (".codex", "runtime", "env") for index in range(len(relative.parts) - 2)):
            continue
        if relative.parts[:3] == ("knowledge-vault", ".obsidian", "plugins"):
            continue
        if path.name == "history-catalog.json":
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for label, pattern in PATTERNS.items():
            for match in pattern.finditer(text):
                if label == "unfinished placeholder" and is_imported_upstream(relative):
                    continue
                if label in {"OpenAI-style secret", "assigned secret"} and is_placeholder_credential(match.group(0)):
                    continue
                line = text.count("\n", 0, match.start()) + 1
                findings.append(f"{path.relative_to(ROOT)}:{line}: {label}")
    if findings:
        print("\n".join(findings))
        return 1
    print("Repository placeholder and secret scan passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

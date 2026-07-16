#!/usr/bin/env python3
"""Build a secret-safe metadata catalog of local Codex history."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def portable_path(value: str | Path | None, codex_home: Path, repository_root: Path) -> str:
    """Return a Git-safe logical location without a user or drive-specific prefix."""
    if not value:
        return ""
    path = Path(value)
    try:
        return "$CODEX_HOME/" + path.resolve().relative_to(codex_home.resolve()).as_posix()
    except (OSError, ValueError):
        pass
    try:
        return "$ARCHITECTURE_ROOT/" + path.resolve().relative_to(repository_root.resolve()).as_posix()
    except (OSError, ValueError):
        pass
    return "$EXTERNAL_WORKSPACE/" + path.name


def read_index(path: Path) -> dict[str, dict]:
    records: dict[str, dict] = {}
    if not path.exists():
        return records
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            try:
                item = json.loads(line)
            except (json.JSONDecodeError, UnicodeDecodeError):
                continue
            thread_id = item.get("id")
            if thread_id:
                records[thread_id] = {
                    "id": thread_id,
                    "title": item.get("thread_name", ""),
                    "updated_at": item.get("updated_at", ""),
                }
    return records


def session_metadata(path: Path) -> dict:
    result = {"path": path}
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                item = json.loads(line)
            except json.JSONDecodeError:
                continue
            if item.get("type") != "session_meta":
                continue
            payload = item.get("payload", {})
            result.update({
                "id": payload.get("id") or payload.get("session_id"),
                "started_at": payload.get("timestamp"),
                "cwd": payload.get("cwd"),
                "originator": payload.get("originator"),
            })
            break
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex-home", type=Path, default=Path.home() / ".codex")
    parser.add_argument("--output", type=Path, default=Path(__file__).parents[1] / "knowledge" / "history-catalog.json")
    parser.add_argument("--include-local-history", action="store_true", help="Index this machine's local Codex session metadata. Default output is release-safe and empty.")
    args = parser.parse_args()

    repository_root = Path(__file__).parents[1]

    if not args.include_local_history:
        output = {
            "schema_version": 2,
            "privacy": "Release-safe placeholder. Local Codex history is not indexed unless --include-local-history is passed.",
            "session_count": 0,
            "sessions": [],
        }
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote release-safe empty history catalog to {args.output}")
        return 0

    index = read_index(args.codex_home / "session_index.jsonl")
    files = list((args.codex_home / "sessions").rglob("*.jsonl"))
    files += list((args.codex_home / "archived_sessions").rglob("*.jsonl"))
    sessions = []
    for path in sorted(files):
        item = session_metadata(path)
        item["path"] = portable_path(item.get("path"), args.codex_home, repository_root)
        item["cwd"] = portable_path(item.get("cwd"), args.codex_home, repository_root)
        indexed = index.get(item.get("id", ""), {})
        item["title"] = indexed.get("title", "")
        item["updated_at"] = indexed.get("updated_at", "")
        sessions.append(item)

    output = {
        "schema_version": 2,
        "privacy": "Metadata only. No prompts, responses, credentials, or tool payloads.",
        "session_count": len(sessions),
        "sessions": sessions,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Indexed {len(sessions)} sessions into {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

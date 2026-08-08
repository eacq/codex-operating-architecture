#!/usr/bin/env python3
"""Build or query a metadata-only, provider-independent local conversation catalog."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def read_json_lines(path: Path):
    if not path.exists():
        return
    with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
        for line in handle:
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def normalize_title(value: object) -> str:
    """Repair the known GBK-decoded UTF-8 title form without touching valid text."""
    text = value if isinstance(value, str) else ""
    # Valid Chinese text must remain unchanged. The broken form observed in the
    # local session index contains private-use code points such as U+E1BC.
    if not any("\ue000" <= char <= "\uf8ff" for char in text):
        return text
    try:
        return text.encode("gbk").decode("utf-8")
    except UnicodeError:
        return text


def read_session_index(path: Path) -> dict[str, dict]:
    records: dict[str, dict] = {}
    for item in read_json_lines(path) or ():
        identifier = item.get("id")
        if identifier:
            records[identifier] = {
                "title": normalize_title(item.get("thread_name", "")),
                "updated_at": item.get("updated_at", ""),
            }
    return records


def session_metadata(path: Path) -> dict | None:
    for item in read_json_lines(path) or ():
        if item.get("type") != "session_meta":
            continue
        payload = item.get("payload", {})
        identifier = payload.get("id") or payload.get("session_id")
        if identifier:
            return {
                "id": identifier,
                "started_at": payload.get("timestamp", ""),
                "cwd": payload.get("cwd", ""),
            }
    return None


def read_desktop_state(codex_home: Path) -> dict:
    """Read task/pin/project metadata only; never read credentials or messages."""
    state_path = codex_home / ".codex-global-state.json"
    empty = {"pinned": set(), "descriptions": {}, "workspace_hints": {}, "project_order": [], "workspaces": []}
    if not state_path.exists():
        return empty
    try:
        state = json.loads(state_path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError):
        return empty
    atom = state.get("electron-persisted-atom-state", {})

    def value(name: str, default):
        return state.get(name, atom.get(name, default))

    return {
        "pinned": set(value("pinned-thread-ids", [])),
        "descriptions": value("thread-descriptions-v1", {}),
        "workspace_hints": value("thread-workspace-root-hints", {}),
        "project_order": value("project-order", []),
        "workspaces": value("electron-saved-workspace-roots", []),
    }


def build_catalog(codex_home: Path) -> dict:
    index = read_session_index(codex_home / "session_index.jsonl")
    desktop = read_desktop_state(codex_home)
    sources = [codex_home / "sessions", codex_home / "archived_sessions"]
    records: dict[str, dict] = {}
    unreadable = 0
    for source in sources:
        if not source.exists():
            continue
        for path in sorted(source.rglob("*.jsonl")):
            metadata = session_metadata(path)
            if metadata is None:
                unreadable += 1
                continue
            identifier = metadata["id"]
            indexed = index.get(identifier, {})
            record = records.setdefault(identifier, {
                "id": identifier,
                "title": "",
                "updated_at": "",
                "started_at": "",
                "cwd": "",
                "paths": [],
            })
            record["title"] = indexed.get("title") or record["title"]
            record["updated_at"] = indexed.get("updated_at") or record["updated_at"]
            record["started_at"] = metadata.get("started_at") or record["started_at"]
            record["cwd"] = metadata.get("cwd") or record["cwd"]
            path_text = str(path)
            if path_text not in record["paths"]:
                record["paths"].append(path_text)

    for record in records.values():
        identifier = record["id"]
        record["is_pinned"] = identifier in desktop["pinned"]
        record["desktop_description"] = desktop["descriptions"].get(identifier, "")
        record["workspace_root"] = desktop["workspace_hints"].get(identifier, "")

    sessions = sorted(records.values(), key=lambda item: (item["updated_at"], item["started_at"], item["id"]), reverse=True)
    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "privacy": "Metadata only. No prompts, responses, credentials, or tool payloads.",
        "provider_independent": True,
        "sources": {
            "session_index": str(codex_home / "session_index.jsonl"),
            "active_sessions": str(codex_home / "sessions"),
            "archived_sessions": str(codex_home / "archived_sessions"),
        },
        "session_count": len(sessions),
        "unreadable_session_files": unreadable,
        "desktop": {
            "pinned_count": len(desktop["pinned"]),
            "pinned_thread_ids": sorted(desktop["pinned"]),
            "project_order": desktop["project_order"],
            "workspace_roots": desktop["workspaces"],
        },
        "sessions": sessions,
    }


def write_catalog(catalog: dict, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def query_catalog(catalog: dict, query: str) -> list[dict]:
    needle = query.casefold()
    return [item for item in catalog["sessions"] if needle in "\n".join([
        item["id"], item["title"], item["desktop_description"], item["workspace_root"], item["updated_at"], item["started_at"], item["cwd"], *item["paths"],
    ]).casefold()]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex-home", type=Path, default=Path.home() / ".codex")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--refresh", action="store_true", help="write the catalog even without a query")
    parser.add_argument("--query", help="filter metadata records after rebuilding the catalog")
    args = parser.parse_args()

    output = args.output or args.codex_home / "conversation-history" / "catalog.json"
    catalog = build_catalog(args.codex_home)
    if args.refresh or args.query:
        write_catalog(catalog, output)
    if args.query:
        print(json.dumps(query_catalog(catalog, args.query), ensure_ascii=False, indent=2))
    else:
        print(f"Cataloged {catalog['session_count']} local conversations at {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

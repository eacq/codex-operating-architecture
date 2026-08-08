#!/usr/bin/env python3
"""Local Agent memory store for the Global Experience Agent.

The design is intentionally small and dependency-free: SQLite + FTS5 for exact
retrieval, TTL/supersession fields for temporal validity, and a frozen snapshot
renderer for stable prompt-prefix memory. Runtime data belongs under
.codex/project/agent-memory and is not tracked by Git.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1
MEMORY_TYPES = {
    "preference",
    "decision",
    "fix",
    "workflow",
    "context",
    "tool-result",
    "error",
    "candidate",
    "scaffold",
}
MEMORY_TYPE_ALIASES = {
    "lesson": "workflow",
    "procedure": "workflow",
}
MEMORY_LAYERS = {"working", "episodic", "semantic", "procedural", "frozen", "archived"}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_label(value: str, allowed: set[str], default: str) -> str:
    candidate = (value or default).strip().lower()
    return candidate if candidate in allowed else default


def normalize_memory_type(value: str) -> str:
    candidate = (value or "context").strip().lower()
    canonical = MEMORY_TYPE_ALIASES.get(candidate, candidate)
    if canonical not in MEMORY_TYPES:
        raise ValueError(f"unsupported memory type: {candidate}")
    return canonical


def connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA busy_timeout=5000")
    return conn


def init_db(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS memories (
            id TEXT PRIMARY KEY,
            agent_id TEXT NOT NULL,
            session_id TEXT NOT NULL,
            memory_type TEXT NOT NULL,
            layer TEXT NOT NULL,
            content TEXT NOT NULL,
            source TEXT NOT NULL,
            confidence REAL NOT NULL DEFAULT 0.5,
            priority INTEGER NOT NULL DEFAULT 5,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            valid_until TEXT,
            superseded_by TEXT,
            access_count INTEGER NOT NULL DEFAULT 0,
            last_accessed_at TEXT,
            tags_json TEXT NOT NULL DEFAULT '[]',
            evidence_json TEXT NOT NULL DEFAULT '[]',
            content_sha256 TEXT NOT NULL
        );

        CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
            id UNINDEXED,
            content,
            tags,
            source,
            tokenize='unicode61'
        );

        CREATE TABLE IF NOT EXISTS consolidation_runs (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            source_count INTEGER NOT NULL,
            archived_count INTEGER NOT NULL,
            frozen_count INTEGER NOT NULL,
            notes TEXT NOT NULL
        );

        CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
            INSERT INTO memories_fts(id, content, tags, source)
            VALUES (new.id, new.content, new.tags_json, new.source);
        END;
        CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
            DELETE FROM memories_fts WHERE id = old.id;
        END;
        CREATE TRIGGER IF NOT EXISTS memories_au AFTER UPDATE ON memories BEGIN
            DELETE FROM memories_fts WHERE id = old.id;
            INSERT INTO memories_fts(id, content, tags, source)
            VALUES (new.id, new.content, new.tags_json, new.source);
        END;
        """
    )
    conn.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?)",
        ("schema_version", str(SCHEMA_VERSION)),
    )
    conn.commit()


def json_list(values: list[str] | None) -> str:
    return json.dumps([v for v in (values or []) if v], ensure_ascii=False)


def row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
    data = dict(row)
    data["tags"] = json.loads(data.pop("tags_json") or "[]")
    data["evidence"] = json.loads(data.pop("evidence_json") or "[]")
    return data


def store(args: argparse.Namespace) -> dict[str, Any]:
    import hashlib

    now = utc_now()
    valid_until = None
    if args.ttl_days and args.ttl_days > 0:
        valid_until = (datetime.now(timezone.utc) + timedelta(days=args.ttl_days)).replace(microsecond=0).isoformat()
    memory_type = normalize_memory_type(args.memory_type)
    layer = normalize_label(args.layer, MEMORY_LAYERS, "episodic")
    content_hash = hashlib.sha256(args.content.encode("utf-8")).hexdigest()
    memory_id = args.id or f"mem-{content_hash[:16]}"
    tags = json_list(args.tags)
    evidence = json_list(args.evidence)
    with connect(args.db) as conn:
        init_db(conn)
        if args.supersedes:
            conn.execute(
                "UPDATE memories SET superseded_by = ?, updated_at = ? WHERE id = ? AND superseded_by IS NULL",
                (memory_id, now, args.supersedes),
            )
        conn.execute(
            """
            INSERT INTO memories(
                id, agent_id, session_id, memory_type, layer, content, source,
                confidence, priority, created_at, updated_at, valid_until,
                superseded_by, tags_json, evidence_json, content_sha256
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                agent_id=excluded.agent_id,
                session_id=excluded.session_id,
                memory_type=excluded.memory_type,
                layer=excluded.layer,
                content=excluded.content,
                source=excluded.source,
                confidence=excluded.confidence,
                priority=excluded.priority,
                updated_at=excluded.updated_at,
                valid_until=excluded.valid_until,
                tags_json=excluded.tags_json,
                evidence_json=excluded.evidence_json,
                content_sha256=excluded.content_sha256
            """,
            (
                memory_id,
                args.agent_id,
                args.session_id,
                memory_type,
                layer,
                args.content,
                args.source,
                args.confidence,
                args.priority,
                now,
                now,
                valid_until,
                tags,
                evidence,
                content_hash,
            ),
        )
        conn.commit()
    return {"result": "memory-stored", "id": memory_id, "type": memory_type, "layer": layer, "content_sha256": content_hash}


def search(args: argparse.Namespace) -> dict[str, Any]:
    now = utc_now()
    limit = max(1, min(args.limit, 50))
    with connect(args.db) as conn:
        init_db(conn)
        try:
            rows = conn.execute(
                """
                SELECT m.*, bm25(memories_fts) AS rank
                FROM memories_fts
                JOIN memories m ON m.id = memories_fts.id
                WHERE memories_fts MATCH ?
                  AND m.superseded_by IS NULL
                  AND (m.valid_until IS NULL OR m.valid_until > ?)
                ORDER BY rank, m.priority DESC, m.updated_at DESC
                LIMIT ?
                """,
                (args.query, now, limit),
            ).fetchall()
        except sqlite3.OperationalError:
            like = f"%{args.query}%"
            rows = conn.execute(
                """
                SELECT m.*, 0.0 AS rank
                FROM memories m
                WHERE (m.content LIKE ? OR m.tags_json LIKE ? OR m.source LIKE ?)
                  AND m.superseded_by IS NULL
                  AND (m.valid_until IS NULL OR m.valid_until > ?)
                ORDER BY m.priority DESC, m.updated_at DESC
                LIMIT ?
                """,
                (like, like, like, now, limit),
            ).fetchall()
        ids = [row["id"] for row in rows]
        if ids:
            conn.executemany(
                "UPDATE memories SET access_count = access_count + 1, last_accessed_at = ? WHERE id = ?",
                [(now, mid) for mid in ids],
            )
            conn.commit()
    return {"result": "memory-search-results", "query_sha256": hash_query(args.query), "count": len(rows), "records": [row_to_dict(row) for row in rows]}


def hash_query(query: str) -> str:
    import hashlib

    return hashlib.sha256((query or "").encode("utf-8")).hexdigest()


def consolidate(args: argparse.Namespace) -> dict[str, Any]:
    now = datetime.now(timezone.utc).replace(microsecond=0)
    now_text = now.isoformat()
    stale_before = (now - timedelta(days=args.stale_days)).isoformat()
    freeze_before = (now - timedelta(days=args.freeze_inactivity_days)).isoformat()
    run_id = f"consolidation-{now.strftime('%Y%m%dT%H%M%SZ')}"
    with connect(args.db) as conn:
        init_db(conn)
        source_count = conn.execute("SELECT COUNT(*) FROM memories WHERE superseded_by IS NULL").fetchone()[0]
        archived = conn.execute(
            """
            UPDATE memories
            SET layer='archived', updated_at=?
            WHERE superseded_by IS NULL
              AND layer NOT IN ('frozen', 'archived')
              AND COALESCE(last_accessed_at, created_at) < ?
            """,
            (now_text, stale_before),
        ).rowcount
        frozen = conn.execute(
            """
            UPDATE memories
            SET layer='frozen', updated_at=?
            WHERE superseded_by IS NULL
              AND layer IN ('semantic', 'procedural')
              AND priority >= ?
              AND updated_at < ?
            """,
            (now_text, args.freeze_priority, freeze_before),
        ).rowcount
        conn.execute(
            "INSERT INTO consolidation_runs(id, created_at, source_count, archived_count, frozen_count, notes) VALUES (?, ?, ?, ?, ?, ?)",
            (run_id, now_text, source_count, archived, frozen, args.notes or "manual consolidation"),
        )
        conn.commit()
    return {"result": "memory-consolidated", "id": run_id, "source_count": source_count, "archived_count": archived, "frozen_count": frozen}


def snapshot(args: argparse.Namespace) -> dict[str, Any]:
    with connect(args.db) as conn:
        init_db(conn)
        rows = conn.execute(
            """
            SELECT *
            FROM memories
            WHERE superseded_by IS NULL
              AND (valid_until IS NULL OR valid_until > ?)
              AND layer IN ('frozen', 'semantic', 'procedural')
            ORDER BY
              CASE layer WHEN 'frozen' THEN 0 WHEN 'procedural' THEN 1 ELSE 2 END,
              priority DESC,
              updated_at DESC
            LIMIT ?
            """,
            (utc_now(), max(1, min(args.limit, 100))),
        ).fetchall()
    lines = [
        "# Global Experience Agent Memory Snapshot",
        "",
        "Stable memory prefix. Dynamic task context belongs after this block.",
        "",
    ]
    for row in rows:
        tags = ", ".join(json.loads(row["tags_json"] or "[]"))
        lines.append(f"- [{row['layer']}/{row['memory_type']}/p{row['priority']}] {row['content']} (id={row['id']}; source={row['source']}; tags={tags})")
    text = "\n".join(lines).rstrip() + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    return {"result": "memory-snapshot-rendered", "count": len(rows), "output": str(args.output) if args.output else None, "text": text if args.include_text else None}


def stats(args: argparse.Namespace) -> dict[str, Any]:
    with connect(args.db) as conn:
        init_db(conn)
        total = conn.execute("SELECT COUNT(*) FROM memories").fetchone()[0]
        active = conn.execute("SELECT COUNT(*) FROM memories WHERE superseded_by IS NULL AND (valid_until IS NULL OR valid_until > ?)", (utc_now(),)).fetchone()[0]
        by_layer = {row["layer"]: row["count"] for row in conn.execute("SELECT layer, COUNT(*) AS count FROM memories GROUP BY layer")}
        by_type = {row["memory_type"]: row["count"] for row in conn.execute("SELECT memory_type, COUNT(*) AS count FROM memories GROUP BY memory_type")}
    return {"result": "memory-stats", "total": total, "active": active, "by_layer": by_layer, "by_type": by_type}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, required=True)
    sub = parser.add_subparsers(dest="command", required=True)

    init = sub.add_parser("init")
    init.set_defaults(func=lambda args: init_result(args))

    st = sub.add_parser("store")
    st.add_argument("--id")
    st.add_argument("--agent-id", default="global-experience-agent")
    st.add_argument("--session-id", default="unknown-session")
    st.add_argument("--type", dest="memory_type", default="context")
    st.add_argument("--layer", default="episodic")
    st.add_argument("--content", required=True)
    st.add_argument("--source", default="agent-runtime")
    st.add_argument("--confidence", type=float, default=0.7)
    st.add_argument("--priority", type=int, default=5)
    st.add_argument("--ttl-days", type=int, default=0)
    st.add_argument("--supersedes")
    st.add_argument("--tag", dest="tags", action="append")
    st.add_argument("--evidence", action="append")
    st.set_defaults(func=store)

    se = sub.add_parser("search")
    se.add_argument("--query", required=True)
    se.add_argument("--limit", type=int, default=10)
    se.set_defaults(func=search)

    co = sub.add_parser("consolidate")
    co.add_argument("--stale-days", type=int, default=30)
    co.add_argument("--freeze-inactivity-days", type=int, default=3)
    co.add_argument("--freeze-priority", type=int, default=8)
    co.add_argument("--notes", default="")
    co.set_defaults(func=consolidate)

    sn = sub.add_parser("snapshot")
    sn.add_argument("--limit", type=int, default=50)
    sn.add_argument("--output", type=Path)
    sn.add_argument("--include-text", action="store_true")
    sn.set_defaults(func=snapshot)

    stat = sub.add_parser("stats")
    stat.set_defaults(func=stats)
    return parser


def init_result(args: argparse.Namespace) -> dict[str, Any]:
    with connect(args.db) as conn:
        init_db(conn)
    return {"result": "memory-initialized", "db": str(args.db), "schema_version": SCHEMA_VERSION}


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        result = args.func(args)
        print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
        return 0
    except Exception as exc:  # pragma: no cover - command boundary
        print(json.dumps({"result": "memory-error", "error": str(exc)}, ensure_ascii=False, separators=(",", ":")))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

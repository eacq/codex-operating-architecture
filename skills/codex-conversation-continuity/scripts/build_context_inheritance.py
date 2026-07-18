#!/usr/bin/env python3
"""Build a bounded, redacted compaction-inheritance input from a local session."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


SECRET_PATTERNS = (
    (re.compile(r"(?i)(api[_-]?key|token|secret|password|cookie|authorization)\\s*[:=]\\s*[^\\s`]+"), r"\\1=[REDACTED]"),
    (re.compile(r"(?i)bearer\\s+[A-Za-z0-9._\\-]+"), "Bearer [REDACTED]"),
    (re.compile(r"sk-[A-Za-z0-9_\\-]{12,}"), "[REDACTED_OPENAI_KEY]"),
)


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
        for line in handle:
            try:
                item = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(item, dict):
                records.append(item)
    return records


def redact(text: str) -> str:
    for pattern, replacement in SECRET_PATTERNS:
        text = pattern.sub(replacement, text)
    return text


def clean_lines(text: str, limit: int) -> str:
    """Keep semantic headings/bullets from an already-compressed text block."""
    text = redact(text.replace("\r", ""))
    marker = "## Handoff Summary"
    if marker in text:
        text = text.split(marker, 1)[1]
    selected: list[str] = []
    seen: set[str] = set()
    for raw in text.split("\n"):
        line = re.sub(r"\\s+", " ", raw).strip()
        if not line or line.startswith("Another language model started"):
            continue
        useful = (
            line.startswith("#")
            or line.startswith(("- ", "* ", "1. ", "2. ", "3. "))
            or re.match(r"^(Current|User|Source|Verification|Constraint|Decision|Status|Scope|Repair|QA|Path|Hash|Rule)\\b", line, re.I)
        )
        if not useful or line.casefold() in seen:
            continue
        if sum(len(item) + 1 for item in selected) + len(line) > limit:
            break
        selected.append(line)
        seen.add(line.casefold())
    if not selected:
        selected.append(text.strip()[:limit])
    return "\n".join(selected).strip()


def text_file(path: Path | None) -> str:
    if path is None:
        return ""
    return path.read_text(encoding="utf-8-sig", errors="replace")


def session_id(records: list[dict[str, Any]]) -> str:
    for record in records:
        if record.get("type") != "session_meta":
            continue
        payload = record.get("payload", {})
        if isinstance(payload, dict):
            return str(payload.get("id") or payload.get("session_id") or "unknown")
    return "unknown"


def compactions(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for record in records:
        if record.get("type") != "compacted":
            continue
        payload = record.get("payload", {})
        if not isinstance(payload, dict) or not isinstance(payload.get("message"), str):
            continue
        replacement = payload.get("replacement_history")
        replacement_count = len(replacement) if isinstance(replacement, list) else 0
        result.append({
            "window_number": payload.get("window_number"),
            "previous_window_id": payload.get("previous_window_id", ""),
            "window_id": payload.get("window_id", ""),
            "first_window_id": payload.get("first_window_id", ""),
            "raw_predecessor_message_count": replacement_count,
            "summary": payload["message"],
        })
    return result


def render(args: argparse.Namespace, records: list[dict[str, Any]]) -> str:
    sid = session_id(records)
    lineage = compactions(records)
    current_before = clean_lines(text_file(args.current_before), args.per_block_chars) if args.current_before else ""
    current_after = clean_lines(text_file(args.current_after), args.per_block_chars) if args.current_after else ""
    blocks: list[str] = []
    for item in lineage:
        summary = clean_lines(item["summary"], args.per_block_chars)
        blocks.append(
            "### Historical compaction window {0}\n"
            "- Previous window: `{1}`\n"
            "- Replacement window: `{2}`\n"
            "- Raw predecessor messages inspected only transiently: {3}\n\n{4}".format(
                item["window_number"],
                item["previous_window_id"],
                item["window_id"],
                item["raw_predecessor_message_count"],
                summary,
            )
        )
    if current_before:
        blocks.append("### Current pre-compression context\n" + current_before)
    if current_after:
        blocks.append("### Current post-recovery context\n" + current_after)

    def header(omitted_count: int) -> str:
        return f"""# Inheritance Compaction Input

- Source session: `{sid}`
- Compaction windows discovered: {len(lineage)}
- Character budget: {args.max_chars}
- Omitted blocks due to budget: {omitted_count}
- Privacy: raw replacement histories, prompts, tool payloads, encrypted reasoning, and credentials are excluded.

## Required successor-summary rules

1. Resolve conflicts in this order: current user instruction, verified current project pointer/hash, current context, historical compaction summaries.
2. Keep only decisions, constraints, verified artifacts, open risks, and the next action; deduplicate repeated facts.
3. Preserve source session/window IDs for claims that depend on historical context.
4. Do not promote an interrupted branch or a raw-history fragment merely because it is newer.
5. Produce one bounded successor summary; do not append the raw lineage to future project knowledge.

## Inputs for this compression pass

"""

    # Allocate before rendering. A final whole-document slice could remove
    # old blocks while leaving the omission count at zero, which would make
    # the handoff inaccurate. Keep chronological order and report trailing
    # blocks that cannot fit.
    for included in range(len(blocks), -1, -1):
        omitted = len(blocks) - included
        prefix = header(omitted)
        if included == 0:
            return (prefix.rstrip() + "\n")[:args.max_chars]
        separator_chars = 2 * (included - 1)
        available = args.max_chars - len(prefix) - separator_chars - 1
        if available < included:
            continue
        per_block_cap = available // included
        # A partial heading such as "### His" is not an inherited context
        # segment.  Count that block as omitted instead of claiming retention.
        if per_block_cap < 80:
            continue
        body = [block[:per_block_cap].rstrip() for block in blocks[:included]]
        result = prefix + "\n\n".join(body).strip() + "\n"
        if len(result) <= args.max_chars and len(body) == included:
            return result
    return (header(len(blocks)).rstrip() + "\n")[:args.max_chars]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("session", type=Path, help="Matched local session JSONL file.")
    parser.add_argument("--current-before", type=Path, help="Redacted current context before recovery/compaction.")
    parser.add_argument("--current-after", type=Path, help="Redacted current context after recovery/compaction.")
    parser.add_argument("--out", type=Path, required=True, help="Private derived Markdown output.")
    parser.add_argument("--max-chars", type=int, default=14000)
    parser.add_argument("--per-block-chars", type=int, default=1400)
    args = parser.parse_args()
    if args.max_chars < 1000 or args.per_block_chars < 200:
        parser.error("--max-chars must be >= 1000 and --per-block-chars must be >= 200")
    if not args.session.exists():
        parser.error(f"Session not found: {args.session}")
    for path in (args.current_before, args.current_after):
        if path is not None and not path.exists():
            parser.error(f"Context file not found: {path}")
    output = render(args, read_jsonl(args.session))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(output, encoding="utf-8")
    print(json.dumps({"out": str(args.out), "characters": len(output), "session": session_id(read_jsonl(args.session))}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

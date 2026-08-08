#!/usr/bin/env python3
"""Scan a local private book shelf and produce safe derived Agent-learning evidence.

The script intentionally does not copy source text into tracked artifacts. It
returns counts, hashes, parse status, and reusable Agent optimization lenses.
Information unit: Agent Skill Evolution Optimization.
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import sys
import time
import zipfile
from pathlib import Path

KEYWORDS = {
    "technology": ["技术", "technology"],
    "evolution": ["进化", "演化", "evolution"],
    "combination": ["组合", "combin"],
    "recursive": ["递归", "recursive"],
    "phenomenon": ["现象", "phenomen"],
    "domain": ["领域", "domain"],
    "module": ["模块", "组件", "component", "module"],
    "model": ["模型", "model"],
    "thinking": ["思考", "思维", "thinking"],
    "complexity": ["复杂", "complex"],
    "system": ["系统", "system"],
    "decision": ["决策", "decision"],
    "bias": ["偏差", "bias"],
    "intuition": ["直觉", "intuition"],
    "analogy": ["类比", "analogy"],
    "pyramid": ["金字塔", "pyramid"],
    "principle": ["原理", "principle"],
    "structure": ["结构", "structure"],
    "evidence": ["证据", "evidence"],
    "risk": ["风险", "risk"],
    "feedback": ["反馈", "feedback"],
    "emergence": ["涌现", "emerg"],
    "uncertainty": ["不确定", "uncertain"],
    "abstraction": ["抽象", "abstraction"],
}



def sha256_file(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1048576), b""):
            h.update(chunk)
    return h.hexdigest()

def clean_html(raw):
    raw = re.sub(r"<script.*?</script>|<style.*?</style>", " ", raw, flags=re.S|re.I)
    text = re.sub(r"<[^>]+>", " ", raw)
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip()

def parse_epub(path):
    text_parts = []
    files = 0
    try:
        with zipfile.ZipFile(path) as zf:
            for name in zf.namelist():
                if not name.lower().endswith((".xhtml", ".html", ".htm")):
                    continue
                try:
                    raw = zf.read(name).decode("utf-8", errors="ignore")
                except Exception:
                    continue
                text = clean_html(raw)
                if len(text) >= 80:
                    files += 1
                    text_parts.append(text)
    except Exception as exc:
        return "", 0, 0, f"epub-parse-error:{type(exc).__name__}"
    joined = "\n".join(text_parts)
    return joined, files, len(joined), None

def parse_pdf_metadata(path):
    """Extract text from a PDF using pypdf. Returns (text, page_count, char_count, error)."""
    try:
        from pypdf import PdfReader
    except ImportError:
        return "", 0, 0, "pdf-text-parser-unavailable"
    try:
        reader = PdfReader(path)
        pages = len(reader.pages)
        parts = []
        for page in reader.pages:
            text = page.extract_text()
            if text:
                parts.append(text)
        joined = "\n".join(parts)
        return joined, pages, len(joined), None
    except Exception as exc:
        return "", 0, 0, f"pdf-parse-error:{type(exc).__name__}"

def count_keywords(text, title):
    haystack = (title + "\n" + text).lower()
    result = {}
    for key, terms in KEYWORDS.items():
        total = 0
        for term in terms:
            total += haystack.count(term.lower())
        if total:
            result[key] = total
    return dict(sorted(result.items(), key=lambda i: (-i[1], i[0])))

def title_lenses(title):
    lenses = []
    rules = [
        ("技术的本质", "combinatorial-recursive-capability-evolution"),
        ("复杂性", "complex-systems-feedback-and-emergence"),
        ("快与慢", "fast-slow-routing-and-bias-checks"),
        ("Thinking, Fast and Slow", "fast-slow-routing-and-bias-checks"),
        ("模型思维", "multi-model-triangulation"),
        ("Model Thinker", "multi-model-triangulation"),
        ("深度思维", "deep-structure-first-principles"),
        ("直觉泵", "thought-experiment-counterexample-probes"),
        ("表象与本质", "analogy-and-abstraction-transfer"),
        ("六顶思考帽", "separated-review-roles"),
        ("金字塔原理", "top-down-pyramid-communication"),
    ]
    for needle, lens in rules:
        if needle.lower() in title.lower():
            lenses.append(lens)
    return lenses

def keyword_lenses(counts):
    lenses = []
    if counts.get("model", 0) >= 20:
        lenses.append("model-selection-before-action")
    if counts.get("complexity", 0) >= 20 or counts.get("feedback", 0) >= 10:
        lenses.append("feedback-loop-risk-review")
    if counts.get("thinking", 0) >= 20 or counts.get("decision", 0) >= 10:
        lenses.append("deliberate-reasoning-checkpoint")
    if counts.get("analogy", 0) >= 5 or counts.get("abstraction", 0) >= 5:
        lenses.append("analogy-transfer-with-boundary-check")
    if counts.get("structure", 0) >= 20 or counts.get("principle", 0) >= 20:
        lenses.append("structure-and-principle-extraction")
    return lenses

def scan_books(book_root):
    started = time.time()
    books = []
    aggregate_counts = {}
    for path in sorted(book_root.iterdir(), key=lambda p: p.name):
        if not path.is_file() or path.suffix.lower() not in {".epub", ".pdf", ".txt", ".md"}:
            continue
        error = None
        strategy = "metadata"
        text = ""
        text_files = 0
        readable_chars = 0
        if path.suffix.lower() == ".epub":
            strategy = "epub-stdlib"
            text, text_files, readable_chars, error = parse_epub(path)
        elif path.suffix.lower() == ".pdf":
            strategy = "pdf-pypdf"
            text, text_files, readable_chars, error = parse_pdf_metadata(path)
        else:
            strategy = "plain-text"
            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
                readable_chars = len(text)
                text_files = 1
            except Exception as exc:
                error = f"text-parse-error:{type(exc).__name__}"
        counts = count_keywords(text, path.name)
        for key, value in counts.items():
            aggregate_counts[key] = aggregate_counts.get(key, 0) + value
        lenses = sorted(set(title_lenses(path.name) + keyword_lenses(counts)))
        books.append({
            "path": str(path).replace("\\", "/"),
            "name": path.name,
            "extension": path.suffix.lower(),
            "bytes": path.stat().st_size,
            "sha256": sha256_file(path),
            "parse_strategy": strategy,
            "text_units": text_files,
            "readable_chars": readable_chars,
            "status": "parsed" if readable_chars > 0 else "degraded",
            "error": error,
            "keyword_counts": counts,
            "agent_lenses": lenses,
        })
    all_lenses = sorted({lens for book in books for lens in book["agent_lenses"]})
    return {
        "schema_version": 1,
        "model": "experience-book-shelf-learning",
        "book_root": str(book_root).replace("\\", "/"),
        "privacy": "local-private-source; do not commit or publish source books",
        "books_total": len(books),
        "parsed_books": sum(1 for b in books if b["status"] == "parsed"),
        "degraded_books": sum(1 for b in books if b["status"] == "degraded"),
        "readable_chars": sum(int(b["readable_chars"]) for b in books),
        "aggregate_keyword_counts": dict(sorted(aggregate_counts.items(), key=lambda i: (-i[1], i[0]))),
        "cross_book_agent_lenses": all_lenses,
        "agent_optimization_summary": [
            "use multiple mental models before owner or skill mutation",
            "separate fast routing from slow validation and bias checks",
            "compose from existing Agent components before top-level growth",
            "make recursive component boundaries and owner gates explicit",
            "add structured review roles for facts, risks, alternatives, value, and process",
            "present outcomes top-down while keeping evidence and caveats inspectable",
            "PDF text parsing now available via pypdf; re-run after book shelf changes",
        ],
        "books": books,
        "duration_ms": int((time.time() - started) * 1000),
    }

def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--book-root", required=True)
    parser.add_argument("--output")
    args = parser.parse_args(argv)
    book_root = Path(args.book_root)
    if not book_root.exists() or not book_root.is_dir():
        raise SystemExit(f"Book root does not exist: {book_root}")
    result = scan_books(book_root)
    payload = json.dumps(result, ensure_ascii=False, indent=2)
    if args.output:
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

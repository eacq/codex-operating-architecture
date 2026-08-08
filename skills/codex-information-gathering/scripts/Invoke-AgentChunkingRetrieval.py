#!/usr/bin/env python3
"""Agent chunking, retrieval, rerank, and calibration baseline.

Stdlib-only adaptation of feynman-build-workshop episode 04. It provides:
- recursive/fixed chunking over plain text or parsed Document JSON;
- JSONL chunk input;
- BM25-lite lexical retrieval with deterministic reranking;
- temperature-scaled confidence calibration plus refusal thresholding;
- recall@k, MRR, answer-accuracy, ECE, Brier, false-accept, and false-refusal evaluation.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import statistics
from collections import Counter
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


TOKEN_RE = re.compile(r"[A-Za-z0-9_]+")


@dataclass
class Chunk:
    id: str
    text: str
    metadata: dict[str, Any]


def tokenize(text: str) -> list[str]:
    return [m.group(0).lower() for m in TOKEN_RE.finditer(text or "")]


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8-sig") as handle:
        for line in handle:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def chunk_words(words: list[str], chunk_size: int, overlap: int) -> list[str]:
    if chunk_size <= 0:
        raise ValueError("chunk_size must be positive")
    overlap = max(0, min(overlap, chunk_size - 1))
    chunks: list[str] = []
    step = chunk_size - overlap
    for start in range(0, len(words), step):
        part = words[start : start + chunk_size]
        if part:
            chunks.append(" ".join(part))
        if start + chunk_size >= len(words):
            break
    return chunks


def recursive_chunk_text(text: str, chunk_size: int, overlap: int) -> list[str]:
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    output: list[str] = []
    current: list[str] = []

    def flush_current() -> None:
        nonlocal current
        if current:
            output.append("\n\n".join(current).strip())
            current = []

    for paragraph in paragraphs or [text]:
        words = paragraph.split()
        if len(words) > chunk_size:
            flush_current()
            output.extend(chunk_words(words, chunk_size, overlap))
            continue
        prospective = " ".join((" ".join(current), paragraph)).split()
        if current and len(prospective) > chunk_size:
            flush_current()
        current.append(paragraph)
    flush_current()

    if overlap > 0 and len(output) > 1:
        enriched: list[str] = []
        previous_tail: list[str] = []
        for chunk in output:
            words = chunk.split()
            merged = previous_tail + words
            enriched.append(" ".join(merged))
            previous_tail = words[-overlap:]
        output = enriched
    return [chunk for chunk in output if chunk.strip()]


def load_chunks_from_path(path: Path, strategy: str, chunk_size: int, overlap: int) -> list[Chunk]:
    suffix = path.suffix.lower()
    if suffix == ".jsonl":
        rows = read_jsonl(path)
        return [
            Chunk(
                id=str(row.get("id") or f"c{index:04d}"),
                text=str(row.get("text") or ""),
                metadata=dict(row.get("metadata") or {}),
            )
            for index, row in enumerate(rows, start=1)
            if str(row.get("text") or "").strip()
        ]

    raw = path.read_text(encoding="utf-8-sig")
    parsed: Any = None
    if suffix == ".json":
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = None
    if isinstance(parsed, dict) and isinstance(parsed.get("chunks"), list):
        chunks: list[Chunk] = []
        for index, row in enumerate(parsed["chunks"], start=1):
            if not isinstance(row, dict):
                continue
            text = str(row.get("text") or "")
            if not text.strip():
                continue
            metadata = dict(row.get("metadata") or {})
            for key in ("page", "table_id", "line_no", "source_path"):
                if key in row and row[key] is not None:
                    metadata[key] = row[key]
            chunks.append(Chunk(id=str(row.get("id") or f"c{index:04d}"), text=text, metadata=metadata))
        return chunks

    if strategy == "fixed":
        parts = chunk_words(raw.split(), chunk_size, overlap)
    else:
        parts = recursive_chunk_text(raw, chunk_size, overlap)
    return [Chunk(id=f"c{index:04d}", text=part, metadata={"source_path": str(path)}) for index, part in enumerate(parts, start=1)]


def build_idf(chunks: list[Chunk]) -> dict[str, float]:
    df: Counter[str] = Counter()
    for chunk in chunks:
        df.update(set(tokenize(chunk.text)))
    total = max(1, len(chunks))
    return {term: math.log(1 + (total - count + 0.5) / (count + 0.5)) for term, count in df.items()}


def bm25_scores(query: str, chunks: list[Chunk]) -> list[dict[str, Any]]:
    query_terms = tokenize(query)
    if not query_terms:
        return []
    idf = build_idf(chunks)
    tokenized = [tokenize(chunk.text) for chunk in chunks]
    avg_len = statistics.mean([len(tokens) for tokens in tokenized] or [1])
    k1 = 1.2
    b = 0.75
    phrase = " ".join(query_terms)
    rows: list[dict[str, Any]] = []
    for chunk, terms in zip(chunks, tokenized):
        counts = Counter(terms)
        length = max(1, len(terms))
        score = 0.0
        for term in query_terms:
            freq = counts.get(term, 0)
            if freq == 0:
                continue
            denom = freq + k1 * (1 - b + b * length / max(avg_len, 1))
            score += idf.get(term, 0.0) * (freq * (k1 + 1) / denom)
        coverage = len(set(query_terms) & set(terms)) / max(1, len(set(query_terms)))
        phrase_match = bool(phrase and phrase in " ".join(terms))
        if phrase_match:
            score += 1.0
        score += coverage * 0.25
        rows.append({"id": chunk.id, "score": round(score, 6), "coverage": round(coverage, 6), "phrase_match": phrase_match})
    rows.sort(key=lambda row: (-row["score"], row["id"]))
    return rows


def sigmoid(value: float) -> float:
    if value >= 50:
        return 1.0
    if value <= -50:
        return 0.0
    return 1.0 / (1.0 + math.exp(-value))


def calibrated_confidence(row: dict[str, Any], max_score: float, temperature: float) -> float:
    safe_temperature = max(0.05, temperature)
    normalized_score = float(row["score"]) / max(abs(max_score), 1e-9)
    phrase_bonus = 0.75 if row.get("phrase_match") else 0.0
    logit = (normalized_score * 3.0) + (float(row["coverage"]) * 2.0) + phrase_bonus - 2.75
    return round(sigmoid(logit / safe_temperature), 6)


def retrieve(query: str, chunks: list[Chunk], top_k: int, temperature: float, refusal_threshold: float) -> list[dict[str, Any]]:
    ranked = bm25_scores(query, chunks)
    by_id = {chunk.id: chunk for chunk in chunks}
    max_score = max([float(row["score"]) for row in ranked] or [0.0])
    output: list[dict[str, Any]] = []
    for row in ranked[:top_k]:
        chunk = by_id[row["id"]]
        confidence = calibrated_confidence(row, max_score, temperature)
        output.append(
            {
                "id": chunk.id,
                "score": row["score"],
                "coverage": row["coverage"],
                "phrase_match": row.get("phrase_match", False),
                "calibrated_confidence": confidence,
                "decision": "accept" if confidence >= refusal_threshold else "refuse",
                "text": chunk.text,
                "metadata": chunk.metadata,
            }
        )
    return output


def recall_at_k(queries: list[dict[str, Any]], retrieved: dict[str, list[str]], k: int) -> float:
    recalls: list[float] = []
    for query in queries:
        relevant = set(query.get("relevant_chunk_ids") or [])
        if not relevant:
            continue
        top = set(retrieved.get(str(query.get("id")), [])[:k])
        recalls.append(len(relevant & top) / len(relevant))
    return statistics.mean(recalls) if recalls else 0.0


def mrr(queries: list[dict[str, Any]], retrieved: dict[str, list[str]]) -> float:
    scores: list[float] = []
    for query in queries:
        relevant = set(query.get("relevant_chunk_ids") or [])
        if not relevant:
            continue
        ranked = retrieved.get(str(query.get("id")), [])
        for index, chunk_id in enumerate(ranked, start=1):
            if chunk_id in relevant:
                scores.append(1.0 / index)
                break
        else:
            scores.append(0.0)
    return statistics.mean(scores) if scores else 0.0


def answer_accuracy(queries: list[dict[str, Any]], answers: dict[str, str]) -> float:
    total = 0
    correct = 0
    for query in queries:
        expected = str(query.get("expected_answer") or "").lower()
        if not expected:
            continue
        total += 1
        actual = answers.get(str(query.get("id")), "").lower()
        if expected in actual:
            correct += 1
    return correct / total if total else 0.0


def expected_calibration_error(confidence_labels: list[tuple[float, int]], bins: int = 5) -> float:
    if not confidence_labels:
        return 0.0
    total = len(confidence_labels)
    ece = 0.0
    for index in range(bins):
        low = index / bins
        high = (index + 1) / bins
        bucket = [(conf, label) for conf, label in confidence_labels if (conf >= low and (conf < high or index == bins - 1))]
        if not bucket:
            continue
        avg_conf = statistics.mean(conf for conf, _ in bucket)
        accuracy = statistics.mean(label for _, label in bucket)
        ece += (len(bucket) / total) * abs(avg_conf - accuracy)
    return ece


def brier_score(confidence_labels: list[tuple[float, int]]) -> float:
    if not confidence_labels:
        return 0.0
    return statistics.mean((conf - label) ** 2 for conf, label in confidence_labels)


def evaluate(queries: list[dict[str, Any]], chunks: list[Chunk], top_k: int, temperature: float, refusal_threshold: float) -> dict[str, Any]:
    retrieved: dict[str, list[str]] = {}
    answers: dict[str, str] = {}
    decisions: dict[str, str] = {}
    confidence_labels: list[tuple[float, int]] = []
    false_accepts = 0
    false_refusals = 0
    answerable_count = 0
    unanswerable_count = 0
    for query in queries:
        query_id = str(query.get("id"))
        ranked = retrieve(str(query.get("question") or ""), chunks, max(top_k, 10), temperature, refusal_threshold)
        retrieved[query_id] = [row["id"] for row in ranked]
        top = ranked[0] if ranked else None
        decisions[query_id] = str(top.get("decision")) if top else "refuse"
        answers[query_id] = top["text"] if top and top.get("decision") == "accept" else ""
        relevant = set(query.get("relevant_chunk_ids") or [])
        label = 1 if top and top["id"] in relevant else 0
        confidence = float(top.get("calibrated_confidence", 0.0)) if top else 0.0
        confidence_labels.append((confidence, label))
        if relevant:
            answerable_count += 1
            if top and top["id"] in relevant and top.get("decision") == "refuse":
                false_refusals += 1
        else:
            unanswerable_count += 1
            if top and top.get("decision") == "accept":
                false_accepts += 1
    return {
        "num_queries": len(queries),
        "recall_at_1": round(recall_at_k(queries, retrieved, 1), 4),
        "recall_at_3": round(recall_at_k(queries, retrieved, 3), 4),
        "recall_at_5": round(recall_at_k(queries, retrieved, 5), 4),
        "mrr": round(mrr(queries, retrieved), 4),
        "answer_accuracy": round(answer_accuracy(queries, answers), 4),
        "expected_calibration_error": round(expected_calibration_error(confidence_labels), 4),
        "brier_score": round(brier_score(confidence_labels), 4),
        "false_accept_rate": round(false_accepts / unanswerable_count, 4) if unanswerable_count else 0.0,
        "false_refusal_rate": round(false_refusals / answerable_count, 4) if answerable_count else 0.0,
        "retrieved": retrieved,
        "decisions": decisions,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Agent chunking and retrieval baseline")
    parser.add_argument("--input", dest="input_path", help="Text, parsed Document JSON, or chunks JSONL")
    parser.add_argument("--chunks", dest="chunks_path", help="Chunks JSONL")
    parser.add_argument("--queries", dest="queries_path", help="Queries JSONL")
    parser.add_argument("--query", help="Single query")
    parser.add_argument("--strategy", choices=["recursive", "fixed"], default="recursive")
    parser.add_argument("--chunk-size", type=int, default=160)
    parser.add_argument("--overlap", type=int, default=24)
    parser.add_argument("--top-k", type=int, default=5)
    parser.add_argument("--temperature", type=float, default=1.0)
    parser.add_argument("--refusal-threshold", type=float, default=0.35)
    parser.add_argument("--output", dest="output_path")
    args = parser.parse_args()

    source_path = Path(args.chunks_path or args.input_path) if (args.chunks_path or args.input_path) else None
    if source_path is None:
        raise SystemExit("--input or --chunks is required")
    chunks = load_chunks_from_path(source_path, args.strategy, args.chunk_size, args.overlap)
    if not chunks:
        raise SystemExit("no chunks available for retrieval")

    result: dict[str, Any] = {
        "model": "agent-chunking-retrieval",
        "strategy": args.strategy,
        "retrieval_method": "bm25-lite-lexical-rerank-calibrated",
        "rerank_method": "deterministic lexical cross-feature rerank",
        "calibration": {
            "method": "temperature-scaled-logistic",
            "temperature": args.temperature,
            "refusal_threshold": args.refusal_threshold,
        },
        "layer": "L1",
        "source": str(source_path),
        "chunk_count": len(chunks),
        "chunks": [asdict(chunk) for chunk in chunks],
        "retrieval": [],
        "evaluation": None,
        "gated_candidates": ["raptor", "graphrag", "ontology-rag", "external-reranker", "embedding-provider"],
    }

    if args.query:
        result["retrieval"] = retrieve(args.query, chunks, args.top_k, args.temperature, args.refusal_threshold)
        result["decision"] = result["retrieval"][0]["decision"] if result["retrieval"] else "refuse"
    if args.queries_path:
        queries = read_jsonl(Path(args.queries_path))
        result["evaluation"] = evaluate(queries, chunks, args.top_k, args.temperature, args.refusal_threshold)

    if args.output_path:
        Path(args.output_path).write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Owner-routed document parse pipeline for the Global Experience Agent.

This is a lightweight, stdlib-first adaptation of the seven-layer document
parse method learned from LesterYu0/feynman-build-workshop episode 03.  It is
not a dependency installer and it does not silently call OCR, VLM, MinerU, or
paid services.  Heavy parsers remain explicit owner-gated capabilities.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import time
import zipfile
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET


NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}


@dataclass
class Chunk:
    text: str
    page: int = 0
    bbox: list[float] | None = None
    table_id: str | None = None
    line_no: int | None = None
    confidence: float = 1.0
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass
class ParsedDocument:
    file_path: str
    file_type: str
    strategy: str
    chunks: list[Chunk] = field(default_factory=list)
    parse_time_ms: int = 0
    page_count: int = 0
    error: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def text(self) -> str:
        return "\n".join(chunk.text for chunk in self.chunks if chunk.text)

    def validate(self, keywords: list[str]) -> dict[str, Any]:
        full_text = self.text
        missing = [keyword for keyword in keywords if keyword not in full_text]
        pages = sorted({chunk.page for chunk in self.chunks if chunk.page})
        table_chunks = [chunk for chunk in self.chunks if chunk.table_id]
        bbox_chunks = [chunk for chunk in self.chunks if chunk.bbox]
        return {
            "passed": not missing and self.error is None,
            "found_keywords": len(keywords) - len(missing),
            "total_keywords": len(keywords),
            "missing_keywords": missing,
            "chunk_count": len(self.chunks),
            "table_count": len(table_chunks),
            "pages_observed": pages,
            "line_numbers_preserved": all(chunk.line_no is not None for chunk in table_chunks) if table_chunks else None,
            "bbox_chunks": len(bbox_chunks),
        }


def detect_file_type(path: Path) -> str:
    ext = path.suffix.lower()
    if ext == ".pdf":
        return "pdf"
    if ext in {".xlsx", ".xlsm", ".xltx"}:
        return "excel"
    if ext == ".docx":
        return "word"
    if ext in {".txt", ".md"}:
        return "text"
    if ext == ".csv":
        return "csv"
    if ext in {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff"}:
        return "image"
    return "unknown"


def classify_pdf(path: Path) -> dict[str, Any]:
    data = path.read_bytes()[:2_000_000]
    text_markers = data.count(b"/Font") + data.count(b"BT") + data.count(b"/ToUnicode")
    image_markers = data.count(b"/Image") + data.count(b"/XObject")
    page_count = max(0, data.count(b"/Type /Page"))
    encrypted = b"/Encrypt" in data[:100_000]
    if encrypted:
        strategy = "blocked_encrypted"
        pdf_kind = "encrypted"
    elif image_markers > text_markers * 2 and image_markers > 2:
        strategy = "mineru_or_ocr_chain"
        pdf_kind = "scan_or_image_heavy"
    elif text_markers >= 1:
        strategy = "pdfplumber_optional"
        pdf_kind = "native_or_mixed"
    else:
        strategy = "pymupdf_optional_probe"
        pdf_kind = "unknown_or_sparse"
    return {
        "pdf_kind": pdf_kind,
        "recommended_strategy": strategy,
        "page_count_estimate": page_count,
        "text_markers": text_markers,
        "image_markers": image_markers,
        "encrypted": encrypted,
    }


def parse_text(path: Path) -> ParsedDocument:
    text = path.read_text(encoding="utf-8", errors="replace")
    chunks = [
        Chunk(text=line, line_no=index, metadata={"source": "line"})
        for index, line in enumerate(text.splitlines(), start=1)
        if line.strip()
    ]
    return ParsedDocument(str(path), detect_file_type(path), "stdlib_text", chunks=chunks, page_count=1 if chunks else 0)


def parse_csv(path: Path) -> ParsedDocument:
    chunks: list[Chunk] = []
    with path.open("r", encoding="utf-8-sig", errors="replace", newline="") as handle:
        reader = csv.reader(handle)
        for line_no, row in enumerate(reader, start=1):
            chunks.append(Chunk(text=" | ".join(row), table_id=path.stem, line_no=line_no, metadata={"cells": row}))
    return ParsedDocument(str(path), "csv", "stdlib_csv", chunks=chunks, page_count=1 if chunks else 0)


def xml_text(element: ET.Element) -> str:
    return "".join(node.text or "" for node in element.iter())


def parse_docx(path: Path) -> ParsedDocument:
    chunks: list[Chunk] = []
    with zipfile.ZipFile(path) as archive:
        document_xml = archive.read("word/document.xml")
    root = ET.fromstring(document_xml)
    paragraph_no = 0
    table_no = 0
    for child in root.findall(".//w:body/*", NS):
        if child.tag.endswith("}p"):
            text = "".join(t.text or "" for t in child.findall(".//w:t", NS)).strip()
            if text:
                paragraph_no += 1
                style = child.find(".//w:pStyle", NS)
                chunks.append(Chunk(text=text, line_no=paragraph_no, metadata={"style": style.get(f"{{{NS['w']}}}val") if style is not None else None}))
        elif child.tag.endswith("}tbl"):
            table_no += 1
            for row_no, row in enumerate(child.findall(".//w:tr", NS), start=1):
                cells = ["".join(t.text or "" for t in cell.findall(".//w:t", NS)).strip() for cell in row.findall("./w:tc", NS)]
                chunks.append(Chunk(text=" | ".join(cells), table_id=f"table-{table_no}", line_no=row_no, metadata={"cells": cells}))
    return ParsedDocument(str(path), "word", "docx_zip_xml", chunks=chunks, page_count=1 if chunks else 0)


def parse_xlsx(path: Path) -> ParsedDocument:
    chunks: list[Chunk] = []
    with zipfile.ZipFile(path) as archive:
        shared_strings: list[str] = []
        if "xl/sharedStrings.xml" in archive.namelist():
            ss_root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            shared_strings = [xml_text(item) for item in ss_root.findall(".//s:si", NS)]
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        sheet_names = [sheet.get("name") or f"sheet-{idx}" for idx, sheet in enumerate(workbook.findall(".//s:sheet", NS), start=1)]
        sheet_files = sorted(name for name in archive.namelist() if re.match(r"xl/worksheets/sheet\d+\.xml$", name))
        for sheet_index, sheet_file in enumerate(sheet_files, start=1):
            sheet_name = sheet_names[sheet_index - 1] if sheet_index - 1 < len(sheet_names) else Path(sheet_file).stem
            sheet_root = ET.fromstring(archive.read(sheet_file))
            merged_ranges = [merge.get("ref") for merge in sheet_root.findall(".//s:mergeCell", NS)]
            for row in sheet_root.findall(".//s:row", NS):
                line_no = int(row.get("r") or "0") or None
                values: list[str] = []
                cells: list[dict[str, Any]] = []
                for cell in row.findall("./s:c", NS):
                    ref = cell.get("r")
                    raw_value = cell.findtext("./s:v", default="", namespaces=NS)
                    if cell.get("t") == "s" and raw_value.isdigit():
                        value = shared_strings[int(raw_value)] if int(raw_value) < len(shared_strings) else raw_value
                    else:
                        value = raw_value
                    values.append(value)
                    cells.append({"ref": ref, "value": value})
                if values:
                    chunks.append(Chunk(text=" | ".join(values), table_id=sheet_name, line_no=line_no, metadata={"cells": cells, "merged_ranges": merged_ranges}))
    return ParsedDocument(str(path), "excel", "xlsx_zip_xml", chunks=chunks, page_count=len({chunk.table_id for chunk in chunks}))


def parse_pdf(path: Path) -> ParsedDocument:
    profile = classify_pdf(path)
    doc = ParsedDocument(str(path), "pdf", profile["recommended_strategy"], page_count=profile["page_count_estimate"])
    doc.metadata["route"] = profile
    if profile["encrypted"]:
        doc.error = "encrypted_pdf_requires_explicit_password_or_owner_gate"
    else:
        doc.metadata["fallback_boundary"] = "Use codex-office-cli or project-local optional parsers for pypdf/pdfplumber/PyMuPDF; route OCR/MinerU/VLM through install/runtime/credential gates."
    return doc


def parse_document(path: Path) -> ParsedDocument:
    if not path.exists():
        return ParsedDocument(str(path), "unknown", "missing", error="file_not_found")
    if path.is_dir():
        return ParsedDocument(str(path), "unknown", "directory", error="path_is_directory")
    if path.stat().st_size == 0:
        return ParsedDocument(str(path), detect_file_type(path), "preflight", error="empty_file")
    file_type = detect_file_type(path)
    try:
        if file_type == "text":
            return parse_text(path)
        if file_type == "csv":
            return parse_csv(path)
        if file_type == "word":
            return parse_docx(path)
        if file_type == "excel":
            return parse_xlsx(path)
        if file_type == "pdf":
            return parse_pdf(path)
        if file_type == "image":
            return ParsedDocument(str(path), "image", "ocr_gate_required", error="image_requires_explicit_ocr_or_vlm_gate")
        return ParsedDocument(str(path), "unknown", "unsupported", error="unsupported_file_type")
    except zipfile.BadZipFile:
        return ParsedDocument(str(path), file_type, "preflight", error="corrupted_zip_container")
    except Exception as exc:
        return ParsedDocument(str(path), file_type, "preflight", error=f"parse_failed: {exc}")


def quality_gate(document: ParsedDocument, keywords: list[str]) -> dict[str, Any]:
    validation = document.validate(keywords) if keywords else {
        "passed": document.error is None,
        "found_keywords": 0,
        "total_keywords": 0,
        "missing_keywords": [],
        "chunk_count": len(document.chunks),
        "table_count": len([chunk for chunk in document.chunks if chunk.table_id]),
    }
    elapsed_ok = document.parse_time_ms < 30_000
    robust = document.error is None or document.error in {
        "empty_file",
        "corrupted_zip_container",
        "encrypted_pdf_requires_explicit_password_or_owner_gate",
        "image_requires_explicit_ocr_or_vlm_gate",
        "unsupported_file_type",
    }
    return {
        "content": validation,
        "structure": {
            "page_count": document.page_count,
            "line_number_chunks": len([chunk for chunk in document.chunks if chunk.line_no is not None]),
            "table_chunks": len([chunk for chunk in document.chunks if chunk.table_id]),
            "bbox_chunks": len([chunk for chunk in document.chunks if chunk.bbox]),
        },
        "performance": {
            "parse_time_ms": document.parse_time_ms,
            "within_default_budget": elapsed_ok,
        },
        "robustness": {
            "error": document.error,
            "handled_boundary": robust,
        },
        "passed": validation["passed"] and elapsed_ok and robust,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    parser.add_argument("--keyword", action="append", default=[])
    parser.add_argument("--json", action="store_true", default=True)
    args = parser.parse_args()

    start = time.time()
    document = parse_document(Path(args.path))
    document.parse_time_ms = int((time.time() - start) * 1000)
    document.metadata["validation"] = quality_gate(document, args.keyword)
    payload = asdict(document)
    payload["text"] = document.text
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if document.metadata["validation"]["passed"] else 2


if __name__ == "__main__":
    raise SystemExit(main())

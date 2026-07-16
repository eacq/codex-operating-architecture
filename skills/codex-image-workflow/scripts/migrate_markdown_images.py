#!/usr/bin/env python3
"""Upload referenced local Markdown images, rewrite links, and safely retire originals."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import mimetypes
import os
import re
import shutil
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


WIKI = re.compile(r"!\[\[([^\]|#]+)(?:\|[^\]]+)?\]\]")
MARKDOWN = re.compile(r"!\[([^\]]*)\]\(([^)\s]+)(?:\s+['\"][^'\"]*['\"])?\)")
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp"}
CDN_SUFFIXES = (".hdslb.com", ".bilibili.com", ".biliimg.com")


def resolve_image(document: Path, root: Path, reference: str, wiki: bool) -> Path | None:
    decoded = urllib.parse.unquote(reference)
    if decoded.startswith(("http://", "https://", "data:")):
        return None
    candidates = [root / decoded] if wiki else [document.parent / decoded, root / decoded]
    for candidate in candidates:
        resolved = candidate.resolve()
        if resolved.is_file() and resolved.suffix.lower() in IMAGE_EXTENSIONS:
            return resolved
    return None


def discover(root: Path, allowed_image_root: Path | None = None) -> tuple[dict[Path, list[dict]], dict[Path, str]]:
    images: dict[Path, list[dict]] = {}
    documents: dict[Path, str] = {}
    for document in root.rglob("*.md"):
        text = document.read_text(encoding="utf-8")
        documents[document] = text
        for match in WIKI.finditer(text):
            image = resolve_image(document, root, match.group(1), True)
            if image and (allowed_image_root is None or image.is_relative_to(allowed_image_root)):
                images.setdefault(image, []).append({"document": document, "original": match.group(0), "alt": image.stem})
        for match in MARKDOWN.finditer(text):
            image = resolve_image(document, root, match.group(2), False)
            if image and (allowed_image_root is None or image.is_relative_to(allowed_image_root)):
                images.setdefault(image, []).append({"document": document, "original": match.group(0), "alt": match.group(1) or image.stem})
    return images, documents


def upload(image: Path, cookie: str) -> str:
    cookie_values = dict(item.strip().split("=", 1) for item in cookie.split(";") if "=" in item)
    csrf = cookie_values.get("bili_jct")
    if not csrf:
        raise RuntimeError("Bilibili Cookie does not contain bili_jct.")
    mime = mimetypes.guess_type(image.name)[0] or "application/octet-stream"
    cover = f"data:{mime};base64,{base64.b64encode(image.read_bytes()).decode('ascii')}"
    payload = urllib.parse.urlencode({"csrf": csrf, "cover": cover}).encode()
    request = urllib.request.Request(
        "https://api.bilibili.com/x/article/creative/article/upcover",
        data=payload,
        headers={"Cookie": cookie, "Referer": "https://www.bilibili.com/", "User-Agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        result = json.load(response)
    if result.get("code") != 0 or not result.get("data", {}).get("url"):
        raise RuntimeError(f"Bilibili upload failed with code {result.get('code')}: {result.get('message')}")
    url = result["data"]["url"]
    if url.startswith("//"):
        url = "https:" + url
    elif url.startswith("http://"):
        url = "https://" + url[len("http://"):]
    verify_remote(url)
    return url


def verify_remote(url: str) -> None:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or not any(parsed.hostname and parsed.hostname.endswith(suffix) for suffix in CDN_SUFFIXES):
        raise RuntimeError(f"Unexpected remote image URL: {url}")
    request = urllib.request.Request(url, headers={"Range": "bytes=0-0", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        if response.status not in (200, 206):
            raise RuntimeError(f"Remote verification failed with HTTP {response.status}: {url}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--allowed-image-root", type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--delete-local", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    allowed_image_root = args.allowed_image_root.resolve() if args.allowed_image_root else None
    images, documents = discover(root, allowed_image_root)
    plan = {str(path): sorted({str(item["document"].relative_to(root)) for item in refs}) for path, refs in images.items()}
    if not args.apply:
        print(json.dumps({"root": str(root), "image_count": len(images), "images": plan}, ensure_ascii=False, indent=2))
        return 0
    if not images:
        print("No referenced local images found.")
        return 0
    cookie = os.environ.get("BILIBILI_IMAGE_COOKIE")
    if not cookie:
        raise RuntimeError("BILIBILI_IMAGE_COOKIE is not available in this process.")

    uploaded = {image: upload(image, cookie) for image in images}
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    quarantine_root = Path(os.environ.get("CODEX_IMAGE_QUARANTINE_ROOT", root / ".image-hosting" / "quarantine"))
    quarantine = quarantine_root / stamp
    manifest_entries = []
    for image, refs in images.items():
        relative = image.relative_to(root)
        backup = quarantine / relative
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(image, backup)
        manifest_entries.append({
            "source": str(relative),
            "sha256": hashlib.sha256(image.read_bytes()).hexdigest(),
            "remote_url": uploaded[image],
            "documents": sorted({str(item["document"].relative_to(root)) for item in refs}),
            "quarantine": "$IMAGE_QUARANTINE_ROOT/" + backup.relative_to(quarantine_root).as_posix(),
        })

    updated = dict(documents)
    for image, refs in images.items():
        for item in refs:
            replacement = f"![{item['alt']}]({uploaded[image]})"
            updated[item["document"]] = updated[item["document"]].replace(item["original"], replacement)
    manifest_dir = root / ".image-hosting" / "manifests"
    manifest_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = manifest_dir / f"{stamp}.json"
    manifest = {"schema_version": 1, "status": "prepared", "provider": "bilibili-article-cover", "created_at": stamp, "entries": manifest_entries}
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    try:
        for document, text in updated.items():
            temporary = document.with_suffix(document.suffix + ".image-hosting.tmp")
            temporary.write_text(text, encoding="utf-8", newline="\n")
            temporary.replace(document)
        remaining, _ = discover(root, allowed_image_root)
        if any(image in remaining for image in images):
            raise RuntimeError("Local references remain after rewrite.")
    except Exception:
        for document, original in documents.items():
            document.write_text(original, encoding="utf-8", newline="\n")
        manifest["status"] = "rolled-back"
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        raise
    manifest["status"] = "committed"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.delete_local:
        for image in images:
            image.unlink()
    print(f"Migrated {len(images)} images; manifest: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

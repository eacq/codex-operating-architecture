from pathlib import Path
import re
import sys


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


ROOT = Path(r"%USERPROFILE%\.codex\skills")
PATTERN = re.compile(
    r"(API_KEY|OPENAI_API_KEY|ZCHAT|GEMINI|GOOGLE|ANTHROPIC|OPENROUTER|"
    r"KLING|ZOTERO|ELSEVIER|SPRINGER|NCBI|SEMANTIC|AMINER|base_url|api_key)",
    re.IGNORECASE,
)
EXTENSIONS = {".md", ".py", ".toml", ".yaml", ".yml", ".example"}
EXCLUDED_PARTS = {".git", "venv", ".venv", "__pycache__", "site-packages"}


def main() -> int:
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        if any(part in EXCLUDED_PARTS for part in path.parts):
            continue
        if path.suffix.lower() not in EXTENSIONS and path.name != ".env.example":
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        matches = []
        for line_no, line in enumerate(text.splitlines(), 1):
            if PATTERN.search(line):
                cleaned = line.strip()
                if len(cleaned) > 160:
                    cleaned = cleaned[:157] + "..."
                matches.append((line_no, cleaned))
        if matches:
            print(path)
            for line_no, line in matches[:20]:
                print(f"  {line_no}: {line}")
            if len(matches) > 20:
                print(f"  ... {len(matches) - 20} more")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

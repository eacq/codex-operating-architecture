from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from typing import Iterable


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


@dataclass(frozen=True)
class EnvVar:
    name: str
    skills: str
    purpose: str
    replaceable_by_zchat: str
    required: bool = False


ENV_VARS: tuple[EnvVar, ...] = (
    EnvVar("ZCHAT_API_KEY", "zchat-api-usage, academic-figure-generation, ppt-generator prompts", "ZCHAT/OpenAI-compatible chat", "native", True),
    EnvVar("ZCHAT_MODEL", "ZCHAT-compatible scripts", "Optional ZCHAT model override", "native"),
    EnvVar("ZCHAT_BASE_URL", "ZCHAT-compatible scripts", "Optional base URL override", "native"),
    EnvVar("OPENAI_API_KEY", "Codex auth, imagegen CLI, transcribe", "OpenAI or OpenAI-compatible auth", "chat/embeddings only"),
    EnvVar("OPENAI_OFFICIAL_API_KEY", "Explicit Codex Platform API fallback", "Official OpenAI Platform key; not the default ChatGPT subscription fallback", "not the default ZCHAT fallback"),
    EnvVar("GEMINI_API_KEY", "ppt-generator", "NanoBanana/Gemini image generation", "no", True),
    EnvVar("KLING_ACCESS_KEY", "ppt-generator", "Kling video transitions", "no"),
    EnvVar("KLING_SECRET_KEY", "ppt-generator", "Kling video transitions", "no"),
    EnvVar("ANTHROPIC_API_KEY", "ppt-generator prompt fallback", "Anthropic transition prompt generation", "yes for patched prompt generation"),
    EnvVar("OPENROUTER_API_KEY", "nature-figure", "OpenRouter image schematics", "no"),
    EnvVar("OPENROUTER_IMAGE_MODEL", "nature-figure", "OpenRouter image model override", "no"),
    EnvVar("OPENROUTER_SITE_URL", "nature-figure", "OpenRouter attribution metadata", "no"),
    EnvVar("OPENROUTER_APP_NAME", "nature-figure", "OpenRouter attribution metadata", "no"),
    EnvVar("SEMANTIC_SCHOLAR_API_KEY", "nature-academic-search", "Semantic Scholar higher rate limit", "no"),
    EnvVar("S2_API_KEY", "paper-fulltext-harvest", "Semantic Scholar higher rate limit", "no"),
    EnvVar("NCBI_API_KEY", "nature-academic-search, citation workflows", "PubMed/NCBI higher rate limit", "no"),
    EnvVar("PUBMED_EMAIL", "nature-academic-search", "NCBI polite access identity", "no"),
    EnvVar("AMINER_API_KEY", "literature-search", "AMiner academic search", "no"),
    EnvVar("OPENALEX_MAILTO", "literature/citation workflows", "OpenAlex polite access identity", "no"),
    EnvVar("CROSSREF_MAILTO", "literature/citation workflows", "Crossref polite access identity", "no"),
    EnvVar("ELSEVIER_API_KEY", "paper-fulltext-harvest", "Elsevier TDM/full-text API", "no"),
    EnvVar("ELSEVIER_INSTTOKEN", "paper-fulltext-harvest", "Elsevier institutional access", "no"),
    EnvVar("ELSEVIER_AUTHTOKEN", "paper-fulltext-harvest", "Optional Elsevier auth context", "no"),
    EnvVar("SPRINGER_API_KEY", "paper-fulltext-harvest", "Springer Nature OA API", "no"),
    EnvVar("SPRINGER_NATURE_API_KEY", "paper-fulltext-harvest", "Alternate Springer env name", "no"),
    EnvVar("ZOTERO_API_KEY", "zotero-management", "Zotero Web API", "no"),
    EnvVar("ZOTERO_USER_ID", "zotero-management", "Zotero user library ID", "no"),
)


def windows_env(name: str) -> str | None:
    if os.name != "nt":
        return None
    try:
        import winreg
    except ImportError:
        return None
    roots = [
        (winreg.HKEY_CURRENT_USER, r"Environment"),
        (
            winreg.HKEY_LOCAL_MACHINE,
            r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",
        ),
    ]
    for root, key_path in roots:
        try:
            with winreg.OpenKey(root, key_path) as key:
                value, _ = winreg.QueryValueEx(key, name)
                if value:
                    return str(value)
        except OSError:
            continue
    return None


def is_set(name: str) -> bool:
    return bool(os.environ.get(name) or windows_env(name))


def selected_vars(args: Iterable[str]) -> tuple[EnvVar, ...]:
    filters = tuple(arg.lower() for arg in args)
    if not filters:
        return ENV_VARS
    return tuple(
        item
        for item in ENV_VARS
        if any(
            f in item.name.lower()
            or f in item.skills.lower()
            or f in item.purpose.lower()
            for f in filters
        )
    )


def main(argv: list[str]) -> int:
    items = selected_vars(argv[1:])
    print("API environment status (values hidden)")
    print("=" * 78)
    for item in items:
        status = "SET" if is_set(item.name) else "missing"
        marker = "required" if item.required else "optional"
        print(f"{item.name:28} {status:8} {marker:8} zchat={item.replaceable_by_zchat}")
        print(f"  skills: {item.skills}")
        print(f"  purpose: {item.purpose}")
    missing_required = [item.name for item in ENV_VARS if item.required and not is_set(item.name)]
    if missing_required:
        print("\nMissing required-for-common-local-workflow variables:")
        for name in missing_required:
            print(f"  - {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

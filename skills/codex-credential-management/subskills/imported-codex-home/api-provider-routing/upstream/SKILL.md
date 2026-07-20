---
name: api-provider-routing
description: Use when configuring skills that require external APIs, deciding whether ZCHAT can replace OpenAI/Anthropic/Gemini/OpenRouter/Kling or publisher APIs, or auditing skill API keys and endpoint routing.
---

# API Provider Routing

Use this skill before editing any skill that requires an external API key or a
non-default provider. The goal is to route compatible model calls through the
user's available providers without pretending that unrelated API shapes are
interchangeable.

## Core Rule

ZCHAT is an OpenAI-format chat/completions and embeddings provider. It can
replace text-chat style OpenAI-compatible clients. It cannot automatically
replace:

- Google Gemini image generation through `google-genai`
- OpenAI audio transcription/speech endpoints
- Kling video-generation APIs
- OpenRouter image-generation routes
- Zotero APIs
- publisher APIs such as Elsevier or Springer
- scholarly service APIs such as Semantic Scholar, NCBI, AMiner, Crossref, or OpenAlex

If a task asks to "use ZCHAT instead", first check whether the original call is
chat/embeddings shaped. If not, add a documented fallback rather than silently
rewiring to the wrong endpoint.

## Local Routing Matrix

Read the full matrix in:

```text
references/local-api-routing.md
```

Current highlights:

- `academic-figure-generation`: already has ZCHAT/OpenAI-compatible text wiring and local matplotlib rendering fallback.
- `zchat-api-usage`: stores generic ZCHAT safety, endpoint, model, and Codex config rules.
- `ppt-generator`: Gemini image generation still requires `GEMINI_API_KEY`; transition prompt text/vision analysis can use `ZCHAT_API_KEY` through the patched OpenAI-compatible branch.
- `transcribe`: requires OpenAI audio transcription support; ZCHAT chat/embeddings docs are not enough.
- `nature-figure`: OpenRouter image generation is not equivalent to ZCHAT chat.
- `paper-fulltext-harvest`: publisher APIs are not LLM APIs and cannot be converted to ZCHAT.

## Configuration Policy

- Prefer environment variables over `.env` files when a key is shared across skills.
- Never print API keys or write real keys into skill documentation.
- Preserve existing `%USERPROFILE%\.codex\config.toml` sections when editing Codex provider config.
- For Codex core chat, prefer ZCHAT first; when authenticated ZCHAT quota/account-pool/provider availability is exhausted after one documented model fallback, prefer ChatGPT sign-in so usage can follow the user's ChatGPT subscription/Plus workspace where eligible.
- Use official OpenAI Platform API fallback only when the user explicitly chooses usage-based API billing or ChatGPT sign-in is unavailable.
- Do not fall back from ZCHAT for request-shape bugs such as 400, 404, unsupported parameters, or misspelled model names.
- Treat `%USERPROFILE%\.codex\auth.json` as the active Codex credential cache, not a multi-provider inventory. Its schema is mode-specific: ZCHAT/API-key mode uses `auth_mode: "apikey"` and `OPENAI_API_KEY`; ChatGPT sign-in uses `auth_mode: "chatgpt"` and token fields. Do not merge those schemas; keep multi-provider metadata in a separate local JSON template.
- Avoid high-concurrency ZCHAT usage, including loops and immersive-translation style integrations.
- Do not continue prompts that trigger ZCHAT moral/safety review warnings.

## Audit Command

Use this script to list API-related references across local skills:

```powershell
%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  %USERPROFILE%\.codex\skills\api-provider-routing\scripts\audit_skill_api_routes.py
```

Use this script to check whether relevant API environment variables are present
without printing any secret values:

```powershell
%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  %USERPROFILE%\.codex\skills\api-provider-routing\scripts\check_api_env.py
```

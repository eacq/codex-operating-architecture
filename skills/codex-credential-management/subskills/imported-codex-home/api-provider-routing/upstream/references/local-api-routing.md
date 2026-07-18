# Local API Routing Matrix

This file records how local Codex skills should handle external API providers.

## ZCHAT-Compatible Or Partially Compatible

| Skill | Original API | ZCHAT status | Configuration |
|---|---|---|---|
| `zchat-api-usage` | ZCHAT OpenAI-compatible chat/embeddings | Native | `ZCHAT_API_KEY`, `https://api.zchat.tech/v1` |
| `academic-figure-generation` | PaperBanana text model plus local rendering fallback | Compatible for text planning | `ZCHAT_API_KEY` mapped to OpenAI-compatible calls; use `CriticRounds=0` first |
| `ppt-generator` transition prompts | Anthropic Claude multimodal prompt generation | Partially compatible | patched to prefer `ZCHAT_API_KEY`/`OPENAI_API_KEY` via OpenAI-compatible chat; set `ZCHAT_MODEL=gemini-3-pro` if model selection is needed |
| `Codex core provider` | OpenAI-compatible chat provider | Compatible | `C:\Users\12484\.codex\config.toml` uses `model_provider = "openai-chat-completions"` and `base_url = "https://api.zchat.tech/v1"` |

## Codex Core Provider Priority

Use this provider order for Codex itself:

1. ZCHAT primary: `model_provider = "openai-chat-completions"` with `base_url = "https://api.zchat.tech/v1"`.
2. ZCHAT model fallback: try one documented alternate model when the primary model returns provider-side 500/502/503 or account-pool shortage.
3. ChatGPT sign-in fallback: after authenticated ZCHAT quota, account-pool, or provider availability is exhausted, sign in with ChatGPT (`codex login` or desktop app sign-in) and use `C:\Users\12484\.codex\chatgpt.config.toml` so eligible usage follows ChatGPT subscription/Plus access.
4. Official OpenAI Platform API fallback: use `C:\Users\12484\.codex\openai.config.toml` only when the user explicitly wants usage-based Platform API billing or ChatGPT sign-in is unavailable.

Do not switch providers for local integration errors. Fix 400 request shape, 404 route/base URL, unsupported parameters, missing credentials, and misspelled models on the ZCHAT route first.

`C:\Users\12484\.codex\auth.json` or the OS credential store holds only the active Codex credentials. Its JSON schema changes by login mode: ZCHAT/API-key mode is `auth_mode: "apikey"` plus `OPENAI_API_KEY`, while ChatGPT sign-in is `auth_mode: "chatgpt"` plus token fields. Switch both `config.toml` and the active auth state together; keeping the old schema produces a mixed provider/auth state. Keep inventory metadata in `C:\Users\12484\.codex\auth.providers.template.json` or a private copy, but do not store multiple live secrets there.

## Not Directly ZCHAT-Compatible

| Skill | Required API | Why not directly convertible | Practical fallback |
|---|---|---|---|
| `.system/imagegen` | OpenAI image API or built-in image tool | Requires OpenAI image generation route/tool semantics, not just chat/embeddings | Prefer built-in image tool; CLI fallback needs `OPENAI_API_KEY` for a compatible image endpoint |
| `ppt-generator` slide images | Google `google-genai` image generation with `response_modalities=["IMAGE"]` | ZCHAT docs only guarantee OpenAI-format chat/completions and embeddings, not Google Gemini image API shape | Keep `GEMINI_API_KEY`; use ZCHAT only for planning/transition prompts |
| `ppt-generator` video transitions | Kling video API | Separate video-generation API with access/secret key signing | Keep `KLING_ACCESS_KEY` and `KLING_SECRET_KEY`; or skip video generation |
| `transcribe` | OpenAI audio transcription | Requires audio endpoint, not chat/embeddings | Use a provider with OpenAI audio transcription support |
| `nature-figure` image schematic generation | OpenRouter image route | Image endpoint and response format differ from ZCHAT chat | Keep `OPENROUTER_API_KEY` or use local matplotlib/SVG generation |
| `paper-fulltext-harvest` | Elsevier/Springer publisher APIs | Domain publisher APIs, not model APIs | Keep publisher keys or use OA fallbacks |
| `nature-academic-search` | Semantic Scholar/NCBI optional keys | Scholarly metadata APIs, not model APIs | Keep service-specific keys |
| `literature-search` | AMiner, Tavily, Exa, Gemini deep research/search tooling | Search/research APIs and web-grounded workflows are not equivalent to ZCHAT chat | Keep service-specific keys/tools; ZCHAT can only help synthesize results already retrieved |
| `zotero-management` | Zotero API key | Library service API, not model API | Keep `ZOTERO_API_KEY` |
| `nature-citation` / citation workflows | Crossref, PubMed/NCBI, Zotero/local bibliographic metadata | Bibliographic metadata services, not model APIs | Use source APIs directly; ZCHAT can help format/compare after metadata retrieval |

## Banana/PPT Generator Notes

`ppt-generator` uses two different ideas that should not be merged:

1. Slide image generation uses Google Gemini image generation through
   `google-genai`, currently with model `gemini-3-pro-image-preview`. This
   requires `GEMINI_API_KEY`.
2. Transition prompt generation is text/vision analysis. That can use ZCHAT
   through the OpenAI-compatible branch added locally:

   ```powershell
   setx ZCHAT_API_KEY "your-zchat-key"
   setx ZCHAT_MODEL "gemini-3-pro"
   ```

Do not set `GEMINI_API_KEY` to a ZCHAT key unless a verified Google-Gemini-
compatible proxy endpoint exists. ZCHAT's documented endpoint is
`https://api.zchat.tech/v1`, which is OpenAI-format, not Google `google-genai`
format.

## Endpoint Testing

For ZCHAT, test only low-frequency single calls:

```powershell
C:\Users\12484\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  C:\Users\12484\.codex\skills\zchat-api-usage\scripts\check_zchat.py `
  --model grok-3
```

Avoid loops, stress tests, and high-concurrency usage.

## Environment Inventory

For the complete local environment variable checklist, read:

```text
C:\Users\12484\.codex\skills\api-provider-routing\references\api-env-inventory.md
```

Check local status without printing secrets:

```powershell
C:\Users\12484\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  C:\Users\12484\.codex\skills\api-provider-routing\scripts\check_api_env.py
```

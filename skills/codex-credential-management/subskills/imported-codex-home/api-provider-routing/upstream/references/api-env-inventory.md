# API Environment Inventory

This inventory lists the external API variables used by local Codex skills. It
does not contain secrets.

## ZCHAT And OpenAI-Compatible Text

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `ZCHAT_API_KEY` | `zchat-api-usage`, `academic-figure-generation`, `ppt-generator` transition prompts | Calling ZCHAT directly from scripts | Native |
| `ZCHAT_MODEL` | `ppt-generator` transition prompts, optional ZCHAT scripts | Choosing a ZCHAT chat model | Native; common value `gemini-3-pro` or `grok-3` |
| `ZCHAT_BASE_URL` | ZCHAT scripts, optional override | Testing non-default ZCHAT-compatible base URL | Native; default `https://api.zchat.tech/v1` |
| `OPENAI_API_KEY` | Codex auth, `.system/imagegen`, `transcribe`, some OpenAI-compatible scripts | OpenAI-compatible provider auth or OpenAI-specific tools | ZCHAT key can be used only for chat/embeddings-compatible clients; not for OpenAI audio/image unless verified |
| `OPENAI_OFFICIAL_API_KEY` | Optional private inventory or explicit API fallback script | Keeping an official OpenAI Platform key separate from ChatGPT subscription fallback | Not the default ZCHAT fallback; use only for explicit usage-based API billing |

## NanoBanana / PPT Generator

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `GEMINI_API_KEY` | `ppt-generator` slide image generation | Generating NanoBanana/Gemini PPT images via `google-genai` | Not replaceable by documented ZCHAT |
| `KLING_ACCESS_KEY` | `ppt-generator` video transition generation | Calling Kling video API | Not replaceable |
| `KLING_SECRET_KEY` | `ppt-generator` video transition generation | Calling Kling video API | Not replaceable |
| `ANTHROPIC_API_KEY` | `ppt-generator` transition prompt fallback | Forcing Anthropic transition prompt generation | Replaceable for patched transition prompts by `ZCHAT_API_KEY` |

## Image And Figure Generation

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `OPENROUTER_API_KEY` | `nature-figure` OpenRouter schematic route | AI manuscript schematic/image generation through OpenRouter | Not replaceable by documented ZCHAT |
| `OPENROUTER_IMAGE_MODEL` | `nature-figure` optional model override | Selecting OpenRouter image model | Not replaceable |
| `OPENROUTER_SITE_URL` | `nature-figure` optional OpenRouter metadata | OpenRouter attribution headers | Not replaceable |
| `OPENROUTER_APP_NAME` | `nature-figure` optional OpenRouter metadata | OpenRouter attribution headers | Not replaceable |

## Audio

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `OPENAI_API_KEY` | `transcribe` | Live audio transcription/diarization | Not replaceable unless the provider explicitly supports OpenAI audio transcription endpoints |

## Literature Search And Metadata

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `SEMANTIC_SCHOLAR_API_KEY` | `nature-academic-search`, literature workflows | Higher Semantic Scholar rate limit | Not replaceable |
| `S2_API_KEY` | `paper-fulltext-harvest` optional Semantic Scholar support | Higher Semantic Scholar rate limit | Not replaceable |
| `NCBI_API_KEY` | `nature-academic-search`, citation workflows | Higher PubMed/NCBI rate limit | Not replaceable |
| `PUBMED_EMAIL` | `nature-academic-search` | PubMed/NCBI polite access identification | Not replaceable |
| `AMINER_API_KEY` | `literature-search` | AMiner search | Not replaceable |
| `OPENALEX_MAILTO` | literature/citation workflows | Polite OpenAlex requests | Not replaceable |
| `CROSSREF_MAILTO` | literature/citation workflows | Polite Crossref requests | Not replaceable |

## Full-Text Harvest

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `ELSEVIER_API_KEY` | `paper-fulltext-harvest` | Elsevier TDM/full-text API | Not replaceable |
| `ELSEVIER_INSTTOKEN` | `paper-fulltext-harvest` | Institutional Elsevier access | Not replaceable |
| `ELSEVIER_AUTHTOKEN` | `paper-fulltext-harvest` | Optional Elsevier auth context | Not replaceable |
| `SPRINGER_API_KEY` | `paper-fulltext-harvest` | Springer Nature OA API | Not replaceable |
| `SPRINGER_NATURE_API_KEY` | `paper-fulltext-harvest` | Alternate Springer env name | Not replaceable |

## Zotero

| Variable | Used By | Required When | ZCHAT Replacement |
|---|---|---|---|
| `ZOTERO_API_KEY` | `zotero-management` | Zotero Web API read/write | Not replaceable |
| `ZOTERO_USER_ID` | `zotero-management` | Zotero Web API user library access | Not replaceable |

## Practical Defaults

- For ZCHAT text tasks: set `ZCHAT_API_KEY`; optionally set `ZCHAT_MODEL`.
- For Codex core chat fallback: keep ZCHAT primary; after authenticated ZCHAT quota/account-pool/provider availability is exhausted, prefer ChatGPT sign-in/subscription fallback before any usage-based Platform API key fallback.
- For multi-provider organization: keep real secrets in environment variables or a secure store; keep only provider metadata and variable names in JSON inventory templates.
- For NanoBanana images: set `GEMINI_API_KEY`.
- For NanoBanana video transitions: set `KLING_ACCESS_KEY` and `KLING_SECRET_KEY`; install `ffmpeg` separately for composition.
- For OpenRouter schematics: set `OPENROUTER_API_KEY`.
- For audio transcription: use a real OpenAI-compatible audio provider; current ZCHAT notes only document chat and embeddings.
- For publisher or literature APIs: use service-specific keys; ZCHAT can summarize retrieved metadata but cannot fetch authoritative records.

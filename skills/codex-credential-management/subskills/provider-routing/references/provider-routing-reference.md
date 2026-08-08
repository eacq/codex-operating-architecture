# OpenAI-Compatible Private Provider Reference

## Request contract

| Use | Local profile value | Request shape |
|---|---|---|
| Chat | `provider.base_url` plus `/chat/completions` | `model`, `messages` |
| Embeddings | `provider.base_url` plus `/embeddings` | `model`, `input` |
| Credentials | `provider.api_key_environment_variable` | `Authorization: Bearer <key>` |

Never log the authorization header or its value.

## Failure matrix

| Signal | Meaning | Next action |
|---|---|---|
| 401/403 | Credential rejected | Check the selected secure source |
| 400 | Request/model unsupported | Remove optional parameters; verify local model choice |
| 404 | Wrong route | Distinguish base URL from full endpoint URL |
| 500/502/503 | Model/provider unavailable | Try one locally configured fallback model |
| Timeout | Network/provider delay | Retry once manually; do not loop |

## Migration boundary

Generic skills may describe OpenAI-compatible protocol and the choice between
API-key and ChatGPT login. A provider name, endpoint, quota policy, model list,
drive layout, and account preference are private profile data. Initialize that
data with `codex-skill-portability`; do not commit it.

If CC Switch manages Codex on this machine, treat `~/.cc-switch/cc-switch.db`
and `settings.json` as the local manager state and `~/.codex/config.toml` as
its live projection. The projection may contain provider-specific bearer-token
fields or OAuth-shaped auth caches. Record the manager presence, provider name,
auth shape, and backup/log timestamps only; never copy credential fields into
project files or diagnostics.

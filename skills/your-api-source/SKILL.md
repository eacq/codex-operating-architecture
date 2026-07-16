---
name: your-api-source
description: Backward-compatible entry for a privately configured OpenAI-compatible provider. Use when a recipient has selected a local provider profile and needs safe API-key diagnostics, ChatGPT login versus API-key routing, endpoint checks, or model fallback without exposing credentials.
---

# Private OpenAI-Compatible Provider Profile

This compatibility skill contains no personal endpoint, model catalog, account,
or path. On first use invoke `codex-skill-portability` and create the local
profile at `~/.codex/private-skill-config/portable-skill.json`.

## Shared contract

- An OpenAI-compatible provider needs a base URL, model, and API-key environment
  variable, all selected locally.
- Codex may instead use ChatGPT login. Treat ChatGPT login and API-key mode as
  alternative active authentication states; do not merge token fields and API
  keys into one tracked file.
- Keep inactive provider definitions only when persisted local tasks require
  them. Never put a private endpoint or secret in a repository configuration.

## Diagnosis

For API-key mode, run one low-frequency request using values from the local
profile. The checker prints only source metadata and HTTP state:

```powershell
py scripts/check_your_api_source.py --base-url <profile-base-url> --api-key-env <profile-env-var> --model <profile-model>
```

- `401/403`: check the selected secure credential source; do not rotate a key
  merely because a model failed.
- `400/404`: check URL shape, model spelling, and unsupported parameters.
- `500/502/503`: credentials may be valid; try one locally configured fallback
  model, then use the recipient's selected ChatGPT-login or official API route.
- Timeout/network error: verify once; do not retry-loop.

For ChatGPT-login mode, use the Codex desktop or official login flow. Do not
extract browser cookies, tokens, or profile data. Read
[references/your-api-source-reference.md](references/your-api-source-reference.md) for the
portable request and migration boundary.

## Interrupted run boundary

Provider quota, rate-limit, account-pool, or timeout symptoms describe whether
a request completed; they do not determine which project artifact is
authoritative. Route document/history source selection to
`codex-conversation-continuity`: a current user-designated file outranks a
later tool-generated artifact from an interrupted provider branch. Do not
inspect credentials to answer this question.

## Example

```powershell
$env:TEST_API_KEY = '<set outside Git>'
py scripts/check_your_api_source.py --base-url https://example.test/v1 --api-key-env TEST_API_KEY --model test-model
```

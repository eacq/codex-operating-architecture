---
name: codex-credential-management
description: Safely configure, diagnose, verify, rotate, and document authentication for APIs, CLIs, browsers, and local tools without exposing secret values. Use when a task mentions login, authentication, API keys, tokens, cookies, OAuth, account IDs, credential environment variables, or access failures.
---

# Codex Credential Management

Store only credential metadata: name, provider, source, scope, secure location, verification date, and rotation status. Never record secret values in skills, Git, logs, examples, or summaries.

1. Identify the required credential and least privilege.
2. Reuse an existing secure store when available.
3. Configure through the provider's supported mechanism.
4. Verify with a minimal non-destructive request.
5. Redact outputs and document only the method.
6. Recommend rotation when a live secret was exposed.

Distinguish identifiers from secrets without publishing either unnecessarily. Browser login may support visible authorized actions, never cookie, storage, profile, password, or session extraction. If no official OAuth exists, require user entry through a local secure prompt into DPAPI or another supported store.

## Provider Routing

Use `$codex-credential-management-provider-routing` for low-frequency
OpenAI-compatible provider diagnosis, model fallback, and the API-key versus
ChatGPT-login boundary. It inherits this owner's credential safety contract;
provider-specific values remain in the local portable profile.

Imported local compatibility modes live under `subskills/imported-codex-home/`; their former provider-routing material cannot override this owner's secure-configuration boundary.

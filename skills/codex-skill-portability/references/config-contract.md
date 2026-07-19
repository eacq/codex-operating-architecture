# Portable Skill Configuration Contract

## Tracked content

Track generic procedure, protocol shape, configuration keys, validation, and a
placeholder-only example. Do not track a personal provider URL, local drive
layout, selected paid service, secret value, account identity, browser state, or
machine inventory.

## Local profile

The initializer writes `~/.codex/private-skill-config/portable-skill.json`.
It may contain a provider label, base URL, environment-variable name, auth
preference, preferred model, software archive/install roots, and selected tools.
It may also contain optional temporary, work, and cache roots for Codex-managed
scratch space. If these are omitted, the architecture repository defaults to
ignored `.runtime` roots rather than the user's system Temp or home cache.
It must not contain a key, password, token, cookie, `auth.json`, or browser
export. Store secrets in an OS secure store or a user environment variable.

## OpenAI-compatible provider boundary

The reusable contract is: an OpenAI-compatible base URL, a model identifier,
and one of `api-key`, `chatgpt-login`, or `both` authentication preferences.
The concrete provider, endpoint, account, quota policy, and model catalog are
private profile choices and must be verified by the recipient before use.

## First-use behavior

If no local profile exists, ask the recipient to choose provider/auth and
optional software settings. Offer skip; do not install software or mutate
credentials as part of initialization. Re-run the initializer with `-Force` to
change choices deliberately.

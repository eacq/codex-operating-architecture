# Codex Provider Switch

Clickable local utilities for switching `$CODEX_HOME\config.toml`.

## Launchers

- `Switch-Codex-To-YourApiSource.cmd`: switch Codex to YourApiSource API-key mode.
- `Switch-Codex-To-OpenAI-ChatGPT.cmd`: switch Codex to OpenAI/ChatGPT provider mode.
- `Set-YourApiSource-API-Key.cmd`: save `YOUR_API_SOURCE_API_KEY`, `YOUR_API_SOURCE_BASE_URL`, and `YOUR_API_SOURCE_MODEL` to the current Windows user environment.
- `Refresh-Codex-ChatGPT-Login.cmd`: switch config to ChatGPT/OpenAI mode and restore a saved ChatGPT login profile when available.
- `Repair-Codex-Sidebar-State.ps1`: converge the three persisted sidebar preference fields to the verified layout: width `276`, all standard sections expanded, and project sidebar preferences initialized. Both provider switches run it automatically after changing provider state, then run a second pass and a final check to avoid needing a second manual switch click.
- `Initialize-Codex-ChatGPT-Profile.ps1`: save the currently active ChatGPT login profile before the first YourApiSource switch.

## Rules

- The switch scripts create timestamped backups under `$CODEX_HOME\backups`.
- Before YourApiSource replaces active API credentials, the script saves a local ChatGPT login profile at `$CODEX_HOME\provider-profiles\chatgpt-auth.json`. Switching back restores it without a browser login. The profile is only a local credential cache; never copy or commit it.
- Both the native OpenAI provider and the YourApiSource provider definition remain in `config.toml`. A switch changes only the top-level active provider and matching active auth mode, so old tasks can still resolve the provider they were created with.
- ChatGPT/Plus browser sign-in is required only when there is no valid saved login profile or it has expired; it is intentionally not automated.
- YourApiSource switching verifies `YOUR_API_SOURCE_API_KEY` against `YOUR_API_SOURCE_BASE_URL` and `YOUR_API_SOURCE_MODEL` before changing active Codex auth.
- Provider tools never write `.codex-global-state.json`, session indexes, or `state_5.sqlite`. The sidebar repair tool never writes provider or credential files.
- Before and after each switch, the local conversation-continuity catalog is refreshed from active and archived session metadata. It never reads credentials or rewrites session files.
- Do not store live API keys in this directory.

---
name: codex-git-operations-scoped-network-proxy
description: Owner-internal workflow for GitHub/OpenAI reachability through a child-process local proxy while keeping unrelated Windows applications off proxy traffic.
---

# Scoped Network Proxy

Use this subskill only through `codex-git-operations` when GitHub, GitHub CLI,
Git remotes, OpenAI API, ChatGPT, or local proxy behavior affects Git/Codex
work on this Windows machine.

## Boundary

Keep the local proxy core and the Windows traffic selectors separate:

- `127.0.0.1:7892` listening means YouTuCore can serve selected child commands.
- Windows `ProxyEnable = 1` means ordinary system-proxy-aware applications may
  enter YouTuCore.
- TUN/Wintun connected means more applications, including games, can be routed
  even when they do not honor the Windows system proxy.
- Environment variables such as `HTTP_PROXY` and `HTTPS_PROXY` affect only the
  current process and children, not already running Codex tasks.

For proxy-budget-sensitive work, prefer system proxy off and TUN off. Let
`scripts/Invoke-GitHubNetworkCommand.ps1` inject proxy variables only for the
child `git` or `gh` command that needs GitHub.

## Rules

1. Do not set WinHTTP proxy, Git global proxy, or persistent user-wide proxy
   variables just to repair GitHub, OpenAI, or ChatGPT reachability.
2. Do not edit YouTu encrypted or account-bearing configuration files directly.
3. Test direct and proxy paths separately. For OpenAI API, a proxied
   unauthenticated `https://api.openai.com/v1/models` returning `401` proves
   network reachability without exposing a key.
4. When checking whether a game or other high-volume app may consume proxy
   traffic, inspect the application process connections. Active connections to
   `127.0.0.1:7892` mean the app is entering YouTuCore and may consume proxy
   traffic depending on rules. `CloseWait` entries after system proxy/TUN are
   disabled are stale, not active routing evidence.
5. To isolate games, turn off Windows system proxy and TUN, keep YouTuCore
   running if needed, and verify the game has no active `Established`
   connection to `127.0.0.1:7892`.

## Verification

Run `scripts/Test-CodexScopedProxyIsolation.ps1` for a no-secret snapshot. It
checks Windows proxy state, local proxy listening, optional game-process
connections, GitHub direct/proxy paths, OpenAI API direct/proxy paths, and
Git/GitHub helper reachability.

## Invalidation

Re-verify when YouTu changes port, proxy software changes, TUN is re-enabled,
Windows proxy is enabled, a different game process is launched, GitHub/OpenAI
connection behavior changes, or the selected Codex provider changes.

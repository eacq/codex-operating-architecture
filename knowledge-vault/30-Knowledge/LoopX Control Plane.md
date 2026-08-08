# LoopX Control Plane

## Source grounding

- Source: https://github.com/huangruiteng/loopx
- Reviewed commit: `22b57a76e18736c31fe749867292f3feeb62f27b`
- Reviewed date: 2026-08-06
- License: MIT
- Local install: `.runtime/software/loopx/` with a Windows adapter

## Problem and philosophy

LoopX treats long-running Agent work as a durable control problem rather than
as a sequence of independent chat turns. Its useful unit is a bounded turn
whose objective, scope, owner, gate, evidence, continuation, and quota state
can be read back after interruption. The source repository demonstrates this
through a shared project state model, typed todos and leases, quota/heartbeat
surfaces, transaction/turn envelopes, recovery paths, host bridges, and a
large regression/canary surface.

Local synthesis: this complements the existing Global Experience Agent instead
of replacing it. The Global Experience Agent owns global lifecycle, Agent
structure, child state, authority, and save points; LoopX owns the optional
project-level goal projection and bounded-turn scheduling contract.

## Adopted

1. Read-first `doctor`/`status`/`diagnose` surfaces before choosing work.
2. Ordered typed todos with explicit claim/lease ownership rather than
   implicit chat ownership.
3. `quota should-run` before a repeat turn and spend only after validated
   writeback.
4. Turn lineage and typed recovery so timeout, wait, preview, failed
   preflight, and successful delivery are not conflated.
5. Evidence-backed handoff and refresh-state readback.
6. A Windows-specific controlled installer that prefers bundled Python and
   avoids PATH mutation.

## Rejected or deferred

- The upstream Bash installer, Unix shell profiles, symlinks, and macOS
  LaunchAgents are not portable to this Windows architecture and are replaced
  by `Install-LoopX.ps1`, `Invoke-LoopX.ps1`, and `loopx.cmd`.
- Lark, OpenViking, public dashboards, and other external providers remain
  opt-in because they add provider, credential, network, or publication
  boundaries that are not needed for the core project loop.
- LoopX is not allowed to become a second global Agent controller or an
  implicit publication/production controller.

## Local validation and invalidation

The adapter is accepted only when the installed release, bundled Python,
Windows command shim, deep doctor, guided project-start packet, and source
manifest pass `scripts/Test-LoopXIntegration.ps1`. Re-run the review if the
upstream release changes, the Python runtime changes, the existing Agent
save-point contract changes, or a project needs an external provider or public
projection. Until then, this is an installed adapted core, not a claim that
every optional LoopX surface is available on Windows.

---
id: concept-oh-my-codex-omx-lite-network-learning
type: concept

promotion_authority: user-candidate-processing-20260718
promotion_status: guarded
source: https://github.com/Yeachan-Heo/oh-my-codex;commit=5319c3d0388b09ad7036e6e3858afd959cfe0eea; https://github.com/IamHBW/omx-lite;commit=7ec85075c648df9b9220b4fc07a6317b967160e3
verified: false
learning_audience: codex
codex_learning: Compare external Codex workflow packages by takeover surface before installing. Full runtimes that manage hooks, config, state, worktrees, team sessions, and implicit routing are usually learn-only or owner-reference in this Windows Codex Desktop architecture; lite methodology packages can contribute manifest, dry-run, backup, explicit-invocation, and size-budget gates after local adaptation.
---

# Oh My Codex and OMX Lite Network Learning

This network learning pass reviewed `Yeachan-Heo/oh-my-codex` at commit
`5319c3d0388b09ad7036e6e3858afd959cfe0eea` and `IamHBW/omx-lite` at commit
`7ec85075c648df9b9220b4fc07a6317b967160e3` on 2026-07-18.

## Comparison

`oh-my-codex` is a full orchestration runtime for Codex CLI. Its package
metadata exposes the `omx` binary, Node.js `>=20`, TypeScript/Rust build paths,
plugin packaging, hooks, setup, doctor, update, team, worktree, mission, and
execution surfaces. Its README states that the recommended default path is
macOS or Linux with Codex CLI, while native Windows and Codex App are not the
default experience. It also uses implicit or natural-language keyword triggers
such as `$ralph`, `keep going`, `autopilot`, `interview`, and `plan this`.

`omx-lite` is a methodology/config package, not a fork or runtime. It contains
`AGENTS.md`, one research profile, three explicit-only skills, three agent TOML
files, install scripts, and a manifest. It explicitly avoids hooks, state
machines, CLI runtime, and automatic keyword routing. Its installer copies a
manifest-defined file set, supports dry-run and check modes, backs up replaced
files, enforces small size budgets, checks `allow_implicit_invocation: false`,
and stops on orphaned full-OMX markers when the `omx` command is unavailable.

## Local Decision

Do not install either upstream package into this architecture by default.

`oh-my-codex` is learn-only or owner-reference here because it overlaps with
existing lifecycle routing, provider continuity, hooks/config safety, release
gates, and skill discovery. Installing it would mutate `$CODEX_HOME` and runtime
state in ways that conflict with the current Windows Codex Desktop operating
model unless a future task explicitly needs the full CLI runtime and can verify
the takeover boundary.

`omx-lite` is a better source of portable packaging ideas, but its raw install
targets do not match this architecture exactly. Its useful ideas should be
adapted into existing owners: manifest-driven install/check, backup-before-copy,
explicit-only imported workflows, size budgets for global guidance, and
conflict-marker detection before replacing hook or config surfaces.

## Adopted Candidates

- Add a scale gate before external skill installation: distinguish a full
  runtime/orchestration layer from a lite methodology package.
- Install only the lightweight methodology subset when the full runtime is not
  needed: interview-first clarification, reviewed planning, and persistent
  completion can live as owner-internal subskills under requirement authoring,
  workflow design, and task execution.
- For full runtimes, require explicit user need, runtime compatibility,
  rollback plan, auth/config smoke test, and proof that existing lifecycle and
  provider-continuity rules will not be shadowed.
- For lite packages, prefer methodology extraction into the current owner model
  instead of preserving upstream roots, names, or install paths.
- Treat explicit invocation as the default for imported external workflows
  until repeated local evidence proves implicit routing improves outcomes
  without accidental activation.
- Use manifest, dry-run, check, backup, size budget, and conflict-marker checks
  as install-quality criteria for external skill packages.

## Deferred

- Do not adopt OMX implicit keyword routing as a global default. This
  architecture already has explicit skill selection, lifecycle routing, and
  user-controlled continuation semantics.
- Do not replace global lifecycle files with an upstream `AGENTS.md`. External
  guidance must be merged into the managed lifecycle block or owner skill that
  already owns the behavior.
- Do not use `.agents/skills` as a canonical global skill root in this
  architecture; `$CODEX_HOME/skills` remains a discovery interface to
  `$ARCHITECTURE_ROOT/skills`.

## Links

- [[Matt Pocock Skills Network Learning]]
- [[Global Experience System]]
- [[Subskill Packaging Boundary]]
- [[Codebase Memory MCP]]

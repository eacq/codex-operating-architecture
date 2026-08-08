---
id: concept-oh-my-codex-omx-lite-network-learning
type: concept

promotion_authority: user-candidate-processing-20260718
promotion_status: structurally-adopted
source: https://github.com/Yeachan-Heo/oh-my-codex;commit=435d4a9cc982ffaf83fabbfbb8711ae6c178ffca; https://github.com/IamHBW/omx-lite;commit=44c5d8ba479b5a27e373e7e0ea5cb30aa48c6c5f
verified: true
learning_audience: codex
codex_learning: Relearn external Codex workflow packages as method systems. Adopt portable gates such as fact-backed planning, explicit invocation, manifest/digest checks, lifecycle outcome vocabulary, authority leases, transport-boundary protection, and redaction tests into existing owners; do not install or copy full runtimes when their hooks, state, worktrees, and plugin surfaces would shadow the local architecture.
---

# Oh My Codex and OMX Lite Network Learning

This note was refreshed on 2026-07-21 after reviewing
`Yeachan-Heo/oh-my-codex` at commit
`435d4a9cc982ffaf83fabbfbb8711ae6c178ffca` and `IamHBW/omx-lite` at commit
`44c5d8ba479b5a27e373e7e0ea5cb30aa48c6c5f`.

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

## Core Philosophy

Upstream-stated ideas:

- `oh-my-codex` describes itself as "better task routing + better workflow +
  better runtime" around Codex rather than a replacement for Codex.
- `omx-lite` describes itself as a methodology-only configuration package,
  explicitly not a fork/runtime and explicitly avoiding hooks, state machines,
  CLI runtime, and automatic keyword routing.

Local synthesis:

- `oh-my-codex` optimizes for a durable runtime layer: explicit workflow
  states, protected transitions, authority ownership, worktree isolation,
  operator diagnostics, and machine-readable contracts. Its core idea is that
  long agent work needs runtime semantics, not only better prompts.
- `omx-lite` optimizes for minimum viable method transfer: keep the useful
  planning, interview, and completion discipline while deleting the runtime
  takeover surface. Its core idea is that methodology can be portable when
  invocation is explicit, files are manifest-controlled, and every high-impact
  premise passes a fact gate.
- The local architecture should combine these by adopting portable semantics
  into existing owners: runtime-like ideas become lifecycle, authority,
  readiness, and redaction contracts; lite ideas become explicit invocation,
  fact-gated planning, manifest checks, and backup-before-copy rules. The
  external runtime itself remains a separate install decision.

The current `omx-lite` revision adds a fact gate to planning workflows. The
portable lesson is stronger than "write a plan": every plan-changing premise
must be classified as an observed repository fact, command output, primary
source, explicit user decision, or hypothesis that must be verified before it
can drive architecture, interface, security, dependency, or acceptance changes.

The current `oh-my-codex` revision has become a full runtime and contract
system. Useful ideas include:

- Canonical terminal lifecycle outcomes: `finished`, `blocked`, `failed`,
  `userinterlude`, and `askuserQuestion`, with explicit evidence, artifacts,
  and handoff.
- State precedence and reconciliation: session-scoped state wins over root
  fallback, compatibility state is a visibility layer, and compatibility sync
  must not resurrect completed modes.
- Protected planning gates: planning-like states cannot be deactivated by
  model/tool-originated transport paths without an explicit allowed handoff.
- Runtime authority leases: one active owner at a time, stale leases are
  explicit, and readiness reports blockers instead of inferring readiness from
  a green doctor/setup check.
- Redaction tests: command summaries and runtime diagnostics redact bearer
  headers, API keys, token-like markers, and repeated secret forms before they
  become logs or model-visible evidence.
- Capability lock files and catalog manifests: large prompt/skill/plugin
  surfaces need digest-backed inventories, not only README claims.

## Local Decision

Do not install either upstream package into this architecture by default unless
a future task needs that exact runtime surface and the install, hook, config,
worktree, auth smoke test, and rollback boundaries are verified first.

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
- Add a fact gate to global planning: high-impact premises must have local
  evidence, a primary source, or an explicit user decision before they can drive
  a plan.
- Use explicit lifecycle outcome labels for persistent completion and long
  global iterations. Assistant prose is not the semantic owner of terminal
  state.
- Treat protected planning/deep-interview state as authority-bearing: execution
  or state-clearing transitions require an explicit accepted handoff, and a
  transport-level command or MCP write is not authority by itself.
- For runtime-like external systems, learn authority leases, stale-owner
  diagnostics, digest manifests, redaction, and readiness smoke-test separation;
  do not import hooks, state machines, tmux/team runtimes, plugin bundles, or
  broad auto-update behavior into the Windows Codex Desktop global architecture.

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

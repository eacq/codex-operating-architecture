# Agency Agents Specialist Design (Owner Reference)

Owner-internal reference distilled from `msitarzewski/agency-agents` ("The
Agency"). Use through `codex-experience-capture` when designing or reviewing
specialist Agent profiles, child-Agent contracts, evidence-acceptance work, or
multi-specialist task planning. This is a handoff artifact, not a new top-level
skill and not permission to copy the upstream package.

## Source grounding

- Source: `https://github.com/msitarzewski/agency-agents`
- Inspected commit: `ebe9c99acb5c96f9468de368d8bead775387d1a7` (2026-08-06)
- License: MIT (Copyright (c) 2025 AgentLand Contributors)
- Local clone: `.runtime/work/network-learning/msitarzewski-agency-agents`
- Inspected surfaces: `README.md`, `divisions.json`, `tools.json`,
  `engineering/engineering-minimal-change-engineer.md`,
  `testing/testing-evidence-collector.md`,
  `examples/nexus-spatial-discovery.md`, `examples/workflow-*.md`,
  `scripts/convert.sh`, `integrations/codex/README.md`.
- Scope rule: reusable method is distilled only from actual artifacts in the
  pinned clone; upstream branding, personal links, app installers, provider
  assumptions, and per-tool install locations are excluded.

## Revalidation (2026-08-09)

The pinned clone was re-read after a failed live refresh attempt. GitHub
network access was unavailable (`Failed to connect to github.com port 443`),
so this is a pinned-commit revalidation, not a claim about the current remote.
The verified snapshot has `HEAD=ebe9c99acb5c96f9468de368d8bead775387d1a7`, 17
registered divisions, 270 source agent files, 16 tool catalog entries, and 4
machine-readable runbooks. `git diff --check` passed in the clean clone.

The deeper reusable pattern is a four-layer system:

1. **Contract layer**: specialist files declare identity, mission, rules,
   deliverables, workflow, communication, memory, and metrics. Recent gated
   specialists make stop conditions and evidence artifacts explicit.
2. **Catalog layer**: `divisions.json` is the division source of truth,
   `tools.json` is the tool/install-format source of truth, and
   `strategy/runbooks.json` maps stable filename slugs to phase-based rosters.
3. **Adapter layer**: `convert.sh` preserves the source body while rendering
   the smallest host-specific format. `install.sh` supports selective
   division/agent installation, dry-run, project/user scope, and bounded
   parallel execution.
4. **Activation layer**: the Hermes integration keeps the full roster on disk
   and exposes search/inspect/load/delegate tools, avoiding startup preload.

Observed caveats are part of the lesson: the 270 files are not perfectly
uniform (header variants and legacy compact agents remain), the README still
advertises `230+` agents and omits the newest catalog tools, and the upstream
examples demonstrate multi-specialist orchestration but do not independently
verify it in the local Codex runtime. Treat upstream production language and
parallel speed claims as unverified until locally measured.

## Source philosophy (stated + local synthesis)

The upstream builds specialists as "deliverable-focused" packages: strong
identity and voice, clear mission, critical rules, technical deliverables with
concrete before/after examples, a workflow, communication style, learning and
memory, and **measurable success metrics**. It organizes a large roster into
divisions (engineering, design, testing, security, ...), publishes multi-agent
workflow examples, and ships per-tool conversion/install scripts. The README's
older `230+` statistic is documentation drift, not the verified snapshot count.

Local synthesis: the reusable core is not the personality text and not the
installers. It is the **specialist contract shape**: every specialist should
declare trigger-precise scope, critical rules, deliverables with evidence, a
workflow, and success metrics, and should be organized into an indexed roster
so a caller can select the smallest specialist set for a mission.

## Local interpretation: specialist-agent design contract

### A. Anatomy mapping

Map the upstream agent-file anatomy onto the local child/profile contract in
`config/minimal-agent-template.json` and `New-MinimalAgentPlan.ps1`:

| Upstream section | Local dimension |
| --- | --- |
| Frontmatter `name` + trigger-precise `description` | child profile id, purpose, and trigger description |
| Identity & Memory / Core Mission | child purpose and allowed operations |
| Critical Rules | denied operations and authority boundary |
| Technical Deliverables with examples | required output artifacts and evidence examples |
| Workflow Process | ordered execution steps and stop conditions |
| Communication Style | typed exit and audience conventions (not persona mimicry) |
| Success Metrics | acceptance criteria and verification gate |

### B. Evidence discipline (adapted from `testing-evidence-collector`)

When a specialist's output is claimed complete or correct:

1. Default to finding issues instead of accepting a first pass ("zero issues"
   is a red flag, not a result).
2. Quote the exact specification text before comparing evidence.
3. Compare rendered/visual evidence against the quote (screenshot, native
   render, or deterministic output), not against memory or intent.
4. Rate honestly (Basic/Good/Excellent; PASS/NEEDS WORK/FAILED) and refuse
   fantasy language such as "perfect" or "production ready" without evidence.
5. Emit issues with priorities and evidence references, then require a re-test
   cycle before acceptance.

This reinforces the existing local rules for visual acceptance (save +
refresh + screenshot; Word-native PDF to 300-dpi PNG comparison) and
`verification-before-completion`.

### C. Minimal-change discipline (adapted from `engineering-minimal-change-engineer`)

For every change, use a scope self-check before submission:

- Task as stated (verbatim).
- Files touched, each with a "required because" reason.
- "While I'm here" temptations listed as follow-ups, not included.
- Abstractions considered and rejected (three similar lines beat a premature
  helper).
- Hypothetical cases intentionally not defended.
- Diff size and "could it be smaller?".

This reinforces the local scope rules: smallest owner-scoped change, no
automatic commit/push/release, and surface-then-follow-up instead of silent
expansion.

### D. Multi-specialist orchestration (candidate, not verified)

The upstream examples (e.g., `nexus-spatial-discovery`) run multiple
specialists in parallel on one mission and merge a unified deliverable with
explicit per-specialist outputs. Local counterpart:
`codex-self-evolution/subskills/collaborative-operating-model/SKILL.md`.
Before adopting a roster-style lane, require a local verified multi-specialist
task and an indexed specialist selection artifact; keep this as a candidate
until then.

## Activation

Use this reference when:

- Designing a new child Agent profile or specialist skill and its acceptance
  criteria.
- Reviewing whether an existing specialist contract has trigger, critical
  rules, deliverables, workflow, and success metrics.
- Planning visual or rendered acceptance for a deliverable.
- Planning a multi-specialist task that needs explicit owner handoffs.

Do not use it when:

- The request is a generic persona or role-play prompt (no contract shape
  needed).
- The task is to install upstream agents or tool integrations wholesale
  (raw `convert.sh`/`install.sh` or `~/.codex/agents` TOML bulk installs are
  rejected; only adapted owner-internal units may enter the canonical repo).
- A neighboring owner already owns the concern (for example
  `codex-exact-word-layout` for layout fidelity or
  `verification-before-completion` for evidence).

## Boundary and rollback

- The reference is advisory; it never expands authority or changes owner
  topology.
- Upstream personality text, provider-specific installers, credentials, and
  private endpoints are excluded.
- Rollback: revert the reference, knowledge note, and test files together; the
  pinned clone under `.runtime/work/network-learning/` can be removed without
  touching canonical skills.

## Pressure-test prompts

- Positive trigger: "设计一个新子代理 profile，需要触发条件、关键规则、交付物、流程和成功指标" ->
  should read this reference.
- Negative lure: "请扮演一个营销专家" -> should NOT route here (persona
  role-play without a contract shape).
- Cross-skill confusion: "这个 Word 模板的排版和渲染不对" -> must route to
  `codex-exact-word-layout`, not to this reference.
- Cross-skill confusion: "提交前先运行验证并给出证据" -> must route to
  `verification-before-completion`/`codex-task-execution`, not to this
  reference alone.


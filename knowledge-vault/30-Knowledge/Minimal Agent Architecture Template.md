---
title: Minimal Agent Architecture Template
type: information-unit
status: active
learning_audience: codex
codex_learning: "Use config/minimal-agent-template.json plus New-MinimalAgentPlan.ps1 to design bounded child Agents from the Global Experience Agent without adding a second controller or expanding authority."
owner: codex-experience-capture
verification:
  - skills/codex-experience-capture/scripts/Test-MinimalAgentTemplate.ps1
  - scripts/Test-GlobalExperienceAgent.ps1
---

# Minimal Agent Architecture Template

The minimal Agent template extracts the smallest reusable child-Agent contract
from the current Global Experience Agent:

1. identity: child id, parent session, and registered concept or specialist
   Agent profile;
2. authority: inherited current authority, never expanded by the child;
3. task: bounded goal, inputs, excluded scope, and selected resources;
4. work surface: isolated write paths and read-only evidence surfaces;
5. completion: acceptance criteria, repository-relative result evidence, and a
   parent merge verifier;
6. lifecycle: delegated, completed, joined, or cancelled;
7. safety: privacy boundary, non-retryable operations, and error-feedback route.

The template lives at `config/minimal-agent-template.json`. The functional unit
is `skills/codex-experience-capture/scripts/New-MinimalAgentPlan.ps1`.

The template also carries the seven `LesterYu0/feynman-build-workshop`
structural improvements that the Global Experience Agent already uses:

1. memory system;
2. intent recognition;
3. document parse pipeline;
4. chunking retrieval;
5. rerank calibration;
6. bounded Agent loop;
7. memory as skill.

These are stored as `feynman_structural_scaffold` for compatibility. They are
also part of the broader versioned learning baseline in
`config/agent-structural-optimization-policy.json`, which additionally carries
authority interfaces, owner/tool gates, durable child lifecycle, error
feedback, Codebase Memory evidence, skill invocation governance,
caller/model-neutral continuation, typed exits and save points, retry/recovery,
redacted observability, review checkpoints, resource economy, extension trust,
human evaluation, and the propagation rule itself. Every future child-Agent
plan inherits the current content-hashed baseline, but inheritance is adaptive:
learned results are compared with the child's purpose, allowed operations,
owner contracts, source types, output artifacts, quality gates, merge verifier,
privacy boundary, and recovery behavior before they are used. Registered child
profiles declare compatibility, a domain adaptation, a profile-fit summary, and
functional effect categories such as routing, memory, source processing,
retrieval, tool use, output quality, review, recovery, or economy. Dynamic
concept/specialist children inherit directly from the template and do not
invent profile-specific domain adaptation.

An accepted Global Experience Agent optimization is incomplete until
`Sync-ChildAgentStructuralOptimizations.ps1 -Apply` has synchronized the
template, registry, manifest, and projections with the profile adaptations.
`DelegateSubagent` then injects the effective snapshot into durable child state.
A stale named profile, or a named profile with only a baseline id set and no
functional adaptation, is rejected before a child directory or delegation event
is created. Ordinary child use never writes tracked architecture files or
expands authority.

The planner may infer a concept Agent for common task families, or accept an
explicit specialist owner. It produces a JSON contract by default. It delegates
only when called with `-Delegate -Apply -SessionId`, and then it forwards to the
existing root controller's `DelegateSubagent` operation. The planner does not
execute the child task; it creates the bounded child work envelope that another
authorized caller or model host may complete.

## Links

- [[Global Experience System]]
- [[Agent Memory System]]
- [[Agent Loop System]]
- [[Agent Skill Invocation Governance]]

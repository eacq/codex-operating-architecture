---
id: concept-matt-pocock-skills-network-learning
type: concept

promotion_authority: user-candidate-processing-20260718
promotion_status: guarded
source: https://github.com/mattpocock/skills;commit=9603c1cc8118d08bc1b3bf34cf714f62178dea3b
verified: false
learning_audience: codex
codex_learning: Matt Pocock skills reinforce skill economy through invocation load, information hierarchy, explicit completion criteria, repo-local setup documents, and feedback loops; external skills can be installed only after necessity, value, compatibility, and verification are established.
---

# Matt Pocock Skills Network Learning

This network learning pass reviewed `mattpocock/skills` at commit
`9603c1cc8118d08bc1b3bf34cf714f62178dea3b` on 2026-07-18.

## Adopted Candidates

- Distinguish user-invoked orchestration skills from model-invoked reusable
  discipline. In this architecture, the equivalent is to keep parent skills as
  discovery/routing surfaces and move detailed modes to subskills or references
  only when the trigger needs autonomous reach.
- Treat skill text as an information hierarchy. Required steps and completion
  criteria stay near the action; branch-specific detail moves behind direct
  pointers.
- Split a sequence only when later steps cause premature completion of the
  current step. First sharpen the completion criterion.
- Use repo-local setup documents for tracker, domain language, and ADR
  conventions. This maps to `.codex/project` lifecycle files rather than a new
  global setup skill.
- For debugging, require a tight red-capable feedback loop before broad
  hypotheses. This aligns with `codex-error-feedback` and may become a stronger
  repair criterion after repeated use.

## Rejected Or Deferred

- Do not raw-copy the upstream skill set into this repository. Installation is
  allowed when a specific skill is necessary, valuable, compatible with local
  privacy/profile/validation rules, and better as an installed skill than as an
  owner reference or subskill.
- Do not adopt plugin-specific or `skills.sh` installation assumptions into
  global rules; keep them as source context only.
- Keep two-axis code review as a candidate for future `codex-task-execution` or
  `codex-git-operations` refinement rather than changing review behavior from a
  single external source.

## Compatible Installation Rule

The local target is not "copy the upstream best practice exactly." The target is
the most suitable local form: learn-only, owner reference, owner subskill,
project-local skill, or global skill. The installed form should preserve the
useful behavior while rewriting triggers, setup, profiles, safety boundaries,
and validation to match the Codex experience system.

## Requirement Workflow Revalidation

On 2026-07-18, the current upstream repository was rechecked. Its engineering
catalog describes `to-spec` as a conversation-to-spec path and separates it
from interview-led `grill-with-docs`; its productivity catalog lists `grilling`
as the reusable clarification discipline. The local adaptation is deliberately
narrow: `codex-requirement-authoring` now supports conversation-to-spec by
default and records project-local vocabulary plus consequential decisions only
when repeated ambiguity changes a downstream handoff. It rejects automatic
issue publication, `CONTEXT.md`, automatic ADRs, raw conversation capture, and
mandatory interviewing. The local generator and double architecture validation
passed; this validates the adaptation, while the broader upstream note remains
guarded until an independent real project use confirms it.

## Combined Relearning With Codebase Memory MCP

The second pass paired this repository with
`DeusData/codebase-memory-mcp` at commit
`e678b2b6acb02bc1ab84a854f2df0e1d092f2cc0`. The useful combined workflow is:

1. Treat an external skill repository as a source codebase, not only prose.
   Index it when codebase-memory-mcp is exposed, inspect schema/architecture,
   and read the concrete files behind any adopted claim.
2. Use Matt Pocock's skill-economy criteria to decide whether the external
   pattern deserves a local form: invocation load, information hierarchy,
   completion criterion, and feedback loop.
3. Use the Codex experience system to decide where it belongs: learn-only note,
   owner reference, owner-internal subskill, project-local skill, or global
   top-level skill.
4. Install only when the skill has necessary and reusable value that cannot be
   captured cleanly as a note or owner reference. The installed version must be
   rewritten for local triggers, privacy, profile assumptions, validation, and
   removal or revision.

This keeps external learning efficient without treating "do not raw-copy" as
"never install."

## Links

- [[Experience Knowledge Subskill Refinement]]
- [[Global Experience System]]
- [[Subskill Packaging Boundary]]

---
name: codex-requirement-authoring
description: Turn unclear or incomplete requests into requirements, assumptions, acceptance criteria, constraints, and implementation-ready task briefs.
---

# Codex Requirement Authoring

1. Preserve the user's literal goals and constraints.
2. Use evidence to resolve discoverable ambiguity.
3. State conservative assumptions where choices are reversible.
4. Ask only when an undiscoverable choice materially changes the result.
5. Define observable acceptance criteria, exclusions, risks, and validation.
6. Keep requirements separate from implementation details unless the detail is a real constraint.

For material or global-system work, create a durable normalized brief with
`scripts/New-NormalizedRequirementBrief.ps1 -Apply` before implementation. Its
contract is in [references/normalized-requirement-contract.md](references/normalized-requirement-contract.md).
The brief distinguishes literal goal, constraints, authority, reversible assumptions,
exclusions, acceptance criteria, and validation; it does not expand authority.
Use the shared collaboration terminology in
`$ARCHITECTURE_ROOT\docs\SKILL-TERMINOLOGY.md` when a requirement spans the
user, model, and the local Global Experience Agent. Put only task-specific or repeatedly
ambiguous domain terms in the brief's `Vocabulary` field.

## Adapted requirement modes

- **Conversation-to-spec:** when the existing user conversation and project evidence
  already determine the outcome, synthesize them directly into the normalized brief
  without an interview, issue-tracker publication, or external side effect.
- **Terminology-and-decision clarification:** use only when repeated domain terms or
  a consequential decision ambiguity would change implementation or verification.
  Record concise vocabulary and decision entries in the brief; do not create a global
  `CONTEXT.md`, automatic ADR, raw conversation capture, or mandatory questioning.

For historical reconstruction, cite the relevant artifact and date. Mark inferred requirements explicitly.

For explicit interview-first clarification, use
[subskills/deep-interview-lite/SKILL.md](subskills/deep-interview-lite/SKILL.md).
Keep the mode lightweight: ask only questions that materially change the result,
then return an execution-ready brief.

For a creative, feature, or system-design request whose intended result is not
yet implementation-ready, use
[subskills/brainstorming-lite/SKILL.md](subskills/brainstorming-lite/SKILL.md).
It explores the smallest consequential unknowns, compares bounded approaches,
and forms a validation-aware design before handing off. It is not a mandatory
pause for a bounded, reversible task that conversation and local evidence
already specify.

The Global Experience Agent must not autonomously route to
`brainstorming-lite` merely because a proposed workflow, skill, experience, or
architecture change has an unresolved choice. Use `brainstorming-lite` only on
explicit user request for brainstorming/design exploration, or when
`codex-requirement-authoring` is already the active owner and a
non-discoverable consequential choice blocks an execution-ready brief. In all
other bounded, reversible, or locally decidable cases, use conversation-to-spec
or hand off directly to the responsible execution owner.

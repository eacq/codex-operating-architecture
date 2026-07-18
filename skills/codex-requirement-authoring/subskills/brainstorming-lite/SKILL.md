---
name: codex-requirement-authoring-brainstorming-lite
description: Owner-internal collaborative design mode for ambiguous creative, feature, or system requests. Use through codex-requirement-authoring to turn an idea into an execution-ready, validation-aware design without expanding authority or delaying bounded work.
---

# Brainstorming Lite

Use this subskill only through `codex-requirement-authoring`. It selectively
adapts the idea-to-design discipline learned from `obra/superpowers`; it is not
an imported plugin, runtime, telemetry channel, or automatic implementation
gate.

## Trigger

Use when a creative, feature, workflow, or system-design request has a material
unknown that local evidence cannot resolve and that changes scope, quality,
authority, safety, cost, or validation. If the existing conversation and local
evidence already make a low-risk, reversible task execution-ready, use
conversation-to-spec instead. Do not turn ordinary vagueness into an interview.

The global experience system may autonomously open this mode when it detects a
material unresolved choice in a proposed skill, workflow, experience, learning,
or architecture change. The autonomous path must stay small: identify the
branch, compare only materially different options, choose a reversible
recommendation when evidence supports one, and ask the user only at a real
authority or decision boundary. Do not use autonomous brainstorming to delay
bounded repairs, obvious documentation updates, validation-only checks, or
routine candidate reporting.

## Flow

1. Inspect only the project context needed to identify existing constraints,
   interfaces, and comparable patterns. State the literal goal, discovered
   facts, and the smallest material unknown.
2. Ask one concise question at a time only while its answer changes a
   consequential branch. Prefer a short choice with a recommendation when it
   reduces user effort; accept a free-form answer when the user needs to define
   the goal.
3. If the request contains independent subsystems, decompose it into a smallest
   valuable first slice before refining details. Do not turn decomposition into
   permission to implement every slice.
4. Offer two or three feasible approaches when alternatives materially differ.
   For each, state outcome, trade-off, resource impact, safety/authority impact,
   and validation. Recommend one based on the user's stated goal and existing
   evidence; avoid false alternatives for a clearly dominant low-risk option.
5. Present a scaled design: intended outcome, boundaries and handoffs, key
   components/data or decision flow, failure handling, acceptance criteria,
   validation, and explicit exclusions. A small change may need only a compact
   paragraph; a non-linear design may use a visual only when it is genuinely
   clearer than text and the normal image-workflow format gate permits it.
6. Ask for confirmation only when the design selects a consequential or
   irreversible branch, changes user authority, or remains materially ambiguous.
   Otherwise record the conservative reversible assumption and transition
   directly to the normalized brief.
7. Write or refresh the normalized requirement brief. Hand a repeatable process
   design to `codex-workflow-design`; hand an execution-ready scoped change to
   `codex-task-execution`. The receiving owner rechecks acceptance criteria and
   does not treat brainstorming as implementation authorization.

## Output

Produce a concise design record in the normalized requirement brief:

- Literal goal and user-visible success condition.
- Discovered facts, explicitly labeled assumptions, and resolved choices.
- Considered approaches and why the recommendation fits.
- Scope boundary, exclusions, authority boundary, and resource-relevant choice.
- Acceptance criteria, validation, fallback, and next accountable owner.

## Safety and Economy

Do not require a full design document, browser companion, Git commit, visual,
or user approval merely because an idea was mentioned. Do not install software,
start agents, access credentials, publish, make paid calls, or mutate external
state. Stop questioning once remaining uncertainty is low-risk, discoverable,
or safely reversible. Preserve the user's final decisions verbatim in the
brief; never substitute model preference for user authority.

## Verification

Before handoff, verify that the design has one named outcome, no unresolved
consequential contradiction, an acceptance criterion for each selected branch,
and a matching validation method. If evidence is insufficient to recommend an
approach, report the decision blocker rather than inventing a design.

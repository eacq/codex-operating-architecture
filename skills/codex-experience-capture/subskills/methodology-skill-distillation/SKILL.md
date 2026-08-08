---
name: codex-experience-capture-methodology-skill-distillation
description: Distill external methodologies, upstream skill repos, or repeated practices into evidence-bearing experience-system skills, references, knowledge, or candidates.
---

# Methodology Skill Distillation

Use this subskill only through the parent `codex-experience-capture` owner and
the Global Experience Agent entry path. It adapts the RIA-TV++ pattern learned
from `kangarooking/cangjie-skill` commit
`355dd47a97eeb87d249bf7d32aab561405b6de76` into this repository's experience
system. Do not copy upstream package shape by default.

## Purpose

Turn a source methodology into a small set of reusable, callable Agent skills or
experience records. The output is not a summary. It must preserve when the
method should trigger, what it does, what evidence supports it, when it should
not be used, and how future agents can test it.

## Admission

Before changing a skill, classify the source as one of:

- `learn-only`: keep a knowledge or candidate record when the source is useful
  but not yet verified against local work.
- `owner-reference`: add a concise rule under an existing owner when the method
  improves a current workflow without a distinct lifecycle.
- `owner-subskill`: create or update an owner-internal subskill when the method
  has distinct steps, artifacts, and validation while sharing the owner's
  safety boundary.
- `project-local skill`: keep project-specific practice in the project.
- `global skill`: use only when no current owner fits and registry evidence
  justifies a new top-level boundary.

Default to `owner-reference` or `owner-subskill` inside existing owners.

## Distillation Pipeline

1. **Source grounding**
   - Capture source URL, commit, license, inspected files, and local scope.
   - Require actual text or artifacts; do not distill from memory alone.
   - Separate reusable method from branding, personal links, install locations,
     provider assumptions, credentials, and upstream-only runtime choices.

2. **Whole-method understanding**
   - Identify the source's mission, target user, lifecycle, artifacts, and
     quality gates.
   - Record the problem it solves for an Agent, not just for a human reader.

3. **Parallel candidate extraction**
   - Extract candidate units along five lenses:
     `framework`, `principle`, `case`, `failure-mode`, and `terminology`.
   - Use child Agents only when the current task explicitly authorizes
     delegation or an applicable runtime contract does; otherwise run the same
     lenses serially.
   - Keep rejected and weak units as candidates when they may be useful later.

4. **Experience triple verification**
   - V1 `cross-context`: the unit appears in at least two independent source
     contexts or one source context plus one local verified use case.
   - V2 `transfer`: the unit predicts a useful action for a new task that the
     source did not explicitly solve.
   - V3 `non-common`: the unit is not generic advice the base model already
     knows; it adds a trigger, boundary, workflow, or evidence requirement.
   - Only units passing all three can become owner-facing instructions.

5. **Experience RIA++ shaping**
   - `R` Record: source pointers, short compliant excerpts when needed, and
     provenance hashes.
   - `I` Interpret: restate the reusable method in local architecture terms.
   - `A1` Applied evidence: cite the source example or local project use.
   - `A2` Activation: write exact trigger and non-trigger conditions for the
     skill `description`.
   - `E` Execution: define ordered steps, stop conditions, artifacts, and owner
     handoffs.
   - `B` Boundary: define safety limits, false positives, stale conditions, and
     rollback or candidate handling.

6. **Link and install**
   - Link the unit to existing owners, concept Agents, information units, and
     functional units.
   - Prefer a handoff artifact over duplicate parent-skill text.
   - Install into the canonical architecture repo only; global Codex-home
     skill folders are discovery interfaces.

7. **Pressure test**
   - Add test prompts or a deterministic regression when behavior changes.
- Include positive triggers, negative lures, and at least one cross-skill
  confusion case. Treat this as the `cross-skill confusion` regression: a
  prompt that should trigger a neighboring skill must not be claimed by the new
  one.
   - If trigger precision fails, repair the `A2`, `E`, or `B` sections rather
     than masking the failure with a vague description.

## Output Contract

For every accepted methodology unit, write or update the smallest necessary
artifact:

- `SKILL.md` with valid `---` YAML frontmatter containing only `name` and
  `description`.
- Optional `references/` only when detailed source mappings are too large for
  the skill body.
- Optional `scripts/` only for deterministic checks or repeated mechanical
  work.
- Knowledge note or workflow-learning record when the result is conceptual
  rather than directly callable.
- Candidate report entry when evidence is promising but not verified.

## Cangjie Lessons Adapted

- Atomic callable units are more valuable than broad summaries.
- Trigger quality is a first-class deliverable; a good skill states when to
  call it and when not to call it.
- Candidate and rejected units should remain auditable instead of disappearing.
- Stage state enables continuation after interruption.
- Test prompts with lures catch over-triggering earlier than normal validation.
- Source methods must be rewritten into the local owner/Agent vocabulary before
  promotion.

## Verification

Run the narrowest checks that cover the change:

```powershell
skills/codex-experience-capture/scripts/Test-MethodologySkillDistillation.ps1 -RepositoryRoot F:\codex
```

For complete global iterations, also run the standard Agent filesystem sync,
knowledge builders, and repository validation required by the Global Experience
Agent closeout.

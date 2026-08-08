---
id: concept-project-vocabulary-decision-brief
type: workflow

promotion_authority: user-candidate-processing-20260718
promotion_status: guarded
source: https://github.com/mattpocock/skills;release=v1.1.0;local-gap-review-2026-07-18
verified: false
learning_audience: codex
codex_learning: For requirement work with repeated domain ambiguity, trial a project-local vocabulary and decision brief under codex-requirement-authoring; validate its effect on one real follow-on workflow before promoting it to a reusable subskill or rule.
---

# Project Vocabulary and Decision Brief

## Trigger

Use only when a project has repeated domain terms, competing meanings, or a
decision that later workflows must interpret consistently. Ordinary bounded
implementation work should keep using the existing requirements and workflow
files without an extra artifact.

## Candidate workflow

1. Record a concise, project-local vocabulary: term, agreed meaning, source or
   owner, and unresolved ambiguity.
2. Record a decision brief only for a consequential choice: context, options,
   decision, consequence, evidence, and invalidation condition.
3. Link the brief from project requirements or the affected workflow; do not
   copy private source text, credentials, raw conversation history, or local
   paths into global knowledge.
4. Verify a real downstream handoff can resolve the named terms and decision
   without reopening the same ambiguity.

## Owner and boundary

`codex-requirement-authoring` owns the project-local artifact and its user
clarification boundary. `codex-knowledge-system` may index a sanitized durable
concept only after independent verification. This does not justify a new global
skill, a mandatory `CONTEXT.md`, or automatic ADR generation.

## Evidence and status

The current upstream re-learning found that `mattpocock/skills` v1.1.0 pairs
requirements grilling with a shared project language and decision records. The
canonical architecture already has requirements, workflows, and linked
knowledge, but no verified repeatable vocabulary-brief handoff. This is one
external source plus a local gap review, so it remains a candidate until one
real project use demonstrates a clearer downstream handoff and a second
independent source or reuse confirms its value.

## Links

- [[Learning Governance]]
- [[Project Creation Capability]]
- [[Subskill Packaging Boundary]]
- [[Verified Experience Promotion]]

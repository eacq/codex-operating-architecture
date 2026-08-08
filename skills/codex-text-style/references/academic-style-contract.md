# Academic Style Contract

## Scope

Use this contract for expression-level academic prose work. It applies to journal manuscripts, theses, abstracts, section prose, captions, reviewer responses, and bilingual translation. It does not establish factual truth, validate citations, alter research design, or repair document layout.

## Style Profile

Capture only the decisions that affect revision:

| Field | Record |
| --- | --- |
| Audience | discipline, expertise, and intended readers |
| Genre | manuscript section, thesis, response, caption, or translation |
| Baseline | supplied exemplar, venue guidance, or neutral academic default |
| Language | Chinese, English with US/UK convention, or translation direction |
| Evidence posture | descriptive, correlational, causal, theoretical, or methodological |
| Intervention | diagnosis, minimal revision, or profile before drafting |

Treat a named venue as context, not permission to imitate unsupported claims or a stereotype of its style.

## Revision Gates

Before delivery, compare the revised text with the source.

1. Preserve values, units, effect direction, qualifiers, citations, technical terms, formulas, and markup.
2. Preserve the distinction among observation, interpretation, and implication.
3. Keep causal language no stronger than the stated design supports.
4. Keep terminology, abbreviations, tense, and language convention consistent in scope.
5. Prefer a concrete logical revision over cosmetic synonym replacement.
6. Report unresolved ambiguity, evidence gaps, or conflicts instead of inventing a repair.

## Output Shapes

Use a minimal revision when the requested scope is clear:

```text
Revised text

Change summary: clarity, cohesion, terminology, or register changes.
Open risks: only unresolved meaning or evidence risks.
```

Use a diagnostic report when the request is broad or the change could alter meaning:

```text
Location: section or paragraph
Severity: blocker, material, or polish
Observation: observable wording or logic issue
Recommendation: bounded revision or author confirmation needed
```

## Evidence Basis

The first iteration cross-checked three independent academic-writing surfaces on 2026-07-16:

- `bahayonghang/academic-writing-skills`: separates source editing, audit, bibliography, and format-specific workflows; requires preserving source syntax and marking evidence as pending.
- `Haojae/scipilot-writing-skill`: combines deterministic checks with semantic review and explicitly protects numbers, formulas, citation keys, and conclusion direction.
- `Figpad/academic-writing-polisher`: uses context-first, author-intent-preserving revision with explicit meaning-risk flags.

These repositories inform workflow boundaries, not correctness of their individual lint rules. Re-evaluate the contract when a target discipline or venue supplies primary style guidance, or when repeated real tasks reveal a missing category.

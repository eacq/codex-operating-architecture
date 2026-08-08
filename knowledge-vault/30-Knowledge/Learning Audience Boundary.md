---
id: concept-learning-audience-boundary
type: concept
status: active
source: user-correction-2026-07-14
verified: true
learning_audience: both
codex_learning: Separate Codex-local operating knowledge from user study; send internal rules to the Codex learning index and export only explicitly user-facing recall material to Anki.
anki_question: What is the difference between Codex-local learning and your Anki learning?
anki_answer: Codex-local learning stores verified operating rules for future task execution and skill iteration; your Anki contains only concepts you personally benefit from recalling.
anki_deck: Knowledge System
---

# Learning Audience Boundary

Codex and the user are different learners. A useful rule for future task execution is not automatically something the user should memorize.

```mermaid
flowchart LR
    E[Verified note] --> D{Who benefits from recall?}
    D -->|Codex| C[Codex local learning index]
    D -->|User| A[User Anki TSV]
    D -->|Both independently| B[Both outputs]
    C --> S[Experience and skill iteration]
    A --> U[User spaced repetition]
```

## Codex-local learning

Use `learning_audience: codex` and `codex_learning`. The generated JSON is a local retrieval index for future Codex tasks. Promotion into a skill still requires [[Verified Experience Promotion]].

## User learning

Use `learning_audience: user` with `anki_question` and `anki_answer`. The prompt must test knowledge the user personally needs for research, technical judgment, or repeated decisions.

## Both

Use `both` only when the Codex operating rule and the user's recall goal each have independent value. Write separate wording for each audience rather than reusing one field mechanically.

This boundary is owned by [[Knowledge System Module]] and summarized in [[Experience and Knowledge Architecture]].

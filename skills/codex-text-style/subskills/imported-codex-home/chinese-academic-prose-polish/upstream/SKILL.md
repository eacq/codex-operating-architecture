---
name: chinese-academic-prose-polish
description: Polish Chinese academic prose for engineering manuscripts, theses, journal papers, review responses, and technical abstracts. Use when the user asks to remove AI-like wording, improve Chinese scholarly logic, make wording precise and natural, preserve the author's latest edits, refine section/paragraph/sentence flow, or align language with common Chinese mechanical-engineering journal style.
---

# Chinese Academic Prose Polish

## Non-Negotiables

Use the latest user-edited text as the base. Preserve technical meaning, data, equation references, figure/table references, citation numbers, and the paper's core innovation.

Do not polish by adding empty grandeur. Prefer accurate subjects, precise verbs, restrained modifiers, and clear causal relations.

## Whole-to-Local Pass

1. Whole paper: check whether title, abstract, introduction, method, results, and conclusion answer the same research question.
2. Section: check whether each section opens with purpose and closes with a result or transition.
3. Paragraph: reorder sentences into background -> problem -> method/evidence -> implication when needed.
4. Sentence: replace generic wording with mechanism-specific wording.
5. Terms: make technical terms consistent across Chinese and English.

## Style Targets

- Use problem-method-result wording only when a real problem and method follow.
- Use result claims only when quantitative evidence follows.
- Use broad value claims sparingly; prefer concrete engineering value.
- Replace mechanical transition chains with causal transitions.
- Avoid stacked abstract nouns when a direct verb works.

## Local Editing Modes

- **Light polish**: improve wording without changing sentence order.
- **Logic polish**: reorder sentences and add missing transitions.
- **Reviewer polish**: make claims more cautious, evidence-linked, and defensible.
- **Anti-AI polish**: reduce template phrases, symmetric lists, and over-smoothed transitions.

Use `references/language_patterns.md` for Chinese sentence-level checks and replacements.

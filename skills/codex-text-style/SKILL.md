---
name: codex-text-style
description: Revise academic prose and coordinate source-grounded academic research work in Chinese, English, or bilingual manuscripts. Use when polishing papers, theses, abstracts, LaTeX drafts, captions, reviewer responses, or translations, or when planning paper/PDF, evidence, research-code, and figure tasks that must preserve author intent, source locators, claims, citations, numbers, formulas, and document markup.
---

# Academic Text Style

Treat style work as expression-level editing, not research generation or factual review. Read [references/academic-style-contract.md](references/academic-style-contract.md) before an unfamiliar genre, venue, or delivery mode. Read [references/academic-workflow-contract.md](references/academic-workflow-contract.md) when the request spans source reading, evidence, writing, code, or figure work.

For an existing manuscript, thesis, abstract, or conclusion, read
`references/manuscript-revision-pipeline.md`. It defines the whole-to-local
revision order, protected-text boundary, citation/field-safe handling, and the
handoff to exact Word layout. Do not create a separate paper-polishing skill
when this owner already covers the expression-level work.

## Establish the Target

Identify the language, discipline, genre, target venue or institution, requested operation, and desired intervention level. Use an author-supplied passage or venue guidance as the style baseline; do not infer a named journal style from its reputation.

Choose one mode:

- **Diagnose**: report issues and meaning risks without rewriting. Use this by default for whole manuscripts, ambiguous requests, or text with material claim risk.
- **Minimal revision**: improve clarity, cohesion, precision, concision, and academic register while preserving the author's voice.
- **Profile**: record an explicit reusable style brief before drafting or a larger revision.

Ask only for information that materially affects the result. State a bounded default when it is missing: neutral, discipline-appropriate academic prose with minimal intervention.

## Academic Research Workflow Submodule

Use this submodule when academic work crosses paper/PDF/LaTeX reading, evidence synthesis, manuscript drafting, research-code analysis, or figure planning. Start with a project-local research manifest:

```powershell
.\scripts\New-AcademicResearchManifest.ps1 `
  -ProjectRoot <project-root> `
  -Mode PaperRead `
  -Goal '<research question>' `
  -Source <paper-or-repository-path>
```

Choose `PaperRead`, `EvidenceSynthesis`, `ManuscriptDraft`, `ResearchCode`, or `FigurePlan`. Record source locators and evidence status before downstream work. The manifest is metadata only; never include source text, private data, credentials, or unsupported claims.

Separate observations, interpretations, and proposed claims. Preserve locators such as page, section, figure, table, equation, file, function, or commit. Mark missing access, extraction uncertainty, unsupported claims, and unverified citations as pending rather than inferring them.

These modes are implemented as headless compositions of the global modules. No interactive UI is required to use them: invoke the routed skills directly and retain the manifest as the control artifact.

## Preserve Meaning

Do not silently change factual claims, numerical values, effect directions, causal strength, uncertainty, citations, technical terms, formulas, or LaTeX/Markdown/Word structural markup. Flag an ambiguity, overclaim, unsupported inference, terminology conflict, or missing evidence instead of filling it in.

Keep the claim-evidence relationship calibrated. Hedge only when the evidence is limited; do not make defensible findings sound weaker merely to sound academic. Preserve established terminology and define a changed term only when the user approves it.

## Perform the Revision

1. Read the requested scope and its immediate argument context before changing a sentence.
2. Build a compact style profile: audience, genre, language convention, evidence posture, preferred voice, and constraints.
3. Revise the smallest surface that achieves the requested outcome. Improve paragraph logic before substituting synonyms.
4. Check terminology, abbreviations, tense, reference pointers, citation keys, numbers, formulas, and markup against the original.
5. Read once as the target academic audience: remove mechanical transitions, vague actors, inflated novelty, and unsupported generalizations.

For whole-manuscript revision, work in this order: argument/section diagnosis,
paragraph logic, local expression, then render-driven layout compaction only
when a locked DOCX requires it. Keep citation-bearing, field-bearing, and
equation-bearing paragraphs structurally intact unless the relevant run-level
markup is explicitly preserved and checked.

For Chinese prose, prioritize precise terminology, natural scholarly syntax, and restrained use of formulaic connectors. For English prose, prioritize explicit subjects and relations, controlled sentence length, discipline-appropriate hedging, and consistent US or UK convention. For translation, preserve epistemic strength and technical meaning before pursuing idiomatic fluency.

Describe observable template-like wording rather than claiming that text is
"AI-generated": generic praise, vague actors, stacked abstract nouns,
formulaic transitions, symmetrical lists without a logical relation, inflated
novelty, or unsupported broad value claims. Replace only when the source
context supports a more concrete subject, relation, mechanism, condition, or
evidence pointer.

## Deliver a Verifiable Result

For a direct revision, return the revised passage and a short change summary. Separately list any unresolved meaning or evidence risks. For diagnosis, prioritize blockers and show location, original concern, severity, and a bounded recommendation.

Do not claim a text meets a venue's requirements without checking its current primary guidance. Do not label wording as "AI-generated" from style alone; describe observable textual features instead.

## Route Adjacent Work

- Route paper/PDF source triage and evidence collection to `codex-information-gathering`; use an installed reader or PDF skill only as an optional format-specific enhancement.
- Route citation existence, bibliographic fields, and claim support to the available literature-search or reference-verification workflow.
- Route substantive argument, data, methods, or result interpretation changes to the author for confirmation.
- Route locked-template DOCX layout and rendered page-flow work to `codex-exact-word-layout`.
- Route document creation or tracked changes to the document workflow, keeping this skill responsible only for text style.
- Route research-code explanation and changes to `codex-information-gathering` and `codex-task-execution`; route evidence-based figures to `codex-image-workflow` or Mermaid.

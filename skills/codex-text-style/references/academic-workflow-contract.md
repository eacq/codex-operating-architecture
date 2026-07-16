# Academic Research Workflow Submodule

## Purpose

Coordinate academic work that crosses source reading, evidence synthesis,
manuscript drafting, research-code interpretation, and figure planning. This
submodule owns the task plan and evidence handoffs. Specialist skills own
extraction, citations, layout, code mutation, and image generation.

## Intake

Record the research question, desired deliverable, mode, source locators,
audience, deadline or scope, and privacy constraints. A locator can be a DOI,
arXiv URL, local file, repository path, commit, figure, table, or section. Do
not treat a filename, title, or URL as evidence by itself.

## Mode Contracts

| Mode | Minimum artifact | Completion condition |
| --- | --- | --- |
| PaperRead | source map plus reading questions | findings cite page/section/figure/table or state extraction limits |
| EvidenceSynthesis | claim-evidence matrix | every material claim is supported, disputed, or pending |
| ManuscriptDraft | argument-evidence matrix | prose does not add facts beyond mapped evidence |
| ResearchCode | repository and data-flow map | explanation distinguishes observed behavior from hypotheses |
| FigurePlan | claim-panel-provenance map | each visual element serves a named evidence-backed purpose |

## Headless Capability Matrix

The submodule is a control plane over existing global capabilities, not a UI
placeholder. Invoke these owners directly when the manifest selects a mode:

| Mode | Headless global implementation |
| --- | --- |
| PaperRead | `codex-information-gathering` for source triage and bounded extraction, then `codex-knowledge-system` for durable notes |
| EvidenceSynthesis | `codex-information-gathering` for evidence ranking plus `codex-knowledge-system` for claim-source links |
| ManuscriptDraft | `codex-text-style` for argument and prose, then `codex-exact-word-layout` when locked DOCX page fidelity matters |
| ResearchCode | `codex-information-gathering` for repository mapping and `codex-task-execution` for inspected changes and verification |
| FigurePlan | `codex-image-workflow` for evidence-backed visual production; use Mermaid when a structural diagram is sufficient |

Installed paper, PDF, literature, citation, document, or domain skills can
enhance a route, but are not the prerequisite for the workflow contract.

## Evidence Status

Use `supported`, `disputed`, `pending`, or `out-of-scope`. Preserve the source
locator and confidence when information was extracted imperfectly. A model
response, a search result, a title, or agreement among models is not an
evidence status.

## Boundaries

- Read only the source scope needed for the selected mode.
- Preserve LaTeX, Markdown, Word, code, and data structure unless the owning
  specialist workflow authorizes a write.
- Ask before expanding source scope, uploading private material, or using a
  paid or remote service.
- Keep source text and private project facts out of global knowledge. Promote
  only repeatable workflow rules.
- Do not treat the absence of an interactive UI as a missing capability; the
  manifest and global-skill routing are the supported headless interface.

## GPT Academic Inspiration

This submodule derives workflow principles, not code, from
`binary-husky/gpt_academic` (reviewed 2026-07-16, GPL-3.0): task-specific
paper/PDF/LaTeX handling, research-code analysis, Mermaid diagrams, and
modular function routing. The adopted principles are source-first routing,
explicit intermediate artifacts, and composable specialist handoffs.

Excluded: its source code, web UI, dependency stack, provider/account model,
multi-model parallel calls, and dynamic plugin execution. Those concerns are
owned by other local modules or require separate user authorization.

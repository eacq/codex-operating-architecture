---
id: concept-baoyu-skills-network-learning
type: concept

promotion_authority: user-candidate-processing-20260718
promotion_status: guarded
source: https://github.com/JimLiu/baoyu-skills;commit=6b7a2e417500561a5ecdd0b168332f4142584617
verified: false
learning_audience: codex
codex_learning: Review Baoyu skills by individual takeover surface, not as a bundle. Keep browser-cookie, credential, publishing, and multi-provider capabilities out of global installation; trial only a project-local, explicitly authorized diagram workflow after runtime and output validation.
---

# Baoyu Skills Network Learning

This network-learning review inspected `JimLiu/baoyu-skills` at commit
`6b7a2e417500561a5ecdd0b168332f4142584617` on 2026-07-18. The repository
contains 21 skills and shared TypeScript packages for image generation, Markdown
rendering, URL extraction, and Chrome CDP operations. It recommends selective
installation rather than adding every skill.

## Decision

Do not install the bundle or any global Baoyu skill now. There is no repeated,
verified local gap that justifies the context cost, runtime dependency, or
additional authority surface. Existing owners already cover image workflows,
text-style boundaries, Office/PPT work, linked knowledge, and verification.

The only plausible future trial is `baoyu-diagram`, and only as a **project-local
trial** under the existing image/visual workflow. It can produce standalone SVG
diagrams and a PNG derivative, but needs Bun or `npx -y bun` plus `sharp`; the
review machine has `npx` but no Bun. Any trial therefore needs a separate user
authorization for the runtime download, an isolated output directory, an SVG
and rendering QA check, and removal after the trial if it adds no measurable
value over Mermaid or the current image workflow.

For content creation, adopt the safe workflow shape rather than install an
upstream skill: analyze source material, select a reader and channel-specific
content form, retain a brief/prompt/output trail, and review before delivery.
This now lives as an internal `codex-task-execution/content-production`
candidate. It deliberately routes visuals, editable Office outputs, source
verification, and publication to existing owners instead of importing Bun,
multi-provider clients, Chrome CDP, cookie persistence, or posting controls.

## Rejected For Global Installation

- `baoyu-danger-gemini-web` and `baoyu-danger-x-to-markdown`: reverse-engineered
  service/API behavior is outside the approved provider and credential boundary.
- `baoyu-url-to-markdown`, `baoyu-post-to-*`, and `baoyu-wechat-summary`:
  Chrome CDP, login/session, cookie-sidecar, credential, publishing, or remote
  action surfaces conflict with the local privacy and explicit-authorization
  model. Source review found X-session cookie export and restore support.
- `baoyu-image-gen`, `baoyu-cover-image`, `baoyu-infographic`, `baoyu-comic`,
  and `baoyu-slide-deck`: useful prompt taxonomy, confirmation, provenance, and
  backup ideas, but their multi-provider credentials or raster-generation
  control planes overlap existing image and Office owners.
- `baoyu-format-markdown`: reject as-is. Its text promises a formatted output
  workflow, but the reviewed implementation writes directly to the input path;
  do not adopt it until a wrapper guarantees immutable input and rendered QA.
- `baoyu-compress-image`, `baoyu-translate`, and `baoyu-electron-extract`:
  retain as project-local references only. Each needs a concrete task and
  runtime check before a narrow installation is warranted.

## Reusable Candidate Ideas

- Preserve explicit confirmation, output-directory isolation, prompt-file
  provenance, and backup-before-regeneration in visual workflows.
- Require source-versus-implementation checks for external skills; README or
  `SKILL.md` promises are insufficient for mutation safety.
- Treat browser automation and cookie persistence as a separate high-authority
  boundary even when a skill labels the action as extraction rather than login.

## Invalidation

Revisit this decision only after a real project needs one named capability and
can show that the existing owner cannot deliver it. An installation proposal
must name the exact skill, version/commit, install path, dependency changes,
test artifact, rollback/removal plan, and authority boundary.

## Links

- [[Global Experience System]]
- [[Subskill Packaging Boundary]]
- [[Learning Governance]]
- [[Experience System Error Feedback]]
- [[Visual Format Selection]]
- [[Content Production Workflow]]

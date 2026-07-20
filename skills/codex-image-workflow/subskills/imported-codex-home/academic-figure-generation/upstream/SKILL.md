---
name: academic-figure-generation
description: >
  Generate and refine publication-quality academic figures, framework
  diagrams, pipeline illustrations, system architectures, and method overview
  figures from paper method text and a target caption. Use for ke yan hua tu,
  lunwen peitu, academic figure polishing, PaperBanana/PaperVizAgent, or
  ZCHAT-backed academic diagram generation.
---

# Academic Figure Generation

Use this skill to create or refine academic method figures. The preferred
local pipeline is PaperBanana/PaperVizAgent, with ZCHAT configured as an
OpenAI-compatible text provider and a matplotlib-code fallback for PNG output.

## Current Local Setup

- PaperBanana root: `%USERPROFILE%\Documents\Codex\2026-07-09\qin\work\PaperBanana`
- Run script: `%USERPROFILE%\Documents\Codex\2026-07-09\qin\work\run_paperbanana.ps1`
- Default output folder: `%USERPROFILE%\Documents\Codex\2026-07-09\qin\outputs`
- Runtime check script: `scripts/check_runtime.py`
- Model/API details: read `references/zchat-paperbanana.md` when configuring, debugging, or running ZCHAT.

Do not print or hardcode the full API key in user-facing text. The key is
stored outside the skill in the user's Codex auth/environment.

## Workflow

1. Gather method text and target caption.
   - Method text should include input/output, modules, data flow, feedback loops, and exact terms to preserve.
   - Caption should state the visual intent, e.g. `Figure 1: Overview of the proposed framework`.

2. Prefer the local PowerShell runner when available:

   ```powershell
   .\work\run_paperbanana.ps1 `
     -MethodFile "C:\path\to\method.md" `
     -Caption "Figure 1: Overview of the proposed framework" `
     -Output "%USERPROFILE%\Documents\Codex\2026-07-09\qin\outputs\figure.png" `
     -AspectRatio "16:9" `
     -Candidates 3 `
     -CriticRounds 0
   ```

3. If the local runner is unavailable, use `scripts/generate.py` with a valid
   PaperBanana checkout:

   ```powershell
   C:\path\to\PaperBanana\.venv\Scripts\python.exe scripts\generate.py `
     --paperbanana-root C:\path\to\PaperBanana `
     --method-file C:\path\to\method.md `
     --caption "Figure 1: Overview of the proposed framework" `
     --out-dir C:\path\to\outputs `
     --candidates 3 `
     --aspect-ratio 16:9
   ```

4. Present generated candidates and iterate on concise refinements:
   color scheme, layout density, label wording, panel ordering, font size,
   arrow semantics, and venue sizing.

## ZCHAT Notes

For ZCHAT setup, API paths, model names, Codex config, and PaperBanana
compatibility details, read:

```text
references/zchat-paperbanana.md
```

To verify the Codex Python runtime after an update, run:

```powershell
%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  %USERPROFILE%\.codex\skills\academic-figure-generation\scripts\check_runtime.py
```

Use `CriticRounds=0` first with ZCHAT because the documented ZCHAT endpoint is
chat-completions/embeddings, not a native image-generation endpoint. Increase
to `1` or `2` only after confirming the selected model can handle the needed
visual/refinement steps.

## Figure Style

- Use a colorblind-friendly palette.
- Use concise labels, not sentences.
- Use solid arrows for main data flow and dashed arrows for optional feedback.
- Keep whitespace generous; reviewers skim figures quickly.
- Match venue conventions: Times-like for ACL/EMNLP, Helvetica/Arial-like for many ML venues.

## Troubleshooting

- If ZCHAT returns `No available accounts`, switch the model to another ZCHAT-listed model such as `grok-3` or `gemini-3-pro`.
- If no PNG is produced, inspect PaperBanana raw results and generated code fields.
- If direct image generation is desired, configure a provider/model with a documented image-generation endpoint; ZCHAT documentation provided here only guarantees chat-completions and embeddings.

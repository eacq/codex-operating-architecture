---
name: codex-error-feedback
description: Extract user-reported errors and capture unexpected behavior from Codex modules, skills, scripts, workflows, or validation as structured reports; diagnose, safely attempt a targeted repair, verify it, and feed only verified lessons back into experience. Use when a user says something is wrong, fails, errors, cannot work, is missing, or needs debugging, an error list, a failure report, incident feedback, or reusable failure experience.
---

# Codex Error Feedback

Use this skill whenever the user describes a problem or an experience-system
module behaves unexpectedly. User wording is evidence, not proof of cause.

## Workflow

1. Extract every error claim from the user's message. Preserve it in
   `-UserReport`; do not replace the user's symptom with an inferred cause.
2. Identify the likely owning module, then gather minimal evidence: expected and
   actual result, command/output, changed files, code path, and verification.
   Redact secrets and private raw-session content.
3. Create the initial report before repair:

   ```powershell
   $report = .\skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1 -ProjectRoot <project-root> -Module <owner> -UserReport '<user wording>' -ExpectedResult '<expected>' -ActualResult '<actual>'
   ```

   It writes Markdown and JSON under `.codex/errors/`, including extracted
   error statements. Artifacts must be UTF-8 without BOM so strict JSON and
   Markdown consumers can read them consistently. Use the report directory
   printed by the command.
4. Diagnose and attempt the smallest safe repair through the owning module.
   Do not install software, alter credentials, delete data, or make external
   changes without the normal authorization boundary. If a repair is unsafe or
   unverified, record the blocker and stop rather than claiming success.
5. Close the same report after the attempt:

   ```powershell
   .\skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1 -ReportDirectory <report-directory> -Status verified -RepairAttempt '<change made>' -RepairResult '<observed result>' -Verification '<command or inspection>'
   ```

6. Route repeated or verified failures to `codex-experience-capture`; route
   durable concepts to `codex-knowledge-system`. One-off or uncertain diagnoses
   remain candidates. Do not add an Anki card merely because an error occurred.

7. After every verified report, run `Invoke-WorkflowErrorReview.ps1`. It classifies whether to add a preventive gate, reorder/normalize input, remove/simplify a redundant step, or monitor. Change workflow steps only when its evidence threshold is met, then rerun the original failure check and full validation.

## Report fields

Required:

- `module`: owning skill or lifecycle module.
- `component`: script, reference, prompt template, workflow, command, or file.
- `code_location`: file path and optional line number or artifact path.
- `code_excerpt`: minimal relevant code or output, redacted.
- `symptom`: exact unexpected behavior.
- `features`: concrete observable traits that distinguish the failure.
- `suspected_causes`: plausible causes, labeled as hypotheses unless verified.
- `possible_outcomes`: likely consequences if not fixed.
- `solutions`: candidate fixes and tradeoffs.
- `verification`: how to confirm the fix.

Optional:

- severity, confidence, trigger, environment, related files, regression risk,
  owner module, invalidation conditions, and promotion status.

Read [references/report-schema.md](references/report-schema.md) before changing
the schema or promotion rules.

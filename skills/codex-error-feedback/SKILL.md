---
name: codex-error-feedback
description: Extract user-reported errors and capture unexpected behavior from Codex modules, skills, scripts, workflows, or validation as structured reports; diagnose, safely attempt a targeted repair, verify it, and feed only verified lessons back into experience. Use when a user says something is wrong, fails, errors, cannot work, is missing, or needs debugging, an error list, a failure report, incident feedback, or reusable failure experience.
---

# Codex Error Feedback

Use this skill whenever the user describes a problem or an experience-system
module behaves unexpectedly. User wording is evidence, not proof of cause.

For cross-project failures caused in part by a global experience-system
capability, read [subskills/global-inbox/SKILL.md](subskills/global-inbox/SKILL.md).
For file-organization and global-iteration debugging, read
[subskills/continuous-diagnosis-feedback/SKILL.md](subskills/continuous-diagnosis-feedback/SKILL.md).
Read [references/report-schema.md](references/report-schema.md) for fields,
command parameters, promotion rules, and the schema contract.

## Workflow

1. Extract every error claim from the user's message. Preserve it in
   `-UserReport`; do not replace the user's symptom with an inferred cause.
   If a multilingual report crosses a shell boundary that may recode arguments,
   write it to a local UTF-8 file and pass `-UserReportFile` instead; the file is
   evidence input and must not be committed.
2. Identify the likely owning module, then gather minimal evidence: expected and
   actual result, command/output, changed files, code path, and verification.
   Redact secrets and private raw-session content.
   Before proposing a repair, reproduce when practical, compare the latest
   relevant change with a working reference, and state one testable root-cause
   hypothesis. In a multi-component workflow, collect evidence at boundaries
   before changing multiple layers. If evidence instead shows an external or
   timing condition, record that limitation and use bounded handling rather
   than inventing a local root cause.
   If the failure crosses a project boundary, record source workflow, involved
   global function(s), and causality strength.
3. Create the initial report before repair:

   ```powershell
   $report = .\skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1 -ProjectRoot <project-root> -Module <owner> -UserReport '<user wording>' -ExpectedResult '<expected>' -ActualResult '<actual>'
   ```

   It writes Markdown and JSON under `.codex/errors/`, including extracted
   error statements. Artifacts must be UTF-8 without BOM so strict JSON and
   Markdown consumers can read them consistently. Use the report directory
   printed by the command.
4. Diagnose and attempt the smallest safe repair through the owning module.
   Change one causal surface at a time; do not bundle opportunistic cleanup
   into a diagnostic repair. If two safe hypotheses fail, return to evidence
   gathering; after a third independent failed repair, stop and require an
   architecture review instead of guessing a fourth change.
   Do not install software, alter credentials, delete data, or make external
   changes without the normal authorization boundary. If a repair is unsafe or
   unverified, record the blocker and stop rather than claiming success.
   For a failed global iteration, first verify that the active tree was unchanged
   or restored from the exact pre-iteration snapshot. If rollback is verified,
   repair the owning error and rerun the complete iteration from the beginning;
   if rollback failed, report a critical blocker and do not continue mutation.
5. Close the same report after the attempt:

   ```powershell
   .\skills\codex-error-feedback\scripts\New-ErrorFeedbackReport.ps1 -ReportDirectory <report-directory> -Status verified -RepairAttempt '<change made>' -RepairResult '<observed result>' -Verification '<command or inspection>'
   ```

6. Route repeated or verified failures to `codex-experience-capture`; route
   durable concepts to `codex-knowledge-system`. One-off or uncertain diagnoses
   remain candidates. Do not add an Anki card merely because an error occurred.

   When the same module, component, and symptom recur, run
   `scripts/Reopen-RepeatedErrorFeedback.ps1` before any new repair. It reopens
   the original report, increments repeat evidence, and records the prior repair
   or mitigation as failed rather than leaving it marked resolved.

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
  owner module, source workflow, global function list, causality strength,
  invalidation conditions, and promotion status.

Read [references/report-schema.md](references/report-schema.md) before changing
the schema or promotion rules.

Imported local compatibility modes live under `subskills/imported-codex-home/`; use them only within this owner's reproduce-diagnose-fix-verify loop.

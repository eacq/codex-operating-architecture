# Error Feedback Report Schema

Error reports are project evidence. They should be precise enough for a future
agent to reproduce the failure path without reading the raw session.

## Error item

- `user_report`: redacted original problem statement supplied by the user.
- `reported_issues`: error-bearing statements extracted from that wording. They
  are user evidence, not confirmed diagnoses.
- `expected_result` and `actual_result`: observable success and failure states.
- `origin_project`: redacted source project label plus a path hash when the
  report was created outside the global architecture repository.
- `origin_workflow`: project workflow or process that invoked the global
  experience-system capability.
- `global_experience_functions`: global skills, scripts, workflows, or lifecycle
  gates involved in the failure path.
- `experience_system_causality`: one of `none`, `suspected`, `partial`,
  `primary`, or `verified`. Use this only for the part of the cause attributed
  to the global experience system; project-local facts remain in the source
  project.

- `id`: stable local identifier inside the report.
- `module`: owning module or skill.
- `component`: script, reference, workflow, prompt, command, generated artifact,
  or lifecycle file.
- `code_location`: path plus optional line number, command, or artifact path.
- `code_excerpt`: minimal relevant snippet or output; redact secrets.
- `symptom`: what happened that should not have happened.
- `features`: observable traits such as error text, malformed output, wrong
  file, stale state, missing field, unexpected side effect, or validation gap.
- `suspected_causes`: hypotheses; mark verified causes explicitly.
- `possible_outcomes`: impact if ignored.
- `solutions`: concrete options with tradeoffs.
- `verification`: command or inspection that proves the fix.
- `confidence`: low, medium, or high.
- `severity`: info, low, medium, high, or critical.
- `status`: observed, triaged, fixed, verified, or candidate.
- `repair_attempt` and `repair_result`: appended only after a targeted repair
  attempt; an unverified attempt must not be marked `verified`.

## Promotion rules

- Write every report under `.codex/errors/` first, before repair.
- Preserve the user's redacted problem statement and extracted statements even
  when triage later finds a different root cause.
- Append repair evidence to the same report with `-ReportDirectory`; do not
  create a disconnected second report for the same incident.
- Add an `EXPERIENCE.md` candidate only when the failure is reusable.
- Promote to verified experience after a fix is validated or the same failure
  repeats in more than one run.
- Promote to a knowledge note when the failure teaches a concept or guardrail
  that applies beyond one module.
- Change a shared skill only after the report identifies the owning skill and
  the validation path.
- When a project outside `$ARCHITECTURE_ROOT` finds that the global experience
  system is a suspected, partial, primary, or verified cause, mirror a redacted
  summary into `$ARCHITECTURE_ROOT/.codex/project/incoming-error-feedback.jsonl`.
  The source project keeps the full local report; the global inbox stores only
  routing evidence for the next global iteration.

## Redaction

Never store credentials, raw private sessions, browser cookies, access tokens,
API keys, account identifiers, or full prompt/response payloads. Keep minimal
snippets and replace sensitive-looking values with `[REDACTED]`.

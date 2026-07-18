---
name: codex-experience-capture
description: Extract, deduplicate, validate, and store reusable lessons from Codex sessions, project logs, Git milestones, tool failures, corrections, and completed iterations. Use after Git initialization, commit, merge, rebase, tag, or release; after a complete verified project iteration; after a task yields a non-obvious repeatable success or failure; when pending project lifecycle events exist; or when updating project experience, the global ledger, and related skills.
---

# Codex Experience Capture

Start with project evidence, memory indexes, and `knowledge/history-catalog.json`; inspect raw sessions only when necessary.

For a whole local experience pass, read
[subskills/local-experience-iteration/SKILL.md](subskills/local-experience-iteration/SKILL.md).
It owns source order, evidence thresholds, catalog refresh, and classification.

When the user names the "global experience system" or asks to refine,
merge, split, or encapsulate experience, skill, knowledge, and workflow
learning together, read
[subskills/global-experience-system/SKILL.md](subskills/global-experience-system/SKILL.md).
It owns the system boundary and handoff order without replacing the
specialist owners.

After a completed global iteration, run
`scripts/New-GlobalIterationCandidateReport.ps1 -Apply` and present its
advisory summary to the user. The Markdown report is Chinese-primary for user
decision-making, followed by a stable English appendix and JSON model view for
the experience system. Candidate wording stays source-preserved to avoid
meaning-changing automatic translation. The report supports explicit decisions
about candidates; it never promotes candidates or authorizes external actions.
For user delivery inside a Codex chat, render the current candidate report
directly in the final response: Chinese-primary summary first, followed by the
stable English model-readable appendix. A Codex chat local-file link opens the
file in the right sidebar; it does **not** execute a `.cmd` launcher. Therefore
never promise that a chat click will start the report command, and do not make
such a link the primary user path. The generated report remains the durable
artifact. `scripts/Open-LatestGlobalIterationCandidateReport.cmd` is an
optional manual launcher for File Explorer or a terminal, while
`codex-report://latest` is only an optional Windows compatibility route.
`scripts/Install-CandidateReportUrlProtocol.ps1` installs the current-user
`codex-report://latest` handler for direct clickable launching of that CMD; it
is local-only and can be removed with `-Uninstall`.
When Markdown Preview Enhanced is available in the local VS Code profile,
enable its automatic side-preview, multiple-preview, live-update, and
scroll-sync settings so every opened Markdown file shows its rendered report
beside the source. This is a local editor preference, not a project artifact or
extension-installation request.

When the user explicitly authorizes all currently pending candidate records,
run `scripts/Process-AuthorizedCandidateRecords.ps1 -Apply`. It consumes only
an active local authorization record, archives every original before changing
it, promotes durable guidance as `promoted-guarded`, clears only derived
pending records, and consumes that authorization. It does not install, update,
configure external tools, publish, access credentials, or treat a guarded item
as independently verified; those actions always retain their own authority
gate.

For workflow-derived learning, read
[subskills/workflow-learning/SKILL.md](subskills/workflow-learning/SKILL.md).
It owns `workflow-learning.json` consumption and the handoff to architecture
iteration.

Capture trigger, observation, action, verification, scope, invalidation, source, and status. Remove secrets and personal detail; merge duplicates. Update project `EXPERIENCE.md` and `RETROSPECTIVES.md` first.

If the evidence is an unexpected module result, malformed artifact, wrong route,
failed validation, or unclear root cause, invoke `codex-error-feedback` first.
Promote the resulting report only after the cause or reusable lesson is
validated.

## Git-aware capture

When a Git event triggered the capture, record evidence from the repository
that owns the changed paths: its exact repository root, branch, commit (when
created), and the scoped files verified. Never infer the repository from the
current shell directory or copy the event into another repository's lifecycle
record. If the root is uncertain or mismatched, hand routing back to
`codex-git-operations` before recording a milestone.

After a successful commit, read the target repository's local
`codex.route.*` and `codex.last.*` checkpoint when present, then capture the
new commit as the next version of that same route. Keep checkpoint metadata
local to Git; store only reviewable evidence and lessons in project files.

Promote only non-trivial, specific, verified, cross-project, non-duplicate lessons to the global ledger or owning skill. A user may explicitly promote a candidate experience as **guarded guidance**: preserve its original wording, source, scope, invalidation, and unverified status; let it guide routing and scoped trials, but never present it as independently verified or use it to bypass safety, authorization, installation, credential, publication, or rollback gates. Keep other weaker candidates in the project. Use `codex-knowledge-system` for durable linked concepts or user recall material, then run full validation.

When a verified private lesson may be shared publicly, require two independent evidence sources and route its sanitized public candidate through `codex-knowledge-system/scripts/Convert-PrivateKnowledgeToPublic.ps1`. Do not publish raw history, credentials, personal paths, provider endpoints, or project-private claims; retain recipient-specific configuration only in the local portability profile.

When an experience contains multiple interacting causes, actions, and outcomes, route a sanitized summary to `codex-image-workflow` for a GPT-first visual decision. Treat visuals as derived artifacts: edit when semantics remain stable, regenerate after topology changes, and remove when they no longer improve understanding.

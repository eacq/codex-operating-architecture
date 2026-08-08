---
name: codex-experience-capture
description: Capture, deduplicate, validate, and promote reusable lessons from sessions, Git milestones, failures, and Agent memory handoffs.
---

# Codex Experience Capture

Canonical information unit for skill evolution and book-shelf learning:
`knowledge-vault/30-Knowledge/Agent Skill Evolution Optimization.md`.

Start with project evidence, Agent Memory operations/snapshots, and `knowledge/history-catalog.json`; inspect raw sessions only when necessary.

For a whole local experience pass, read
[subskills/local-experience-iteration/SKILL.md](subskills/local-experience-iteration/SKILL.md).
It owns source order, evidence thresholds, catalog refresh, and classification.

When the user names the "global experience system" or asks to refine,
merge, split, or encapsulate experience, skill, knowledge, and workflow
learning together, read
[subskills/global-experience-system/SKILL.md](subskills/global-experience-system/SKILL.md).
It owns the system boundary and handoff order without replacing the
specialist owners. Enter that work through the root Agent registry: experience
capture is a specialist Agent capability and participates in the
`experience-memory-agent` concept profile. It consumes verified root/child
results and returns candidates, promoted experience, reports, or error routing
to the root save point; it is not a parallel global-system controller.

After a completed global iteration, run
`scripts/New-GlobalIterationCandidateReport.ps1 -Apply` and present its
advisory summary to the user. The Markdown report is Chinese-primary for user
decision-making, followed by a stable English appendix and JSON model view for
the Global Experience Agent. Candidate wording stays source-preserved to avoid
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

For a convenient Codex-facing access adapter to start, continue, resume, search,
store, route, or report through the Global Experience Agent, read
[subskills/experience-agent-access/SKILL.md](subskills/experience-agent-access/SKILL.md).
It forwards to the root controller and preserves interface, owner, and tool
gates; it is not a second experience-Agent entrypoint.

When learning from an external methodology, upstream skill repository, long-form
content pipeline, or repeated project practice and turning it into a reusable
experience-system skill, read
[subskills/methodology-skill-distillation/SKILL.md](subskills/methodology-skill-distillation/SKILL.md).
It adapts source methods into owner-scoped skills, references, knowledge notes,
or candidates through source grounding, triple verification, RIA++ shaping,
linking, and trigger pressure tests.

For the distilled specialist-design contract from
`msitarzewski/agency-agents` (trigger-precise agent anatomy, evidence
discipline, minimal-change scope self-check, roster/orchestration boundary),
see `references/agency-agents-specialist-design.md`.

When a task needs multi-Agent collaboration, explicit role handoffs, durable
work-item/timeline replay, Evidence-Finding-Path lineage, or external skill/MCP
supply-chain review, read
[subskills/reverse-skill-collaboration/SKILL.md](subskills/reverse-skill-collaboration/SKILL.md).
This is a guarded adaptation of reverse-skill's collaboration control plane;
it does not enable its target-facing security skills, bootstrap dependencies,
network actions, or global instruction injection.

When the user asks to evolve, optimize, train, judge, score, ratchet, or
consolidate an experience-system skill after source grounding, read
[subskills/skill-evolution-optimization/SKILL.md](subskills/skill-evolution-optimization/SKILL.md).
It applies Darwin-style review loops and SkillOpt-style strict-improvement
gates: one primary `SKILL.md` candidate per epoch, evidence-backed scoring,
safety checks, human/owner checkpoints, validation, and keep/revert semantics.

Permission inheritance is enabled for the same optimization task. When the
user explicitly grants optimization, deep optimization, full authority, or
equivalent execution authority over the global experience system, that grant
also authorizes one current-candidate processing pass. The inherited pass
defaults to processing_mode: structural-optimization because the goal is
improvement rather than mere cleanup. Create the local authorization record,
preserve source wording and evidence, record the structural handoff, and
regenerate the candidate report. This is one-shot for the current project and
task; it is not periodic or unprompted processing. If the authorization is
only to retain or process candidates as guidance, use guarded mode.

When the user explicitly authorizes all currently pending candidate records,
run `skills/codex-experience-capture/scripts/Process-AuthorizedCandidateRecords.ps1 -Apply`. It consumes only
an active local authorization record and archives every original before
changing it. The default `guarded` mode promotes durable guidance as
`promoted-guarded` and clears derived pending records. If the authorization
explicitly names structural optimization, use
`processing_mode: structural-optimization`: workflow-learning candidates must
be recorded under `.codex/project/structural-optimization-records/` as accepted
architecture-iteration input, then routed through the existing experience,
knowledge, and architecture owners instead of being treated as cleanup only.
When the user explicitly asks for formal promotion, use
`processing_mode: formal-promotion` only with one exact `verification_records`
entry per current candidate. Each entry must match the report source and source-
preserved summary, declare `status: verified`, name the proving check, and cite
existing project-relative evidence files. The processor rejects missing or
drifted evidence, archives every source, writes a formal-promotion proof, and
marks durable experience or linked knowledge as verified promotion. Formal
promotion still does not authorize an external, credential, installation,
publication, destructive, Git, or release action. Permission inheritance also
never creates periodic processing or bypasses the independent gates for
formal promotion, credentials, installation, publication, destructive work,
Git, release, or material Agent-structure changes.
Do not call a candidate "handled" merely because it was archived.

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

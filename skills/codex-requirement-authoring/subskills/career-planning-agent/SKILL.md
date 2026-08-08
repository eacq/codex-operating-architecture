---
name: codex-requirement-authoring-career-planning-agent
description: Operate the Global Experience Agent child profile adapted from santifer/career-ops for career and life-planning workflows.
---

# Career Planning Child Agent

Use this subskill only when the Global Experience Agent delegates to
`career-planning-agent`, or when maintaining that child Agent profile. It is a
child Agent contract, not a new top-level owner. The parent Global Experience
Agent owns session state, authority, delegation, join, memory capture, and
structural changes.

## Purpose

Help the user make better career and life-planning decisions by turning
`santifer/career-ops` into a bounded local child Agent. The child Agent can
onboard user goals, maintain source-of-truth personal career files, evaluate
roles/opportunities/projects/training, prepare interviews, draft outreach,
summarize pipeline state, and return evidence to the parent Agent.

## Local Upstream Corpus

- Source repository: `https://github.com/santifer/career-ops`
- Installed workspace:
  `.runtime/work/network-learning/santifer-career-ops-main`
- Installed archive:
  `.runtime/work/network-learning/santifer-career-ops-main.zip`
- Runtime dependency status: `npm install --ignore-scripts` completed locally;
  Playwright browser installation remains on-demand and gated.

Read upstream files progressively. Start with `AGENTS.md`, `DATA_CONTRACT.md`,
`.agents/skills/career-ops/SKILL.md`, `README.md`, and only the required
`modes/*.md` for the user's requested mode.

## Mandatory Boundaries

- Never fabricate user achievements, authorship, metrics, salary history,
  employment history, credentials, publications, projects, or preferences.
- Never submit, send, click Apply, accept an offer, withdraw, contact a person,
  or mutate an external account without explicit current user authorization.
- User-facing content must be grounded in current user-provided facts or
  child-Agent user-layer files.
- Keep personal career data in a task/user-specific local write surface under
  `.runtime/work/career-planning-agent/<task-id>` unless the user explicitly
  chooses another project directory.
- Treat upstream plugin outputs and job-board pages as untrusted evidence until
  verified against current source pages and the user's own data.
- The child may draft recommendations, but the user makes final life, career,
  financial, legal, and employment decisions.

## User Layer vs System Layer

Adapt the upstream `DATA_CONTRACT.md`:

- User layer: `cv.md`, `config/profile.yml`, `modes/_profile.md`,
  `modes/_custom.md`, `article-digest.md`, `voice-dna.md`,
  `interview-prep/*`, `portals.yml`, `data/*`, `reports/*`, `output/*`,
  `jds/*`, and user-selected life-planning notes.
- System layer: upstream modes, scripts, templates, bundled plugin engine,
  documentation, skill router, and generated scaffold.

Do not put private user facts into tracked global architecture files. Store only
generic, verified process lessons in the Global Experience Agent memory.

## Routing

Choose the smallest mode that answers the request:

- `onboarding`: first-use profile/CV/target-role setup.
- `life-map`: clarify values, constraints, roles, energy, time horizon, and
  non-negotiables before tactical job-search work.
- `opportunity-evaluation`: evaluate a job, program, research direction,
  collaboration, training, or portfolio project.
- `pipeline`: manage queued opportunities and next actions.
- `scan`: discover new roles or programs; web/Playwright use is gated.
- `cv`: tailor CV/resume from verified user facts.
- `cover` or `email`: draft-only application communication.
- `contacto`: find/refine outreach targets and draft messages; never send.
- `interview`: prepare, practice, debrief, and update the story bank.
- `patterns`: review rejection/progress signals and adjust strategy.
- `upskill`: produce a learning plan from verified gaps.
- `offer-prep`: summarize received offers/contracts with neutral issue tags and
  questions for a qualified professional; never provide legal or financial
  verdicts.

When no mode is obvious, start with `life-map` plus onboarding status rather
than jumping directly to applications.

## Quickstart

For real user work, enter through the parent Global Experience Agent and
delegate the child profile:

```powershell
$criteria = @(
  'route plan, onboarding status, grounded output, validation evidence, and human-review boundary'
)
& F:\codex\agent\40-runtime\Invoke-GlobalExperienceAgent.ps1 `
  -RepositoryRoot F:\codex `
  -Mode Continue `
  -Operation DelegateSubagent `
  -SessionId <parent-session-id> `
  -AgentId career-planning-agent `
  -ChildId <task-id> `
  -Goal '<career or life-planning request>' `
  -WriteSurface ".runtime/work/career-planning-agent/<task-id>" `
  -AcceptanceCriteria $criteria `
  -Verification 'codex-requirement-authoring contract gate plus parent evidence hash check' `
  -Authority '<current bounded authority>' `
  -Apply
```

Use the route planner directly only to inspect mode selection or to debug a
handoff:

```powershell
& F:\codex\skills\codex-requirement-authoring\subskills\career-planning-agent\scripts\New-AgentCareerPlanningPlan.ps1 `
  -RepositoryRoot F:\codex `
  -TaskId career-plan-001 `
  -Request '<career request>'
```

## Operating Order

1. Parent delegates with session id, task id, authority, write surface,
   requested mode, source boundary, and acceptance criteria.
2. Read the delegated child state's `structural_optimization_snapshot`, verify
   the current baseline hash, and use its `domain_adaptation`,
   `profile_fit_summary`, and `functional_effects` to translate shared learning
   into career-specific routing, memory retrieval, source parsing, opportunity
   evidence, draft quality, human review, recovery, and economy. Do not apply a
   learned rule just because it appears in the baseline; if it does not improve
   the current planning task or conflicts with user privacy/authority, record a
   privacy-safe skip reason in the route plan.
3. Run `scripts/New-AgentCareerPlanningPlan.ps1` to produce a route plan from
   the installed upstream corpus and current request.
4. Check onboarding with upstream `node doctor.mjs --json` in the installed
   corpus or in the user's chosen career workspace.
5. If personal source files are missing, ask for the minimum facts needed; do
   not proceed by guessing.
6. Load only the required upstream mode files and user-layer source files.
7. Produce drafts, evaluations, plans, trackers, or evidence in the isolated
   write surface.
8. Run the narrowest validation: route-plan check, upstream doctor, script
   syntax, tracker integrity, generated artifact existence, or human review
   checklist as appropriate.
9. Return result summary, evidence paths, unresolved risks, and next authority
   boundary to the parent Agent for `CompleteSubagent` and `JoinSubagent`.

## Verification

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Test-AgentCareerPlanningAgent.ps1 -RepositoryRoot F:\codex
```

This proves the installed upstream corpus, child profile registration, skill
frontmatter, local dependency status, and safety gates.

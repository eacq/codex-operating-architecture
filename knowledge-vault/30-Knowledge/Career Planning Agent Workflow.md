# Career Planning Agent Workflow

## Role

`career-planning-agent` is a bounded child Agent under the Global Experience
Agent. It adapts `santifer/career-ops` from a job-search command center into a
broader life and career planning assistant.

## Installed Source

- Upstream repository: `https://github.com/santifer/career-ops`
- Local corpus: `.runtime/work/network-learning/santifer-career-ops-main`
- Local archive:
  `.runtime/work/network-learning/santifer-career-ops-main.zip`
- Archive SHA-256:
  `8E3307C7AC02C55072C15687CEEAD5A6CDF3E6317067B298149AEB71B199541D`
- Observed package: `career-ops` `1.22.0`
- Local dependency install: `npm install --ignore-scripts`

## Extracted Principles

1. Career decisions need a pipeline, not one-off advice.
2. Personal facts are source-of-truth data and must not be fabricated.
3. AI can evaluate, draft, compare, and prepare; the user decides and acts.
4. Quality beats mass action: low-fit opportunities should usually be skipped.
5. Reflection loops improve strategy: outcomes update profile, story bank,
   preferences, and targeting.

## Agent Adaptation

The child Agent preserves the upstream user/system data split. Personal career
facts, CV material, target roles, preferences, interview stories, and generated
reports remain in an isolated local write surface or a user-approved career
workspace. Tracked global architecture files store only generic process rules,
contracts, and validation.

The Global Experience Agent delegates bounded work to this child, then joins it
through evidence. The child can plan, evaluate, draft, scan, prepare, and
summarize, but it cannot submit applications, send messages, mutate external
accounts, use credentials, publish, release, or change Agent structure.

## Modes

- `life-map`: values, constraints, non-negotiables, energy, time horizon.
- `onboarding`: CV/profile/target-role setup.
- `opportunity-evaluation`: jobs, training, projects, collaborations.
- `pipeline`: queued opportunities and next actions.
- `scan`: discovery through configured sources.
- `cv`, `cover`, `email`: user-facing drafts from verified facts.
- `contacto`: contact discovery and draft-only outreach.
- `interview`: prep, practice, debrief, story-bank updates.
- `patterns`: rejection/progress pattern review.
- `upskill`: learning plan from verified gaps.
- `offer-prep`: neutral clause/offer review and professional question list.

## Usage

Use the parent Global Experience Agent for real career work:
`DelegateSubagent -AgentId career-planning-agent` with an isolated write surface
under `.runtime/work/career-planning-agent/<task-id>`. The parent owns durable
session state, authority, memory capture, join, and gated external actions.

Use `New-AgentCareerPlanningPlan.ps1` only for local route inspection. It
returns the selected mode, secondary modes for multi-intent requests, source
files to load from the upstream corpus, structural evidence requirements,
safety boundaries, and next-step hints.

## Verification

Run `scripts/Test-AgentCareerPlanningAgent.ps1`. The test verifies the upstream
installation, package scripts, local dependency presence, child profile
registration, frontmatter, denied operations, resource links, English and
Chinese route planning, secondary route preservation, and usage hints.

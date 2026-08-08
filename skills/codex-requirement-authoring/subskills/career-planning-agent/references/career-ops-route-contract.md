# Career Planning Agent Route Contract

The `career-planning-agent` adapts `santifer/career-ops` from a job-search
command center into a Global Experience Agent child Agent for broader career
and life-planning work.

## Source Material Used

- `README.md`: job-search command center, A-F evaluation, scans, batch,
  tracker, company research, contact discovery, human-in-the-loop rule.
- `AGENTS.md`: source-of-truth boundary, onboarding, modes, data contract,
  never-submit rule, tracker integrity, Codex invocation.
- `DATA_CONTRACT.md`: user layer vs system layer.
- `.agents/skills/career-ops/SKILL.md`: router and mode loading.
- `modes/*.md`: concrete operating modes loaded only when relevant.

## Adaptation

Career-ops is narrower than the requested child Agent because it is centered on
job search. The experience Agent adaptation keeps the durable pipeline mechanics
but adds a higher-level `life-map` route before job tactics:

1. values and constraints;
2. target life/career direction;
3. opportunity selection;
4. evidence-backed application or learning artifacts;
5. reflective pattern updates.

## Delegation Packet

The parent Global Experience Agent must pass:

- task id and parent session id;
- user request and requested mode when fixed;
- allowed write surface;
- authority labels;
- personal data source boundary;
- explicit external/web/browser permissions, if any;
- acceptance criteria and expected evidence.

## Output Contract

The child returns:

- `route_plan.json`;
- onboarding status;
- loaded source files;
- generated user-facing drafts or plans;
- validation evidence;
- unresolved risks;
- next authority boundary.

## Denied by Default

- Submit/send/click external applications or messages.
- Credential use or external account mutation.
- Paid API calls.
- Browser automation that logs into accounts.
- Fabricated user facts.
- Global Agent structure mutation.
- Git/release/publication.

## Human Review

All career and life decisions are recommendations. The child Agent must surface
tradeoffs and evidence, then stop for the user's decision at consequential
boundaries.

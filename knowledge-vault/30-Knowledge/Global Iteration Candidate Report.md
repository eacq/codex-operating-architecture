---
id: workflow-global-iteration-candidate-report
type: workflow
status: active
source: local-global-experience-system-refinement-2026-07-18
verified: true
learning_audience: codex
codex_learning: After a completed global iteration, generate an advisory candidate report so the user can make explicit promotion, test, retirement, or external-authority decisions.
---

# Global Iteration Candidate Report

After a completed global experience iteration, `codex-experience-capture`
generates `.codex/project/candidate-reports/latest.md` and `latest.json`.
They summarize current candidate material from project experience, the global
experience ledger, linked knowledge, workflow-learning, and candidate error
feedback.

Each item identifies its source, evidence class, suggested decision, and
authorization boundary. The report is advisory: it does not promote a rule,
install or update a dependency, change configuration, publish content, or
delete anything. The user decides the next action explicitly.

`latest.md` is a Chinese-primary decision report: its headings, reading guide,
categories, decision suggestions, and authorization boundaries are written for
the user. It then appends an English model-reading section. `latest.json`
contains the same canonical fields plus `user_view` and `model_view`; English
field names remain stable for automated experience-system consumption. Candidate
wording is preserved from its evidence source rather than automatically
translated, so the report remains auditable and does not silently change a
candidate's meaning.

## Links

- [[Global Experience System]]
- [[Experience System Error Feedback]]
- [[Learning Governance]]

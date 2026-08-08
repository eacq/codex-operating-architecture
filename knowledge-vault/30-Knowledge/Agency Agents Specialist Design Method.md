---
id: agency-agents-specialist-design-method
type: concept
status: active
source: https://github.com/msitarzewski/agency-agents at commit ebe9c99acb5c96f9468de368d8bead775387d1a7 (MIT)
verified: true
learning_audience: codex
codex_learning: Design specialists as deliverable-focused contracts (trigger-precise description, critical rules, deliverables with evidence, workflow, success metrics), organize them into an indexed roster, and route multi-specialist work through explicit owner handoffs; adapt upstream method only, never bulk-install upstream agents.
---

# Agency Agents Specialist Design Method

## Source grounding

- Source: `https://github.com/msitarzewski/agency-agents`
- Inspected commit: `ebe9c99acb5c96f9468de368d8bead775387d1a7`
- License: MIT (Copyright (c) 2025 AgentLand Contributors)
- Local clone: `.runtime/work/network-learning/msitarzewski-agency-agents`
- Local adaptation: `skills/codex-experience-capture/references/agency-agents-specialist-design.md`

## Local interpretation

The upstream "Agency" is a roster of 230+ specialist agent files. Its reusable
core for the Global Experience Agent is the specialist contract shape, not the
personality text or the per-tool installers. A specialist should carry a
trigger-precise description, mission, critical rules, deliverables with
concrete examples, a workflow, and measurable success metrics. That shape maps
onto the local `config/minimal-agent-template.json` child-profile dimensions.
Multi-specialist orchestration remains a candidate until a local verified
multi-specialist task exists.

## Reusable pattern

1. Ground the source (URL, commit, license, inspected files).
2. Extract the contract shape: description -> rules -> deliverables ->
   workflow -> metrics.
3. Map each shape element to an existing local contract dimension instead of
   copying upstream files.
4. Apply the evidence discipline (quote spec, compare rendered evidence, honest
   rating) and the minimal-change discipline (scope self-check).
5. Keep raw upstream installers and bulk `~/.codex/agents` TOML installs
   rejected; adapted owner-internal units are the only permitted install form.

## Invalidation

This note becomes stale if a local specialist contract template replaces the
minimal-agent-template mapping, or if a verified local multi-specialist task
upgrades the orchestration unit from candidate to verified.


---
name: collaborative-operating-model
description: Route a material task across the user, local experience system, and model-owned work as a small, evidence-backed logical team. Use under codex-self-evolution when quality, authority, resources, handoffs, or safety need an explicit shared contract.
---

# Collaborative Operating Model

## Purpose

Treat collaboration as a contract among user authority, local experience, and
model execution. A "team" is normally a set of logical owner roles and durable
handoffs, not a default request to start parallel agents, paid services, or
external runtimes.

## Trigger and Inputs

Use for a material or compound task with two or more of: a decision from the
user, reusable local evidence, specialized execution, a resource trade-off, or
a consequential safety boundary. Start from the project requirements, state,
workflow, and relevant verified experience. Record a short task contract:

- objective and observable acceptance/quality floor;
- scope, sensitivity, and authority already granted;
- smallest required owner roles and their write surfaces;
- resource budget for user attention, model/context/tool work, time, and paid
  or external actions; and
- verification, fallback, stop condition, and experience-capture destination.

For self-evolution or structure work, add the terminal-goal mapping from
[../outcome-directed-iteration/SKILL.md](../outcome-directed-iteration/SKILL.md):
which collaboration failure is reduced, which of the five outcome checks is
improved, the baseline or evidence used, and the no-regression checks.

## Roles and Authority

| Role | Responsibility | Cannot decide alone |
| --- | --- | --- |
| User | Goal, priority, acceptance trade-offs, and new authority | External installation/update/reconfiguration, paid/public/destructive or credential actions without explicit approval |
| `codex-self-evolution` controller | Select the smallest owner set, route handoffs, and preserve the contract | Expand authority or manufacture a need for parallel work |
| Operational owner | Perform a narrow implementation or analysis and emit named artifacts | Change another owner's surface without a handoff |
| Evidence and learning owners | Find local evidence, classify lessons, and retain provenance | Promote unverified observations into global behavior |
| Verification and feedback owners | Test acceptance criteria and report unexpected behavior | Waive the quality or security floor to save resources |

## Three Capability Lanes

1. **Operate:** requirements and local evidence route through the relevant
   execution owner, then behavior verification.
2. **Learn:** evidence routes through `codex-learning`, linked knowledge, and
   candidate classification; only qualifying evidence can change a reusable
   contract.
3. **Evolve:** verified outcomes route through `codex-experience-capture`,
   `codex-architecture-iteration`, and the existing owner that should absorb
   the change.

Use the experience-first ladder: project authority and verified local indexes
before raw history; existing skills and deterministic scripts before fresh
model work; targeted external evidence only when the local record cannot decide
the task. Batch independent read-only checks. Stop as soon as the stated
acceptance criteria are decidable.

## Resource and Parallelism Rules

Keep the quality floor, security controls, and required verification fixed. For
the resource ladder, caching, paid/external escalation, and human-attention
budget, use [../resource-economy/SKILL.md](../resource-economy/SKILL.md).

Default to one execution owner. Use parallel work only when work is independent,
read-only or has isolated write surfaces, shares the same acceptance criteria,
and has a named merge/checkpoint owner. Never run concurrent writers against
the same artifact. Logical role assignment does not authorize agent spawning,
external multi-agent infrastructure, monitoring, or model-provider changes.

## Safety and Closeout

Previously granted permission does not authorize a later external update,
installation, reconfiguration, or substantive re-learning. Do not create a
periodic update monitor. Preserve confirmation boundaries for destructive,
public, paid, privileged, credential, or irreversible actions. Route unexpected
owner or handoff behavior to `codex-error-feedback` before learning from it.

Close by reporting role outputs, evidence, resource-relevant choices,
verification, and limits. Capture only verified cross-project lessons, then run
the architecture/economy review when a reusable workflow changed. Revisit this
contract after observed multi-owner use; it is not evidence that autonomous
teams are warranted.

---
name: loopx-auto-ml-experiment
description: Use for long-running local ML experiment trajectories with hypotheses, matched windows, replicates, negative lineages, guardrails, and promote/retire gates.
---

# LoopX Auto ML Experiment Adapter

This is advisory and evidence-first on a local desktop. It does not launch,
stop, restart, or promote external training jobs unless a separate owner and
registry gate explicitly grants that authority.

## Durable experiment contract

Keep generic LoopX goal/todo/quota state separate from domain state at
`.loopx/domain-state/<goal-id>/ml_experiment/ledger.jsonl`. Each checkpoint
must identify a hypothesis, mechanism family, code/model lineage, matched
train/eval windows, primary metric, guardrail status, and next decision.
Record invalid or failed lineages as evidence; do not silently retry a weak
near-neighbor.

Promotion requires aligned evaluation evidence, clean guardrails, and an owner
or registry decision. Otherwise classify as monitor, no-promote, retire, or
replan. A metric delta alone never makes a winner.

## Desktop policy

Default to `ml-experiment preview` and compact result ledgers. Use one local
replicate at a time, low-frequency observation, artifact aliases instead of
raw dumps, and no background launch loop. A child returns a ledger row and
verification; the parent decides whether to spend another slot or stop.
When a genuinely discriminating replicate or longer matched window justifies
the cost, the parent may enable a higher-cost experiment batch, but must record
the budget, expected information gain, stop rule, and no-promote fallback
before spending the next slot.

Example:

```powershell
& F:\codex\scripts\Invoke-LoopX.ps1 ml-experiment preview --format json `
  --experiment-id exp_01 --primary-metric offline_auc `
  --baseline-value 0.421 --candidate-value 0.437 `
  --guardrail-status clean --train-window train_w1 --eval-window eval_w1 `
  --hypothesis-id h_route_mix --mechanism-family route_mix --route local_replicate
```

Required write surface: `.runtime/work/auto-ml-experiment-agent/<task-id>`. Required
evidence: `hypothesis.json`, `dataset_window.json`, `replicate_*.json`,
`result_ledger.json`, `decision.json`, and `handoff.json`. Raw metrics, private
paths, commands, environment dumps, and credentials stay outside the durable
control plane.

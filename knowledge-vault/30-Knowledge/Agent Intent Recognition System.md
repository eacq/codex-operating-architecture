---
id: concept-agent-intent-recognition-system
title: Agent Intent Recognition System
type: knowledge
owner: codex-self-evolution
status: active
source: https://github.com/LesterYu0/feynman-build-workshop/tree/main/episodes/02-intent-recognition
---

# Agent Intent Recognition System

The Global Experience Agent uses a local intent-recognition funnel before an
`Auto` request becomes a runtime operation. The design adapts the four-layer
intent router from `LesterYu0/feynman-build-workshop/episodes/02-intent-recognition`
without copying its business demo or adding its optional embedding dependencies.

## Contract

- policy: `config/agent-intent-policy.json`;
- runtime integration: `agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1`;
- operation: `ClassifyIntent`;
- event: `intent_classified`;
- tests: `scripts/Test-AgentIntentRecognition.ps1` and
  `scripts/Test-GlobalExperienceAgent.ps1`;
- authority: intent labels never grant authority. The resolved operation still
  passes through `config/agent-interface-policy.json` before durable mutation.

## Four Layers

1. `L0` handles explicit operations, explicit owners, slash commands, and
   high-frequency fixed phrases.
2. `L1` uses deterministic local utterance and keyword scoring for common Agent
   operations.
3. `L2` is reserved for a future strict enum host adapter with temperature `0`;
   it is disabled by default and never called by the local runtime.
4. `L3` falls back to `StartWork` so unknown or ambiguous requests become a
   bounded work contract instead of an unsafe guessed side effect.

## Safety Boundary

The classifier is evidence-only unless its result is later executed as the
selected runtime operation. Gated or structural operations such as
`CompleteIteration` and `RequestStructureChange` still require the registered
interface permission, authority scope, owner gate, save point, rollback, and
verification path.

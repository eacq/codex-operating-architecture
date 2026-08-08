---
title: Agent Loop System
type: information-unit
status: active
learning_audience: codex
codex_learning: "Treat feynman-build-workshop episode 06 as the Global Experience Agent control-plane contract: bounded Plan-Act-Observe-Reflect-Settle loop, explicit error observations, context budget, multi-condition termination, tracing, and owner-gated tool execution."
source: LesterYu0/feynman-build-workshop episode 06 agent-loop
owner: codex-self-evolution
verification:
  - scripts/Test-AgentLoopPolicy.ps1
  - scripts/Test-AgentHarnessContract.ps1
  - scripts/Test-AgentSystemTopology.ps1
---

# Agent Loop System

Episode 06 of `LesterYu0/feynman-build-workshop` is a control-plane lesson for
the Global Experience Agent. C01-C05 provide the data plane: Agent memory,
intent recognition, document parsing, chunking retrieval, and rerank
calibration. C06 defines how the Agent decides, acts, observes, recovers, and
stops.

The local adaptation does not install OpenAI, FastAPI, LangChain, LlamaIndex,
or any background runner. It strengthens the existing
`agent/40-runtime/Invoke-GlobalExperienceAgent.ps1` harness with a policy that
is readable through `agent/40-runtime/Get-AgentHarnessState.ps1` and verified by
`scripts/Test-AgentLoopPolicy.ps1`.

## Control points

1. Max iterations. Bounded work never uses unguarded `while true` progress. The
   default ceiling is 10, and overflow returns partial evidence plus the next
   authority boundary.
2. Error recovery. Tool, parser, authorization, and unknown-tool failures become
   explicit observations or error-feedback records. Empty strings are not valid
   recovery evidence.
3. Context budget. The Agent preserves system/project authority, the active task
   contract, the latest save point, and recent observations. Older context is
   summarized, retrieved from Agent memory, or reconstructed from Codebase
   Memory evidence rather than carried as raw transcript.
4. Termination. Completion does not rely on one marker. The loop stops on finish
   action, explicit final-answer signal, max iteration ceiling, settled save
   point, authority boundary, or verification failure.
5. Transport recovery. If a known stream, TLS, connection, or request-timeout
   failure occurs before a completion marker, the loop disables automatic retry,
   persists the current session and pending writes, and returns a typed
   `restart-required` exit with a user-facing restart prompt. Child-Agent
   failures propagate through `JoinSubagent` to the parent instead of leaving
   the parent waiting indefinitely.
6. Host watchdog. After a Codex app thread snapshot, an active `inProgress` turn
   with no assistant message and no tool marker for the configured threshold is
   classified as `host-stall-suspected`. Persist a host-recovery marker and prompt
   for restart; never force-kill the task. This closes the silent-hang boundary
   that cannot produce an error string for the Agent runtime classifier.

## Local loop

The Agent control plane is:

`Plan -> Act -> Observe -> Reflect -> Settle`

- Plan maps to intake, experience context loading, and resource selection.
- Act maps to owner-routed tool-gate requests and bounded tool calls.
- Observe records tool results or error feedback.
- Reflect chooses the narrowest proving check and candidate or memory update.
- Settle commits or rejects a save point and returns a typed exit.

The one-step rule is deliberate: each `Run` or `Continue` operation executes or
routes at most one bounded operation before settlement. Follow-on work becomes
`nextTurn`, `FollowUp`, or a new authorized `Continue` call.

### Transport failure boundary

The shared policy is `config/agent-transport-recovery-policy.json`, implemented
by `agent/40-runtime/TransportRecovery.ps1` and exposed through
`agent/40-runtime/Get-AgentTransportRecoverySignal.ps1`. A classified failure
sets the durable state to `blocked-restart-required`, records only a safe error
hash and classification, preserves pending writes and child lineage, and tells
the user to restart Codex or the affected host. After restart, `Resume` re-arms
the session; `Continue` remains blocked until that resume boundary is accepted.
Ordinary validation, parser, authorization, and business errors stay on the
normal error path.

### Host watchdog boundary

The host-facing detector is `agent/40-runtime/Get-AgentHostRecoverySignal.ps1`.
It consumes snapshots from `codex_app__list_threads` and
`codex_app__wait_threads`, persists `.codex/project/host-recovery/latest.json`,
and returns the same restart boundary without killing the task.

## Authority boundary

The loop can request specialist work, but it cannot bypass owner gates. Git,
release, installation, credentials, external services, public endpoints,
background autonomous runners, non-idempotent retry, and structural owner
changes keep their existing gates.

Loop traces in Git contain only safe metadata: event names, phases, owners,
operation names, statuses, path evidence, hashes, typed exits, and residual
risk. Raw private prompts, credentials, transcripts, headers, and full tool
payloads are unsafe by default.

## Functional units

- `config/agent-loop-policy.json`
- `agent/40-runtime/Get-AgentHarnessState.ps1`
- `agent/40-runtime/Invoke-GlobalExperienceAgent.ps1`
- `agent/40-runtime/Invoke-GlobalExperienceAgentRuntime.ps1`
- `config/agent-transport-recovery-policy.json`
- `agent/40-runtime/TransportRecovery.ps1`
- `agent/40-runtime/Get-AgentTransportRecoverySignal.ps1`
- `agent/40-runtime/HostTransportRecovery.ps1`
- `agent/40-runtime/Get-AgentHostRecoverySignal.ps1`
- `scripts/Test-AgentLoopPolicy.ps1`
- `scripts/Test-AgentTransportRecovery.ps1`
- `scripts/Test-AgentHostTransportRecovery.ps1`

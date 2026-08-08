# Network Learning: Durable Iteration and Decision Records

## Trigger

The experience system needs stronger, testable handoffs before it simplifies skills, knowledge, experience, or workflows.

## Sources and comparison

- Temporal documents durable workflow execution through append-only event history, deterministic workflow code, and idempotent or explicitly non-retryable activities.
- LangGraph documents persistent state, resumability, and human oversight for long-running agent workflows.
- ADR guidance records the context and consequences of significant decisions and treats lifecycle/sunsetting as first-class concerns.

## Decision

Revise existing owners rather than add a module. The Git iteration gate now runs replay-safe, read-only integration probes for workflow-to-knowledge/experience routing and GPT-first visual planning before it permits an iteration record. The probes have no external side effect; only `-Apply` writes an ignored local gate record.

## Rejected or deferred

Do not introduce a workflow engine, background scheduler, external state service, or automatic retry. Those add operational and privacy risk without evidence that this local architecture needs them.

## Validation and invalidation

The gate must pass its probes and full validation. If a probe becomes flaky, requires credentials, reads raw session data, or adds meaningful latency, remove it and retain only a deterministic contract check.

## Sources

- https://github.com/temporalio/temporal/blob/main/docs/architecture/README.md
- https://github.com/langchain-ai/langgraph
- https://github.com/architecture-decision-record/architecture-decision-record

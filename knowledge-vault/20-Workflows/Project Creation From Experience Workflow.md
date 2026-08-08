---
id: workflow-project-creation-from-experience
type: workflow
status: active
source: xlw1-project-iteration-2026-07-15
verified: true
learning_audience: codex
codex_learning: New project creation should turn folder evidence into lifecycle files, project-local skills, storage indexes, runtime preflight, error feedback, and verified retrospectives before promoting global lessons.
---

# Project Creation From Experience Workflow

This workflow connects [[Project Knowledge Boundary]], [[Experience System Error Feedback]],
[[Verified Experience Promotion]], and [[Knowledge System Module]]. It turns a
folder into a durable Codex project operating layer.

## Trigger

Use this when:

- a project lacks `.codex/project/state.json`;
- the user asks to build project-specific skill, knowledge, or experience;
- prior conversations/API-mode records must become project operating rules;
- repeated errors show that chat-only instructions are insufficient.

## Inputs

- Project root and Git topology.
- User goal, current artifact authority, and open decisions.
- Existing source files, scripts, templates, logs, and generated outputs.
- Runtime, shell, package, and external-tool evidence.
- Prior Codex/API history, summarized and sanitized.

## Steps

1. Route through `codex-self-evolution`.
2. If lifecycle files are missing, run the project-optimization initializer.
3. Write evidence-backed requirements and keep unknowns explicit.
4. Record repeatable commands and domain gates in `WORKFLOWS.md`.
5. Store verified local lessons in `EXPERIENCE.md`.
6. Append complete iteration evidence in `RETROSPECTIVES.md`.
7. Add project-local skills for recurring project-specific workflows.
8. Keep artifact indexes under `.codex/project/storage/`.
9. Add runtime/encoding preflight before dependency-backed work.
10. Create error-feedback reports for repeated wrong-result, runtime, encoding,
    or routing failures.
11. Promote only verified cross-project lessons into the global knowledge system
    or owning skill.

## Outputs

- `.codex/project/REQUIREMENTS.md`
- `.codex/project/WORKFLOWS.md`
- `.codex/project/EXPERIENCE.md`
- `.codex/project/RETROSPECTIVES.md`
- `.codex/project/state.json`
- optional `.codex/project/skills/<name>/`
- optional `.codex/project/storage/<domain>/`
- `.codex/errors/<report>/` for verified failures

## XLW1 evidence

XLW1 demonstrated the pattern with a manuscript-formatting project:

- lifecycle files retained local manuscript facts;
- project-local skills and storage separated workflow from artifacts;
- repeated user corrections became stronger audits;
- runtime/encoding drift became a preflight and error-feedback gate;
- verified lessons were added to project experience before global abstraction.

## Verification

- Parse lifecycle JSON and storage indexes.
- Smoke-test project scripts with the runtime they will actually use.
- Run the project’s strongest domain validation gate.
- Check that project-local skills do not contain secrets.
- Confirm global notes contain generic rules, not private project content.

## Links

- Applies to: [[Project Knowledge Boundary]]
- Uses: [[Experience System Error Feedback]]
- Produces: [[Verified Experience Promotion]]
- Maintained by: [[Knowledge System Module]]

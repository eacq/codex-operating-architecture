# Local state boundary

This directory is a tracked policy boundary, not a runtime-data folder.

- Agent sessions: `.codex/project/agent-sessions/`
- Project lifecycle: `.codex/project/state.json`
- Temporary runtime work: `.runtime/work/`
- Runtime evidence: `.runtime/evidence/`

Those locations remain ignored or locally governed. Never copy credentials, raw private sessions, caches, or temporary evidence into `agent/`.

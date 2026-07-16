# Local Conversation Catalog Contract

The catalog is a local metadata index for `session_index.jsonl`, `sessions/`,
`archived_sessions/`, and desktop pin/project metadata in
`.codex-global-state.json`. It is independent of provider, account, model,
and active `auth.json` schema.

Only add metadata fields that can be derived without reading conversation text
or credentials. Keep raw conversation files in place. The desktop sidebar may
have a narrower UI filter than the catalog; the catalog is the continuity
source for agents, not a replacement for the desktop UI.

Provider switches must refresh the catalog after their new auth/config state is
committed. A catalog failure may be reported, but it must not undo a completed
provider switch or mutate any session file.

## Artifact-source boundary

This catalog intentionally does not index conversation completion, final
deliveries, document paths, or tool payloads. For a file-producing project,
metadata search is only the first stage. The caller must use a minimal raw
session inspection to distinguish a current user-designated file, a complete
delivery, and a later interrupted branch. User-specified artifacts outrank
inference from session timing, provider fields, scripts, QA output, or file
timestamps. Store only a redacted project-level selection record containing
the selected path/hash, session ID, selection basis, and verification status.

## Compaction-context inheritance boundary

Some local session files contain a chain of `compacted` records. Each record
has a compacted handoff message, an ordered window lineage, and a
`replacement_history` field containing raw prior messages. The compacted
message is reusable derived context; `replacement_history` is private raw
history.

When an agent resumes a history-dependent task, it may create a private,
bounded inheritance input that combines:

1. prior compaction summaries in chronological order, with their window IDs;
2. the current task's pre-compression context; and
3. the current task's post-recovery/current-state context.

The inheritance input is an input to one new compression pass, not an
ever-growing transcript. It must include source session IDs, a character
budget, and the authority order: current user instruction, verified current
project state, current context, then historical summaries. Deduplicate
repeated facts and retain conflicts as explicit decisions rather than silently
averaging them.

Do not write raw `replacement_history`, raw prompts, tool payloads, encrypted
reasoning, credentials, or unrelated messages into the catalog, project
knowledge, or committed repositories. If raw boundary inspection is needed to
resolve an ambiguity, perform it in memory for the smallest necessary span and
persist only a redacted conclusion with its provenance.

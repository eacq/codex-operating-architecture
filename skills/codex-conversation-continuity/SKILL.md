---
name: codex-conversation-continuity
description: Build and query a provider-independent catalog of local Codex conversations across session_index.jsonl, active sessions, and archived sessions. Use when continuing work after changing a ChatGPT account, API key, or model provider; when a local conversation appears missing; or when relevant prior local Codex history must be located before planning or implementation.
---

# Codex Conversation Continuity

Treat the local Codex home as the source of conversation continuity, not the
active provider, account, `auth.json`, or desktop sidebar. Never copy or
inspect credential values.

## Workflow

1. Refresh the metadata-only catalog before a provider switch and after the
   new provider state is committed:

   ```powershell
   py scripts/build_conversation_catalog.py --refresh
   ```

   Validate the refreshed UTF-8 file with the same Python runtime that created
   it. Do not use a Windows PowerShell default-decoded read as JSON evidence;
   it can produce a false parse failure for non-ASCII metadata.

2. Locate relevant history by task terms, workspace path, or thread ID:

   ```powershell
   py scripts/build_conversation_catalog.py --query "provider switch"
   ```

3. Read only the matched local session files needed for continuity. Start with
   `session_meta`, project records, and summaries; do not bulk-load prompts,
   tool payloads, or credentials.

4. If the active desktop sidebar does not show a locally cataloged thread,
   report it as a UI discovery limitation. Do not delete, rewrite, or migrate
   session files to make the sidebar change.

## Compaction-Context Inheritance

When a recovered session contains `compacted` records, do not treat the most
recent handoff summary as its entire history. Build one bounded successor
compression input from the compaction lineage and the current task context:

```powershell
py scripts/build_context_inheritance.py <matched-session.jsonl> `
  --current-before <current-state-before.md> `
  --current-after <current-state-after.md> `
  --out <private-derived-handoff.md>
```

The utility retains the ordered prior compaction summaries, records their
before/after window identifiers, and folds the supplied current pre/post
context into one redacted, budgeted input. The next summarization must resolve
conflicts in this order: the current user instruction, verified current
project pointers/hashes, the current task context, then historical summaries.
It must emit one successor summary with source IDs and decisions, not append
unbounded histories.

`replacement_history` and messages surrounding a compaction are raw local
conversation material. They may be inspected transiently only when a summary
is ambiguous; never persist them or include them verbatim in an inheritance
artifact. The derived handoff may contain only compacted summaries, supplied
current context, redacted provenance, and bounded semantic facts.

## Recovering a Project Artifact From History

The catalog establishes discovery only; it does not establish which document
artifact is authoritative. When a user asks to continue a file-producing task,
resolve the source in this order:

1. A file explicitly designated by the user in the current request.
2. A file explicitly delivered at the end of the last complete relevant local
   session.
3. A file linked by a verified project source pointer, manifest, and matching
   hash chain.
4. Timestamp, script, and QA evidence, used only to classify otherwise
   ambiguous artifacts.

After metadata narrows the candidate sessions, inspect only the minimal raw
session evidence needed: the relevant user instruction, the artifact-producing
operation, and the final delivery or interruption boundary. A tool-created
file, a successful QA run, a provider/model field, or a later modification time
does not by itself prove that a branch was completed or authorized. Treat a
quota/rate-limit/interrupted branch as diagnostic evidence only unless the user
explicitly promotes its artifact. Record the selected path, hash, session ID,
selection basis, and verification result in the project; never copy raw
prompts, tool payloads, credentials, or unrelated messages into durable
records.

## Guarantees and Limits

- The catalog merges active and archived local session metadata with the local
  session index and desktop pin/project metadata, so account/API switches do
  not alter its discovery scope.
- It stores metadata only: IDs, titles, pin state, project/workspace hints,
  timestamps, working directories, and source paths. It never stores message
  content, tokens, API keys, or auth.
- It cannot merge cloud-only conversation history from a different account
  that is not present in the local Codex home.
- `model_provider`, account, and active authentication metadata identify a
  routing context, not the authority or completion state of a document branch.

See [references/local-history-contract.md](references/local-history-contract.md)
before changing the catalog schema or provider-switch integration.

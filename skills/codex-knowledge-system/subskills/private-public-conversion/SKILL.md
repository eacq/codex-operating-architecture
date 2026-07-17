---
name: codex-knowledge-system-private-public-conversion
description: Owner-internal subskill for converting private knowledge or experience into sanitized public candidates.
---

# Private To Public Conversion

Use this subskill only through the parent `codex-knowledge-system` owner.

## Trigger

Run when a private skill, knowledge note, or experience lesson may be shared
outside the local environment.

## Contract

Use `scripts/Convert-PrivateKnowledgeToPublic.ps1` first in read-only mode.
Apply mode requires two independent verified evidence paths and creates only a
sanitized public candidate.

The converter must refuse raw history, credential-state markers, personal
paths, endpoints, and secret-like values. Keep non-secret local preferences only
in a local portability profile.

## Handoffs

After conversion, validate links and builds, then route the candidate through
`codex-experience-capture`, documentation synchronization, and the private
auto-Git gate when applicable. A sanitized candidate is not a public release.

## Verification

Run `scripts/build_knowledge.py`, `scripts/build_mindmaps.py`, and the relevant
publication/privacy checks before any release decision.

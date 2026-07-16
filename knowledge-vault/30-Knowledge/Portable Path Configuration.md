---
id: portable-path-configuration
type: concept
status: active
source: codex-skill-portability
verified: true
learning_audience: codex
codex_learning: Git-tracked skills, knowledge records, manifests, and public docs must use logical roots or repository-relative paths; machine-specific roots belong in the local portable profile or environment variables.
---

# Portable Path Configuration

Tracked architecture content must not rely on one machine's drive letters, user
home, installer directory, provider endpoint, or account state. Use logical
roots in committed files and resolve them locally at runtime.

## Logical roots

- `$ARCHITECTURE_ROOT`: the cloned architecture repository.
- `$CODEX_HOME`: the local Codex home directory.
- `$EXTERNAL_WORKSPACE`: a local parent for other projects referenced as evidence.
- `$SOFTWARE_ARCHIVE_ROOT`: the local installer/archive directory.
- `$SOFTWARE_INSTALL_ROOT`: the local custom installation directory.
- `$IMAGE_QUARANTINE_ROOT`: the local image quarantine directory.

## Routing rule

Reusable workflow belongs in tracked skills and docs. Private path choices
belong in `~/.codex/private-skill-config/portable-skill.json` or environment
variables documented in [[Knowledge Tooling]]. Generated history catalogs,
image manifests, learning indexes, and MindMaster/Mermaid maps must preserve
the same boundary so that a clone remains understandable without this machine.

## Links

- Supports [[Project Knowledge Boundary]] by keeping project facts local and
  publishing only portable references.
- Supports [[Provider Capability Boundary]] by separating protocol contracts
  from private provider and account choices.
- Supports [[Image Hosting and Cleanup Workflow]] by keeping quarantine paths
  configurable while remote Markdown URLs stay portable.

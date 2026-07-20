---
name: imported-api-provider-routing
description: Internal compatibility package for the migrated Codex Home skill 'api-provider-routing'. Route through codex-credential-management; this package is not a top-level discovery interface.
---

# Imported Codex Home Package: api-provider-routing

**Owner:** $(@{Name=api-provider-routing; Owner=codex-credential-management; Source=%USERPROFILE%\.codex\skills\api-provider-routing}.Owner)
**Invocation:** owner-routed internal subskill; do not register this package as a new global entry point.
**Imported source:** upstream/ (portable workflow and non-secret assets only).

## Contract

1. Reuse the upstream material only when the parent owner selects this mode.
2. Follow the parent owner's authority, privacy, validation, and handoff rules.
3. Local provider, account, path, runtime, and credential choices remain in the private migration profile; never reconstruct them from the imported content.
4. Before changing this package, compare its trigger, artifacts, and safety boundary with the parent owner and promote only with verified reuse evidence.

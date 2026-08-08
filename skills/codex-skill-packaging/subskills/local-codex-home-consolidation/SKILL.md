---
name: local-codex-home-consolidation
description: Consolidate direct user-installed Codex Home skills into canonical global owner subskills, preserve a reversible local backup, migrate only non-secret configuration metadata, and reduce top-level skill discovery surface.
---

# Local Codex Home Skill Consolidation

Use this internal mode when direct packages exist under `$CODEX_HOME/skills` in
addition to the canonical junction interfaces.

1. Classify each direct package against an existing owner by trigger, artifacts,
   maintained knowledge, and safety boundary. Do not add a global owner merely
   to preserve an upstream package name.
2. Maintain `config/local-skill-consolidation.json` as the explicit source to
   owner map. A package without a map blocks apply mode.
3. Run `scripts/Migrate-CodexHomeSkills.ps1` in preview, then `-Apply` only
   with current authorization. It copies reusable content to
   `skills/<owner>/subskills/imported-codex-home/<package>/upstream/`, writes a
   small owner-routed wrapper, and moves the original package to an off-root
   Codex Home backup.
4. Never import runtimes, `.git`, browser state, credential files, live `.env`
   files, certificates, tokens, cookies, or private endpoints. Record only
   placeholder or filename-level configuration migration facts in the local
   private profile.
5. Rebuild canonical junction interfaces with `scripts/install-global.ps1
   -Mode Junction`, then validate the repository and global install. Keep
   imported subskills internal unless two independent verified uses establish a
   separate owner boundary.

**Acceptance:** every mapped direct package has a canonical owner, a verified
portable copy, an off-root backup, a non-secret local profile record, and no
new top-level discovery interface.

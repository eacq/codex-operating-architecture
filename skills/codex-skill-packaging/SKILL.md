---
name: codex-skill-packaging
description: Create, update, consolidate, validate, install, and document reusable global Codex skills and skill collections. Use when adding a module, turning a workflow into a skill, removing duplication among skills, changing skill triggers, or packaging this architecture for global discovery.
---

# Codex Skill Packaging

Use the system `skill-creator`. Keep each skill focused and concise; put triggers in YAML and move optional detail to direct references. Prefer an existing owner over duplication, and keep `agents/openai.yaml` aligned.

Use subskill-style organization to reduce top-level module sprawl. A subskill is
an owner-internal capability package under `subskills/<name>/` or a direct
reference contract plus scripts under the owning skill. It may define modes,
inputs, outputs, handoffs, and tests, but it is not a separately registered
global skill and must not duplicate the parent's YAML trigger surface.

Use parent-skill refinement when an existing broad owner has become a long
controller document. The parent `SKILL.md` keeps discovery metadata, routing,
acceptance gates, and non-negotiable safety boundaries; detailed modes, gates,
recovery paths, and release commands move into owner-internal subskills.

## Naming And Renames

Use [references/skill-naming-governance.md](references/skill-naming-governance.md)
when a skill name may no longer match its actual capability. A rename requires
agreement between the skill's real contract, user-recognizable language,
verified experience evidence, and owning parent. Top-level names are reserved
for independent owners; parent-owned capabilities move to `subskills` and use
a parent-prefixed callable name. Keep a compatibility alias for one release
and validate the migration map before retiring a historical name.
Top-owner renames may use the stored naming-only authority when their contract
and safety boundary are unchanged; they never authorize owner restructuring.

Create a top-level skill only when the trigger, workflow, maintained knowledge,
artifacts, and safety boundary do not fit an existing owner. Otherwise add a
subskill-style contract to the owner and route from the parent `SKILL.md`.

External skills may be installed, but never by raw copying alone. First classify
the candidate as: learn-only, owner-reference, owner-internal subskill,
project-local skill, or global top-level skill. Install only when the candidate
has clear necessity, reusable value, compatibility with this architecture's
privacy and verification rules, and a validation path. Adapt names, triggers,
profiles, safety boundaries, and docs to the local owner model instead of
preserving upstream structure merely because it exists.

Before installing an external Codex workflow package, compare its takeover
surface. Treat full runtimes that manage CLI launch, hooks, config, state
directories, worktrees, team sessions, MCP/plugin wiring, or implicit keyword
routing as high-risk: default them to learn-only or owner-reference unless the
user explicitly needs that runtime and a rollback plus real execution smoke test
is available. Treat lite methodology packages as extraction candidates: reuse
manifest, dry-run/check, backup, size-budget, and conflict-marker ideas, but
rewrite install roots, invocation policy, and validation for this architecture.
Imported workflows default to explicit invocation until repeated local evidence
proves implicit routing is safer and more useful.

Edit only `$ARCHITECTURE_ROOT\skills`. Global paths are junction interfaces installed by `install-global.ps1`; use copy mode only as a recorded filesystem exception.

Read [references/subskill-contract.md](references/subskill-contract.md) before
adding, splitting, or promoting a subskill-style capability. Read
[references/parent-skill-refinement.md](references/parent-skill-refinement.md)
before trimming a broad parent skill.

For a pre-existing direct Codex Home skill inventory, use
[subskills/local-codex-home-consolidation/SKILL.md](subskills/local-codex-home-consolidation/SKILL.md).
It imports compatible content beneath existing owners, migrates only non-secret
configuration metadata, retains an off-root rollback copy, and rebuilds the
single canonical global discovery surface.

Run `quick_validate.py`, relevant subskill script tests, full validation, and
global-interface validation. Skill files and junctions are ordinary file
handling; notify before any external software or system change required by a
skill.

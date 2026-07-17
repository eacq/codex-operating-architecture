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

Create a top-level skill only when the trigger, workflow, maintained knowledge,
artifacts, and safety boundary do not fit an existing owner. Otherwise add a
subskill-style contract to the owner and route from the parent `SKILL.md`.

Edit only `$ARCHITECTURE_ROOT\skills`. Global paths are junction interfaces installed by `install-global.ps1`; use copy mode only as a recorded filesystem exception.

Read [references/subskill-contract.md](references/subskill-contract.md) before
adding, splitting, or promoting a subskill-style capability. Read
[references/parent-skill-refinement.md](references/parent-skill-refinement.md)
before trimming a broad parent skill.

Run `quick_validate.py`, relevant subskill script tests, full validation, and
global-interface validation. Skill files and junctions are ordinary file
handling; notify before any external software or system change required by a
skill.

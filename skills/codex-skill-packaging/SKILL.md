---
name: codex-skill-packaging
description: Create, update, consolidate, validate, install, and document reusable global Codex skills and skill collections. Use when adding a module, turning a workflow into a skill, removing duplication among skills, changing skill triggers, or packaging this architecture for global discovery.
---

# Codex Skill Packaging

Use the system `skill-creator`. Keep each skill focused and concise; put triggers in YAML and move optional detail to direct references. Prefer an existing owner over duplication, and keep `agents/openai.yaml` aligned.

Edit only `$ARCHITECTURE_ROOT\skills`. Global paths are junction interfaces installed by `install-global.ps1`; use copy mode only as a recorded filesystem exception.

Run `quick_validate.py`, relevant script tests, full validation, and global-interface validation. Skill files and junctions are ordinary file handling; notify before any external software or system change required by a skill.

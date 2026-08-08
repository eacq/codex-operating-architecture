# Skill Naming Governance

Rename a skill only when the existing name materially obscures its proven
capability or owning parent. Active root skills are architecture owners and use
`codex-<domain>`; a capability that shares a parent's trigger, artifacts,
knowledge, and safety boundary belongs under `skills/<parent>/subskills/` and
uses the callable name `codex-<parent>-<capability>`. Assess actual contract,
user-recognizable language, and verified experience plus
`module-registry.json` evidence. Keep a stable name when no candidate is
clearly better on all three.

Top-owner names may be migrated automatically under the stored naming authority
only when the migration is naming-only: its owner contract, trigger, artifacts,
knowledge, and safety boundary do not change. The same three-way evidence,
migration record, compatibility alias, reference update, and validation gates
remain mandatory. Adding, merging, splitting, deprecating, deleting, or
materially revising an owner still requires separate user authorization.

For a live rename, add a canonical kebab-case name, preserve the historical
top-level entry for at least one release as a routing-only compatibility alias,
and record the mapping in `config/skill-name-migrations.json`. Update metadata,
agents, executable paths, tests, module registry, architecture, requirements,
workflows, documentation, and global junction interfaces. Run
`scripts/Test-SkillNameMigrations.ps1`, full validation, installation, and
global-interface validation before retiring an alias.

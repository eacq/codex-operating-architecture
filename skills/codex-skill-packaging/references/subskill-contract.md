# Subskill-Style Packaging Contract

Use subskill-style packaging when a capability is real enough to need its own
mode contract, scripts, tests, or examples, but not independent enough to become
a top-level global skill.

## Allowed shapes

- `skills/<owner>/subskills/<name>/SKILL.md` for an owner-internal capability
  with substantial instructions.
- `skills/<owner>/references/<name>-contract.md` for a lightweight mode or
  workflow contract.
- `skills/<owner>/scripts/<name>*.ps1|py` for executable support owned by the
  parent skill.
- `skills/<owner>/examples/<name>/` or `templates/<name>/` for reusable assets.

## Rules

1. The parent `SKILL.md` remains the only discovery surface. Its YAML
   description should mention the broad owner trigger, not every subskill.
2. A subskill must name its trigger, inputs, outputs, owner handoffs,
   verification, and safety boundary.
3. A subskill may call other global skills, but it must not reimplement their
   contracts or hide a new owner boundary.
4. The module registry tracks only the parent owner unless the subskill later
   proves it needs a separate top-level owner.
5. Promote a subskill to a top-level skill only after two independent verified
   use cases show that trigger, workflow, artifacts, maintained knowledge, and
   safety boundary no longer fit the parent.
6. Merge a subskill back into the parent when its contract is small enough that
   a direct section is clearer than a separate internal package.

## Validation

- Run quick validation on the parent skill.
- Run any subskill-specific tests or smoke checks.
- Run full repository validation and global-interface validation after changing
  parent routing, scripts, or generated knowledge.
- Update linked knowledge or workflow records when the subskill changes durable
  behavior.

# Skill Architecture Review - 2026-07-14

## Scope

Reviewed all 16 architecture skills against `module-registry.json`, the requirements manual, project experience, trigger descriptions, bodies, references, scripts, and global routing.

## Result

- Modules before and after: 16.
- Total `SKILL.md` words: 3236 -> 2546 (-21.3%).
- Skills materially reduced: 8.
- Skills already concise and preserved: 8.
- Added, split, merged, deprecated, or deleted modules: 0.

## Overlap decisions

| Candidates | Shared surface | Decision | Boundary retained |
|---|---|---|---|
| self-evolution / project-optimization | project entry and lifecycle | keep separate | global routing versus project-local initialization and optimization |
| self-evolution / task-execution | planning, execution, verification | keep separate | controller routing versus implementation workflow |
| architecture-iteration / skill-packaging | skill changes and validation | keep separate | module governance/versioning versus skill artifact packaging/discovery |
| information-gathering / learning | evidence collection | keep separate | task decision evidence versus comparative study and tested practice promotion |
| project-optimization / experience-capture | project history and lessons | keep separate | project improvement lifecycle versus lesson extraction and promotion gate |
| knowledge-system / image-workflow | visual knowledge | keep separate | canonical linked knowledge versus fragile image upload/recovery transaction |
| tool-installation / skill-packaging | installation and global discovery | keep separate | external tools/runtimes versus local skill artifacts and junction interfaces |
| git-operations / experience-capture | Git milestones | keep separate | Git safety and remote operations versus post-event knowledge synchronization |

No pair met the registry merge rule of substantial overlap in trigger, workflow, and maintained knowledge. No missing capability had two independent use cases without an owner, so no module met the add rule. No active module lacked evidence or had a superseding owner, so none met deprecation.

## Deduplication applied

- The controller now routes instead of repeating downstream module procedures.
- The knowledge skill owns schemas and learning boundaries but delegates image transactions.
- The image skill keeps only the fragile, ordered safety transaction in its body.
- Tool installation keeps the local software-root policy while detailed path policy remains in its reference.
- Skill packaging keeps authoring, validation, and junction rules without repeating installation policy.
- Experience capture keeps the promotion gate without repeating the full knowledge-system workflow.

## Validation

- All 16 skills passed `quick_validate.py` through `scripts/validate.ps1`.
- Module registry still matches skill folders.
- Knowledge, mind-map, learning, image, and secret-scan validation passed.
- Global junction interfaces remain unchanged because canonical canonical repository folders were edited in place.

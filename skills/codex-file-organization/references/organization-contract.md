# Organization Contract

- Default plan and lifecycle review are read-only and reversible. File moves or renames require an explicit, user-approved plan, a verified backup created outside the selected root, and an explicit apply request. The global experience iteration never applies moves.
- Folder roles: `00-inbox` unclassified intake; `10-active` current work; `20-reference` durable inputs; `30-output` derived deliverables; `40-archive` closed material; `90-private-local` non-versioned local-only material.
- Do not move `.git`, `.codex`, `.env*`, `auth.json`, secrets, browser profiles, encrypted stores, or any path outside the selected root.
- Store any name-bearing `organization-plan.json` and backup manifests only in a selected local project location; do not commit them. Lifecycle records committed or shared outside the project may contain only aggregate bucket counts, policy version, checksums, and decision status.
- Keep source filenames unless a rename is explicitly approved. Resolve collisions by adding a suffix rather than overwriting.
- Evolve the taxonomy with the same evidence rule as workflows: retain/refine for a proven rule, add only for a repeated unserved use case, merge substantially overlapping buckets, split a bucket only when lifecycle or access controls materially differ, and deprecate before removal. Test handoffs to workflow, knowledge, experience, backup, and visual documentation before an economy pass.
- `file-organization.json` is the project-local policy. `file-organization-review.json` is a redacted lifecycle result. `file-organization-backup.json` records only backup readiness and a backup checksum; all are under `.codex/project/` by default.

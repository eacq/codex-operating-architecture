# Source grounding

- Repository: https://github.com/zhaoxuya520/reverse-skill
- Reviewed commit: `d8bf34540cbc1aa34052e1b142576fc36a1f1437`
- Local reviewed release: `F:\codex\.runtime\software\reverse-skill\releases\1.0.0-d8bf3454`
- Declared top-level license: MIT (`LICENSE`); the repository also contains nested components with their own licenses, so the adapter does not redistribute those components into the canonical skill tree.
- Inspected source surfaces:
  - `skills/ops/scope-contract.md`
  - `skills/ops/evidence-finding-path.md`
  - `skills/ops/role-map.md`
  - `skills/ops/timeline-workitem.md`
  - `skills/ops/skill-supply-chain.md`
  - `skills/ops/sandbox-profile.md`
  - `skills/ops/IDENTITY.md`
  - `skills/scripts/case-init.ps1`, `case-guard.ps1`, `append-evidence.ps1`
- Adopted: scope/authorization vocabulary, role handoff, Evidence→Finding→Path, append-only timeline, work-item coverage, and external skill supply-chain review.
- Deferred: all target-facing security/逆向/渗透/漏洞利用/提权 skills, automatic bootstrap, MCP endpoints, Kali/Burp/IDA/JDK/Node/Python dependency installation, global client injection, and network actions.

This note records provenance and a guarded adaptation. It is not a claim that the upstream package has been independently reproduced or that its security results are validated for this project.

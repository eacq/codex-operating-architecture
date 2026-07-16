# GitHub Pattern Review

Reviewed on 2026-07-14. These sources informed the design; no third-party code was copied verbatim.

| Source | Adopted pattern | Deliberately excluded |
|---|---|---|
| https://github.com/AlexMikhalev/claude-code-continuous-learning-skill | Extract only reusable, non-trivial, specific, verified knowledge; update an existing skill before creating another | Claude-specific frontmatter and creating a new skill after every discovery |
| https://github.com/savedpixel/ai-agent-workflow-kits | Keep project-local workflow and curated active lessons; preserve user-edited config on updates | Large multi-stage task state machine and mandatory review ceremony for small work |
| https://github.com/JiangWay/openspec-schemas | Scale ceremony with risk; record evidence-based retrospectives and carry unpromoted candidates forward | OpenSpec/Superpowers-specific commands and schema |
| https://github.com/yqlizeao/SymlinkAgent | Use managed blocks and non-destructive project application/checking | Central symlinks, because project knowledge should remain versioned with each project |

---
id: concept-xlw1-version-authority
type: concept
status: active
source: source-xlw1-api-conversation-evidence
verified: true
learning_audience: codex
codex_learning: For XLW1 manuscript work, identify the source DOCX from the newest explicit user instruction, record its path and SHA-256 before changing it, and write each structural revision to a separately named process-folder output.
---

# XLW1 Version Authority

Historical builders, drafts, and refined copies are evidence, not default editing targets. The active source manuscript is chosen by the newest explicit instruction and anchored by its path and SHA-256.

## Evidence

- The initial refinement baseline selected a refined manuscript.
- A later explicit correction required the structural condensation to use `过程文件/当前版本/机械工程学报模板格式修订版.docx` instead.
- The validated structural revision was emitted under `过程文件/初次修改后/` without overwriting the source.

## Invalidation

- Reconfirm the authority rule when the user intentionally replaces the current manuscript or names another source version.

## Links

- Evidence: [[XLW1 API Conversation Evidence]]
- Applies to: [[XLW1 Manuscript Refinement Workflow]]
- Related: [[XLW1 Manuscript Knowledge Map]]

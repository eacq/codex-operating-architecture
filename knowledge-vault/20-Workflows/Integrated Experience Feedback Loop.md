---
id: workflow-integrated-experience-feedback-loop
type: workflow
status: active
source: architecture-iteration-2026-07-15
verified: true
learning_audience: codex
codex_learning: Integrated experience work routes knowledge, generated visuals, hosted images, error reports, and verified lessons through their owning modules instead of merging those modules.
---

# Integrated Experience Feedback Loop

This workflow connects [[Knowledge System Module]], [[Image Workflow Module]],
[[Experience System Error Feedback]], and [[Verified Experience Promotion]].

## Flow

1. Write or update the canonical Markdown knowledge note.
2. Use Mermaid when structure is enough; use [[Image Workflow Module]] only when
   a bitmap materially improves understanding.
3. For generated images, record prompt provenance and capture later edit
   requirements before changing prompt templates.
4. If a bitmap will be embedded broadly, run [[Image Hosting and Cleanup Workflow]]
   on demand to verify upload, rewrite links, quarantine the local
   original, and retain migration manifests.
5. If any module behaves unexpectedly, create an [[Experience System Error Feedback]]
   report before promoting the event.
6. Promote only verified, reusable outcomes through [[Verified Experience Promotion]].

## Refinement rule

Keep modules separate when their triggers and owned artifacts differ. Integrate
them through explicit handoffs: knowledge note, prompt request, image manifest,
error report, experience candidate, and verified knowledge note.

---
name: chinese-me-paper-workflow
description: Build, restructure, review, or iterate Chinese mechanical-engineering journal papers from theses, PDFs, Word manuscripts, figures, tables, and local literature folders. Use when the user asks to condense a dissertation into a journal paper, follow Journal of Mechanical Engineering-style logic, preserve core innovations, compare with related papers, or improve a manuscript from overall structure down to sections, paragraphs, figures, tables, equations, and references.
---

# Chinese Mechanical Paper Workflow

## Core Rule

Treat the user's latest manuscript as the source of truth. When a dissertation, template, reference paper, or literature folder is also provided, use those materials to support the current manuscript rather than rebuilding from older drafts.

## Layered Workflow

1. Establish the paper kernel: research object, engineering problem, method contribution, validation path, and conclusion claim.
2. Map dissertation material to a journal-paper structure. Preserve the dissertation's core innovation; condense background and routine CAM/software operation.
3. Build a problem-solving chain: problem limitation -> method design -> algorithm implementation -> error/efficiency analysis -> process or experiment verification.
4. Compare against local reference papers only for format, argument density, terminology, and evidence style. Do not import unrelated conclusions.
5. Polish from whole to part: title/abstract first, then section logic, then paragraph order, then sentence-level language.
6. Verify publication elements last: equations, citations, figures, tables, captions, references, author information, and render layout.

## Mechanical Engineering Emphasis

Prefer algorithm, geometry, machining mechanism, error source, process constraint, and experimental verification. Do not let CAM operation, software screenshots, or tool-interface description become the paper's main contribution.

For screw-rotor/form-grinding manuscripts, keep the innovation focused on:

- three-dimensional discrete geometry rather than planar derivative-only derivation;
- slicing, intersection, nearest-point search, AABB or topology-based acceleration;
- error decomposition and explainability;
- installation-parameter feasibility and non-interference verification;
- NC simulation and actual grinding or inspection evidence.

## Review Loop

Before making edits, identify the current bottleneck:

- **Structure**: sections do not answer a coherent research question.
- **Logic**: method steps are present but not causally connected.
- **Evidence**: claims lack data, equations, figures, tables, or comparison.
- **Language**: wording is generic, repetitive, or too AI-like.
- **Format**: Word layout, equations, references, citations, figures, and tables violate journal norms.

Use `references/paper_layers.md` when a full manuscript pass is needed.

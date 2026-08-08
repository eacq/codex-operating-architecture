# Nature Scientific Figure Workflow

Status: source-grounded adaptation.

Source: `Yuan1z0825/nature-skills`, `nature-figure`, commit
`91862221b39f7ca16d52ae0e1e9cb6c2bb31a96b`.

## Local interpretation

The useful unit is not a separate top-level skill. It is a scientific-figure
contract inside the existing `codex-image-workflow` owner, specifically the
`figure-optimization` subskill.

The transferable method is:

1. Establish the scientific claim before choosing a template.
2. Map every panel to a distinct evidence role.
3. Choose an archetype: quantitative grid, schematic-led composite, image plate
   plus quantification, or asymmetric mixed-modality figure.
4. Keep Python/R plotting backend decisions explicit and exclusive.
5. Treat AI-generated schematics as conceptual drafts only.
6. Verify statistics, source data, image integrity, editable vector text,
   dimensions, and export formats before delivery.
7. Preserve the upstream router idea locally: load the small contract first,
   resolve the route/backend, then load deeper route-specific guidance only
   when the deliverable needs it.
8. Ask once rather than guessing when backend choice affects the result and no
   project/user-scoped preference exists.

## Agent use

The Global Experience Agent should route manuscript figure requests to
`codex-image-workflow` and then to
`codex-image-workflow-figure-optimization`. The Agent should retrieve the
scientific figure contract before plotting, rewriting plotting code, auditing a
multi-panel figure, or generating a graphical abstract prompt.

## Boundaries

- Do not use generative image models to recreate quantitative figures.
- Do not silently switch from a selected Python/R backend to another renderer.
- Do not hide excluded data, missing values, or replicate definitions.
- Do not claim journal readiness without source and rendered-output QA.
- Do not store a learned plotting backend as a global default for every user or
  project; scope it to the project or authorized Agent memory.

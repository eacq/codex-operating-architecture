# Draw.io Skill Integration Contract

`drawio-skill` is a managed subskill of `codex-image-workflow`, not an independent Global Experience Agent entrypoint. Use it when the image workflow selects an editable, high-fidelity diagram rather than Mermaid, a generic SVG, or a raster asset.

## Runtime

Run `scripts/Resolve-DrawioRuntime.ps1` before export. Host paths are private configuration in `%USERPROFILE%\.codex\private-skill-config\drawio-skill.json`, created from `config/drawio-skill-runtime.template.json`; never commit host paths, user style presets, raw source data, credentials, or diagrams to the shared skill.

On Windows use `Start-Process -Wait` for draw.io export and verify the requested output path afterwards. The desktop application can return control before the export child has flushed its artifact. Use `scripts/Test-DrawioSkill.ps1` as the readiness proof.

## Agent and safety boundary

- The Global Experience Agent routes diagram tasks through `codex-image-workflow`; this subskill cannot mutate Agent structure, Git state, releases, credentials, or external accounts.
- Treat supplied files as the only diagram source by default. Live Terraform, Docker, Kubernetes, cloud, Git-history, CI/PR, browser-opening, or external-network operations require their normal owner gate and explicit task authority.
- Keep `.drawio` source authoritative. Exported PNG/SVG/PDF/JPG and HTML/PPTX conversions are derived artifacts that require structural lint and delivery-size inspection.
- Store task outputs in the target project or its approved runtime work surface. The skill directory and `%USERPROFILE%\.drawio-skill\styles` are not task-output locations.

## Portable setup

Install draw.io and Graphviz through the OS package manager or an approved installer. Copy the template to the private configuration path only when automatic discovery cannot resolve the executables. `python-pptx` is already available in the project runtime for optional PPTX conversion; no credentials are needed.

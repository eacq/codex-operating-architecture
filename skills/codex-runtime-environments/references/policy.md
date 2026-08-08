# Runtime Environment Policy

## Ownership

- `$ARCHITECTURE_ROOT\runtime-environments\base\environment.yml`: minimal reproducible base definition.
- `$ARCHITECTURE_ROOT\runtime-environments\usage-ledger.json`: cross-project metadata and promotion evidence.
- `$ARCHITECTURE_ROOT\runtime-environments\tool-profiles.json`: optional dependency profiles for recurring script workflows such as Office, PDF, and image processing.
- `<project>\.codex\runtime`: project manifest, dependency declarations, lock snapshot, and launchers cloned from the minimal base before project-only additions.
- `<project>\.codex\runtime\env`: physical project environment; always ignored by Git.

## Promotion gate

A dependency becomes a base candidate only when the ledger shows at least three successful uses across at least two distinct project roots. Promotion remains a reviewed change: verify license, Python compatibility, dependency conflicts, size, security, and whether the package is genuinely cross-project. Failed uses and one-project repetition never qualify.

## Shell contract

PowerShell and CMD launchers must resolve paths relative to their own project, call the project interpreter directly, preserve arguments, and fail clearly when the environment is missing. Activation is optional; deterministic interpreter paths are authoritative.

Child Python processes that exchange multilingual text or JSON set `PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`, and `PYTHONNOUSERSITE=1` for the child only, then restore the parent environment. Repository data and Agent-state text is strict UTF-8 without BOM. On Windows PowerShell 5.1, do not use `Set-Content`, `Add-Content`, or `Out-File -Encoding UTF8` for durable data artifacts because those commands emit a BOM; use `.NET` UTF-8 APIs with `UTF8Encoding(false)`. PowerShell source is a separate compatibility surface: keep it ASCII when practical, and require UTF-8 BOM for `.ps1` or `.psm1` files that contain non-ASCII characters.

## File processing scripts

Use tool profiles to record intent before installing document-processing packages. The default Office/media profile covers `python-docx`, `python-pptx`, `pypdf`, and `Pillow`; advanced PDF layout work may add `PyMuPDF`; mixed-format Markdown conversion may add `markitdown` or `docling` only when the project really needs that depth. Scaffolded file tools must import dependencies lazily so a project can probe missing capability without failing every command.

Read [file-tool-profiles.md](file-tool-profiles.md) when changing profile contents or adding document-processing packages.

## Secret input

Project scripts may store local keys through a hidden PowerShell prompt and Windows DPAPI using `Read-Host -AsSecureString` and `ConvertFrom-SecureString`. Commit only the helper scripts and metadata patterns. Never commit generated `*.dpapi`, package-index credentials, plaintext secrets, prompts containing secrets, or decrypted command output.

## Recording

Store package name, normalized project root, requirement, purpose, outcome, timestamp, and verification command. Never store package-index credentials, environment variables, prompts, or command output containing secrets.

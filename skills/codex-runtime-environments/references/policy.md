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

## File processing scripts

Use tool profiles to record intent before installing document-processing packages. The default Office/media profile covers `python-docx`, `python-pptx`, `pypdf`, and `Pillow`; advanced PDF layout work may add `PyMuPDF`; mixed-format Markdown conversion may add `markitdown` or `docling` only when the project really needs that depth. Scaffolded file tools must import dependencies lazily so a project can probe missing capability without failing every command.

Read [file-tool-profiles.md](file-tool-profiles.md) when changing profile contents or adding document-processing packages.

## Secret input

Project scripts may store local keys through a hidden PowerShell prompt and Windows DPAPI using `Read-Host -AsSecureString` and `ConvertFrom-SecureString`. Commit only the helper scripts and metadata patterns. Never commit generated `*.dpapi`, package-index credentials, plaintext secrets, prompts containing secrets, or decrypted command output.

## Recording

Store package name, normalized project root, requirement, purpose, outcome, timestamp, and verification command. Never store package-index credentials, environment variables, prompts, or command output containing secrets.

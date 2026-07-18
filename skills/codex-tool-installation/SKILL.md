---
name: codex-tool-installation
description: Install, update, configure, and verify Codex skills, plugins, command-line tools, software, and runtime dependencies using the machine's required configured package and installation roots. Use when the user asks to install a named tool or skill, repair or upgrade an installation, configure PATH, inspect dependencies, enforce $SOFTWARE_ARCHIVE_ROOT and $SOFTWARE_INSTALL_ROOT placement, or ensure future Codex tasks can actually run a workflow.
---

# Codex Tool Installation

1. Distinguish ordinary skill/config file handling from external software or system changes. Before an install, upgrade, or reconfiguration prompted by a newly detected external release, report the item, source, scope, paths, impact, and rollback boundary, then obtain explicit user authorization.
2. Check existing installations first; preserve working versions and locations unless change is necessary.
3. Follow a user-selected target after notification; otherwise prefer official sources and repository methods.
4. Keep provider boundaries explicit. For Python, verify the runtime future Codex tasks actually use, including bundled Python.
5. Verify location, imports or help, file structure, and one representative operation. Separate dependency failures from broken skill content.
6. Record non-secret prerequisites, versions, hashes, results, and recovery steps.

## Required Windows paths

Read [references/software-path-policy.md](references/software-path-policy.md) before every external software installation or upgrade.

Archive installers under `$SOFTWARE_ARCHIVE_ROOT\<product>` and install custom-location software under `$SOFTWARE_INSTALL_ROOT\<product>`. Use `install_software.ps1` for winget plans. Report installer-controlled exceptions first; never migrate existing software or user data automatically.

## Example

```powershell
.\scripts\install_software.ps1 -PackageId Test.Tool -ProductName test-tool
```

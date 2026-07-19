# Software Path Policy

## Canonical roots

- Package archive: `$SOFTWARE_ARCHIVE_ROOT`
- Installation root: `$SOFTWARE_INSTALL_ROOT`
- Default package archive when local roots are not configured:
  `$ARCHITECTURE_ROOT\.runtime\installers`
- Default custom installation root when local roots are not configured:
  `$ARCHITECTURE_ROOT\.runtime\software`
- Disposable workspace/cache roots:
  `$ARCHITECTURE_ROOT\.runtime\tmp`, `.runtime\work`, and `.runtime\cache`
- Machine-readable policy: `$ARCHITECTURE_ROOT\config\software-install-policy.json`

## Workflow

1. Normalize a human-readable product folder name without losing meaningful product identity.
2. Inspect existing installations and preserve an existing configured install target during upgrades.
3. Plan `$SOFTWARE_ARCHIVE_ROOT\<product>` and `$SOFTWARE_INSTALL_ROOT\<product>`.
4. Notify the user of source, version, package path, install path, and system impact.
5. Download and retain the installer in the package archive.
6. Install with the explicit target directory.
7. Verify an executable or registered `InstallLocation` resolves under the intended target.
8. Write a redacted installation record under `$SOFTWARE_ARCHIVE_ROOT\_records`.
9. For temporary downloads, extracted installers, validation clones, or package-manager staging that Codex controls, resolve the path through `scripts\Resolve-CodexRunRoot.ps1` and clean it after verification. If the installer or package manager writes outside these roots, report the exact exception before treating the installation as policy-compliant.

## Exceptions

Do not silently accept another location. Report before installation when Store/UWP packaging, WindowsApps application packages, drivers, Windows components, or an installer without custom-location support controls placement. Do not move Store/UWP or WindowsApps application directories after installation; treat them as installer-controlled external application evidence. Package-manager caches may exist temporarily elsewhere only when the tool controls them; a retained copy of the installer must exist under the package archive and the external cache must be reported with a cleanup or retention decision.

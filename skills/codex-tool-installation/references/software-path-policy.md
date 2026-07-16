# Software Path Policy

## Canonical roots

- Package archive: `$SOFTWARE_ARCHIVE_ROOT`
- Installation root: `$SOFTWARE_INSTALL_ROOT`
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

## Exceptions

Do not silently accept another location. Report before installation when Store/UWP packaging, drivers, Windows components, or an installer without custom-location support controls placement. Package-manager caches may exist temporarily elsewhere, but a retained copy of the installer must exist under the package archive.

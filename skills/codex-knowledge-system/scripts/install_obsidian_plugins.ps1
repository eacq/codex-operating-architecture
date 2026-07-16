param([string]$Vault = $(Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'knowledge-vault'))

$ErrorActionPreference = 'Stop'
$plugins = @(
    @{ Id = 'obsidian-git'; Base = 'https://github.com/Vinzent03/obsidian-git/releases/download/2.38.6'; Files = @('main.js', 'manifest.json', 'styles.css') },
    @{ Id = 'dataview'; Base = 'https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.70'; Files = @('main.js', 'manifest.json', 'styles.css') },
    @{ Id = 'omnisearch'; Base = 'https://github.com/scambier/obsidian-omnisearch/releases/download/1.29.3'; Files = @('main.js', 'manifest.json', 'styles.css') }
)

foreach ($plugin in $plugins) {
    $target = Join-Path $Vault ".obsidian\plugins\$($plugin.Id)"
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    foreach ($file in $plugin.Files) {
        Invoke-WebRequest -Uri "$($plugin.Base)/$file" -OutFile (Join-Path $target $file)
    }
    Write-Host "Installed $($plugin.Id)"
}

$manifest = Get-Content -LiteralPath (Join-Path $Vault '.obsidian\plugin-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($plugin in $plugins) {
    foreach ($file in $plugin.Files) {
        $path = Join-Path $Vault ".obsidian\plugins\$($plugin.Id)\$file"
        $expected = $manifest.($plugin.Id).sha256.$file
        $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($actual -ne $expected) { throw "Hash mismatch: $($plugin.Id)/$file" }
    }
}
Write-Host 'All plugin hashes verified.'

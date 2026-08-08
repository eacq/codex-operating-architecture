param([switch]$Apply)

$ErrorActionPreference = 'Stop'
$codexHome = Join-Path $env:USERPROFILE '.codex'
$statePath = Join-Path $codexHome '.codex-global-state.json'
$backupDir = Join-Path $codexHome 'backups'

if (-not (Test-Path -LiteralPath $statePath)) {
    throw "Missing Codex desktop state: $statePath"
}

$nodeScript = @'
const fs = require('fs');
const path = process.argv[1];
const apply = process.argv[2] === 'apply';
const backupPath = process.argv[3];
const readJson = filePath => JSON.parse(fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, ''));
const state = readJson(path);
const atom = state['electron-persisted-atom-state'];
if (!atom || typeof atom !== 'object' || Array.isArray(atom)) {
  throw new Error('Missing electron-persisted-atom-state');
}
let changed = false;
const targetSidebarWidth = 276;
if (atom['sidebar-width'] !== targetSidebarWidth) {
  atom['sidebar-width'] = targetSidebarWidth;
  changed = true;
}
const sections = atom['sidebar-collapsed-sections-v1'];
const expandedSections = { chats: false, cloud: false, pinned: false, threads: false };
if (!sections || typeof sections !== 'object' || Array.isArray(sections) ||
    Object.entries(expandedSections).some(([key, value]) => sections[key] !== value)) {
  atom['sidebar-collapsed-sections-v1'] = {
    ...(sections && typeof sections === 'object' && !Array.isArray(sections) ? sections : {}),
    ...expandedSections,
  };
  changed = true;
}
const preferences = atom['flat-project-sidebar-preferences-v1'];
const targetPreferences = { chatSortMode: 'priority', initialized: true, mode: 'project', projectSortMode: 'priority' };
if (!preferences || typeof preferences !== 'object' || Array.isArray(preferences) ||
    Object.entries(targetPreferences).some(([key, value]) => preferences[key] !== value)) {
  atom['flat-project-sidebar-preferences-v1'] = {
    ...(preferences && typeof preferences === 'object' && !Array.isArray(preferences) ? preferences : {}),
    ...targetPreferences,
  };
  changed = true;
}
if (apply && changed) {
  fs.copyFileSync(path, backupPath);
  const temporaryPath = `${path}.sidebar-repair.tmp`;
  fs.writeFileSync(temporaryPath, JSON.stringify(state), 'utf8');
  readJson(temporaryPath);
  fs.renameSync(temporaryPath, path);
}
console.log(JSON.stringify({
  valid: true,
  changed,
  applied: apply && changed,
  sidebarWidth: atom['sidebar-width'],
  sectionsExpanded: Object.entries(expandedSections).every(([key, value]) => atom['sidebar-collapsed-sections-v1'][key] === value),
  preferencesNormalized: Object.entries(targetPreferences).every(([key, value]) => atom['flat-project-sidebar-preferences-v1'][key] === value),
}));
'@

$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) { throw 'Node.js is required to validate Codex desktop state.' }

if ($Apply) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
}

# This tool deliberately touches only the three sidebar preference fields. It
# never reads or writes auth.json, config.toml, session indexes, or SQLite data.
$backupPath = if ($Apply) { Join-Path $backupDir ".codex-global-state.sidebar.$timestamp.bak" } else { '' }
& $nodePath.Source -e $nodeScript $statePath $(if ($Apply) { 'apply' } else { 'check' }) $backupPath

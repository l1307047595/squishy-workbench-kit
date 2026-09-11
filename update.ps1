<#
update.ps1 - pull the latest kit and sync it into the local workbench

What it does
  1. git pull --ff-only in the repo (skills are junctions, so they update the moment the pull lands)
  2. re-copies rules\*.md into the workbench root and scripts\*.py into workbench\scripts
  3. prints the head commit and any local dirt

Run it manually, or let the scheduled task (installed by install.ps1) run it every N minutes.

NOTE: this file is intentionally ASCII-only (Windows PowerShell 5.1 mis-decodes BOM-less UTF-8).
#>

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CfgPath = Join-Path $env:USERPROFILE ".workbuddy\squishy-workbench.json"

function Say  ($m) { Write-Host "[upd] $m" }
function Warn ($m) { Write-Host "[upd][warn] $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "[upd][fail] $m" -ForegroundColor Red; exit 1 }

if (-not (Test-Path $CfgPath)) { Fail "not installed yet - run install.ps1 first (missing $CfgPath)" }
$cfg = Get-Content -Path $CfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$wb = $cfg.workbench_dir
if (-not $wb -or -not (Test-Path $wb)) { Fail "workbench_dir from config is invalid: '$wb'" }

Say "repo      = $RepoDir"
Say "workbench = $wb"

# ---------------------------------------------------------------- 1. pull
if (-not (Test-Path (Join-Path $RepoDir ".git"))) { Fail "'$RepoDir' is not a git repo - re-clone it" }

$remote = ((& git -C $RepoDir remote) 2>$null) -join ""
if (-not $remote) {
    Warn "no git remote configured - skipping pull (files only)"
    $before = "local"
    $after  = "local"
} else {
    $before = (& git -C $RepoDir rev-parse --short HEAD) 2>$null
    & git -C $RepoDir pull --ff-only
    if ($LASTEXITCODE -ne 0) { Fail "git pull failed (code $LASTEXITCODE) - check network / remote / local edits" }
    $after = (& git -C $RepoDir rev-parse --short HEAD) 2>$null
    if ($before -eq $after) { Say "already up to date ($after)" } else { Say "updated: $before -> $after" }
}

# ---------------------------------------------------------------- 2. sync files
$nRules = 0
$rulesSrc = Join-Path $RepoDir "rules"
if (Test-Path $rulesSrc) {
    Copy-Item (Join-Path $rulesSrc "*.md") $wb -Force
    $nRules = @(Get-ChildItem $rulesSrc -Filter "*.md").Count
}
Say "rules   synced -> $nRules file(s)"

$nScripts = 0
$scriptsSrc = Join-Path $RepoDir "scripts"
if (Test-Path $scriptsSrc) {
    $scriptsDst = Join-Path $wb "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Copy-Item (Join-Path $scriptsSrc "*.py") $scriptsDst -Force
    $nScripts = @(Get-ChildItem $scriptsSrc -Filter "*.py").Count
}
Say "scripts synced -> $nScripts file(s)"

# ---------------------------------------------------------------- 3. report
Write-Host ""
& git -C $RepoDir log -1 --date=short --pretty=format:"head: %h  %ad  %s"
Write-Host ""
$dirty = (& git -C $RepoDir status --porcelain) 2>$null
if ($dirty) { Warn "repo has local changes - do not edit files inside the repo, they will block future pulls" }

Say "done. skills are live (junction); rules/scripts refreshed."

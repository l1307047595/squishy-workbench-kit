<#
update.ps1 - pull the latest kit and sync ONLY the shared files into the local workbench

Scope (this is the whole point of the script)
  SYNCED (shared, overwritten):
      rules\*.md    scripts\*.py    AGENTS.md
  NEVER TOUCHED (personal - each person keeps their own):
      memory\                  your daily logs / personal memory
      STATE.md                 your own order board
      ref\ prompts\ outputs\   your own assets and products
      config\api.json          your own key
  Before overwriting any synced file whose local copy differs, the local copy is backed up to
  %USERPROFILE%\.workbuddy\squishy-workbench-local-backup\<timestamp>\
  so a personal edit inside a shared file is never silently destroyed.

Run it manually, or let the scheduled task (installed by install.ps1) run it every N minutes.

NOTE: this file is intentionally ASCII-only (Windows PowerShell 5.1 mis-decodes BOM-less UTF-8).
#>

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CfgPath = Join-Path $env:USERPROFILE ".workbuddy\squishy-workbench.json"
$script:backupRoot = $null

function Say  ($m) { Write-Host "[upd] $m" }
function Warn ($m) { Write-Host "[upd][warn] $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "[upd][fail] $m" -ForegroundColor Red; exit 1 }

function Backup-IfChanged ($srcFile, $dstFile) {
    if (-not (Test-Path $dstFile)) { return }
    $a = (Get-FileHash -LiteralPath $srcFile -Algorithm SHA256).Hash
    $b = (Get-FileHash -LiteralPath $dstFile -Algorithm SHA256).Hash
    if ($a -ne $b) {
        if (-not $script:backupRoot) {
            $script:backupRoot = Join-Path $env:USERPROFILE (".workbuddy\squishy-workbench-local-backup\" + (Get-Date -Format "yyyyMMdd-HHmmss"))
            New-Item -ItemType Directory -Path $script:backupRoot -Force | Out-Null
        }
        $dest = Join-Path $script:backupRoot (Split-Path -Leaf $dstFile)
        Copy-Item -LiteralPath $dstFile -Destination $dest -Force
        Warn ("local copy backed up before overwrite -> " + $dest)
    }
}

if (-not (Test-Path $CfgPath)) { Fail "not installed yet - run install.ps1 first (missing $CfgPath)" }
$cfg = Get-Content -Path $CfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$wb = $cfg.workbench_dir
if (-not $wb -or -not (Test-Path $wb)) { Fail "workbench_dir from config is invalid: '$wb'" }

Say "repo      = $RepoDir"
Say "workbench = $wb"

# ---------------------------------------------------------------- 1. pull
if (-not (Test-Path (Join-Path $RepoDir ".git"))) { Fail "'$RepoDir' is not a git repo - re-clone it" }

$remote = ((& git -C $RepoDir remote) 2>$null) -join ""
$pullOk = $true
if (-not $remote) {
    Warn "no git remote configured - skipping pull (files only)"
} else {
    $before = (& git -C $RepoDir rev-parse --short HEAD) 2>$null
    & git -C $RepoDir pull --ff-only
    if ($LASTEXITCODE -ne 0) {
        $pullOk = $false
        Warn "git pull FAILED (code $LASTEXITCODE) - network or credential problem."
        Warn "Continuing with the LOCAL repo content, so synced files may be STALE."
        Warn "Fix it by running manually:  git -C `"$RepoDir`" pull"
    } else {
        $after = (& git -C $RepoDir rev-parse --short HEAD) 2>$null
        if ($before -eq $after) { Say "already up to date ($after)" } else { Say "updated: $before -> $after" }
    }
}

# ---------------------------------------------------------------- 2. sync shared files only
$nRules = 0
$rulesSrc = Join-Path $RepoDir "rules"
if (Test-Path $rulesSrc) {
    Get-ChildItem $rulesSrc -Filter "*.md" -File | ForEach-Object {
        $dst = Join-Path $wb $_.Name
        Backup-IfChanged $_.FullName $dst
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
        $nRules++
    }
}
Say "rules   synced -> $nRules file(s)"

$nScripts = 0
$scriptsSrc = Join-Path $RepoDir "scripts"
if (Test-Path $scriptsSrc) {
    $scriptsDst = Join-Path $wb "scripts"
    if (-not (Test-Path $scriptsDst)) { New-Item -ItemType Directory -Path $scriptsDst -Force | Out-Null }
    Get-ChildItem $scriptsSrc -Filter "*.py" -File | ForEach-Object {
        $dst = Join-Path $scriptsDst $_.Name
        Backup-IfChanged $_.FullName $dst
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
        $nScripts++
    }
}
Say "scripts synced -> $nScripts file(s)"

$agentsSrc = Join-Path $RepoDir "AGENTS.md"
if (Test-Path $agentsSrc) {
    $dst = Join-Path $wb "AGENTS.md"
    Backup-IfChanged $agentsSrc $dst
    Copy-Item -LiteralPath $agentsSrc -Destination $dst -Force
    Say "AGENTS.md synced"
}

# STATE.md is personal: seed from template only on first run, never overwrite afterwards
$stateDst = Join-Path $wb "STATE.md"
if (-not (Test-Path $stateDst) -and (Test-Path (Join-Path $RepoDir "STATE.template.md"))) {
    Copy-Item (Join-Path $RepoDir "STATE.template.md") $stateDst
    Say "STATE.md created from template (first run only)"
}

# ---------------------------------------------------------------- 3. report
Write-Host ""
& git -C $RepoDir log -1 --date=short --pretty=format:"head: %h  %ad  %s"
Write-Host ""
$dirty = (& git -C $RepoDir status --porcelain) 2>$null
if ($dirty) { Warn "repo has local changes - do not edit files inside the repo, they will block future pulls" }

Say "personal files untouched: memory\  STATE.md  ref\  prompts\  outputs\  config\api.json"
if ($script:backupRoot) { Say "backups written this run: $script:backupRoot" }
if (-not $pullOk) { Warn "REMINDER: this run used the local repo copy (pull failed) - synced files may be stale." }
Say "done. skills are live (junction); shared rules/scripts/AGENTS refreshed."

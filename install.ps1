<#
install.ps1 - one-shot setup for squishy-workbench-kit (Windows, PowerShell 5.1 compatible)

What it does
  1. creates the local workbench folder tree
  2. seeds rules PERSONALLY: identity.md with content, feedback.md / library.md empty
     (seeded once only - later updates NEVER overwrite them)
  3. copies scripts\*.py into the workbench (shared, updated by update.ps1)
  4. creates workbench config\api.json from the template (if missing)
  5. creates directory junctions under %USERPROFILE%\.workbuddy\skills\ pointing at this repo's skills\*
     -> after this, `git pull` updates the skills instantly, nothing to reinstall
  6. writes %USERPROFILE%\.workbuddy\squishy-workbench.json (machine-local path map)
  7. optionally registers a scheduled task that auto-runs update.ps1

Usage
  cd D:\skills-repo
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -WorkbenchDir "E:\my-workbench" -ScheduleMinutes 15
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -ScheduleMinutes 0    # no scheduled task

NOTE: this file is intentionally ASCII-only.
Windows PowerShell 5.1 mis-decodes BOM-less UTF-8, so non-ASCII text here would show as garbage.
#>

param(
    [string]$WorkbenchDir = "D:\squishy-workbench",
    [int]$ScheduleMinutes = 30
)

$ErrorActionPreference = "Stop"

$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillHome = Join-Path $env:USERPROFILE ".workbuddy\skills"
$CfgPath   = Join-Path $env:USERPROFILE ".workbuddy\squishy-workbench.json"
$TaskName  = "SquishyWorkbenchUpdate"

function Say  ($m) { Write-Host "[kit] $m" }
function Warn ($m) { Write-Host "[kit][warn] $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "[kit][fail] $m" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------- 0. sanity
Say "repo      = $RepoDir"
Say "workbench = $WorkbenchDir"

foreach ($d in @("skills", "rules", "scripts", "config")) {
    if (-not (Test-Path (Join-Path $RepoDir $d))) { Fail "repo layout broken: missing '$d' under $RepoDir" }
}
$skillDirs = @(Get-ChildItem (Join-Path $RepoDir "skills") -Directory)
if ($skillDirs.Count -eq 0) { Fail "no skill folders found under $(Join-Path $RepoDir 'skills')" }

# ---------------------------------------------------------------- 1. workbench tree
foreach ($d in @("ref", "prompts", "outputs", "config", "scripts", "memory")) {
    $p = Join-Path $WorkbenchDir $d
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null; Say "mkdir  $p" }
}

# ---------------------------------------------------------------- 2. rules (PERSONAL: seed once, never overwrite)
# identity.md ships WITH content; feedback.md / library.md start EMPTY (each person's own log).
$rulesSrc = Join-Path $RepoDir "rules"
$idDst = Join-Path $WorkbenchDir "identity.md"
if (-not (Test-Path $idDst)) {
    Copy-Item (Join-Path $rulesSrc "identity.md") $idDst
    Say "identity.md seeded (with content)"
} else {
    Say "identity.md kept (personal, not overwritten)"
}
foreach ($n in @("feedback.md", "library.md")) {
    $p = Join-Path $WorkbenchDir $n
    if (-not (Test-Path $p)) {
        Set-Content -LiteralPath $p -Value "" -Encoding UTF8
        Say "$n created EMPTY (your own rule/case log, fill it as you work)"
    } else {
        Say "$n kept (personal, not overwritten)"
    }
}

Copy-Item (Join-Path $RepoDir "scripts\*.py") (Join-Path $WorkbenchDir "scripts") -Force
Say ("scripts synced -> " + (Get-ChildItem (Join-Path $RepoDir "scripts") -Filter "*.py").Count + " file(s)")

if (Test-Path (Join-Path $RepoDir "AGENTS.md")) {
    Copy-Item (Join-Path $RepoDir "AGENTS.md") (Join-Path $WorkbenchDir "AGENTS.md") -Force
    Say "AGENTS.md copied (agent entry point)"
}
$stateDst = Join-Path $WorkbenchDir "STATE.md"
if (-not (Test-Path $stateDst)) {
    Copy-Item (Join-Path $RepoDir "STATE.template.md") $stateDst
    Say "STATE.md created from template (order status board)"
} else {
    Say "STATE.md kept (not overwritten)"
}

# ---------------------------------------------------------------- 3. api config
$api = Join-Path $WorkbenchDir "config\api.json"
if (-not (Test-Path $api)) {
    Copy-Item (Join-Path $RepoDir "config\api.example.json") $api
    Warn "created config template: $api"
    Warn "FILL IN YOUR OWN api_key THERE BEFORE GENERATING ANY IMAGE"
} else {
    Say "config kept (not overwritten): $api"
}

# ---------------------------------------------------------------- 4. skill junctions
if (-not (Test-Path $SkillHome)) { New-Item -ItemType Directory -Path $SkillHome -Force | Out-Null }
foreach ($sd in $skillDirs) {
    $link = Join-Path $SkillHome $sd.Name
    if (Test-Path $link) {
        $item = Get-Item $link -Force
        if ($item.LinkType) {
            Say "link exists, refreshing: $($sd.Name)"
            $item.Delete()
        } else {
            $bak = $link + ".bak-" + (Get-Date -Format "yyyyMMddHHmmss")
            Warn "real folder found (not a link), renamed to $bak"
            Rename-Item -LiteralPath $link -NewName (Split-Path -Leaf $bak)
        }
    }
    New-Item -ItemType Junction -Path $link -Target $sd.FullName | Out-Null
    Say "junction  $link  ->  $($sd.FullName)"
}

# ---------------------------------------------------------------- 5. machine config
$parent = Split-Path -Parent $CfgPath
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$cfg = [ordered]@{
    workbench_dir = (Get-Item -LiteralPath $WorkbenchDir).FullName
    skills_repo   = (Get-Item -LiteralPath $RepoDir).FullName
    update_script = (Join-Path (Get-Item -LiteralPath $RepoDir).FullName "update.ps1")
    updated_at    = (Get-Date).ToString("s")
}
$cfg | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $CfgPath
Say "wrote  $CfgPath"

# ---------------------------------------------------------------- 6. scheduled task
if ($ScheduleMinutes -gt 0) {
    $psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $argLine = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $RepoDir 'update.ps1')`""
    try {
        $action  = New-ScheduledTaskAction -Execute $psExe -Argument $argLine
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) `
                    -RepetitionInterval (New-TimeSpan -Minutes $ScheduleMinutes)
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Force `
                    -Description "squishy-workbench auto update (git pull + sync rules)" | Out-Null
        Say "scheduled task '$TaskName' registered, every $ScheduleMinutes minute(s)"
    } catch {
        Warn "could not register scheduled task (needs admin)."
        Warn "Run update.ps1 by hand instead. Elevated alternative:"
        $sch = 'schtasks /create /tn ' + $TaskName + ' /sc minute /mo ' + $ScheduleMinutes + ' /tr "' + $psExe + ' ' + $argLine + '" /f'
        Warn ("  " + $sch)
    }
} else {
    Say "scheduled task skipped (-ScheduleMinutes 0)"
}

# ---------------------------------------------------------------- 7. next steps
Write-Host ""
Say "DONE. next steps:"
Say "  1. edit $api  -> put YOUR api_key in"
Say "  2. cd `"$WorkbenchDir`""
Say "  3. python scripts\generate.py --check        (zero-cost health check)"
Say "  4. restart WorkBuddy, then just ask it to write squishy prompts"
Write-Host ""
Say "update anytime:  powershell -NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $RepoDir 'update.ps1')`""

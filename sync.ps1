<#
.synopsis
    Sync Trae skills & mcp.json between this repo and local Trae.
.parameter Mode
    pull = apply repo configs to local Trae (use on a new computer)
    push = backup local configs into repo and push to remote
    auto = pull first, then push (default)
#>

param(
    [ValidateSet("pull", "push", "auto")]
    [string]$Mode = "auto"
)

$ErrorActionPreference = "Continue"

$RepoDir     = $PSScriptRoot
$SkillsRepo  = Join-Path $RepoDir "skills"
$McpRepo     = Join-Path $RepoDir "mcp.json"
$SkillsLocal = Join-Path $env:USERPROFILE ".trae\skills"
$McpLocal    = Join-Path $env:APPDATA "Trae CN\User\mcp.json"

Set-Location $RepoDir
git pull --ff-only
if ($LASTEXITCODE -ne 0) {
    Write-Warning "git pull failed. Check network/SSH and retry."
    exit 1
}

if ($Mode -in @("pull", "auto")) {
    Write-Host "[1/2] Copy skills -> ~/.trae\skills"
    robocopy $SkillsRepo $SkillsLocal /E /NFL /NDL /NJH /NJS | Out-Null
    $LASTEXITCODE = 0
    Write-Host "[1/2] Copy mcp.json -> Trae User dir"
    Copy-Item $McpRepo $McpLocal -Force
    Write-Host "Local updated. Restart Trae to take effect."
}

if ($Mode -in @("push", "auto")) {
    Write-Host "[2/2] Collect local configs -> repo"
    robocopy $SkillsLocal $SkillsRepo /E /NFL /NDL /NJH /NJS | Out-Null
    $LASTEXITCODE = 0
    Copy-Item $McpLocal $McpRepo -Force

    git add -A
    $changes = git status --porcelain
    if ($changes) {
        git commit -m "sync: local config backup $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        git push
        if ($LASTEXITCODE -eq 0) { Write-Host "Pushed to remote." }
    } else {
        Write-Host "No changes, skip commit."
    }
}

Write-Host "Sync done."

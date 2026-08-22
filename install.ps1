# =============================================================================
# install.ps1 — Android Guidelines Skill Installer (Windows)
# =============================================================================
# Creates a directory junction in %USERPROFILE%\.gemini\config\skills\ pointing
# to this repo so that the android-guidelines skill is available globally to
# all AGY projects.
#
# Usage (run in PowerShell from the repo root):
#   .\install.ps1
#
# If you get an execution-policy error, run first:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#
# To uninstall:
#   Remove-Item "$env:USERPROFILE\.gemini\config\skills\android-guidelines"
# =============================================================================

#Requires -Version 5.1

# ── Colors helper ─────────────────────────────────────────────────────────────
function Write-Color {
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::White)
    $prev = [Console]::ForegroundColor
    [Console]::ForegroundColor = $Color
    Write-Host $Text
    [Console]::ForegroundColor = $prev
}

# ── Resolve repo root (directory where this script lives) ─────────────────────
$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SkillName = "android-guidelines"
$SkillsDir = Join-Path $env:USERPROFILE ".gemini\config\skills"
$LinkTarget = Join-Path $SkillsDir $SkillName

Write-Host ""
Write-Color "Android Guidelines Skill — Installer" Cyan
Write-Host "----------------------------------------"
Write-Host "  Repo  : $RepoDir"
Write-Host "  Target: $LinkTarget"
Write-Host ""

# ── Verify SKILL.md exists ────────────────────────────────────────────────────
$SkillFile = Join-Path $RepoDir "SKILL.md"
if (-not (Test-Path $SkillFile)) {
    Write-Color "x  SKILL.md not found in $RepoDir. Aborting." Red
    exit 1
}

# ── Create skills directory if needed ────────────────────────────────────────
if (-not (Test-Path $SkillsDir)) {
    Write-Color ">>  Creating directory: $SkillsDir" Yellow
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

# ── Remove existing junction / symlink at target ──────────────────────────────
if (Test-Path $LinkTarget) {
    $item = Get-Item $LinkTarget -Force
    # ReparsePoint covers both junctions and symlinks
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Color ">>  Removing existing junction/symlink at $LinkTarget" Yellow
        Remove-Item $LinkTarget -Force
    } else {
        Write-Color "x  A real directory already exists at $LinkTarget." Red
        Write-Host   "   Remove it manually and re-run this script."
        exit 1
    }
}

# ── Attempt to create a directory junction ────────────────────────────────────
# Junctions work on same-drive paths without elevated privileges.
$success = $false
try {
    $null = New-Item -ItemType Junction -Path $LinkTarget -Target $RepoDir -ErrorAction Stop
    $success = $true
    Write-Color ">>  Created directory junction." Yellow
} catch {
    Write-Color ">>  Junction creation failed (possibly cross-drive). Falling back to symbolic link..." Yellow
    # Symlinks require Developer Mode or admin on Windows
    try {
        $null = New-Item -ItemType SymbolicLink -Path $LinkTarget -Target $RepoDir -ErrorAction Stop
        $success = $true
        Write-Color ">>  Created symbolic link." Yellow
    } catch {
        Write-Color "x  Could not create junction or symlink: $_" Red
        Write-Host ""
        Write-Host "   FALLBACK: Copying files instead."
        Write-Host "   Note: You will need to re-run this script after every git pull."
        New-Item -ItemType Directory -Path $LinkTarget -Force | Out-Null
        Copy-Item -Path (Join-Path $RepoDir "SKILL.md") -Destination $LinkTarget -Force
        $success = $true
        Write-Color ">>  Files copied to $LinkTarget" Yellow
    }
}

# ── Verify ────────────────────────────────────────────────────────────────────
$verifyPath = Join-Path $LinkTarget "SKILL.md"
if ($success -and (Test-Path $verifyPath)) {
    Write-Host ""
    Write-Color "OK  Skill installed successfully!" Green
    Write-Host ""
    Write-Host "  'android-guidelines' is now available globally in all AGY projects."
    Write-Host "  Run 'git pull' inside the repo to update the skill on this machine."
} else {
    Write-Color "x  Installation failed — SKILL.md not reachable at $verifyPath" Red
    exit 1
}
Write-Host ""

$ErrorActionPreference = "Stop"

function Write-Info($message) {
    Write-Host "-> $message" -ForegroundColor DarkGray
}

function Write-Ok($message) {
    Write-Host $message -ForegroundColor Green
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Green
Write-Host "          JINX INSTALL       " -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""
Write-Host "installing jinx on Windows..." -ForegroundColor DarkGray
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required to auto-install dependencies. Install App Installer from Microsoft Store and rerun this script."
}

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Info "installing ollama via winget..."
    winget install --id Ollama.Ollama --accept-package-agreements --accept-source-agreements
} else {
    Write-Info "ollama already installed"
}

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Info "installing uv via winget..."
    winget install --id Astral-sh.uv --accept-package-agreements --accept-source-agreements

    # Refresh command lookup for current session.
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
} else {
    Write-Info "uv already installed"
}

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    throw "ollama command not found after installation. Restart PowerShell and run install.ps1 again."
}

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw "uv command not found after installation. Restart PowerShell and run install.ps1 again."
}

Write-Host ""
Write-Host "  available models:"
Write-Host "  [1] phi4-mini    - recommended (smart, 2.5GB)"
Write-Host "  [2] llama3.2:3b  - faster, lighter (2GB)"
Write-Host "  [3] mistral      - great balance (4GB)"
Write-Host "  [4] gemma3:1b    - ultralight, less accurate (800MB)"
Write-Host ""
$modelChoice = Read-Host "  choose model [1]"

switch ($modelChoice) {
    "2" { $model = "llama3.2:3b" }
    "3" { $model = "mistral" }
    "4" { $model = "gemma3:1b" }
    default { $model = "phi4-mini" }
}

Write-Info "pulling $model..."
ollama pull $model

Write-Info "installing python dependencies..."
uv sync

Write-Host ""
$defaultProjectsDir = Join-Path $HOME "Personal"
$projectsDir = Read-Host "  projects directory [$defaultProjectsDir]"
if ([string]::IsNullOrWhiteSpace($projectsDir)) {
    $projectsDir = $defaultProjectsDir
}

$editor = Read-Host "  editor [code]"
if ([string]::IsNullOrWhiteSpace($editor)) {
    $editor = "code"
}

$config = [ordered]@{
    projects_dir = $projectsDir
    editor = $editor
    model = $model
    invoke = "jinx"
}
$config | ConvertTo-Json | Set-Content -Path "config.json" -Encoding UTF8
'{"tasks": []}' | Set-Content -Path "tasks.json" -Encoding UTF8

$jinxDir = (Get-Location).Path
$launcherDir = Join-Path $HOME "bin"
$launcherPath = Join-Path $launcherDir "jinx.cmd"

if (-not (Test-Path $launcherDir)) {
    New-Item -Path $launcherDir -ItemType Directory | Out-Null
}

 $launcherScript = @"
@echo off
cd /d "$jinxDir"
uv run jinx.py %*
"@
$launcherScript | Set-Content -Path $launcherPath -Encoding ASCII

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrWhiteSpace($userPath)) {
    $userPath = ""
}

if (($userPath -split ";") -notcontains $launcherDir) {
    $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $launcherDir } else { $userPath.TrimEnd(";") + ";" + $launcherDir }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Info "added $launcherDir to your user PATH"
    Write-Info "open a new terminal to use the jinx command globally"
} else {
    Write-Info "$launcherDir is already in PATH"
}

Write-Host ""
Write-Ok "-> jinx installed successfully"
Write-Host "   type jinx in a new terminal window to start" -ForegroundColor DarkGray
Write-Host ""

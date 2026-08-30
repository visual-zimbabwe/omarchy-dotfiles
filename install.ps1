# Omarchy & Dotfiles Setup for Windows PowerShell
$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Omarchy Setup & Dotfiles (Windows)    " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$TargetDir = "$env:LOCALAPPDATA\omarchy-dotfiles"
$RepoUrl = "https://github.com/visual-zimbabwe/omarchy-dotfiles.git"

# 1. Determine execution context
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$ScriptDir\config") {
    $SrcDir = $ScriptDir
} else {
    if (Test-Path "$TargetDir\.git") {
        Write-Host "--> Updating existing repository at $TargetDir..." -ForegroundColor Yellow
        git -C "$TargetDir" pull
    } else {
        Write-Host "--> Cloning repository to $TargetDir..." -ForegroundColor Green
        git clone "$RepoUrl" "$TargetDir"
    }
    $SrcDir = $TargetDir
}

# 2. Restore cross-platform configurations
$ConfigDir = "$env:USERPROFILE\.config"
if (!(Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

Write-Host "--> Restoring cross-platform configurations (Alacritty, Ghostty, Kitty, Neovim, Starship, Lazygit)..." -ForegroundColor Green

$Apps = @("alacritty", "ghostty", "kitty", "nvim", "btop", "lazygit")
foreach ($app in $Apps) {
    $src = "$SrcDir\config\$app"
    if (Test-Path $src) {
        $dest = "$ConfigDir\$app"
        if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force
    }
}

if (Test-Path "$SrcDir\config\starship.toml") {
    Copy-Item -Path "$SrcDir\config\starship.toml" -Destination $ConfigDir -Force
}

Write-Host "`n✔ Windows dotfiles successfully restored!" -ForegroundColor Green
Write-Host "`nNote on Omarchy Desktop:" -ForegroundColor Yellow
Write-Host "Omarchy is an Arch Linux / Hyprland desktop environment." -ForegroundColor White
Write-Host "To run the complete Omarchy desktop on Windows:" -ForegroundColor White
Write-Host "1. Install WSL2 (Arch Linux / Ubuntu): wsl --install" -ForegroundColor Cyan
Write-Host "2. Inside the Linux terminal, run:" -ForegroundColor White
Write-Host "   bash <(curl -fsSL https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.sh)" -ForegroundColor Cyan

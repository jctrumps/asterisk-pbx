<#
.SYNOPSIS
  Installs Windows-side prerequisites for asterisk-pbx.

.DESCRIPTION
  Installs OpenTofu using winget when missing. Also checks for SSH and WSL.
  Ansible should be installed inside WSL/Linux using scripts/install-prereqs-wsl.sh.

.PARAMETER InstallWSL
  If supplied, runs 'wsl --install -d Ubuntu' when WSL is missing. This may require administrator rights and/or a reboot.
#>

param(
    [switch]$InstallWSL
)

$ErrorActionPreference = "Stop"

function Has-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "== Installing/checking Windows prerequisites ==" -ForegroundColor Cyan

if (-not (Has-Command "winget")) {
    throw "winget was not found. Install 'App Installer' from Microsoft Store, then rerun this script."
}

if (-not (Has-Command "tofu")) {
    Write-Host "Installing OpenTofu with winget..." -ForegroundColor Yellow
    winget install --exact --id OpenTofu.Tofu --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "OpenTofu is already installed." -ForegroundColor Green
    tofu -version
}

if (-not (Has-Command "ssh")) {
    Write-Host "OpenSSH client was not found. Enable the Windows OpenSSH Client optional feature." -ForegroundColor Yellow
} else {
    Write-Host "OpenSSH client is available." -ForegroundColor Green
}

if (-not (Has-Command "wsl")) {
    if ($InstallWSL) {
        Write-Host "Installing WSL Ubuntu. A reboot may be required." -ForegroundColor Yellow
        wsl --install -d Ubuntu
    } else {
        Write-Host "WSL was not found. To install it, rerun with:" -ForegroundColor Yellow
        Write-Host "  .\scripts\install-prereqs.ps1 -InstallWSL"
    }
} else {
    Write-Host "WSL is available." -ForegroundColor Green
    wsl --status
}

Write-Host ""
Write-Host "Next, install/check Ansible inside WSL:" -ForegroundColor Cyan
Write-Host "  wsl bash /mnt/c/projects/asterisk-pbx/scripts/install-prereqs-wsl.sh"
Write-Host ""

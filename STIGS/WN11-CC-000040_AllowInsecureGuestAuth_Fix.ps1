<#
====================================================================
  STIG Remediation Script – WN11-CC-000040
  Control : Insecure logons to an SMB server must be disabled.

  Registry:
    HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation
      AllowInsecureGuestAuth (REG_DWORD) = 0
====================================================================

  
  -------------------
  Created By   : Andre Poyser
  Date Created : 2025-12-02
  Date Tested  : 2025-12-02
  Last Updated : 2025-12-02
  OS Tested    : Windows 11 24H2 - Pro
  Version      : 1.0.0
====================================================================
#>

$Path    = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
$PathRaw = "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
$Name    = "AllowInsecureGuestAuth"
$Value   = 0

Write-Host "=== Fix: WN11-CC-000040 (Disable insecure SMB guest logons) ===" -ForegroundColor Cyan

# Before state
$before = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
Write-Host "Before:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $PathRaw)
Write-Host ("  Exists : {0}" -f ([bool]$before))
Write-Host ("  Value  : {0}" -f ($(if ($before) { $before.$Name } else { '<null>' })))
Write-Host ""

# Ensure key exists
if (-not (Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
}

# Set value
New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null

# After state
$after = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
Write-Host "After:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $PathRaw)
Write-Host ("  Value  : {0}" -f $after.$Name)
Write-Host ""

if ($after.$Name -eq $Value) {
    Write-Host "SUCCESS: AllowInsecureGuestAuth is set to 0 (insecure SMB guest logons disabled)." -ForegroundColor Green
    exit 0
} else {
    Write-Warning "FAIL: Value did not apply correctly."
    exit 1
}

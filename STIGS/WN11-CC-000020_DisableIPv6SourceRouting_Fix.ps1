<#
====================================================================
  STIG Remediation Script – WN11-CC-000020
  Control : IPv6 source routing must be configured to highest protection.

  Registry:
    HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters
      DisableIpSourceRouting (REG_DWORD) = 2
====================================================================

  CREATOR / METADATA
  -------------------
  Created By   : Andre Poyser
  Date Created : 2025-12-02
  Date Tested  : 2025-12-04
  Last Updated : 2025-12-02
  Version      : 1.0.0
====================================================================
#>

$Path    = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$PathRaw = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$Name    = "DisableIpSourceRouting"
$Value   = 2  # 2 = Highest protection, source routing completely disabled

Write-Host "=== Fix: WN11-CC-000020 (IPv6 source routing – Highest protection) ===" -ForegroundColor Cyan

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
    Write-Host "SUCCESS: DisableIpSourceRouting is set to 2 (highest protection)." -ForegroundColor Green
    exit 0
}
else {
    Write-Warning "FAIL: Value did not apply correctly."
    exit 1
}


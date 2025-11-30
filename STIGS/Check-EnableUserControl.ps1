<#
====================================================================
   STIG / Policy Check Script
   Setting: EnableUserControl = 0  
   Control Area: Windows Installer Policy Hardening

   Registry Path:
     HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer
       → EnableUserControl (REG_DWORD) = 0

   Check Logic:
     - Read the value of EnableUserControl under the policy key.
     - PASS if:
         - Value exists AND
         - Value == 0
     - FAIL otherwise.
====================================================================

   -------------------
   Created By   : Andre Poyser
   Date Created : 2025-11-30
   Date Tested  : 2025-11-30
   OS Tested    : Windows 11 24H2-Pro
   Last Updated : 2025-11-30
   Version      : 1.0.0

   NOTES:
   - This script is CHECK-ONLY: it does NOT modify the system.
   - Exit codes:
        0 = COMPLIANT (EnableUserControl = 0)
        1 = NON-COMPLIANT or undetermined
====================================================================
#>

$Path     = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$PathRaw  = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer"
$Value    = "EnableUserControl"
$Expected = 0

Write-Host "=== Policy Check: EnableUserControl (Windows Installer) ===" -ForegroundColor Cyan
Write-Host ("Verifying {0}\{1} = {2} ..." -f $PathRaw, $Value, $Expected) -ForegroundColor Cyan
Write-Host ""

# Read current state
$exists = $false
$current = $null

try {
    $props = Get-ItemProperty -Path $Path -Name $Value -ErrorAction SilentlyContinue
    if ($props) {
        $exists  = $true
        $current = [int]$props.$Value
    }
}
catch {
    # ignore, treat as non-compliant
}

Write-Host "Current state:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $PathRaw)
Write-Host ("  Name   : {0}" -f $Value)
Write-Host ("  Exists : {0}" -f $exists)
Write-Host ("  Value  : {0}" -f ($(if ($current -ne $null) { $current } else { '<null>' })))
Write-Host ""

if ($exists -and $current -eq $Expected) {
    Write-Host "[PASS] EnableUserControl is correctly set to 0." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] EnableUserControl is NOT compliant." -ForegroundColor Red
    Write-Host ("       Expected: {0}\{1} = {2}" -f $PathRaw, $Value, $Expected) -ForegroundColor Red
    exit 1
}

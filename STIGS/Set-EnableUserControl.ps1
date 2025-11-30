<#
====================================================================
   STIG / Policy Automation Script
   Setting: EnableUserControl = 0  
   Control Area: Windows Installer Policy Hardening

   Registry Path:
     HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer
       → EnableUserControl (REG_DWORD) = 0

   Purpose:
     Prevents users from changing installer-related settings that
     affect security posture. Used in hardening and STIG alignment.
====================================================================

   Created By   : Andre Poyser
   Date Created : 2025-11-29
   Date Tested  : 2025-11-30
   Last Updated : 2025-11-29
   Version      : 1.0.0

   NOTES:
   - Run script from an elevated (Administrator) PowerShell window.
   - This script:
        * Ensures the policy registry path exists
        * Sets EnableUserControl = 0
        * Displays before & after config
        * Returns exit code 0 when compliant
====================================================================
#>

$Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$Value = "EnableUserControl"
$Data  = 0

Write-Host "=== Applying Windows Installer Policy Setting ===" -ForegroundColor Cyan

# --- Before State ---
$Before = Get-ItemProperty -Path $Path -Name $Value -ErrorAction SilentlyContinue
Write-Host "Before:" -ForegroundColor Yellow
Write-Host ("  Exists: {0}" -f ($Before -ne $null))
Write-Host ("  Value : {0}" -f ($Before.$Value))
Write-Host ""

# --- Ensure Path Exists ---
if (-not (Test-Path $Path)) {
    New-Item -Path $Path -Force | Out-Null
}

# --- Apply Setting ---
New-ItemProperty -Path $Path -Name $Value -Value $Data -PropertyType DWord -Force | Out-Null

# --- After State ---
$After = Get-ItemProperty -Path $Path -Name $Value
Write-Host "After:" -ForegroundColor Yellow
Write-Host ("  Value : {0}" -f $After.$Value)
Write-Host ""

# --- Compliance Check ---
if ($After.$Value -eq $Data) {
    Write-Host "SUCCESS: EnableUserControl is set to 0 (Policy Applied)." -ForegroundColor Green
    exit 0
}
else {
    Write-Warning "FAIL: Value did not apply correctly."
    exit 1
}

<#
====================================================================
   STIG Remediation Script – WN11-SO-000167
   Control: Remote calls to the Security Account Manager (SAM)
            must be restricted to Administrators.

   Registry Setting:
     HKLM\SYSTEM\CurrentControlSet\Control\Lsa
       RestrictRemoteSAM (REG_SZ) = "O:BAG:BAD:(A;;RC;;;BA)"
====================================================================

  -------------------
   Created By   : Andre Poyser
   Date Created : 2025-11-30
   Date Tested  : 2025-11-30
   Last Updated : 2025-11-30
   Version      : 1.0.0

   NOTES:
   - Run from an elevated PowerShell session.
   - This script:
       * Ensures the LSA key exists
       * Sets RestrictRemoteSAM to the STIG-required SDDL
       * Shows before/after values
       * Exit code: 0 = compliant, 1 = not compliant
====================================================================
#>

$RegPath    = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegPathRaw = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
$Name       = "RestrictRemoteSAM"
$Desired    = 'O:BAG:BAD:(A;;RC;;;BA)'

Write-Host "=== STIG Remediation: WN11-SO-000167 (RestrictRemoteSAM) ===" -ForegroundColor Cyan
Write-Host "Enforcing: Remote SAM calls restricted to Administrators only." -ForegroundColor Cyan
Write-Host ""

# --- Before state ---
$beforeExists = $false
$beforeValue  = $null

try {
    $props = Get-ItemProperty -Path $RegPath -Name $Name -ErrorAction SilentlyContinue
    if ($props) {
        $beforeExists = $true
        $beforeValue  = [string]$props.$Name
    }
}
catch { }

Write-Host "Before:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $RegPathRaw)
Write-Host ("  Name   : {0}" -f $Name)
Write-Host ("  Exists : {0}" -f $beforeExists)
Write-Host ("  Value  : {0}" -f ($(if ($beforeValue) { $beforeValue } else { '<null>' })))
Write-Host ""

# --- Ensure key exists ---
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# --- Apply setting ---
Write-Host "[*] Applying STIG-compliant SDDL to RestrictRemoteSAM..." -ForegroundColor Yellow

try {
    New-ItemProperty -Path $RegPath -Name $Name -Value $Desired -PropertyType String -Force | Out-Null

    $afterProps = Get-ItemProperty -Path $RegPath -Name $Name -ErrorAction Stop
    $afterValue = [string]$afterProps.$Name

    Write-Host ""
    Write-Host "After:" -ForegroundColor Yellow
    Write-Host ("  Path   : {0}" -f $RegPathRaw)
    Write-Host ("  Name   : {0}" -f $Name)
    Write-Host ("  Value  : {0}" -f $afterValue)
    Write-Host ""

    if ($afterValue -eq $Desired) {
        Write-Host "SUCCESS: WN11-SO-000167 is now compliant (RestrictRemoteSAM set to required SDDL)." -ForegroundColor Green
        exit 0
    }
    else {
        Write-Warning ("FAIL: Value does not match expected SDDL.`nExpected: {0}`nActual  : {1}" -f $Desired, $afterValue)
        exit 1
    }
}
catch {
    Write-Error "Failed to configure RestrictRemoteSAM: $($_.Exception.Message)"
    exit 1
}

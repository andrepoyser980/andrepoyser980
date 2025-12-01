<#
====================================================================
   STIG Remediation Script – WN11-SO-000205
   Control: The LanMan authentication level must be set to:
            "Send NTLMv2 response only. Refuse LM & NTLM."

   Policy:
     Computer Configuration →
       Windows Settings →
         Security Settings →
           Local Policies →
             Security Options →
               "Network security: LAN Manager authentication level"

   Registry:
     HKLM\SYSTEM\CurrentControlSet\Control\Lsa
       LmCompatibilityLevel (REG_DWORD) = 5
====================================================================

  -------------------
   Created By   : Andre Poyser
   Date Created : 2025-11-30
   Date Tested  : 2025-11-30
   Last Updated : 2025-11-30
   OS Tested    : Windows 11 24H2-Pro
   Version      : 1.0.0

   NOTES:
   - Run from an elevated PowerShell session.
   - This script:
       * Ensures the Lsa key exists
       * Sets LmCompatibilityLevel = 5
       * Shows before/after values
       * Exit code: 0 = compliant, 1 = not compliant
====================================================================
#>

$RegPath    = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegPathRaw = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
$Name       = "LmCompatibilityLevel"
$Desired    = 5

Write-Host "=== STIG Remediation: WN11-SO-000205 (LAN Manager auth level) ===" -ForegroundColor Cyan
Write-Host 'Enforcing: "Send NTLMv2 response only. Refuse LM & NTLM".' -ForegroundColor Cyan
Write-Host ""

# --- Before state ---
$beforeExists = $false
$beforeValue  = $null

try {
    $props = Get-ItemProperty -Path $RegPath -Name $Name -ErrorAction SilentlyContinue
    if ($props) {
        $beforeExists = $true
        $beforeValue  = [int]$props.$Name
    }
}
catch { }

Write-Host "Before:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $RegPathRaw)
Write-Host ("  Name   : {0}" -f $Name)
Write-Host ("  Exists : {0}" -f $beforeExists)
Write-Host ("  Value  : {0}" -f ($(if ($beforeValue -ne $null) { $beforeValue } else { '<null>' })))
Write-Host ""

# --- Ensure key exists ---
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# --- Apply setting ---
Write-Host "[*] Applying STIG-compliant value (LmCompatibilityLevel = 5)..." -ForegroundColor Yellow

try {
    New-ItemProperty -Path $RegPath -Name $Name -Value $Desired -PropertyType DWord -Force | Out-Null

    $afterProps = Get-ItemProperty -Path $RegPath -Name $Name -ErrorAction Stop
    $afterValue = [int]$afterProps.$Name

    Write-Host ""
    Write-Host "After:" -ForegroundColor Yellow
    Write-Host ("  Path   : {0}" -f $RegPathRaw)
    Write-Host ("  Name   : {0}" -f $Name)
    Write-Host ("  Value  : {0}" -f $afterValue)
    Write-Host ""

    if ($afterValue -eq $Desired) {
        Write-Host "SUCCESS: WN11-SO-000205 is now compliant (LmCompatibilityLevel = 5)." -ForegroundColor Green
        Write-Host "Note: A logoff/logon or reboot is recommended to ensure all sessions use NTLMv2 only." -ForegroundColor Yellow
        exit 0
    }
    else {
        Write-Warning "FAIL: Value does not match desired state. Expected: $Desired, Actual: $afterValue"
        exit 1
    }
}
catch {
    Write-Error "Failed to configure WN11-SO-000205: $($_.Exception.Message)"
    exit 1
}

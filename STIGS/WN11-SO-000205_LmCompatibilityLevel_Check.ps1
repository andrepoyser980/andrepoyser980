<#
====================================================================
   STIG Check Script – WN11-SO-000205
   Control: The LanMan authentication level must be:
            "Send NTLMv2 response only. Refuse LM & NTLM."

   Registry:
     HKLM\SYSTEM\CurrentControlSet\Control\Lsa
       LmCompatibilityLevel (REG_DWORD) = 5

   Check Logic:
     - Read LmCompatibilityLevel.
     - PASS if it exists AND equals 5.
     - FAIL otherwise.
====================================================================

   CREATOR / METADATA
   -------------------
   Created By   : Andre Poyser
   Date Created : 2025-11-30
   Date Tested  : 2025-11-30
   Last Updated : 2025-11-30
   Version      : 1.0.0

   NOTES:
   - CHECK-ONLY: No changes are made.
   - Exit codes:
        0 = COMPLIANT
        1 = NON-COMPLIANT or undetermined
====================================================================
#>

$RegPath    = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegPathRaw = "HKLM\SYSTEM\CurrentControlSet\Control\Lsa"
$Name       = "LmCompatibilityLevel"
$Expected   = 5

Write-Host "=== STIG Check: WN11-SO-000205 (LAN Manager auth level) ===" -ForegroundColor Cyan
Write-Host 'Verifying "Send NTLMv2 response only. Refuse LM & NTLM" (LmCompatibilityLevel = 5)...' -ForegroundColor Cyan
Write-Host ""

$exists  = $false
$current = $null

try {
    $props = Get-ItemProperty -Path $RegPath -Name $Name -ErrorAction SilentlyContinue
    if ($props) {
        $exists  = $true
        $current = [int]$props.$Name
    }
}
catch { }

Write-Host "Current state:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $RegPathRaw)
Write-Host ("  Name   : {0}" -f $Name)
Write-Host ("  Exists : {0}" -f $exists)
Write-Host ("  Value  : {0}" -f ($(if ($current -ne $null) { $current } else { '<null>' })))
Write-Host ""

if ($exists -and $current -eq $Expected) {
    Write-Host "[PASS] WN11-SO-000205 is COMPLIANT (LmCompatibilityLevel = 5)." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] WN11-SO-000205 is NOT compliant." -ForegroundColor Red
    Write-Host ("       Expected: {0}\{1} = {2}" -f $RegPathRaw, $Name, $Expected) -ForegroundColor Red
    exit 1
}

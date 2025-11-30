<#
====================================================================
   STIG Check Script – WN11-AU-000560
   Control: "Other Logon/Logoff Events" must be configured to log
            Success (advanced audit policy).

   Location:
     Advanced Audit Policy Configuration:
       Computer Configuration →
         Policies →
           Windows Settings →
             Security Settings →
               Advanced Audit Policy Configuration →
                 System Audit Policies →
                   Logon/Logoff →
                     Other Logon/Logoff Events

   Check Logic:
     - Run: auditpol /get /subcategory:"Other Logon/Logoff Events"
     - Parse the "Setting" value
     - PASS if "Success" is included (e.g., "Success" or "Success and Failure")
     - FAIL otherwise (including "No Auditing" or "Failure" only)
====================================================================

   CREATOR / METADATA
   -------------------
   Created By   : Andre Poyser
   Date Created : 2025-11-30
   Date Tested  : 2025-11-30
   Last Updated : 2025-11-30
   Version      : 1.0.0

   NOTES:
   - This script is CHECK-ONLY: it does NOT make changes.
   - Exit codes:
        0 = STIG WN11-AU-000560 is COMPLIANT
        1 = STIG WN11-AU-000560 is NOT COMPLIANT or undetermined
====================================================================
#>

Write-Host "=== STIG Check: WN11-AU-000560 (Other Logon/Logoff Events – Success) ===" -ForegroundColor Cyan
Write-Host "Verifying advanced audit setting for 'Other Logon/Logoff Events'..." -ForegroundColor Cyan
Write-Host ""

function Get-OtherLogonLogoffSetting {
    [CmdletBinding()]
    param()

    $output = auditpol.exe /get /subcategory:"Other Logon/Logoff Events" 2>&1

    if ($LASTEXITCODE -ne 0 -or -not $output) {
        Write-Warning "auditpol command failed or returned no output."
        return $null
    }

    # Example output:
    # System audit policy
    # Category/Subcategory                      Setting
    # Logon/Logoff
    #   Other Logon/Logoff Events               Success and Failure
    #
    # We'll find the line containing "Other Logon/Logoff Events"
    $line = $output | ForEach-Object { $_ } | Where-Object { $_ -match "Other Logon/Logoff Events" }

    if (-not $line) {
        Write-Warning "Could not find 'Other Logon/Logoff Events' line in auditpol output."
        return $null
    }

    # Normalize whitespace, then split into parts:
    # "Other Logon/Logoff Events               Success and Failure"
    # -> ["Other Logon/Logoff Events", "Success and Failure"]
    $normalized = ($line -replace "\s{2,}", "|").Trim()
    $parts      = $normalized -split "\|"

    if ($parts.Count -lt 2) {
        Write-Warning "Unexpected format for auditpol line: $line"
        return $null
    }

    $subcategory = $parts[0].Trim()
    $setting     = $parts[1].Trim()

    [PSCustomObject]@{
        Subcategory = $subcategory
        Setting     = $setting
    }
}

# --- Perform Check ---

$result = Get-OtherLogonLogoffSetting

if ($null -eq $result) {
    Write-Host "[FAIL] Unable to determine current setting for 'Other Logon/Logoff Events'." -ForegroundColor Red
    exit 1
}

Write-Host "Current auditpol state:" -ForegroundColor Yellow
Write-Host ("  Subcategory : {0}" -f $result.Subcategory)
Write-Host ("  Setting     : {0}" -f $result.Setting)
Write-Host ""

# STIG requirement: "Success" must be enabled.
# We consider COMPLIANT if the string contains "Success" at all.
$settingText = $result.Setting

if ($settingText -match "Success") {
    Write-Host "[PASS] WN11-AU-000560: 'Other Logon/Logoff Events' is configured to log Success (Setting = '$settingText')." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] WN11-AU-000560: 'Other Logon/Logoff Events' is NOT logging Success (Setting = '$settingText')." -ForegroundColor Red
    Write-Host "       Expected: Setting includes 'Success' (e.g., 'Success' or 'Success and Failure')." -ForegroundColor Red
    exit 1
}


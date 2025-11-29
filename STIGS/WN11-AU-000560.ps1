<#
====================================================================
   STIG Remediation Script – WN11-AU-000560
   Configure Advanced Audit Policy:
     Logon/Logoff → Other Logon/Logoff Events → Success: Enabled
====================================================================

   Created By      : Andre Poyser
   Date Created    : 2025-11-27
   Date Tested     : 2025-11-29
   OS Version      : Windows 11 24h2-Pro
   Last Updated    : 
   Version         : 1.0.1

   NOTES:
   - This script configures the Windows 11 audit policy to comply with
     STIG WN11-AU-000560.
   - Must be executed from an elevated PowerShell session.
   - Prints before/after audit states for evidence/screenshot purposes.
====================================================================
#>

# region Helper Functions

function Get-OtherLogonLogoffAuditSetting {
    [CmdletBinding()]
    param()

    $output = auditpol.exe /get /subcategory:"Other Logon/Logoff Events" /r 2>$null

    if (-not $output) {
        Write-Warning "Unable to read current Advanced Audit settings."
        return $null
    }

    # Split into non-empty lines
    $lines = $output -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

    if ($lines.Count -lt 2) {
        Write-Warning "Unexpected auditpol output format."
        return $null
    }

    # Last line is usually the data row when using /r
    $dataLine = $lines[-1]

    # auditpol /r returns CSV-like output:
    # "Subcategory","GUID","Inclusion Setting","Exclusion Setting","Success","Failure"
    $parts = $dataLine -split ","

    if ($parts.Count -lt 6) {
        Write-Warning "Unexpected auditpol CSV column count."
        return $null
    }

    $subcategory    = $parts[0].Trim('" ')
    $successState   = $parts[4].Trim('" ')
    $failureState   = $parts[5].Trim('" ')

    [PSCustomObject]@{
        RawLine        = $dataLine
        Subcategory    = $subcategory
        SuccessEnabled = ($successState -eq 'Enabled')
        FailureEnabled = ($failureState -eq 'Enabled')
        SuccessText    = $successState
        FailureText    = $failureState
    }
}

function Set-OtherLogonLogoffAuditSuccess {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Advanced Audit Policy", "Enable Success for 'Other Logon/Logoff Events'")) {
        $result = auditpol.exe /set /subcategory:"Other Logon/Logoff Events" /success:enable 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to set audit policy. Exit code: $LASTEXITCODE`n$result"
            return $false
        }

        Write-Host "Successfully enabled Success auditing for 'Other Logon/Logoff Events'." -ForegroundColor Green
        return $true
    }

    return $false
}

# endregion Helper Functions

# region Main

Write-Host "=== STIG Remediation: WN11-AU-000560 ===" -ForegroundColor Cyan
Write-Host "Requirement: 'Other Logon/Logoff Events' must audit Success." -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Checking current audit setting..." -ForegroundColor Yellow
$current = Get-OtherLogonLogoffAuditSetting

if ($null -eq $current) {
    Write-Error "Could not determine current audit setting. Exiting."
    exit 1
}

Write-Host ("Subcategory: {0}" -f $current.Subcategory)
Write-Host ("  Success: {0}" -f $current.SuccessText)
Write-Host ("  Failure: {0}" -f $current.FailureText)
Write-Host ""

if ($current.SuccessEnabled) {
    Write-Host "No change required. Success auditing is already enabled for 'Other Logon/Logoff Events'." -ForegroundColor Green
}
else {
    Write-Host "[*] Applying STIG-required setting (enable Success)..." -ForegroundColor Yellow
    $setResult = Set-OtherLogonLogoffAuditSuccess

    if ($setResult) {
        Write-Host ""
        Write-Host "[*] Re-checking setting after change..." -ForegroundColor Yellow
        $updated = Get-OtherLogonLogoffAuditSetting

        if ($null -eq $updated) {
            Write-Warning "Could not re-read settings after change. Verify manually via secpol.msc or GPO."
        }
        else {
            Write-Host ("Updated Subcategory: {0}" -f $updated.Subcategory)
            Write-Host ("  Success: {0}" -f $updated.SuccessText)
            Write-Host ("  Failure: {0}" -f $updated.FailureText)

            if ($updated.SuccessEnabled) {
                Write-Host ""
                Write-Host "System now aligns with STIG WN11-AU-000560 (Success enabled for 'Other Logon/Logoff Events')." -ForegroundColor Green
            }
            else {
                Write-Warning "Change did not take effect as expected. Verify via secpol.msc or GPO."
            }
        }
    }
}

# Final compliance check for exit code
$currentFinal = Get-OtherLogonLogoffAuditSetting
if ($currentFinal -and $currentFinal.SuccessEnabled) {
    exit 0
}
else {
    exit 1
}

# endregion Main

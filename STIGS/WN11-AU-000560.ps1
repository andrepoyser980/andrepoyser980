<#
====================================================================
   STIG Remediation Script – WN11-AU-000560
   Configure Advanced Audit Policy:
     Logon/Logoff → Other Logon/Logoff Events
     Required: Success (WN11-AU-000560)
     Recommended: Failure (WN11-AU-000565)

   This version:
   - Enables Success AND Failure for "Other Logon/Logoff Events"
   - Ensures the registry value:
       HKLM\SYSTEM\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy
     exists as REG_DWORD = 1 (create if missing).

   IMPORTANT:
   - Make sure all legacy Audit Policy entries in:
       secpol.msc → Local Policies → Audit Policy
     are set to "No auditing", or advanced audit policy will be blocked.
====================================================================

   -------------------------
   CREATOR / METADATA BLOCK
   -------------------------
   Created By      : Andre Poyser
   Date Created    : 2025-11-27
   Date Tested     : 
   Last Updated    : 2025-11-29
   Version         : 1.0.5

   NOTES:
   - Run from an elevated PowerShell session.
   - Ideal for lab / STIG-hardening.
   - Coordinate with domain GPO owners for production.
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

    # Typical CSV-like format when using /r:
    # "Machine Name","Policy Target","Subcategory","Subcategory GUID","Inclusion Setting","Exclusion Setting"
    $parts = $dataLine -split ","

    if ($parts.Count -lt 6) {
        Write-Warning "Unexpected auditpol CSV column count."
        return $null
    }

    $subcategory    = $parts[2].Trim('" ')
    $inclusionState = $parts[4].Trim('" ')

    # Inclusion Setting is usually "Success", "Failure", "Success and Failure", or "No Auditing"
    $successEnabled = $false
    $failureEnabled = $false

    switch ($inclusionState) {
        "Success" {
            $successEnabled = $true
        }
        "Failure" {
            $failureEnabled = $true
        }
        "Success and Failure" {
            $successEnabled = $true
            $failureEnabled = $true
        }
        default { }
    }

    [PSCustomObject]@{
        RawLine        = $dataLine
        Subcategory    = $subcategory
        SuccessEnabled = $successEnabled
        FailureEnabled = $failureEnabled
        InclusionText  = $inclusionState
    }
}

function Get-AuditSubcategoryOverrideState {
    <#
        Reads:
        HKLM\SYSTEM\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy

        Returns object:
        - Exists   : $true / $false (value exists)
        - Value    : current DWORD or $null
        - Enabled  : $true if == 1
    #>
    [CmdletBinding()]
    param()

    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $name    = 'SCENoApplyLegacyAuditPolicy'

    $obj = New-Object PSObject -Property @{
        Exists  = $false
        Value   = $null
        Enabled = $false
    }

    try {
        $props = Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue

        if ($null -ne $props) {
            $obj.Exists  = $true
            $obj.Value   = [int]$props.$name
            $obj.Enabled = ($props.$name -eq 1)
        }
    }
    catch {
        # ignore, return default
    }

    return $obj
}

function Enable-AuditSubcategoryOverride {
    <#
        Ensures:
        Security Option:
        "Audit: Force audit policy subcategory settings (Windows Vista or later)
         to override audit policy category settings" = Enabled

        Under the hood:
        HKLM\SYSTEM\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy = 1 (REG_DWORD)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $name    = 'SCENoApplyLegacyAuditPolicy'

    $before = Get-AuditSubcategoryOverrideState

    $beforeValueText = '<null>'
    if ($before.Value -ne $null) {
        $beforeValueText = $before.Value.ToString()
    }

    Write-Host "Current audit subcategory override state:" -ForegroundColor Yellow
    Write-Host ("  Exists : {0}" -f $before.Exists)
    Write-Host ("  Value  : {0}" -f $beforeValueText)
    Write-Host ("  Enabled: {0}" -f $before.Enabled)
    Write-Host ""

    if ($before.Enabled) {
        Write-Host "Audit subcategory override is already enabled (no change needed)." -ForegroundColor Green
        return $true
    }

    if ($PSCmdlet.ShouldProcess("$regPath\$name", "Set to 1 (enable subcategory override)")) {
        try {
            # Ensure parent key exists; only create if it does NOT exist
            if (-not (Test-Path -Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }

            # Create or set the value as REG_DWORD = 1 (decimal)
            New-ItemProperty -Path $regPath -Name $name -Value 1 -PropertyType DWord -Force | Out-Null

            $after = Get-AuditSubcategoryOverrideState

            $afterValueText = '<null>'
            if ($after.Value -ne $null) {
                $afterValueText = $after.Value.ToString()
            }

            Write-Host "Updated audit subcategory override state:" -ForegroundColor Yellow
            Write-Host ("  Exists : {0}" -f $after.Exists)
            Write-Host ("  Value  : {0}" -f $afterValueText)
            Write-Host ("  Enabled: {0}" -f $after.Enabled)

            if ($after.Enabled) {
                Write-Host "Successfully enabled audit subcategory override (SCENoApplyLegacyAuditPolicy = 1)." -ForegroundColor Green
                return $true
            }
            else {
                Write-Warning "Attempted to enable override, but it does not appear as Enabled. Verify manually."
                return $false
            }
        }
        catch {
            Write-Error "Failed to enable audit subcategory override: $($_.Exception.Message)"
            return $false
        }
    }

    return $false
}

function Set-OtherLogonLogoffAuditSuccessAndFailure {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if ($PSCmdlet.ShouldProcess("Advanced Audit Policy", "Enable Success and Failure for 'Other Logon/Logoff Events'")) {
        $result = auditpol.exe /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to set audit policy. Exit code: $LASTEXITCODE`n$result"
            return $false
        }

        Write-Host "Successfully enabled Success AND Failure auditing for 'Other Logon/Logoff Events'." -ForegroundColor Green
        return $true
    }

    return $false
}

# endregion Helper Functions

# region Main

Write-Host "=== STIG Remediation: WN11-AU-000560 (Other Logon/Logoff Events) ===" -ForegroundColor Cyan
Write-Host "This script enables Success (and Failure) and enforces advanced audit subcategories." -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Ensuring audit subcategory override is enabled..." -ForegroundColor Yellow
$overrideResult = Enable-AuditSubcategoryOverride
Write-Host ""

Write-Host "[*] Checking current audit setting for 'Other Logon/Logoff Events'..." -ForegroundColor Yellow
$current = Get-OtherLogonLogoffAuditSetting

if ($null -eq $current) {
    Write-Error "Could not determine current audit setting. Exiting."
    exit 1
}

Write-Host ("Current Subcategory: {0}" -f $current.Subcategory)
Write-Host ("  Inclusion Setting: {0}" -f $current.InclusionText)
Write-Host ""

Write-Host "[*] Applying STIG-aligned setting (Success AND Failure)..." -ForegroundColor Yellow
$setResult = Set-OtherLogonLogoffAuditSuccessAndFailure

if ($setResult) {
    Write-Host ""
    Write-Host "[*] Re-checking setting after change..." -ForegroundColor Yellow
    $updated = Get-OtherLogonLogoffAuditSetting

    if ($null -eq $updated) {
        Write-Warning "Could not re-read settings after change. Verify manually via secpol.msc or auditpol."
    }
    else {
        Write-Host ("Updated Subcategory     : {0}" -f $updated.Subcategory)
        Write-Host ("  Updated Inclusion Set : {0}" -f $updated.InclusionText)

        if ($updated.SuccessEnabled -and $updated.FailureEnabled) {
            Write-Host ""
            Write-Host "System now aligns with WN11-AU-000560 (Success) and is ready for WN11-AU-000565 (Failure)." -ForegroundColor Green
        }
        elseif ($updated.SuccessEnabled) {
            Write-Host ""
            Write-Host "System now aligns with WN11-AU-000560 (Success enabled)." -ForegroundColor Green
        }
        else {
            Write-Warning "Success auditing is still not enabled as expected. Check for legacy Audit Policy or other overrides."
        }
    }
}

# Final compliance-oriented exit code (0 = Success enabled, 1 = not)
$currentFinal = Get-OtherLogonLogoffAuditSetting
if ($currentFinal -and $currentFinal.SuccessEnabled) {
    exit 0
}
else {
    exit 1
}

# endregion Main

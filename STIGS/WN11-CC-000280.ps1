<#
====================================================================
   STIG Remediation Script – WN11-CC-000280
   Control: Remote Desktop Services must always prompt a client
            for passwords upon connection.

   Setting:
     GPO Path:
       Computer Configuration →
         Administrative Templates →
           Windows Components →
             Remote Desktop Services →
               Remote Desktop Session Host →
                 Security →
                   "Always prompt for password upon connection" = Enabled

     Registry Equivalent (local / policy store):
       HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\fPromptForPassword = 1 (REG_DWORD)
====================================================================

   
   Created By      : Andre Poyser
   Date Created    : 2025-11-29
   Date Tested     : 2025-11-29
   Last Updated    : 2025-11-29
   Version         : 1.1.0

   NOTES:
   - Run from an elevated PowerShell session (Run as Administrator).
   - Script behavior:
       1. Detects if the system is domain-joined.
       2. Uses gpresult to check if any GPO already enforces:
            "Always prompt for password upon connection"
       3. If GPO already Enabled → no registry change (just log PASS).
       4. If not enforced → sets:
            fPromptForPassword = 1 under the policy registry path.
       5. Returns exit code 0 when compliant, 1 otherwise.

   LIMITATIONS:
   - This script does NOT modify domain GPOs. For domain enforcement,
     apply this setting in a domain GPO via Group Policy Management.
====================================================================
#>

$regPath     = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
$regPathRaw  = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
$name        = 'fPromptForPassword'
$desired     = 1

Write-Host "=== STIG Remediation: WN11-CC-000280 (RDP Prompt for Password) ===" -ForegroundColor Cyan
Write-Host "Enforcing: Remote Desktop Services must always prompt for password upon connection." -ForegroundColor Cyan
Write-Host ""

# region Helper Functions

function Get-DomainJoinStatus {
    try {
        $cs = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
        return [PSCustomObject]@{
            ComputerName = $cs.Name
            Domain       = $cs.Domain
            PartOfDomain = [bool]$cs.PartOfDomain
        }
    }
    catch {
        Write-Warning "Unable to determine domain join status: $($_.Exception.Message)"
        return $null
    }
}

function Test-RdpPromptPolicyFromGpresult {
    <#
        Uses gpresult /scope computer /v to see if any GPO
        already sets "Always prompt for password upon connection".

        Returns:
          - "Enabled"  if the text is found with Enabled
          - "Disabled" / "NotConfigured" if found with those states
          - $null if not found or gpresult fails
    #>
    Write-Host "[*] Checking Resultant Set of Policy (RSoP) using gpresult..." -ForegroundColor Yellow
    try {
        $gp = gpresult /scope computer /v 2>&1
        if ($LASTEXITCODE -ne 0 -or -not $gp) {
            Write-Warning "gpresult did not complete successfully or returned no output."
            return $null
        }

        # Find the line that references the setting, if present
        $line = $gp | Select-String -Pattern "Always prompt for password upon connection" -SimpleMatch

        if (-not $line) {
            Write-Host "  RSoP: No explicit 'Always prompt for password upon connection' entry found." -ForegroundColor Yellow
            return $null
        }

        $text = $line.ToString()

        if ($text -match "Enabled") {
            Write-Host "  RSoP: 'Always prompt for password upon connection' is ENABLED by a GPO." -ForegroundColor Green
            return "Enabled"
        }
        elseif ($text -match "Disabled") {
            Write-Host "  RSoP: 'Always prompt for password upon connection' is DISABLED by a GPO." -ForegroundColor Yellow
            return "Disabled"
        }
        elseif ($text -match "Not Configured") {
            Write-Host "  RSoP: 'Always prompt for password upon connection' is NOT CONFIGURED in GPO." -ForegroundColor Yellow
            return "NotConfigured"
        }
        else {
            Write-Host "  RSoP: Setting found but state not clearly parsed. Line:" -ForegroundColor Yellow
            Write-Host "    $text"
            return $null
        }
    }
    catch {
        Write-Warning "Failed to run or parse gpresult: $($_.Exception.Message)"
        return $null
    }
}

function Get-LocalPolicyRegistryState {
    $exists = $false
    $value  = $null

    try {
        $props = Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue
        if ($props) {
            $exists = $true
            $value  = [int]$props.$name
        }
    }
    catch {
        # ignore
    }

    [PSCustomObject]@{
        Exists = $exists
        Value  = $value
    }
}

# endregion Helper Functions

# region Domain Join Info

$domainInfo = Get-DomainJoinStatus
if ($null -ne $domainInfo) {
    Write-Host "System Identity:" -ForegroundColor Yellow
    Write-Host ("  Computer Name : {0}" -f $domainInfo.ComputerName)
    Write-Host ("  Domain        : {0}" -f $domainInfo.Domain)
    Write-Host ("  Part of Domain: {0}" -f $domainInfo.PartOfDomain)
    Write-Host ""

    if ($domainInfo.PartOfDomain) {
        Write-Warning "This system is domain-joined. Domain GPOs may override local settings."
        Write-Warning "This script will configure the local policy registry, but you should also enforce this via a domain GPO."
        Write-Host ""
    }
}

# endregion Domain Join Info

# region Check via gpresult (RSoP)

$gpState = Test-RdpPromptPolicyFromGpresult
Write-Host ""

if ($gpState -eq "Enabled") {
    Write-Host "A GPO already enforces 'Always prompt for password upon connection' = Enabled." -ForegroundColor Green
    Write-Host "Local registry will not be modified. STIG WN11-CC-000280 is effectively COMPLIANT." -ForegroundColor Green
    exit 0
}

if ($gpState -eq "Disabled") {
    Write-Warning "A GPO explicitly DISABLES this setting. Local changes may be overridden."
    Write-Warning "Coordinate with your GPO administrator to correct the domain policy."
    # We can still set local policy, but warn that it may not stick.
}

# If gpState is NotConfigured or $null, we proceed to configure local policy registry.

# endregion Check via gpresult (RSoP)

# region Local Policy Registry – Before State

$before = Get-LocalPolicyRegistryState

Write-Host "Current local policy registry state:" -ForegroundColor Yellow
Write-Host ("  Path   : {0}" -f $regPathRaw)
Write-Host ("  Name   : {0}" -f $name)
Write-Host ("  Exists : {0}" -f $before.Exists)
Write-Host ("  Value  : {0}" -f ($(if ($before.Value -ne $null) { $before.Value } else { '<null>' })))
Write-Host ""

# If already correct locally and no GPO is contradicting it, we're good.

if ($before.Exists -and $before.Value -eq $desired -and $gpState -ne "Disabled") {
    Write-Host "Local policy registry already matches desired state (fPromptForPassword = 1)." -ForegroundColor Green
    Write-Host "WN11-CC-000280 is COMPLIANT based on local policy registry." -ForegroundColor Green
    exit 0
}

# endregion Local Policy Registry – Before State

# region Apply Local Policy Registry

Write-Host "[*] Applying STIG-compliant local policy registry setting (fPromptForPassword = 1)..." -ForegroundColor Yellow

try {
    if (-not (Test-Path $regPath)) {
        Write-Host "[*] Policy key does not exist; creating: $regPathRaw" -ForegroundColor Yellow
        New-Item -Path $regPath -Force | Out-Null
    }

    New-ItemProperty -Path $regPath -Name $name -Value $desired -PropertyType DWord -Force | Out-Null

    $afterProps = Get-ItemProperty -Path $regPath -Name $name -ErrorAction Stop
    $afterValue = [int]$afterProps.$name

    Write-Host ""
    Write-Host "Updated local policy registry state:" -ForegroundColor Yellow
    Write-Host ("  Path   : {0}" -f $regPathRaw)
    Write-Host ("  Name   : {0}" -f $name)
    Write-Host ("  Value  : {0}" -f $afterValue)
    Write-Host ""

    if ($afterValue -eq $desired) {
        if ($gpState -eq "Disabled") {
            Write-Warning "Local policy is now correct, but a GPO currently DISABLES this setting."
            Write-Warning "You MUST fix the domain GPO to fully satisfy STIG WN11-CC-000280."
            exit 1
        }
        else {
            Write-Host "SUCCESS: WN11-CC-000280 is now compliant from a local policy perspective (fPromptForPassword = 1)." -ForegroundColor Green
            Write-Host "Note: A logoff/logon or reboot is recommended to ensure RDP behavior is consistent." -ForegroundColor Yellow
            exit 0
        }
    }
    else {
        Write-Warning "Registry value did not match desired state. Expected: $desired, Actual: $afterValue"
        exit 1
    }
}
catch {
    Write-Error "Failed to configure WN11-CC-000280: $($_.Exception.Message)"
    exit 1
}

# endregion Apply Local Policy Registry

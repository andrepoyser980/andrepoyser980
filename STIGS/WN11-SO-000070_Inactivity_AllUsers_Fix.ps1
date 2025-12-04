<#
====================================================================
  STIG Remediation Script – WN11-SO-000070
  Control : Machine inactivity must lock after 15 minutes (all users).

  Settings:
    HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
      InactivityTimeoutSecs (DWORD) = 900

    For all users (existing + new):
      HKU\<Hive>\Software\Policies\Microsoft\Windows\Control Panel\Desktop
        ScreenSaveActive    (REG_SZ) = "1"
        ScreenSaverIsSecure (REG_SZ) = "1"
        ScreenSaveTimeOut   (REG_SZ) = "900"
        SCRNSAVE.EXE        (REG_SZ) = "scrnsave.scr"
====================================================================

  CREATOR / METADATA
  -------------------
  Created By   : Andre Poyser
  Date Created : 2025-12-03
  Date Tested  : 2025-12-04
  Last Updated : 2025-12-03
  Version      : 2.1.0
====================================================================
#>

Write-Host "=== Fix: WN11-SO-000070 (15-Minute Lock – All Users) ===" -ForegroundColor Cyan

# Ensure HKU: drive exists (needed for per-user hives)
if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}

# 1) Machine inactivity timeout (system-wide)
$hkmlPath      = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$timeoutName   = "InactivityTimeoutSecs"
$timeoutValue  = 900

if (-not (Test-Path $hkmlPath)) {
    New-Item -Path $hkmlPath -Force | Out-Null
}

New-ItemProperty -Path $hkmlPath -Name $timeoutName -Value $timeoutValue -PropertyType DWord -Force | Out-Null

# 2) Function to apply screensaver policy to a given hive (HKU:\SID or HKU:\.DEFAULT)
function Set-ScreensaverPolicyForHive {
    param(
        [Parameter(Mandatory = $true)][string]$HiveRoot  # e.g. 'HKU:\S-1-5-21-...' or 'HKU:\.DEFAULT'
    )

    $desktopPath = Join-Path $HiveRoot "Software\Policies\Microsoft\Windows\Control Panel\Desktop"

    if (-not (Test-Path $desktopPath)) {
        New-Item -Path $desktopPath -Force | Out-Null
    }

    $settings = @{
        "ScreenSaveActive"    = "1"
        "ScreenSaverIsSecure" = "1"
        "ScreenSaveTimeOut"   = "900"
        "SCRNSAVE.EXE"        = "scrnsave.scr"
    }

    foreach ($name in $settings.Keys) {
        New-ItemProperty -Path $desktopPath -Name $name -Value $settings[$name] -PropertyType String -Force | Out-Null
    }

    Write-Host ("  Applied screensaver policy to: {0}" -f $desktopPath)
}

Write-Host "[*] Applying screensaver policy to all loaded user hives..." -ForegroundColor Yellow

# 2a) Default profile (affects new users)
Set-ScreensaverPolicyForHive -HiveRoot "HKU:\.DEFAULT"

# 2b) All currently loaded real user profiles (S-1-5-21-*)
Get-ChildItem "HKU:\" |
    Where-Object { $_.Name -match '^HKEY_USERS\\S-1-5-21-' } |
    ForEach-Object {
        Set-ScreensaverPolicyForHive -HiveRoot ("HKU:\{0}" -f ($_.PSChildName))
    }

Write-Host "`nFinal system inactivity timeout (HKLM):" -ForegroundColor Yellow
Write-Host ("  InactivityTimeoutSecs : {0}" -f (Get-ItemProperty $hkmlPath).InactivityTimeoutSecs)

Write-Host "`nSUCCESS: WN11-SO-000070 applied for system and all loaded users (plus default profile)." -ForegroundColor Green
exit 0

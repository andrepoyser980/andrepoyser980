<#
====================================================================
  STIG Remediation Script – WN11-AU-000005
  Control : "Audit Credential Validation" = Success and Failure

  Approach:
    - Enable advanced audit override:
        HKLM\SYSTEM\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy = 1
    - Configure policy registry:
        HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit
          "Credential Validation" (REG_DWORD) = 3  (Success + Failure)
    - Set effective audit policy now:
        auditpol /set /subcategory:"Credential Validation"
                  /success:enable /failure:enable
    - Register a Scheduled Task to re-apply auditpol at startup.
====================================================================

  
  Created By   : Andre Poyser
  Date Created : 2025-12-02
  Date Tested  : (enter after testing)
  Last Updated : 2025-12-02
  Version      : 2.0.0
====================================================================
#>

Write-Host "=== Fix: WN11-AU-000005 (Credential Validation – Success & Failure) ===" -ForegroundColor Cyan

# 1) Ensure advanced audit override is enabled
$lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (-not (Test-Path $lsaPath)) {
    New-Item -Path $lsaPath -Force | Out-Null
}
$currentOverride = (Get-ItemProperty -Path $lsaPath -Name 'SCENoApplyLegacyAuditPolicy' -ErrorAction SilentlyContinue).SCENoApplyLegacyAuditPolicy
if ($currentOverride -ne 1) {
    Write-Host "[*] Enabling advanced audit override (SCENoApplyLegacyAuditPolicy = 1)..." -ForegroundColor Yellow
    New-ItemProperty -Path $lsaPath -Name 'SCENoApplyLegacyAuditPolicy' -Value 1 -PropertyType DWord -Force | Out-Null
}

# 2) Configure policy registry for Credential Validation (3 = Success + Failure)
$auditRegPath    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
$auditRegPathRaw = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
$auditName       = "Credential Validation"
$auditValue      = 3   # 1=Success, 2=Failure, 3=Success+Failure

if (-not (Test-Path $auditRegPath)) {
    New-Item -Path $auditRegPath -Force | Out-Null
}

Write-Host "[*] Setting policy registry: $auditRegPathRaw\$auditName = $auditValue (DWORD)..." -ForegroundColor Yellow
New-ItemProperty -Path $auditRegPath -Name $auditName -Value $auditValue -PropertyType DWord -Force | Out-Null

# 3) Apply effective audit policy now
Write-Host "`nCurrent auditpol setting:" -ForegroundColor Yellow
auditpol /get /subcategory:"Credential Validation"

Write-Host "`n[*] Enabling Success AND Failure for 'Credential Validation' via auditpol..." -ForegroundColor Yellow
$setOut = auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "auditpol failed: $setOut"
    exit 1
}

Write-Host "`nUpdated auditpol setting:" -ForegroundColor Yellow
$out = auditpol /get /subcategory:"Credential Validation"
$out

$line    = $out | Where-Object { $_ -match 'Credential Validation' }
$setting = $null
if ($line) {
    $setting = ($line -replace '\s{2,}', '|').Split('|')[-1].Trim()
}
Write-Host ("Parsed Setting: {0}" -f $setting) -ForegroundColor Yellow

# 4) Register Scheduled Task to re-apply on startup
$taskName = "STIG-WN11-AU-000005-CredentialValidation"
Write-Host "`n[*] Creating/Updating startup scheduled task: $taskName" -ForegroundColor Yellow

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"auditpol /set /subcategory:'Credential Validation' /success:enable /failure:enable`""
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

Write-Host "[*] Scheduled task registered to re-apply auditpol at startup." -ForegroundColor Green

# 5) Final compliance check (current session)
if ($setting -and $setting -match 'Success' -and $setting -match 'Failure') {
    Write-Host "`nSUCCESS: WN11-AU-000005 is configured for Success & Failure and will be enforced again at startup." -ForegroundColor Green
    exit 0
} else {
    Write-Warning "`nWN11-AU-000005 may NOT be compliant (Setting = '$setting')."
    exit 1
}

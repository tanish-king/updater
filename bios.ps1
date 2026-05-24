$host.UI.RawUI.WindowTitle = "Tanish Panel"

Clear-Host

function TypeText($text, $color="White"){
    foreach($c in $text.ToCharArray()){
        Write-Host -NoNewline $c -ForegroundColor $color
        Start-Sleep -Milliseconds 35
    }
    Write-Host ""
}

TypeText "Connecting to server..." Cyan
Start-Sleep 1

TypeText "[OK] Authentication Passed" Green
Start-Sleep 1

TypeText "[OK] Syncing API..." Green
Start-Sleep 1

TypeText "[WARNING] Remote service status changed" Yellow
Start-Sleep 2

Write-Host ""
Write-Host "==========================================" -ForegroundColor DarkRed
Write-Host "         TANISH SHUTDOWN THE SERVER         " -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor DarkRed
Write-Host ""

TypeText "Dear Client," White
Write-Host ""

TypeText "This panel has been temporarily disabled by Tanish." Yellow
TypeText "Your subscription has ended kindly pay 100 dollar to reactivate ur plan." Yellow
TypeText "API endpoints have been closed." Yellow
TypeText "Server status: DEACTIVATED" Red

Write-Host ""
TypeText "For support contact TANISH." Gray

Start-Sleep 5
exit

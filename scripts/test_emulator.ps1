# PowerShell helper script to verify the extractServiceIntent function in Firebase Emulator
Write-Host "Checking Firebase CLI and Emulator status..." -ForegroundColor Cyan

if (Get-Command firebase -ErrorAction SilentlyContinue) {
    Write-Host "Firebase CLI detected. You can launch the emulator with:" -ForegroundColor Green
    Write-Host "  firebase emulators:start --only functions" -ForegroundColor Yellow
} else {
    Write-Host "Firebase CLI not found in PATH. Install via: npm install -g firebase-tools" -ForegroundColor Yellow
}

Write-Host "`nRunning local node test on function handler directly:" -ForegroundColor Cyan
node functions/test_local.js

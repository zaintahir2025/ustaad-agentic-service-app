# PowerShell script to execute the Firestore security rules verification test suite
# using the Firebase Local Emulator Suite.

$ErrorActionPreference = "Stop"

Write-Host "Configuring Java environment for Firestore Emulator..." -ForegroundColor Cyan

# Check if java is already in PATH
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    # Check Android Studio bundled JBR
    $jbrPath = "C:\Program Files\Android\Android Studio\jbr\bin"
    if (Test-Path "$jbrPath\java.exe") {
        Write-Host "Found OpenJDK runtime in Android Studio JBR. Adding to PATH..." -ForegroundColor Green
        $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
        $env:PATH = "$jbrPath;$env:PATH"
    } else {
        Write-Host "Warning: Java not found. Please ensure Java 11+ is installed to run the Firestore emulator." -ForegroundColor Yellow
    }
}

# Verify Java
if (Get-Command java -ErrorAction SilentlyContinue) {
    java -version
    Write-Host "`nLaunching Firebase Emulator Suite to verify security rules..." -ForegroundColor Cyan
    firebase emulators:exec --only firestore "node scripts/test_firestore_rules.js"
} else {
    Write-Host "`nError: Java is required to run the Firestore emulator." -ForegroundColor Red
    exit 1
}

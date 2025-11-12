# PowerShell script to deploy Firestore rules
# Run this script to fix permission denied errors

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Talkzy - Deploy Firestore Rules" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI installation..." -ForegroundColor Yellow
$firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue

if (-not $firebaseInstalled) {
    Write-Host "❌ Firebase CLI is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Firebase CLI first:" -ForegroundColor Yellow
    Write-Host "  npm install -g firebase-tools" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation, run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Firebase CLI is installed" -ForegroundColor Green
Write-Host ""

# Check if user is logged in
Write-Host "Checking Firebase login status..." -ForegroundColor Yellow
$loginStatus = firebase login:list 2>&1

if ($loginStatus -match "No authorized accounts") {
    Write-Host "❌ Not logged in to Firebase!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Logging in to Firebase..." -ForegroundColor Yellow
    firebase login
}
else {
    Write-Host "✅ Already logged in to Firebase" -ForegroundColor Green
}

Write-Host ""

# Deploy Firestore rules
Write-Host "Deploying Firestore rules..." -ForegroundColor Yellow
Write-Host ""

try {
    firebase deploy --only firestore:rules
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ Rules deployed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Wait 30-60 seconds for rules to propagate" -ForegroundColor White
    Write-Host "  2. Restart your Flutter app" -ForegroundColor White
    Write-Host "  3. Try sending a friend request again" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ❌ Deployment failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Make sure you selected the correct Firebase project" -ForegroundColor White
    Write-Host "  2. Check if firebase.json exists in this directory" -ForegroundColor White
    Write-Host "  3. Try running: firebase init firestore" -ForegroundColor White
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

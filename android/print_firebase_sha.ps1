# Firebase Android: debug SHA-1 / SHA-256 yazdirir ve proje ayarlarini tarayicida acar.
# Kullanim: android klasorunden:  powershell -ExecutionPolicy Bypass -File .\print_firebase_sha.ps1

$ErrorActionPreference = 'Stop'
$keystore = Join-Path $env:USERPROFILE '.android\debug.keystore'
if (-not (Test-Path $keystore)) {
    Write-Host "debug.keystore bulunamadi: $keystore" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '=== Firebase > Proje ayarlari > Android > SHA sertifika parmak izi ===' -ForegroundColor Cyan
Write-Host 'Asagidaki SHA1 satirini (iki noktali) Firebase''e yapistirin.' -ForegroundColor Yellow
Write-Host ''
& keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android | Select-String -Pattern 'SHA1:|SHA256:'
Write-Host ''
Write-Host 'Sonra: google-services.json indirip su dosyayi degistirin:' -ForegroundColor Green
Write-Host '  android\app\google-services.json'
Write-Host ''
$projectId = 'mathfunapp-1460b'
$url = "https://console.firebase.google.com/project/$projectId/settings/general/"
Write-Host "Tarayicida aciliyor: $url"
Start-Process $url

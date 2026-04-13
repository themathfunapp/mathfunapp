# Store / yan yukleme APK: release + obfuscation.
# Kullanım: .\scripts\build_release_apk.ps1
param(
    [string] $PrivacyUrl = "",
    [string] $TermsUrl = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$symDir = Join-Path $root "symbols\apk"
if (Test-Path $symDir) {
    Remove-Item -Recurse -Force $symDir
}
New-Item -ItemType Directory -Path $symDir -Force | Out-Null

$flutterArgs = @(
    "build", "apk",
    "--release",
    "--obfuscate",
    "--split-debug-info=$symDir"
)
if ($PrivacyUrl) { $flutterArgs += "--dart-define=PRIVACY_POLICY_URL=$PrivacyUrl" }
if ($TermsUrl) { $flutterArgs += "--dart-define=TERMS_OF_USE_URL=$TermsUrl" }

Write-Host ">> flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
& flutter @flutterArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Tamam. APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
Write-Host "Sembol haritalari (YEDEKLEYIN): $symDir" -ForegroundColor Yellow

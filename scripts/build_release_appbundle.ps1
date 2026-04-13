# Store AAB: release + Dart obfuscation + split debug info (crash de-obfuscation için yedekleyin).
# Kullanım: .\scripts\build_release_appbundle.ps1
# İsteğe bağlı: -PrivacyUrl "https://..." -TermsUrl "https://..."
param(
    [string] $PrivacyUrl = "",
    [string] $TermsUrl = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$symDir = Join-Path $root "symbols\app_bundle"
if (Test-Path $symDir) {
    Remove-Item -Recurse -Force $symDir
}
New-Item -ItemType Directory -Path $symDir -Force | Out-Null

$flutterArgs = @(
    "build", "appbundle",
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
Write-Host "Tamam. AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
Write-Host "Sembol haritalari (YEDEKLEYIN, repoya eklemeyin): $symDir" -ForegroundColor Yellow

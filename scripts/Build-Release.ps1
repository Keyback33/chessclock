param([string]$AndroidSdk = "$env:LOCALAPPDATA/Android/sdk", [string]$JavaHome = 'C:/Program Files/Android/Android Studio/jbr')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    $env:JAVA_HOME = $JavaHome
    if (!(Test-Path android/key.properties)) { throw 'Falta firma. Ejecutar scripts/New-SigningKey.ps1 una sola vez.' }
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Falló el análisis.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas.' }
    & flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación.' }
    New-Item -ItemType Directory -Force dist | Out-Null
    Copy-Item build/app/outputs/flutter-apk/app-release.apk dist/chessclock-1.0.0.apk
    & "$PSScriptRoot/Verify-Apk.ps1" -AndroidSdk $AndroidSdk -JavaHome $JavaHome
} finally { Pop-Location }

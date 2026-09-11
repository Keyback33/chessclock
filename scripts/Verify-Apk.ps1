param([string]$AndroidSdk = "$env:LOCALAPPDATA/Android/sdk", [string]$JavaHome = 'C:/Program Files/Android/Android Studio/jbr')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$apkPath = Join-Path $projectRoot 'dist/chessclock-1.0.0.apk'
$env:JAVA_HOME = $JavaHome
$buildTools = Join-Path $AndroidSdk 'build-tools/36.1.0'
$signature = & "$buildTools/apksigner.bat" verify --verbose --print-certs $apkPath 2>&1
if ($LASTEXITCODE -ne 0) { throw 'La firma del APK no es válida.' }
$signature | Set-Content (Join-Path $projectRoot 'dist/signature.txt')
$badging = & "$buildTools/aapt.exe" dump badging $apkPath
if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer el APK.' }
$permissions = & "$buildTools/aapt.exe" dump permissions $apkPath
if ($permissions -match 'android.permission.INTERNET|android.permission.ACCESS_NETWORK_STATE') { throw 'El APK contiene permisos de red.' }
if ($signature -match 'CN=Android Debug') { throw 'Se detectó firma de depuración.' }
if (!($badging -match "sdkVersion:'24'") -or !($badging -match "versionName='1.0.0'")) { throw 'Versión o mínimo Android inesperado.' }
$badging | Set-Content (Join-Path $projectRoot 'dist/apk-info.txt')
$permissions | Set-Content (Join-Path $projectRoot 'dist/permissions.txt')
$hash = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  chessclock-1.0.0.apk" | Set-Content (Join-Path $projectRoot 'dist/chessclock-1.0.0.apk.sha256')
Write-Output "APK verificado: $apkPath"
Write-Output "SHA-256: $hash"

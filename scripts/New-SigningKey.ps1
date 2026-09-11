param([string]$JavaHome = 'C:/Program Files/Android/Android Studio/jbr')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$keyDirectory = Join-Path $projectRoot '.signing'
$propertiesFile = Join-Path $projectRoot 'android/key.properties'
if ((Test-Path $keyDirectory) -or (Test-Path $propertiesFile)) { throw 'La firma ya existe. No se sobrescribe una clave de producción.' }
New-Item -ItemType Directory -Path $keyDirectory | Out-Null
$bytes = [byte[]]::new(32)
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$password = [Convert]::ToBase64String($bytes)
$env:CHESSCLOCK_KEY_PASSWORD = $password
try {
    & "$JavaHome/bin/keytool.exe" -genkeypair -keystore "$keyDirectory/chessclock-release.jks" -storetype JKS -alias chessclock -keyalg RSA -keysize 3072 -validity 10000 -storepass:env CHESSCLOCK_KEY_PASSWORD -keypass:env CHESSCLOCK_KEY_PASSWORD -dname 'CN=chessclock, OU=Android, O=chessclock, C=AR'
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar la clave.' }
    @"
storeFile=../.signing/chessclock-release.jks
storePassword=$password
keyPassword=$password
keyAlias=chessclock
"@ | Set-Content -LiteralPath $propertiesFile -Encoding ascii
    # Restrict private files to the current Windows user and SYSTEM.
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls.exe $keyDirectory '/inheritance:r' '/grant:r' "${identity}:(OI)(CI)F" 'SYSTEM:(OI)(CI)F' | Out-Null
    & icacls.exe $propertiesFile '/inheritance:r' '/grant:r' "${identity}:F" 'SYSTEM:F' | Out-Null
    Write-Output 'Clave de producción creada en .signing; credenciales en android/key.properties. Respaldar ambos archivos fuera del repositorio.'
} finally {
    Remove-Item Env:CHESSCLOCK_KEY_PASSWORD -ErrorAction SilentlyContinue
    $password = $null
}

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$fixtureRoot = Join-Path $projectRoot ('work/retention-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
try {
    foreach ($version in @('1.0.0', '1.9.0', '1.10.0', '2.0.0')) {
        $apk = Join-Path $fixtureRoot "chessclock-$version.apk"
        Set-Content -LiteralPath $apk -Value "fixture $version"
        $hash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash
        Set-Content -LiteralPath "$apk.sha256" -Value "$hash  chessclock-$version.apk"
        New-Item -ItemType Directory -Path (Join-Path $fixtureRoot $version) | Out-Null
        foreach ($report in @('signature.txt', 'apk-info.txt', 'permissions.txt')) {
            Set-Content -LiteralPath (Join-Path $fixtureRoot "$version/$report") -Value 'fixture'
            Set-Content -LiteralPath (Join-Path $fixtureRoot $report) -Value 'legacy'
        }
    }
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'notes.txt') -Value 'unrelated'
    Set-Content -LiteralPath (Join-Path $fixtureRoot 'chessclock-0.9.0.apk.sha256') -Value 'orphan'
    $newChecksum = Join-Path $fixtureRoot 'chessclock-1.10.0.apk.sha256'
    $validChecksum = Get-Content -LiteralPath $newChecksum -Raw
    Set-Content -LiteralPath $newChecksum -Value 'invalid'
    $rejected = $false
    try { & "$PSScriptRoot/Remove-OldReleases.ps1" -CurrentVersion '1.10.0' -DistributionPath $fixtureRoot }
    catch { $rejected = $true }
    if (!$rejected -or !(Test-Path -LiteralPath (Join-Path $fixtureRoot 'chessclock-1.0.0.apk'))) {
        throw 'La limpieza no protegió la entrega anterior ante un checksum inválido.'
    }
    Set-Content -LiteralPath $newChecksum -Value $validChecksum
    $newReport = Join-Path $fixtureRoot '1.10.0/permissions.txt'
    Remove-Item -LiteralPath $newReport
    $rejected = $false
    try { & "$PSScriptRoot/Remove-OldReleases.ps1" -CurrentVersion '1.10.0' -DistributionPath $fixtureRoot }
    catch { $rejected = $true }
    if (!$rejected -or !(Test-Path -LiteralPath (Join-Path $fixtureRoot 'chessclock-1.0.0.apk'))) {
        throw 'La limpieza no protegió la entrega anterior ante informes incompletos.'
    }
    Set-Content -LiteralPath $newReport -Value 'fixture'
    1..2 | ForEach-Object {
        & "$PSScriptRoot/Remove-OldReleases.ps1" -CurrentVersion '1.10.0' -DistributionPath $fixtureRoot
    }
    $remaining = @(Get-ChildItem -LiteralPath $fixtureRoot -Name | Sort-Object)
    $expected = @('1.10.0',
        'chessclock-1.10.0.apk', 'chessclock-1.10.0.apk.sha256', 'notes.txt') | Sort-Object
    if (Compare-Object $remaining $expected) { throw 'Los artefactos conservados no coinciden.' }
    Write-Output 'Retención verificada: solo la última entrega generada, checksum, metadatos, huérfanos e idempotencia.'
} finally {
    $resolvedFixture = (Resolve-Path -LiteralPath $fixtureRoot).Path
    $workRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'work'))
    if ([IO.Path]::GetDirectoryName($resolvedFixture) -ne $workRoot) { throw 'Ruta de fixture inválida.' }
    Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
}

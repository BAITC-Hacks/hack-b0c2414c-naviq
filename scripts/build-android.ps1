param(
    [Parameter(Mandatory = $true)]
    [uri]$ApiBaseUrl,
    [switch]$LocalDemo
)

$ErrorActionPreference = 'Stop'
if (-not $ApiBaseUrl.IsAbsoluteUri -or $ApiBaseUrl.Scheme -notin @('http', 'https')) {
    throw 'ApiBaseUrl must be an absolute HTTP(S) server URL.'
}
if ($ApiBaseUrl.UserInfo -or $ApiBaseUrl.Query -or $ApiBaseUrl.Fragment -or $ApiBaseUrl.AbsolutePath -ne '/') {
    throw 'Use a server origin without credentials, path, query or fragment.'
}
if ($ApiBaseUrl.Scheme -eq 'http' -and -not $LocalDemo) {
    throw 'HTTP is allowed only with -LocalDemo. Use HTTPS for a public server.'
}
if ($ApiBaseUrl.IsLoopback) {
    throw 'On a phone localhost points to the phone. Use the computer LAN address or a public server.'
}

$projectDirectory = Split-Path $PSScriptRoot -Parent
$previousHttpSetting = [Environment]::GetEnvironmentVariable('NAVIQ_ALLOW_LOCAL_HTTP', 'Process')
Push-Location $projectDirectory
try {
    $env:NAVIQ_ALLOW_LOCAL_HTTP = if ($LocalDemo) { 'true' } else { 'false' }
    & flutter build apk --release "--dart-define=API_BASE_URL=$($ApiBaseUrl.AbsoluteUri.TrimEnd('/'))"
    if ($LASTEXITCODE -ne 0) { throw "Android build failed (exit $LASTEXITCODE)." }
    Write-Output "APK: $projectDirectory\build\app\outputs\flutter-apk\app-release.apk"
    Write-Output 'This APK uses the development signing key and is intended for demo installation, not store publication.'
}
finally {
    [Environment]::SetEnvironmentVariable('NAVIQ_ALLOW_LOCAL_HTTP', $previousHttpSetting, 'Process')
    Pop-Location
}

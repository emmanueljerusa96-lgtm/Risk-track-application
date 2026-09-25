# Uploads local Android credentials to GitHub Actions secrets.
# Does not print secret values. Requires gh auth with secrets permission.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$repo = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { "emmanueljerusa96-lgtm/Risk-track-application" }

$jsonPath = "android/app/google-services.json"
if (-not (Test-Path $jsonPath)) {
  throw "Missing $jsonPath. Place the Firebase file there before setting secrets."
}
$json = Get-Content -Raw $jsonPath | ConvertFrom-Json
$packages = @($json.client | ForEach-Object { $_.client_info.android_client_info.package_name })
if ($packages -notcontains "com.risktrack.app") {
  throw "Refusing to upload google-services.json: package_name is not com.risktrack.app"
}

Get-Content -Raw $jsonPath | gh secret set GOOGLE_SERVICES_JSON --repo $repo
Write-Host "Set GOOGLE_SERVICES_JSON on $repo"

$propsPath = "android/key.properties"
if (-not (Test-Path $propsPath)) {
  Write-Host "android/key.properties is missing, so signing secrets were not set."
  Write-Host "Create android/upload-keystore.jks, copy android/key.properties.example to android/key.properties, then rerun this script."
  exit 0
}

$props = @{}
Get-Content $propsPath | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
  $name, $value = $_.Split("=", 2)
  $props[$name.Trim()] = $value.Trim()
}
foreach ($key in @("storePassword", "keyPassword", "keyAlias", "storeFile")) {
  if (-not $props.ContainsKey($key) -or $props[$key] -eq "CHANGE_ME" -or [string]::IsNullOrWhiteSpace($props[$key])) {
    throw "android/key.properties is missing a real $key."
  }
}

$keystore = [System.IO.Path]::GetFullPath((Join-Path "android/app" $props["storeFile"]))
if (-not (Test-Path $keystore)) {
  throw "Keystore not found at $keystore (from storeFile=$($props['storeFile']))."
}

[Convert]::ToBase64String([IO.File]::ReadAllBytes($keystore)) | gh secret set ANDROID_KEYSTORE_BASE64 --repo $repo
$props["storePassword"] | gh secret set ANDROID_KEYSTORE_PASSWORD --repo $repo
$props["keyPassword"] | gh secret set ANDROID_KEY_PASSWORD --repo $repo
$props["keyAlias"] | gh secret set ANDROID_KEY_ALIAS --repo $repo
Write-Host "Set ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD on $repo"
gh secret list --repo $repo

param(
  [string[]]$Target = @('all'),
  [switch]$Clean,
  [switch]$NoPubGet,
  [string]$BuildName,
  [string]$BuildNumber,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$distRoot = Join-Path $projectRoot 'dist'
$artifactName = 'xianyushengxi'
$script:FlutterCommand = $null
$script:GradleUserHomeOverridden = $false
$script:OriginalGradleUserHome = $null

Push-Location $projectRoot

function Get-HostPlatform {
  $runtime = [System.Runtime.InteropServices.RuntimeInformation]
  $platform = [System.Runtime.InteropServices.OSPlatform]

  if ($runtime::IsOSPlatform($platform::Windows)) { return 'windows' }
  if ($runtime::IsOSPlatform($platform::OSX)) { return 'macos' }
  if ($runtime::IsOSPlatform($platform::Linux)) { return 'linux' }

  throw 'Unsupported host platform.'
}

function Get-SupportedTargets {
  param([string]$Platform)

  switch ($Platform) {
    'windows' { return @('android-apk', 'android-appbundle', 'windows') }
    'macos' { return @('android-apk', 'android-appbundle', 'ios', 'macos') }
    'linux' { return @('android-apk', 'android-appbundle', 'linux') }
    default { throw "Unsupported platform: $Platform" }
  }
}

function Resolve-Targets {
  param(
    [string[]]$RequestedTargets,
    [string]$Platform
  )

  $supportedTargets = Get-SupportedTargets -Platform $Platform
  if ($RequestedTargets -contains 'all') {
    return $supportedTargets
  }

  foreach ($item in $RequestedTargets) {
    if ($item -eq 'web') {
      throw "Target 'web' is disabled because the current app depends on dart:ffi packages such as sherpa_onnx, sqlite3, and ffi, which do not compile to Flutter Web. Re-enable it only after adding web-specific implementations."
    }
    if ($supportedTargets -notcontains $item) {
      throw "Target '$item' is not supported on host '$Platform'."
    }
  }

  return $RequestedTargets
}

function Normalize-RequestedTargets {
  param([string[]]$Values)

  $items = @()
  foreach ($value in $Values) {
    if ([string]::IsNullOrWhiteSpace($value)) {
      continue
    }
    $items += $value.Split(',') | ForEach-Object { $_.Trim() } | Where-Object {
      -not [string]::IsNullOrWhiteSpace($_)
    }
  }

  if ($items.Count -eq 0) {
    return @('all')
  }

  return $items
}

function New-BuildArgumentList {
  param([string[]]$BaseArguments)

  $arguments = @($BaseArguments)
  if ($BuildName) {
    $arguments += "--build-name=$BuildName"
  }
  if ($BuildNumber) {
    $arguments += "--build-number=$BuildNumber"
  }
  return $arguments
}

function Resolve-FlutterCommand {
  if ($script:FlutterCommand) {
    return $script:FlutterCommand
  }

  $candidates = @()

  if ($env:FLUTTER_BIN) {
    $candidates += $env:FLUTTER_BIN
  }
  if ($env:FLUTTER_ROOT) {
    $candidates += (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat')
    $candidates += (Join-Path $env:FLUTTER_ROOT 'bin\flutter')
  }

  $command = Get-Command flutter -ErrorAction SilentlyContinue
  if ($command) {
    $candidates += $command.Source
  }

  $candidates += @(
    (Join-Path $projectRoot '.fvm\flutter_sdk\bin\flutter.bat'),
    (Join-Path $projectRoot '.fvm\flutter_sdk\bin\flutter'),
    'D:\env\Flutter\flutter\bin\flutter.bat',
    'C:\src\flutter\bin\flutter.bat',
    (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'),
    (Join-Path $env:USERPROFILE 'fvm\default\bin\flutter.bat')
  )

  foreach ($candidate in $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
    if (Test-Path $candidate) {
      $script:FlutterCommand = $candidate
      return $script:FlutterCommand
    }
  }

  throw "Flutter executable was not found. Set FLUTTER_BIN or FLUTTER_ROOT, or install Flutter in a standard location."
}

function Add-PathEntry {
  param([string]$PathEntry)

  if ([string]::IsNullOrWhiteSpace($PathEntry)) {
    return
  }
  if (-not (Test-Path $PathEntry)) {
    return
  }

  $separator = [System.IO.Path]::PathSeparator
  $currentEntries = $env:PATH -split [regex]::Escape($separator)
  if ($currentEntries -contains $PathEntry) {
    return
  }
  $env:PATH = "$PathEntry$separator$env:PATH"
}

function Resolve-AndroidSdkRoot {
  $candidates = @()

  if ($env:ANDROID_SDK_ROOT) {
    $candidates += $env:ANDROID_SDK_ROOT
  }
  if ($env:ANDROID_HOME) {
    $candidates += $env:ANDROID_HOME
  }

  $candidates += @(
    'D:\env\AndroidSDK',
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:USERPROFILE\AppData\Local\Android\Sdk",
    'C:\Android\Sdk'
  )

  foreach ($candidate in $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
    if ((Test-Path (Join-Path $candidate 'platform-tools\adb.exe')) -or
        (Test-Path (Join-Path $candidate 'platform-tools\adb'))) {
      return $candidate
    }
  }

  return $null
}

function Ensure-AndroidSdkEnvironment {
  $sdkRoot = Resolve-AndroidSdkRoot
  if (-not $sdkRoot) {
    throw "Android SDK was not found. Set ANDROID_HOME or ANDROID_SDK_ROOT, or install the SDK in a standard location."
  }

  $env:ANDROID_HOME = $sdkRoot
  $env:ANDROID_SDK_ROOT = $sdkRoot
  Add-PathEntry -PathEntry (Join-Path $sdkRoot 'platform-tools')
  Add-PathEntry -PathEntry (Join-Path $sdkRoot 'emulator')
  Add-PathEntry -PathEntry (Join-Path $sdkRoot 'cmdline-tools\latest\bin')
  Add-PathEntry -PathEntry (Join-Path $sdkRoot 'tools\bin')
}

function Reset-StaleGradleWrapperState {
  $wrapperPropertiesPath = Join-Path $projectRoot 'android\gradle\wrapper\gradle-wrapper.properties'
  if (-not (Test-Path $wrapperPropertiesPath)) {
    return
  }

  $distributionUrlLine = Get-Content $wrapperPropertiesPath | Where-Object {
    $_ -match '^distributionUrl='
  } | Select-Object -First 1
  if (-not $distributionUrlLine) {
    return
  }

  $distributionUrl = ($distributionUrlLine -replace '^distributionUrl=', '').Trim()
  if ([string]::IsNullOrWhiteSpace($distributionUrl)) {
    return
  }

  $distributionFileName = [System.IO.Path]::GetFileName($distributionUrl)
  if ([string]::IsNullOrWhiteSpace($distributionFileName)) {
    return
  }

  $distributionKey = $distributionFileName -replace '\.zip$', ''
  $gradleUserHome = if ($env:GRADLE_USER_HOME) {
    $env:GRADLE_USER_HOME
  } else {
    Join-Path $env:USERPROFILE '.gradle'
  }
  $wrapperDistRoot = Join-Path $gradleUserHome "wrapper\dists\$distributionKey"
  if (-not (Test-Path $wrapperDistRoot)) {
    return
  }

  Get-ChildItem -Path $wrapperDistRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like '*.part' -or $_.Name -like '*.lck'
  } | ForEach-Object {
    Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
  }
}

function Use-ProjectGradleUserHome {
  if ($script:GradleUserHomeOverridden) {
    return
  }

  $script:OriginalGradleUserHome = $env:GRADLE_USER_HOME
  $script:GradleUserHomeOverridden = $true
  $localGradleUserHome = Join-Path $projectRoot 'android\.gradle-user-home'
  Ensure-Directory -Path $localGradleUserHome
  $env:GRADLE_USER_HOME = $localGradleUserHome
}

function Restore-GradleUserHome {
  if (-not $script:GradleUserHomeOverridden) {
    return
  }

  if ([string]::IsNullOrWhiteSpace($script:OriginalGradleUserHome)) {
    Remove-Item Env:GRADLE_USER_HOME -ErrorAction SilentlyContinue
  } else {
    $env:GRADLE_USER_HOME = $script:OriginalGradleUserHome
  }
  $script:GradleUserHomeOverridden = $false
}

function Invoke-Flutter {
  param([string[]]$Arguments)

  $flutterCommand = Resolve-FlutterCommand
  $commandText = "$flutterCommand " + ($Arguments -join ' ')
  Write-Host $commandText
  if ($DryRun) {
    return
  }

  & $flutterCommand @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $commandText"
  }
}

function Reset-Path {
  param([string]$Path)

  if (Test-Path $Path) {
    Remove-Item -Path $Path -Recurse -Force
  }
}

function Ensure-Directory {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Copy-Artifact {
  param(
    [string]$Source,
    [string]$Destination
  )

  if ($DryRun) {
    Write-Host "Copy $Source -> $Destination"
    return
  }

  if (-not (Test-Path $Source)) {
    throw "Build artifact not found: $Source"
  }

  Reset-Path -Path $Destination
  Ensure-Directory -Path (Split-Path -Parent $Destination)
  Copy-Item -Path $Source -Destination $Destination -Recurse -Force
}

function Build-AndroidApk {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'apk', '--release'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk') `
    -Destination (Join-Path $distRoot 'android-apk\xianyushengxi.apk')
}

function Build-AndroidAppBundle {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'appbundle', '--release'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab') `
    -Destination (Join-Path $distRoot 'android-appbundle\xianyushengxi.aab')
}

function Build-Ios {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'ios', '--release', '--no-codesign'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot 'build\ios\iphoneos\Runner.app') `
    -Destination (Join-Path $distRoot 'ios\Runner.app')
}

function Build-Macos {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'macos', '--release'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot "build\macos\Build\Products\Release\$artifactName.app") `
    -Destination (Join-Path $distRoot "$artifactName-macos.app")
}

function Build-Windows {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'windows', '--release'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot 'build\windows\x64\runner\Release') `
    -Destination (Join-Path $distRoot 'windows')
}

function Build-Linux {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'linux', '--release'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot 'build\linux\x64\release\bundle') `
    -Destination (Join-Path $distRoot 'linux')
}

try {
  $hostPlatform = Get-HostPlatform
  $requestedTargets = Normalize-RequestedTargets -Values $Target
  $resolvedTargets = Resolve-Targets -RequestedTargets $requestedTargets -Platform $hostPlatform

  Ensure-Directory -Path $distRoot

  if ($Clean) {
    Invoke-Flutter -Arguments @('clean')
  }

  if (-not $NoPubGet) {
    Invoke-Flutter -Arguments @('pub', 'get')
  }

  if ($resolvedTargets -contains 'android-apk' -or $resolvedTargets -contains 'android-appbundle') {
    Ensure-AndroidSdkEnvironment
    Use-ProjectGradleUserHome
    Reset-StaleGradleWrapperState
  }

  foreach ($item in $resolvedTargets) {
    switch ($item) {
      'android-apk' { Build-AndroidApk }
      'android-appbundle' { Build-AndroidAppBundle }
      'ios' { Build-Ios }
      'macos' { Build-Macos }
      'windows' { Build-Windows }
      'linux' { Build-Linux }
      default { throw "Unsupported target: $item" }
    }
  }

  Write-Host "Build outputs are ready in $distRoot"
} finally {
  Restore-GradleUserHome
  Pop-Location
}

param(
  [string[]]$Target = @('all'),
  [switch]$Clean,
  [switch]$ResetBuildCache,
  [switch]$NoPubGet,
  [string]$BuildName,
  [string]$BuildNumber,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'tooling-env.ps1')

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

  $script:FlutterCommand = Resolve-ProjectFlutterCommand -ProjectRoot $projectRoot
  return $script:FlutterCommand
}

function Ensure-AndroidSdkEnvironment {
  return Ensure-ProjectAndroidSdkEnvironment -ProjectRoot $projectRoot
}

function Ensure-AndroidAppBundleEnvironment {
  $sdkRoot = Ensure-AndroidSdkEnvironment
  $apkAnalyzer = Assert-ProjectAndroidAppBundleTooling -SdkRoot $sdkRoot
  Write-Host "Android SDK: $sdkRoot"
  Write-Host "Android apkanalyzer: $apkAnalyzer"
}

function Ensure-CMakeEnvironment {
  $cmakeCommand = Ensure-ProjectCMakeEnvironment -ProjectRoot $projectRoot
  $nugetCommand = Ensure-ProjectNuGet
  Write-Host "CMake: $cmakeCommand"
  Write-Host "NuGet: $nugetCommand"
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

  if ($ResetBuildCache) {
    Clear-ProjectGeneratedBuildCache -ProjectRoot $projectRoot -Scope all -DryRun:$DryRun
  } else {
    if ($resolvedTargets -contains 'windows') {
      Repair-ProjectCMakeCache -ProjectRoot $projectRoot -Scope windows -DryRun:$DryRun
    }
    if ($resolvedTargets -contains 'android-apk' -or $resolvedTargets -contains 'android-appbundle') {
      Repair-ProjectCMakeCache -ProjectRoot $projectRoot -Scope android -DryRun:$DryRun
    }
  }

  if ($Clean) {
    Invoke-Flutter -Arguments @('clean')
  }

  if (-not $NoPubGet) {
    Invoke-Flutter -Arguments @('pub', 'get')
  }

  if ($resolvedTargets -contains 'android-apk' -or $resolvedTargets -contains 'android-appbundle') {
    if ($resolvedTargets -contains 'android-appbundle') {
      Ensure-AndroidAppBundleEnvironment
    } else {
      $sdkRoot = Ensure-AndroidSdkEnvironment
      Write-Host "Android SDK: $sdkRoot"
    }
    Use-ProjectGradleUserHome
    Reset-StaleGradleWrapperState
  }
  if ($resolvedTargets -contains 'windows') {
    Ensure-CMakeEnvironment
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

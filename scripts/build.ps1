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
    'windows' { return @('android-apk', 'android-appbundle', 'windows', 'web') }
    'macos' { return @('android-apk', 'android-appbundle', 'ios', 'macos', 'web') }
    'linux' { return @('android-apk', 'android-appbundle', 'linux', 'web') }
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

function Invoke-Flutter {
  param([string[]]$Arguments)

  $commandText = 'flutter ' + ($Arguments -join ' ')
  Write-Host $commandText
  if ($DryRun) {
    return
  }

  & flutter @Arguments
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

function Build-Web {
  Invoke-Flutter -Arguments (New-BuildArgumentList -BaseArguments @('build', 'web', '--release', '--no-wasm-dry-run'))
  Copy-Artifact `
    -Source (Join-Path $projectRoot 'build\web') `
    -Destination (Join-Path $distRoot 'web')
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

  foreach ($item in $resolvedTargets) {
    switch ($item) {
      'android-apk' { Build-AndroidApk }
      'android-appbundle' { Build-AndroidAppBundle }
      'ios' { Build-Ios }
      'macos' { Build-Macos }
      'windows' { Build-Windows }
      'linux' { Build-Linux }
      'web' { Build-Web }
      default { throw "Unsupported target: $item" }
    }
  }

  Write-Host "Build outputs are ready in $distRoot"
} finally {
  Pop-Location
}

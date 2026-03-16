param(
  [switch]$Clean,
  [switch]$ResetAppState,
  [switch]$NoPubGet,
  [switch]$NoRun,
  [string]$Device = "windows",
  [int]$RunRetry = 2
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

function Add-PathIfMissing {
  param([string]$PathToAdd)
  if ([string]::IsNullOrWhiteSpace($PathToAdd)) { return }
  $segments = ($env:Path -split ';') | Where-Object { $_ -and $_.Trim().Length -gt 0 }
  if ($segments -contains $PathToAdd) { return }
  $env:Path = "$PathToAdd;$env:Path"
}

function Ensure-NuGet {
  $nuget = Get-Command nuget.exe -ErrorAction SilentlyContinue
  if ($nuget) {
    return $nuget.Source
  }

  $localBin = Join-Path $env:USERPROFILE ".local\bin"
  $localNuget = Join-Path $localBin "nuget.exe"
  if (Test-Path $localNuget) {
    Add-PathIfMissing -PathToAdd $localBin
    return $localNuget
  }

  Write-Host "nuget.exe not found. Downloading to $localNuget ..."
  New-Item -ItemType Directory -Path $localBin -Force | Out-Null
  Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $localNuget
  Add-PathIfMissing -PathToAdd $localBin
  return $localNuget
}

function Ensure-BuildTools {
  $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
  if (-not $flutterCmd) {
    throw "flutter command not found in PATH."
  }
  $cmakeCmd = Get-Command cmake -ErrorAction SilentlyContinue
  if (-not $cmakeCmd) {
    throw "cmake command not found in PATH. Please install Visual Studio C++ build tools."
  }
  $null = Ensure-NuGet
}

function Stop-FlutterAppProcess {
  $running = Get-Process xianyushengxi -ErrorAction SilentlyContinue
  if ($running) {
    Write-Host "Stopping existing xianyushengxi process..."
    $running | Stop-Process -Force
    Start-Sleep -Milliseconds 800
  }
}

function Remove-LockedRunnerArtifacts {
  $paths = @(
    (Join-Path $projectRoot "build\windows\x64\runner\Debug\sqlite3.dll"),
    (Join-Path $projectRoot "build\windows\x64\runner\Debug\flutter_tts_plugin.dll")
  )
  foreach ($path in $paths) {
    if (-not (Test-Path $path)) { continue }
    try {
      Remove-Item -Force $path -ErrorAction Stop
      Write-Host "Removed stale artifact: $path"
    } catch {
      Write-Host "Skip removing locked artifact: $path"
    }
  }
}

function Reset-AppState {
  $paths = @(
    (Join-Path $env:APPDATA "group.zn\xianyushengxi"),
    (Join-Path $env:LOCALAPPDATA "group.zn\xianyushengxi"),
    (Join-Path $env:APPDATA "group.zn\咸鱼声息"),
    (Join-Path $env:LOCALAPPDATA "group.zn\咸鱼声息")
  )
  foreach ($path in $paths) {
    if (-not (Test-Path $path)) { continue }
    try {
      Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
      Write-Host "Removed app state: $path"
    } catch {
      Write-Host "Skip removing app state: $path"
    }
  }
}

try {
  Write-Host "Project root: $projectRoot"
  Ensure-BuildTools

  if ($Clean) {
    Write-Host "Running flutter clean..."
    flutter clean
  }

  if ($ResetAppState -or $Clean) {
    Write-Host "Resetting app cache/config..."
    Reset-AppState
  }

  if (-not $NoPubGet) {
    Write-Host "Running flutter pub get..."
    flutter pub get
  }

  Stop-FlutterAppProcess
  Remove-LockedRunnerArtifacts

  if ($NoRun) {
    Write-Host "Skip flutter run (NoRun=true)."
    exit 0
  }

  $attempts = [Math]::Max(1, $RunRetry)
  for ($attempt = 1; $attempt -le $attempts; $attempt++) {
    Write-Host "Starting flutter run -d $Device (attempt $attempt/$attempts) ..."
    flutter run -d $Device
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
      exit 0
    }

    if ($attempt -lt $attempts) {
      Write-Host "flutter run failed with code $exitCode. Retrying after cleanup..."
      Stop-FlutterAppProcess
      Remove-LockedRunnerArtifacts
      Start-Sleep -Seconds 1
      continue
    }

    throw "flutter run failed with exit code $exitCode."
  }
} finally {
  Pop-Location
}

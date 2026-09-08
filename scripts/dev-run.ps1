param(
  [switch]$Clean,
  [switch]$ResetAppState,
  [switch]$ResetBuildCache,
  [switch]$NoPubGet,
  [switch]$NoRun,
  [string]$Device = "windows",
  [int]$RunRetry = 2
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'tooling-env.ps1')

$projectRoot = Split-Path -Parent $PSScriptRoot
$script:FlutterCommand = $null
Push-Location $projectRoot

function Resolve-FlutterCommand {
  if ($script:FlutterCommand) {
    return $script:FlutterCommand
  }

  $script:FlutterCommand = Resolve-ProjectFlutterCommand -ProjectRoot $projectRoot
  return $script:FlutterCommand
}

function Ensure-BuildTools {
  $flutterCmd = Resolve-FlutterCommand
  $cmakeCmd = Ensure-ProjectCMakeEnvironment -ProjectRoot $projectRoot
  $null = Ensure-ProjectNuGet
  $libClangDirectory = $null
  if ($Device -ieq 'windows') {
    $libClangDirectory = Ensure-ProjectLibClangEnvironment -ProjectRoot $projectRoot
  }
  Write-Host "Flutter: $flutterCmd"
  Write-Host "CMake: $cmakeCmd"
  if ($libClangDirectory) {
    Write-Host "libclang: $libClangDirectory"
  }
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

function Invoke-Flutter {
  param([string[]]$Arguments)

  $flutterCommand = Resolve-FlutterCommand
  $commandText = "$flutterCommand " + ($Arguments -join ' ')
  Write-Host $commandText
  & $flutterCommand @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $commandText"
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

  if ($ResetBuildCache) {
    Clear-ProjectGeneratedBuildCache -ProjectRoot $projectRoot -Scope windows
  } else {
    Repair-ProjectCMakeCache -ProjectRoot $projectRoot -Scope windows
  }

  if ($Clean) {
    Write-Host "Running flutter clean..."
    Invoke-Flutter -Arguments @('clean')
  }

  if ($ResetAppState -or $Clean) {
    Write-Host "Resetting app cache/config..."
    Reset-AppState
  }

  if (-not $NoPubGet) {
    Write-Host "Running flutter pub get..."
    Invoke-Flutter -Arguments @('pub', 'get')
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
    $flutterCommand = Resolve-FlutterCommand
    & $flutterCommand @('run', '-d', $Device)
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

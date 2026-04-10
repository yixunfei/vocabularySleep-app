param(
  [ValidateSet("format-check", "format-write", "dart-analyze", "flutter-analyze", "analyze", "all")]
  [string[]]$Task = @("all"),
  [string[]]$Target = @("lib"),
  [switch]$CleanTemp,
  [switch]$PubGet
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

function Resolve-FlutterCommand {
  $command = Get-Command flutter -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $candidates = @(
    "D:\env\flutter\flutter\bin\flutter.bat",
    (Join-Path $projectRoot ".fvm\flutter_sdk\bin\flutter.bat"),
    $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE "flutter\bin\flutter.bat" })
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "Flutter executable was not found. Ensure flutter is in PATH or installed in a known location."
}

function Resolve-DartCommand {
  param([string]$FlutterCommand)

  $flutterDir = Split-Path -Parent $FlutterCommand
  $dartFromFlutter = Join-Path $flutterDir "cache\dart-sdk\bin\dart.exe"
  if (Test-Path $dartFromFlutter) {
    return $dartFromFlutter
  }

  $command = Get-Command dart -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  throw "Dart executable was not found."
}

function Initialize-LocalToolingEnvironment {
  $toolingRoot = Join-Path $projectRoot ".tooling"
  $paths = @{
    APPDATA = Join-Path $toolingRoot "appdata"
    LOCALAPPDATA = Join-Path $toolingRoot "localappdata"
    PUB_CACHE = Join-Path $toolingRoot "pub-cache"
    HOME = Join-Path $toolingRoot "home"
    USERPROFILE = Join-Path $toolingRoot "home"
  }

  foreach ($path in ($paths.Values | Select-Object -Unique)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
  }

  foreach ($entry in $paths.GetEnumerator()) {
    Set-Item -Path ("Env:{0}" -f $entry.Key) -Value $entry.Value
  }

  return $toolingRoot
}

function Resolve-RequestedTasks {
  param([string[]]$RequestedTasks)

  $expanded = @()
  foreach ($item in $RequestedTasks) {
    switch ($item) {
      "all" {
        $expanded += @("format-check", "dart-analyze", "flutter-analyze")
      }
      "analyze" {
        $expanded += @("dart-analyze", "flutter-analyze")
      }
      default {
        $expanded += $item
      }
    }
  }

  return $expanded | Select-Object -Unique
}

function Invoke-ToolCommand {
  param(
    [string]$Executable,
    [string[]]$Arguments,
    [string]$Label
  )

  $joinedArguments = $Arguments -join " "
  Write-Host "Running $Label..." -ForegroundColor Cyan
  Write-Host ("Command: {0} {1}" -f $Executable, $joinedArguments) -ForegroundColor DarkGray
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE."
  }
}

function Resolve-TargetGroups {
  param([string[]]$Targets)

  $groups = @{
    Dart = New-Object System.Collections.Generic.List[string]
    PowerShell = New-Object System.Collections.Generic.List[string]
  }

  foreach ($item in $Targets) {
    $extension = [System.IO.Path]::GetExtension($item)
    if ($extension -in @(".ps1", ".psm1", ".psd1")) {
      $groups.PowerShell.Add($item)
      continue
    }

    $groups.Dart.Add($item)
  }

  return $groups
}

function Assert-PowerShellSyntax {
  param([string[]]$Targets)

  foreach ($item in $Targets) {
    $resolvedPath = Resolve-Path $item -ErrorAction Stop
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
      $resolvedPath.Path,
      [ref]$tokens,
      [ref]$errors
    ) | Out-Null

    if ($errors.Count -gt 0) {
      $messages = $errors | ForEach-Object {
        "$($_.Extent.StartLineNumber):$($_.Extent.StartColumnNumber) $($_.Message)"
      }
      throw "PowerShell syntax check failed for $item`n$($messages -join [Environment]::NewLine)"
    }

    Write-Host "PowerShell syntax OK: $item" -ForegroundColor DarkGreen
  }
}

function Invoke-FormatCheck {
  param(
    [string]$DartCommand,
    [hashtable]$TargetGroups
  )

  if ($TargetGroups.Dart.Count -gt 0) {
    Invoke-ToolCommand `
      -Executable $DartCommand `
      -Arguments (@("format", "--output=none", "--set-exit-if-changed") + $TargetGroups.Dart.ToArray()) `
      -Label "dart format (check)"
  }

  if ($TargetGroups.PowerShell.Count -gt 0) {
    Write-Host "Running PowerShell syntax check..." -ForegroundColor Cyan
    Assert-PowerShellSyntax -Targets $TargetGroups.PowerShell.ToArray()
  }
}

function Invoke-FormatWrite {
  param(
    [string]$DartCommand,
    [hashtable]$TargetGroups
  )

  if ($TargetGroups.Dart.Count -gt 0) {
    Invoke-ToolCommand `
      -Executable $DartCommand `
      -Arguments (@("format") + $TargetGroups.Dart.ToArray()) `
      -Label "dart format (write)"
  }

  if ($TargetGroups.PowerShell.Count -gt 0) {
    throw "format-write does not support PowerShell targets yet: $($TargetGroups.PowerShell -join ", ")"
  }
}

function Assert-HasDartTargets {
  param(
    [hashtable]$TargetGroups,
    [string]$TaskName
  )

  if ($TargetGroups.Dart.Count -eq 0) {
    Write-Host "Skipping $TaskName because no Dart/Flutter targets were provided." -ForegroundColor Yellow
    return $false
  }

  return $true
}

try {
  $flutterCommand = Resolve-FlutterCommand
  $dartCommand = Resolve-DartCommand -FlutterCommand $flutterCommand
  $toolingRoot = Join-Path $projectRoot ".tooling"

  if ($CleanTemp -and (Test-Path $toolingRoot)) {
    Remove-Item -LiteralPath $toolingRoot -Recurse -Force
  }

  $toolingRoot = Initialize-LocalToolingEnvironment
  $resolvedTasks = Resolve-RequestedTasks -RequestedTasks $Task
  $targetGroups = Resolve-TargetGroups -Targets $Target

  Write-Host "Local verify toolbox" -ForegroundColor Green
  Write-Host "Project root: $projectRoot"
  Write-Host "Flutter: $flutterCommand"
  Write-Host "Dart: $dartCommand"
  Write-Host "Tooling root: $toolingRoot"
  Write-Host ("Tasks: {0}" -f ($resolvedTasks -join ", "))
  Write-Host ("Targets: {0}" -f ($Target -join ", "))

  if ($PubGet) {
    Invoke-ToolCommand -Executable $flutterCommand -Arguments @("pub", "get") -Label "flutter pub get"
  }

  foreach ($currentTask in $resolvedTasks) {
    switch ($currentTask) {
      "format-check" {
        Invoke-FormatCheck -DartCommand $dartCommand -TargetGroups $targetGroups
      }
      "format-write" {
        Invoke-FormatWrite -DartCommand $dartCommand -TargetGroups $targetGroups
      }
      "dart-analyze" {
        if (-not (Assert-HasDartTargets -TargetGroups $targetGroups -TaskName "dart analyze")) {
          continue
        }

        Invoke-ToolCommand `
          -Executable $dartCommand `
          -Arguments (@("analyze") + $TargetGroups.Dart.ToArray()) `
          -Label "dart analyze"
      }
      "flutter-analyze" {
        if (-not (Assert-HasDartTargets -TargetGroups $targetGroups -TaskName "flutter analyze")) {
          continue
        }

        Invoke-ToolCommand `
          -Executable $flutterCommand `
          -Arguments (@("analyze") + $TargetGroups.Dart.ToArray()) `
          -Label "flutter analyze"
      }
      default {
        throw "Unsupported task: $currentTask"
      }
    }
  }

  Write-Host "Local verification finished with no issues." -ForegroundColor Green
} finally {
  Pop-Location
}

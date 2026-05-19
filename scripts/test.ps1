param(
  [string[]]$Target = @('test'),
  [string]$Name,
  [string]$PlainName,
  [ValidateSet('compact', 'expanded', 'github', 'json')]
  [string]$Reporter = 'compact',
  [switch]$NoPubGet,
  [switch]$UseLocalTooling,
  [switch]$CleanTemp,
  [switch]$ResetBuildCache,
  [switch]$DryRun,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ExtraArgs
)

$ErrorActionPreference = 'Stop'
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

function Normalize-TestTargets {
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
    return @('test')
  }

  return $items
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

try {
  $flutterCommand = Resolve-FlutterCommand
  $toolingRoot = Join-Path $projectRoot '.tooling'

  if ($CleanTemp -and (Test-Path -LiteralPath $toolingRoot)) {
    if ($DryRun) {
      Write-Host "Would remove local tooling temp: $toolingRoot"
    } else {
      Remove-Item -LiteralPath $toolingRoot -Recurse -Force
    }
  }

  if ($UseLocalTooling) {
    $toolingRoot = Initialize-ProjectLocalToolingEnvironment -ProjectRoot $projectRoot
  }

  if ($ResetBuildCache) {
    Clear-ProjectGeneratedBuildCache -ProjectRoot $projectRoot -Scope all -DryRun:$DryRun
  } else {
    Repair-ProjectCMakeCache -ProjectRoot $projectRoot -Scope all -DryRun:$DryRun
  }

  $resolvedTargets = Normalize-TestTargets -Values $Target
  $testArguments = @('test') + $resolvedTargets + @("--reporter=$Reporter")

  if (-not [string]::IsNullOrWhiteSpace($Name)) {
    $testArguments += @('--name', $Name)
  }
  if (-not [string]::IsNullOrWhiteSpace($PlainName)) {
    $testArguments += @('--plain-name', $PlainName)
  }
  if ($ExtraArgs) {
    $testArguments += $ExtraArgs
  }

  Write-Host 'Flutter test toolbox' -ForegroundColor Green
  Write-Host "Project root: $projectRoot"
  Write-Host "Flutter: $flutterCommand"
  if ($UseLocalTooling) {
    Write-Host "Tooling root: $toolingRoot"
  }
  Write-Host ("Targets: {0}" -f ($resolvedTargets -join ', '))

  if (-not $NoPubGet) {
    Invoke-Flutter -Arguments @('pub', 'get')
  }

  Invoke-Flutter -Arguments $testArguments
  Write-Host 'Flutter tests finished with no issues.' -ForegroundColor Green
} finally {
  Pop-Location
}

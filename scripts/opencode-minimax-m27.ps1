param(
  [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$Prompt,
  [ValidateSet("default", "json")]
  [string]$Format = "default",
  [string]$Variant,
  [string[]]$File,
  [switch]$Share,
  [switch]$Thinking,
  [switch]$SkipPermissions
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

function Resolve-OpencodeCommand {
  $command = Get-Command opencode -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $candidates = @(
    "C:\Users\yixun\AppData\Roaming\npm\opencode.cmd",
    "C:\Users\yixun\AppData\Roaming\npm\opencode.ps1"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "opencode command was not found. Ensure opencode is installed and available in PATH."
}

try {
  $opencodeCommand = Resolve-OpencodeCommand
  $modelId = "minimax-cn-coding-plan/MiniMax-M2.7"
  $message = ($Prompt -join " ").Trim()

  if ([string]::IsNullOrWhiteSpace($message)) {
    throw "Prompt cannot be empty."
  }

  $arguments = @("run", "-m", $modelId, "--format", $Format)

  if (-not [string]::IsNullOrWhiteSpace($Variant)) {
    $arguments += @("--variant", $Variant)
  }

  foreach ($attachment in $File) {
    $arguments += @("--file", $attachment)
  }

  if ($Share) {
    $arguments += "--share"
  }

  if ($Thinking) {
    $arguments += "--thinking"
  }

  if ($SkipPermissions) {
    $arguments += "--dangerously-skip-permissions"
  }

  $arguments += $message

  Write-Host "Running opencode MiniMax M2.7 template..." -ForegroundColor Cyan
  Write-Host "Model: $modelId"
  Write-Host "Project root: $projectRoot"
  & $opencodeCommand @arguments

  if ($LASTEXITCODE -ne 0) {
    throw "MiniMax M2.7 template command failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}


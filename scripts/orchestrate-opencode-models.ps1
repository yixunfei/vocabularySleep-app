param(
  [Parameter(Mandatory = $true)]
  [string]$Prompt,
  [string[]]$Profile,
  [int]$Throttle = 3,
  [int]$TimeoutSeconds = 180,
  [string]$OutputDir,
  [switch]$SkipPermissions,
  [switch]$PassThru
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

function Resolve-OpencodeCommand {
  $preferred = "C:\Users\yixun\AppData\Roaming\npm\opencode.cmd"
  if (Test-Path $preferred) {
    return $preferred
  }

  $command = Get-Command opencode -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $fallback = "C:\Users\yixun\AppData\Roaming\npm\opencode.ps1"
  if (Test-Path $fallback) {
    return $fallback
  }

  throw "opencode command was not found. Ensure opencode is installed and available in PATH."
}

function Get-ProfileConfig {
  $configPath = Join-Path $PSScriptRoot "opencode-model-profiles.json"
  if (-not (Test-Path $configPath)) {
    throw "Profile config not found: $configPath"
  }

  return (Get-Content $configPath -Raw | ConvertFrom-Json)
}

function Resolve-RequestedProfiles {
  param([string[]]$RawProfiles)

  $resolved = New-Object System.Collections.Generic.List[string]
  foreach ($item in $RawProfiles) {
    if ([string]::IsNullOrWhiteSpace($item)) {
      continue
    }

    foreach ($segment in ($item -split ",")) {
      $trimmed = $segment.Trim()
      if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
        $resolved.Add($trimmed)
      }
    }
  }

  return @($resolved | Select-Object -Unique)
}

function New-OutputDirectory {
  param([string]$RequestedPath)

  if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
    $resolvedParent = Split-Path -Parent $RequestedPath
    if (-not [string]::IsNullOrWhiteSpace($resolvedParent)) {
      New-Item -ItemType Directory -Force -Path $resolvedParent | Out-Null
    }
    New-Item -ItemType Directory -Force -Path $RequestedPath | Out-Null
    return (Resolve-Path $RequestedPath).Path
  }

  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $generatedPath = Join-Path $projectRoot ".tmp_model_runs\$timestamp"
  New-Item -ItemType Directory -Force -Path $generatedPath | Out-Null
  return (Resolve-Path $generatedPath).Path
}

function Start-ModelProcess {
  param(
    [string]$OpencodeCommand,
    [string]$ProfileName,
    [string]$ModelId,
    [string]$Message,
    [string]$BatchOutputDir,
    [bool]$AutoApprove
  )

  $safeName = ($ProfileName -replace "[^a-zA-Z0-9_-]", "_")
  $rawPath = Join-Path $BatchOutputDir ($safeName + ".jsonl")
  $errorPath = Join-Path $BatchOutputDir ($safeName + ".stderr.txt")
  $textPath = Join-Path $BatchOutputDir ($safeName + ".txt")

  if (Test-Path $rawPath) {
    Remove-Item -LiteralPath $rawPath -Force
  }
  if (Test-Path $errorPath) {
    Remove-Item -LiteralPath $errorPath -Force
  }

  $arguments = @("run", "-m", $ModelId, "--format", "json")
  if ($AutoApprove) {
    $arguments += "--dangerously-skip-permissions"
  }
  $arguments += $Message

  $process = Start-Process `
    -FilePath $OpencodeCommand `
    -ArgumentList $arguments `
    -WorkingDirectory $projectRoot `
    -RedirectStandardOutput $rawPath `
    -RedirectStandardError $errorPath `
    -PassThru

  [pscustomobject]@{
    profile = $ProfileName
    model = $ModelId
    raw_path = $rawPath
    error_path = $errorPath
    text_path = $textPath
    process = $process
  }
}

function Receive-ModelProcessResult {
  param(
    [pscustomobject]$ProcessInfo,
    [int]$PerModelTimeoutSeconds
  )

  $null = $ProcessInfo.process.WaitForExit($PerModelTimeoutSeconds * 1000)
  if (-not $ProcessInfo.process.HasExited) {
    try {
      $ProcessInfo.process.Kill()
    } catch {
      # Ignore cleanup failure here; the timeout is already the real error.
    }

    return [pscustomobject]@{
      profile = $ProcessInfo.profile
      model = $ProcessInfo.model
      exit_code = -1
      raw_path = $ProcessInfo.raw_path
      error_path = $ProcessInfo.error_path
      text_path = $ProcessInfo.text_path
      text = ""
      success = $false
      error = "Timed out after $PerModelTimeoutSeconds seconds."
    }
  }

  $rawLines = @()
  if (Test-Path $ProcessInfo.raw_path) {
    $rawLines = @(Get-Content $ProcessInfo.raw_path)
  }

  $textParts = New-Object System.Collections.Generic.List[string]
  foreach ($line in $rawLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }

    try {
      $event = $line | ConvertFrom-Json -ErrorAction Stop
      if ($event.type -eq "text" -and $null -ne $event.part -and $event.part.text) {
        $textParts.Add([string]$event.part.text)
      }
    } catch {
      continue
    }
  }

  $joinedText = $textParts -join [Environment]::NewLine
  if ($null -eq $joinedText) {
    $joinedText = ""
  }

  $textOutput = $joinedText.Trim()
  [System.IO.File]::WriteAllText($ProcessInfo.text_path, $textOutput)

  $errorText = ""
  if (Test-Path $ProcessInfo.error_path) {
    $rawErrorText = Get-Content $ProcessInfo.error_path -Raw
    if ($null -eq $rawErrorText) {
      $rawErrorText = ""
    }

    $errorText = $rawErrorText.Trim()
  }

  $normalizedExitCode = $ProcessInfo.process.ExitCode
  if ($null -eq $normalizedExitCode) {
    if ($rawLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($errorText)) {
      $normalizedExitCode = 0
    } else {
      $normalizedExitCode = -1
    }
  }

  [pscustomobject]@{
    profile = $ProcessInfo.profile
    model = $ProcessInfo.model
    exit_code = $normalizedExitCode
    raw_path = $ProcessInfo.raw_path
    error_path = $ProcessInfo.error_path
    text_path = $ProcessInfo.text_path
    text = $textOutput
    success = ($normalizedExitCode -eq 0)
    error = $errorText
  }
}

try {
  $resolvedPrompt = $Prompt.Trim()
  if ([string]::IsNullOrWhiteSpace($resolvedPrompt)) {
    throw "Prompt cannot be empty."
  }

  $config = Get-ProfileConfig
  $requestedProfiles = Resolve-RequestedProfiles -RawProfiles $Profile
  if ($requestedProfiles.Count -eq 0) {
    $requestedProfiles = @($config.defaultProfiles)
  }

  $throttleValue = [Math]::Max(1, $Throttle)
  $timeoutValue = [Math]::Max(30, $TimeoutSeconds)
  $opencodeCommand = Resolve-OpencodeCommand
  $resolvedOutputDir = New-OutputDirectory -RequestedPath $OutputDir
  $results = New-Object System.Collections.Generic.List[object]

  Write-Host "Starting opencode model orchestration..." -ForegroundColor Cyan
  Write-Host "Project root: $projectRoot"
  Write-Host "Output dir: $resolvedOutputDir"
  Write-Host ("Profiles: {0}" -f ($requestedProfiles -join ", "))
  Write-Host "Throttle: $throttleValue"
  Write-Host "Timeout seconds: $timeoutValue"

  for ($index = 0; $index -lt $requestedProfiles.Count; $index += $throttleValue) {
    $batchProfiles = @(
      $requestedProfiles[$index..([Math]::Min($index + $throttleValue - 1, $requestedProfiles.Count - 1))]
    )
    $processes = New-Object System.Collections.Generic.List[object]

    foreach ($profileName in $batchProfiles) {
      $profileConfig = $config.profiles.PSObject.Properties[$profileName]
      if (-not $profileConfig) {
        throw "Unknown profile: $profileName"
      }

      $modelId = [string]$profileConfig.Value.model
      Write-Host "Launch model: $profileName -> $modelId" -ForegroundColor DarkGray
      $processInfo = Start-ModelProcess `
        -OpencodeCommand $opencodeCommand `
        -ProfileName $profileName `
        -ModelId $modelId `
        -Message $resolvedPrompt `
        -BatchOutputDir $resolvedOutputDir `
        -AutoApprove $SkipPermissions.IsPresent
      $processes.Add($processInfo)
    }

    foreach ($processInfo in $processes) {
      $result = Receive-ModelProcessResult `
        -ProcessInfo $processInfo `
        -PerModelTimeoutSeconds $timeoutValue
      $results.Add($result)
    }
  }

  $failed = @($results | Where-Object { -not $_.success })
  foreach ($result in $results) {
    Write-Host ""
    Write-Host ("[{0}] {1}" -f $result.profile, $result.model) -ForegroundColor Green
    Write-Host ("Text path: {0}" -f $result.text_path) -ForegroundColor DarkGray
    if (-not [string]::IsNullOrWhiteSpace($result.error)) {
      Write-Host ("Error: {0}" -f $result.error) -ForegroundColor Yellow
    }

    if ([string]::IsNullOrWhiteSpace($result.text)) {
      Write-Host "(No parsed text output; inspect raw JSONL if needed.)" -ForegroundColor Yellow
    } else {
      Write-Host $result.text
    }
  }

  if ($PassThru) {
    $results
  }

  if ($failed.Count -gt 0) {
    throw "One or more model runs failed. Inspect output files in $resolvedOutputDir"
  }
} finally {
  Pop-Location
}

param(
  [int]$Last = 200,
  [switch]$Follow
)

$candidateRoots = @(
  (Join-Path $env:APPDATA 'group.zn\xianyushengxi\logs'),
  (Join-Path $env:APPDATA 'group.zn\咸鱼声息\logs')
)
$logRoot = $candidateRoots | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $logRoot) {
  Write-Error "Log directory not found. Checked: $($candidateRoots -join ', ')"
  exit 1
}

$latest = Get-ChildItem -Path $logRoot -Filter 'app-*.log' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if ($null -eq $latest) {
  Write-Error "No app log file found in $logRoot"
  exit 1
}

Write-Host "Using log file: $($latest.FullName)"
if ($Follow) {
  Get-Content -Path $latest.FullName -Tail $Last -Wait
} else {
  Get-Content -Path $latest.FullName -Tail $Last
}

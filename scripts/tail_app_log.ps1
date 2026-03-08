param(
  [int]$Last = 200,
  [switch]$Follow
)

$logRoot = Join-Path $env:APPDATA 'com.example\flutter_app\logs'
if (-not (Test-Path $logRoot)) {
  Write-Error "Log directory not found: $logRoot"
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

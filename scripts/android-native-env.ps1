# FJS bindgen loads a host libclang DLL, which may not ship standard headers.
# Use the headers from the same NDK that Flutter selects for Android builds.
function Get-ProjectAndroidClangInclude {
  param([string]$ProjectRoot, [string]$FlutterCommand, [string]$SdkRoot)

  $appGradle = Get-Content -Raw (Join-Path $ProjectRoot 'android/app/build.gradle.kts')
  $ndkMatch = [regex]::Match($appGradle, 'ndkVersion\s*=\s*"([^"]+)"')
  if (-not $ndkMatch.Success) {
    $flutterRoot = Split-Path -Parent (Split-Path -Parent $FlutterCommand)
    $extensionPath = Join-Path $flutterRoot 'packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt'
    if (-not (Test-Path -LiteralPath $extensionPath)) {
      throw 'Cannot resolve Flutter Android NDK version for native bindings.'
    }
    $extension = Get-Content -Raw -LiteralPath $extensionPath
    $ndkMatch = [regex]::Match($extension, 'ndkVersion(?:\s*:\s*String)?\s*=\s*"([^"]+)"')
  }
  if (-not $ndkMatch.Success) {
    throw 'Cannot resolve Android NDK version for native bindings.'
  }

  $clangRoot = Join-Path $SdkRoot "ndk/$($ndkMatch.Groups[1].Value)/toolchains/llvm/prebuilt/windows-x86_64/lib/clang"
  $includePath = Get-ChildItem -LiteralPath $clangRoot -Directory |
    Sort-Object { [version]($_.Name + '.0') } -Descending |
    ForEach-Object { Join-Path $_.FullName 'include' } |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ 'stdbool.h') } |
    Select-Object -First 1
  if (-not $includePath) {
    throw "Android NDK Clang headers are missing under $clangRoot. Reinstall this NDK using SDK Manager."
  }
  return $includePath
}

function Invoke-ProjectAndroidNativeBuild {
  param([string]$ProjectRoot, [string]$FlutterCommand, [scriptblock]$Build)

  $oldIncludePath = $env:C_INCLUDE_PATH
  $oldLibClangPath = $env:LIBCLANG_PATH
  $oldExecutablePath = $env:PATH
  try {
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
      [System.Runtime.InteropServices.OSPlatform]::Windows)) {
      $sdkRoot = Ensure-ProjectAndroidSdkEnvironment -ProjectRoot $ProjectRoot
      $includePath = Get-ProjectAndroidClangInclude -ProjectRoot $ProjectRoot `
        -FlutterCommand $FlutterCommand -SdkRoot $sdkRoot
      $libClangPath = Ensure-ProjectLibClangEnvironment -ProjectRoot $ProjectRoot
      $env:C_INCLUDE_PATH = $includePath
      if ($oldIncludePath) {
        $env:C_INCLUDE_PATH += [IO.Path]::PathSeparator + $oldIncludePath
      }
      Write-Host "Android native bindings: $libClangPath; headers: $includePath"
    }
    & $Build
  } finally {
    $env:C_INCLUDE_PATH = $oldIncludePath
    $env:LIBCLANG_PATH = $oldLibClangPath
    $env:PATH = $oldExecutablePath
  }
}

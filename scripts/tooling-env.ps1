function Add-ProjectPathEntry {
  param([string]$PathEntry)

  if ([string]::IsNullOrWhiteSpace($PathEntry)) {
    return
  }
  if (-not (Test-Path -LiteralPath $PathEntry)) {
    return
  }

  $separator = [System.IO.Path]::PathSeparator
  $currentEntries = $env:PATH -split [regex]::Escape($separator)
  if ($currentEntries -contains $PathEntry) {
    return
  }

  $env:PATH = "$PathEntry$separator$env:PATH"
}

function Resolve-ProjectFlutterCommand {
  param([string]$ProjectRoot)

  $candidates = New-Object System.Collections.Generic.List[string]

  if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_BIN)) {
    $candidates.Add($env:FLUTTER_BIN)
  }
  if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) {
    $candidates.Add((Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'))
    $candidates.Add((Join-Path $env:FLUTTER_ROOT 'bin\flutter'))
  }

  $command = Get-Command flutter -ErrorAction SilentlyContinue
  if ($command) {
    $candidates.Add($command.Source)
  }

  $candidates.Add((Join-Path $ProjectRoot '.fvm\flutter_sdk\bin\flutter.bat'))
  $candidates.Add((Join-Path $ProjectRoot '.fvm\flutter_sdk\bin\flutter'))

  if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    $candidates.Add((Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'))
    $candidates.Add((Join-Path $env:USERPROFILE 'fvm\default\bin\flutter.bat'))
  }

  foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  throw 'Flutter executable was not found. Set FLUTTER_BIN or FLUTTER_ROOT, or install Flutter in a standard location.'
}

function Resolve-ProjectDartCommand {
  param([string]$FlutterCommand)

  $flutterDir = Split-Path -Parent $FlutterCommand
  $dartFromFlutter = Join-Path $flutterDir 'cache\dart-sdk\bin\dart.exe'
  if (Test-Path -LiteralPath $dartFromFlutter) {
    return $dartFromFlutter
  }

  $dartFromFlutterUnix = Join-Path $flutterDir 'cache/dart-sdk/bin/dart'
  if (Test-Path -LiteralPath $dartFromFlutterUnix) {
    return $dartFromFlutterUnix
  }

  $command = Get-Command dart -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  throw 'Dart executable was not found.'
}

function Resolve-ProjectCMakeCommand {
  param([string]$ProjectRoot)

  $candidates = New-Object System.Collections.Generic.List[string]

  if (-not [string]::IsNullOrWhiteSpace($env:CMAKE_BIN)) {
    if (Test-Path -LiteralPath $env:CMAKE_BIN -PathType Container) {
      $candidates.Add((Join-Path $env:CMAKE_BIN 'cmake.exe'))
      $candidates.Add((Join-Path $env:CMAKE_BIN 'cmake'))
    } else {
      $candidates.Add($env:CMAKE_BIN)
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($env:CMAKE_ROOT)) {
    $candidates.Add((Join-Path $env:CMAKE_ROOT 'bin\cmake.exe'))
    $candidates.Add((Join-Path $env:CMAKE_ROOT 'bin\cmake'))
  }

  $command = Get-Command cmake -ErrorAction SilentlyContinue
  if ($command) {
    $candidates.Add($command.Source)
  }

  $candidates.Add((Join-Path $ProjectRoot '.tooling\cmake\bin\cmake.exe'))
  if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $candidates.Add((Join-Path $env:ProgramFiles 'CMake\bin\cmake.exe'))
    $candidates.Add((Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'))
    $candidates.Add((Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'))
  }
  $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
  if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
    $candidates.Add((Join-Path $programFilesX86 'CMake\bin\cmake.exe'))
  }

  foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  throw 'CMake executable was not found. Set CMAKE_BIN or CMAKE_ROOT, install CMake, or add cmake.exe to PATH.'
}

function Ensure-ProjectCMakeEnvironment {
  param([string]$ProjectRoot)

  $cmakeCommand = Resolve-ProjectCMakeCommand -ProjectRoot $ProjectRoot
  Add-ProjectPathEntry -PathEntry (Split-Path -Parent $cmakeCommand)
  return $cmakeCommand
}

function Test-ProjectX64PortableExecutable {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return $false
  }

  $stream = $null
  $reader = $null
  try {
    $stream = [System.IO.File]::Open(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite
    )
    if ($stream.Length -lt 64) {
      return $false
    }

    $reader = New-Object System.IO.BinaryReader($stream)
    if ($reader.ReadUInt16() -ne 0x5A4D) {
      return $false
    }

    $stream.Position = 0x3C
    $peOffset = $reader.ReadInt32()
    if ($peOffset -lt 0 -or $peOffset -gt ($stream.Length - 6)) {
      return $false
    }

    $stream.Position = $peOffset
    return ($reader.ReadUInt32() -eq 0x00004550) -and
      ($reader.ReadUInt16() -eq 0x8664)
  } catch {
    return $false
  } finally {
    if ($reader) {
      $reader.Dispose()
    } elseif ($stream) {
      $stream.Dispose()
    }
  }
}

function Test-ProjectX64LibClangDirectory {
  param([string]$Directory)

  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
    return $false
  }

  foreach ($fileName in @('libclang.dll', 'clang.dll')) {
    if (Test-ProjectX64PortableExecutable -Path (Join-Path $Directory $fileName)) {
      return $true
    }
  }

  return $false
}

function Resolve-ProjectLibClangDirectory {
  param([string]$ProjectRoot)

  $candidates = New-Object System.Collections.Generic.List[string]
  foreach ($value in @(
      $env:LIBCLANG_PATH,
      [Environment]::GetEnvironmentVariable('LIBCLANG_PATH', 'User'),
      [Environment]::GetEnvironmentVariable('LIBCLANG_PATH', 'Machine'),
      (Join-Path $ProjectRoot '.tooling\libclang\runtimes\win-x64\native'),
      (Join-Path $ProjectRoot '.tooling\libclang\bin')
    )) {
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      $candidates.Add($value)
    }
  }

  $projectLibClangRoot = Join-Path $ProjectRoot '.tooling\libclang'
  if (Test-Path -LiteralPath $projectLibClangRoot -PathType Container) {
    Get-ChildItem -LiteralPath $projectLibClangRoot -Directory -Filter 'libclang.runtime.win-x64*' -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending |
      ForEach-Object {
        $candidates.Add((Join-Path $_.FullName 'runtimes\win-x64\native'))
      }
  }

  if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Directory -Filter 'libclang-*' -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending |
      ForEach-Object {
        $candidates.Add((Join-Path $_.FullName 'runtimes\win-x64\native'))
        $candidates.Add((Join-Path $_.FullName 'bin'))
      }
  }

  if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    $nugetRoot = Join-Path $env:USERPROFILE '.nuget\packages\libclang.runtime.win-x64'
    if (Test-Path -LiteralPath $nugetRoot -PathType Container) {
      Get-ChildItem -LiteralPath $nugetRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object {
          $candidates.Add((Join-Path $_.FullName 'runtimes\win-x64\native'))
        }
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $candidates.Add((Join-Path $env:ProgramFiles 'LLVM\bin'))
    foreach ($edition in @('Community', 'Professional', 'Enterprise', 'BuildTools')) {
      $candidates.Add((Join-Path $env:ProgramFiles "Microsoft Visual Studio\2022\$edition\VC\Tools\Llvm\x64\bin"))
    }
  }

  $visited = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($candidate in $candidates) {
    $expanded = [Environment]::ExpandEnvironmentVariables($candidate.Trim().Trim([char]34))
    if ([string]::IsNullOrWhiteSpace($expanded)) {
      continue
    }

    $directory = $expanded
    if (Test-Path -LiteralPath $expanded -PathType Leaf) {
      if ([System.IO.Path]::GetFileName($expanded) -notin @('libclang.dll', 'clang.dll')) {
        continue
      }
      $directory = Split-Path -Parent $expanded
    }
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
      continue
    }

    $fullDirectory = [System.IO.Path]::GetFullPath($directory)
    if (-not $visited.Add($fullDirectory)) {
      continue
    }
    if (Test-ProjectX64LibClangDirectory -Directory $fullDirectory) {
      return $fullDirectory
    }
  }

  throw @"
A valid x64 libclang.dll was not found. FJS/rquickjs requires it for the bindgen build step.
Set LIBCLANG_PATH to the directory containing an x64 libclang.dll, or use the project PowerShell scripts to bootstrap the pinned runtime.
"@
}

function Install-ProjectLibClangRuntime {
  param([string]$ProjectRoot)

  $packageId = 'libclang.runtime.win-x64'
  $packageVersion = '22.1.8'
  $outputDirectory = Join-Path $ProjectRoot '.tooling\libclang'
  $packageDirectory = Join-Path $outputDirectory "$packageId.$packageVersion"
  $runtimeDirectory = Join-Path $packageDirectory 'runtimes\win-x64\native'

  if (Test-ProjectX64LibClangDirectory -Directory $runtimeDirectory) {
    return $runtimeDirectory
  }

  if (Test-Path -LiteralPath $packageDirectory) {
    $quarantineDirectory = "$packageDirectory.incomplete.$([DateTime]::UtcNow.ToString('yyyyMMddHHmmssfff'))"
    Write-Warning "Moving incomplete libclang package to $quarantineDirectory"
    Move-Item -LiteralPath $packageDirectory -Destination $quarantineDirectory
  }

  $nugetCommand = Ensure-ProjectNuGet
  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  Write-Host "x64 libclang was not found. Installing $packageId $packageVersion to $outputDirectory ..."

  $nugetOutput = & $nugetCommand @(
    'install',
    $packageId,
    '-Version', $packageVersion,
    '-OutputDirectory', $outputDirectory,
    '-Source', 'https://api.nuget.org/v3/index.json',
    '-DirectDownload',
    '-NonInteractive',
    '-ForceEnglishOutput'
  )
  $exitCode = $LASTEXITCODE
  $nugetOutput | ForEach-Object { Write-Host $_ }
  if ($exitCode -ne 0) {
    throw "NuGet failed to install $packageId $packageVersion (exit code $exitCode). Set LIBCLANG_PATH to an existing x64 libclang directory and retry."
  }
  if (-not (Test-ProjectX64LibClangDirectory -Directory $runtimeDirectory)) {
    throw "NuGet completed, but a valid x64 libclang.dll was not found in $runtimeDirectory."
  }

  return $runtimeDirectory
}

function Ensure-ProjectLibClangEnvironment {
  param([string]$ProjectRoot)

  try {
    $directory = Resolve-ProjectLibClangDirectory -ProjectRoot $ProjectRoot
  } catch {
    $directory = Install-ProjectLibClangRuntime -ProjectRoot $ProjectRoot
  }
  $env:LIBCLANG_PATH = $directory
  Add-ProjectPathEntry -PathEntry $directory
  return $directory
}

function Resolve-ProjectAndroidSdkRoot {
  param([string]$ProjectRoot)

  $candidates = New-Object System.Collections.Generic.List[string]

  if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
    $candidates.Add($env:ANDROID_SDK_ROOT)
  }
  if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
    $candidates.Add($env:ANDROID_HOME)
  }

  $candidates.Add((Join-Path $ProjectRoot '.tooling\android-sdk'))

  if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Android\Sdk'))
  }
  if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    $candidates.Add((Join-Path $env:USERPROFILE 'AppData\Local\Android\Sdk'))
  }

  foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }

    $adbExe = Join-Path $candidate 'platform-tools\adb.exe'
    $adbUnix = Join-Path $candidate 'platform-tools\adb'
    if ((Test-Path -LiteralPath $adbExe) -or (Test-Path -LiteralPath $adbUnix)) {
      return $candidate
    }
  }

  return $null
}

function Test-ProjectHostIsWindows {
  $runtime = [System.Runtime.InteropServices.RuntimeInformation]
  $platform = [System.Runtime.InteropServices.OSPlatform]
  return $runtime::IsOSPlatform($platform::Windows)
}

function Get-ProjectAndroidCmdlineToolBinaryName {
  param([string]$Name)

  if ((Test-ProjectHostIsWindows) -and
      -not $Name.EndsWith('.bat', [System.StringComparison]::OrdinalIgnoreCase) -and
      -not $Name.EndsWith('.exe', [System.StringComparison]::OrdinalIgnoreCase)) {
    return "$Name.bat"
  }

  return $Name
}

function Get-ProjectAndroidCmdlineToolBinDirectories {
  param([string]$SdkRoot)

  $directories = New-Object System.Collections.Generic.List[string]
  $cmdlineToolsRoot = Join-Path $SdkRoot 'cmdline-tools'
  $latestBin = Join-Path $cmdlineToolsRoot 'latest\bin'
  if (Test-Path -LiteralPath $latestBin -PathType Container) {
    $directories.Add($latestBin)
  }

  if (Test-Path -LiteralPath $cmdlineToolsRoot -PathType Container) {
    Get-ChildItem -LiteralPath $cmdlineToolsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
      $bin = Join-Path $_.FullName 'bin'
      if (Test-Path -LiteralPath $bin -PathType Container) {
        $directories.Add($bin)
      }
    }
  }

  $legacyToolsBin = Join-Path $SdkRoot 'tools\bin'
  if (Test-Path -LiteralPath $legacyToolsBin -PathType Container) {
    $directories.Add($legacyToolsBin)
  }

  return $directories | Select-Object -Unique
}

function Resolve-ProjectAndroidCmdlineTool {
  param(
    [string]$SdkRoot,
    [string]$Name
  )

  $binaryName = Get-ProjectAndroidCmdlineToolBinaryName -Name $Name
  foreach ($directory in (Get-ProjectAndroidCmdlineToolBinDirectories -SdkRoot $SdkRoot)) {
    $candidate = Join-Path $directory $binaryName
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  return $null
}

function Ensure-ProjectAndroidSdkEnvironment {
  param([string]$ProjectRoot)

  $sdkRoot = Resolve-ProjectAndroidSdkRoot -ProjectRoot $ProjectRoot
  if (-not $sdkRoot) {
    throw 'Android SDK was not found. Set ANDROID_HOME or ANDROID_SDK_ROOT, or install the SDK in a standard location.'
  }

  $env:ANDROID_HOME = $sdkRoot
  $env:ANDROID_SDK_ROOT = $sdkRoot
  Add-ProjectPathEntry -PathEntry (Join-Path $sdkRoot 'platform-tools')
  Add-ProjectPathEntry -PathEntry (Join-Path $sdkRoot 'emulator')
  foreach ($directory in (Get-ProjectAndroidCmdlineToolBinDirectories -SdkRoot $sdkRoot)) {
    Add-ProjectPathEntry -PathEntry $directory
  }
  Add-ProjectPathEntry -PathEntry (Join-Path $sdkRoot 'tools\bin')

  return $sdkRoot
}

function Assert-ProjectAndroidAppBundleTooling {
  param([string]$SdkRoot)

  $cmdlineToolsRoot = Join-Path $SdkRoot 'cmdline-tools'
  if (-not (Test-Path -LiteralPath $cmdlineToolsRoot -PathType Container)) {
    throw @"
Android SDK command-line tools are missing: $cmdlineToolsRoot
Flutter builds the AAB successfully, but then requires cmdline-tools/apkanalyzer to verify stripped native debug symbols.
Install Android SDK Command-line Tools in Android Studio SDK Manager, or install the official command-line tools package and ensure sdkmanager/apkanalyzer live under:
  $SdkRoot\cmdline-tools\latest\bin
After installation, run:
  flutter doctor --android-licenses
"@
  }

  $apkAnalyzer = Resolve-ProjectAndroidCmdlineTool -SdkRoot $SdkRoot -Name 'apkanalyzer'
  if (-not $apkAnalyzer) {
    throw @"
Android SDK apkanalyzer was not found under: $cmdlineToolsRoot
Flutter appbundle uses apkanalyzer after Gradle completes to verify that native debug symbols were stripped.
Install or update Android SDK Command-line Tools, then ensure this file exists:
  $SdkRoot\cmdline-tools\latest\bin\apkanalyzer.bat
"@
  }

  Add-ProjectPathEntry -PathEntry (Split-Path -Parent $apkAnalyzer)
  return $apkAnalyzer
}

function Ensure-ProjectNuGet {
  if (-not [string]::IsNullOrWhiteSpace($env:NUGET_BIN)) {
    if (Test-Path -LiteralPath $env:NUGET_BIN -PathType Container) {
      $nugetFromEnvDir = Join-Path $env:NUGET_BIN 'nuget.exe'
      if (Test-Path -LiteralPath $nugetFromEnvDir) {
        Add-ProjectPathEntry -PathEntry $env:NUGET_BIN
        return $nugetFromEnvDir
      }
    } elseif (Test-Path -LiteralPath $env:NUGET_BIN) {
      Add-ProjectPathEntry -PathEntry (Split-Path -Parent $env:NUGET_BIN)
      return $env:NUGET_BIN
    }
  }

  $nuget = Get-Command nuget.exe -ErrorAction SilentlyContinue
  if ($nuget) {
    return $nuget.Source
  }

  if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    throw 'nuget.exe was not found and USERPROFILE is not available for local installation.'
  }

  $localBin = Join-Path $env:USERPROFILE '.local\bin'
  $localNuget = Join-Path $localBin 'nuget.exe'
  if (Test-Path -LiteralPath $localNuget) {
    Add-ProjectPathEntry -PathEntry $localBin
    return $localNuget
  }

  Write-Host "nuget.exe not found. Downloading to $localNuget ..."
  New-Item -ItemType Directory -Path $localBin -Force | Out-Null
  Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $localNuget
  Add-ProjectPathEntry -PathEntry $localBin
  return $localNuget
}

function Initialize-ProjectLocalToolingEnvironment {
  param([string]$ProjectRoot)

  $toolingRoot = Join-Path $ProjectRoot '.tooling'
  $paths = @{
    APPDATA = Join-Path $toolingRoot 'appdata'
    LOCALAPPDATA = Join-Path $toolingRoot 'localappdata'
    PUB_CACHE = Join-Path $toolingRoot 'pub-cache'
    HOME = Join-Path $toolingRoot 'home'
    USERPROFILE = Join-Path $toolingRoot 'home'
  }

  foreach ($path in ($paths.Values | Select-Object -Unique)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
  }

  foreach ($entry in $paths.GetEnumerator()) {
    Set-Item -Path ("Env:{0}" -f $entry.Key) -Value $entry.Value
  }

  return $toolingRoot
}

function ConvertTo-ProjectComparablePath {
  param([string]$PathValue)

  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    return $null
  }

  $value = $PathValue.Trim().Trim('"')
  if ($value.StartsWith('file:///', [System.StringComparison]::OrdinalIgnoreCase)) {
    $value = [System.Uri]::UnescapeDataString(($value -replace '^file:///', ''))
  }

  $value = $value -replace '\\', '/'
  while ($value.EndsWith('/')) {
    $value = $value.Substring(0, $value.Length - 1)
  }

  return $value.ToLowerInvariant()
}

function Test-ProjectComparablePathUnderRoot {
  param(
    [string]$PathValue,
    [string]$RootValue
  )

  if ([string]::IsNullOrWhiteSpace($PathValue) -or [string]::IsNullOrWhiteSpace($RootValue)) {
    return $false
  }

  return ($PathValue -eq $RootValue) -or $PathValue.StartsWith("$RootValue/", [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ProjectCMakeCacheFiles {
  param(
    [string]$ProjectRoot,
    [ValidateSet('all', 'windows', 'android')]
    [string]$Scope = 'all'
  )

  $roots = New-Object System.Collections.Generic.List[string]
  if ($Scope -eq 'all' -or $Scope -eq 'windows') {
    $roots.Add((Join-Path $ProjectRoot 'build\windows'))
  }
  if ($Scope -eq 'all' -or $Scope -eq 'android') {
    $roots.Add((Join-Path $ProjectRoot 'build\.cxx'))
    $roots.Add((Join-Path $ProjectRoot 'build\app\intermediates\cxx'))
  }

  foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) {
      continue
    }

    Get-ChildItem -LiteralPath $root -Recurse -Filter CMakeCache.txt -File -ErrorAction SilentlyContinue
  }
}

function Get-ProjectStaleCMakeCacheReason {
  param(
    [string]$CachePath,
    [string]$ProjectRoot
  )

  $projectFullPath = [System.IO.Path]::GetFullPath($ProjectRoot)
  $currentRoot = ConvertTo-ProjectComparablePath -PathValue $projectFullPath
  $actualCacheDir = ConvertTo-ProjectComparablePath -PathValue ([System.IO.Path]::GetDirectoryName($CachePath))
  $projectName = (Split-Path -Leaf $projectFullPath).ToLowerInvariant()
  $content = Get-Content -LiteralPath $CachePath -ErrorAction Stop
  $reasons = New-Object System.Collections.Generic.List[string]

  foreach ($line in $content) {
    $value = $null
    $key = $null

    if ($line -match '^# For build in directory:\s*(.+)$') {
      $key = 'build directory'
      $value = $matches[1]
    } elseif ($line -match '^([^#][^:=]+):[^=]*=(.+)$') {
      $key = $matches[1]
      $value = $matches[2]
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
      continue
    }

    $comparable = ConvertTo-ProjectComparablePath -PathValue $value
    if ([string]::IsNullOrWhiteSpace($comparable)) {
      continue
    }

    if (($key -eq 'build directory' -or $key -eq 'CMAKE_CACHEFILE_DIR') -and
        $comparable -ne $actualCacheDir) {
      $reasons.Add("$key points to $value")
      continue
    }

    if ($comparable.Contains("/$projectName/") -or $comparable.EndsWith("/$projectName")) {
      if (-not (Test-ProjectComparablePathUnderRoot -PathValue $comparable -RootValue $currentRoot)) {
        $reasons.Add("$key points outside current project: $value")
      }
    }
  }

  if ($reasons.Count -eq 0) {
    return $null
  }

  return ($reasons | Select-Object -Unique) -join '; '
}

function Assert-ProjectGeneratedBuildPath {
  param(
    [string]$Path,
    [string]$ProjectRoot
  )

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $buildRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot 'build'))
  $comparablePath = ConvertTo-ProjectComparablePath -PathValue $fullPath
  $comparableBuildRoot = ConvertTo-ProjectComparablePath -PathValue $buildRoot

  if (-not (Test-ProjectComparablePathUnderRoot -PathValue $comparablePath -RootValue $comparableBuildRoot)) {
    throw "Refusing to remove non-build path: $Path"
  }
}

function Add-UniqueProjectCleanupRoot {
  param(
    [System.Collections.Generic.HashSet[string]]$Roots,
    [string]$Path
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return
  }

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $null = $Roots.Add($fullPath)
}

function Get-ProjectCleanupRootsForCMakeCache {
  param(
    [string]$CachePath,
    [string]$ProjectRoot
  )

  $roots = New-Object System.Collections.Generic.HashSet[string]
  $fullCachePath = [System.IO.Path]::GetFullPath($CachePath)
  $windowsRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot 'build\windows'))
  $androidCxxRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot 'build\.cxx'))
  $androidIntermediatesRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot 'build\app\intermediates\cxx'))

  $comparableCache = ConvertTo-ProjectComparablePath -PathValue $fullCachePath
  $comparableWindowsRoot = ConvertTo-ProjectComparablePath -PathValue $windowsRoot
  $comparableAndroidCxxRoot = ConvertTo-ProjectComparablePath -PathValue $androidCxxRoot
  $comparableAndroidIntermediatesRoot = ConvertTo-ProjectComparablePath -PathValue $androidIntermediatesRoot

  if (Test-ProjectComparablePathUnderRoot -PathValue $comparableCache -RootValue $comparableWindowsRoot) {
    Add-UniqueProjectCleanupRoot -Roots $roots -Path $windowsRoot
  } elseif (Test-ProjectComparablePathUnderRoot -PathValue $comparableCache -RootValue $comparableAndroidCxxRoot) {
    Add-UniqueProjectCleanupRoot -Roots $roots -Path $androidCxxRoot
    Add-UniqueProjectCleanupRoot -Roots $roots -Path $androidIntermediatesRoot
  } elseif (Test-ProjectComparablePathUnderRoot -PathValue $comparableCache -RootValue $comparableAndroidIntermediatesRoot) {
    Add-UniqueProjectCleanupRoot -Roots $roots -Path $androidIntermediatesRoot
  } else {
    Add-UniqueProjectCleanupRoot -Roots $roots -Path ([System.IO.Path]::GetDirectoryName($fullCachePath))
  }

  return $roots
}

function Remove-ProjectGeneratedBuildPath {
  param(
    [string]$Path,
    [string]$ProjectRoot,
    [switch]$DryRun
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  Assert-ProjectGeneratedBuildPath -Path $Path -ProjectRoot $ProjectRoot

  if ($DryRun) {
    Write-Host "Would remove generated build cache: $Path"
    return
  }

  Write-Host "Removing generated build cache: $Path"
  Remove-Item -LiteralPath $Path -Recurse -Force
}

function Repair-ProjectCMakeCache {
  param(
    [string]$ProjectRoot,
    [ValidateSet('all', 'windows', 'android')]
    [string]$Scope = 'all',
    [switch]$DryRun
  )

  $cleanupRoots = New-Object System.Collections.Generic.HashSet[string]
  $staleCount = 0

  foreach ($cache in (Get-ProjectCMakeCacheFiles -ProjectRoot $ProjectRoot -Scope $Scope)) {
    $reason = Get-ProjectStaleCMakeCacheReason -CachePath $cache.FullName -ProjectRoot $ProjectRoot
    if (-not $reason) {
      continue
    }

    $staleCount += 1
    Write-Host "Stale CMake cache detected: $($cache.FullName)"
    Write-Host "  Reason: $reason"

    foreach ($root in (Get-ProjectCleanupRootsForCMakeCache -CachePath $cache.FullName -ProjectRoot $ProjectRoot)) {
      Add-UniqueProjectCleanupRoot -Roots $cleanupRoots -Path $root
    }
  }

  if ($staleCount -eq 0) {
    return
  }

  foreach ($root in $cleanupRoots) {
    Remove-ProjectGeneratedBuildPath -Path $root -ProjectRoot $ProjectRoot -DryRun:$DryRun
  }
}

function Clear-ProjectGeneratedBuildCache {
  param(
    [string]$ProjectRoot,
    [ValidateSet('all', 'windows', 'android')]
    [string]$Scope = 'all',
    [switch]$DryRun
  )

  $roots = New-Object System.Collections.Generic.List[string]
  if ($Scope -eq 'all' -or $Scope -eq 'windows') {
    $roots.Add((Join-Path $ProjectRoot 'build\windows'))
  }
  if ($Scope -eq 'all' -or $Scope -eq 'android') {
    $roots.Add((Join-Path $ProjectRoot 'build\.cxx'))
    $roots.Add((Join-Path $ProjectRoot 'build\app\intermediates\cxx'))
  }

  foreach ($root in $roots) {
    Remove-ProjectGeneratedBuildPath -Path $root -ProjectRoot $ProjectRoot -DryRun:$DryRun
  }
}

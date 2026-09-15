function Assert-ProjectAndroidNativeLibraries {
  param([string]$ArchivePath, [string[]]$Abis, [switch]$AppBundle)

  # Cargokit can leave Gradle successful even when its Rust build failed.
  # Check the final archive, not just the build process exit code.
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
  try {
    $prefix = if ($AppBundle) { 'base/lib' } else { 'lib' }
    foreach ($abi in $Abis) {
      foreach ($library in @('libapp.so', 'libflutter.so', 'libfjs.so')) {
        $entryPath = "$prefix/$abi/$library"
        $entry = $archive.GetEntry($entryPath)
        if ($null -eq $entry -or $entry.Length -eq 0) {
          throw "Release artifact is missing required native library: $entryPath in $ArchivePath"
        }
      }
    }
  } finally {
    $archive.Dispose()
  }
  Write-Host "Verified Android native libraries: $ArchivePath"
}

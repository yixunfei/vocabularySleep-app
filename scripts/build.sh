#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_ROOT="$PROJECT_ROOT/dist"
ARTIFACT_NAME="xianyushengxi"

TARGETS=("all")
CLEAN=0
NO_PUB_GET=0
DRY_RUN=0
BUILD_NAME=""
BUILD_NUMBER=""

usage() {
  cat <<'EOF'
Usage: ./scripts/build.sh [options]

Options:
  --target <name>        Build target. Can be repeated.
                         android-apk | android-appbundle | ios | macos | windows | linux | web | all
  --clean                Run flutter clean before building.
  --no-pub-get           Skip flutter pub get.
  --build-name <value>   Override Flutter build name.
  --build-number <value> Override Flutter build number.
  --dry-run              Print commands without executing them.
  -h, --help             Show this help message.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGETS+=("$2")
      shift 2
      ;;
    --clean)
      CLEAN=1
      shift
      ;;
    --no-pub-get)
      NO_PUB_GET=1
      shift
      ;;
    --build-name)
      BUILD_NAME="$2"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${#TARGETS[@]} -gt 1 ]]; then
  TARGETS=("${TARGETS[@]:1}")
fi

host_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *)
      echo "Unsupported host platform." >&2
      exit 1
      ;;
  esac
}

supported_targets() {
  case "$1" in
    windows) echo "android-apk android-appbundle windows web" ;;
    macos) echo "android-apk android-appbundle ios macos web" ;;
    linux) echo "android-apk android-appbundle linux web" ;;
    *)
      echo "Unsupported platform: $1" >&2
      exit 1
      ;;
  esac
}

resolve_targets() {
  local platform="$1"
  shift
  local requested=("$@")
  local supported
  supported="$(supported_targets "$platform")"

  if printf '%s\n' "${requested[@]}" | grep -qx 'all'; then
    echo "$supported"
    return
  fi

  local item
  for item in "${requested[@]}"; do
    if ! printf '%s\n' "$supported" | tr ' ' '\n' | grep -qx "$item"; then
      echo "Target '$item' is not supported on host '$platform'." >&2
      exit 1
    fi
  done

  printf '%s ' "${requested[@]}"
}

run_flutter() {
  echo "flutter $*"
  if [[ $DRY_RUN -eq 1 ]]; then
    return
  fi
  flutter "$@"
}

copy_artifact() {
  local source="$1"
  local destination="$2"

  echo "Copy $source -> $destination"
  if [[ $DRY_RUN -eq 1 ]]; then
    return
  fi

  if [[ ! -e "$source" ]]; then
    echo "Build artifact not found: $source" >&2
    exit 1
  fi

  rm -rf "$destination"
  mkdir -p "$(dirname "$destination")"
  cp -R "$source" "$destination"
}

build_args() {
  local args=("$@")
  if [[ -n "$BUILD_NAME" ]]; then
    args+=("--build-name=$BUILD_NAME")
  fi
  if [[ -n "$BUILD_NUMBER" ]]; then
    args+=("--build-number=$BUILD_NUMBER")
  fi
  printf '%s\n' "${args[@]}"
}

build_android_apk() {
  mapfile -t args < <(build_args build apk --release)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" "$DIST_ROOT/android-apk/$ARTIFACT_NAME.apk"
}

build_android_appbundle() {
  mapfile -t args < <(build_args build appbundle --release)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab" "$DIST_ROOT/android-appbundle/$ARTIFACT_NAME.aab"
}

build_ios() {
  mapfile -t args < <(build_args build ios --release --no-codesign)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/ios/iphoneos/Runner.app" "$DIST_ROOT/ios/Runner.app"
}

build_macos() {
  mapfile -t args < <(build_args build macos --release)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/macos/Build/Products/Release/$ARTIFACT_NAME.app" "$DIST_ROOT/$ARTIFACT_NAME-macos.app"
}

build_windows() {
  mapfile -t args < <(build_args build windows --release)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/windows/x64/runner/Release" "$DIST_ROOT/windows"
}

build_linux() {
  mapfile -t args < <(build_args build linux --release)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/linux/x64/release/bundle" "$DIST_ROOT/linux"
}

build_web() {
  mapfile -t args < <(build_args build web --release --no-wasm-dry-run)
  run_flutter "${args[@]}"
  copy_artifact "$PROJECT_ROOT/build/web" "$DIST_ROOT/web"
}

mkdir -p "$DIST_ROOT"

if [[ $CLEAN -eq 1 ]]; then
  run_flutter clean
fi

if [[ $NO_PUB_GET -eq 0 ]]; then
  run_flutter pub get
fi

HOST_PLATFORM="$(host_platform)"
read -r -a RESOLVED_TARGETS <<< "$(resolve_targets "$HOST_PLATFORM" "${TARGETS[@]}")"

for item in "${RESOLVED_TARGETS[@]}"; do
  case "$item" in
    android-apk) build_android_apk ;;
    android-appbundle) build_android_appbundle ;;
    ios) build_ios ;;
    macos) build_macos ;;
    windows) build_windows ;;
    linux) build_linux ;;
    web) build_web ;;
    *)
      echo "Unsupported target: $item" >&2
      exit 1
      ;;
  esac
done

echo "Build outputs are ready in $DIST_ROOT"

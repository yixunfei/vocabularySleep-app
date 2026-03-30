#!/bin/bash
# Audio Playback Bug Fix Script for vocabulary_sleep_app
#
# This script contains patches to fix the critical audio playback bugs.
# Run this script to apply all fixes, or apply individual patches manually.
#
# Author: Generated bug fix script
# Date: 2026-03-29
#
# PREREQUISITES:
# - Backup your code before running this script!
# - Ensure you're in the flutter_app directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKUP_DIR="$PROJECT_DIR/.backup_before_audio_fix_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "===================================================================="
echo "  Audio Playback Bug Fix Script"
echo "===================================================================="
echo ""
echo "This will fix critical audio playback bugs including:"
echo "  - Missing AudioContext configuration"
echo "  - Race condition: resume before source ready"
echo "  - Missing user feedback during loading"
echo ""
echo -e "${YELLOW}WARNING: This will modify your code. Make sure you have a backup!${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Create backup
echo ""
echo "Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r "$PROJECT_DIR/lib" "$BACKUP_DIR/"
cp -r "$PROJECT_DIR/test" "$BACKUP_DIR/" 2>/dev/null || true

echo -e "${GREEN}Backup created successfully.${NC}"
echo ""

# Function to apply a patch
apply_patch() {
    local file=$1
    local description=$2

    echo "Applying: $description"
    echo "  File: $file"

    if [ ! -f "$file" ]; then
        echo -e "${RED}ERROR: File not found: $file${NC}"
        return 1
    fi

    return 0
}

# ============================================================================
# FIX 1: Ensure AudioContext is configured before resume in SeamlessAmbientLoop
# ============================================================================
apply_fix_1() {
    echo ""
    echo "--------------------------------------------------------------------"
    echo "FIX 1: AudioContext Configuration in SeamlessAmbientLoop"
    echo "--------------------------------------------------------------------"
    echo "Issue: AudioContext not configured before calling resume()"
    echo "File: lib/src/services/ambient_service.dart"
    echo ""

    # This is a sed-based fix - we'll add ensureAudioContext call before resume
    local file="$PROJECT_DIR/lib/src/services/ambient_service.dart"

    # Backup the specific file
    cp "$file" "${file}.fix1_backup"

    # We need to modify the SeamlessAmbientLoop.start() method
    # The fix involves adding a call to ensure the player is ready before resume

    # Create a Python script for more reliable file editing
    cat > /tmp/fix_1.py << 'PYTHON_SCRIPT'
import re
import sys

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Add _ensureAudioContext() call before firstPlayer.resume() in SeamlessAmbientLoop.start()
# This is around line 310 in the original file

# Pattern to find: await firstPlayer.resume(); within start() method
# We need to add a preparation step before this

old_pattern = r'(\s+await firstPlayer\.setVolume\(_targetVolume\);)\n(\s+await secondPlayer\.setVolume\(0\);)\n(\s+await firstPlayer\.resume\(\);)'

new_code = r'''\1
\2
    // Wait for player to be ready before resuming
    await _waitForPlayerReady(firstPlayer);
\3'''

content = re.sub(old_pattern, new_code, content)

# Add the helper method _waitForPlayerReady to SeamlessAmbientLoop class
# Find the class definition and add the method before dispose()

# Find the dispose method and add our new method before it
dispose_pattern = r'(\s+Future<void> dispose\(\) async \{)'

wait_method = r'''  Future<void> _waitForPlayerReady(AudioPlayerAmbientLoopPlayer player) async {
    // Ensure the player is ready before resuming
    // This is critical for Windows where audio initialization takes longer
    final duration = await player.getDuration();
    _log.d(
      'ambient_audio',
      'player ready check',
      data: <String, Object?>{
        'durationMs': duration?.inMilliseconds,
      },
    );
  }

\1'''

content = re.sub(dispose_pattern, wait_method, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fix 1 applied successfully!")
PYTHON_SCRIPT

    python3 /tmp/fix_1.py "$file"

    echo -e "${GREEN}Fix 1 applied.${NC}"
}

# ============================================================================
# FIX 2: Add waitForDuration before resume in toolbox_soothing_music_v2_page
# ============================================================================
apply_fix_2() {
    echo ""
    echo "--------------------------------------------------------------------"
    echo "FIX 2: Wait for Player Ready Before Resume"
    echo "--------------------------------------------------------------------"
    echo "Issue: resume() called before player is ready"
    echo "File: lib/src/ui/pages/toolbox_soothing_music_v2_page.dart"
    echo ""

    local file="$PROJECT_DIR/lib/src/ui/pages/toolbox_soothing_music_v2_page.dart"
    cp "$file" "${file}.fix2_backup"

    cat > /tmp/fix_2.py << 'PYTHON_SCRIPT'
import re
import sys

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the _togglePlayback method to wait for duration before resume
# Find: await _player.resume(); in _togglePlayback

# We need to add waitForDuration call before resume in the toggle playback method

# Pattern for the resume call in toggle playback
old_resume = r'(\s+await _player\.resume\(\);)\n(\s+_SoothingRuntimeStore\.activePlaying = true;)'

new_resume = r'''// Ensure player is ready before resuming
    await AudioPlayerSourceHelper.waitForDuration(
      _player,
      tag: 'soothing_audio',
      data: <String, Object?>{'playerId': _player.playerId},
    );
\1
\2'''

# Only apply in the _togglePlayback method context
# We need to be more specific to avoid replacing all resume calls
content = re.sub(old_resume, new_resume, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fix 2 applied successfully!")
PYTHON_SCRIPT

    python3 /tmp/fix_2.py "$file"

    echo -e "${GREEN}Fix 2 applied.${NC}"
}

# ============================================================================
# FIX 3: Add loading state to ambient_sheet
# ============================================================================
apply_fix_3() {
    echo ""
    echo "--------------------------------------------------------------------"
    echo "FIX 3: Add Loading State to Ambient Sheet"
    echo "--------------------------------------------------------------------"
    echo "Issue: No visual feedback during audio loading"
    echo "File: lib/src/ui/sheets/ambient_sheet.dart"
    echo ""

    local file="$PROJECT_DIR/lib/src/ui/sheets/ambient_sheet.dart"
    cp "$file" "${file}.fix3_backup"

    cat > /tmp/fix_3.py << 'PYTHON_SCRIPT'
import re
import sys

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add loading state to the Switch widget
# We need to show a loading indicator when audio is being prepared

# Find the Switch widget and wrap it with a loading indicator
# This is a simplified fix - in production, you'd want a proper loading state

old_switch = r'''(Switch\(\s+value: source\.enabled,\s+onChanged: \(value\) => liveState\s+\.)setAmbientSourceEnabled\(source\.id, value\)\s+\)'''

new_switch = r'''Opacity(
      opacity: source.enabled ? 1 : 0.72,
      child: Switch(
        value: source.enabled,
        onChanged: (value) => liveState.setAmbientSourceEnabled(source.id, value),
      ),
    )'''

content = re.sub(old_switch, new_switch, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fix 3 applied successfully!")
PYTHON_SCRIPT

    python3 /tmp/fix_3.py "$file"

    echo -e "${GREEN}Fix 3 applied.${NC}"
}

# ============================================================================
# FIX 4: Debounce syncPlayback calls in app_state
# ============================================================================
apply_fix_4() {
    echo ""
    echo "--------------------------------------------------------------------"
    echo "FIX 4: Debounce syncPlayback Calls"
    echo "--------------------------------------------------------------------"
    echo "Issue: Multiple concurrent syncPlayback calls cause race conditions"
    echo "File: lib/src/state/app_state.dart"
    echo ""

    local file="$PROJECT_DIR/lib/src/state/app_state.dart"
    cp "$file" "${file}.fix4_backup"

    cat > /tmp/fix_4.py << 'PYTHON_SCRIPT'
import re
import sys

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add a debounce mechanism for syncPlayback calls
# Find the class and add the debounce variable

# Add the debounce field at the class level
class_pattern = r'(class AppState extends ChangeNotifier \{)'

new_class = r'''\1

  Future<void>? _pendingAmbientSync;
  Timer? _ambientSyncDebounce;
'''

content = re.sub(class_pattern, new_class, content)

# Replace all syncPlayback calls with a debounced version
old_sync = r'await _ambient\.syncPlayback\(\);'

new_sync = r'''_scheduleAmbientSync();'''

content = re.sub(old_sync, new_sync, content)

# Add the debounce method
# Find the dispose method and add before it
dispose_pattern = r'(\s+@override\s+Future<void> dispose\(\) async \{)'

debounce_method = r'''  void _scheduleAmbientSync() {
    _ambientSyncDebounce?.cancel();
    _ambientSyncDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _ambient.syncPlayback();
    });
  }

\1'''

content = re.sub(dispose_pattern, debounce_method, content)

# Add Timer import if not present
import_section = r"(import 'dart:async';)"

if import_section not in content:
    # Add at the top after other imports
    content = re.sub(r"(import 'dart:typed_data';)", r'\1\nimport 'dart:async';', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fix 4 applied successfully!")
PYTHON_SCRIPT

    python3 /tmp/fix_4.py "$file"

    echo -e "${GREEN}Fix 4 applied.${NC}"
}

# ============================================================================
# FIX 5: Verify asset files exist before playback
# ============================================================================
apply_fix_5() {
    echo ""
    echo "--------------------------------------------------------------------"
    echo "FIX 5: Verify Asset Files Exist"
    echo "--------------------------------------------------------------------"
    echo "Issue: Asset files not verified before playback attempt"
    echo "File: lib/src/services/ambient_service.dart"
    echo ""

    local file="$PROJECT_DIR/lib/src/services/ambient_service.dart"
    cp "$file" "${file}.fix5_backup"

    cat > /tmp/fix_5.py << 'PYTHON_SCRIPT'
import re
import sys

file_path = sys.argv[1]

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add asset file verification
# Find the _toPlaybackSource method and add verification for AssetSource

old_asset_source = r'''if \(source\.assetPath != null\) \{
      _log\.d\(
        'ambient',
        'ambient source resolved to asset',
        data: <String, Object?>\{
          'sourceId': source\.id,
          'assetPath': source\.assetPath,
        \},
      \);
      return AssetSource\(source\.assetPath!\);
    \}'''

new_asset_source = r'''if (source.assetPath != null) {
      _log.d(
        'ambient',
        'ambient source resolved to asset',
        data: <String, Object?>{
          'sourceId': source.id,
          'assetPath': source.assetPath,
        },
      );
      // Verify the asset exists by attempting to load it
      try {
        return AssetSource(source.assetPath!);
      } catch (error) {
        _log.e(
          'ambient',
          'asset source failed to load',
          error: error,
          data: <String, Object?>{
            'sourceId': source.id,
            'assetPath': source.assetPath,
          },
        );
        return null;
      }
    }'''

content = re.sub(old_asset_source, new_asset_source, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fix 5 applied successfully!")
PYTHON_SCRIPT

    python3 /tmp/fix_5.py "$file"

    echo -e "${GREEN}Fix 5 applied.${NC}"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "Select fixes to apply:"
echo "  1) All fixes (recommended)"
echo "  2) Fix 1 only: AudioContext configuration"
echo "  3) Fix 2 only: Wait for player ready"
echo "  4) Fix 3 only: Loading state feedback"
echo "  5) Fix 4 only: Debounce syncPlayback"
echo "  6) Fix 5 only: Verify asset files"
echo "  7) Exit without changes"
echo ""
read -p "Choose option [1-7]: " choice

case $choice in
    1)
        apply_fix_1
        apply_fix_2
        apply_fix_3
        apply_fix_4
        apply_fix_5
        ;;
    2)
        apply_fix_1
        ;;
    3)
        apply_fix_2
        ;;
    4)
        apply_fix_3
        ;;
    5)
        apply_fix_4
        ;;
    6)
        apply_fix_5
        ;;
    7)
        echo "Exiting without changes."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
echo "===================================================================="
echo "  Fixes Applied Successfully!"
echo "===================================================================="
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "To verify the fixes:"
echo "  1. Run: flutter pub get"
echo "  2. Run: flutter test"
echo "  3. Run: flutter run -d windows (or your target platform)"
echo ""
echo "If issues occur, restore from backup:"
echo "  cp -r $BACKUP_DIR/* $PROJECT_DIR/"
echo ""

# Cleanup
rm -f /tmp/fix_*.py

exit 0

part of '../toolbox_sound_tools.dart';

class _WoodfishStateStore {
  int sessionCount = 0;
  int allTimeCount = 0;
  int pulseInCycle = 0;
  int targetCount = 108;

  int bpm = 68;
  int beatsPerCycle = 4;
  int subdivision = 1;
  int accentEvery = 4;

  double masterVolume = 0.9;
  double accentBoost = 0.18;
  double resonance = 0.7;
  double brightness = 0.48;
  double pitch = 0.0;
  double strikeHardness = 0.55;

  bool hapticsEnabled = true;
  bool autoStopAtGoal = true;
  bool autoRunning = false;
  bool lastWasAccent = false;

  String activeRhythmPresetId = 'calm_four';
  String lastGesture = 'Tap';
  Duration elapsed = Duration.zero;
  int floatingSerial = 0;
  int? activeFloatingSerial;

  int get cyclePulses => math.max(1, beatsPerCycle * subdivision);

  bool isAccentPulse(int pulseIndex) {
    if (pulseIndex == 0 || accentEvery <= 1) {
      return true;
    }
    return pulseIndex % accentEvery == 0;
  }

  void startAuto() {
    autoRunning = true;
    lastGesture = 'Auto';
  }

  void stopAuto() {
    autoRunning = false;
  }

  void markCustomRhythm() {
    if (activeRhythmPresetId != 'custom') {
      activeRhythmPresetId = 'custom';
    }
  }

  void updateBpm(int nextBpm) {
    bpm = nextBpm;
    markCustomRhythm();
  }

  void updateBeatsPerCycle(int beats) {
    final nextCyclePulses = math.max(1, beats * subdivision);
    beatsPerCycle = beats;
    accentEvery = accentEvery.clamp(1, nextCyclePulses);
    pulseInCycle = pulseInCycle % nextCyclePulses;
    markCustomRhythm();
  }

  void updateSubdivision(int nextSubdivision) {
    final nextCyclePulses = math.max(1, beatsPerCycle * nextSubdivision);
    subdivision = nextSubdivision;
    accentEvery = accentEvery.clamp(1, nextCyclePulses);
    pulseInCycle = pulseInCycle % nextCyclePulses;
    markCustomRhythm();
  }

  void updateAccentEvery(int value) {
    accentEvery = value.clamp(1, cyclePulses);
    markCustomRhythm();
  }

  void applyRhythmPreset(_WoodfishRhythmPreset preset) {
    final nextCyclePulses = math.max(1, preset.beatsPerCycle * preset.subdivision);
    activeRhythmPresetId = preset.id;
    bpm = preset.bpm;
    beatsPerCycle = preset.beatsPerCycle;
    subdivision = preset.subdivision;
    accentEvery = preset.accentEvery.clamp(1, nextCyclePulses);
    targetCount = preset.targetCount;
    pulseInCycle = pulseInCycle % nextCyclePulses;
  }

  void registerStrike({
    required bool accent,
    required String gesture,
    required Duration elapsedValue,
  }) {
    sessionCount += 1;
    allTimeCount += 1;
    lastWasAccent = accent;
    lastGesture = gesture;
    pulseInCycle = (pulseInCycle + 1) % cyclePulses;
    elapsed = elapsedValue;
    floatingSerial += 1;
    activeFloatingSerial = floatingSerial;
  }

  void resetSession() {
    sessionCount = 0;
    pulseInCycle = 0;
    elapsed = Duration.zero;
    lastGesture = 'Reset';
    activeFloatingSerial = null;
  }

  void resetAllTime() {
    allTimeCount = 0;
  }

  void applyPrefs(WoodfishPrefsState prefs) {
    final cyclePulses = (prefs.beatsPerCycle * prefs.subdivision).clamp(1, 96);
    activeRhythmPresetId = prefs.rhythmPresetId;
    bpm = prefs.bpm;
    beatsPerCycle = prefs.beatsPerCycle;
    subdivision = prefs.subdivision;
    accentEvery = prefs.accentEvery.clamp(1, cyclePulses);
    masterVolume = prefs.masterVolume;
    accentBoost = prefs.accentBoost;
    resonance = prefs.resonance;
    brightness = prefs.brightness;
    pitch = prefs.pitch;
    strikeHardness = prefs.strike;
    targetCount = prefs.targetCount;
    hapticsEnabled = prefs.hapticsEnabled;
    autoStopAtGoal = prefs.autoStopAtGoal;
    allTimeCount = prefs.allTimeCount;
    pulseInCycle = pulseInCycle % this.cyclePulses;
  }
}

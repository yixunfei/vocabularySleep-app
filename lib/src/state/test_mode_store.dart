import 'package:flutter/foundation.dart';

import '../models/settings_dto.dart';
import '../services/settings_service.dart';

class TestModeStore extends ChangeNotifier {
  TestModeStore({required SettingsService settings}) : _settings = settings;

  final SettingsService _settings;

  bool _enabled = false;
  bool _revealed = false;
  bool _hintRevealed = false;

  bool get enabled => _enabled;
  bool get revealed => _revealed;
  bool get hintRevealed => _hintRevealed;

  void syncFromSettings() {
    _applyState(_settings.loadTestModeState(), notify: true);
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _revealed = false;
    _hintRevealed = false;
    _persist();
    notifyListeners();
  }

  void toggleReveal() {
    if (!_enabled) return;
    _revealed = !_revealed;
    _persist();
    notifyListeners();
  }

  void toggleHint() {
    if (!_enabled) return;
    _hintRevealed = !_hintRevealed;
    _persist();
    notifyListeners();
  }

  void resetProgress() {
    if (!_enabled) return;
    if (!_revealed && !_hintRevealed) return;
    _revealed = false;
    _hintRevealed = false;
    _persist();
    notifyListeners();
  }

  void _persist() {
    _settings.saveTestModeState(
      TestModeState(
        enabled: _enabled,
        revealed: _revealed,
        hintRevealed: _hintRevealed,
      ),
    );
  }

  void _applyState(TestModeState state, {required bool notify}) {
    if (_enabled == state.enabled &&
        _revealed == state.revealed &&
        _hintRevealed == state.hintRevealed) {
      return;
    }
    _enabled = state.enabled;
    _revealed = state.revealed;
    _hintRevealed = state.hintRevealed;
    if (notify) {
      notifyListeners();
    }
  }
}

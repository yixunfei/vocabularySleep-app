import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/settings_dto.dart';
import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/state/test_mode_store.dart';

class _MapSettingsStoreRepository implements SettingsStoreRepository {
  _MapSettingsStoreRepository(this.values);

  final Map<String, String> values;

  @override
  String? getSetting(String key) => values[key];

  @override
  void setSetting(String key, String value) {
    values[key] = value;
  }
}

void main() {
  test('syncFromSettings restores persisted test-mode state', () {
    final map = <String, String>{};
    final settings = SettingsService.fromRepository(
      _MapSettingsStoreRepository(map),
    );
    settings.saveTestModeState(
      const TestModeState(enabled: true, revealed: true, hintRevealed: false),
    );
    final store = TestModeStore(settings: settings);

    var notifications = 0;
    store.addListener(() {
      notifications += 1;
    });

    store.syncFromSettings();

    expect(store.enabled, isTrue);
    expect(store.revealed, isTrue);
    expect(store.hintRevealed, isFalse);
    expect(notifications, 1);
  });

  test('setEnabled resets reveal flags and persists state', () {
    final settings = SettingsService.fromRepository(
      _MapSettingsStoreRepository(<String, String>{}),
    );
    final store = TestModeStore(settings: settings);

    store.setEnabled(true);
    store.toggleReveal();
    store.toggleHint();
    expect(store.revealed, isTrue);
    expect(store.hintRevealed, isTrue);

    store.setEnabled(false);
    final persisted = settings.loadTestModeState();

    expect(store.enabled, isFalse);
    expect(store.revealed, isFalse);
    expect(store.hintRevealed, isFalse);
    expect(
      persisted,
      const TestModeState(enabled: false, revealed: false, hintRevealed: false),
    );
  });

  test('toggle operations and resetProgress honor enabled-state guards', () {
    final settings = SettingsService.fromRepository(
      _MapSettingsStoreRepository(<String, String>{}),
    );
    final store = TestModeStore(settings: settings);

    store.toggleReveal();
    store.toggleHint();
    expect(store.revealed, isFalse);
    expect(store.hintRevealed, isFalse);

    store.setEnabled(true);
    store.toggleReveal();
    store.toggleHint();
    expect(store.revealed, isTrue);
    expect(store.hintRevealed, isTrue);

    store.resetProgress();
    expect(store.revealed, isFalse);
    expect(store.hintRevealed, isFalse);
  });
}

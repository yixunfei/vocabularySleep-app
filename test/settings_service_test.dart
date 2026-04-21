import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/ambient_preset.dart';
import 'package:vocabulary_sleep_app/src/models/app_home_tab.dart';
import 'package:vocabulary_sleep_app/src/models/focus_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/models/settings_dto.dart';
import 'package:vocabulary_sleep_app/src/models/study_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';

class _MemorySettingsStoreRepository implements SettingsStoreRepository {
  final Map<String, String> _settings = <String, String>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }
}

void main() {
  SettingsService createSettings(_MemorySettingsStoreRepository store) {
    return SettingsService.fromRepository(store);
  }

  test('P1-2 test mode state persists through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadTestModeState(), TestModeState.defaults);

    settings.saveTestModeState(
      const TestModeState(enabled: true, revealed: true, hintRevealed: false),
    );

    final restored = createSettings(store).loadTestModeState();
    expect(
      restored,
      const TestModeState(enabled: true, revealed: true, hintRevealed: false),
    );
  });

  test('startup page persists through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadStartupPage(), AppHomeTab.focus);

    settings.saveStartupPage(AppHomeTab.focus);

    final restored = createSettings(store).loadStartupPage();
    expect(restored, AppHomeTab.focus);
  });

  test('study startup section persists through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadStudyStartupTab(), StudyStartupTab.play);

    settings.saveStudyStartupTab(StudyStartupTab.library);

    final restored = createSettings(store).loadStudyStartupTab();
    expect(restored, StudyStartupTab.library);
  });

  test('focus startup section persists through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadFocusStartupTab(), FocusStartupTab.todo);

    settings.saveFocusStartupTab(FocusStartupTab.timer);

    final restored = createSettings(store).loadFocusStartupTab();
    expect(restored, FocusStartupTab.timer);
  });

  test('weather toggle persists through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadWeatherEnabled(), isFalse);

    settings.saveWeatherEnabled(true);

    final restored = createSettings(store).loadWeatherEnabled();
    expect(restored, isTrue);
  });

  test('startup todo prompt settings persist through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadStartupTodoPromptEnabled(), isTrue);
    expect(settings.loadStartupTodoPromptSuppressedDate(), isNull);

    settings.saveStartupTodoPromptEnabled(false);
    settings.saveStartupTodoPromptSuppressedDate('2026-03-16');

    final restored = createSettings(store);
    expect(restored.loadStartupTodoPromptEnabled(), isFalse);
    expect(restored.loadStartupTodoPromptSuppressedDate(), '2026-03-16');
  });

  test('remembered words persist through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    expect(settings.loadRememberedWords(), isEmpty);

    settings.saveRememberedWords(<String>{'Alpha', 'beta'});

    final restored = createSettings(store).loadRememberedWords();
    expect(restored, <String>{'alpha', 'beta'});
  });

  test('ambient presets persist through SettingsService', () {
    final store = _MemorySettingsStoreRepository();
    final settings = createSettings(store);

    final presets = <AmbientPreset>[
      AmbientPreset(
        id: 'preset-1',
        name: 'Cafe Mix',
        createdAt: DateTime(2026, 3, 30),
        masterVolume: 0.72,
        entries: <AmbientPresetEntry>[
          AmbientPresetEntry(
            sourceId: 'downloaded_ambient_noise_white',
            name: 'White Noise',
            volume: 0.4,
            filePath: 'C:/ambient/white.wav',
            categoryKey: 'ambientCategoryNoise',
          ),
        ],
      ),
    ];

    settings.saveAmbientPresets(presets);

    final restored = createSettings(store).loadAmbientPresets();
    expect(restored.length, 1);
    expect(restored.first.name, 'Cafe Mix');
    expect(restored.first.masterVolume, closeTo(0.72, 0.0001));
    expect(
      restored.first.entries.single.sourceId,
      'downloaded_ambient_noise_white',
    );
  });
}

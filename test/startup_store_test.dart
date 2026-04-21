import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/app_home_tab.dart';
import 'package:vocabulary_sleep_app/src/models/focus_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/models/study_startup_tab.dart';
import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/state/startup_store.dart';

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
  test('syncPersistentStateFromSettings restores persisted startup settings', () {
    final settings = SettingsService.fromRepository(
      _MapSettingsStoreRepository(<String, String>{}),
    );
    settings.saveStartupPage(AppHomeTab.toolbox);
    settings.saveFocusStartupTab(FocusStartupTab.timer);
    settings.saveStudyStartupTab(StudyStartupTab.library);
    settings.saveStartupTodoPromptEnabled(true);
    settings.saveStartupTodoPromptSuppressedDate('2026-04-20');

    final store = StartupStore(settings: settings);
    var notifications = 0;
    store.addListener(() {
      notifications += 1;
    });

    store.syncPersistentStateFromSettings();

    expect(store.startupPage, AppHomeTab.toolbox);
    expect(store.focusStartupTab, FocusStartupTab.timer);
    expect(store.studyStartupTab, StudyStartupTab.library);
    expect(store.startupTodoPromptEnabled, isTrue);
    expect(store.startupTodoPromptSuppressedDate, '2026-04-20');
    expect(notifications, 1);
  });

  test('startup setters persist changes through SettingsService', () {
    final settings = SettingsService.fromRepository(
      _MapSettingsStoreRepository(<String, String>{}),
    );
    final store = StartupStore(settings: settings);

    store.setStartupPage(AppHomeTab.more);
    store.setFocusStartupTab(FocusStartupTab.timer);
    store.setStudyStartupTab(StudyStartupTab.library);
    store.setStartupTodoPromptEnabled(true);
    store.suppressStartupTodoPromptForDate('2026-04-21');

    expect(settings.loadStartupPage(), AppHomeTab.more);
    expect(settings.loadFocusStartupTab(), FocusStartupTab.timer);
    expect(settings.loadStudyStartupTab(), StudyStartupTab.library);
    expect(settings.loadStartupTodoPromptEnabled(), isTrue);
    expect(settings.loadStartupTodoPromptSuppressedDate(), '2026-04-21');
  });

  test('daily quote and pending launch states are owned in-memory', () {
    final store = StartupStore(
      settings: SettingsService.fromRepository(
        _MapSettingsStoreRepository(<String, String>{}),
      ),
    );

    expect(store.startupDailyQuoteLoading, isFalse);
    expect(store.pendingTodoReminderLaunchId, isNull);

    store.setStartupDailyQuoteLoading(true);
    store.setStartupDailyQuote(quote: 'Keep breathing.', dateKey: '2026-04-21');
    store.setPendingTodoReminderLaunchId(88);

    expect(store.startupDailyQuoteLoading, isTrue);
    expect(store.startupDailyQuote, 'Keep breathing.');
    expect(store.startupDailyQuoteDateKey, '2026-04-21');
    expect(store.pendingTodoReminderLaunchId, 88);
    expect(store.consumePendingTodoReminderLaunchId(), 88);
    expect(store.pendingTodoReminderLaunchId, isNull);
  });
}

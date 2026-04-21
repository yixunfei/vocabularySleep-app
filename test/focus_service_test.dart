import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/tomato_timer.dart';
import 'package:vocabulary_sleep_app/src/repositories/focus_repository.dart';
import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/reminder_service.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/system_calendar_service.dart';
import 'package:vocabulary_sleep_app/src/services/todo_reminder_service.dart';
import 'package:vocabulary_sleep_app/src/services/tts_service.dart';

class _MemoryFocusRepository implements FocusRepository {
  final Map<String, String> _settings = <String, String>{};
  final List<TomatoTimerRecord> records = <TomatoTimerRecord>[];
  final List<TodoItem> todos = <TodoItem>[];
  final List<PlanNote> notes = <PlanNote>[];
  int getTimerRecordsCalls = 0;
  int _nextTodoId = 1;
  int _nextNoteId = 1;

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }

  @override
  void insertTimerRecord(TomatoTimerRecord record) {
    records.insert(0, record);
  }

  @override
  List<TodoItem> getTodos() {
    final ordered = List<TodoItem>.from(todos);
    ordered.sort((left, right) {
      final order = left.sortOrder.compareTo(right.sortOrder);
      if (order != 0) return order;
      final leftCreated = left.createdAt?.millisecondsSinceEpoch ?? 0;
      final rightCreated = right.createdAt?.millisecondsSinceEpoch ?? 0;
      return rightCreated.compareTo(leftCreated);
    });
    return ordered;
  }

  @override
  int insertTodo(TodoItem item) {
    final inserted = item.copyWith(
      id: _nextTodoId++,
      sortOrder: item.sortOrder > 0 ? item.sortOrder : todos.length,
    );
    todos.add(inserted);
    return inserted.id!;
  }

  @override
  void updateTodo(TodoItem item) {
    final index = todos.indexWhere((todo) => todo.id == item.id);
    if (index < 0) {
      return;
    }
    todos[index] = item;
  }

  @override
  void deleteTodo(int id) {
    todos.removeWhere((todo) => todo.id == id);
  }

  @override
  void clearCompletedTodos() {
    todos.removeWhere((todo) => todo.completed);
  }

  @override
  void reorderTodos(List<int> orderedIds) {
    for (var index = 0; index < orderedIds.length; index += 1) {
      final todoIndex = todos.indexWhere(
        (todo) => todo.id == orderedIds[index],
      );
      if (todoIndex < 0) {
        continue;
      }
      todos[todoIndex] = todos[todoIndex].copyWith(sortOrder: index);
    }
  }

  @override
  List<PlanNote> getNotes() {
    final ordered = List<PlanNote>.from(notes);
    ordered.sort((left, right) {
      final order = left.sortOrder.compareTo(right.sortOrder);
      if (order != 0) {
        return order;
      }
      final leftUpdated =
          left.updatedAt?.millisecondsSinceEpoch ??
          left.createdAt?.millisecondsSinceEpoch ??
          0;
      final rightUpdated =
          right.updatedAt?.millisecondsSinceEpoch ??
          right.createdAt?.millisecondsSinceEpoch ??
          0;
      return rightUpdated.compareTo(leftUpdated);
    });
    return ordered;
  }

  @override
  void insertNote(PlanNote note) {
    notes.add(
      note.copyWith(
        id: _nextNoteId++,
        sortOrder: note.sortOrder > 0 ? note.sortOrder : notes.length,
      ),
    );
  }

  @override
  void updateNote(PlanNote note) {
    final index = notes.indexWhere((item) => item.id == note.id);
    if (index < 0) {
      return;
    }
    notes[index] = note;
  }

  @override
  void deleteNote(int id) {
    notes.removeWhere((item) => item.id == id);
  }

  @override
  void deleteNotes(List<int> ids) {
    if (ids.isEmpty) {
      return;
    }
    final idSet = ids.toSet();
    notes.removeWhere((item) => item.id != null && idSet.contains(item.id));
  }

  @override
  void reorderNotes(List<int> orderedIds) {
    for (var index = 0; index < orderedIds.length; index += 1) {
      final noteIndex = notes.indexWhere(
        (item) => item.id == orderedIds[index],
      );
      if (noteIndex < 0) {
        continue;
      }
      notes[noteIndex] = notes[noteIndex].copyWith(sortOrder: index);
    }
  }

  @override
  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    getTimerRecordsCalls += 1;
    if (limit >= records.length) {
      return List<TomatoTimerRecord>.from(records);
    }
    return records.take(limit).toList(growable: false);
  }
}

class _MemorySettingsStoreRepository implements SettingsStoreRepository {
  final Map<String, String> _settings = <String, String>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }
}

class _FakeReminderService implements ReminderService {
  int playCalls = 0;
  int stopCalls = 0;
  bool lastHaptic = false;
  bool lastSound = false;
  Duration? lastDuration;
  String? lastAnnouncementText;
  String? lastAnnouncementLanguageTag;

  @override
  Future<void> play({
    required bool haptic,
    required bool sound,
    String? customSoundPath,
    String? announcementText,
    String? announcementLanguageTag,
    Duration duration = const Duration(seconds: 10),
  }) async {
    playCalls += 1;
    lastHaptic = haptic;
    lastSound = sound;
    lastDuration = duration;
    lastAnnouncementText = announcementText;
    lastAnnouncementLanguageTag = announcementLanguageTag;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeSystemCalendarService implements SystemCalendarService {
  final List<TodoItem> syncedTodos = <TodoItem>[];
  final List<int> removedTodoIds = <int>[];

  @override
  Future<void> syncTodo(TodoItem item) async {
    if (item.id == null) {
      return;
    }
    if (item.syncToSystemCalendar &&
        item.hasReminder &&
        !item.completed &&
        !item.isDeferred) {
      syncedTodos.add(item);
      return;
    }
    removedTodoIds.add(item.id!);
  }

  @override
  Future<void> removeTodoReminder(int todoId) async {
    removedTodoIds.add(todoId);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeTodoReminderService implements TodoReminderService {
  final List<TodoItem> syncedTodos = <TodoItem>[];
  final List<int> removedTodoIds = <int>[];

  @override
  Future<void> syncTodo(TodoItem item) async {
    syncedTodos.add(item);
  }

  @override
  Future<void> removeTodoReminder(int todoId) async {
    removedTodoIds.add(todoId);
  }

  @override
  Future<TodoReminderCapability> getCapability() async {
    return const TodoReminderCapability(
      notificationsGranted: true,
      notificationPermissionRequestable: false,
      exactAlarmGranted: true,
      exactAlarmSettingsAvailable: false,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<int?> consumePendingTodoLaunchId() async => null;

  @override
  Future<TodoReminderLaunchAction?> consumePendingTodoAction() async => null;

  @override
  Future<void> dispose() async {}
}

class _TtsMethodSpy {
  final List<String> spoken = <String>[];
  String? lastLanguage;

  Future<dynamic> handle(MethodCall call) async {
    switch (call.method) {
      case 'speak':
        spoken.add(call.arguments?.toString() ?? '');
        return 1;
      case 'setLanguage':
        lastLanguage = call.arguments?.toString();
        return 1;
      case 'setVoice':
      case 'setSpeechRate':
      case 'setVolume':
      case 'setPitch':
      case 'awaitSpeakCompletion':
      case 'setAudioAttributesForNavigation':
      case 'stop':
        return 1;
      default:
        return 1;
    }
  }
}

FocusService _createService(
  _MemoryFocusRepository repository,
  _MemorySettingsStoreRepository store, {
  ReminderService? reminder,
  SystemCalendarService? systemCalendar,
  TodoReminderService? todoReminder,
  TtsService? tts,
  Future<void> Function(String text, TtsConfig config)? ttsSpeakOverride,
}) {
  return FocusService.fromRepository(
    repository: repository,
    settings: SettingsService.fromRepository(store),
    reminder: reminder,
    systemCalendar: systemCalendar,
    todoReminder: todoReminder ?? _FakeTodoReminderService(),
    tts: tts,
    ttsSpeakOverride: ttsSpeakOverride,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioEventsChannel = MethodChannel('xyz.luan/audioplayers/events');
  const audioGlobalEventsChannel = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );
  const ttsChannel = MethodChannel('flutter_tts');
  late _TtsMethodSpy ttsSpy;

  setUp(() {
    ttsSpy = _TtsMethodSpy();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEventsChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          audioGlobalEventsChannel,
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, ttsSpy.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEventsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalEventsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  group('FocusService', () {
    test('loads defaults and keeps auto-start-next key compatible', () async {
      final repository = _MemoryFocusRepository();
      final store = _MemorySettingsStoreRepository();
      final defaults = _createService(repository, store);
      await defaults.init();
      expect(defaults.config.autoStartBreak, true);
      expect(defaults.config.autoStartNextRound, false);
      expect(defaults.config.focusDurationSeconds, 25 * 60);
      expect(defaults.config.breakDurationSeconds, 5 * 60);

      repository.setSetting('tomato_auto_start_next', '1');
      final legacy = _createService(repository, store);
      await legacy.init();
      expect(legacy.config.autoStartNextRound, true);

      legacy.saveConfig(
        legacy.config.copyWith(
          autoStartBreak: false,
          autoStartNextRound: true,
          workspaceSplitRatio: 0.61,
          reminder: const TimerReminderConfig(voice: true),
        ),
      );
      expect(repository.getSetting('tomato_auto_start_break'), '0');
      expect(repository.getSetting('tomato_auto_start_next'), '1');
      expect(repository.getSetting('tomato_auto_start_next_round'), '1');
      expect(repository.getSetting('tomato_workspace_split_ratio'), isNotNull);
      expect(
        repository.getSetting('tomato_reminder_config'),
        contains('voice'),
      );
    });

    test('manual phase transitions require explicit advance action', () async {
      final repository = _MemoryFocusRepository();
      final store = _MemorySettingsStoreRepository();
      final service = _createService(repository, store);
      await service.init();
      service.saveConfig(
        const TomatoTimerConfig(
          focusDurationSeconds: 3,
          breakDurationSeconds: 2,
          rounds: 2,
          autoStartBreak: false,
          autoStartNextRound: false,
          reminder: TimerReminderConfig(
            haptic: false,
            sound: false,
            voice: false,
            visual: true,
          ),
        ),
      );

      fakeAsync((async) {
        service.start();

        async.elapse(const Duration(seconds: 3));
        expect(service.state.phase, TomatoTimerPhase.breakReady);
        service.resume();
        expect(service.state.phase, TomatoTimerPhase.breakReady);

        service.advanceToNextPhase();
        expect(service.state.phase, TomatoTimerPhase.breakTime);

        async.elapse(const Duration(seconds: 2));
        expect(service.state.phase, TomatoTimerPhase.focusReady);
        service.resume();
        expect(service.state.phase, TomatoTimerPhase.focusReady);

        service.advanceToNextPhase();
        expect(service.state.phase, TomatoTimerPhase.focus);
      });
    });

    test('today stats separate focus minutes and session minutes', () async {
      final repository = _MemoryFocusRepository();
      final store = _MemorySettingsStoreRepository();
      final service = _createService(repository, store);
      await service.init();
      service.saveConfig(
        const TomatoTimerConfig(
          focusDurationSeconds: 60,
          breakDurationSeconds: 60,
          rounds: 1,
          autoStartBreak: true,
          autoStartNextRound: false,
          reminder: TimerReminderConfig(
            haptic: false,
            sound: false,
            voice: false,
            visual: true,
          ),
        ),
      );

      fakeAsync((async) {
        service.start();
        async.elapse(const Duration(seconds: 120));
        expect(service.state.phase, TomatoTimerPhase.idle);
      });

      expect(service.getTodayFocusMinutes(), 1);
      expect(service.getTodaySessionMinutes(), 2);
      expect(service.getTodayRoundsCompleted(), 1);
      expect(repository.records.first.partial, false);
    });

    test(
      'today stats cache avoids repeated database reads until invalidated',
      () async {
        final repository = _MemoryFocusRepository();
        final store = _MemorySettingsStoreRepository();
        repository.records.addAll(<TomatoTimerRecord>[
          TomatoTimerRecord(
            startTime: DateTime.now(),
            durationMinutes: 30,
            focusDurationMinutes: 25,
            breakDurationMinutes: 5,
            roundsCompleted: 2,
            focusMinutes: 25,
            breakMinutes: 5,
          ),
          TomatoTimerRecord(
            startTime: DateTime.now(),
            durationMinutes: 15,
            focusDurationMinutes: 10,
            breakDurationMinutes: 5,
            roundsCompleted: 1,
            focusMinutes: 10,
            breakMinutes: 5,
          ),
        ]);

        final service = _createService(repository, store);
        await service.init();

        expect(service.getTodayFocusMinutes(), 35);
        expect(service.getTodaySessionMinutes(), 45);
        expect(service.getTodayRoundsCompleted(), 3);
        expect(repository.getTimerRecordsCalls, 1);

        expect(service.getTodayFocusMinutes(), 35);
        expect(service.getTodaySessionMinutes(), 45);
        expect(service.getTodayRoundsCompleted(), 3);
        expect(repository.getTimerRecordsCalls, 1);

        service.stop();
        expect(service.getTodayFocusMinutes(), 35);
        expect(repository.getTimerRecordsCalls, 1);

        fakeAsync((async) {
          service.start(
            focusDurationSeconds: 60,
            breakDurationSeconds: 60,
            rounds: 1,
          );
          async.elapse(const Duration(seconds: 15));
          service.stop();
        });

        expect(service.getTodayFocusMinutes(), greaterThanOrEqualTo(35));
        expect(repository.getTimerRecordsCalls, 2);
      },
    );

    test('stop stores a partial session record', () async {
      final repository = _MemoryFocusRepository();
      final store = _MemorySettingsStoreRepository();
      final service = _createService(repository, store);
      await service.init();
      service.saveConfig(
        const TomatoTimerConfig(
          focusDurationSeconds: 60,
          breakDurationSeconds: 60,
          rounds: 1,
        ),
      );

      fakeAsync((async) {
        service.start();
        async.elapse(const Duration(seconds: 30));
        service.stop();
      });

      expect(repository.records, isNotEmpty);
      expect(repository.records.first.partial, true);
      expect(repository.records.first.focusDurationMinutes, greaterThan(0));
    });

    test(
      'lock screen state clears when stopping or completing a session',
      () async {
        final repository = _MemoryFocusRepository();
        final store = _MemorySettingsStoreRepository();
        final service = _createService(repository, store);
        await service.init();
        service.saveConfig(
          const TomatoTimerConfig(
            focusDurationSeconds: 2,
            breakDurationSeconds: 1,
            rounds: 1,
            autoStartBreak: true,
            reminder: TimerReminderConfig(
              haptic: false,
              sound: false,
              voice: false,
              visual: true,
            ),
          ),
        );

        fakeAsync((async) {
          service.start();
          service.setLockScreenActive(true);
          expect(service.lockScreenActive, true);

          service.stop(saveProgress: false);
          expect(service.lockScreenActive, false);

          service.start();
          service.setLockScreenActive(true);
          async.elapse(const Duration(seconds: 3));
          expect(service.state.phase, TomatoTimerPhase.idle);
          expect(service.lockScreenActive, false);
        });
      },
    );

    test(
      'phase completion waits for reminder acknowledgement before auto advance',
      () async {
        final repository = _MemoryFocusRepository();
        final store = _MemorySettingsStoreRepository();
        final reminder = _FakeReminderService();
        final service = _createService(repository, store, reminder: reminder);
        await service.init();
        service.saveConfig(
          const TomatoTimerConfig(
            focusDurationSeconds: 2,
            breakDurationSeconds: 3,
            rounds: 1,
            autoStartBreak: true,
            reminder: TimerReminderConfig(
              haptic: true,
              sound: true,
              voice: false,
              visual: true,
            ),
          ),
        );

        fakeAsync((async) {
          service.start();
          async.elapse(const Duration(seconds: 2));

          expect(service.reminderAcknowledgementPending, true);
          expect(service.pendingReminderPhase, TomatoTimerPhase.focus);
          expect(service.state.phase, TomatoTimerPhase.breakReady);
        });

        expect(reminder.playCalls, 1);
        expect(reminder.lastHaptic, true);
        expect(reminder.lastSound, true);
        expect(reminder.lastDuration, const Duration(seconds: 45));

        await service.acknowledgeReminder();

        expect(reminder.stopCalls, greaterThan(0));
        expect(service.reminderAcknowledgementPending, false);
        expect(service.state.phase, TomatoTimerPhase.breakTime);
      },
    );

    test(
      'reminder announcement includes round and next-step details',
      () async {
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        binding.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
        addTearDown(binding.platformDispatcher.clearAllTestValues);
        final repository = _MemoryFocusRepository();
        final store = _MemorySettingsStoreRepository();
        store.setSetting('uiLanguage', 'en');
        final reminder = _FakeReminderService();
        final service = _createService(repository, store, reminder: reminder);
        await service.init();
        service.saveConfig(
          const TomatoTimerConfig(
            focusDurationSeconds: 2,
            breakDurationSeconds: 180,
            rounds: 1,
            autoStartBreak: true,
            reminder: TimerReminderConfig(
              haptic: true,
              sound: true,
              voice: true,
              visual: true,
            ),
          ),
        );

        fakeAsync((async) {
          service.start();
          async.elapse(const Duration(seconds: 2));
        });

        expect(reminder.playCalls, 1);
        expect(reminder.lastAnnouncementLanguageTag, startsWith('zh'));
        expect(reminder.lastAnnouncementText, contains('专注时间结束'));
        expect(reminder.lastAnnouncementText, contains('第'));
        expect(reminder.lastAnnouncementText, contains('时长'));
        expect(reminder.lastAnnouncementText, contains('3 分'));
      },
    );

    test('voice reminders pass the system locale to TTS playback', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
      addTearDown(binding.platformDispatcher.clearAllTestValues);

      final repository = _MemoryFocusRepository();
      final store = _MemorySettingsStoreRepository();
      store.setSetting('uiLanguage', 'en');
      String? spokenText;
      String? spokenLanguage;
      final service = _createService(
        repository,
        store,
        ttsSpeakOverride: (text, config) async {
          spokenText = text;
          spokenLanguage = config.language;
        },
      );
      await service.init();
      service.saveConfig(
        const TomatoTimerConfig(
          focusDurationSeconds: 2,
          breakDurationSeconds: 3,
          rounds: 1,
          autoStartBreak: true,
          reminder: TimerReminderConfig(
            haptic: false,
            sound: false,
            voice: true,
            visual: true,
          ),
        ),
      );

      fakeAsync((async) {
        service.start();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
      });

      expect(spokenText, isNotNull);
      expect(spokenLanguage, startsWith('ja'));
    });

    test('saving a reminder todo syncs it to the system calendar', () async {
      final repository = _MemoryFocusRepository();
      final store = _MemorySettingsStoreRepository();
      final systemCalendar = _FakeSystemCalendarService();
      final todoReminder = _FakeTodoReminderService();
      final service = _createService(
        repository,
        store,
        systemCalendar: systemCalendar,
        todoReminder: todoReminder,
      );
      await service.init();

      service.addTodo(
        'Sync release checklist',
        dueAt: DateTime(2026, 3, 15, 9, 30),
        alarmEnabled: true,
        systemCalendarNotificationMinutesBefore: 5,
        systemCalendarAlarmEnabled: true,
        systemCalendarAlarmMinutesBefore: 15,
      );
      await pumpEventQueue();

      expect(systemCalendar.syncedTodos, hasLength(1));
      expect(todoReminder.syncedTodos, hasLength(1));
      expect(systemCalendar.syncedTodos.single.id, isNotNull);
      expect(systemCalendar.syncedTodos.single.hasReminder, isTrue);
      expect(
        systemCalendar.syncedTodos.single.systemCalendarNotificationOffsets,
        isEmpty,
      );
      expect(
        systemCalendar.syncedTodos.single.systemCalendarAlarmOffsets,
        <int>[15],
      );
      expect(
        systemCalendar.syncedTodos.single.systemCalendarReminderOffsets,
        <int>[15],
      );
    });

    test(
      'saving a local-only reminder todo does not sync it to the system calendar',
      () async {
        final repository = _MemoryFocusRepository();
        final store = _MemorySettingsStoreRepository();
        final systemCalendar = _FakeSystemCalendarService();
        final todoReminder = _FakeTodoReminderService();
        final service = _createService(
          repository,
          store,
          systemCalendar: systemCalendar,
          todoReminder: todoReminder,
        );
        await service.init();

        service.addTodo(
          'Keep reminder inside app only',
          dueAt: DateTime(2026, 3, 15, 14, 0),
          alarmEnabled: true,
          syncToSystemCalendar: false,
        );
        await pumpEventQueue();

        expect(systemCalendar.syncedTodos, isEmpty);
        expect(systemCalendar.removedTodoIds, hasLength(1));
        expect(todoReminder.syncedTodos, hasLength(1));
      },
    );

    test(
      'deleting a reminder todo removes its system calendar event',
      () async {
        final repository = _MemoryFocusRepository();
        final store = _MemorySettingsStoreRepository();
        final systemCalendar = _FakeSystemCalendarService();
        final todoReminder = _FakeTodoReminderService();
        final service = _createService(
          repository,
          store,
          systemCalendar: systemCalendar,
          todoReminder: todoReminder,
        );
        await service.init();

        service.addTodo(
          'Remove synced reminder',
          dueAt: DateTime(2026, 3, 15, 11, 0),
          alarmEnabled: true,
        );
        await pumpEventQueue();

        final todoId = systemCalendar.syncedTodos.single.id!;
        service.deleteTodo(todoId);
        await pumpEventQueue();

        expect(systemCalendar.removedTodoIds, contains(todoId));
        expect(todoReminder.removedTodoIds, contains(todoId));
      },
    );
  });
}

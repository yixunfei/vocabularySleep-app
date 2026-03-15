import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/tomato_timer.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/reminder_service.dart';
import 'package:vocabulary_sleep_app/src/services/system_calendar_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService() : super(WordbookImportService());

  final Map<String, String> _settings = <String, String>{};
  final List<TomatoTimerRecord> records = <TomatoTimerRecord>[];
  final List<TodoItem> todos = <TodoItem>[];
  int getTimerRecordsCalls = 0;
  int _nextTodoId = 1;

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
      final todoIndex = todos.indexWhere((todo) => todo.id == orderedIds[index]);
      if (todoIndex < 0) {
        continue;
      }
      todos[todoIndex] = todos[todoIndex].copyWith(sortOrder: index);
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

class _FakeReminderService implements ReminderService {
  int playCalls = 0;
  int stopCalls = 0;
  bool lastHaptic = false;
  bool lastSound = false;
  Duration? lastDuration;

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
    syncedTodos.add(item);
  }

  @override
  Future<void> removeTodoReminder(int todoId) async {
    removedTodoIds.add(todoId);
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('FocusService', () {
    test('loads defaults and keeps auto-start-next key compatible', () async {
      final database = _MemoryDatabaseService();

      final defaults = FocusService(database);
      await defaults.init();
      expect(defaults.config.autoStartBreak, true);
      expect(defaults.config.autoStartNextRound, false);
      expect(defaults.config.focusDurationSeconds, 25 * 60);
      expect(defaults.config.breakDurationSeconds, 5 * 60);

      database.setSetting('tomato_auto_start_next', '1');
      final legacy = FocusService(database);
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
      expect(database.getSetting('tomato_auto_start_break'), '0');
      expect(database.getSetting('tomato_auto_start_next'), '1');
      expect(database.getSetting('tomato_auto_start_next_round'), '1');
      expect(database.getSetting('tomato_workspace_split_ratio'), isNotNull);
      expect(database.getSetting('tomato_reminder_config'), contains('voice'));
    });

    test('manual phase transitions require explicit advance action', () async {
      final database = _MemoryDatabaseService();
      final service = FocusService(database);
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
      final database = _MemoryDatabaseService();
      final service = FocusService(database);
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
      expect(database.records.first.partial, false);
    });

    test(
      'today stats cache avoids repeated database reads until invalidated',
      () async {
        final database = _MemoryDatabaseService();
        database.records.addAll(<TomatoTimerRecord>[
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

        final service = FocusService(database);
        await service.init();

        expect(service.getTodayFocusMinutes(), 35);
        expect(service.getTodaySessionMinutes(), 45);
        expect(service.getTodayRoundsCompleted(), 3);
        expect(database.getTimerRecordsCalls, 1);

        expect(service.getTodayFocusMinutes(), 35);
        expect(service.getTodaySessionMinutes(), 45);
        expect(service.getTodayRoundsCompleted(), 3);
        expect(database.getTimerRecordsCalls, 1);

        service.stop();
        expect(service.getTodayFocusMinutes(), 35);
        expect(database.getTimerRecordsCalls, 1);

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
        expect(database.getTimerRecordsCalls, 2);
      },
    );

    test('stop stores a partial session record', () async {
      final database = _MemoryDatabaseService();
      final service = FocusService(database);
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

      expect(database.records, isNotEmpty);
      expect(database.records.first.partial, true);
      expect(database.records.first.focusDurationMinutes, greaterThan(0));
    });

    test(
      'lock screen state clears when stopping or completing a session',
      () async {
        final database = _MemoryDatabaseService();
        final service = FocusService(database);
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
        final database = _MemoryDatabaseService();
        final reminder = _FakeReminderService();
        final service = FocusService(database, reminder: reminder);
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

    test('saving a reminder todo syncs it to the system calendar', () async {
      final database = _MemoryDatabaseService();
      final systemCalendar = _FakeSystemCalendarService();
      final service = FocusService(
        database,
        systemCalendar: systemCalendar,
      );
      await service.init();

      service.addTodo(
        'Sync release checklist',
        dueAt: DateTime(2026, 3, 15, 9, 30),
        alarmEnabled: true,
      );
      await pumpEventQueue();

      expect(systemCalendar.syncedTodos, hasLength(1));
      expect(systemCalendar.syncedTodos.single.id, isNotNull);
      expect(systemCalendar.syncedTodos.single.hasReminder, isTrue);
    });

    test('deleting a reminder todo removes its system calendar event', () async {
      final database = _MemoryDatabaseService();
      final systemCalendar = _FakeSystemCalendarService();
      final service = FocusService(
        database,
        systemCalendar: systemCalendar,
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
    });
  });
}

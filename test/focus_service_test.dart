import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/tomato_timer.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';

class _MemoryDatabaseService extends AppDatabaseService {
  _MemoryDatabaseService() : super(WordbookImportService());

  final Map<String, String> _settings = <String, String>{};
  final List<TomatoTimerRecord> records = <TomatoTimerRecord>[];

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
  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    if (limit >= records.length) {
      return List<TomatoTimerRecord>.from(records);
    }
    return records.take(limit).toList(growable: false);
  }
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
  });
}

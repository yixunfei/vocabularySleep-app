part of 'database_service.dart';

extension AppDatabaseServiceTasks on AppDatabaseService {
  List<TodoItem> getTodos() {
    final rows = _selectMaps(
      'SELECT * FROM todos ORDER BY sort_order ASC, created_at DESC, id DESC',
    );
    return rows.map(TodoItem.fromMap).toList();
  }

  int insertTodo(TodoItem item) {
    final normalizedItem = _normalizeTodoSystemCalendarAlertSelection(item);
    final sortOrder = item.sortOrder > 0
        ? item.sortOrder
        : _nextTodoSortOrder();
    final normalizedDeferred = normalizedItem.completed
        ? false
        : normalizedItem.deferred;
    _db.execute(
      'INSERT INTO todos (content, completed, deferred, priority, category, note, color, sort_order, due_at, alarm_enabled, sync_to_system_calendar, system_calendar_notification_enabled, system_calendar_notification_minutes_before, system_calendar_alarm_enabled, system_calendar_alarm_minutes_before, created_at, completed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        normalizedItem.content,
        normalizedItem.completed ? 1 : 0,
        normalizedDeferred ? 1 : 0,
        normalizedItem.priority,
        normalizedItem.category,
        normalizedItem.note,
        normalizedItem.color,
        sortOrder,
        normalizedItem.dueAt?.toIso8601String(),
        normalizedItem.alarmEnabled ? 1 : 0,
        normalizedItem.syncToSystemCalendar ? 1 : 0,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.notification
            ? 1
            : 0,
        normalizedItem.systemCalendarNotificationMinutesBefore,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.alarm
            ? 1
            : 0,
        normalizedItem.systemCalendarAlarmMinutesBefore,
        normalizedItem.createdAt?.toIso8601String(),
        normalizedItem.completedAt?.toIso8601String(),
      ],
    );
    return _lastInsertId();
  }

  void updateTodo(TodoItem item) {
    if (item.id == null) return;
    final normalizedItem = _normalizeTodoSystemCalendarAlertSelection(item);
    final normalizedDeferred = normalizedItem.completed
        ? false
        : normalizedItem.deferred;
    _db.execute(
      'UPDATE todos SET content = ?, completed = ?, deferred = ?, priority = ?, category = ?, note = ?, color = ?, sort_order = ?, due_at = ?, alarm_enabled = ?, sync_to_system_calendar = ?, system_calendar_notification_enabled = ?, system_calendar_notification_minutes_before = ?, system_calendar_alarm_enabled = ?, system_calendar_alarm_minutes_before = ?, completed_at = ? WHERE id = ?',
      <Object?>[
        normalizedItem.content,
        normalizedItem.completed ? 1 : 0,
        normalizedDeferred ? 1 : 0,
        normalizedItem.priority,
        normalizedItem.category,
        normalizedItem.note,
        normalizedItem.color,
        normalizedItem.sortOrder,
        normalizedItem.dueAt?.toIso8601String(),
        normalizedItem.alarmEnabled ? 1 : 0,
        normalizedItem.syncToSystemCalendar ? 1 : 0,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.notification
            ? 1
            : 0,
        normalizedItem.systemCalendarNotificationMinutesBefore,
        normalizedItem.systemCalendarAlertMode ==
                TodoSystemCalendarAlertMode.alarm
            ? 1
            : 0,
        normalizedItem.systemCalendarAlarmMinutesBefore,
        normalizedItem.completedAt?.toIso8601String(),
        normalizedItem.id,
      ],
    );
  }

  TodoItem _normalizeTodoSystemCalendarAlertSelection(TodoItem item) {
    final useAlarm =
        item.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm;
    return item.copyWith(
      systemCalendarNotificationEnabled: !useAlarm,
      systemCalendarAlarmEnabled: useAlarm,
    );
  }

  void deleteTodo(int id) {
    _db.execute('DELETE FROM todos WHERE id = ?', <Object?>[id]);
  }

  void clearCompletedTodos() {
    _db.execute('DELETE FROM todos WHERE completed = 1');
  }

  void reorderTodos(List<int> orderedIds) {
    if (orderedIds.isEmpty) return;
    _runInTransaction<void>(() {
      for (var index = 0; index < orderedIds.length; index += 1) {
        _db.execute('UPDATE todos SET sort_order = ? WHERE id = ?', <Object?>[
          index,
          orderedIds[index],
        ]);
      }
    });
  }

  List<PlanNote> getNotes() {
    final rows = _selectMaps(
      'SELECT * FROM notes ORDER BY sort_order ASC, updated_at DESC, id DESC',
    );
    return rows.map(PlanNote.fromMap).toList();
  }

  void insertNote(PlanNote note) {
    final sortOrder = note.sortOrder > 0
        ? note.sortOrder
        : _nextNoteSortOrder();
    _db.execute(
      'INSERT INTO notes (title, content, color, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        note.title,
        note.content,
        note.color,
        sortOrder,
        note.createdAt?.toIso8601String(),
        note.updatedAt?.toIso8601String(),
      ],
    );
  }

  void updateNote(PlanNote note) {
    if (note.id == null) return;
    _db.execute(
      'UPDATE notes SET title = ?, content = ?, color = ?, sort_order = ?, updated_at = ? WHERE id = ?',
      <Object?>[
        note.title,
        note.content,
        note.color,
        note.sortOrder,
        note.updatedAt?.toIso8601String(),
        note.id,
      ],
    );
  }

  void deleteNote(int id) {
    _db.execute('DELETE FROM notes WHERE id = ?', <Object?>[id]);
  }

  void deleteNotes(List<int> ids) {
    if (ids.isEmpty) return;
    final placeholders = List<String>.filled(ids.length, '?').join(', ');
    _db.execute(
      'DELETE FROM notes WHERE id IN ($placeholders)',
      ids.cast<Object?>(),
    );
  }

  void reorderNotes(List<int> orderedIds) {
    if (orderedIds.isEmpty) return;
    _runInTransaction<void>(() {
      for (var index = 0; index < orderedIds.length; index += 1) {
        _db.execute('UPDATE notes SET sort_order = ? WHERE id = ?', <Object?>[
          index,
          orderedIds[index],
        ]);
      }
    });
  }

  void insertTimerRecord(TomatoTimerRecord record) {
    _db.execute(
      'INSERT INTO timer_records (start_time, duration_minutes, focus_duration_minutes, break_duration_minutes, rounds_completed, focus_minutes, break_minutes, is_partial) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        record.startTime.toIso8601String(),
        record.durationMinutes,
        record.focusDurationMinutes,
        record.breakDurationMinutes,
        record.roundsCompleted,
        record.focusMinutes,
        record.breakMinutes,
        record.partial ? 1 : 0,
      ],
    );
  }

  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) {
    final rows = _selectMaps(
      'SELECT * FROM timer_records ORDER BY start_time DESC LIMIT ?',
      <Object?>[limit],
    );
    return rows.map(TomatoTimerRecord.fromMap).toList();
  }

  int _nextNoteSortOrder() {
    final row = _selectOne(
      'SELECT COALESCE(MAX(sort_order), -1) AS value FROM notes',
    );
    return ((row?['value'] as num?)?.toInt() ?? -1) + 1;
  }

  int _nextTodoSortOrder() {
    final row = _selectOne(
      'SELECT COALESCE(MAX(sort_order), -1) AS value FROM todos',
    );
    return ((row?['value'] as num?)?.toInt() ?? -1) + 1;
  }

  List<Map<String, Object?>> _selectDownloadedAmbientSounds() {
    return _selectMaps(
      'SELECT * FROM downloaded_ambient_sounds ORDER BY downloaded_at DESC',
    );
  }

  List<DownloadedAmbientSoundInfo> getDownloadedAmbientSounds() {
    final rows = _selectDownloadedAmbientSounds();
    return rows.map((row) => DownloadedAmbientSoundInfo.fromMap(row)).toList();
  }

  void insertDownloadedAmbientSound({
    required String soundId,
    required String remoteKey,
    required String relativePath,
    required String categoryKey,
    required String name,
    required String filePath,
  }) {
    _db.execute(
      '''
      INSERT OR REPLACE INTO downloaded_ambient_sounds (
        sound_id, remote_key, relative_path, category_key, name, file_path, last_accessed_at
      ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      ''',
      <Object?>[soundId, remoteKey, relativePath, categoryKey, name, filePath],
    );
  }

  void deleteDownloadedAmbientSound(String soundId) {
    _db.execute(
      'DELETE FROM downloaded_ambient_sounds WHERE sound_id = ?',
      <Object?>[soundId],
    );
  }

  bool isAmbientSoundDownloaded(String soundId) {
    final row = _selectOne(
      'SELECT 1 FROM downloaded_ambient_sounds WHERE sound_id = ?',
      <Object?>[soundId],
    );
    return row != null;
  }

  void updateDownloadedAmbientSoundAccess(String soundId) {
    _db.execute(
      'UPDATE downloaded_ambient_sounds SET last_accessed_at = CURRENT_TIMESTAMP WHERE sound_id = ?',
      <Object?>[soundId],
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/todo_item.dart';
import 'database_service.dart';

abstract interface class SystemCalendarService {
  Future<void> syncTodo(TodoItem item);

  Future<void> removeTodoReminder(int todoId);

  Future<void> dispose();
}

class PlatformSystemCalendarService implements SystemCalendarService {
  PlatformSystemCalendarService(this._database);

  static const MethodChannel _channel = MethodChannel(
    'vocabulary_sleep/system_calendar',
  );
  static const String _eventLinksSettingKey = 'todo_system_calendar_links';

  final AppDatabaseService _database;

  Future<void> _operationQueue = Future<void>.value();
  bool _disposed = false;

  @override
  Future<void> syncTodo(TodoItem item) {
    final todoId = item.id;
    if (_disposed || todoId == null || !_supportsCurrentPlatform) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      if (!_shouldSyncTodo(item)) {
        await _removeTodoReminderInternal(todoId);
        return;
      }

      final links = _loadEventLinks();
      final response =
          await _invokeCalendarMethod('upsertTodoReminder', <String, Object?>{
            'todoId': todoId,
            'title': item.content,
            'description': _buildTodoDescription(item),
            'startAtMillis': item.dueAt!.millisecondsSinceEpoch,
            'endAtMillis': item.dueAt!
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
            'reminderOffsetsMinutes': item.systemCalendarReminderOffsets,
            if (links['$todoId'] case final String existingEventId
                when existingEventId.trim().isNotEmpty)
              'eventId': existingEventId.trim(),
          });
      final success = response['success'] == true;
      final eventId = '${response['eventId'] ?? ''}'.trim();
      if (!success || eventId.isEmpty) {
        return;
      }

      links['$todoId'] = eventId;
      _saveEventLinks(links);
    });
  }

  @override
  Future<void> removeTodoReminder(int todoId) {
    if (_disposed || !_supportsCurrentPlatform) {
      return Future<void>.value();
    }
    return _enqueue(() => _removeTodoReminderInternal(todoId));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    try {
      await _operationQueue;
    } catch (_) {
      // Best-effort shutdown.
    }
  }

  bool get _supportsCurrentPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool _shouldSyncTodo(TodoItem item) {
    return item.syncToSystemCalendar &&
        item.hasReminder &&
        !item.completed &&
        !item.isDeferred;
  }

  Future<void> _removeTodoReminderInternal(int todoId) async {
    final links = _loadEventLinks();
    final eventId = links['$todoId']?.trim() ?? '';
    if (eventId.isEmpty) {
      return;
    }

    final response = await _invokeCalendarMethod(
      'removeTodoReminder',
      <String, Object?>{'eventId': eventId},
    );
    final success = response['success'] == true;
    final errorCode = '${response['errorCode'] ?? ''}'.trim();
    if (success || errorCode == 'not_found') {
      links.remove('$todoId');
      _saveEventLinks(links);
    }
  }

  Future<Map<String, Object?>> _invokeCalendarMethod(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        method,
        arguments,
      );
      return response ?? const <String, Object?>{};
    } on MissingPluginException {
      return const <String, Object?>{
        'success': false,
        'errorCode': 'unsupported',
      };
    } catch (_) {
      return const <String, Object?>{'success': false, 'errorCode': 'failed'};
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operationQueue.catchError((_) {}).then((_) => operation());
    _operationQueue = next.catchError((_) {});
    return next;
  }

  Map<String, String> _loadEventLinks() {
    final raw = _database.getSetting(_eventLinksSettingKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map<String, String>((key, value) {
          return MapEntry('$key', '$value');
        });
      }
    } catch (_) {
      // Ignore broken mapping payloads and overwrite on next successful sync.
    }
    return <String, String>{};
  }

  void _saveEventLinks(Map<String, String> links) {
    _database.setSetting(_eventLinksSettingKey, jsonEncode(links));
  }

  String? _buildTodoDescription(TodoItem item) {
    final lines = <String>[];
    final category = item.category?.trim() ?? '';
    final note = item.note?.trim() ?? '';
    if (category.isNotEmpty) {
      lines.add('Category: $category');
    }
    if (note.isNotEmpty) {
      lines.add(note);
    }
    if (lines.isEmpty) {
      return null;
    }
    return lines.join('\n');
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/todo_item.dart';

abstract interface class TodoReminderService {
  Future<void> syncTodo(TodoItem item);

  Future<void> removeTodoReminder(int todoId);

  Future<TodoReminderCapability> getCapability();

  Future<bool> requestNotificationPermission();

  Future<void> openExactAlarmSettings();

  Future<int?> consumePendingTodoLaunchId();

  Future<TodoReminderLaunchAction?> consumePendingTodoAction();

  Future<void> dispose();
}

class TodoReminderCapability {
  const TodoReminderCapability({
    required this.notificationsGranted,
    required this.notificationPermissionRequestable,
    required this.exactAlarmGranted,
    required this.exactAlarmSettingsAvailable,
  });

  final bool notificationsGranted;
  final bool notificationPermissionRequestable;
  final bool exactAlarmGranted;
  final bool exactAlarmSettingsAvailable;

  bool get needsNotificationPermission =>
      notificationPermissionRequestable && !notificationsGranted;

  bool get needsExactAlarmPermission =>
      exactAlarmSettingsAvailable && !exactAlarmGranted;
}

enum TodoReminderActionType { open, detail, complete, snooze }

class TodoReminderLaunchAction {
  const TodoReminderLaunchAction({
    required this.todoId,
    required this.type,
    this.snoozeMinutes = 10,
  });

  final int todoId;
  final TodoReminderActionType type;
  final int snoozeMinutes;
}

class PlatformTodoReminderService implements TodoReminderService {
  PlatformTodoReminderService();

  static const MethodChannel _channel = MethodChannel(
    'vocabulary_sleep/todo_reminder',
  );

  Future<void> _operationQueue = Future<void>.value();
  bool _disposed = false;

  @override
  Future<void> syncTodo(TodoItem item) {
    final todoId = item.id;
    if (_disposed || todoId == null || !_supportsCurrentPlatform) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      if (!_shouldScheduleTodo(item)) {
        await removeTodoReminder(todoId);
        return;
      }

      final dueAt = item.dueAt!;
      final minutesBefore =
          item.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm
          ? item.systemCalendarAlarmMinutesBefore
          : item.systemCalendarNotificationMinutesBefore;
      final triggerAt = dueAt.subtract(
        Duration(minutes: minutesBefore.clamp(0, 7 * 24 * 60)),
      );
      await _invokeReminderMethod('upsertTodoReminder', <String, Object?>{
        'todoId': todoId,
        'title': item.content,
        'description': item.note?.trim(),
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'dueAtMillis': dueAt.millisecondsSinceEpoch,
        'mode': item.systemCalendarAlertMode.name,
      });
    });
  }

  @override
  Future<void> removeTodoReminder(int todoId) {
    if (_disposed || !_supportsCurrentPlatform) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      await _invokeReminderMethod('removeTodoReminder', <String, Object?>{
        'todoId': todoId,
      });
    });
  }

  @override
  Future<TodoReminderCapability> getCapability() async {
    if (!_supportsCurrentPlatform) {
      return const TodoReminderCapability(
        notificationsGranted: true,
        notificationPermissionRequestable: false,
        exactAlarmGranted: true,
        exactAlarmSettingsAvailable: false,
      );
    }
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'getTodoReminderCapability',
      );
      return TodoReminderCapability(
        notificationsGranted: response?['notificationsGranted'] == true,
        notificationPermissionRequestable:
            response?['notificationPermissionRequestable'] == true,
        exactAlarmGranted: response?['exactAlarmGranted'] == true,
        exactAlarmSettingsAvailable:
            response?['exactAlarmSettingsAvailable'] == true,
      );
    } on MissingPluginException {
      return const TodoReminderCapability(
        notificationsGranted: true,
        notificationPermissionRequestable: false,
        exactAlarmGranted: true,
        exactAlarmSettingsAvailable: false,
      );
    } catch (_) {
      return const TodoReminderCapability(
        notificationsGranted: false,
        notificationPermissionRequestable: false,
        exactAlarmGranted: false,
        exactAlarmSettingsAvailable: false,
      );
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!_supportsCurrentPlatform) {
      return true;
    }
    try {
      final granted = await _channel.invokeMethod<bool>(
        'requestTodoReminderNotificationPermission',
      );
      return granted ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (!_supportsCurrentPlatform) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('openTodoReminderExactAlarmSettings');
    } on MissingPluginException {
      // Unsupported platforms silently ignore.
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  Future<int?> consumePendingTodoLaunchId() async {
    if (!_supportsCurrentPlatform) {
      return null;
    }
    try {
      final todoId = await _channel.invokeMethod<int>(
        'consumePendingTodoLaunchId',
      );
      if (todoId == null || todoId <= 0) {
        return null;
      }
      return todoId;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TodoReminderLaunchAction?> consumePendingTodoAction() async {
    if (!_supportsCurrentPlatform) {
      return null;
    }
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'consumePendingTodoAction',
      );
      final todoId = (response?['todoId'] as num?)?.toInt() ?? 0;
      if (todoId <= 0) {
        return null;
      }
      final type = switch ('${response?['type'] ?? ''}'.trim()) {
        'detail' => TodoReminderActionType.detail,
        'complete' => TodoReminderActionType.complete,
        'snooze' => TodoReminderActionType.snooze,
        _ => TodoReminderActionType.open,
      };
      final snoozeMinutes = (response?['snoozeMinutes'] as num?)?.toInt() ?? 10;
      return TodoReminderLaunchAction(
        todoId: todoId,
        type: type,
        snoozeMinutes: snoozeMinutes < 1 ? 10 : snoozeMinutes,
      );
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _invokeReminderMethod(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Unsupported platforms silently ignore local reminder scheduling.
    } catch (_) {
      // Best-effort scheduling.
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operationQueue.catchError((_) {}).then((_) => operation());
    _operationQueue = next.catchError((_) {});
    return next;
  }

  bool get _supportsCurrentPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool _shouldScheduleTodo(TodoItem item) {
    return item.hasReminder && !item.completed && !item.isDeferred;
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
}

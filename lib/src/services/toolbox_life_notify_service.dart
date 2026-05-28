import 'dart:convert';

import '../models/todo_item.dart';

enum LifeNotifyPresentationType { notification, alarm, fakeCall }

enum LifeNotifyScheduleType { dateTime, countdown }

class LifeNotifyMetadata {
  const LifeNotifyMetadata({
    this.note = '',
    this.presentationType = LifeNotifyPresentationType.notification,
    this.scheduleType = LifeNotifyScheduleType.dateTime,
    this.countdownMinutes = 0,
    this.stickyNotification = false,
    this.cancelOnOpen = true,
    this.callerName = '',
    this.callerNumber = '',
    this.callerLocation = '',
    this.callerTag = '',
  });

  static const String noteMarker = '[[life_notify_v1]]';
  static const String notifyCategory = 'life_notify_me';
  static const String fakeCallCategory = 'life_fake_call';

  final String note;
  final LifeNotifyPresentationType presentationType;
  final LifeNotifyScheduleType scheduleType;
  final int countdownMinutes;
  final bool stickyNotification;
  final bool cancelOnOpen;
  final String callerName;
  final String callerNumber;
  final String callerLocation;
  final String callerTag;

  bool get isFakeCall =>
      presentationType == LifeNotifyPresentationType.fakeCall;

  bool get hasCallerMeta =>
      callerName.trim().isNotEmpty ||
      callerNumber.trim().isNotEmpty ||
      callerLocation.trim().isNotEmpty ||
      callerTag.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'note': note.trim(),
      'presentationType': presentationType.name,
      'scheduleType': scheduleType.name,
      'countdownMinutes': countdownMinutes.clamp(0, 7 * 24 * 60),
      'stickyNotification': stickyNotification,
      'cancelOnOpen': cancelOnOpen,
      'callerName': callerName.trim(),
      'callerNumber': callerNumber.trim(),
      'callerLocation': callerLocation.trim(),
      'callerTag': callerTag.trim(),
    };
  }

  String encode() => '$noteMarker${jsonEncode(toJson())}';

  LifeNotifyMetadata copyWith({
    String? note,
    LifeNotifyPresentationType? presentationType,
    LifeNotifyScheduleType? scheduleType,
    int? countdownMinutes,
    bool? stickyNotification,
    bool? cancelOnOpen,
    String? callerName,
    String? callerNumber,
    String? callerLocation,
    String? callerTag,
  }) {
    return LifeNotifyMetadata(
      note: note ?? this.note,
      presentationType: presentationType ?? this.presentationType,
      scheduleType: scheduleType ?? this.scheduleType,
      countdownMinutes: countdownMinutes ?? this.countdownMinutes,
      stickyNotification: stickyNotification ?? this.stickyNotification,
      cancelOnOpen: cancelOnOpen ?? this.cancelOnOpen,
      callerName: callerName ?? this.callerName,
      callerNumber: callerNumber ?? this.callerNumber,
      callerLocation: callerLocation ?? this.callerLocation,
      callerTag: callerTag ?? this.callerTag,
    );
  }

  static LifeNotifyMetadata decode(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) {
      return const LifeNotifyMetadata();
    }
    if (!text.startsWith(noteMarker)) {
      return LifeNotifyMetadata(note: text);
    }
    final payload = text.substring(noteMarker.length).trim();
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return LifeNotifyMetadata(note: text);
      }
      final map = decoded.map<String, Object?>(
        (key, value) => MapEntry('$key', value),
      );
      return LifeNotifyMetadata(
        note: '${map['note'] ?? ''}'.trim(),
        presentationType: _parsePresentationType(map['presentationType']),
        scheduleType: _parseScheduleType(map['scheduleType']),
        countdownMinutes: (map['countdownMinutes'] as num?)?.toInt() ?? 0,
        stickyNotification: map['stickyNotification'] == true,
        cancelOnOpen: map['cancelOnOpen'] != false,
        callerName: '${map['callerName'] ?? ''}'.trim(),
        callerNumber: '${map['callerNumber'] ?? ''}'.trim(),
        callerLocation: '${map['callerLocation'] ?? ''}'.trim(),
        callerTag: '${map['callerTag'] ?? ''}'.trim(),
      );
    } catch (_) {
      return LifeNotifyMetadata(note: text);
    }
  }

  static LifeNotifyPresentationType _parsePresentationType(Object? raw) {
    return switch ('$raw'.trim()) {
      'alarm' => LifeNotifyPresentationType.alarm,
      'fakeCall' => LifeNotifyPresentationType.fakeCall,
      _ => LifeNotifyPresentationType.notification,
    };
  }

  static LifeNotifyScheduleType _parseScheduleType(Object? raw) {
    return switch ('$raw'.trim()) {
      'countdown' => LifeNotifyScheduleType.countdown,
      _ => LifeNotifyScheduleType.dateTime,
    };
  }
}

class LifeNotifyTodoViewData {
  const LifeNotifyTodoViewData({
    required this.title,
    required this.metadata,
    required this.sourceCategory,
  });

  final String title;
  final LifeNotifyMetadata metadata;
  final String sourceCategory;

  String? get calendarDescription {
    final lines = <String>[];
    if (metadata.note.trim().isNotEmpty) {
      lines.add(metadata.note.trim());
    }
    if (metadata.isFakeCall) {
      final fakeCallParts = <String>[
        if (metadata.callerName.trim().isNotEmpty) metadata.callerName.trim(),
        if (metadata.callerNumber.trim().isNotEmpty)
          metadata.callerNumber.trim(),
        if (metadata.callerLocation.trim().isNotEmpty)
          metadata.callerLocation.trim(),
        if (metadata.callerTag.trim().isNotEmpty) metadata.callerTag.trim(),
      ];
      if (fakeCallParts.isNotEmpty) {
        lines.add('Fake call: ${fakeCallParts.join(' / ')}');
      }
    }
    if (lines.isEmpty) {
      return null;
    }
    return lines.join('\n');
  }
}

bool isLifeNotifyCategory(String? category) {
  final normalized = (category ?? '').trim();
  return normalized == LifeNotifyMetadata.notifyCategory ||
      normalized == LifeNotifyMetadata.fakeCallCategory;
}

LifeNotifyTodoViewData buildLifeNotifyTodoViewData(TodoItem item) {
  final category = item.category?.trim() ?? '';
  var metadata = isLifeNotifyCategory(category)
      ? LifeNotifyMetadata.decode(item.note)
      : LifeNotifyMetadata(note: item.note?.trim() ?? '');
  if (category == LifeNotifyMetadata.fakeCallCategory &&
      metadata.presentationType != LifeNotifyPresentationType.fakeCall) {
    metadata = metadata.copyWith(
      presentationType: LifeNotifyPresentationType.fakeCall,
    );
  }
  return LifeNotifyTodoViewData(
    title: item.content,
    metadata: metadata,
    sourceCategory: category,
  );
}

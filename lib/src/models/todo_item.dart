class TodoItem {
  static const Object _unset = Object();

  const TodoItem({
    this.id,
    required this.content,
    this.completed = false,
    this.deferred = false,
    this.priority = 0,
    this.category,
    this.note,
    this.color,
    this.sortOrder = 0,
    this.dueAt,
    this.alarmEnabled = false,
    this.syncToSystemCalendar = true,
    this.createdAt,
    this.completedAt,
  });

  final int? id;
  final String content;
  final bool completed;
  final bool deferred;
  final int priority;
  final String? category;
  final String? note;
  final String? color;
  final int sortOrder;
  final DateTime? dueAt;
  final bool alarmEnabled;
  final bool syncToSystemCalendar;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get hasReminder => alarmEnabled && dueAt != null;
  bool get isDeferred => deferred && !completed;

  TodoItem copyWith({
    int? id,
    String? content,
    bool? completed,
    bool? deferred,
    int? priority,
    Object? category = _unset,
    Object? note = _unset,
    Object? color = _unset,
    int? sortOrder,
    Object? dueAt = _unset,
    bool? alarmEnabled,
    bool? syncToSystemCalendar,
    DateTime? createdAt,
    Object? completedAt = _unset,
  }) {
    return TodoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      completed: completed ?? this.completed,
      deferred: deferred ?? this.deferred,
      priority: priority ?? this.priority,
      category: identical(category, _unset)
          ? this.category
          : category as String?,
      note: identical(note, _unset) ? this.note : note as String?,
      color: identical(color, _unset) ? this.color : color as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      dueAt: identical(dueAt, _unset) ? this.dueAt : dueAt as DateTime?,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      syncToSystemCalendar: syncToSystemCalendar ?? this.syncToSystemCalendar,
      createdAt: createdAt ?? this.createdAt,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  factory TodoItem.fromMap(Map<String, Object?> map) {
    return TodoItem(
      id: (map['id'] as num?)?.toInt(),
      content: (map['content'] as String?) ?? '',
      completed: (map['completed'] as num?)?.toInt() == 1,
      deferred: (map['deferred'] as num?)?.toInt() == 1,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      category: map['category'] as String?,
      note: map['note'] as String?,
      color: map['color'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      dueAt: map['due_at'] != null
          ? DateTime.tryParse(map['due_at'] as String)
          : null,
      alarmEnabled: (map['alarm_enabled'] as num?)?.toInt() == 1,
      syncToSystemCalendar: map['sync_to_system_calendar'] == null
          ? true
          : (map['sync_to_system_calendar'] as num?)?.toInt() == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'content': content,
      'completed': completed ? 1 : 0,
      'deferred': isDeferred ? 1 : 0,
      'priority': priority,
      'category': category,
      'note': note,
      'color': color,
      'sort_order': sortOrder,
      'due_at': dueAt?.toIso8601String(),
      'alarm_enabled': alarmEnabled ? 1 : 0,
      'sync_to_system_calendar': syncToSystemCalendar ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

class PlanNote {
  static const Object _unset = Object();

  const PlanNote({
    this.id,
    required this.title,
    this.content,
    this.color,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String? content;
  final String? color;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlanNote copyWith({
    int? id,
    String? title,
    Object? content = _unset,
    Object? color = _unset,
    int? sortOrder,
    DateTime? createdAt,
    Object? updatedAt = _unset,
  }) {
    return PlanNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: identical(content, _unset) ? this.content : content as String?,
      color: identical(color, _unset) ? this.color : color as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  factory PlanNote.fromMap(Map<String, Object?> map) {
    return PlanNote(
      id: (map['id'] as num?)?.toInt(),
      title: (map['title'] as String?) ?? '',
      content: map['content'] as String?,
      color: map['color'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

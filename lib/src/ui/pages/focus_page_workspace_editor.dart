part of 'focus_page.dart';

extension _FocusPageWorkspaceEditorExtension on _FocusPageState {
  _TodoDraftState _todoDraftStateOf(TodoItem todo) {
    if (todo.completed) {
      return _TodoDraftState.completed;
    }
    if (todo.isDeferred) {
      return _TodoDraftState.deferred;
    }
    return _TodoDraftState.active;
  }

  String _todoDraftStateLabel(AppI18n i18n, _TodoDraftState state) {
    return switch (state) {
      _TodoDraftState.active => pickUiText(
        i18n,
        zh: '进行中',
        en: 'Active',
        ja: '進行中',
        de: 'Aktiv',
        fr: 'Actives',
        es: 'Activas',
        ru: 'Активные',
      ),
      _TodoDraftState.deferred => pickUiText(
        i18n,
        zh: '延后搁置',
        en: 'Deferred',
        ja: '保留中',
        de: 'Zurueckgestellt',
        fr: 'Reporte',
        es: 'Pospuestas',
        ru: 'Отложено',
      ),
      _TodoDraftState.completed => pickUiText(
        i18n,
        zh: '已完成',
        en: 'Completed',
        ja: '完了',
        de: 'Erledigt',
        fr: 'Terminees',
        es: 'Completadas',
        ru: 'Выполнено',
      ),
    };
  }

  String _todoStatusLabel(AppI18n i18n, TodoItem todo) {
    return _todoDraftStateLabel(i18n, _todoDraftStateOf(todo));
  }

  IconData _todoStatusIcon(TodoItem todo) {
    if (todo.completed) {
      return Icons.task_alt_rounded;
    }
    if (todo.isDeferred) {
      return Icons.snooze_rounded;
    }
    return Icons.flash_on_rounded;
  }

  Color _todoStatusColor(ThemeData theme, TodoItem todo) {
    if (todo.completed) {
      return theme.colorScheme.secondary;
    }
    if (todo.isDeferred) {
      return theme.colorScheme.tertiary;
    }
    return theme.colorScheme.primary;
  }

  Widget _buildTodoStatusBadge(TodoItem todo, AppI18n i18n, ThemeData theme) {
    final color = _todoStatusColor(theme, todo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: todo.completed ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_todoStatusIcon(todo), size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _todoStatusLabel(i18n, todo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _todoCardColor(TodoItem todo, ThemeData theme) {
    final accent = _parseHexColor(todo.color);
    if (accent == null && todo.isDeferred) {
      return Color.alphaBlend(
        theme.colorScheme.tertiaryContainer.withValues(alpha: 0.36),
        theme.colorScheme.surfaceContainerLow,
      );
    }
    if (accent == null) {
      return theme.colorScheme.surfaceContainerLow;
    }
    return Color.alphaBlend(
      accent.withValues(alpha: todo.completed ? 0.12 : 0.24),
      theme.colorScheme.surfaceContainerLow,
    );
  }

  Color _todoAccentColor(ThemeData theme, TodoItem todo) {
    return _parseHexColor(todo.color) ??
        (todo.completed || todo.isDeferred
            ? _todoStatusColor(theme, todo)
            : _todoPriorityColor(theme, todo.priority));
  }

  String _todoPriorityLabel(AppI18n i18n, int priority) {
    return switch (priority.clamp(0, 2)) {
      2 => i18n.t('todoPriorityHigh'),
      1 => i18n.t('todoPriorityMedium'),
      _ => i18n.t('todoPriorityLow'),
    };
  }

  Color _todoPriorityColor(ThemeData theme, int priority) {
    return switch (priority.clamp(0, 2)) {
      2 => theme.colorScheme.error,
      1 => theme.colorScheme.primary,
      _ => theme.colorScheme.tertiary,
    };
  }

  String _formatTodoDateTime(DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date $time';
  }

  String _formatTodoTime(DateTime value) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String? _normalizeOptionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _colorToHex(Color? value) {
    if (value == null) return null;
    return value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  List<int> _todoCalendarReminderLeadOptions(int currentMinutes) {
    final values = <int>[0, 5, 10, 15, 30, 60, 120, 24 * 60];
    if (!values.contains(currentMinutes) && currentMinutes >= 0) {
      values.add(currentMinutes);
      values.sort();
    }
    return values;
  }

  String _todoCalendarReminderLeadLabel(AppI18n i18n, int minutesBefore) {
    if (minutesBefore <= 0) {
      return pickUiText(i18n, zh: '准时提醒', en: 'At event time');
    }
    if (minutesBefore < 60) {
      return pickUiText(
        i18n,
        zh: '提前 $minutesBefore 分钟',
        en: '$minutesBefore minutes before',
      );
    }
    if (minutesBefore % 60 == 0) {
      final hours = minutesBefore ~/ 60;
      return pickUiText(i18n, zh: '提前 $hours 小时', en: '$hours hours before');
    }
    return pickUiText(
      i18n,
      zh: '提前 $minutesBefore 分钟',
      en: '$minutesBefore minutes before',
    );
  }

  Future<void> _showTodoEditor(
    FocusService focus,
    AppI18n i18n, {
    TodoItem? todo,
  }) async {
    final titleController = TextEditingController(text: todo?.content ?? '');
    final categoryController = TextEditingController(
      text: todo?.category ?? '',
    );
    final noteController = TextEditingController(text: todo?.note ?? '');
    var priority = (todo?.priority ?? 1).clamp(0, 2).toInt();
    var draftState = todo == null
        ? _TodoDraftState.active
        : _todoDraftStateOf(todo);
    var selectedColor = _parseHexColor(todo?.color);
    var dueAt = todo?.dueAt;
    var alarmEnabled = todo?.alarmEnabled ?? false;
    var syncToSystemCalendar = todo?.syncToSystemCalendar ?? true;
    var systemCalendarAlertMode =
        todo?.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm
        ? _TodoSystemCalendarAlertMode.alarm
        : _TodoSystemCalendarAlertMode.notification;
    var systemCalendarNotificationMinutesBefore =
        todo?.systemCalendarNotificationMinutesBefore ?? 0;
    var systemCalendarAlarmMinutesBefore =
        todo?.systemCalendarAlarmMinutesBefore ?? 10;
    Future<TodoReminderCapability> reminderCapabilityFuture = focus
        .getTodoReminderCapability();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickReminder() async {
              final picked = await _pickTodoReminderDateTime(dueAt);
              if (picked == null) return;
              setSheetState(() {
                dueAt = picked;
                alarmEnabled = true;
              });
            }

            final theme = Theme.of(sheetContext);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        todo == null ? 'addTodoDetails' : 'editTodoDetails',
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('todo-title-field'),
                      controller: titleController,
                      autofocus: todo == null,
                      decoration: InputDecoration(
                        labelText: i18n.t('todoTitle'),
                        hintText: i18n.t('todoTitleHint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('todo-category-field'),
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: i18n.t('todoCategory'),
                        hintText: i18n.t('todoCategoryHint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '状态',
                        en: 'Status',
                        ja: '状態',
                        de: 'Status',
                        fr: 'Statut',
                        es: 'Estado',
                        ru: 'Статус',
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final value in _TodoDraftState.values)
                          ChoiceChip(
                            key: ValueKey<String>('todo-status-${value.name}'),
                            label: Text(_todoDraftStateLabel(i18n, value)),
                            selected: draftState == value,
                            onSelected: (_) {
                              setSheetState(() {
                                draftState = value;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      i18n.t('todoPriority'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final value in <int>[0, 1, 2])
                          ChoiceChip(
                            label: Text(_todoPriorityLabel(i18n, value)),
                            selected: priority == value,
                            onSelected: (_) {
                              setSheetState(() {
                                priority = value;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      i18n.t('todoColor'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text(i18n.t('todoNoColor')),
                          selected: selectedColor == null,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedColor = null;
                            });
                          },
                        ),
                        for (final raw in _FocusPageState._todoPalette)
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Color(raw),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(i18n.t('todoColorOption')),
                              ],
                            ),
                            selected: selectedColor?.toARGB32() == raw,
                            onSelected: (_) {
                              setSheetState(() {
                                selectedColor = Color(raw);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('todo-note-field'),
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: i18n.t('todoNotes'),
                        hintText: i18n.t('todoNotesHint'),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: alarmEnabled,
                      title: Text(i18n.t('todoReminder')),
                      subtitle: Text(
                        dueAt == null
                            ? i18n.t('todoReminderHint')
                            : _formatTodoDateTime(dueAt!),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          alarmEnabled = value;
                          if (!alarmEnabled) {
                            dueAt = null;
                          }
                        });
                      },
                    ),
                    if (alarmEnabled) ...<Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: pickReminder,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(
                              dueAt == null
                                  ? i18n.t('todoPickReminder')
                                  : _formatTodoDateTime(dueAt!),
                            ),
                          ),
                          if (dueAt != null)
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  dueAt = null;
                                  alarmEnabled = false;
                                });
                              },
                              child: Text(i18n.t('clearValue')),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i18n.t('todoReminderStorageHint'),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<TodoReminderCapability>(
                        future: reminderCapabilityFuture,
                        builder: (context, snapshot) {
                          final capability =
                              snapshot.data ??
                              const TodoReminderCapability(
                                notificationsGranted: true,
                                notificationPermissionRequestable: false,
                                exactAlarmGranted: true,
                                exactAlarmSettingsAvailable: false,
                              );
                          final showNotificationWarning =
                              capability.needsNotificationPermission;
                          final showExactAlarmWarning =
                              systemCalendarAlertMode ==
                                  _TodoSystemCalendarAlertMode.alarm &&
                              capability.needsExactAlarmPermission;
                          if (!showNotificationWarning &&
                              !showExactAlarmWarning) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (showNotificationWarning) ...<Widget>[
                                  Text(
                                    pickUiText(
                                      i18n,
                                      zh: '当前系统未授予通知权限，待办到点后可能不会显示提醒。',
                                      en: 'Notification permission is not granted, so todo reminders may not appear on time.',
                                    ),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await focus
                                          .requestTodoReminderNotificationPermission();
                                      if (!context.mounted) return;
                                      setSheetState(() {
                                        reminderCapabilityFuture = focus
                                            .getTodoReminderCapability();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.notifications_active_rounded,
                                    ),
                                    label: Text(
                                      pickUiText(
                                        i18n,
                                        zh: '授予通知权限',
                                        en: 'Enable notifications',
                                      ),
                                    ),
                                  ),
                                ],
                                if (showExactAlarmWarning) ...<Widget>[
                                  if (showNotificationWarning)
                                    const SizedBox(height: 8),
                                  Text(
                                    pickUiText(
                                      i18n,
                                      zh: '闹钟模式建议开启“精确闹钟”，否则系统可能延后提醒时间。',
                                      en: 'Alarm mode works best with exact alarms enabled. Otherwise the system may delay the reminder.',
                                    ),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await focus
                                          .openTodoReminderExactAlarmSettings();
                                      if (!context.mounted) return;
                                      setSheetState(() {
                                        reminderCapabilityFuture = focus
                                            .getTodoReminderCapability();
                                      });
                                    },
                                    icon: const Icon(Icons.alarm_on_rounded),
                                    label: Text(
                                      pickUiText(
                                        i18n,
                                        zh: '打开精确闹钟设置',
                                        en: 'Open exact alarm settings',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: syncToSystemCalendar,
                        title: Text(
                          pickUiText(
                            i18n,
                            zh: '同步到系统日历',
                            en: 'Sync to system calendar',
                            ja: 'システムカレンダーに同期',
                            de: 'Mit Systemkalender synchronisieren',
                            fr: 'Synchroniser avec le calendrier systeme',
                            es: 'Sincronizar con el calendario del sistema',
                            ru: 'Синхронизировать с системным календарем',
                          ),
                        ),
                        subtitle: Text(
                          pickUiText(
                            i18n,
                            zh: '开启后会写入系统日历事件；关闭后只保留应用内提醒。',
                            en: 'When enabled, reminders are written to the system calendar. When disabled, they stay only inside the app.',
                            ja: '有効にするとシステムカレンダーへ予定を作成し、無効にするとアプリ内のリマインダーだけを保持します。',
                            de: 'Wenn aktiviert, werden Erinnerungen in den Systemkalender geschrieben. Andernfalls bleiben sie nur in der App.',
                            fr: 'Lorsque cette option est activee, le rappel est ajoute au calendrier systeme. Sinon, il reste uniquement dans l’application.',
                            es: 'Al activarlo, el recordatorio se agrega al calendario del sistema. Si se desactiva, solo se conserva dentro de la app.',
                            ru: 'При включении напоминание будет сохранено в системный календарь. При выключении оно останется только внутри приложения.',
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            syncToSystemCalendar = value;
                          });
                        },
                      ),
                      if (syncToSystemCalendar) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          pickUiText(i18n, zh: '提醒方式', en: 'Reminder type'),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<_TodoSystemCalendarAlertMode>(
                          groupValue: systemCalendarAlertMode,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setSheetState(() {
                              systemCalendarAlertMode = value;
                            });
                          },
                          child: Column(
                            children: <Widget>[
                              RadioListTile<
                                _TodoSystemCalendarAlertMode
                              >.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value:
                                    _TodoSystemCalendarAlertMode.notification,
                                title: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '应用通知提醒',
                                    en: 'App notification reminder',
                                  ),
                                ),
                                subtitle: Text(
                                  _todoCalendarReminderLeadLabel(
                                    i18n,
                                    systemCalendarNotificationMinutesBefore,
                                  ),
                                ),
                              ),
                              if (systemCalendarAlertMode ==
                                  _TodoSystemCalendarAlertMode.notification)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: DropdownButtonFormField<int>(
                                    initialValue:
                                        systemCalendarNotificationMinutesBefore,
                                    decoration: InputDecoration(
                                      labelText: pickUiText(
                                        i18n,
                                        zh: '提醒提前时间',
                                        en: 'Reminder lead time',
                                      ),
                                    ),
                                    items:
                                        _todoCalendarReminderLeadOptions(
                                              systemCalendarNotificationMinutesBefore,
                                            )
                                            .map((minutes) {
                                              return DropdownMenuItem<int>(
                                                value: minutes,
                                                child: Text(
                                                  _todoCalendarReminderLeadLabel(
                                                    i18n,
                                                    minutes,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(growable: false),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setSheetState(() {
                                        systemCalendarNotificationMinutesBefore =
                                            value;
                                      });
                                    },
                                  ),
                                ),
                              RadioListTile<
                                _TodoSystemCalendarAlertMode
                              >.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _TodoSystemCalendarAlertMode.alarm,
                                title: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '应用闹钟提醒',
                                    en: 'App alarm reminder',
                                  ),
                                ),
                                subtitle: Text(
                                  _todoCalendarReminderLeadLabel(
                                    i18n,
                                    systemCalendarAlarmMinutesBefore,
                                  ),
                                ),
                              ),
                              if (systemCalendarAlertMode ==
                                  _TodoSystemCalendarAlertMode.alarm)
                                DropdownButtonFormField<int>(
                                  initialValue:
                                      systemCalendarAlarmMinutesBefore,
                                  decoration: InputDecoration(
                                    labelText: pickUiText(
                                      i18n,
                                      zh: '提醒提前时间',
                                      en: 'Reminder lead time',
                                    ),
                                  ),
                                  items:
                                      _todoCalendarReminderLeadOptions(
                                            systemCalendarAlarmMinutesBefore,
                                          )
                                          .map((minutes) {
                                            return DropdownMenuItem<int>(
                                              value: minutes,
                                              child: Text(
                                                _todoCalendarReminderLeadLabel(
                                                  i18n,
                                                  minutes,
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setSheetState(() {
                                      systemCalendarAlarmMinutesBefore = value;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '不同系统日历会自行决定这些提醒以通知还是闹钟样式呈现。',
                            en: 'The app handles the real reminder. System calendar sync only writes a mirrored event when enabled.',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(i18n.t('cancel')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          key: const ValueKey<String>('todo-save-button'),
                          onPressed: () {
                            final content = titleController.text.trim();
                            if (content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(i18n.t('todoTitleRequired')),
                                ),
                              );
                              return;
                            }
                            focus.saveTodo(
                              TodoItem(
                                id: todo?.id,
                                content: content,
                                completed:
                                    draftState == _TodoDraftState.completed,
                                deferred:
                                    draftState == _TodoDraftState.deferred,
                                priority: priority,
                                category: _normalizeOptionalText(
                                  categoryController.text,
                                ),
                                note: _normalizeOptionalText(
                                  noteController.text,
                                ),
                                color: _colorToHex(selectedColor),
                                sortOrder: todo?.sortOrder ?? 0,
                                dueAt: dueAt,
                                alarmEnabled: alarmEnabled && dueAt != null,
                                syncToSystemCalendar: syncToSystemCalendar,
                                systemCalendarNotificationEnabled:
                                    systemCalendarAlertMode ==
                                    _TodoSystemCalendarAlertMode.notification,
                                systemCalendarNotificationMinutesBefore:
                                    systemCalendarNotificationMinutesBefore,
                                systemCalendarAlarmEnabled:
                                    systemCalendarAlertMode ==
                                    _TodoSystemCalendarAlertMode.alarm,
                                systemCalendarAlarmMinutesBefore:
                                    systemCalendarAlarmMinutesBefore,
                                createdAt: todo?.createdAt ?? DateTime.now(),
                                completedAt:
                                    draftState == _TodoDraftState.completed
                                    ? (todo?.completedAt ?? DateTime.now())
                                    : null,
                              ),
                            );
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: Text(i18n.t('save')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmStop(FocusService focus, AppI18n i18n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.t('stopTimer')),
        content: Text(i18n.t('stopTimerConfirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              focus.stop();
              Navigator.pop(context);
            },
            child: Text(i18n.t('stop')),
          ),
        ],
      ),
    );
  }

  String _defaultNoteTitle(AppI18n i18n) {
    final now = DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(now);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(now),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final prefix = pickUiText(
      i18n,
      zh: '快速笔记',
      en: 'Quick note',
      ja: 'クイックノート',
      de: 'Schnellnotiz',
      fr: 'Note rapide',
      es: 'Nota rapida',
      ru: 'Быстрая заметка',
    );
    return '$prefix $date $time';
  }

  void _showNoteDialog(FocusService focus, AppI18n i18n, {PlanNote? note}) {
    final state = ref.read(appStateProvider);
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    var selectedColor = _parseHexColor(note?.color);
    var voiceState = _NoteVoiceInputState.idle;
    String? voiceError;
    String? voiceNotice;
    var sheetClosed = false;
    var systemSpeechFallbackActive = false;
    final speechLanguageTag = _noteSpeechLanguageTag(state);
    final voiceInputProvider = state.config.voiceInput.provider;

    Future<void> cleanupVoiceInput() async {
      if (voiceState != _NoteVoiceInputState.idle) {
        await _systemSpeech.cancelListening();
        await state.cancelVoiceInputRecording();
        state.stopVoiceInputProcessing();
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final theme = Theme.of(sheetContext);

            void updateSheet(VoidCallback action) {
              if (sheetClosed || !sheetContext.mounted) {
                return;
              }
              setSheetState(action);
            }

            Future<void> appendRecognizedText(String recognizedText) async {
              final merged = _mergeRecognizedNoteContent(
                contentController.text,
                recognizedText,
              );
              contentController.value = contentController.value.copyWith(
                text: merged,
                selection: TextSelection.collapsed(offset: merged.length),
                composing: TextRange.empty,
              );
            }

            Future<bool> startRecorderVoiceInput({
              bool switchedFromSystem = false,
            }) async {
              final audioPath = await state.startVoiceInputRecording(
                forceRecorder: switchedFromSystem,
              );
              if (sheetClosed || !sheetContext.mounted) {
                return false;
              }
              if ((audioPath ?? '').trim().isEmpty) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = _noteVoiceRecorderErrorText(i18n);
                });
                return false;
              }
              updateSheet(() {
                voiceState = _NoteVoiceInputState.listening;
                voiceError = null;
                if (switchedFromSystem) {
                  systemSpeechFallbackActive = true;
                  voiceNotice = _noteSystemSpeechFallbackText(i18n);
                } else {
                  voiceNotice = null;
                }
              });
              return true;
            }

            Future<void> finishRecorderVoiceInput() async {
              final audioPath = await state.stopVoiceInputRecording();
              if (sheetClosed || !sheetContext.mounted) {
                return;
              }
              if ((audioPath ?? '').trim().isEmpty) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = _noteVoiceRecorderErrorText(i18n);
                });
                return;
              }

              final result = await state.transcribeVoiceInputRecording(
                audioPath!,
              );
              if (sheetClosed || !sheetContext.mounted) {
                return;
              }
              if (!result.success) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = _noteVoiceInputErrorText(
                    i18n,
                    result.error,
                    result.errorParams,
                  );
                });
                return;
              }

              final recognizedText = result.text?.trim() ?? '';
              if (recognizedText.isEmpty) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = _noteVoiceInputErrorText(
                    i18n,
                    result.error ?? 'asrEmptyResult',
                    result.errorParams,
                  );
                });
                return;
              }

              await appendRecognizedText(recognizedText);
              updateSheet(() {
                voiceState = _NoteVoiceInputState.idle;
                voiceError = null;
              });
            }

            String voiceButtonLabel() {
              final useRecorderFlow =
                  voiceInputProvider != VoiceInputProviderType.system ||
                  systemSpeechFallbackActive;
              if (useRecorderFlow) {
                switch (voiceState) {
                  case _NoteVoiceInputState.starting:
                    return pickUiText(
                      i18n,
                      zh: '正在启动语音输入…',
                      en: 'Starting voice input...',
                    );
                  case _NoteVoiceInputState.listening:
                    return pickUiText(
                      i18n,
                      zh: '点击结束语音输入',
                      en: 'Tap to stop voice input',
                    );
                  case _NoteVoiceInputState.finishing:
                    return pickUiText(
                      i18n,
                      zh: '正在转写语音输入…',
                      en: 'Transcribing voice input...',
                    );
                  case _NoteVoiceInputState.idle:
                    return pickUiText(
                      i18n,
                      zh: '点击开始语音输入',
                      en: 'Tap to start voice input',
                    );
                }
              }
              switch (voiceState) {
                case _NoteVoiceInputState.starting:
                  return pickUiText(
                    i18n,
                    zh: '正在启动听写…',
                    en: 'Starting dictation...',
                  );
                case _NoteVoiceInputState.listening:
                  return pickUiText(
                    i18n,
                    zh: '点击结束听写',
                    en: 'Tap to stop dictation',
                  );
                case _NoteVoiceInputState.finishing:
                  return pickUiText(
                    i18n,
                    zh: '正在整理识别结果…',
                    en: 'Finishing dictation...',
                  );
                case _NoteVoiceInputState.idle:
                  return pickUiText(
                    i18n,
                    zh: '点击开始听写',
                    en: 'Tap to start dictation',
                  );
              }
            }

            Future<void> toggleVoiceInput() async {
              if (voiceState == _NoteVoiceInputState.starting ||
                  voiceState == _NoteVoiceInputState.finishing) {
                return;
              }
              if (voiceState == _NoteVoiceInputState.listening) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.finishing;
                  voiceError = null;
                });
                if (voiceInputProvider != VoiceInputProviderType.system ||
                    systemSpeechFallbackActive) {
                  await finishRecorderVoiceInput();
                  return;
                }
                final result = await _systemSpeech.stopListening();
                if (sheetClosed || !sheetContext.mounted) {
                  return;
                }
                if (!result.success) {
                  updateSheet(() {
                    voiceState = _NoteVoiceInputState.idle;
                    voiceError = _noteSpeechErrorText(
                      i18n,
                      result.errorCode,
                      result.errorMessage,
                    );
                  });
                  return;
                }

                final recognizedText = result.text?.trim() ?? '';
                if (recognizedText.isEmpty) {
                  updateSheet(() {
                    voiceState = _NoteVoiceInputState.idle;
                    voiceError = _noteSpeechErrorText(
                      i18n,
                      result.errorCode ?? 'no_match',
                      result.errorMessage,
                    );
                  });
                  return;
                }

                await appendRecognizedText(recognizedText);
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = null;
                });
                return;
              }

              updateSheet(() {
                voiceState = _NoteVoiceInputState.starting;
                voiceError = null;
              });
              if (voiceInputProvider != VoiceInputProviderType.system ||
                  systemSpeechFallbackActive) {
                await startRecorderVoiceInput();
                return;
              }
              final startResult = await _systemSpeech.startListening(
                languageTag: speechLanguageTag,
              );
              if (sheetClosed || !sheetContext.mounted) {
                return;
              }
              if (!startResult.success) {
                final errorCode = (startResult.errorCode ?? '').trim();
                if (errorCode == 'unsupported' || errorCode == 'unavailable') {
                  await startRecorderVoiceInput(switchedFromSystem: true);
                  return;
                }
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = _noteSpeechErrorText(
                    i18n,
                    startResult.errorCode,
                    startResult.errorMessage,
                  );
                });
                return;
              }
              updateSheet(() {
                voiceState = _NoteVoiceInputState.listening;
              });
            }

            String effectiveVoiceHelperText() {
              final insertHint = pickUiText(
                i18n,
                zh: '识别结果会追加到正文，标题留空时会自动生成摘要。',
                en: 'Transcribed text is appended to the note body, and an empty title will be auto-filled.',
                ja: '認識結果は本文に追記され、タイトルが空の場合は自動で要約が入ります。',
                de: 'Erkannter Text wird an den Inhalt angeh盲ngt, und ein leerer Titel wird automatisch erg盲nzt.',
                fr: 'Le texte reconnu est ajoute au contenu, et un titre vide sera complete automatiquement.',
                es: 'El texto reconocido se anade al contenido y el titulo vacio se completa automaticamente.',
                ru: '袪邪褋锌芯蟹薪邪薪薪褘泄 褌械泻褋褌 写芯斜邪胁谢褟械褌褋褟 胁 蟹邪屑械褌泻褍, 邪 锌褍褋褌芯泄 蟹邪谐芯谢芯胁芯泻 蟹邪锌芯谢薪褟械褌褋褟 邪胁褌芯屑邪褌懈褔械褋泻懈.',
              );
              final useRecorderFlow =
                  voiceInputProvider != VoiceInputProviderType.system ||
                  systemSpeechFallbackActive;
              final baseText = useRecorderFlow
                  ? _noteVoiceRecordingHelperText(
                      i18n,
                      voiceState,
                      speechLanguageTag,
                      voiceInputProvider,
                    )
                  : _noteSpeechHelperText(
                      i18n,
                      voiceState,
                      speechLanguageTag,
                      voiceInputProvider,
                    );
              return voiceError ??
                  [
                    if (voiceState == _NoteVoiceInputState.idle &&
                        voiceNotice != null &&
                        voiceNotice!.trim().isNotEmpty)
                      voiceNotice!,
                    baseText +
                        (voiceState == _NoteVoiceInputState.idle
                            ? ' $insertHint'
                            : ''),
                  ].join(' ');
            }

            final isVoiceBusy =
                voiceState == _NoteVoiceInputState.starting ||
                voiceState == _NoteVoiceInputState.finishing;
            final isRecording = voiceState == _NoteVoiceInputState.listening;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t(note == null ? 'addNote' : 'editNote'),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey<String>('note-title-field'),
                          controller: titleController,
                          autofocus: note == null,
                          decoration: InputDecoration(
                            labelText: i18n.t('noteTitle'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey<String>('note-content-field'),
                          controller: contentController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: i18n.t('noteContent'),
                            alignLabelWithHint: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const ValueKey<String>(
                            'note-voice-input-button',
                          ),
                          onPressed: isVoiceBusy ? null : toggleVoiceInput,
                          icon: isVoiceBusy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : Icon(
                                  isRecording
                                      ? Icons.stop_circle_outlined
                                      : Icons.mic_none_rounded,
                                ),
                          label: Text(voiceButtonLabel()),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          effectiveVoiceHelperText(),
                          key: const ValueKey<String>('note-voice-helper-text'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: voiceError == null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          i18n.t('todoColor'),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(i18n.t('todoNoColor')),
                              selected: selectedColor == null,
                              onSelected: (_) {
                                setSheetState(() {
                                  selectedColor = null;
                                });
                              },
                            ),
                            for (final raw in _FocusPageState._todoPalette)
                              ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Color(raw),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(i18n.t('todoColorOption')),
                                  ],
                                ),
                                selected: selectedColor?.toARGB32() == raw,
                                onSelected: (_) {
                                  setSheetState(() {
                                    selectedColor = Color(raw);
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: Text(i18n.t('cancel')),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                final rawTitle = titleController.text.trim();
                                final content = contentController.text.trim();
                                if (rawTitle.isEmpty && content.isEmpty) {
                                  return;
                                }
                                final title = rawTitle.isEmpty
                                    ? _defaultNoteTitle(i18n)
                                    : rawTitle;
                                if (note == null) {
                                  focus.addNote(
                                    title,
                                    content.isEmpty ? null : content,
                                    _colorToHex(selectedColor),
                                  );
                                } else {
                                  focus.updateNote(
                                    note.copyWith(
                                      title: title,
                                      content: content.isEmpty ? null : content,
                                      color: _colorToHex(selectedColor),
                                    ),
                                  );
                                }
                                Navigator.pop(sheetContext);
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: Text(i18n.t('save')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      sheetClosed = true;
      await cleanupVoiceInput();
    });
  }

  void _confirmDeleteSingleNote(
    FocusService focus,
    PlanNote note,
    AppI18n i18n,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.t('deleteNote')),
        content: Text(i18n.t('deleteNoteConfirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (note.id != null) {
                focus.deleteNote(note.id!);
              }
              Navigator.pop(context);
            },
            child: Text(i18n.t('delete')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelectedNotes(FocusService focus, AppI18n i18n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.t('deleteSelectedNotes')),
        content: Text(
          i18n.t(
            'selectedNotesCount',
            params: <String, Object?>{'count': _selectedNoteIds.length},
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              focus.deleteNotes(_selectedNoteIds.toList(growable: false));
              _setViewState(() {
                _selectedNoteIds.clear();
                _noteSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: Text(i18n.t('delete')),
          ),
        ],
      ),
    );
  }
}

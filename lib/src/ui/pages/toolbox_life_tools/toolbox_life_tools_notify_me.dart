part of '../toolbox_life_tools.dart';

class _NotifyMeToolPage extends StatefulWidget {
  const _NotifyMeToolPage();

  @override
  State<_NotifyMeToolPage> createState() => _NotifyMeToolPageState();
}

class _NotifyMeToolPageState extends State<_NotifyMeToolPage> {
  static const String _notifyCategory = LifeNotifyMetadata.notifyCategory;
  static const List<int> _leadPresets = <int>[0, 5, 10, 15, 30, 60, 120];
  static const List<int> _countdownPresets = <int>[5, 10, 15, 30, 45, 60, 120];
  static const int _maxMinutes = 7 * 24 * 60;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _leadController = TextEditingController(
    text: '0',
  );
  final TextEditingController _countdownController = TextEditingController(
    text: '15',
  );

  late DateTime _scheduledAt;
  LifeNotifyPresentationType _presentationType =
      LifeNotifyPresentationType.notification;
  LifeNotifyScheduleType _scheduleType = LifeNotifyScheduleType.dateTime;
  bool _stickyNotification = true;
  bool _cancelOnOpen = true;
  bool _syncToSystemCalendar = true;
  int _minutesBefore = 0;
  int _countdownMinutes = 15;
  bool _creating = false;
  bool _loadingCapability = true;
  TodoReminderCapability _capability = const TodoReminderCapability(
    notificationsGranted: false,
    notificationPermissionRequestable: false,
    exactAlarmGranted: false,
    exactAlarmSettingsAvailable: false,
  );

  @override
  void initState() {
    super.initState();
    _scheduledAt = _initialScheduledAt();
    _loadCapability();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _leadController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  bool get _supportsNativeReminder =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  DateTime _initialScheduledAt() {
    final now = DateTime.now().add(const Duration(hours: 1));
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute < 30 ? 30 : 0,
    ).add(now.minute < 30 ? Duration.zero : const Duration(hours: 1));
  }

  Future<void> _loadCapability() async {
    final capability = await context
        .read<AppState>()
        .focusService
        .getTodoReminderCapability();
    if (!mounted) {
      return;
    }
    setState(() {
      _capability = capability;
      _loadingCapability = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _requestNotificationPermission() async {
    await context
        .read<AppState>()
        .focusService
        .requestTodoReminderNotificationPermission();
    if (!mounted) {
      return;
    }
    await _loadCapability();
  }

  Future<void> _openExactAlarmSettings() async {
    await context
        .read<AppState>()
        .focusService
        .openTodoReminderExactAlarmSettings();
    if (!mounted) {
      return;
    }
    await _loadCapability();
  }

  DateTime _resolveDueTime() {
    if (_scheduleType == LifeNotifyScheduleType.countdown) {
      return DateTime.now().add(Duration(minutes: _countdownMinutes));
    }
    return _scheduledAt;
  }

  DateTime _resolveAlertTime(DateTime dueAt) {
    if (_scheduleType == LifeNotifyScheduleType.countdown) {
      return dueAt;
    }
    return dueAt.subtract(Duration(minutes: _minutesBefore));
  }

  LifeNotifyMetadata _buildMetadata() {
    return LifeNotifyMetadata(
      note: _noteController.text.trim(),
      presentationType: _presentationType,
      scheduleType: _scheduleType,
      countdownMinutes: _countdownMinutes,
      stickyNotification:
          _presentationType == LifeNotifyPresentationType.notification &&
          _stickyNotification,
      cancelOnOpen: _cancelOnOpen,
    );
  }

  Future<void> _createReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack(
        _lifeI18nText(
          context,
          'inline.plan295.life.enter_a_reminder_title_first.d621bb4c9d5b',
        ),
      );
      return;
    }

    final dueAt = _resolveDueTime();
    final alertAt = _resolveAlertTime(dueAt);
    final now = DateTime.now();
    if (!dueAt.isAfter(now)) {
      _showSnack(
        _lifeI18nText(
          context,
          'inline.plan295.life.reminder_time_must_be_in_the_future.59555dd13b04',
        ),
      );
      return;
    }
    if (!alertAt.isAfter(now)) {
      _showSnack(
        _lifeI18nText(
          context,
          'inline.plan295.life.the_lead_time_would_fire_in_the_past.0e5a6cbb5f8e',
        ),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final state = context.read<AppState>();
      final useAlarm = _presentationType == LifeNotifyPresentationType.alarm;
      state.focusService.addTodo(
        title,
        category: _notifyCategory,
        note: _buildMetadata().encode(),
        dueAt: dueAt,
        alarmEnabled: true,
        syncToSystemCalendar: _syncToSystemCalendar,
        systemCalendarNotificationEnabled: !useAlarm,
        systemCalendarNotificationMinutesBefore: !useAlarm ? _minutesBefore : 0,
        systemCalendarAlarmEnabled: useAlarm,
        systemCalendarAlarmMinutesBefore: useAlarm ? _minutesBefore : 0,
      );
      _resetForm();
      _showSnack(
        _lifeI18nText(
          context,
          'inline.plan295.life.reminder_created.e79dfe086bd9',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _noteController.clear();
    setState(() {
      _scheduledAt = _initialScheduledAt();
      _scheduleType = LifeNotifyScheduleType.dateTime;
      _presentationType = LifeNotifyPresentationType.notification;
      _stickyNotification = true;
      _cancelOnOpen = true;
      _syncToSystemCalendar = true;
      _minutesBefore = 0;
      _countdownMinutes = 15;
      _leadController.text = '0';
      _countdownController.text = '15';
    });
  }

  void _reuseReminder(TodoItem item) {
    final viewData = buildLifeNotifyTodoViewData(item);
    final meta = viewData.metadata;
    final dueAt = item.dueAt;
    _titleController.text = item.content;
    _noteController.text = meta.note;
    setState(() {
      _presentationType = meta.isFakeCall
          ? LifeNotifyPresentationType.notification
          : meta.presentationType;
      _scheduleType = meta.scheduleType;
      _scheduledAt = dueAt != null && dueAt.isAfter(DateTime.now())
          ? dueAt
          : _initialScheduledAt();
      _countdownMinutes = meta.countdownMinutes <= 0
          ? 15
          : meta.countdownMinutes.clamp(1, _maxMinutes);
      _stickyNotification =
          _presentationType == LifeNotifyPresentationType.notification &&
          meta.stickyNotification;
      _cancelOnOpen = meta.cancelOnOpen;
      _syncToSystemCalendar = item.syncToSystemCalendar;
      _minutesBefore =
          item.systemCalendarAlertMode == TodoSystemCalendarAlertMode.alarm
          ? item.systemCalendarAlarmMinutesBefore.clamp(0, _maxMinutes)
          : item.systemCalendarNotificationMinutesBefore.clamp(0, _maxMinutes);
      _leadController.text = '$_minutesBefore';
      _countdownController.text = '$_countdownMinutes';
    });
    _showSnack(
      _lifeI18nText(
        context,
        'inline.plan295.life.reminder_settings_copied.0f8bd7b9d2c2',
      ),
    );
  }

  void _setLeadMinutes(int value) {
    final safeValue = value.clamp(0, _maxMinutes);
    setState(() {
      _minutesBefore = safeValue;
      _leadController.text = '$safeValue';
    });
  }

  void _setCountdownMinutes(int value) {
    final safeValue = value.clamp(1, _maxMinutes);
    setState(() {
      _countdownMinutes = safeValue;
      _countdownController.text = '$safeValue';
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<TodoItem> _notifyTodos(AppState state) {
    final todos = state.focusService
        .getTodos()
        .where((item) {
          if (!item.hasReminder || item.completed || item.id == null) {
            return false;
          }
          final viewData = buildLifeNotifyTodoViewData(item);
          return (item.category == _notifyCategory ||
                  (isLifeNotifyCategory(item.category) &&
                      !viewData.metadata.isFakeCall)) &&
              !viewData.metadata.isFakeCall;
        })
        .toList(growable: false);
    todos.sort((left, right) {
      final leftDue = left.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDue = right.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return leftDue.compareTo(rightDue);
    });
    return todos;
  }

  String _formatDate(DateTime value) {
    final material = MaterialLocalizations.of(context);
    return material.formatMediumDate(value);
  }

  String _formatTime(DateTime value) {
    final material = MaterialLocalizations.of(context);
    return material.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: true,
    );
  }

  String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${_formatTime(value)}';
  }

  String _presentationLabel(LifeNotifyPresentationType type) {
    return switch (type) {
      LifeNotifyPresentationType.notification => _lifeI18nText(
        context,
        'inline.plan295.life.status_bar_notification.18388d7086db',
      ),
      LifeNotifyPresentationType.alarm => _lifeI18nText(
        context,
        'inline.plan295.life.lock_screen_alert.9925aa5a6e36',
      ),
      LifeNotifyPresentationType.fakeCall => _lifeI18nText(
        context,
        'inline.plan295.life.fake_incoming_call.a3cd1b946f9f',
      ),
    };
  }

  String _scheduleLabel(LifeNotifyScheduleType type) {
    return switch (type) {
      LifeNotifyScheduleType.dateTime => _lifeI18nText(
        context,
        'inline.plan295.life.fixed_time.6fd29885b880',
      ),
      LifeNotifyScheduleType.countdown => _lifeI18nText(
        context,
        'inline.ui.pages.toolbox_human_tests_time_perception.countdown_da672d',
      ),
    };
  }

  String _leadLabel(int value) {
    if (value <= 0) {
      return _lifeI18nText(context, 'inline.plan295.life.on_time.7d3451c72e34');
    }
    if (value < 60) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.notify.me.min_earlier.2126919029',
        params: <String, Object?>{'value': value},
      );
    }
    final hours = (value / 60).toStringAsFixed(value % 60 == 0 ? 0 : 1);
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.notify.me.h_earlier.d373fb6390',
      params: <String, Object?>{'hours': hours},
    );
  }

  String _countdownLabel(int value) {
    if (value < 60) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.notify.me.in_min.d14647b3ba',
        params: <String, Object?>{'value': value},
      );
    }
    final hours = (value / 60).toStringAsFixed(value % 60 == 0 ? 0 : 1);
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.notify.me.in_h.5b681a51ba',
      params: <String, Object?>{'hours': hours},
    );
  }

  String _reminderStateLabel(TodoItem item) {
    final dueAt = item.dueAt;
    if (dueAt == null) {
      return _lifeI18nText(context, 'inline.plan295.life.no_time.f065e511c569');
    }
    if (dueAt.isBefore(DateTime.now())) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.triggered.7f04e3959161',
      );
    }
    return _lifeI18nText(context, 'inline.plan295.life.scheduled.7f0c64868b4e');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final focus = state.focusService;
    final reminders = _notifyTodos(state);
    final metadata = _buildMetadata();
    final dueAt = _resolveDueTime();
    final alertAt = _resolveAlertTime(dueAt);
    final previewTitle = _titleController.text.trim().isEmpty
        ? _lifeI18nText(
            context,
            'inline.plan295.life.title_preview_appears_here.c49155e0eed5',
          )
        : _titleController.text.trim();
    final previewBody = metadata.note.trim().isEmpty
        ? _lifeI18nText(
            context,
            'inline.plan295.life.description_action_hint_or_a_short_n.f2dcb7e7d691',
          )
        : metadata.note.trim();
    final nextReminder = reminders.isEmpty ? null : reminders.first;

    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.notify_me.a1cb3fafbdd1',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.leave_yourself_actionable_prompts_th.f6bcb002e8ec',
      ),
      child: Column(
        key: const ValueKey<String>('life-notify-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _NotifyHeroPanel(
            title: previewTitle,
            body: previewBody,
            modeLabel: _presentationLabel(_presentationType),
            scheduleLabel: _scheduleLabel(_scheduleType),
            dueLabel: _formatDateTime(dueAt),
            alertLabel: _formatDateTime(alertAt),
            nextLabel: nextReminder == null
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.no_reminder_created.84fd806c0af4',
                  )
                : '${nextReminder.content} · ${_formatDateTime(nextReminder.dueAt!)}',
            nativeReady:
                state.todoSystemRemindersEnabled &&
                (!_supportsNativeReminder || _capability.notificationsGranted),
            calendarEnabled: _syncToSystemCalendar,
            sticky: metadata.stickyNotification,
            cancelOnOpen: metadata.cancelOnOpen,
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.delivery_capability.d0f091f20879',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.check_the_delivery_path_first_platfo.823a85407299',
            ),
            children: <Widget>[
              SwitchListTile(
                value: state.todoSystemRemindersEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.enable_app_reminders.a0096ea88257',
                  ),
                ),
                subtitle: Text(
                  _supportsNativeReminder
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.when_enabled_android_status_bar_and.a5e996081f38',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.life.this_platform_mainly_supports_page_s.74b759bb14b8',
                        ),
                ),
                onChanged: (value) =>
                    state.setTodoSystemRemindersEnabled(value),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _NotifyStatusChip(
                    icon: Icons.notifications_active_rounded,
                    label: _loadingCapability
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.life.checking_permission.af8208aa7018',
                          )
                        : _capability.notificationsGranted
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.life.notification_granted.9111301ce719',
                          )
                        : _lifeI18nText(
                            context,
                            'inline.plan295.life.notification_needed.2594b2c1b13f',
                          ),
                    active:
                        _loadingCapability || _capability.notificationsGranted,
                  ),
                  _NotifyStatusChip(
                    icon: Icons.alarm_on_rounded,
                    label: _loadingCapability
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.life.checking_alarm_access.43ca96e166bb',
                          )
                        : _capability.exactAlarmGranted
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.life.exact_alarm_ready.42eeee18df29',
                          )
                        : _lifeI18nText(
                            context,
                            'inline.plan295.life.exact_alarm_needed.59c42ae6c48f',
                          ),
                    active: _loadingCapability || _capability.exactAlarmGranted,
                  ),
                ],
              ),
              if (_capability.needsNotificationPermission) ...<Widget>[
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _requestNotificationPermission,
                  icon: const Icon(Icons.notification_add_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.request_notification_access.b9d2d4deca63',
                    ),
                  ),
                ),
              ],
              if (_capability.needsExactAlarmPermission) ...<Widget>[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openExactAlarmSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.open_exact_alarm_settings.0aca6c182c5d',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.create_reminder.beecee4bca34',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.write_what_to_remember_then_choose_w.069868c9cd66',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-notify-title'),
                controller: _titleController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.reminder_title.986b25c09cf7',
                  ),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-notify-note'),
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.reminder_note.04c5ea64f83b',
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _LifeSegmentedField<LifeNotifyPresentationType>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.presentation.ac3dd7df99b5',
                ),
                value: _presentationType,
                options: const <_LifeOption<LifeNotifyPresentationType>>[
                  _LifeOption<LifeNotifyPresentationType>(
                    value: LifeNotifyPresentationType.notification,
                    labelKey: 'inline.plan295.life.notification.a590187ec684',
                  ),
                  _LifeOption<LifeNotifyPresentationType>(
                    value: LifeNotifyPresentationType.alarm,
                    labelKey: 'inline.plan295.life.lock_screen.48f2558ba470',
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _presentationType = value;
                    if (value == LifeNotifyPresentationType.alarm) {
                      _stickyNotification = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              _LifeSegmentedField<LifeNotifyScheduleType>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.schedule.f2b78149b790',
                ),
                value: _scheduleType,
                options: const <_LifeOption<LifeNotifyScheduleType>>[
                  _LifeOption<LifeNotifyScheduleType>(
                    value: LifeNotifyScheduleType.dateTime,
                    labelKey: 'inline.plan295.life.fixed_time.6fd29885b880',
                  ),
                  _LifeOption<LifeNotifyScheduleType>(
                    value: LifeNotifyScheduleType.countdown,
                    labelKey:
                        'inline.ui.pages.toolbox_human_tests_time_perception.countdown_da672d',
                  ),
                ],
                onChanged: (value) => setState(() => _scheduleType = value),
              ),
              const SizedBox(height: 14),
              if (_scheduleType == LifeNotifyScheduleType.dateTime)
                _buildDateTimeControls()
              else
                _buildCountdownControls(),
              const SizedBox(height: 14),
              _buildDeliveryControls(),
              const SizedBox(height: 10),
              _NotifySummaryStrip(
                items: <String>[
                  _presentationLabel(_presentationType),
                  _scheduleLabel(_scheduleType),
                  _scheduleType == LifeNotifyScheduleType.dateTime
                      ? _leadLabel(_minutesBefore)
                      : _countdownLabel(_countdownMinutes),
                  _formatDateTime(alertAt),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey<String>('life-notify-create-button'),
                  onPressed: _creating ? null : _createReminder,
                  icon: const Icon(Icons.add_alert_rounded),
                  label: Text(
                    _creating
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.life.creating.a424312477e4',
                          )
                        : _lifeI18nText(
                            context,
                            'inline.plan295.life.create_reminder.7d32ca9b5129',
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.created_reminders.21beeb8a0bbd',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.unfinished_reminders_stay_here_inclu.55ecc9316296',
            ),
            children: <Widget>[
              if (reminders.isEmpty)
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.no_reminders_yet_create_one_for_your.3cbd0f1bd134',
                  ),
                  key: const ValueKey<String>('life-notify-empty'),
                )
              else
                Column(
                  key: const ValueKey<String>('life-notify-list'),
                  children: reminders
                      .map((item) {
                        final todoId = item.id!;
                        final viewData = buildLifeNotifyTodoViewData(item);
                        final meta = viewData.metadata;
                        return _NotifyReminderCard(
                          key: ValueKey<String>('life-notify-item-$todoId'),
                          title: item.content,
                          note: meta.note.trim(),
                          stateLabel: _reminderStateLabel(item),
                          dueLabel: _formatDateTime(item.dueAt!),
                          presentationLabel: _presentationLabel(
                            meta.presentationType,
                          ),
                          sticky: meta.stickyNotification,
                          calendarEnabled: item.syncToSystemCalendar,
                          onComplete: () {
                            focus.completeTodo(todoId);
                            _showSnack(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.reminder_completed.514f4213b202',
                              ),
                            );
                          },
                          onSnooze10: () {
                            focus.snoozeTodoReminder(
                              todoId,
                              const Duration(minutes: 10),
                            );
                            _showSnack(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.snoozed_for_10_min.80902e7300ea',
                              ),
                            );
                          },
                          onSnooze60: () {
                            focus.snoozeTodoReminder(
                              todoId,
                              const Duration(hours: 1),
                            );
                            _showSnack(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.snoozed_for_1_hour.9547271b8a0f',
                              ),
                            );
                          },
                          onReuse: () => _reuseReminder(item),
                          onDelete: () {
                            focus.deleteTodo(todoId);
                            _showSnack(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.reminder_deleted.4c7b08816cf3',
                              ),
                            );
                          },
                        );
                      })
                      .toList(growable: false),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey<String>('life-notify-date-button'),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(_formatDate(_scheduledAt)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey<String>('life-notify-time-button'),
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time_rounded),
                label: Text(_formatTime(_scheduledAt)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _lifeI18nText(context, 'inline.plan295.life.lead_time.ba1f6a261083'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _leadPresets
              .map(
                (value) => ChoiceChip(
                  selected: _minutesBefore == value,
                  label: Text(_leadLabel(value)),
                  onSelected: (_) => _setLeadMinutes(value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        _NotifyMinuteInput(
          controller: _leadController,
          label: _lifeI18nText(
            context,
            'inline.plan295.life.custom_lead_minutes.755573a9fbcc',
          ),
          min: 0,
          max: _maxMinutes,
          onChanged: _setLeadMinutes,
        ),
      ],
    );
  }

  Widget _buildCountdownControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.countdown_length.53382bdbee24',
          ),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _countdownPresets
              .map(
                (value) => ChoiceChip(
                  selected: _countdownMinutes == value,
                  label: Text(_countdownLabel(value)),
                  onSelected: (_) => _setCountdownMinutes(value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        _NotifyMinuteInput(
          controller: _countdownController,
          label: _lifeI18nText(
            context,
            'inline.plan295.life.custom_countdown_minutes.2696b990b3a6',
          ),
          min: 1,
          max: _maxMinutes,
          onChanged: _setCountdownMinutes,
        ),
      ],
    );
  }

  Widget _buildDeliveryControls() {
    return Column(
      children: <Widget>[
        SwitchListTile(
          value: _stickyNotification,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.sticky_status_bar_reminder.95c309f042c4',
            ),
          ),
          subtitle: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.keep_it_in_the_notification_shade_un.456ed5c02dab',
            ),
          ),
          onChanged:
              _presentationType == LifeNotifyPresentationType.notification
              ? (value) => setState(() => _stickyNotification = value)
              : null,
        ),
        SwitchListTile(
          value: _cancelOnOpen,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.cancel_when_opening_the_app.a6c4e7c0a317',
            ),
          ),
          subtitle: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.when_off_tapping_the_reminder_opens.eca06e03c62f',
            ),
          ),
          onChanged: (value) => setState(() => _cancelOnOpen = value),
        ),
        SwitchListTile(
          value: _syncToSystemCalendar,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeI18nText(
              context,
              'inline.ui.pages.focus_page_workspace_editor.sync_to_system_calendar_488722',
            ),
          ),
          subtitle: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.when_supported_a_mirrored_calendar_e.c857b55e1e39',
            ),
          ),
          onChanged: (value) => setState(() => _syncToSystemCalendar = value),
        ),
      ],
    );
  }
}

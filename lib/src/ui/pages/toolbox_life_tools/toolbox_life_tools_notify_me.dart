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
        _lifeText(context, zh: '请先输入提醒标题', en: 'Enter a reminder title first'),
      );
      return;
    }

    final dueAt = _resolveDueTime();
    final alertAt = _resolveAlertTime(dueAt);
    final now = DateTime.now();
    if (!dueAt.isAfter(now)) {
      _showSnack(
        _lifeText(
          context,
          zh: '提醒时间需要晚于当前时间',
          en: 'Reminder time must be in the future',
        ),
      );
      return;
    }
    if (!alertAt.isAfter(now)) {
      _showSnack(
        _lifeText(
          context,
          zh: '提前提醒已经早于当前时间，请缩短提前时间或改晚提醒时间',
          en: 'The lead time would fire in the past. Shorten it or choose a later reminder time.',
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
      _showSnack(_lifeText(context, zh: '提醒已创建', en: 'Reminder created'));
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
      _lifeText(context, zh: '已套用这条提醒的配置', en: 'Reminder settings copied'),
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
      LifeNotifyPresentationType.notification => _lifeText(
        context,
        zh: '状态栏通知',
        en: 'Status-bar notification',
      ),
      LifeNotifyPresentationType.alarm => _lifeText(
        context,
        zh: '锁屏提醒',
        en: 'Lock-screen alert',
      ),
      LifeNotifyPresentationType.fakeCall => _lifeText(
        context,
        zh: '模拟来电',
        en: 'Fake incoming call',
      ),
    };
  }

  String _scheduleLabel(LifeNotifyScheduleType type) {
    return switch (type) {
      LifeNotifyScheduleType.dateTime => _lifeText(
        context,
        zh: '指定时间',
        en: 'Fixed time',
      ),
      LifeNotifyScheduleType.countdown => _lifeText(
        context,
        zh: '倒计时',
        en: 'Countdown',
      ),
    };
  }

  String _leadLabel(int value) {
    if (value <= 0) {
      return _lifeText(context, zh: '准时', en: 'On time');
    }
    if (value < 60) {
      return _lifeText(context, zh: '提前 $value 分钟', en: '$value min earlier');
    }
    final hours = (value / 60).toStringAsFixed(value % 60 == 0 ? 0 : 1);
    return _lifeText(context, zh: '提前 $hours 小时', en: '$hours h earlier');
  }

  String _countdownLabel(int value) {
    if (value < 60) {
      return _lifeText(context, zh: '$value 分钟后', en: 'In $value min');
    }
    final hours = (value / 60).toStringAsFixed(value % 60 == 0 ? 0 : 1);
    return _lifeText(context, zh: '$hours 小时后', en: 'In $hours h');
  }

  String _reminderStateLabel(TodoItem item) {
    final dueAt = item.dueAt;
    if (dueAt == null) {
      return _lifeText(context, zh: '未设置时间', en: 'No time');
    }
    if (dueAt.isBefore(DateTime.now())) {
      return _lifeText(context, zh: '已触发，等待处理', en: 'Triggered');
    }
    return _lifeText(context, zh: '待触发', en: 'Scheduled');
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
        ? _lifeText(context, zh: '提醒标题会显示在这里', en: 'Title preview appears here')
        : _titleController.text.trim();
    final previewBody = metadata.note.trim().isEmpty
        ? _lifeText(
            context,
            zh: '说明、待办细节或给自己的短句会显示在这里',
            en: 'Description, action hint, or a short note appears here',
          )
        : metadata.note.trim();
    final nextReminder = reminders.isEmpty ? null : reminders.first;

    return ToolboxToolPage(
      title: _lifeText(context, zh: '通知自己', en: 'Notify me'),
      subtitle: _lifeText(
        context,
        zh: '用状态栏、锁屏提醒和系统日历给自己留下一条可执行的提示。',
        en: 'Leave yourself actionable prompts through notifications, lock-screen alerts, and calendar mirroring.',
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
                ? _lifeText(context, zh: '暂无已创建提醒', en: 'No reminder created')
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
            title: _lifeText(context, zh: '投递能力', en: 'Delivery capability'),
            subtitle: _lifeText(
              context,
              zh: '先确认提醒链路是否可用；不支持完整原生提醒的平台仍会保留页面列表和日历镜像。',
              en: 'Check the delivery path first. Platforms without native reminders still keep the in-app list and calendar mirror.',
            ),
            children: <Widget>[
              SwitchListTile(
                value: state.todoSystemRemindersEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _lifeText(context, zh: '启用应用提醒', en: 'Enable app reminders'),
                ),
                subtitle: Text(
                  _supportsNativeReminder
                      ? _lifeText(
                          context,
                          zh: '开启后会调度 Android 状态栏与锁屏提醒。',
                          en: 'When enabled, Android status-bar and lock-screen reminders are scheduled.',
                        )
                      : _lifeText(
                          context,
                          zh: '当前平台以页面管理和系统日历镜像为主。',
                          en: 'This platform mainly supports page-side management and calendar mirroring.',
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
                        ? _lifeText(
                            context,
                            zh: '通知权限检查中',
                            en: 'Checking permission',
                          )
                        : _capability.notificationsGranted
                        ? _lifeText(
                            context,
                            zh: '通知权限已允许',
                            en: 'Notification granted',
                          )
                        : _lifeText(
                            context,
                            zh: '通知权限待开启',
                            en: 'Notification needed',
                          ),
                    active:
                        _loadingCapability || _capability.notificationsGranted,
                  ),
                  _NotifyStatusChip(
                    icon: Icons.alarm_on_rounded,
                    label: _loadingCapability
                        ? _lifeText(
                            context,
                            zh: '精确闹钟检查中',
                            en: 'Checking alarm access',
                          )
                        : _capability.exactAlarmGranted
                        ? _lifeText(
                            context,
                            zh: '精确闹钟可用',
                            en: 'Exact alarm ready',
                          )
                        : _lifeText(
                            context,
                            zh: '精确闹钟待确认',
                            en: 'Exact alarm needed',
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
                    _lifeText(
                      context,
                      zh: '请求通知权限',
                      en: 'Request notification access',
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
                    _lifeText(
                      context,
                      zh: '打开精确闹钟设置',
                      en: 'Open exact-alarm settings',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '新建提醒', en: 'Create reminder'),
            subtitle: _lifeText(
              context,
              zh: '先写清楚要提醒什么，再决定何时触发、用哪种提醒强度以及是否同步到日历。',
              en: 'Write what to remember, then choose when it fires, how strong it appears, and whether it mirrors to calendar.',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-notify-title'),
                controller: _titleController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(
                    context,
                    zh: '提醒标题',
                    en: 'Reminder title',
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
                  labelText: _lifeText(
                    context,
                    zh: '提醒说明',
                    en: 'Reminder note',
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _LifeSegmentedField<LifeNotifyPresentationType>(
                label: _lifeText(context, zh: '提醒强度', en: 'Presentation'),
                value: _presentationType,
                options: const <_LifeOption<LifeNotifyPresentationType>>[
                  _LifeOption<LifeNotifyPresentationType>(
                    value: LifeNotifyPresentationType.notification,
                    labelZh: '状态栏通知',
                    labelEn: 'Notification',
                  ),
                  _LifeOption<LifeNotifyPresentationType>(
                    value: LifeNotifyPresentationType.alarm,
                    labelZh: '锁屏提醒',
                    labelEn: 'Lock-screen',
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
                label: _lifeText(context, zh: '触发方式', en: 'Schedule'),
                value: _scheduleType,
                options: const <_LifeOption<LifeNotifyScheduleType>>[
                  _LifeOption<LifeNotifyScheduleType>(
                    value: LifeNotifyScheduleType.dateTime,
                    labelZh: '指定时间',
                    labelEn: 'Fixed time',
                  ),
                  _LifeOption<LifeNotifyScheduleType>(
                    value: LifeNotifyScheduleType.countdown,
                    labelZh: '倒计时',
                    labelEn: 'Countdown',
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
                        ? _lifeText(context, zh: '创建中...', en: 'Creating...')
                        : _lifeText(context, zh: '创建提醒', en: 'Create reminder'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '已创建提醒', en: 'Created reminders'),
            subtitle: _lifeText(
              context,
              zh: '这里集中处理未完成提醒；过期提醒会保留，方便完成、删除或稍后提醒。',
              en: 'Unfinished reminders stay here, including triggered ones, so you can complete, delete, or snooze them.',
            ),
            children: <Widget>[
              if (reminders.isEmpty)
                Text(
                  _lifeText(
                    context,
                    zh: '还没有提醒。先在上方创建一个给自己的提醒。',
                    en: 'No reminders yet. Create one for yourself above.',
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
                              _lifeText(
                                context,
                                zh: '提醒已完成',
                                en: 'Reminder completed',
                              ),
                            );
                          },
                          onSnooze10: () {
                            focus.snoozeTodoReminder(
                              todoId,
                              const Duration(minutes: 10),
                            );
                            _showSnack(
                              _lifeText(
                                context,
                                zh: '已稍后 10 分钟',
                                en: 'Snoozed for 10 min',
                              ),
                            );
                          },
                          onSnooze60: () {
                            focus.snoozeTodoReminder(
                              todoId,
                              const Duration(hours: 1),
                            );
                            _showSnack(
                              _lifeText(
                                context,
                                zh: '已稍后 1 小时',
                                en: 'Snoozed for 1 hour',
                              ),
                            );
                          },
                          onReuse: () => _reuseReminder(item),
                          onDelete: () {
                            focus.deleteTodo(todoId);
                            _showSnack(
                              _lifeText(
                                context,
                                zh: '提醒已删除',
                                en: 'Reminder deleted',
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
          _lifeText(context, zh: '提前提醒', en: 'Lead time'),
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
          label: _lifeText(context, zh: '自定义提前分钟', en: 'Custom lead minutes'),
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
          _lifeText(context, zh: '倒计时长度', en: 'Countdown length'),
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
          label: _lifeText(
            context,
            zh: '自定义倒计时分钟',
            en: 'Custom countdown minutes',
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
            _lifeText(context, zh: '状态栏常驻', en: 'Sticky status-bar reminder'),
          ),
          subtitle: Text(
            _lifeText(
              context,
              zh: '触发后保持在通知栏，直到完成、稍后提醒、删除或按设置进入应用取消。',
              en: 'Keep it in the notification shade until completed, snoozed, deleted, or dismissed by open-app behavior.',
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
            _lifeText(
              context,
              zh: '进入应用后取消提醒',
              en: 'Cancel when opening the app',
            ),
          ),
          subtitle: Text(
            _lifeText(
              context,
              zh: '关闭后，点击通知进入应用不会自动移除常驻通知，适合需要反复看到的提醒。',
              en: 'When off, tapping the reminder opens the app without dismissing a sticky notification.',
            ),
          ),
          onChanged: (value) => setState(() => _cancelOnOpen = value),
        ),
        SwitchListTile(
          value: _syncToSystemCalendar,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeText(context, zh: '同步到系统日历', en: 'Sync to system calendar'),
          ),
          subtitle: Text(
            _lifeText(
              context,
              zh: '支持时会写入系统日历事件，并保留备注与提醒时间。',
              en: 'When supported, a mirrored calendar event is written with the note and reminder timing.',
            ),
          ),
          onChanged: (value) => setState(() => _syncToSystemCalendar = value),
        ),
      ],
    );
  }
}

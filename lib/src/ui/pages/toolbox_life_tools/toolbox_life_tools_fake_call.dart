part of '../toolbox_life_tools.dart';

enum _FakeCallScheduleMode { countdown, fixedTime }

enum _FakeCallCountdownUnit { seconds, minutes, hours }

enum _FakeCallBackgroundStyle { cover, dim, blur }

String _backgroundStyleCode(_FakeCallBackgroundStyle style) {
  return switch (style) {
    _FakeCallBackgroundStyle.cover => 'cover',
    _FakeCallBackgroundStyle.dim => 'dim',
    _FakeCallBackgroundStyle.blur => 'blur',
  };
}

List<_LifeOption<_FakeCallBackgroundStyle>> _fakeCallBackgroundStyleOptions() {
  return const <_LifeOption<_FakeCallBackgroundStyle>>[
    _LifeOption<_FakeCallBackgroundStyle>(
      value: _FakeCallBackgroundStyle.cover,
      labelZh: '原图',
      labelEn: 'Cover',
    ),
    _LifeOption<_FakeCallBackgroundStyle>(
      value: _FakeCallBackgroundStyle.dim,
      labelZh: '压暗',
      labelEn: 'Dim',
    ),
    _LifeOption<_FakeCallBackgroundStyle>(
      value: _FakeCallBackgroundStyle.blur,
      labelZh: '模糊',
      labelEn: 'Blur',
    ),
  ];
}

class _FakeCallToolPage extends StatefulWidget {
  const _FakeCallToolPage();

  @override
  State<_FakeCallToolPage> createState() => _FakeCallToolPageState();
}

class _FakeCallToolPageState extends State<_FakeCallToolPage> {
  final ToolboxFakeCallService _fakeCallService =
      PlatformToolboxFakeCallService();
  final TextEditingController _callerNameController = TextEditingController(
    text: 'Manager',
  );
  final TextEditingController _callerNumberController = TextEditingController(
    text: '+1 415 555 0198',
  );
  final TextEditingController _callerLocationController = TextEditingController(
    text: 'San Francisco, CA',
  );
  final TextEditingController _callerTagController = TextEditingController(
    text: 'Mobile',
  );
  final TextEditingController _countdownValueController = TextEditingController(
    text: '15',
  );

  _FakeCallScheduleMode _scheduleMode = _FakeCallScheduleMode.countdown;
  _FakeCallCountdownUnit _countdownUnit = _FakeCallCountdownUnit.seconds;
  late DateTime _fixedTriggerAt;
  DateTime? _activeTriggerAt;
  int? _activeCallId;
  Timer? _fallbackTimer;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _ringtoneEnabled = true;
  bool _vibrationEnabled = true;
  bool _starting = false;
  bool _loadingCapability = true;
  bool _nativeScheduled = false;
  String _incomingBackgroundPath = '';
  String _inCallBackgroundPath = '';
  _FakeCallBackgroundStyle _incomingBackgroundStyle =
      _FakeCallBackgroundStyle.cover;
  _FakeCallBackgroundStyle _inCallBackgroundStyle =
      _FakeCallBackgroundStyle.cover;
  ToolboxFakeCallCapability _capability = ToolboxFakeCallCapability.fallback;

  @override
  void initState() {
    super.initState();
    _fixedTriggerAt = _initialTriggerAt();
    _loadCapability();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _ticker?.cancel();
    _callerNameController.dispose();
    _callerNumberController.dispose();
    _callerLocationController.dispose();
    _callerTagController.dispose();
    _countdownValueController.dispose();
    super.dispose();
  }

  bool get _hasActiveCall => _activeTriggerAt != null && _activeCallId != null;

  DateTime _initialTriggerAt() {
    final now = DateTime.now().add(const Duration(minutes: 5));
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  Future<void> _loadCapability() async {
    final capability = await _fakeCallService.getCapability();
    if (!mounted) {
      return;
    }
    setState(() {
      _capability = capability;
      _loadingCapability = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    await _fakeCallService.requestNotificationPermission();
    await _loadCapability();
  }

  Future<void> _openExactAlarmSettings() async {
    await _fakeCallService.openExactAlarmSettings();
    await _loadCapability();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fixedTriggerAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _fixedTriggerAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _fixedTriggerAt.hour,
        _fixedTriggerAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fixedTriggerAt),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _fixedTriggerAt = DateTime(
        _fixedTriggerAt.year,
        _fixedTriggerAt.month,
        _fixedTriggerAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Duration? _resolveCountdownDuration() {
    final value = int.tryParse(_countdownValueController.text.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return switch (_countdownUnit) {
      _FakeCallCountdownUnit.seconds => Duration(seconds: value),
      _FakeCallCountdownUnit.minutes => Duration(minutes: value),
      _FakeCallCountdownUnit.hours => Duration(hours: value),
    };
  }

  DateTime? _resolveTriggerAt() {
    if (_scheduleMode == _FakeCallScheduleMode.fixedTime) {
      return _fixedTriggerAt;
    }
    final duration = _resolveCountdownDuration();
    if (duration == null) {
      return null;
    }
    return DateTime.now().add(duration);
  }

  ToolboxFakeCallSpec _buildSpec({
    required int callId,
    required DateTime triggerAt,
  }) {
    return ToolboxFakeCallSpec(
      callId: callId,
      triggerAt: triggerAt,
      callerName: _callerNameController.text.trim(),
      callerNumber: _callerNumberController.text.trim(),
      callerLocation: _callerLocationController.text.trim(),
      callerTag: _callerTagController.text.trim(),
      ringtoneEnabled: _ringtoneEnabled,
      vibrationEnabled: _vibrationEnabled,
      incomingBackgroundPath: _incomingBackgroundPath,
      incomingBackgroundStyle: _backgroundStyleCode(_incomingBackgroundStyle),
      inCallBackgroundPath: _inCallBackgroundPath,
      inCallBackgroundStyle: _backgroundStyleCode(_inCallBackgroundStyle),
    );
  }

  Future<void> _pickBackground({required bool incoming}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    final filePath = result?.files.single.path?.trim();
    if (filePath == null || filePath.isEmpty || !mounted) {
      return;
    }
    setState(() {
      if (incoming) {
        _incomingBackgroundPath = filePath;
      } else {
        _inCallBackgroundPath = filePath;
      }
    });
  }

  void _clearBackground({required bool incoming}) {
    setState(() {
      if (incoming) {
        _incomingBackgroundPath = '';
      } else {
        _inCallBackgroundPath = '';
      }
    });
  }

  Future<void> _startFakeCall() async {
    final triggerAt = _resolveTriggerAt();
    if (triggerAt == null) {
      _showSnack(
        _lifeText(
          context,
          zh: '请输入大于 0 的倒计时时长',
          en: 'Enter a countdown longer than 0',
        ),
      );
      return;
    }
    if (!triggerAt.isAfter(DateTime.now())) {
      _showSnack(
        _lifeText(
          context,
          zh: '触发时间需要晚于当前时间',
          en: 'Trigger time must be in the future',
        ),
      );
      return;
    }
    final remaining = triggerAt.difference(DateTime.now());
    if (remaining > const Duration(days: 30)) {
      _showSnack(
        _lifeText(
          context,
          zh: '模拟来电最长支持 30 天内触发',
          en: 'Fake calls can be scheduled up to 30 days ahead',
        ),
      );
      return;
    }
    final callerLabel = _callerLabel();
    if (callerLabel.trim().isEmpty) {
      _showSnack(
        _lifeText(
          context,
          zh: '请至少填写来电姓名或号码',
          en: 'Enter at least a caller name or number',
        ),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      await _cancelActiveCall(showMessage: false);
      final callId = DateTime.now().millisecondsSinceEpoch.remainder(
        0x3fffffff,
      );
      final spec = _buildSpec(callId: callId, triggerAt: triggerAt);
      final result = await _fakeCallService.scheduleFakeCall(spec);
      if (!mounted) {
        return;
      }
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(triggerAt.difference(DateTime.now()), () {
        if (!mounted || _activeCallId != callId) {
          return;
        }
        _showInAppIncomingCall();
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _refreshRemaining();
      });
      setState(() {
        _activeCallId = callId;
        _activeTriggerAt = triggerAt;
        _nativeScheduled = result.nativeScheduled;
        _remaining = triggerAt.difference(DateTime.now());
      });
      _showSnack(
        result.nativeScheduled
            ? _lifeText(
                context,
                zh: '已开始等待，到点将全屏播放模拟来电',
                en: 'Started. The fake call will play full-screen at the trigger time',
              )
            : _lifeText(
                context,
                zh: '已开始前台等待，到点会在应用内全屏播放',
                en: 'Started with in-app fallback. Keep this page open for full-screen playback',
              ),
      );
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _previewNow() async {
    final callId = DateTime.now().millisecondsSinceEpoch.remainder(0x3fffffff);
    final spec = _buildSpec(callId: callId, triggerAt: DateTime.now());
    final shown = await _fakeCallService.showFakeCallNow(spec);
    if (!shown && mounted) {
      await _pushInAppIncomingCall();
    }
  }

  Future<void> _cancelActiveCall({bool showMessage = true}) async {
    final callId = _activeCallId;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _ticker?.cancel();
    _ticker = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _activeCallId = null;
      _activeTriggerAt = null;
      _nativeScheduled = false;
      _remaining = Duration.zero;
    });
    if (showMessage) {
      _showSnack(
        _lifeText(context, zh: '已取消本次模拟来电', en: 'Fake call cancelled'),
      );
    }
    if (callId != null) {
      await _fakeCallService.cancelFakeCall(callId);
    }
  }

  void _refreshRemaining() {
    final triggerAt = _activeTriggerAt;
    if (!mounted || triggerAt == null) {
      return;
    }
    final remaining = triggerAt.difference(DateTime.now());
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  Future<void> _showInAppIncomingCall() async {
    await _cancelActiveCall(showMessage: false);
    if (!mounted) {
      return;
    }
    await _pushInAppIncomingCall();
  }

  Future<void> _pushInAppIncomingCall() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FakeCallInAppScreen(
          callerName: _callerNameController.text.trim(),
          callerNumber: _callerNumberController.text.trim(),
          callerLocation: _callerLocationController.text.trim(),
          callerTag: _callerTagController.text.trim(),
          ringtoneEnabled: _ringtoneEnabled,
          vibrationEnabled: _vibrationEnabled,
          incomingBackgroundPath: _incomingBackgroundPath,
          incomingBackgroundStyle: _backgroundStyleCode(
            _incomingBackgroundStyle,
          ),
          inCallBackgroundPath: _inCallBackgroundPath,
          inCallBackgroundStyle: _backgroundStyleCode(_inCallBackgroundStyle),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _callerLabel() {
    final name = _callerNameController.text.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return _callerNumberController.text.trim();
  }

  String _callerNumberLabel() {
    final number = _callerNumberController.text.trim();
    if (number.isNotEmpty) {
      return number;
    }
    return _lifeText(context, zh: '未知号码', en: 'Unknown number');
  }

  String _formatDate(DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }

  String _formatTime(DateTime value) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: true,
    );
  }

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _countdownUnitLabel(_FakeCallCountdownUnit unit) {
    return switch (unit) {
      _FakeCallCountdownUnit.seconds => _lifeText(
        context,
        zh: '秒',
        en: 'Seconds',
      ),
      _FakeCallCountdownUnit.minutes => _lifeText(
        context,
        zh: '分钟',
        en: 'Minutes',
      ),
      _FakeCallCountdownUnit.hours => _lifeText(context, zh: '小时', en: 'Hours'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final triggerAt = _activeTriggerAt ?? _resolveTriggerAt();
    final theme = Theme.of(context);

    return ToolboxToolPage(
      title: _lifeText(context, zh: '模拟来电', en: 'Fake incoming call'),
      subtitle: _lifeText(
        context,
        zh: '点击开始后等待指定时间，到点全屏播放模拟来电、铃声和震动。',
        en: 'Tap start, wait for the selected time, then play a full-screen fake incoming call with ringtone and vibration.',
      ),
      child: Column(
        key: const ValueKey<String>('life-fake-call-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FakeCallStage(
            callerName: _callerLabel().isEmpty
                ? _lifeText(context, zh: '模拟来电', en: 'Fake incoming call')
                : _callerLabel(),
            callerNumber: _callerNumberLabel(),
            callerLocation: _callerLocationController.text.trim(),
            callerTag: _callerTagController.text.trim(),
            active: _hasActiveCall,
            remainingText: _hasActiveCall
                ? _formatDuration(_remaining)
                : triggerAt == null
                ? '--:--'
                : '${_formatDate(triggerAt)} ${_formatTime(triggerAt)}',
            nativeScheduled: _nativeScheduled,
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '背景样式', en: 'Background style'),
            subtitle: _lifeText(
              context,
              zh: '来电触发和接听后的通话界面可以使用不同背景。',
              en: 'Incoming and accepted-call screens can use different backgrounds.',
            ),
            children: <Widget>[
              _FakeCallBackgroundPicker(
                key: const ValueKey<String>(
                  'life-fake-call-incoming-background',
                ),
                title: _lifeText(
                  context,
                  zh: '来电背景',
                  en: 'Incoming background',
                ),
                subtitle: _lifeText(
                  context,
                  zh: '用于全屏来电响铃界面。',
                  en: 'Used on the full-screen ringing interface.',
                ),
                imagePath: _incomingBackgroundPath,
                style: _incomingBackgroundStyle,
                pickButtonKey: const ValueKey<String>(
                  'life-fake-call-incoming-background-button',
                ),
                clearButtonKey: const ValueKey<String>(
                  'life-fake-call-incoming-background-clear',
                ),
                onPick: () => _pickBackground(incoming: true),
                onClear: () => _clearBackground(incoming: true),
                onStyleChanged: (value) =>
                    setState(() => _incomingBackgroundStyle = value),
              ),
              const SizedBox(height: 12),
              _FakeCallBackgroundPicker(
                key: const ValueKey<String>('life-fake-call-incall-background'),
                title: _lifeText(context, zh: '通话背景', en: 'In-call background'),
                subtitle: _lifeText(
                  context,
                  zh: '接听后进入通话计时界面使用。',
                  en: 'Used after accepting the call.',
                ),
                imagePath: _inCallBackgroundPath,
                style: _inCallBackgroundStyle,
                pickButtonKey: const ValueKey<String>(
                  'life-fake-call-incall-background-button',
                ),
                clearButtonKey: const ValueKey<String>(
                  'life-fake-call-incall-background-clear',
                ),
                onPick: () => _pickBackground(incoming: false),
                onClear: () => _clearBackground(incoming: false),
                onStyleChanged: (value) =>
                    setState(() => _inCallBackgroundStyle = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '来电信息', en: 'Caller details'),
            subtitle: _lifeText(
              context,
              zh: '这些内容会显示在全屏来电界面上。',
              en: 'These details appear on the full-screen call UI.',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-fake-call-caller-name'),
                controller: _callerNameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(context, zh: '来电姓名', en: 'Caller name'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-fake-call-caller-number'),
                controller: _callerNumberController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(
                    context,
                    zh: '来电号码',
                    en: 'Caller number',
                  ),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>(
                        'life-fake-call-caller-location',
                      ),
                      controller: _callerLocationController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _lifeText(
                          context,
                          zh: '归属地',
                          en: 'Location',
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('life-fake-call-caller-tag'),
                      controller: _callerTagController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _lifeText(context, zh: '标签', en: 'Label'),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '触发时间', en: 'Trigger time'),
            subtitle: _lifeText(
              context,
              zh: '选择倒计时或指定时间。开始后到点直接进入全屏来电。',
              en: 'Choose a countdown or fixed time. Once started, the call screen appears at the trigger time.',
            ),
            children: <Widget>[
              _LifeSegmentedField<_FakeCallScheduleMode>(
                label: _lifeText(context, zh: '启动方式', en: 'Start mode'),
                value: _scheduleMode,
                options: const <_LifeOption<_FakeCallScheduleMode>>[
                  _LifeOption<_FakeCallScheduleMode>(
                    value: _FakeCallScheduleMode.countdown,
                    labelZh: '倒计时',
                    labelEn: 'Countdown',
                  ),
                  _LifeOption<_FakeCallScheduleMode>(
                    value: _FakeCallScheduleMode.fixedTime,
                    labelZh: '指定时间',
                    labelEn: 'Fixed time',
                  ),
                ],
                onChanged: _hasActiveCall
                    ? (_) {}
                    : (value) => setState(() => _scheduleMode = value),
              ),
              const SizedBox(height: 12),
              if (_scheduleMode == _FakeCallScheduleMode.countdown)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: TextField(
                        key: const ValueKey<String>(
                          'life-fake-call-countdown-value',
                        ),
                        controller: _countdownValueController,
                        enabled: !_hasActiveCall,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _lifeText(
                            context,
                            zh: '倒计时时长',
                            en: 'Countdown length',
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<_FakeCallCountdownUnit>(
                        key: const ValueKey<String>(
                          'life-fake-call-countdown-unit',
                        ),
                        initialValue: _countdownUnit,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _lifeText(context, zh: '单位', en: 'Unit'),
                        ),
                        items: _FakeCallCountdownUnit.values
                            .map(
                              (unit) =>
                                  DropdownMenuItem<_FakeCallCountdownUnit>(
                                    value: unit,
                                    child: Text(_countdownUnitLabel(unit)),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: _hasActiveCall
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _countdownUnit = value);
                              },
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>(
                          'life-fake-call-date-button',
                        ),
                        onPressed: _hasActiveCall ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text(_formatDate(_fixedTriggerAt)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>(
                          'life-fake-call-time-button',
                        ),
                        onPressed: _hasActiveCall ? null : _pickTime,
                        icon: const Icon(Icons.access_time_rounded),
                        label: Text(_formatTime(_fixedTriggerAt)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '来电效果', en: 'Call effects'),
            children: <Widget>[
              SwitchListTile(
                value: _ringtoneEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _lifeText(context, zh: '播放系统铃声', en: 'Play ringtone'),
                ),
                onChanged: _hasActiveCall
                    ? null
                    : (value) => setState(() => _ringtoneEnabled = value),
              ),
              SwitchListTile(
                value: _vibrationEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(_lifeText(context, zh: '震动', en: 'Vibration')),
                onChanged: _hasActiveCall
                    ? null
                    : (value) => setState(() => _vibrationEnabled = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey<String>(
                        'life-fake-call-start-button',
                      ),
                      onPressed: _starting
                          ? null
                          : _hasActiveCall
                          ? () => _cancelActiveCall()
                          : _startFakeCall,
                      icon: Icon(
                        _hasActiveCall
                            ? Icons.call_end_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _starting
                            ? _lifeText(
                                context,
                                zh: '启动中...',
                                en: 'Starting...',
                              )
                            : _hasActiveCall
                            ? _lifeText(
                                context,
                                zh: '取消本次来电',
                                en: 'Cancel call',
                              )
                            : _lifeText(context, zh: '开始', en: 'Start'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    key: const ValueKey<String>(
                      'life-fake-call-preview-button',
                    ),
                    tooltip: _lifeText(context, zh: '立即预览', en: 'Preview now'),
                    onPressed: _previewNow,
                    icon: const Icon(Icons.phone_in_talk_rounded),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '触发能力', en: 'Delivery capability'),
            subtitle: _lifeText(
              context,
              zh: 'Android 可在锁屏或后台尝试全屏唤起来电；其他平台使用应用内前台触发。',
              en: 'Android can try to launch full-screen from lock screen or background. Other platforms use the in-app foreground fallback.',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(
                    label: Text(
                      _loadingCapability
                          ? _lifeText(context, zh: '能力检查中', en: 'Checking')
                          : _capability.nativeFullScreenSupported
                          ? _lifeText(
                              context,
                              zh: '原生全屏可用',
                              en: 'Native full-screen ready',
                            )
                          : _lifeText(
                              context,
                              zh: '应用内前台触发',
                              en: 'In-app foreground fallback',
                            ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      _capability.notificationsGranted
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
                    ),
                  ),
                  Chip(
                    label: Text(
                      _capability.exactAlarmGranted
                          ? _lifeText(
                              context,
                              zh: '准点触发可用',
                              en: 'Exact trigger ready',
                            )
                          : _lifeText(
                              context,
                              zh: '准点触发待确认',
                              en: 'Exact trigger needed',
                            ),
                    ),
                  ),
                ],
              ),
              if (_capability.needsNotificationPermission) ...<Widget>[
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _requestNotificationPermission,
                  child: Text(
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
                OutlinedButton(
                  onPressed: _openExactAlarmSettings,
                  child: Text(
                    _lifeText(
                      context,
                      zh: '打开精确闹钟设置',
                      en: 'Open exact-alarm settings',
                    ),
                  ),
                ),
              ],
              if (_hasActiveCall) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _nativeScheduled
                      ? _lifeText(
                          context,
                          zh: '已交给系统调度；页面保持打开时也会有应用内兜底。',
                          en: 'Scheduled natively; this page also keeps an in-app fallback while open.',
                        )
                      : _lifeText(
                          context,
                          zh: '当前使用应用内兜底，请保持页面打开。',
                          en: 'Using in-app fallback. Keep this page open.',
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeCallStage extends StatelessWidget {
  const _FakeCallStage({
    required this.callerName,
    required this.callerNumber,
    required this.callerLocation,
    required this.callerTag,
    required this.active,
    required this.remainingText,
    required this.nativeScheduled,
  });

  final String callerName;
  final String callerNumber;
  final String callerLocation;
  final String callerTag;
  final bool active;
  final String remainingText;
  final bool nativeScheduled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      if (callerLocation.isNotEmpty) callerLocation,
      if (callerTag.isNotEmpty) callerTag,
    ].join('  ·  ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF132536), Color(0xFF071018)],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                active
                    ? Icons.notifications_active_rounded
                    : Icons.call_rounded,
                color: const Color(0xFF7DD3FC),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active
                      ? _lifeText(
                          context,
                          zh: '等待来电触发',
                          en: 'Waiting for trigger',
                        )
                      : _lifeText(context, zh: '来电预览', en: 'Call preview'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFD8E4F0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  nativeScheduled
                      ? _lifeText(context, zh: '系统调度', en: 'Native')
                      : _lifeText(context, zh: '前台兜底', en: 'Fallback'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF20384E),
            ),
            alignment: Alignment.center,
            child: Text(
              callerName.characters.isEmpty
                  ? '?'
                  : callerName.characters.first.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            callerName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            callerNumber,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFD8E4F0),
            ),
          ),
          if (meta.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9FB2C5),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            remainingText,
            key: const ValueKey<String>('life-fake-call-remaining'),
            style: theme.textTheme.displaySmall?.copyWith(
              color: const Color(0xFF7DD3FC),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeCallBackgroundPicker extends StatelessWidget {
  const _FakeCallBackgroundPicker({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.style,
    required this.pickButtonKey,
    required this.clearButtonKey,
    required this.onPick,
    required this.onClear,
    required this.onStyleChanged,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final _FakeCallBackgroundStyle style;
  final Key pickButtonKey;
  final Key clearButtonKey;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final ValueChanged<_FakeCallBackgroundStyle> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imagePath.trim().isNotEmpty;
    final fileName = hasImage ? path.basename(imagePath) : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF20384E), Color(0xFF071018)],
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(imagePath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : const Icon(
                        Icons.wallpaper_rounded,
                        color: Colors.white70,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                    if (hasImage) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSegmentedField<_FakeCallBackgroundStyle>(
            label: _lifeText(context, zh: '显示样式', en: 'Display style'),
            value: style,
            options: _fakeCallBackgroundStyleOptions(),
            onChanged: onStyleChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                key: pickButtonKey,
                onPressed: onPick,
                icon: const Icon(Icons.image_rounded),
                label: Text(
                  hasImage
                      ? _lifeText(context, zh: '更换图片', en: 'Change image')
                      : _lifeText(context, zh: '选择图片', en: 'Choose image'),
                ),
              ),
              if (hasImage)
                TextButton.icon(
                  key: clearButtonKey,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(_lifeText(context, zh: '清除', en: 'Clear')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeCallInAppScreen extends StatefulWidget {
  const _FakeCallInAppScreen({
    required this.callerName,
    required this.callerNumber,
    required this.callerLocation,
    required this.callerTag,
    required this.ringtoneEnabled,
    required this.vibrationEnabled,
    required this.incomingBackgroundPath,
    required this.incomingBackgroundStyle,
    required this.inCallBackgroundPath,
    required this.inCallBackgroundStyle,
  });

  final String callerName;
  final String callerNumber;
  final String callerLocation;
  final String callerTag;
  final bool ringtoneEnabled;
  final bool vibrationEnabled;
  final String incomingBackgroundPath;
  final String incomingBackgroundStyle;
  final String inCallBackgroundPath;
  final String inCallBackgroundStyle;

  @override
  State<_FakeCallInAppScreen> createState() => _FakeCallInAppScreenState();
}

class _FakeCallInAppScreenState extends State<_FakeCallInAppScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _soundTimer;
  Timer? _vibrationTimer;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _enterLifePortraitImmersive();
    if (widget.ringtoneEnabled) {
      _startInAppSound();
    }
    if (widget.vibrationEnabled) {
      _startInAppVibration();
    }
  }

  @override
  void dispose() {
    _soundTimer?.cancel();
    _vibrationTimer?.cancel();
    _callTimer?.cancel();
    _cancelLifeVibration();
    _pulseController.dispose();
    _exitLifeImmersive();
    super.dispose();
  }

  void _startInAppVibration() {
    _playLifeVibrationPattern(
      timingsMs: const <int>[0, 300, 220, 520],
      amplitudes: const <int>[0, 210, 0, 255],
    );
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      _playLifeVibrationPattern(
        timingsMs: const <int>[0, 300, 220, 520],
        amplitudes: const <int>[0, 210, 0, 255],
      );
    });
  }

  void _startInAppSound() {
    SystemSound.play(SystemSoundType.alert);
    _soundTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      SystemSound.play(SystemSoundType.alert);
    });
  }

  void _stopIncomingEffects() {
    _soundTimer?.cancel();
    _soundTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _cancelLifeVibration();
  }

  void _accept() {
    _stopIncomingEffects();
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    _callTimer?.cancel();
    setState(() {
      _accepted = true;
      _callDuration = Duration.zero;
    });
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _callDuration += const Duration(seconds: 1);
      });
    });
  }

  void _finish() {
    _stopIncomingEffects();
    _callTimer?.cancel();
    Navigator.of(context).pop();
  }

  String _formatCallDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callerName = widget.callerName.trim().isEmpty
        ? _lifeText(context, zh: '模拟来电', en: 'Fake incoming call')
        : widget.callerName.trim();
    final callerNumber = widget.callerNumber.trim().isEmpty
        ? _lifeText(context, zh: '未知号码', en: 'Unknown number')
        : widget.callerNumber.trim();
    final meta = <String>[
      if (widget.callerLocation.trim().isNotEmpty) widget.callerLocation.trim(),
      if (widget.callerTag.trim().isNotEmpty) widget.callerTag.trim(),
    ].join('  ·  ');
    final backgroundPath = _accepted
        ? widget.inCallBackgroundPath
        : widget.incomingBackgroundPath;
    final backgroundStyle = _accepted
        ? widget.inCallBackgroundStyle
        : widget.incomingBackgroundStyle;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF071018),
        body: _FakeCallFullScreenBackground(
          imagePath: backgroundPath,
          styleCode: backgroundStyle,
          accepted: _accepted,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _accepted
                    ? _buildInCallContent(theme, callerName, callerNumber, meta)
                    : _buildIncomingContent(
                        theme,
                        callerName,
                        callerNumber,
                        meta,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingContent(
    ThemeData theme,
    String callerName,
    String callerNumber,
    String meta,
  ) {
    return Column(
      key: const ValueKey<String>('life-fake-call-incoming-screen'),
      children: <Widget>[
        Text(
          _lifeText(context, zh: '来电中', en: 'Incoming call'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1 + _pulseController.value * 0.08;
            return Transform.scale(scale: scale, child: child);
          },
          child: _FakeCallAvatar(
            callerName: callerName,
            size: 112,
            glowColor: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(height: 28),
        _FakeCallIdentityBlock(
          callerName: callerName,
          callerNumber: callerNumber,
          meta: meta,
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _FakeCallActionButton(
              label: _lifeText(context, zh: '拒绝', en: 'Decline'),
              icon: Icons.call_end_rounded,
              color: const Color(0xFFC24141),
              onPressed: _finish,
            ),
            const SizedBox(width: 26),
            _FakeCallActionButton(
              key: const ValueKey<String>('life-fake-call-accept-button'),
              label: _lifeText(context, zh: '接听', en: 'Accept'),
              icon: Icons.call_rounded,
              color: const Color(0xFF2E9C67),
              onPressed: _accept,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInCallContent(
    ThemeData theme,
    String callerName,
    String callerNumber,
    String meta,
  ) {
    return Column(
      key: const ValueKey<String>('life-fake-call-incall-screen'),
      children: <Widget>[
        Text(
          _lifeText(context, zh: '通话中', en: 'In call'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _formatCallDuration(_callDuration),
          key: const ValueKey<String>('life-fake-call-call-duration'),
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Expanded(
          child: Center(
            child: _FakeCallInCallStage(
              key: const ValueKey<String>('life-fake-call-incall-animation'),
              animation: _pulseController,
              callerName: callerName,
              callerNumber: callerNumber,
              meta: meta,
            ),
          ),
        ),
        _FakeCallActionButton(
          key: const ValueKey<String>('life-fake-call-hangup-button'),
          label: _lifeText(context, zh: '挂断', en: 'Hang up'),
          icon: Icons.call_end_rounded,
          color: const Color(0xFFC24141),
          onPressed: _finish,
        ),
      ],
    );
  }
}

class _FakeCallFullScreenBackground extends StatelessWidget {
  const _FakeCallFullScreenBackground({
    required this.imagePath,
    required this.styleCode,
    required this.accepted,
    required this.child,
  });

  final String imagePath;
  final String styleCode;
  final bool accepted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imagePath.trim().isNotEmpty && File(imagePath).existsSync();
    final overlayOpacity = switch (styleCode) {
      'dim' => 0.66,
      'blur' => 0.56,
      _ => 0.44,
    };
    final baseGradient = accepted
        ? const <Color>[Color(0xFF102A24), Color(0xFF071018)]
        : const <Color>[Color(0xFF132536), Color(0xFF071018)];
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: baseGradient,
        ),
        image: hasImage
            ? DecorationImage(
                image: FileImage(File(imagePath)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: overlayOpacity),
        ),
        child: child,
      ),
    );
    if (hasImage && styleCode == 'blur') {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: content,
      );
    }
    return content;
  }
}

class _FakeCallAvatar extends StatelessWidget {
  const _FakeCallAvatar({
    required this.callerName,
    required this.size,
    required this.glowColor,
  });

  final String callerName;
  final double size;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF20384E).withValues(alpha: 0.92),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 42,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        callerName.characters.isEmpty
            ? '?'
            : callerName.characters.first.toUpperCase(),
        style: theme.textTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FakeCallInCallStage extends StatelessWidget {
  const _FakeCallInCallStage({
    super.key,
    required this.animation,
    required this.callerName,
    required this.callerNumber,
    required this.meta,
  });

  final Animation<double> animation;
  final String callerName;
  final String callerNumber;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textReserve = meta.isNotEmpty ? 126.0 : 104.0;
        final heightLimit = math.max(
          160.0,
          constraints.maxHeight - textReserve,
        );
        final maxStage = math.min(constraints.maxWidth, heightLimit);
        final stageSize = maxStage.clamp(160.0, 380.0).toDouble();
        final avatarSize = (stageSize * 0.34).clamp(78.0, 132.0).toDouble();
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: stageSize,
              height: stageSize,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      for (var index = 0; index < 3; index += 1)
                        _FakeCallPulseRing(
                          progress: (animation.value + index / 3) % 1,
                          maxSize: stageSize,
                        ),
                      Container(
                        width: stageSize * 0.58,
                        height: stageSize * 0.58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      _FakeCallAvatar(
                        callerName: callerName,
                        size: avatarSize,
                        glowColor: const Color(0xFF22C55E),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _FakeCallIdentityBlock(
              callerName: callerName,
              callerNumber: callerNumber,
              meta: meta,
            ),
          ],
        );
      },
    );
  }
}

class _FakeCallPulseRing extends StatelessWidget {
  const _FakeCallPulseRing({required this.progress, required this.maxSize});

  final double progress;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final curved = Curves.easeOutCubic.transform(progress);
    final size = maxSize * (0.28 + curved * 0.68);
    final opacity = (1 - curved).clamp(0.0, 1.0) * 0.34;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}

class _FakeCallIdentityBlock extends StatelessWidget {
  const _FakeCallIdentityBlock({
    required this.callerName,
    required this.callerNumber,
    required this.meta,
  });

  final String callerName;
  final String callerNumber;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          callerName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          callerNumber,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFFD8E4F0),
          ),
        ),
        if (meta.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            meta,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ],
    );
  }
}

class _FakeCallActionButton extends StatelessWidget {
  const _FakeCallActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 68,
          height: 68,
          child: IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: color),
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

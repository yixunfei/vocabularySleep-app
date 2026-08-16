part of '../toolbox_life_tools.dart';

class _PhoneMonitorToolPage extends StatefulWidget {
  const _PhoneMonitorToolPage();

  @override
  State<_PhoneMonitorToolPage> createState() => _PhoneMonitorToolPageState();
}

class _PhoneMonitorToolPageState extends State<_PhoneMonitorToolPage> {
  Timer? _timer;
  Map<String, Object?> _snapshot = const <String, Object?>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported = _snapshot['supported'] as bool? ?? true;
    final battery = (_snapshot['batteryLevel'] as num?)?.toInt();
    final screenWidth = (_snapshot['screenWidthPx'] as num?)?.toInt();
    final screenHeight = (_snapshot['screenHeightPx'] as num?)?.toInt();
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.phone_monitor.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.phone_monitor.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.phone_monitor.stage'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.phone_monitor.stage_subtitle',
            ),
            children: <Widget>[
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (!supported)
                _LifeInlineNotice(
                  icon: Icons.settings_cell_rounded,
                  text: _lifeI18nText(
                    context,
                    'toolbox.life.phone_monitor.unsupported',
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'toolbox.life.phone_monitor.metric_battery',
                      ),
                      value: battery == null ? '--' : '$battery%',
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'toolbox.life.phone_monitor.metric_charge',
                      ),
                      value: _batteryStatusText(context),
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'toolbox.life.phone_monitor.metric_screen',
                      ),
                      value: screenWidth == null || screenHeight == null
                          ? '--'
                          : '${screenWidth}x$screenHeight',
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'toolbox.life.phone_monitor.metric_density',
                      ),
                      value:
                          '${((_snapshot['density'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}x',
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _lifeI18nText(context, 'toolbox.life.common.refresh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.phone_monitor.details'),
            children: <Widget>[
              _PhoneInfoRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.phone_monitor.platform',
                ),
                value: _value('platform'),
              ),
              _PhoneInfoRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.phone_monitor.manufacturer',
                ),
                value: _value('manufacturer'),
              ),
              _PhoneInfoRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.phone_monitor.model',
                ),
                value: _value('model'),
              ),
              _PhoneInfoRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.phone_monitor.system',
                ),
                value: _systemValue(),
              ),
              _PhoneInfoRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.phone_monitor.thermal',
                ),
                value: _value('thermalState'),
              ),
              _PhoneInfoRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.phone_monitor.memory',
                ),
                value: _memoryValue(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    final snapshot = await _getLifeDeviceSnapshot();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  String _value(String key) {
    final value = _snapshot[key];
    final text = value?.toString() ?? '';
    return text.trim().isEmpty ? '--' : text;
  }

  String _batteryStatusText(BuildContext context) {
    final raw = _value('batteryStatus');
    return _lifeI18nText(context, switch (raw) {
      'charging' => 'toolbox.life.phone_monitor.charge.charging',
      'full' => 'toolbox.life.phone_monitor.charge.full',
      'discharging' => 'toolbox.life.phone_monitor.charge.discharging',
      'notCharging' => 'toolbox.life.phone_monitor.charge.not_charging',
      _ => 'toolbox.life.phone_monitor.charge.unknown',
    });
  }

  String _systemValue() {
    final sdk = _snapshot['sdkInt'];
    final release = _snapshot['systemVersion'];
    if (sdk != null && release != null) {
      return '$release / API $sdk';
    }
    return release?.toString() ?? sdk?.toString() ?? '--';
  }

  String _memoryValue() {
    final total = (_snapshot['totalMemoryBytes'] as num?)?.toInt();
    final free = (_snapshot['freeMemoryBytes'] as num?)?.toInt();
    if (total == null && free == null) {
      return '--';
    }
    if (total == null) {
      return _lifeFormatBytes(free!);
    }
    if (free == null) {
      return _lifeFormatBytes(total);
    }
    return '${_lifeFormatBytes(free)} / ${_lifeFormatBytes(total)}';
  }
}

class _PhoneInfoRow extends StatelessWidget {
  const _PhoneInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

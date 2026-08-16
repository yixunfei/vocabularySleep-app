part of '../toolbox_life_tools.dart';

class _LightMeterToolPage extends StatefulWidget {
  const _LightMeterToolPage();

  @override
  State<_LightMeterToolPage> createState() => _LightMeterToolPageState();
}

class _LightMeterToolPageState extends State<_LightMeterToolPage> {
  Timer? _timer;
  double? _lux;
  double _maxLux = 0;
  double _minLux = double.infinity;
  String _sensorName = '';
  bool _supported = true;
  bool _loading = true;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lux = _lux;
    final band = _bandKey(lux);
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.light_meter.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.light_meter.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.light_meter.stage'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.light_meter.stage_subtitle',
            ),
            children: <Widget>[
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (!_supported)
                _LifeInlineNotice(
                  icon: Icons.lightbulb_outline_rounded,
                  text: _lifeI18nText(
                    context,
                    'toolbox.life.light_meter.unsupported',
                  ),
                )
              else
                Center(
                  child: Column(
                    children: <Widget>[
                      Text(
                        lux == null ? '--' : lux.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        _lifeI18nText(context, 'toolbox.life.light_meter.lux'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.wb_sunny_rounded),
                        label: Text(_lifeI18nText(context, band)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _lifeI18nText(context, 'toolbox.life.common.refresh'),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _resetRange,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      _lifeI18nText(context, 'toolbox.life.common.reset'),
                    ),
                  ),
                ],
              ),
              if (_errorCode != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.light_meter.error_code',
                    params: <String, Object?>{'code': _errorCode},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.light_meter.metric_min',
                ),
                value: _minLux.isInfinite ? '--' : _minLux.toStringAsFixed(0),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.light_meter.metric_max',
                ),
                value: _maxLux <= 0 ? '--' : _maxLux.toStringAsFixed(0),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.light_meter.metric_sensor',
                ),
                value: _sensorName.isEmpty ? '--' : _sensorName,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }
    final snapshot = await _getLifeLightSnapshot();
    if (!mounted) {
      return;
    }
    final supported = snapshot['supported'] as bool? ?? false;
    final luxValue = (snapshot['lux'] as num?)?.toDouble();
    setState(() {
      _loading = false;
      _supported = supported;
      _errorCode = snapshot['errorCode']?.toString();
      _sensorName = snapshot['sensorName']?.toString() ?? '';
      if (supported && luxValue != null && luxValue.isFinite) {
        _lux = luxValue;
        _maxLux = math.max(_maxLux, luxValue);
        _minLux = math.min(_minLux, luxValue);
      }
    });
  }

  void _resetRange() {
    setState(() {
      _maxLux = _lux ?? 0;
      _minLux = _lux ?? double.infinity;
    });
  }

  String _bandKey(double? lux) {
    if (lux == null) {
      return 'toolbox.life.light_meter.band.waiting';
    }
    if (lux < 10) {
      return 'toolbox.life.light_meter.band.dark';
    }
    if (lux < 80) {
      return 'toolbox.life.light_meter.band.dim';
    }
    if (lux < 500) {
      return 'toolbox.life.light_meter.band.indoor';
    }
    if (lux < 5000) {
      return 'toolbox.life.light_meter.band.bright';
    }
    return 'toolbox.life.light_meter.band.sun';
  }
}

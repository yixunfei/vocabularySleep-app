part of '../toolbox_life_tools.dart';

class _LevelToolPage extends StatefulWidget {
  const _LevelToolPage();

  @override
  State<_LevelToolPage> createState() => _LevelToolPageState();
}

class _LevelToolPageState extends State<_LevelToolPage> {
  StreamSubscription<AccelerometerEvent>? _accelSub;

  double _smoothPitch = 0;
  double _smoothRoll = 0;
  bool _plumbMode = false;
  bool _sensorsAvailable = true;

  static const double _tightThreshold = 0.8;
  static const double _softThreshold = 2.0;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  void _startSensors() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _sensorsAvailable = false;
      return;
    }
    try {
      _accelSub =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 70),
          ).listen(
            (event) {
              final x = event.x;
              final y = event.y;
              final z = event.z;
              final pitch =
                  math.atan2(-x, math.sqrt(y * y + z * z)) * 180 / math.pi;
              final roll = math.atan2(y, z) * 180 / math.pi;
              if (!mounted) {
                return;
              }
              setState(() {
                _smoothPitch = _smoothPitch + (pitch - _smoothPitch) * 0.18;
                _smoothRoll = _smoothRoll + (roll - _smoothRoll) * 0.18;
              });
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(() => _sensorsAvailable = false);
            },
            cancelOnError: true,
          );
    } on MissingPluginException {
      setState(() => _sensorsAvailable = false);
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  bool get _isTightLevel {
    if (_plumbMode) {
      return _smoothPitch.abs() <= _tightThreshold;
    }
    return _smoothPitch.abs() <= _tightThreshold &&
        _smoothRoll.abs() <= _tightThreshold;
  }

  bool get _isNearLevel {
    if (_plumbMode) {
      return _smoothPitch.abs() <= _softThreshold;
    }
    return _smoothPitch.abs() <= _softThreshold &&
        _smoothRoll.abs() <= _softThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '水平仪', en: 'Level meter'),
      subtitle: _lifeText(
        context,
        zh: '一屏看清水平、垂直、误差和当前持机状态，方便贴墙、摆台和快速找平。',
        en: 'See horizontal, vertical, error, and holding state on one screen for quick leveling checks.',
      ),
      child: _sensorsAvailable
          ? _buildBody(context)
          : _buildUnsupported(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _isTightLevel
        ? const Color(0xFF16A34A)
        : _isNearLevel
        ? const Color(0xFFF59E0B)
        : theme.colorScheme.primary;
    final primaryAngle = _plumbMode ? _smoothPitch.abs() : _dominantError();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifeSettingsPanel(
          title: _lifeText(context, zh: '模式与舞台', en: 'Mode and stage'),
          subtitle: _lifeText(
            context,
            zh: '水平模式同时看俯仰和横滚；垂直模式更适合贴墙和门框校正。',
            en: 'Level mode watches pitch and roll together; plumb mode is better for walls and door frames.',
          ),
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  selected: !_plumbMode,
                  label: Text(_lifeText(context, zh: '水平模式', en: 'Level')),
                  onSelected: (_) => setState(() => _plumbMode = false),
                ),
                ChoiceChip(
                  selected: _plumbMode,
                  label: Text(_lifeText(context, zh: '垂直模式', en: 'Plumb')),
                  onSelected: (_) => setState(() => _plumbMode = true),
                ),
                _LevelStatePill(
                  color: accent,
                  label: _levelStatusText(context),
                  icon: _isTightLevel
                      ? Icons.check_circle_rounded
                      : Icons.tune_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.58),
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    key: const ValueKey<String>('life-level-stage'),
                    width: 272,
                    height: 272,
                    child: CustomPaint(
                      painter: _LevelPainter(
                        pitch: _smoothPitch,
                        roll: _smoothRoll,
                        plumbMode: _plumbMode,
                        isTightLevel: _isTightLevel,
                        accent: accent,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${primaryAngle.toStringAsFixed(1)}°',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _levelHint(context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '俯仰', en: 'Pitch'),
              value: '${_smoothPitch.toStringAsFixed(1)}°',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '横滚', en: 'Roll'),
              value: '${_smoothRoll.toStringAsFixed(1)}°',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '主要误差', en: 'Main error'),
              value: '${_dominantError().toStringAsFixed(1)}°',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSettingsPanel(
          title: _lifeText(context, zh: '读数说明', en: 'Reading notes'),
          subtitle: _lifeText(
            context,
            zh: '手机壳凸起、桌面软垫和手持抖动都会影响结果，建议短暂停稳后再看数字。',
            en: 'Raised cases, soft surfaces, and hand shake all affect the reading. Pause briefly before trusting the number.',
          ),
          children: <Widget>[
            Text(
              _lifeText(
                context,
                zh: '绿色表示已经基本找平；黄色表示接近；仍偏差较大时请缓慢调整，不要边大幅移动边读数。',
                en: 'Green means level, yellow means close, and larger errors call for slow corrections instead of reading while moving.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnsupported(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '设备不支持', en: 'Unavailable'),
      subtitle: _lifeText(
        context,
        zh: '当前设备没有可用加速度计，所以无法提供水平检测。',
        en: 'This device does not expose the accelerometer required for leveling.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '请在手机真机上使用该功能，桌面端和多数模拟器通常不会返回可靠的重力方向。',
            en: 'Use this tool on a physical phone. Desktop targets and most simulators do not provide a reliable gravity vector.',
          ),
        ),
      ],
    );
  }

  double _dominantError() {
    if (_plumbMode) {
      return _smoothPitch.abs();
    }
    return math.max(_smoothPitch.abs(), _smoothRoll.abs());
  }

  String _levelStatusText(BuildContext context) {
    if (_isTightLevel) {
      return _lifeText(context, zh: '已找平', en: 'Level');
    }
    if (_isNearLevel) {
      return _lifeText(context, zh: '接近水平', en: 'Almost level');
    }
    return _lifeText(context, zh: '仍需调整', en: 'Needs adjustment');
  }

  String _levelHint(BuildContext context) {
    if (_plumbMode) {
      return _lifeText(
        context,
        zh: _isTightLevel ? '已经接近垂直线' : '让气泡回到中心竖线附近',
        en: _isTightLevel
            ? 'The device is close to plumb'
            : 'Bring the bubble back to the center line',
      );
    }
    return _lifeText(
      context,
      zh: _isTightLevel ? '俯仰和横滚都已经压到很小' : '同时把俯仰和横滚往 0° 收',
      en: _isTightLevel
          ? 'Pitch and roll are both tightly centered'
          : 'Bring both pitch and roll closer to 0°',
    );
  }
}

class _LevelStatePill extends StatelessWidget {
  const _LevelStatePill({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LevelPainter extends CustomPainter {
  const _LevelPainter({
    required this.pitch,
    required this.roll,
    required this.plumbMode,
    required this.isTightLevel,
    required this.accent,
    required this.theme,
  });

  final double pitch;
  final double roll;
  final bool plumbMode;
  final bool isTightLevel;
  final Color accent;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final bubbleRadius = 18.0;
    final maxOffset = radius * 0.62;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.colorScheme.surface.withValues(alpha: 0.98),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.86),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );

    for (final factor in <double>[0.25, 0.5, 0.75]) {
      canvas.drawCircle(
        center,
        radius * factor,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = factor == 0.75 ? 1.4 : 1
          ..color = theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
      );
    }

    canvas.drawLine(
      Offset(center.dx - radius + 18, center.dy),
      Offset(center.dx + radius - 18, center.dy),
      Paint()
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 18),
      Offset(center.dx, center.dy + radius - 18),
      Paint()
        ..strokeWidth = 2
        ..color = theme.colorScheme.outlineVariant,
    );

    final dx = (plumbMode ? pitch : roll) / 45;
    final dy = plumbMode ? 0.0 : pitch / 45;
    final bubbleCenter = Offset(
      center.dx + dx.clamp(-1.0, 1.0) * maxOffset,
      center.dy + dy.clamp(-1.0, 1.0) * maxOffset,
    );

    canvas.drawCircle(bubbleCenter, bubbleRadius, Paint()..color = accent);
    canvas.drawCircle(
      bubbleCenter.translate(-5, -5),
      bubbleRadius * 0.34,
      Paint()..color = Colors.white.withValues(alpha: 0.36),
    );
    if (isTightLevel) {
      canvas.drawCircle(center, 8, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPainter oldDelegate) {
    return pitch != oldDelegate.pitch ||
        roll != oldDelegate.roll ||
        plumbMode != oldDelegate.plumbMode ||
        isTightLevel != oldDelegate.isTightLevel ||
        accent != oldDelegate.accent ||
        theme.colorScheme != oldDelegate.theme.colorScheme;
  }
}

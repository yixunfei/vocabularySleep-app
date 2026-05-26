part of '../toolbox_life_tools.dart';

class _DualTeamMode extends StatefulWidget {
  const _DualTeamMode({required this.vsync});

  final TickerProvider vsync;

  @override
  State<_DualTeamMode> createState() => _DualTeamModeState();
}

class _DualTeamModeState extends State<_DualTeamMode> {
  int _seconds = 0;
  bool _countdown = false;
  Timer? _timer;
  bool _running = false;

  String _teamAName = 'A队';
  String _teamBName = 'B队';
  Color _teamAColor = _teamColorPresets[0];
  Color _teamBColor = _teamColorPresets[1];
  int _scoreA = 0;
  int _scoreB = 0;

  bool _settingsExpanded = false;
  bool _stepEnabled = false;
  int _stepValue = 1;

  final TextEditingController _nameACtrl = TextEditingController();
  final TextEditingController _nameBCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameACtrl.text = _teamAName;
    _nameBCtrl.text = _teamBName;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameACtrl.dispose();
    _nameBCtrl.dispose();
    super.dispose();
  }

  int get _step => _stepEnabled ? _stepValue : 1;

  void _adjustScoreA(int delta) {
    setState(() => _scoreA = math.max(0, _scoreA + delta * _step));
  }

  void _adjustScoreB(int delta) {
    setState(() => _scoreB = math.max(0, _scoreB + delta * _step));
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      _timer = null;
      setState(() => _running = false);
      return;
    }
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        if (_countdown) {
          if (_seconds <= 0) {
            _timer?.cancel();
            _timer = null;
            _running = false;
            return;
          }
          _seconds -= 1;
        } else {
          _seconds += 1;
        }
      });
    });
    setState(() {});
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    setState(() => _seconds = 0);
  }

  void _adjustTimer(int deltaMinutes) {
    if (_running) return;
    setState(() {
      _seconds = math.max(0, _seconds + deltaMinutes * 60);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: <Widget>[
        _buildTimerSection(theme),
        const SizedBox(height: 12),
        _buildSettingsToggle(theme),
        _buildSettingsPanel(theme),
        const SizedBox(height: 12),
        _buildTeamsRow(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _openImmersive,
          icon: const Icon(Icons.fullscreen_rounded),
          label: Text(
            _lifeText(context, zh: '全屏横屏记分', en: 'Fullscreen landscape'),
          ),
        ),
      ],
    );
  }

  void _openImmersive() {
    _timer?.cancel();
    final wasRunning = _running;
    _running = false;
    if (wasRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _timer?.cancel();
          return;
        }
        setState(() {
          if (_countdown) {
            if (_seconds <= 0) {
              _timer?.cancel();
              _timer = null;
              _running = false;
              return;
            }
            _seconds -= 1;
          } else {
            _seconds += 1;
          }
        });
      });
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ScoreboardImmersivePage(
          initialScoreA: _scoreA,
          initialScoreB: _scoreB,
          initialTeamAName: _teamAName,
          initialTeamBName: _teamBName,
          initialTeamAColor: _teamAColor,
          initialTeamBColor: _teamBColor,
          initialSeconds: _seconds,
          initialCountdown: _countdown,
          initialRunning: _running,
          stepEnabled: _stepEnabled,
          stepValue: _stepValue,
          teamAName: _nameACtrl.text,
          teamBName: _nameBCtrl.text,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildSettingsToggle(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _settingsExpanded = !_settingsExpanded),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(
              _settingsExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _lifeText(context, zh: '设置', en: 'Settings'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(ThemeData theme) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 220),
      crossFadeState: _settingsExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _lifeText(context, zh: '队伍 A', en: 'Team A'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: _teamAColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameACtrl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                _teamAName = v.trim().isEmpty ? 'A队' : v.trim();
              },
            ),
            const SizedBox(height: 6),
            _ColorPicker(
              value: _teamAColor,
              onChanged: (c) => setState(() => _teamAColor = c),
              compact: true,
            ),
            const SizedBox(height: 14),
            Text(
              _lifeText(context, zh: '队伍 B', en: 'Team B'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: _teamBColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameBCtrl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                _teamBName = v.trim().isEmpty ? 'B队' : v.trim();
              },
            ),
            const SizedBox(height: 6),
            _ColorPicker(
              value: _teamBColor,
              onChanged: (c) => setState(() => _teamBColor = c),
              compact: true,
            ),
            const SizedBox(height: 12),
            _StepValueSetting(
              enabled: _stepEnabled,
              value: _stepValue,
              onToggle: (v) => setState(() => _stepEnabled = v),
              onValueChanged: (v) => setState(() => _stepValue = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ChoiceChip(
                selected: !_countdown,
                label: Text(_lifeText(context, zh: '正计时', en: 'Count up')),
                onSelected: (_) {
                  if (_running) return;
                  setState(() {
                    _countdown = false;
                    _seconds = 0;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                selected: _countdown,
                label: Text(_lifeText(context, zh: '倒计时', en: 'Countdown')),
                onSelected: (_) {
                  if (_running) return;
                  setState(() {
                    _countdown = true;
                    _seconds = 0;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_countdown && !_running)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton.filledTonal(
                  onPressed: () => _adjustTimer(-1),
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(_seconds ~/ 60)} min',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: () => _adjustTimer(1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          Text(
            _formatTime(_seconds),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _toggleTimer,
                icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _running
                      ? _lifeText(context, zh: '暂停', en: 'Pause')
                      : _lifeText(context, zh: '开始', en: 'Start'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _TeamPanel(
            name: _teamAName,
            color: _teamAColor,
            score: _scoreA,
            vsync: widget.vsync,
            onMinus: () => _adjustScoreA(-1),
            onPlus: () => _adjustScoreA(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeamPanel(
            name: _teamBName,
            color: _teamBColor,
            score: _scoreB,
            vsync: widget.vsync,
            onMinus: () => _adjustScoreB(-1),
            onPlus: () => _adjustScoreB(1),
          ),
        ),
      ],
    );
  }
}

class _TeamPanel extends StatelessWidget {
  const _TeamPanel({
    required this.name,
    required this.color,
    required this.score,
    required this.vsync,
    required this.onMinus,
    required this.onPlus,
  });

  final String name;
  final Color color;
  final int score;
  final TickerProvider vsync;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _FlipScore(
          score: score,
          color: color,
          vsync: vsync,
          cardColor: _FlipScore.lightCardColor,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ScoreButton(
              icon: Icons.remove_rounded,
              onTap: onMinus,
              color: color,
              disabled: score <= 0,
            ),
            const SizedBox(width: 14),
            _ScoreButton(
              icon: Icons.add_rounded,
              onTap: onPlus,
              color: color,
            ),
          ],
        ),
      ],
    );
  }
}

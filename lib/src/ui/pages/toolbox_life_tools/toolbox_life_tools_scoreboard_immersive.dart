part of '../toolbox_life_tools.dart';

class _ScoreboardImmersivePage extends StatefulWidget {
  const _ScoreboardImmersivePage({
    required this.initialScoreA,
    required this.initialScoreB,
    required this.initialTeamAName,
    required this.initialTeamBName,
    required this.initialTeamAColor,
    required this.initialTeamBColor,
    required this.initialSeconds,
    required this.initialCountdown,
    required this.initialRunning,
    required this.stepEnabled,
    required this.stepValue,
    required this.teamAName,
    required this.teamBName,
  });

  final int initialScoreA;
  final int initialScoreB;
  final String initialTeamAName;
  final String initialTeamBName;
  final Color initialTeamAColor;
  final Color initialTeamBColor;
  final int initialSeconds;
  final bool initialCountdown;
  final bool initialRunning;
  final bool stepEnabled;
  final int stepValue;
  final String teamAName;
  final String teamBName;

  @override
  State<_ScoreboardImmersivePage> createState() =>
      _ScoreboardImmersivePageState();
}

class _ScoreboardImmersivePageState extends State<_ScoreboardImmersivePage>
    with TickerProviderStateMixin {
  late int _scoreA, _scoreB;
  late String _teamAName, _teamBName;
  late Color _teamAColor, _teamBColor;
  late int _seconds;
  late bool _countdown, _running;
  late bool _stepEnabled;
  late int _stepValue;
  Timer? _timer;

  bool _showHud = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scoreA = widget.initialScoreA;
    _scoreB = widget.initialScoreB;
    _teamAName = widget.teamAName;
    _teamBName = widget.teamBName;
    _teamAColor = widget.initialTeamAColor;
    _teamBColor = widget.initialTeamBColor;
    _seconds = widget.initialSeconds;
    _countdown = widget.initialCountdown;
    _running = widget.initialRunning;
    _stepEnabled = widget.stepEnabled;
    _stepValue = widget.stepValue;
    unawaited(_enterLifeLandscapeImmersive());
    if (_running) _startTimer();
    _scheduleHideHud();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    unawaited(_exitLifeImmersive());
    super.dispose();
  }

  int get _step => _stepEnabled ? _stepValue : 1;

  void _startTimer() {
    _timer?.cancel();
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

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      _startTimer();
      setState(() {});
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _seconds = 0;
    });
  }

  void _revealHud() {
    setState(() => _showHud = true);
    _scheduleHideHud();
  }

  void _scheduleHideHud() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHud = false);
    });
  }

  void _openSettingsSheet() {
    _hideTimer?.cancel();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _StepValueSetting(
                          enabled: _stepEnabled,
                          value: _stepValue,
                          onToggle: (v) {
                            setState(() => _stepEnabled = v);
                            setSheetState(() {});
                          },
                          onValueChanged: (v) {
                            setState(() => _stepValue = v);
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _toggleTimer,
                                icon: Icon(_running
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded),
                                label: Text(
                                  _running
                                      ? _lifeText(context, zh: '暂停', en: 'Pause')
                                      : _lifeText(context, zh: '开始', en: 'Start'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _resetTimer,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _lifeText(context, zh: '重置', en: 'Reset'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(
                            _lifeText(context, zh: '退出全屏', en: 'Exit fullscreen'),
                          ),
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
    ).whenComplete(_scheduleHideHud);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: GestureDetector(
          onTap: _revealHud,
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildContent(),
                _buildHud(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          _formatTime(_seconds),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const Spacer(),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildTeamSide(
                name: _teamAName,
                color: _teamAColor,
                score: _scoreA,
                onMinus: () =>
                    setState(() => _scoreA = math.max(0, _scoreA - _step)),
                onPlus: () => setState(() => _scoreA += _step),
              ),
            ),
            Container(
              width: 1,
              height: 200,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            Expanded(
              child: _buildTeamSide(
                name: _teamBName,
                color: _teamBColor,
                score: _scoreB,
                onMinus: () =>
                    setState(() => _scoreB = math.max(0, _scoreB - _step)),
                onPlus: () => setState(() => _scoreB += _step),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTeamSide({
    required String name,
    required Color color,
    required int score,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _FlipScore(
          score: score,
          color: color,
          vsync: this,
          fontSize: 88,
          height: 130,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ScoreButton(
              icon: Icons.remove_rounded,
              onTap: onMinus,
              color: Colors.white70,
              disabled: score <= 0,
            ),
            const SizedBox(width: 20),
            _ScoreButton(
              icon: Icons.add_rounded,
              onTap: onPlus,
              color: Colors.white70,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHud() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_showHud,
        child: Align(
          alignment: Alignment.topRight,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: _showHud ? Offset.zero : const Offset(1.45, 0),
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton.filledTonal(
                    onPressed: _openSettingsSheet,
                    icon: const Icon(Icons.settings_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

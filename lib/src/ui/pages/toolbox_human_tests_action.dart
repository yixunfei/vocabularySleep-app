part of 'toolbox_human_tests.dart';

class TapSpeedTestPage extends StatelessWidget {
  const TapSpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '手速测试',
        en: 'Tap speed',
        ja: 'Tap speed',
        de: 'Tap speed',
        fr: 'Vitesse de la touche',
        es: 'Velocidad',
        ru: 'Скорость нажатия',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在经典连点、目标追击和节奏命中模式中测试点击速度、稳定性与准确率。',
        en: 'Measure tap speed, stability, and accuracy across classic, target chase, and rhythm modes.',
        ja: 'Measure tap speed, stability, and accuracy across classic, target chase, and rhythm modes.',
        de: 'Measure tap speed, stability, and accuracy across classic, target chase, and rhythm modes.',
        fr: 'Mesurer la vitesse, la stabilité et la précision du robinet sur les modes classiques, de poursuite des cibles et de rythme.',
        es: 'Medir la velocidad del grifo, la estabilidad y la precisión a través de los modos clásicos, persecución del objetivo y ritmo.',
        ru: 'Измерьте скорость касания, стабильность и точность в классических, целевых режимах погони и ритме.',
      ),
      accent: const Color(0xFFC05180),
      icon: Icons.touch_app_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式后开始挑战',
        en: 'Next: choose a mode and start',
        ja: 'Next: choose a mode and start',
        de: 'Next: choose a mode and start',
        fr: 'Suivant : choisissez un mode et démarrez',
        es: 'Siguiente: elegir un modo y comenzar',
        ru: 'Далее: выберите режим и начните',
      ),
      child: const _TapSpeedTestCard(),
    );
  }
}

enum _TapSpeedMode { classic, targetChase, rhythm }

class _TapSpeedTestCard extends StatefulWidget {
  const _TapSpeedTestCard();

  @override
  State<_TapSpeedTestCard> createState() => _TapSpeedTestCardState();
}

class _TapSpeedTestCardState extends State<_TapSpeedTestCard> {
  static const Color _accent = Color(0xFFC05180);
  final math.Random _random = math.Random();
  Timer? _timer;
  _TapSpeedMode _mode = _TapSpeedMode.classic;
  int _durationSeconds = 10;
  int _count = 0;
  int _attempts = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _remainingTenths = 100;
  int _targetSlot = 4;
  int _rhythmSlot = 4;
  bool _running = false;
  bool _done = false;
  bool? _lastHit;
  int _feedbackSerial = 0;

  int get _totalTenths => _durationSeconds * 10;

  double get _cps => _durationSeconds <= 0 ? 0 : _count / _durationSeconds;

  double get _accuracy => _attempts <= 0 ? 1 : _count / _attempts;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _count = 0;
      _attempts = 0;
      _combo = 0;
      _bestCombo = 0;
      _remainingTenths = _totalTenths;
      _targetSlot = _random.nextInt(9);
      _rhythmSlot = 4;
      _running = true;
      _done = false;
      _lastHit = null;
      _feedbackSerial = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        return;
      }
      if (_remainingTenths <= 1) {
        timer.cancel();
        setState(() {
          _remainingTenths = 0;
          _running = false;
          _done = true;
        });
        unawaited(_showReport());
        return;
      }
      setState(() {
        _remainingTenths -= 1;
        if (_mode == _TapSpeedMode.rhythm && _remainingTenths % 5 == 0) {
          _rhythmSlot = _random.nextInt(9);
        }
      });
    });
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _count = 0;
      _attempts = 0;
      _combo = 0;
      _bestCombo = 0;
      _remainingTenths = _totalTenths;
      _targetSlot = _random.nextInt(9);
      _rhythmSlot = 4;
      _running = false;
      _done = false;
      _lastHit = null;
      _feedbackSerial = 0;
    });
  }

  void _registerTap({required bool hit}) {
    if (!_running) {
      _start();
      return;
    }
    setState(() {
      _attempts += 1;
      if (hit) {
        _count += 1;
        _combo += 1;
        _bestCombo = math.max(_bestCombo, _combo);
        if (_mode == _TapSpeedMode.targetChase) {
          _targetSlot = _nextDifferentSlot(_targetSlot);
        }
      } else {
        _combo = 0;
      }
      _lastHit = hit;
      _feedbackSerial += 1;
    });
  }

  int _nextDifferentSlot(int current) {
    var next = _random.nextInt(9);
    var guard = 0;
    while (next == current && guard < 8) {
      guard += 1;
      next = _random.nextInt(9);
    }
    return next;
  }

  void _setMode(_TapSpeedMode mode) {
    if (_running) {
      return;
    }
    setState(() {
      _mode = mode;
      _done = false;
      _lastHit = null;
    });
  }

  Future<void> _showReport() async {
    if (!mounted || (!_done && _attempts <= 0)) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) => _TapSpeedReportDialog(
        i18n: i18n,
        mode: _modeLabel(i18n, _mode),
        taps: _count,
        attempts: _attempts,
        cps: _cps,
        accuracy: _accuracy,
        bestCombo: _bestCombo,
        durationSeconds: _durationSeconds,
      ),
    );
  }

  String _modeLabel(AppI18n i18n, _TapSpeedMode mode) {
    return switch (mode) {
      _TapSpeedMode.classic => pickUiText(
        i18n,
        zh: '经典连点',
        en: 'Classic',
        ja: 'クラシック',
        de: 'Classic',
        fr: 'Classique',
        es: 'Clásico',
        ru: 'Классика',
      ),
      _TapSpeedMode.targetChase => pickUiText(
        i18n,
        zh: '目标追击',
        en: 'Target chase',
        ja: 'Target chase',
        de: 'Target chase',
        fr: 'Cible poursuite',
        es: 'Persecución del objetivo',
        ru: 'Погоня за целью',
      ),
      _TapSpeedMode.rhythm => pickUiText(
        i18n,
        zh: '节奏命中',
        en: 'Rhythm hit',
        ja: 'Rhythm hit',
        de: 'Rhythm hit',
        fr: 'Coup de rythme',
        es: 'Rhythm hit',
        ru: 'Ритмовый удар',
      ),
    };
  }

  String _modeHint(AppI18n i18n) {
    return switch (_mode) {
      _TapSpeedMode.classic => pickUiText(
        i18n,
        zh: '任意点击舞台，尽量保持稳定高速。',
        en: 'Tap anywhere on the stage and keep a stable high pace.',
        ja: 'Tap anywhere on the stage and keep a stable high pace.',
        de: 'Tap anywhere on the stage and keep a stable high pace.',
        fr: 'Appuyez n\'importe où sur la scène et garder un rythme stable.',
        es: 'Toque en cualquier lugar del escenario y mantenga un ritmo alto estable.',
        ru: 'Нажмите в любом месте на сцене и держите стабильный высокий темп.',
      ),
      _TapSpeedMode.targetChase => pickUiText(
        i18n,
        zh: '只点亮起的目标格，点错会断连击。',
        en: 'Tap only the lit target tile. Wrong taps break combo.',
        ja: 'Tap only the lit target tile. Wrong taps break combo.',
        de: 'Tap only the lit target tile. Wrong taps break combo.',
        fr: 'Appuyez uniquement sur la tuile de cible allumée. Les mauvais robinets brisent le combo.',
        es: 'Toca sólo la baldosa de destino iluminada. Grifos equivocados rompen combo.',
        ru: 'Нажмите только на зажженную целевую плитку. Неправильные краны разрушают комбо.',
      ),
      _TapSpeedMode.rhythm => pickUiText(
        i18n,
        zh: '目标按节奏跳动，抓住亮起的格子。',
        en: 'The target jumps on a rhythm. Catch the lit tile.',
        ja: 'The target jumps on a rhythm. Catch the lit tile.',
        de: 'The target jumps on a rhythm. Catch the lit tile.',
        fr: 'La cible saute sur un rythme. Attrape la tuile allumée.',
        es: 'El objetivo salta a ritmo. Coge la baldosa iluminada.',
        ru: 'Цель прыгает в ритме. Поймай зажженную плитку.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final secondsLeft = _remainingTenths / 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '命中',
                en: 'Hits',
                ja: 'Hits',
                de: 'Hits',
                fr: 'Coups',
                es: 'Golpes',
                ru: 'Хиты',
              ),
              '$_count',
            ),
            (
              pickUiText(
                i18n,
                zh: '剩余',
                en: 'Left',
                ja: 'Left',
                de: 'Left',
                fr: 'Gauche',
                es: 'Izquierda',
                ru: 'Левый',
              ),
              _formatSeconds(secondsLeft),
            ),
            (
              pickUiText(
                i18n,
                zh: '每秒',
                en: 'Per sec',
                ja: 'Per sec',
                de: 'Per sec',
                fr: 'Par sec',
                es: 'Per sec',
                ru: 'Через секунду',
              ),
              (_running || _done) ? _cps.toStringAsFixed(1) : '-',
            ),
            (
              pickUiText(
                i18n,
                zh: '准确率',
                en: 'Accuracy',
                ja: '精度',
                de: 'Accuracy',
                fr: 'Accuracy',
                es: 'Precisión',
                ru: 'точность',
              ),
              _attempts <= 0 ? '-' : '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '连击',
                en: 'Combo',
                ja: 'コンボ',
                de: 'Combo',
                fr: 'Combo',
                es: 'Combo',
                ru: 'Комбинация',
              ),
              '$_combo',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTapSettingsSection(i18n, theme),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _modeHint(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _TapSpeedStage(
                mode: _mode,
                running: _running,
                targetSlot: _mode == _TapSpeedMode.rhythm
                    ? _rhythmSlot
                    : _targetSlot,
                lastHit: _lastHit,
                feedbackSerial: _feedbackSerial,
                onTapStage: () =>
                    _registerTap(hit: _mode == _TapSpeedMode.classic),
                onTapSlot: (index) {
                  if (_mode == _TapSpeedMode.classic) {
                    _registerTap(hit: true);
                    return;
                  }
                  final target = _mode == _TapSpeedMode.rhythm
                      ? _rhythmSlot
                      : _targetSlot;
                  _registerTap(hit: index == target);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: _running
                        ? pickUiText(
                            i18n,
                            zh: '挑战中',
                            en: 'Running',
                            ja: 'Running',
                            de: 'Running',
                            fr: 'Courir',
                            es: 'Corriendo',
                            ru: 'бегать',
                          )
                        : pickUiText(
                            i18n,
                            zh: '开始挑战',
                            en: 'Start challenge',
                            ja: 'Start challenge',
                            de: 'Start challenge',
                            fr: 'Démarrage',
                            es: 'Inicio desafío',
                            ru: 'Начинать вызов',
                          ),
                    icon: _running
                        ? Icons.flash_on_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: _running ? null : _start,
                  ),
                  OutlinedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '重新开始',
                        en: 'Restart',
                        ja: 'Restart',
                        de: 'Restart',
                        fr: 'Redémarrer',
                        es: 'Restart',
                        ru: 'Перезапустить',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _attempts <= 0
                        ? null
                        : () => unawaited(_showReport()),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '报告',
                        en: 'Report',
                        ja: 'Report',
                        de: 'Report',
                        fr: 'Rapport annuel',
                        es: 'Informe',
                        ru: 'Доклад',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTapSettingsSection(AppI18n i18n, ThemeData theme) {
    return _HumanSettingsSection(
      title: pickUiText(
        i18n,
        zh: '手速设置',
        en: 'Tap settings',
        ja: 'Tap settings',
        de: 'Tap settings',
        fr: 'Paramètres de la touche',
        es: 'Ajustes',
        ru: 'Настройки касания',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '选择玩法和挑战时长，运行中设置会锁定。',
        en: 'Choose mode and duration. Settings lock while running.',
        ja: 'モードと期間を選択します。実行中は設定がロックされます。',
        de: 'Choose mode and duration. Settings lock while running.',
        fr: 'Choisissez le mode et la durée. Réglages verrouillés pendant l\'exécution.',
        es: 'Elige el modo y la duración. Los ajustes se bloquean mientras corren.',
        ru: 'Выберите режим и продолжительность. Настройка замка во время бега.',
      ),
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '玩法模式',
              en: 'Game mode',
              ja: 'Game mode',
              de: 'Game mode',
              fr: 'Mode jeu',
              es: 'Modo de juego',
              ru: 'Режим игры',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _TapSpeedMode.values
                .map(
                  (mode) => ChoiceChip(
                    label: Text(_modeLabel(i18n, mode)),
                    selected: _mode == mode,
                    onSelected: _running ? null : (_) => _setMode(mode),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '挑战时长',
              en: 'Duration',
              ja: 'Duration',
              de: 'Duration',
              fr: 'Durée',
              es: 'Duración',
              ru: 'Продолжительность',
            ),
            style: theme.textTheme.labelLarge,
          ),
          Slider(
            value: _durationSeconds.toDouble(),
            min: 5,
            max: 30,
            divisions: 5,
            label: '$_durationSeconds s',
            onChanged: _running
                ? null
                : (value) => setState(() => _durationSeconds = value.round()),
          ),
        ],
      ),
    );
  }
}

class _TapSpeedStage extends StatelessWidget {
  const _TapSpeedStage({
    required this.mode,
    required this.running,
    required this.targetSlot,
    required this.lastHit,
    required this.feedbackSerial,
    required this.onTapStage,
    required this.onTapSlot,
  });

  final _TapSpeedMode mode;
  final bool running;
  final int targetSlot;
  final bool? lastHit;
  final int feedbackSerial;
  final VoidCallback onTapStage;
  final ValueChanged<int> onTapSlot;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    if (mode == _TapSpeedMode.classic) {
      return GestureDetector(
        onTap: onTapStage,
        child: _TapSpeedClassicPad(
          running: running,
          lastHit: lastHit,
          feedbackSerial: feedbackSerial,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final width = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              List<Widget>.generate(9, (index) {
                final active = running && index == targetSlot;
                return SizedBox(
                  width: width,
                  height: 82,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTapSlot(index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: active
                              ? _TapSpeedTestCardState._accent.withValues(
                                  alpha: 0.22,
                                )
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.40),
                          border: Border.all(
                            color: active
                                ? _TapSpeedTestCardState._accent.withValues(
                                    alpha: 0.70,
                                  )
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            active
                                ? Icons.ads_click_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: active
                                ? _TapSpeedTestCardState._accent
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })..insert(
                0,
                SizedBox(
                  width: constraints.maxWidth,
                  child: Text(
                    running
                        ? pickUiText(
                            i18n,
                            zh: '点击亮起目标',
                            en: 'Tap the lit target',
                            ja: 'Tap the lit target',
                            de: 'Tap the lit target',
                            fr: 'Appuyez sur la cible allumée',
                            es: 'Toque el objetivo encendido',
                            ru: 'Нажмите на освещенную цель',
                          )
                        : pickUiText(
                            i18n,
                            zh: '开始后目标会亮起',
                            en: 'Targets light up after start',
                            ja: 'Targets light up after start',
                            de: 'Targets light up after start',
                            fr: 'Les cibles s\'allument après le départ',
                            es: 'Los objetivos se iluminan después de empezar',
                            ru: 'Цели загораются после старта',
                          ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }
}

class _TapSpeedClassicPad extends StatelessWidget {
  const _TapSpeedClassicPad({
    required this.running,
    required this.lastHit,
    required this.feedbackSerial,
  });

  final bool running;
  final bool? lastHit;
  final int feedbackSerial;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          height: 220,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _TapSpeedTestCardState._accent.withValues(alpha: 0.14),
            border: Border.all(
              color: _TapSpeedTestCardState._accent.withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            running
                ? pickUiText(
                    i18n,
                    zh: '点击',
                    en: 'Tap',
                    ja: 'Tap',
                    de: 'Tap',
                    fr: 'Appuyez sur',
                    es: 'Tap',
                    ru: 'нажатие',
                  )
                : pickUiText(
                    i18n,
                    zh: '点击开始',
                    en: 'Tap to start',
                    ja: 'Tap to start',
                    de: 'Tap to start',
                    fr: 'Appuyez sur pour démarrer',
                    es: 'Pulsa para empezar',
                    ru: 'Нажмите, чтобы начать',
                  ),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (feedbackSerial > 0)
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(feedbackSerial),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: (1 - value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.7 + value * 0.6,
                  child: const Icon(
                    Icons.touch_app_rounded,
                    size: 64,
                    color: _TapSpeedTestCardState._accent,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TapSpeedReportDialog extends StatelessWidget {
  const _TapSpeedReportDialog({
    required this.i18n,
    required this.mode,
    required this.taps,
    required this.attempts,
    required this.cps,
    required this.accuracy,
    required this.bestCombo,
    required this.durationSeconds,
  });

  final AppI18n i18n;
  final String mode;
  final int taps;
  final int attempts;
  final double cps;
  final double accuracy;
  final int bestCombo;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = cps >= 8.5 && accuracy >= 0.9
        ? pickUiText(
            i18n,
            zh: '爆发型选手',
            en: 'Burst specialist',
            ja: 'バースト専門家',
            de: 'Burst specialist',
            fr: 'Spécialiste des bourrages',
            es: 'Especialista en Burst',
            ru: 'Специалист Burst',
          )
        : cps >= 6.5
        ? pickUiText(
            i18n,
            zh: '高速稳定',
            en: 'Fast and steady',
            ja: 'Fast and steady',
            de: 'Fast and steady',
            fr: 'Rapide et stable',
            es: 'Rápido y estable',
            ru: 'Быстрый и устойчивый',
          )
        : accuracy < 0.75
        ? pickUiText(
            i18n,
            zh: '需要稳手',
            en: 'Needs control',
            ja: 'Needs control',
            de: 'Needs control',
            fr: 'Contrôle des besoins',
            es: 'Control de necesidades',
            ru: 'Требуется контроль',
          )
        : pickUiText(
            i18n,
            zh: '稳定练习中',
            en: 'Steady practice',
            ja: 'Steady practice',
            de: 'Steady practice',
            fr: 'Pratique stable',
            es: 'Práctica constante',
            ru: 'Устойчивая практика',
          );
    return AlertDialog(
      title: Text(
        pickUiText(
          i18n,
          zh: '手速报告',
          en: 'Tap speed report',
          ja: 'Tap speed report',
          de: 'Tap speed report',
          fr: 'Rapport de vitesse de la touche',
          es: 'Informe de velocidad',
          ru: 'Отчет о скорости',
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '称号',
                      en: 'Title',
                      ja: 'Title',
                      de: 'Title',
                      fr: 'Titre',
                      es: 'Título',
                      ru: 'Название',
                    ),
                    value: title,
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '每秒',
                      en: 'Per sec',
                      ja: 'Per sec',
                      de: 'Per sec',
                      fr: 'Par sec',
                      es: 'Per sec',
                      ru: 'Через секунду',
                    ),
                    value: cps.toStringAsFixed(1),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '命中/尝试',
                      en: 'Hits/attempts',
                      ja: 'Hits/attempts',
                      de: 'Hits/attempts',
                      fr: 'Coups/coups',
                      es: 'Hits/attempts',
                      ru: 'Хиты/попытки',
                    ),
                    value: '$taps/$attempts',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '最佳连击',
                      en: 'Best combo',
                      ja: 'ベストコンボ',
                      de: 'Best combo',
                      fr: 'Meilleur combo',
                      es: 'Mejor combo',
                      ru: 'Лучшее сочетание',
                    ),
                    value: '$bestCombo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(
                  i18n,
                  zh: '本轮设置',
                  en: 'Session settings',
                  ja: 'Session settings',
                  de: 'Session settings',
                  fr: 'Paramètres de la session',
                  es: 'Ajustes del período de sesiones',
                  ru: 'Параметры сеанса',
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(mode)),
                    Chip(label: Text('$durationSeconds s')),
                    Chip(label: Text('${(accuracy * 100).round()}% accuracy')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(
                  i18n,
                  zh: '训练建议',
                  en: 'Training note',
                  ja: 'Training note',
                  de: 'Training note',
                  fr: 'Note de formation',
                  es: 'Nota de capacitación',
                  ru: 'Учебная записка',
                ),
                child: Text(
                  accuracy < 0.8
                      ? pickUiText(
                          i18n,
                          zh: '先降低误触，目标追击模式下保持拇指回到中心再点下一格。',
                          en: 'Reduce mis-taps first. In target chase, return to center before the next tile.',
                          ja: 'Reduce mis-taps first. In target chase, return to center before the next tile.',
                          de: 'Reduce mis-taps first. In target chase, return to center before the next tile.',
                          fr: 'Réduire les erreurs d\'abord. Dans la poursuite de la cible, retournez au centre avant la prochaine tuile.',
                          es: 'Reduzca los errores primero. En persecución objetivo, volver al centro antes de la siguiente ficha.',
                          ru: 'Сначала уменьшите количество ошибок. В погоне за целью, вернитесь в центр перед следующей плиткой.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '准确率稳定，可以缩短休息间隔或切换到节奏命中练习爆发。',
                          en: 'Accuracy is stable. Shorten rests or switch to rhythm hit for burst practice.',
                          ja: '精度は安定しています。休憩時間を短くするか、バースト練習のためにリズムヒットに切り替えます。',
                          de: 'Accuracy is stable. Shorten rests or switch to rhythm hit for burst practice.',
                          fr: 'Accuracy is stable. Shorten rests or switch to rhythm hit for burst practice.',
                          es: 'La precisión es estable. Acortar los descansos o cambiar al ritmo de la práctica de la explosión.',
                          ru: 'Точность стабильна. Укоротить отдых или переключиться на ритм-хит для лопнувшей практики.',
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            pickUiText(
              i18n,
              zh: '关闭',
              en: 'Close',
              ja: '閉じる',
              de: 'Close',
              fr: 'Fermer',
              es: 'Cerca',
              ru: 'Закрыть',
            ),
          ),
        ),
      ],
    );
  }
}

part of 'toolbox_human_tests.dart';

enum _DragTrackDifficulty { gentle, standard, expert }

class FineDragTrackingTestPage extends StatelessWidget {
  const FineDragTrackingTestPage({super.key});

  static const Color _accent = Color(0xFF4E8B6B);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '精细拖拽追踪',
        en: 'Fine drag tracking',
        ja: 'Fine drag tracking',
        de: 'Fine drag tracking',
        fr: 'Traçage fin de la traînée',
        es: 'Seguimiento de la arrastre',
        ru: 'Отличное отслеживание сопротивления',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '手指稳住，沿窄轨从起点滑到终点——越慢越难。',
        en: 'Drag a cursor along a narrow track for fine movement control.',
        ja: 'Drag a cursor along a narrow track to train fine movement control and sustained tracking stability.',
        de: 'Drag a cursor along a narrow track to train fine movement control and sustained tracking stability.',
        fr: 'Faites glisser un curseur le long d\'une voie étroite pour entraîner un contrôle de mouvement fin et une stabilité de suivi soutenue.',
        es: 'Arrastre un cursor a lo largo de una estrecha pista para entrenar el control de movimiento fino y la estabilidad de seguimiento sostenida.',
        ru: 'Перетащите курсор по узкой дорожке, чтобы обучить тонкому контролю движения и устойчивой стабильности отслеживания.',
      ),
      accent: _accent,
      icon: Icons.gesture_rounded,
      status: pickUiText(
        i18n,
        zh: '稳住手指，沿着窄轨从起点滑到终点',
        en: 'Next: hold the start point and drag along the track',
        ja: 'Next: hold the start point and drag along the track',
        de: 'Next: hold the start point and drag along the track',
        fr: 'Suivant : maintenez le point de départ et faites glisser le long de la piste',
        es: 'Siguiente: mantener el punto de inicio y arrastrar a lo largo de la pista',
        ru: 'Далее: удерживайте точку старта и тащите по трассе',
      ),
      child: const _FineDragTrackingCard(),
    );
  }
}

class _DragTrackProjection {
  const _DragTrackProjection({
    required this.distance,
    required this.progress,
    required this.nearest,
  });

  final double distance;
  final double progress;
  final Offset nearest;
}

class _DragTrackRecord {
  const _DragTrackRecord({
    required this.milliseconds,
    required this.offTrackEvents,
    required this.averageDeviation,
    required this.maxDeviation,
    required this.difficulty,
  });

  final int milliseconds;
  final int offTrackEvents;
  final double averageDeviation;
  final double maxDeviation;
  final _DragTrackDifficulty difficulty;
}

class _FineDragTrackingCard extends StatefulWidget {
  const _FineDragTrackingCard();

  @override
  State<_FineDragTrackingCard> createState() => _FineDragTrackingCardState();
}

class _FineDragTrackingCardState extends State<_FineDragTrackingCard> {
  static const Color _accent = FineDragTrackingTestPage._accent;

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_DragTrackRecord> _records = <_DragTrackRecord>[];
  Timer? _transitionTimer;

  _DragTrackDifficulty _difficulty = _DragTrackDifficulty.standard;
  int _roundCount = 4;
  double _trackWidth = 28;
  int _roundIndex = 0;
  int _offTrackInRound = 0;
  int _samples = 0;
  double _deviationSum = 0;
  double _maxDeviation = 0;
  double _progress = 0;
  bool _running = false;
  bool _roundComplete = false;
  bool _wasOffTrack = false;
  List<Offset> _path = const <Offset>[];
  Offset _cursor = const Offset(0.08, 0.5);

  int get _completed => _records.length;

  int get _averageDeviation {
    if (_samples == 0) {
      return 0;
    }
    return (_deviationSum / _samples).round();
  }

  int get _sessionAverageDeviation {
    if (_records.isEmpty) {
      return 0;
    }
    final total = _records.fold<double>(
      0,
      (sum, item) => sum + item.averageDeviation,
    );
    return (total / _records.length).round();
  }

  int get _bestMs {
    if (_records.isEmpty) {
      return 0;
    }
    return _records
        .map((item) => item.milliseconds)
        .reduce((a, b) => math.min(a, b));
  }

  @override
  void initState() {
    super.initState();
    _path = _generatePath();
    _cursor = _path.first;
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  List<Offset> _generatePath() {
    final nodeCount = switch (_difficulty) {
      _DragTrackDifficulty.gentle => 5,
      _DragTrackDifficulty.standard => 7,
      _DragTrackDifficulty.expert => 9,
    };
    final amplitude = switch (_difficulty) {
      _DragTrackDifficulty.gentle => 0.16,
      _DragTrackDifficulty.standard => 0.26,
      _DragTrackDifficulty.expert => 0.34,
    };
    final phase = _random.nextDouble() * math.pi * 2;
    return List<Offset>.generate(nodeCount, (index) {
      final t = index / (nodeCount - 1);
      final x = 0.08 + t * 0.84;
      final y = index == 0 || index == nodeCount - 1
          ? 0.5
          : (0.5 +
                    math.sin(phase + t * math.pi * 2.6) * amplitude * 0.65 +
                    (_random.nextDouble() - 0.5) * amplitude)
                .clamp(0.18, 0.82)
                .toDouble();
      return Offset(x, y);
    }, growable: false);
  }

  void _start() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _running = true;
    });
    _beginRound();
  }

  void _reset() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _running = false;
      _roundComplete = false;
      _progress = 0;
      _offTrackInRound = 0;
      _samples = 0;
      _deviationSum = 0;
      _maxDeviation = 0;
      _path = _generatePath();
      _cursor = _path.first;
    });
  }

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    setState(() {
      _path = _generatePath();
      _cursor = _path.first;
      _progress = 0;
      _offTrackInRound = 0;
      _samples = 0;
      _deviationSum = 0;
      _maxDeviation = 0;
      _wasOffTrack = false;
      _roundComplete = false;
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _handlePointer(Offset localPosition, Size size) {
    if (!_running || _roundComplete || size.width <= 0 || size.height <= 0) {
      return;
    }
    final points = _scaledPath(size);
    final projection = _projectToPath(localPosition, points);
    final offTrack = projection.distance > _trackWidth * 0.55;
    setState(() {
      _cursor = Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
        (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
      );
      _samples += 1;
      _deviationSum += projection.distance;
      _maxDeviation = math.max(_maxDeviation, projection.distance);
      if (offTrack && !_wasOffTrack) {
        _offTrackInRound += 1;
      }
      _wasOffTrack = offTrack;
      if (!offTrack) {
        _progress = math.max(_progress, projection.progress);
      }
    });
    if (!offTrack && _progress >= 0.985) {
      _completeRound();
    }
  }

  void _completeRound() {
    if (_roundComplete) {
      return;
    }
    _stopwatch.stop();
    final averageDeviation = _samples == 0 ? 0.0 : _deviationSum / _samples;
    setState(() {
      _roundComplete = true;
      _roundIndex += 1;
      _records.add(
        _DragTrackRecord(
          milliseconds: math.max(1, _stopwatch.elapsedMilliseconds),
          offTrackEvents: _offTrackInRound,
          averageDeviation: averageDeviation,
          maxDeviation: _maxDeviation,
          difficulty: _difficulty,
        ),
      );
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 720), _beginRound);
  }

  void _finish() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _roundComplete = true;
    });
    unawaited(_showReport());
  }

  List<Offset> _scaledPath(Size size) {
    return _path
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
  }

  _DragTrackProjection _projectToPath(Offset point, List<Offset> points) {
    var totalLength = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      totalLength += (points[index + 1] - points[index]).distance;
    }
    var traversed = 0.0;
    var bestDistance = double.infinity;
    var bestProgress = 0.0;
    var bestPoint = points.first;
    for (var index = 0; index < points.length - 1; index += 1) {
      final a = points[index];
      final b = points[index + 1];
      final segment = b - a;
      final segmentLength = segment.distance;
      if (segmentLength <= 0) {
        continue;
      }
      final t =
          (((point - a).dx * segment.dx + (point - a).dy * segment.dy) /
                  (segmentLength * segmentLength))
              .clamp(0.0, 1.0)
              .toDouble();
      final projected = a + segment * t;
      final distance = (point - projected).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestProgress = totalLength <= 0
            ? 0
            : ((traversed + segmentLength * t) / totalLength)
                  .clamp(0.0, 1.0)
                  .toDouble();
        bestPoint = projected;
      }
      traversed += segmentLength;
    }
    return _DragTrackProjection(
      distance: bestDistance,
      progress: bestProgress,
      nearest: bestPoint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              '$_completed/$_roundCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '轨迹进度',
                en: 'Track',
                ja: 'Track',
                de: 'Track',
                fr: 'Voie',
                es: 'Pista',
                ru: 'трек',
              ),
              '${(_progress * 100).round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均偏离',
                en: 'Avg deviation',
                ja: '平均偏差',
                de: 'Avg deviation',
                fr: 'Écart d\'Avg',
                es: 'Avg deviation',
                ru: 'отклонение',
              ),
              _samples == 0 ? '-' : '${_averageDeviation}px',
            ),
            (
              pickUiText(
                i18n,
                zh: '离轨',
                en: 'Off-track',
                ja: 'Off-track',
                de: 'Off-track',
                fr: 'Hors piste',
                es: 'Off-track',
                ru: 'Вне трассы',
              ),
              '$_offTrackInRound',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '拖拽设置',
            en: 'Drag settings',
            ja: 'Drag settings',
            de: 'Drag settings',
            fr: 'Paramètres de glisser',
            es: 'Ajustes',
            ru: 'Настройки перетаскивания',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '轨迹复杂度、宽度和轮数都在这里。',
            en: 'Adjust track complexity, width, and round count.',
            ja: 'トラックの複雑さ、幅、ラウンドカウントを調整します。',
            de: 'Adjust track complexity, width, and round count.',
            fr: 'Adjust track complexity, width, and round count.',
            es: 'Ajuste la complejidad de la pista, el ancho y el recuento redondo.',
            ru: 'Настройте сложность трека, ширину и количество раундов.',
          ),
          child: _buildSettings(context, i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
      ],
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: _running
                  ? pickUiText(
                      i18n,
                      zh: '重新开始',
                      en: 'Restart',
                      ja: 'Restart',
                      de: 'Restart',
                      fr: 'Redémarrer',
                      es: 'Restart',
                      ru: 'Перезапустить',
                    )
                  : pickUiText(
                      i18n,
                      zh: '开始',
                      en: 'Start',
                      ja: 'Start',
                      de: 'Start',
                      fr: 'Démarrer',
                      es: 'Comienzo',
                      ru: 'Начинать',
                    ),
              icon: _running ? Icons.replay_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '重置',
                  en: 'Reset',
                  ja: 'Reset',
                  de: 'Reset',
                  fr: 'Réinitialiser',
                  es: 'Reset',
                  ru: 'сброс',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _running
              ? pickUiText(
                  i18n,
                  zh: '拖动光标沿轨迹前进，离轨会被记录。',
                  en: 'Drag the cursor along the path; leaving the track is recorded.',
                  ja: 'Drag the cursor along the path; leaving the track is recorded.',
                  de: 'Drag the cursor along the path; leaving the track is recorded.',
                  fr: 'Faites glisser le curseur le long du chemin; la sortie de la piste est enregistrée.',
                  es: 'Arrastre el cursor a lo largo del camino; dejar la pista se registra.',
                  ru: 'Перетащите курсор по траектории; выход из трека записывается.',
                )
              : pickUiText(
                  i18n,
                  zh: '开始后从左侧起点沿线拖到右侧终点。',
                  en: 'After starting, drag from the left start point to the right finish point.',
                  ja: '開始後、左の開始点から右の終了点までドラッグします。',
                  de: 'After starting, drag from the left start point to the right finish point.',
                  fr: 'After starting, drag from the left start point to the right finish point.',
                  es: 'Después de comenzar, arrastre desde el punto de inicio izquierdo hasta el punto de llegada derecho.',
                  ru: 'После старта перетащите с левой точки старта на правую точку финиша.',
                ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.62,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return _HumanPointerDragBoundary(
                onPointerDown: (event) =>
                    _handlePointer(event.localPosition, size),
                onPointerMove: (event) =>
                    _handlePointer(event.localPosition, size),
                child: CustomPaint(
                  key: const ValueKey<String>('fine-drag-track-stage'),
                  painter: _DragTrackPainter(
                    path: _path,
                    cursor: _cursor,
                    progress: _progress,
                    trackWidth: _trackWidth,
                    accent: _accent,
                    offTrack: _wasOffTrack,
                    surface: Theme.of(context).colorScheme.surface,
                    outline: Theme.of(context).colorScheme.outlineVariant,
                    error: Theme.of(context).colorScheme.error,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            i18n,
            zh: '难度',
            en: 'Difficulty',
            ja: 'Difficulty',
            de: 'Difficulty',
            fr: 'Difficulté',
            es: 'Dificultad',
            ru: 'трудность',
          ),
        ),
        Wrap(
          spacing: 8,
          children: _DragTrackDifficulty.values
              .map((difficulty) {
                return ChoiceChip(
                  label: Text(_difficultyLabel(i18n, difficulty)),
                  selected: _difficulty == difficulty,
                  onSelected: _running
                      ? null
                      : (_) {
                          setState(() {
                            _difficulty = difficulty;
                            _path = _generatePath();
                            _cursor = _path.first;
                          });
                        },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(
          pickUiText(
            i18n,
            zh: '轨道宽度',
            en: 'Track width',
            ja: 'Track width',
            de: 'Track width',
            fr: 'Largeur de la voie',
            es: 'Ancho de pista',
            ru: 'Ширина полосы движения',
          ),
        ),
        Slider(
          value: _trackWidth,
          min: 18,
          max: 38,
          divisions: 10,
          label: '${_trackWidth.round()} px',
          onChanged: _running
              ? null
              : (value) => setState(() => _trackWidth = value),
        ),
        const SizedBox(height: 12),
        Text(
          pickUiText(
            i18n,
            zh: '轮数',
            en: 'Rounds',
            ja: 'Rounds',
            de: 'Rounds',
            fr: 'Rondes',
            es: 'Rondas',
            ru: 'Круги',
          ),
        ),
        Wrap(
          spacing: 8,
          children: <int>[3, 4, 5, 6]
              .map(
                (value) => ChoiceChip(
                  label: Text('$value'),
                  selected: _roundCount == value,
                  onSelected: _running
                      ? null
                      : (_) => setState(() => _roundCount = value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String _difficultyLabel(AppI18n i18n, _DragTrackDifficulty difficulty) {
    return switch (difficulty) {
      _DragTrackDifficulty.gentle => pickUiText(
        i18n,
        zh: '舒缓',
        en: 'Gentle',
        ja: 'Gentle',
        de: 'Gentle',
        fr: 'Doucement',
        es: 'Gentle',
        ru: 'нежный',
      ),
      _DragTrackDifficulty.standard => pickUiText(
        i18n,
        zh: '标准',
        en: 'Standard',
        ja: 'Standard',
        de: 'Standard',
        fr: 'Norme',
        es: 'Estándar',
        ru: 'Стандарт',
      ),
      _DragTrackDifficulty.expert => pickUiText(
        i18n,
        zh: '精细',
        en: 'Expert',
        ja: 'Expert',
        de: 'Expert',
        fr: 'Expert',
        es: 'Expert',
        ru: 'эксперт',
      ),
    };
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '拖拽追踪报告',
              en: 'Drag tracking report',
              ja: 'Drag tracking report',
              de: 'Drag tracking report',
              fr: 'Rapport de suivi du glissement',
              es: 'Informe de seguimiento de los resultados',
              ru: 'Отчет по отслеживанию бросков',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HumanMetricWrap(
                  metrics: <(String, String)>[
                    (
                      pickUiText(
                        i18n,
                        zh: '完成',
                        en: 'Completed',
                        ja: 'しました。完了しました',
                        de: 'Completed',
                        fr: 'Achevé',
                        es: 'Completado',
                        ru: 'завершенный',
                      ),
                      '${_records.length}/$_roundCount',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '最佳用时',
                        en: 'Best time',
                        ja: 'ベストタイム',
                        de: 'Best time',
                        fr: 'Meilleur moment',
                        es: 'El mejor tiempo',
                        ru: 'Лучшее время',
                      ),
                      _formatMilliseconds(_bestMs),
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '平均偏离',
                        en: 'Avg deviation',
                        ja: '平均偏差',
                        de: 'Avg deviation',
                        fr: 'Écart d\'Avg',
                        es: 'Avg deviation',
                        ru: 'отклонение',
                      ),
                      '${_sessionAverageDeviation}px',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '总离轨',
                        en: 'Off-track total',
                        ja: 'Off-track total',
                        de: 'Off-track total',
                        fr: 'Total hors piste',
                        es: 'Total desviado',
                        ru: 'Вне трассы общее',
                      ),
                      '${_records.fold<int>(0, (sum, item) => sum + item.offTrackEvents)}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HumanPanel(
                  child: Text(
                    _sessionAverageDeviation <= _trackWidth * 0.35
                        ? pickUiText(
                            i18n,
                            zh: '控制稳定，可以尝试更窄轨道或更高难度。',
                            en: 'Control is stable. Try a narrower track or higher difficulty.',
                            ja: 'コントロールは安定しています。狭いトラック以上の難易度を試してみてください。',
                            de: 'Control is stable. Try a narrower track or higher difficulty.',
                            fr: 'Le contrôle est stable. Essayez une piste plus étroite ou plus difficile.',
                            es: 'El control es estable. Pruebe una vía más estrecha o mayor dificultad.',
                            ru: 'Контроль стабилен. Попробуйте более узкий путь или более высокую сложность.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '建议降低难度，先保持慢速连续移动，减少突然折返。',
                            en: 'Lower the difficulty and focus on slow, continuous movement with fewer abrupt reversals.',
                            ja: 'Lower the difficulty and focus on slow, continuous movement with fewer abrupt reversals.',
                            de: 'Lower the difficulty and focus on slow, continuous movement with fewer abrupt reversals.',
                            fr: 'Abaissez la difficulté et concentrez-vous sur le mouvement lent et continu avec moins de renversements brusques.',
                            es: 'Bajar la dificultad y centrarse en el movimiento lento y continuo con menos reversales abruptos.',
                            ru: 'Снизьте сложность и сосредоточьтесь на медленном, непрерывном движении с меньшим количеством резких разворотов.',
                          ),
                  ),
                ),
              ],
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
      },
    );
  }
}

class _DragTrackPainter extends CustomPainter {
  const _DragTrackPainter({
    required this.path,
    required this.cursor,
    required this.progress,
    required this.trackWidth,
    required this.accent,
    required this.offTrack,
    required this.surface,
    required this.outline,
    required this.error,
  });

  final List<Offset> path;
  final Offset cursor;
  final double progress;
  final double trackWidth;
  final Color accent;
  final bool offTrack;
  final Color surface;
  final Color outline;
  final Color error;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }
    final points = path
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    final basePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      basePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      basePath,
      Paint()
        ..color = outline
        ..strokeWidth = trackWidth + 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      basePath,
      Paint()
        ..color = surface
        ..strokeWidth = trackWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    _drawProgress(canvas, points);
    canvas.drawCircle(points.first, 13, Paint()..color = accent);
    canvas.drawCircle(
      points.last,
      13,
      Paint()
        ..color = surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      points.last,
      13,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final cursorPoint = Offset(cursor.dx * size.width, cursor.dy * size.height);
    canvas.drawCircle(
      cursorPoint,
      14,
      Paint()..color = (offTrack ? error : accent).withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      cursorPoint,
      8,
      Paint()..color = offTrack ? error : accent,
    );
  }

  void _drawProgress(Canvas canvas, List<Offset> points) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (clamped <= 0) {
      return;
    }
    var totalLength = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      totalLength += (points[index + 1] - points[index]).distance;
    }
    var remaining = totalLength * clamped;
    final progressPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index += 1) {
      final a = points[index];
      final b = points[index + 1];
      final segment = b - a;
      final length = segment.distance;
      if (remaining >= length) {
        progressPath.lineTo(b.dx, b.dy);
        remaining -= length;
      } else {
        final t = length == 0
            ? 0.0
            : (remaining / length).clamp(0.0, 1.0).toDouble();
        final end = a + segment * t;
        progressPath.lineTo(end.dx, end.dy);
        break;
      }
    }
    canvas.drawPath(
      progressPath,
      Paint()
        ..color = accent
        ..strokeWidth = math.max(4, trackWidth * 0.32)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DragTrackPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.cursor != cursor ||
        oldDelegate.progress != progress ||
        oldDelegate.trackWidth != trackWidth ||
        oldDelegate.offTrack != offTrack ||
        oldDelegate.surface != surface ||
        oldDelegate.outline != outline ||
        oldDelegate.error != error;
  }
}

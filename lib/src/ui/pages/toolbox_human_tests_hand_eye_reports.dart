part of 'toolbox_human_tests.dart';

class _HumanReportDialogFrame extends StatelessWidget {
  const _HumanReportDialogFrame({
    required this.title,
    required this.children,
    required this.accent,
  });

  final Widget title;
  final List<Widget> children;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaSize = MediaQuery.sizeOf(context);
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : mediaSize.width - 32;
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : mediaSize.height - 48;
          final width = math.min(560.0, math.max(0.0, availableWidth));
          final height = math.min(640.0, math.max(0.0, availableHeight));

          return SizedBox(
            width: width,
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    child: title,
                  ),
                ),
                Divider(height: 1, color: accent.withValues(alpha: 0.18)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).okButtonLabel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HandEyeCompletionReportDialog extends StatelessWidget {
  const _HandEyeCompletionReportDialog({
    required this.results,
    required this.roundCount,
    required this.totalBlankTaps,
    required this.totalDistractorTaps,
    required this.accent,
  });

  final List<_HandEyeRoundResult> results;
  final int roundCount;
  final int totalBlankTaps;
  final int totalDistractorTaps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final successes = results.where((item) => item.success).length;
    final missed = results.length - successes;
    final reactions = results
        .where((item) => item.success && item.firstReaction != null)
        .map((item) => item.firstReaction!.inMilliseconds)
        .toList(growable: false);
    final averageReaction = reactions.isEmpty
        ? null
        : Duration(
            milliseconds: (reactions.reduce((a, b) => a + b) / reactions.length)
                .round(),
          );
    final bestReaction = reactions.isEmpty ? null : reactions.reduce(math.min);
    final completionTimes = results
        .where((item) => item.completionLatency != null)
        .map((item) => item.completionLatency!.inMilliseconds)
        .toList(growable: false);
    final averageCompletion = completionTimes.isEmpty
        ? null
        : Duration(
            milliseconds:
                (completionTimes.reduce((a, b) => a + b) /
                        completionTimes.length)
                    .round(),
          );

    return _HumanReportDialogFrame(
      title: Text(
        pickUiText(
          i18n,
          zh: '手眼协调结果报告',
          en: 'Hand-eye report',
          ja: 'Hand-eye report',
          de: 'Hand-eye report',
          fr: 'Rapport sur les yeux des mains',
          es: 'Informe de mano-ojo',
          ru: 'Отчет с глаз долой',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '完成轮次',
                en: 'Rounds',
                ja: 'Rounds',
                de: 'Rounds',
                fr: 'Rondes',
                es: 'Rondas',
                ru: 'Круги',
              ),
              '$successes/$roundCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '漏掉',
                en: 'Missed',
                ja: 'Missed',
                de: 'Missed',
                fr: 'Manque',
                es: 'Desaparecido',
                ru: 'Пропавший',
              ),
              '$missed',
            ),
            (
              pickUiText(
                i18n,
                zh: '点空',
                en: 'Blanks',
                ja: 'ブランク',
                de: 'Blanks',
                fr: 'Blancs',
                es: 'Blanks',
                ru: 'бланки',
              ),
              '$totalBlankTaps',
            ),
            (
              pickUiText(
                i18n,
                zh: '假目标',
                en: 'False targets',
                ja: 'False targets',
                de: 'False targets',
                fr: 'Faux objectifs',
                es: 'Objetivos falsos',
                ru: 'Ложные цели',
              ),
              '$totalDistractorTaps',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均反应',
                en: 'Avg reaction',
                ja: '平均反応',
                de: 'Avg reaction',
                fr: 'Réaction d\' Avg',
                es: 'Reacción de Avg',
                ru: 'Авг реакция',
              ),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
            (
              pickUiText(
                i18n,
                zh: '最快反应',
                en: 'Best reaction',
                ja: 'ベスト',
                de: 'Best reaction',
                fr: 'Meilleure réaction',
                es: 'La mejor reacción',
                ru: 'лучшая реакция',
              ),
              bestReaction == null ? '-' : _formatMilliseconds(bestReaction),
            ),
            (
              pickUiText(
                i18n,
                zh: '平均完成',
                en: 'Avg completion',
                ja: '平均',
                de: 'Avg completion',
                fr: 'Achèvement',
                es: 'Finalización de la Avg',
                ru: 'Завершение Avg',
              ),
              averageCompletion == null
                  ? '-'
                  : _formatMilliseconds(averageCompletion.inMilliseconds),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(
            i18n,
            zh: '逐轮明细',
            en: 'Round details',
            ja: 'Round details',
            de: 'Round details',
            fr: 'Détails',
            es: 'Detalles de la ronda',
            ru: 'Круглые детали',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Column(
          children: <Widget>[
            for (var index = 0; index < results.length; index++) ...<Widget>[
              _HandEyeResultRow(
                index: index + 1,
                result: results[index],
                accent: accent,
              ),
              if (index != results.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _JoystickCompletionReportDialog extends StatelessWidget {
  const _JoystickCompletionReportDialog({
    required this.mode,
    required this.durationSeconds,
    required this.targetGoal,
    required this.hits,
    required this.shotsOff,
    required this.falseTargetShots,
    required this.reactions,
    required this.targetDiameter,
    required this.targetMovementEnabled,
    required this.accent,
  });

  final _JoystickTestMode mode;
  final int durationSeconds;
  final int targetGoal;
  final int hits;
  final int shotsOff;
  final int falseTargetShots;
  final List<Duration> reactions;
  final double targetDiameter;
  final bool targetMovementEnabled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final shots = hits + shotsOff;
    final accuracy = shots == 0 ? null : hits / shots * 100;
    final reactionMs = reactions
        .map((item) => item.inMilliseconds)
        .toList(growable: false);
    final averageReaction = reactionMs.isEmpty
        ? null
        : Duration(
            milliseconds:
                (reactionMs.reduce((a, b) => a + b) / reactionMs.length)
                    .round(),
          );
    final bestReaction = reactionMs.isEmpty
        ? null
        : reactionMs.reduce(math.min);
    final progress = mode == _JoystickTestMode.timed
        ? _formatSeconds(durationSeconds)
        : '$hits/$targetGoal';

    return _HumanReportDialogFrame(
      title: Text(
        pickUiText(
          i18n,
          zh: '摇杆手眼协调结果报告',
          en: 'Joystick report',
          ja: 'Joystick report',
          de: 'Joystick report',
          fr: 'Rapport Joystick',
          es: 'Informe de Joystick',
          ru: 'Отчет Джойстика',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '模式',
                en: 'Mode',
                ja: 'Mode',
                de: 'Mode',
                fr: 'Mode',
                es: 'Modo',
                ru: 'Режим',
              ),
              mode == _JoystickTestMode.timed
                  ? pickUiText(
                      i18n,
                      zh: '单位时间',
                      en: 'Timed',
                      ja: 'Timed',
                      de: 'Timed',
                      fr: 'Délai',
                      es: 'Timed',
                      ru: 'Время',
                    )
                  : pickUiText(
                      i18n,
                      zh: '目标总数',
                      en: 'Target count',
                      ja: 'Target count',
                      de: 'Target count',
                      fr: 'Nombre cible',
                      es: 'Conteo de objetivos',
                      ru: 'Целевой счет',
                    ),
            ),
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
              progress,
            ),
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
              '$hits',
            ),
            (
              pickUiText(
                i18n,
                zh: '射空',
                en: 'Shots off',
                ja: 'Shots off',
                de: 'Shots off',
                fr: 'Coups de feu',
                es: 'Disparos apagados',
                ru: 'Выстрелы',
              ),
              '$shotsOff',
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
              accuracy == null ? '-' : '${accuracy.round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均反应',
                en: 'Avg reaction',
                ja: '平均反応',
                de: 'Avg reaction',
                fr: 'Réaction d\' Avg',
                es: 'Reacción de Avg',
                ru: 'Авг реакция',
              ),
              averageReaction == null
                  ? '-'
                  : _formatMilliseconds(averageReaction.inMilliseconds),
            ),
            (
              pickUiText(
                i18n,
                zh: '最快反应',
                en: 'Best reaction',
                ja: 'ベスト',
                de: 'Best reaction',
                fr: 'Meilleure réaction',
                es: 'La mejor reacción',
                ru: 'лучшая реакция',
              ),
              bestReaction == null ? '-' : _formatMilliseconds(bestReaction),
            ),
            (
              pickUiText(
                i18n,
                zh: '假目标射击',
                en: 'False shots',
                ja: 'False shots',
                de: 'False shots',
                fr: 'Faux coups',
                es: 'Falsos disparos',
                ru: 'Ложные выстрелы',
              ),
              '$falseTargetShots',
            ),
            (
              pickUiText(
                i18n,
                zh: '目标大小',
                en: 'Target size',
                ja: 'Target size',
                de: 'Target size',
                fr: 'Taille cible',
                es: 'Tamaño del objetivo',
                ru: 'Целевой размер',
              ),
              '${targetDiameter.round()} dp',
            ),
            (
              pickUiText(
                i18n,
                zh: '目标移动',
                en: 'Target movement',
                ja: 'Target movement',
                de: 'Target movement',
                fr: 'Cible',
                es: 'Movimiento objetivo',
                ru: 'Движение мишеней',
              ),
              targetMovementEnabled
                  ? pickUiText(
                      i18n,
                      zh: '开启',
                      en: 'On',
                      ja: 'On',
                      de: 'On',
                      fr: 'À',
                      es: 'On',
                      ru: 'На',
                    )
                  : pickUiText(
                      i18n,
                      zh: '关闭',
                      en: 'Off',
                      ja: 'Off',
                      de: 'Off',
                      fr: 'Arrêt',
                      es: 'Fuera.',
                      ru: 'Оставить',
                    ),
            ),
          ],
        ),
        if (reactions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            pickUiText(
              i18n,
              zh: '命中延迟明细',
              en: 'Hit latency details',
              ja: 'Hit latency details',
              de: 'Hit latency details',
              fr: 'Affichage des détails de latence',
              es: 'Datos de latencia',
              ru: 'Детали задержки',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(reactions.length, (index) {
              return _HumanPill(
                text:
                    '#${index + 1} ${_formatMilliseconds(reactions[index].inMilliseconds)}',
                accent: accent,
              );
            }),
          ),
        ],
      ],
    );
  }
}

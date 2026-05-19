part of 'toolbox_human_tests.dart';

class _ColorVisionTargetPrompt extends StatelessWidget {
  const _ColorVisionTargetPrompt({
    required this.i18n,
    required this.color,
    required this.targetCount,
  });

  final AppI18n i18n;
  final Color color;
  final int targetCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(
                    i18n,
                    zh: '目标颜色',
                    en: 'Target color',
                    ja: 'Target color',
                    de: 'Target color',
                    fr: 'Couleur de la cible',
                    es: 'Color blanco',
                    ru: 'Целевой цвет',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pickUiText(
                    i18n,
                    zh: '点击与左侧色块完全相同的格子，本轮目标数：$targetCount',
                    en: 'Tap tiles exactly matching the swatch. Targets this round: $targetCount',
                    ja: 'Tap tiles exactly matching the swatch. Targets this round: $targetCount',
                    de: 'Tap tiles exactly matching the swatch. Targets this round: $targetCount',
                    fr: 'Taper les tuiles qui correspondent exactement à la montre. Cible ce cycle : $targetCount',
                    es: 'Pulsa las fichas exactamente igualando el reloj. Metas de esta ronda:',
                    ru: 'Нажмите на плитки, точно соответствующие часам. Цели этого раунда: $targetCount',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorVisionGrid extends StatelessWidget {
  const _ColorVisionGrid({
    required this.i18n,
    required this.cells,
    required this.gridSize,
    required this.hintActive,
    required this.onTap,
  });

  final AppI18n i18n;
  final List<_ColorVisionCell> cells;
  final int gridSize;
  final bool hintActive;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final cell = cells[index];
        final showHint = hintActive && cell.correct;
        return Semantics(
          button: true,
          label: showHint
              ? pickUiText(
                  i18n,
                  zh: '提示目标色块',
                  en: 'Hint target color tile',
                  ja: 'Hint target color tile',
                  de: 'Hint target color tile',
                  fr: 'Aligner la tuile de couleur cible',
                  es: 'Azulejos de color blanco',
                  ru: 'Цветная плитка Hint Target',
                )
              : pickUiText(
                  i18n,
                  zh: '色块',
                  en: 'Color tile',
                  ja: 'カラータイル',
                  de: 'Color tile',
                  fr: 'Carrelage couleur',
                  es: 'Azulejos de color',
                  ru: 'Цветная плитка',
                ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                key: ValueKey<String>('color-vision-cell-$index'),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cell.color,
                  border: Border.all(
                    color: showHint
                        ? colorScheme.onSurface
                        : Colors.white.withValues(alpha: 0.28),
                    width: showHint ? 3 : 1,
                  ),
                  boxShadow: showHint
                      ? <BoxShadow>[
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: showHint
                    ? Icon(
                        Icons.my_location_rounded,
                        color: colorScheme.onSurface,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorVisionSettingSlider extends StatelessWidget {
  const _ColorVisionSettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(valueText, style: theme.textTheme.labelMedium),
          ],
        ),
        if ((max - min).abs() < 0.001)
          const SizedBox(height: 8)
        else
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: math.max(1, divisions),
            label: valueText,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _ColorVisionReportDialog extends StatelessWidget {
  const _ColorVisionReportDialog({
    required this.data,
    required this.accent,
    required this.modeLabel,
    required this.filterLabel,
    required this.bandLabel,
    required this.axisLabel,
  });

  final _ColorVisionReportData data;
  final Color accent;
  final String Function(_ColorVisionMode mode) modeLabel;
  final String Function(_ColorVisionFilter filter) filterLabel;
  final String Function(_ColorVisionHueBand band) bandLabel;
  final String Function(_ColorVisionDeltaAxis axis) axisLabel;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final bandStats = _bandStats();
    final axisStats = _axisStats();
    final weakestBand = bandStats.isEmpty
        ? null
        : bandStats.reduce(
            (left, right) => left.accuracy <= right.accuracy ? left : right,
          );
    final weakestAxis = axisStats.isEmpty
        ? null
        : axisStats.reduce(
            (left, right) => left.accuracy <= right.accuracy ? left : right,
          );
    final recommendation = _recommendation(i18n, weakestBand, weakestAxis);

    return AlertDialog(
      title: Text(
        pickUiText(
          i18n,
          zh: '色觉测试报告',
          en: 'Color vision report',
          ja: 'カラービジョンカラービジョンレポート',
          de: 'Color vision report',
          fr: 'Rapport de vision couleur',
          es: 'Informe de visión de color',
          ru: 'Отчет о цветовом зрении',
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
                      zh: '最高等级',
                      en: 'Best level',
                      ja: 'ベストレベル',
                      de: 'Best level',
                      fr: 'Meilleur niveau',
                      es: 'Mejor nivel',
                      ru: 'Лучший уровень',
                    ),
                    value: '${data.bestLevel}',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '正确率',
                      en: 'Accuracy',
                      ja: '精度',
                      de: 'Accuracy',
                      fr: 'Accuracy',
                      es: 'Precisión',
                      ru: 'точность',
                    ),
                    value: '${(data.accuracy * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '完成轮次',
                      en: 'Rounds',
                      ja: 'Rounds',
                      de: 'Rounds',
                      fr: 'Rondes',
                      es: 'Rondas',
                      ru: 'Круги',
                    ),
                    value: '${data.rounds}',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '提示次数',
                      en: 'Hints',
                      ja: 'Hints',
                      de: 'Hints',
                      fr: 'Conseils',
                      es: 'Hintes',
                      ru: 'Подсказки',
                    ),
                    value: '${data.hintsUsed}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ColorVisionReportSection(
                title: pickUiText(
                  i18n,
                  zh: '整体判断',
                  en: 'Overall analysis',
                  ja: 'Overall analysis',
                  de: 'Overall analysis',
                  fr: 'Analyse générale',
                  es: 'Análisis general',
                  ru: 'Общий анализ',
                ),
                child: Text(
                  _overallSummary(i18n, weakestBand, weakestAxis),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              if (data.records.length >= 2)
                _ColorVisionReportSection(
                  title: pickUiText(
                    i18n,
                    zh: '近轮色差记录',
                    en: 'Recent delta records',
                    ja: 'Recent delta records',
                    de: 'Recent delta records',
                    fr: 'Données récentes concernant le delta',
                    es: 'Registros recientes delta',
                    ru: 'Последние дельта рекорды',
                  ),
                  child: _ColorVisionRecentDeltaList(
                    records: data.records,
                    accent: accent,
                  ),
                ),
              const SizedBox(height: 12),
              if (bandStats.isNotEmpty)
                _ColorVisionReportSection(
                  title: pickUiText(
                    i18n,
                    zh: '色相分组表现',
                    en: 'Hue groups',
                    ja: 'Hue groups',
                    de: 'Hue groups',
                    fr: 'Groupes Hue',
                    es: 'Grupos de Hue',
                    ru: 'Группы Хюэ',
                  ),
                  child: _ColorVisionBandStatList(
                    stats: bandStats,
                    labelFor: bandLabel,
                    accent: accent,
                  ),
                ),
              const SizedBox(height: 12),
              if (axisStats.isNotEmpty)
                _ColorVisionReportSection(
                  title: pickUiText(
                    i18n,
                    zh: '差异类型表现',
                    en: 'Contrast axes',
                    ja: 'コントラスト軸',
                    de: 'Contrast axes',
                    fr: 'Axes parallèles',
                    es: 'Hachas de contraste',
                    ru: 'Контрастные оси',
                  ),
                  child: _ColorVisionAxisStatList(
                    stats: axisStats,
                    labelFor: axisLabel,
                    accent: accent,
                  ),
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
                    Chip(label: Text(modeLabel(data.mode))),
                    Chip(label: Text(filterLabel(data.filter))),
                    Chip(
                      label: Text(
                        '${data.initialGrid}x${data.initialGrid} -> ${data.maxGrid}x${data.maxGrid}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '平均通过色差 ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}',
                          en: 'Avg passed delta ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}',
                          ja: '平均合格デルタ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}',
                          de: 'Avg passed delta ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}',
                          fr: 'Avg est passé delta ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}',
                          es: 'Avg pasó delta <v0/',
                          ru: 'Avg прошел дельту ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}',
                        ),
                      ),
                    ),
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
                  recommendation,
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

  List<_ColorVisionBandStat> _bandStats() {
    return _ColorVisionHueBand.values
        .map((band) {
          final records = data.records
              .where((record) => record.hueBand == band)
              .toList(growable: false);
          if (records.isEmpty) {
            return null;
          }
          return _ColorVisionBandStat(
            band: band,
            total: records.length,
            correct: records.where((record) => record.correct).length,
            averageDelta:
                records.fold<double>(0, (sum, record) => sum + record.delta) /
                records.length,
          );
        })
        .whereType<_ColorVisionBandStat>()
        .toList(growable: false);
  }

  List<_ColorVisionAxisStat> _axisStats() {
    return _ColorVisionDeltaAxis.values
        .map((axis) {
          final records = data.records
              .where((record) => record.deltaAxis == axis)
              .toList(growable: false);
          if (records.isEmpty) {
            return null;
          }
          return _ColorVisionAxisStat(
            axis: axis,
            total: records.length,
            correct: records.where((record) => record.correct).length,
          );
        })
        .whereType<_ColorVisionAxisStat>()
        .toList(growable: false);
  }

  String _overallSummary(
    AppI18n i18n,
    _ColorVisionBandStat? weakestBand,
    _ColorVisionAxisStat? weakestAxis,
  ) {
    if (data.rounds <= 0) {
      return pickUiText(
        i18n,
        zh: '还没有有效轮次。先完成几轮后，报告会显示色差、色相和弱项分析。',
        en: 'No valid rounds yet. Complete a few rounds to unlock delta, hue, and weak-area analysis.',
        ja: 'No valid rounds yet. Complete a few rounds to unlock delta, hue, and weak-area analysis.',
        de: 'No valid rounds yet. Complete a few rounds to unlock delta, hue, and weak-area analysis.',
        fr: 'Pas encore de rondes valides. Terminer quelques rondes pour déverrouiller l\'analyse delta, teinte et zone faible.',
        es: 'Todavía no hay rondas válidas. Complete algunas rondas para desbloquear el delta, el hue y el análisis de área débil.',
        ru: 'Никаких действительных раундов. Выполните несколько раундов, чтобы разблокировать анализ дельты, оттенка и слабой области.',
      );
    }
    final weakBandText = weakestBand == null
        ? pickUiText(
            i18n,
            zh: '暂不明显',
            en: 'not clear yet',
            ja: 'not clear yet',
            de: 'not clear yet',
            fr: 'pas encore clair',
            es: 'todavía no está claro',
            ru: 'Пока не ясно',
          )
        : bandLabel(weakestBand.band);
    final weakAxisText = weakestAxis == null
        ? pickUiText(
            i18n,
            zh: '暂不明显',
            en: 'not clear yet',
            ja: 'not clear yet',
            de: 'not clear yet',
            fr: 'pas encore clair',
            es: 'todavía no está claro',
            ru: 'Пока не ясно',
          )
        : axisLabel(weakestAxis.axis);
    return pickUiText(
      i18n,
      zh: '本轮正确率 ${(data.accuracy * 100).round()}%，最弱色相集中在 $weakBandText，较弱差异类型为 $weakAxisText。平均通过色差 ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}，平均失误色差 ${(data.averageMissDelta * 100).toStringAsFixed(1)}。',
      en: 'Accuracy is ${(data.accuracy * 100).round()}%. The weakest hue band is $weakBandText, and the weaker contrast axis is $weakAxisText. Average passed delta is ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}, while missed delta averages ${(data.averageMissDelta * 100).toStringAsFixed(1)}.',
      ja: '精度は${(data.accuracy * 100).round()}%です。最も弱い色相帯域はで$weakBandText、より弱いコントラスト軸はです$weakAxisText。合格したデルタの平均はですが${(data.averageCorrectDelta * 100).toStringAsFixed(1)}、合格しなかったデルタの平均はです${(data.averageMissDelta * 100).toStringAsFixed(1)}。',
      de: 'Accuracy is ${(data.accuracy * 100).round()}%. The weakest hue band is $weakBandText, and the weaker contrast axis is $weakAxisText. Average passed delta is ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}, while missed delta averages ${(data.averageMissDelta * 100).toStringAsFixed(1)}.',
      fr: 'Accuracy is ${(data.accuracy * 100).round()}%. The weakest hue band is $weakBandText, and the weaker contrast axis is $weakAxisText. Average passed delta is ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}, while missed delta averages ${(data.averageMissDelta * 100).toStringAsFixed(1)}.',
      es: 'La precisión es יv0/%. La banda más débil de los cascos es неv3/ confiar, y el eje de contraste más débil es неv4/ ES. Promedio aprobado delta es неv1/ título, mientras que falta el delta promedios יv2/año.',
      ru: 'Точность ${(data.accuracy * 100).round()}%. Самая слабая полоса оттенка - $weakBandText, а более слабая ось контраста - $weakAxisText. Средняя пройденная дельта ${(data.averageCorrectDelta * 100).toStringAsFixed(1)}, в то время как пропущенные средние дельты ${(data.averageMissDelta * 100).toStringAsFixed(1)}.',
    );
  }

  String _recommendation(
    AppI18n i18n,
    _ColorVisionBandStat? weakestBand,
    _ColorVisionAxisStat? weakestAxis,
  ) {
    if (data.rounds < 6) {
      return pickUiText(
        i18n,
        zh: '样本量还少，建议至少完成 10 轮再判断稳定弱项。可以先用 3 到 5 生命、4x4 网格练习。',
        en: 'The sample is still small. Complete at least 10 rounds before treating weak areas as stable. Start with 3 to 5 lives and a 4x4 grid.',
        ja: 'The sample is still small. Complete at least 10 rounds before treating weak areas as stable. Start with 3 to 5 lives and a 4x4 grid.',
        de: 'The sample is still small. Complete at least 10 rounds before treating weak areas as stable. Start with 3 to 5 lives and a 4x4 grid.',
        fr: 'L\'échantillon est encore petit. Terminer au moins 10 rondes avant de traiter les zones faibles comme stables. Commencez par 3 à 5 vies et une grille 4x4.',
        es: 'La muestra sigue siendo pequeña. Completa al menos 10 rondas antes de tratar áreas débiles como estables. Comience con 3 a 5 vidas y una cuadrícula 4x4.',
        ru: 'Образец все еще небольшой. Выполните не менее 10 раундов, прежде чем рассматривать слабые области как стабильные. Начните с 3-5 жизней и сетки 4x4.',
      );
    }
    final band = weakestBand == null ? '' : bandLabel(weakestBand.band);
    final axis = weakestAxis == null ? '' : axisLabel(weakestAxis.axis);
    return pickUiText(
      i18n,
      zh: '建议下一轮保留当前弱项相关色系，降低最大网格或开启提示练习。重点关注 $band 的 $axis，等正确率稳定后再提高最大网格。',
      en: 'For the next run, keep the weak hue family enabled, lower the maximum grid, or practice with hints. Focus on $axis around $band, then raise the maximum grid after accuracy stabilizes.',
      ja: 'For the next run, keep the weak hue family enabled, lower the maximum grid, or practice with hints. Focus on $axis around $band, then raise the maximum grid after accuracy stabilizes.',
      de: 'For the next run, keep the weak hue family enabled, lower the maximum grid, or practice with hints. Focus on $axis around $band, then raise the maximum grid after accuracy stabilizes.',
      fr: 'Pour la prochaine course, gardez la famille de teintes faibles activée, baissez la grille maximale, ou pratiquez avec des conseils. Concentrez-vous sur $axis autour de $band, puis augmentez la grille maximale après stabilisation de la précision.',
      es: 'Para la próxima carrera, mantenga activada la familia débil del casco, baja la rejilla máxima, o practique con indicios. Enfóquese en יv0/tio alrededor de <v1/tio, luego levante la cuadrícula máxima después de que se estabilice la precisión.',
      ru: 'Для следующего пробега держите семью слабого оттенка включенной, понижайте максимальную сетку или практикуйте с подсказками. Сосредоточьтесь на $axis вокруг $band, затем поднимите максимальную сетку после стабилизации точности.',
    );
  }
}

class _ColorVisionReportMetric extends StatelessWidget {
  const _ColorVisionReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ColorVisionReportSection extends StatelessWidget {
  const _ColorVisionReportSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ColorVisionRecentDeltaList extends StatelessWidget {
  const _ColorVisionRecentDeltaList({
    required this.records,
    required this.accent,
  });

  final List<_ColorVisionRoundRecord> records;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final shown = records.length <= 8
        ? records
        : records.sublist(records.length - 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(shown.length, (index) {
        final record = shown[index];
        final color = record.correct
            ? accent
            : Theme.of(context).colorScheme.error;
        return Padding(
          padding: EdgeInsets.only(bottom: index == shown.length - 1 ? 0 : 8),
          child: Row(
            children: <Widget>[
              Icon(
                record.correct
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: record.delta.clamp(0.0, 1.0),
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pickUiText(
                  i18n,
                  zh: '色差 ${(record.delta * 100).toStringAsFixed(1)}',
                  en: 'Delta ${(record.delta * 100).toStringAsFixed(1)}',
                  ja: 'Delta ${(record.delta * 100).toStringAsFixed(1)}',
                  de: 'Delta ${(record.delta * 100).toStringAsFixed(1)}',
                  fr: 'Delta ${(record.delta * 100).toStringAsFixed(1)}',
                  es: 'Delta',
                  ru: 'Дельта ${(record.delta * 100).toStringAsFixed(1)}',
                ),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ColorVisionBandStatList extends StatelessWidget {
  const _ColorVisionBandStatList({
    required this.stats,
    required this.labelFor,
    required this.accent,
  });

  final List<_ColorVisionBandStat> stats;
  final String Function(_ColorVisionHueBand band) labelFor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: stats
          .map((stat) {
            return _ColorVisionStatRow(
              label: labelFor(stat.band),
              value: stat.accuracy,
              trailing:
                  '${stat.correct}/${stat.total} · ${(stat.averageDelta * 100).toStringAsFixed(1)}',
              color: accent,
            );
          })
          .toList(growable: false),
    );
  }
}

class _ColorVisionAxisStatList extends StatelessWidget {
  const _ColorVisionAxisStatList({
    required this.stats,
    required this.labelFor,
    required this.accent,
  });

  final List<_ColorVisionAxisStat> stats;
  final String Function(_ColorVisionDeltaAxis axis) labelFor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: stats
          .map((stat) {
            return _ColorVisionStatRow(
              label: labelFor(stat.axis),
              value: stat.accuracy,
              trailing: '${stat.correct}/${stat.total}',
              color: accent,
            );
          })
          .toList(growable: false),
    );
  }
}

class _ColorVisionStatRow extends StatelessWidget {
  const _ColorVisionStatRow({
    required this.label,
    required this.value,
    required this.trailing,
    required this.color,
  });

  final String label;
  final double value;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value.clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              '${(value * 100).round()}% $trailing',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorVisionDeltaTrendPainter extends CustomPainter {
  const _ColorVisionDeltaTrendPainter({
    required this.records,
    required this.accent,
    required this.errorColor,
  });

  final List<_ColorVisionRoundRecord> records;
  final Color accent;
  final Color errorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      12,
      10,
      math.max(0, size.width - 24),
      math.max(0, size.height - 22),
    );
    final axisPaint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index += 1) {
      final y = chartRect.top + chartRect.height * index / 3;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        axisPaint,
      );
    }
    if (records.length < 2) {
      return;
    }
    final deltas = records
        .map((record) => record.delta)
        .toList(growable: false);
    final minDelta = deltas.reduce(math.min);
    final maxDelta = deltas.reduce(math.max);
    final deltaSpan = math.max(0.01, maxDelta - minDelta);
    final points = <Offset>[];
    for (var index = 0; index < records.length; index += 1) {
      final record = records[index];
      final x = records.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * index / (records.length - 1);
      final normalized = maxDelta == minDelta
          ? 0.5
          : ((record.delta - minDelta) / deltaSpan).clamp(0.0, 1.0);
      final y = chartRect.bottom - normalized * chartRect.height;
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index += 1) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var index = 0; index < points.length; index += 1) {
      final color = records[index].correct ? accent : errorColor;
      canvas.drawCircle(
        points[index],
        records[index].usedHint ? 6 : 4,
        Paint()..color = color,
      );
      if (records[index].usedHint) {
        canvas.drawCircle(
          points[index],
          8,
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ColorVisionDeltaTrendPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.accent != accent ||
        oldDelegate.errorColor != errorColor;
  }
}

class _ColorVisionHueBiasPainter extends CustomPainter {
  const _ColorVisionHueBiasPainter({
    required this.stats,
    required this.labelFor,
    required this.accent,
    required this.textColor,
  });

  final List<_ColorVisionBandStat> stats;
  final String Function(_ColorVisionHueBand band) labelFor;
  final Color accent;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) {
      return;
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelWidth = math.min(84.0, size.width * 0.28);
    final valueWidth = 48.0;
    final barLeft = labelWidth;
    final barRight = math.max(barLeft + 40, size.width - valueWidth);
    final rowHeight = math.max(26.0, (size.height - 8) / stats.length);
    for (var index = 0; index < stats.length; index += 1) {
      final stat = stats[index];
      final top = 4 + index * rowHeight;
      final centerY = top + rowHeight * 0.5;
      final track = Rect.fromLTWH(
        barLeft,
        centerY - 6,
        math.max(1, barRight - barLeft),
        12,
      );
      final width = track.width * stat.accuracy.clamp(0.0, 1.0);
      final filled = Rect.fromLTWH(track.left, track.top, width, track.height);
      textPainter.text = TextSpan(
        text: labelFor(stat.band),
        style: TextStyle(fontSize: 11, color: textColor),
      );
      textPainter.layout(maxWidth: labelWidth - 8);
      textPainter.paint(canvas, Offset(0, centerY - textPainter.height / 2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(track, const Radius.circular(999)),
        Paint()..color = accent.withValues(alpha: 0.10),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(filled, const Radius.circular(999)),
        Paint()..color = accent.withValues(alpha: 0.42 + stat.accuracy * 0.42),
      );
      textPainter.text = TextSpan(
        text: '${(stat.accuracy * 100).round()}%',
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: valueWidth);
      textPainter.paint(
        canvas,
        Offset(
          size.width - textPainter.width,
          centerY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColorVisionHueBiasPainter oldDelegate) {
    return oldDelegate.stats != stats ||
        oldDelegate.accent != accent ||
        oldDelegate.textColor != textColor;
  }
}

class _ColorVisionAxisBarPainter extends CustomPainter {
  const _ColorVisionAxisBarPainter({
    required this.stats,
    required this.axisLabel,
    required this.colors,
    required this.textColor,
  });

  final List<_ColorVisionAxisStat> stats;
  final String Function(_ColorVisionDeltaAxis axis) axisLabel;
  final List<Color> colors;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) {
      return;
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelWidth = math.min(108.0, size.width * 0.34);
    final valueWidth = 64.0;
    final trackLeft = labelWidth;
    final trackRight = math.max(trackLeft + 44, size.width - valueWidth);
    final rowHeight = math.max(34.0, (size.height - 8) / stats.length);
    for (var index = 0; index < stats.length; index += 1) {
      final stat = stats[index];
      final top = 4 + index * rowHeight;
      final centerY = top + rowHeight * 0.5;
      final color = colors[index % colors.length];
      final accuracy = stat.accuracy.clamp(0.0, 1.0);
      final track = Rect.fromLTWH(
        trackLeft,
        centerY - 7,
        math.max(1, trackRight - trackLeft),
        14,
      );
      textPainter.text = TextSpan(
        text: axisLabel(stat.axis),
        style: TextStyle(fontSize: 12, color: textColor),
      );
      textPainter.layout(maxWidth: labelWidth - 8);
      textPainter.paint(canvas, Offset(0, centerY - textPainter.height / 2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(track, const Radius.circular(999)),
        Paint()..color = color.withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(track.left, track.top, track.width * accuracy, 14),
          const Radius.circular(999),
        ),
        Paint()..color = color.withValues(alpha: 0.72),
      );
      textPainter.text = TextSpan(
        text: '${(accuracy * 100).round()}% · ${stat.correct}/${stat.total}',
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: valueWidth);
      textPainter.paint(
        canvas,
        Offset(
          size.width - textPainter.width,
          centerY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColorVisionAxisBarPainter oldDelegate) {
    return oldDelegate.stats != stats ||
        oldDelegate.colors != colors ||
        oldDelegate.textColor != textColor;
  }
}

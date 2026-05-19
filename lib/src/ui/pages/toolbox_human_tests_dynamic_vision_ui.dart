part of 'toolbox_human_tests.dart';

extension _DynamicVisionCardUi on _DynamicVisionCardState {
  Widget buildDynamicVisionBody(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildModeSwitcher(context, i18n),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInQuad,
          child: mode == _DynamicVisionMode.symbol
              ? _buildSymbolMode(context, i18n)
              : _buildBallCountMode(context, i18n),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher(BuildContext context, AppI18n i18n) {
    return SegmentedButton<_DynamicVisionMode>(
      segments: <ButtonSegment<_DynamicVisionMode>>[
        ButtonSegment<_DynamicVisionMode>(
          value: _DynamicVisionMode.symbol,
          icon: const Icon(Icons.text_fields_rounded),
          label: Text(
            pickUiText(
              i18n,
              zh: '字符识别',
              en: 'Moving symbol',
              ja: 'Moving symbol',
              de: 'Moving symbol',
              fr: 'Symbole de déplacement',
              es: 'símbolo de movimiento',
              ru: 'Движущийся символ',
            ),
          ),
        ),
        ButtonSegment<_DynamicVisionMode>(
          value: _DynamicVisionMode.ballCount,
          icon: const Icon(Icons.bubble_chart_rounded),
          label: Text(
            pickUiText(
              i18n,
              zh: '小球数量',
              en: 'Ball count',
              ja: 'ボールカウント',
              de: 'Ball count',
              fr: 'Nombre de balles',
              es: 'Conteo de bolas',
              ru: 'Количество мячей',
            ),
          ),
        ),
      ],
      selected: <_DynamicVisionMode>{mode},
      onSelectionChanged: (values) => unawaited(changeMode(values.first)),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll<TextStyle>(
          Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800) ??
              const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSymbolMode(BuildContext context, AppI18n i18n) {
    final nextDuration = symbolDurationForRound(
      (symbolRound + 1).clamp(1, symbolRoundCount),
    );
    return Column(
      key: const ValueKey<_DynamicVisionMode>(_DynamicVisionMode.symbol),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '轮次',
                en: 'Round',
                ja: 'Round',
                de: 'Round',
                fr: 'Cycle',
                es: 'Ronda',
                ru: 'Круглый',
              ),
              '$symbolRound/$symbolRoundCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '正确',
                en: 'Correct',
                ja: '正解',
                de: 'Correct',
                fr: 'Corrigé',
                es: 'Correcto.',
                ru: 'Правильно',
              ),
              '$symbolCorrect',
            ),
            (
              pickUiText(
                i18n,
                zh: '下轮速度',
                en: 'Next speed',
                ja: 'Next speed',
                de: 'Next speed',
                fr: 'Vitesse suivante',
                es: 'Siguiente velocidad',
                ru: 'Следующая скорость',
              ),
              formatSpeed(symbolEffectiveSpeed),
            ),
            (
              pickUiText(
                i18n,
                zh: '显示时间',
                en: 'Dwell',
                ja: 'Dwell',
                de: 'Dwell',
                fr: 'Bien',
                es: 'Dwell',
                ru: 'Ужин',
              ),
              _formatMilliseconds(nextDuration.inMilliseconds),
            ),
            (
              pickUiText(
                i18n,
                zh: '字符集',
                en: 'Set',
                ja: 'Set',
                de: 'Set',
                fr: 'Jeu',
                es: 'Set',
                ru: 'Настройка',
              ),
              symbolSetLabel(i18n, symbolSet),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: buildSymbolStage(context, i18n),
        ),
        const SizedBox(height: 12),
        if (symbolChoosing)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: symbolOptions
                .map(
                  (value) => SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => chooseSymbol(value),
                      child: Text(value),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        if (symbolDone) ...<Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '完成：$symbolCorrect / $symbolRoundCount',
              en: 'Done: $symbolCorrect / $symbolRoundCount',
              ja: 'Done: $symbolCorrect / $symbolRoundCount',
              de: 'Done: $symbolCorrect / $symbolRoundCount',
              fr: 'Fait: $symbolCorrect / $symbolRoundCount',
              es: 'Hecho:',
              ru: 'Выполнено: $symbolCorrect / $symbolRoundCount',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
        ],
        if (symbolFeedbackZh != null) ...<Widget>[
          Text(
            pickUiText(
              i18n,
              zh: symbolFeedbackZh!,
              en: symbolFeedbackEn!,
              ja: symbolFeedbackJa!,
              de: symbolFeedbackDe!,
              fr: symbolFeedbackFr!,
              es: symbolFeedbackEs!,
              ru: symbolFeedbackRu!,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: symbolLastCorrect == false
                  ? Theme.of(context).colorScheme.error
                  : accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: symbolChoosing ? null : resetSymbol,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '重置开始',
                  en: 'Reset start',
                  ja: 'Reset start',
                  de: 'Reset start',
                  fr: 'Réinitialiser le début',
                  es: 'Reset start',
                  ru: 'Начало сброса',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: symbolRecords.isEmpty
                  ? null
                  : () => unawaited(showSymbolReport()),
              icon: const Icon(Icons.analytics_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '查看报告',
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
        const SizedBox(height: 12),
        _buildSymbolSettings(context, i18n),
      ],
    );
  }

  Widget buildSymbolStage(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 0.58).clamp(220.0, 310.0);
        final size = Size(constraints.maxWidth, height);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: AnimatedBuilder(
            animation: symbolAnimation,
            builder: (context, child) {
              final value = Curves.linear.transform(symbolAnimation.value);
              final position = symbolPositionFor(value, size);
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  if (symbolShowing)
                    ...symbolDistractors.map((item) {
                      return Positioned(
                        left: (item.dx * size.width).clamp(
                          12.0,
                          size.width - 48,
                        ),
                        top: (item.dy * size.height).clamp(
                          12.0,
                          size.height - 48,
                        ),
                        child: Opacity(
                          opacity: 0.22,
                          child: Text(
                            item.value,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      );
                    }),
                  if (symbolShowing)
                    Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: Text(
                        symbolTarget,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    )
                  else
                    Center(
                      child: symbolDone
                          ? Text(
                              pickUiText(
                                i18n,
                                zh: '完成',
                                en: 'Done',
                                ja: 'Done',
                                de: 'Done',
                                fr: 'Fait',
                                es: 'Hecho',
                                ru: 'Сделано',
                              ),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            )
                          : _HumanActionButton(
                              label: pickUiText(
                                i18n,
                                zh: '开始',
                                en: 'Start',
                                ja: 'Start',
                                de: 'Start',
                                fr: 'Démarrer',
                                es: 'Comienzo',
                                ru: 'Начинать',
                              ),
                              icon: Icons.play_arrow_rounded,
                              onPressed: startSymbolRound,
                            ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSymbolSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: pickUiText(
        i18n,
        zh: '字符识别设置',
        en: 'Symbol settings',
        ja: 'Symbol settings',
        de: 'Symbol settings',
        fr: 'Paramètres des symboles',
        es: 'Ajustes de símbolo',
        ru: 'Настройки символов',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '调整字符集、轮次数、轨迹、速度、干扰和选项数量',
        en: 'Tune character set, rounds, path, speed, distractors, and option count',
        ja: 'Tune character set, rounds, path, speed, distractors, and option count',
        de: 'Tune character set, rounds, path, speed, distractors, and option count',
        fr: 'Jeu de caractères Tune, tours, chemin, vitesse, disjoncteurs et nombre d\'options',
        es: 'Tune conjunto de caracteres, rondas, camino, velocidad, distracciones y cuenta de opción',
        ru: 'Настройка персонажа, раунды, путь, скорость, отвлекающие факторы и количество опций',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '测试轮次数',
              en: 'Test rounds',
              ja: 'Test rounds',
              de: 'Test rounds',
              fr: 'Cycles d \' essai',
              es: 'Pruebas redondas',
              ru: 'Тестовые раунды',
            ),
            valueText: '$symbolRoundCount',
            value: symbolRoundCount.toDouble(),
            min: 5,
            max: 15,
            divisions: 10,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolRoundCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '选项数量',
              en: 'Option count',
              ja: 'Option count',
              de: 'Option count',
              fr: 'Nombre d\'options',
              es: 'Conteo de opciones',
              ru: 'Количество вариантов',
            ),
            valueText: '$symbolOptionCount',
            value: symbolOptionCount.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolOptionCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '字符组合长度',
              en: 'Symbol group length',
              ja: 'Symbol group length',
              de: 'Symbol group length',
              fr: 'Longueur du groupe symbole',
              es: 'Duración del grupo de símbolos',
              ru: 'Длина символьной группы',
            ),
            valueText: '$symbolGroupLength',
            value: symbolGroupLength.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolGroupLength(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '基础移动速度',
              en: 'Base movement speed',
              ja: '基本移動速度',
              de: 'Base movement speed',
              fr: 'Vitesse de déplacement de base',
              es: 'Velocidad de movimiento de base',
              ru: 'Скорость движения базы',
            ),
            valueText: formatSpeed(symbolBaseSpeed),
            value: symbolBaseSpeed,
            min: 0.7,
            max: 1.8,
            divisions: 11,
            onChanged: (value) =>
                unawaited(updateSymbolSetting(() => setSymbolBaseSpeed(value))),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '上下摆动幅度',
              en: 'Vertical path amplitude',
              ja: 'Vertical path amplitude',
              de: 'Vertical path amplitude',
              fr: 'amplitude de trajectoire verticale',
              es: 'Vía vertical amplitude',
              ru: 'Амплитуда вертикального пути',
            ),
            valueText: '${(symbolWaveAmplitude * 100).round()}%',
            value: symbolWaveAmplitude,
            min: 0.08,
            max: 0.28,
            divisions: 10,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolWaveAmplitude(value)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '字符集',
              en: 'Character set',
              ja: 'キャラクターセット',
              de: 'Character set',
              fr: 'Jeu de caractères',
              es: 'Conjunto de caracteres',
              ru: 'Набор персонажей',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _DynamicSymbolSet.values
                .map(
                  (set) => ChoiceChip(
                    label: Text(symbolSetLabel(i18n, set)),
                    selected: symbolSet == set,
                    onSelected: (_) =>
                        unawaited(updateSymbolSetting(() => setSymbolSet(set))),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '移动轨迹',
              en: 'Movement path',
              ja: 'Movement path',
              de: 'Movement path',
              fr: 'Voie de déplacement',
              es: 'Camino del movimiento',
              ru: 'Путь движения',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _DynamicSymbolPath.values
                .map(
                  (path) => ChoiceChip(
                    label: Text(symbolPathLabel(i18n, path)),
                    selected: symbolPath == path,
                    onSelected: (_) => unawaited(
                      updateSymbolSetting(() => setSymbolPath(path)),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: symbolDistractorEnabled,
            title: Text(
              pickUiText(
                i18n,
                zh: '显示弱干扰字符',
                en: 'Show faint distractors',
                ja: 'Show faint distractors',
                de: 'Show faint distractors',
                fr: 'Afficher les disjoncteurs faibles',
                es: 'Mostrar distracciones débiles',
                ru: 'Показать слабые отвлекающие факторы',
              ),
            ),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '干扰只影响识别压力，不参与答案。',
                en: 'Distractors add visual load but are never correct answers.',
                ja: 'Distractors add visual load but are never correct answers.',
                de: 'Distractors add visual load but are never correct answers.',
                fr: 'Les disjoncteurs ajoutent une charge visuelle mais ne sont jamais des réponses correctes.',
                es: 'Los Distractors agregan carga visual pero nunca son respuestas correctas.',
                ru: 'Отвлекатели добавляют визуальную нагрузку, но никогда не дают правильных ответов.',
              ),
            ),
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolDistractorEnabled(value)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: symbolCustomController,
            decoration: InputDecoration(
              labelText: pickUiText(
                i18n,
                zh: '自定义组合（逗号分割）',
                en: 'Custom groups (comma separated)',
                ja: 'Custom groups (comma separated)',
                de: 'Custom groups (comma separated)',
                fr: 'Groupes personnalisés (comma séparés)',
                es: 'Grupos aduaneros (comma separados)',
                ru: 'Обычные группы (комма разделена)',
              ),
              hintText: 'AB, 82, F9',
              border: const OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 2,
            onSubmitted: (value) => unawaited(
              updateSymbolSetting(() => setSymbolCustomSource(value.trim())),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              updateSymbolSetting(
                () => setSymbolCustomSource(symbolCustomController.text.trim()),
              ),
            ),
            icon: const Icon(Icons.done_rounded),
            label: Text(
              pickUiText(
                i18n,
                zh: '应用自定义组合',
                en: 'Apply custom groups',
                ja: 'カスタムグループ',
                de: 'Apply custom groups',
                fr: 'Appliquer des groupes personnalisés',
                es: 'Aplicar grupos personalizados',
                ru: 'Применять пользовательские группы',
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DynamicCurveSelector(
            label: pickUiText(
              i18n,
              zh: '增长曲线',
              en: 'Growth curve',
              ja: 'Growth curve',
              de: 'Growth curve',
              fr: 'Courbe de croissance',
              es: 'Curva de crecimiento',
              ru: 'Кривая роста',
            ),
            value: symbolCurve,
            enabled: true,
            labelFor: (curve) => curveLabel(i18n, curve),
            onChanged: (curve) =>
                unawaited(updateSymbolSetting(() => setSymbolCurve(curve))),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              updateSymbolSetting(() {
                setSymbolRoundCount(10);
                setSymbolGroupLength(1);
                setSymbolOptionCount(4);
                setSymbolCustomSource('');
                symbolCustomController.text = '';
                setSymbolBaseSpeed(1.0);
                setSymbolWaveAmplitude(0.18);
                setSymbolCurve(_DynamicVisionGrowthCurve.linear);
                setSymbolSet(_DynamicSymbolSet.mixed);
                setSymbolPath(_DynamicSymbolPath.wave);
                setSymbolDistractorEnabled(false);
              }),
            ),
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: Text(
              pickUiText(
                i18n,
                zh: '恢复默认',
                en: 'Reset defaults',
                ja: 'Reset defaults',
                de: 'Reset defaults',
                fr: 'Réinitialiser les valeurs par défaut',
                es: 'Reset defaults',
                ru: 'Сброс дефолтов',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBallCountMode(BuildContext context, AppI18n i18n) {
    return Column(
      key: const ValueKey<_DynamicVisionMode>(_DynamicVisionMode.ballCount),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '等级',
                en: 'Level',
                ja: 'Level',
                de: 'Level',
                fr: 'Niveau',
                es: 'Nivel',
                ru: 'Уровень',
              ),
              '$ballLevel',
            ),
            (
              pickUiText(
                i18n,
                zh: '数量范围',
                en: 'Count range',
                ja: 'カウント範囲',
                de: 'Count range',
                fr: 'Gamme de comptage',
                es: 'Rango de cuenta',
                ru: 'Диапазон значений',
              ),
              ballCountRangeLabel,
            ),
            (
              pickUiText(
                i18n,
                zh: '速度范围',
                en: 'Speed range',
                ja: 'Speed range',
                de: 'Speed range',
                fr: 'Plage de vitesse',
                es: 'Rango de velocidad',
                ru: 'Скорость',
              ),
              ballSpeedRangeLabel,
            ),
            (
              pickUiText(
                i18n,
                zh: '失误',
                en: 'Misses',
                ja: 'Misses',
                de: 'Misses',
                fr: 'Mlle',
                es: 'Misses',
                ru: 'Мисс.',
              ),
              '$ballMisses/3',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: buildBallStage(context, i18n),
        ),
        const SizedBox(height: 12),
        if (ballAnswering)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ballOptions
                .map(
                  (value) => SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => chooseBallCount(value),
                      child: Text('$value'),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        if (ballFeedbackZh != null) ...<Widget>[
          _DynamicFeedbackStrip(
            accent: ballLastCorrect == true
                ? const Color(0xFF3F9A6B)
                : Theme.of(context).colorScheme.error,
            icon: ballLastCorrect == true
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            text: pickUiText(
              i18n,
              zh: ballFeedbackZh!,
              en: ballFeedbackEn!,
              ja: ballFeedbackJa!,
              de: ballFeedbackDe!,
              fr: ballFeedbackFr!,
              es: ballFeedbackEs!,
              ru: ballFeedbackRu!,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (!ballShowing && !ballAnswering)
              _HumanActionButton(
                label: ballDone
                    ? pickUiText(
                        i18n,
                        zh: '重新开始',
                        en: 'Start over',
                        ja: 'Start over',
                        de: 'Start over',
                        fr: 'Recommencer',
                        es: 'Empieza de nuevo',
                        ru: 'Начинай сначала.',
                      )
                    : ballFeedbackZh == null
                    ? pickUiText(
                        i18n,
                        zh: '开始',
                        en: 'Start',
                        ja: 'Start',
                        de: 'Start',
                        fr: 'Démarrer',
                        es: 'Comienzo',
                        ru: 'Начинать',
                      )
                    : pickUiText(
                        i18n,
                        zh: '下一轮',
                        en: 'Next round',
                        ja: 'Next round',
                        de: 'Next round',
                        fr: 'Prochain tour',
                        es: 'Siguiente ronda',
                        ru: 'Следующий раунд',
                      ),
                icon: ballDone
                    ? Icons.restart_alt_rounded
                    : Icons.play_arrow_rounded,
                onPressed: ballDone ? resetBalls : startBallRound,
              ),
            OutlinedButton.icon(
              onPressed: ballShowing || ballAnswering ? null : resetBalls,
              icon: const Icon(Icons.restart_alt_rounded),
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
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '正确轮数',
                en: 'Correct rounds',
                ja: '正解ラウンド',
                de: 'Correct rounds',
                fr: 'Coups corrects',
                es: 'Correcciones correctas',
                ru: 'Правильные раунды',
              ),
              '$ballCorrect',
            ),
            (
              pickUiText(
                i18n,
                zh: '最佳等级',
                en: 'Best level',
                ja: 'ベストレベル',
                de: 'Best level',
                fr: 'Meilleur niveau',
                es: 'Mejor nivel',
                ru: 'Лучший уровень',
              ),
              '$ballBestLevel',
            ),
            (
              pickUiText(
                i18n,
                zh: '观察时长',
                en: 'Observe time',
                ja: 'Observe time',
                de: 'Observe time',
                fr: 'Observer le temps',
                es: 'Observe el tiempo',
                ru: 'Наблюдать время',
              ),
              _formatSeconds(ballObservationMs / 1000),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBallSettings(context, i18n),
      ],
    );
  }

  Widget buildBallStage(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 0.64).clamp(230.0, 330.0);
        final size = Size(constraints.maxWidth, height);
        setLastBallStageSize(size);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _DynamicVisionBallPainter(
                    balls: visibleBalls,
                    accent: accent,
                    surface: Theme.of(context).colorScheme.surface,
                    outline: Theme.of(context).colorScheme.outlineVariant,
                    repaint: ballAnimation,
                  ),
                ),
              ),
              if (!ballShowing)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      ballAnswering
                          ? pickUiText(
                              i18n,
                              zh: '刚才有多少个小球？',
                              en: 'How many balls did you see?',
                              ja: 'How many balls did you see?',
                              de: 'How many balls did you see?',
                              fr: 'Combien de couilles avez-vous vues ?',
                              es: '¿Cuántas bolas viste?',
                              ru: 'Сколько шаров ты видел?',
                            )
                          : ballDone
                          ? pickUiText(
                              i18n,
                              zh: '测试结束',
                              en: 'Test over',
                              ja: 'Test over',
                              de: 'Test over',
                              fr: 'Essai terminé',
                              es: 'Pruebas sobre',
                              ru: 'Проверка',
                            )
                          : pickUiText(
                              i18n,
                              zh: '开始后快速数出移动小球数量',
                              en: 'Start and count the moving balls quickly',
                              ja: 'Start and count the moving balls quickly',
                              de: 'Start and count the moving balls quickly',
                              fr: 'Commencez et comptez les boules mobiles rapidement',
                              es: 'Comienza y cuenta las bolas móviles rápidamente',
                              ru: 'Начните и считайте быстро движущиеся шары.',
                            ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (ballShowing)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _HumanPill(
                    text: pickUiText(
                      i18n,
                      zh: '观察中',
                      en: 'Watching',
                      ja: 'Watching',
                      de: 'Watching',
                      fr: 'Regarder',
                      es: 'Mirando',
                      ru: 'смотреть',
                    ),
                    accent: accent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBallSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: pickUiText(
        i18n,
        zh: '小球数量设置',
        en: 'Ball count settings',
        ja: 'ボールカウント設定',
        de: 'Ball count settings',
        fr: 'Paramètres de comptage des balles',
        es: 'Ajustes del conteo de bolas',
        ru: 'Параметры счета мяча',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '调整起始数量、上限、速度、观察时长与增长曲线',
        en: 'Tune starting count, cap, speed, observe time, and growth curve',
        ja: 'Tune starting count, cap, speed, observe time, and growth curve',
        de: 'Tune starting count, cap, speed, observe time, and growth curve',
        fr: 'Compte de départ, cap, vitesse, temps d\'observation et courbe de croissance',
        es: 'Tune cuenta de inicio, tapa, velocidad, observar tiempo y curva de crecimiento',
        ru: 'Тюнинг стартовый счет, кэп, скорость, наблюдать время и кривая роста',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '起始小球数量',
              en: 'Starting balls',
              ja: 'Starting balls',
              de: 'Starting balls',
              fr: 'Balles de départ',
              es: 'Comenzando bolas',
              ru: 'Начинающие шары',
            ),
            valueText: '$ballStartCount',
            value: ballStartCount.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (value) => unawaited(
              updateBallSetting(() => setBallStartCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '最大小球数量',
              en: 'Maximum balls',
              ja: 'Maximum balls',
              de: 'Maximum balls',
              fr: 'Balles maximales',
              es: 'Bolas máximas',
              ru: 'Максимальные шары',
            ),
            valueText: '$ballMaxCount',
            value: ballMaxCount.toDouble(),
            min: 6,
            max: 18,
            divisions: 12,
            onChanged: (value) => unawaited(
              updateBallSetting(() => setBallMaxCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '基础移动速度',
              en: 'Base movement speed',
              ja: '基本移動速度',
              de: 'Base movement speed',
              fr: 'Vitesse de déplacement de base',
              es: 'Velocidad de movimiento de base',
              ru: 'Скорость движения базы',
            ),
            valueText: formatSpeed(ballBaseSpeed),
            value: ballBaseSpeed,
            min: 0.6,
            max: 1.8,
            divisions: 12,
            onChanged: (value) =>
                unawaited(updateBallSetting(() => setBallBaseSpeed(value))),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '观察时长',
              en: 'Observe time',
              ja: 'Observe time',
              de: 'Observe time',
              fr: 'Observer le temps',
              es: 'Observe el tiempo',
              ru: 'Наблюдать время',
            ),
            valueText: _formatSeconds(ballObservationMs / 1000),
            value: ballObservationMs.toDouble(),
            min: 800,
            max: 12000,
            divisions: 56,
            onChanged: (value) => unawaited(
              updateBallSetting(() => setBallObservationMs(value.round())),
            ),
          ),
          TextField(
            controller: ballObservationController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: pickUiText(
                i18n,
                zh: '观察时长输入（秒）',
                en: 'Observe time input (seconds)',
                ja: 'Observe time input (seconds)',
                de: 'Observe time input (seconds)',
                fr: 'Observer l\'entrée de temps (secondes)',
                es: 'Observe el tiempo de entrada (segundos)',
                ru: 'Время ввода (секунды)',
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final milliseconds = parseObservationMilliseconds(value);
              if (milliseconds == null) {
                ballObservationController.text = formatObservationInput(
                  ballObservationMs,
                );
                return;
              }
              unawaited(
                updateBallSetting(() => setBallObservationMs(milliseconds)),
              );
            },
          ),
          const SizedBox(height: 8),
          _DynamicEnumChoice<_DynamicBallColorMode>(
            label: pickUiText(
              i18n,
              zh: '小球颜色',
              en: 'Ball color',
              ja: 'ボールカラー',
              de: 'Ball color',
              fr: 'Couleur de la bille',
              es: 'Color de bola',
              ru: 'Цвет шара',
            ),
            value: ballColorMode,
            values: _DynamicBallColorMode.values,
            labelFor: (mode) => switch (mode) {
              _DynamicBallColorMode.uniform => pickUiText(
                i18n,
                zh: '同色',
                en: 'Uniform',
                ja: 'Uniform',
                de: 'Uniform',
                fr: 'Uniforme',
                es: 'Uniforme',
                ru: 'униформа',
              ),
              _DynamicBallColorMode.varied => pickUiText(
                i18n,
                zh: '多色',
                en: 'Varied',
                ja: 'Varied',
                de: 'Varied',
                fr: 'Varié',
                es: 'Variado',
                ru: 'разнообразный',
              ),
            },
            onChanged: (mode) =>
                unawaited(updateBallSetting(() => setBallColorMode(mode))),
          ),
          const SizedBox(height: 8),
          _DynamicCurveSelector(
            label: pickUiText(
              i18n,
              zh: '增长曲线',
              en: 'Growth curve',
              ja: 'Growth curve',
              de: 'Growth curve',
              fr: 'Courbe de croissance',
              es: 'Curva de crecimiento',
              ru: 'Кривая роста',
            ),
            value: ballCurve,
            enabled: true,
            labelFor: (curve) => curveLabel(i18n, curve),
            onChanged: (curve) =>
                unawaited(updateBallSetting(() => setBallCurve(curve))),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              updateBallSetting(() {
                setBallStartCount(3);
                setBallMaxCount(12);
                setBallBaseSpeed(1.0);
                setBallObservationMs(2200);
                setBallColorMode(_DynamicBallColorMode.uniform);
                setBallCurve(_DynamicVisionGrowthCurve.linear);
              }),
            ),
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: Text(
              pickUiText(
                i18n,
                zh: '恢复默认',
                en: 'Reset defaults',
                ja: 'Reset defaults',
                de: 'Reset defaults',
                fr: 'Réinitialiser les valeurs par défaut',
                es: 'Reset defaults',
                ru: 'Сброс дефолтов',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

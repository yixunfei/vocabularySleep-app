part of 'focus_page.dart';

extension _FocusPageTimerExtension on _FocusPageState {
  Widget _buildTimerTab(AppState state, FocusService focus, AppI18n i18n) {
    final timerState = focus.state;
    final config = focus.config;
    final appearance = state.config.appearance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthTier = AppWidthBreakpoints.tierFor(constraints.maxWidth);
        final availableWidth = math.max(0.0, constraints.maxWidth - 32);
        final contentWidth = math.min(
          availableWidth,
          _pageContentMaxWidth(widthTier),
        );
        return Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    children: <Widget>[
                      _buildTimerDisplay(
                        timerState,
                        config,
                        i18n,
                        widthTier,
                        appearance.normalizedTimerStyle,
                      ),
                      const SizedBox(height: 20),
                      _buildTimerControls(focus, timerState, i18n),
                      const SizedBox(height: 20),
                      _buildTimerConfig(
                        focus,
                        config,
                        i18n,
                        contentWidth,
                        widthTier,
                      ),
                      const SizedBox(height: 20),
                      _buildTodayStats(focus, i18n, contentWidth, widthTier),
                    ],
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: true,
              child: _buildAmbientLauncher(
                state,
                i18n,
                widthTier,
                constraints.maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }

  void _syncConfiguredStartupTab(FocusStartupTab tab) {
    _pageController.syncConfiguredStartupTab(tab, _tabController);
  }

  Widget _buildAmbientLauncher(
    AppState state,
    AppI18n i18n,
    AppWidthTier widthTier,
    double maxWidth,
  ) {
    final theme = Theme.of(context);
    final enabledSources = state.ambientSources
        .where((source) => source.enabled)
        .toList(growable: false);
    final activeCount = enabledSources.length;
    final panelWidth = math.min(
      maxWidth - 32,
      widthTier.isCompact ? 280.0 : 320.0,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _ambientLauncherExpanded
          ? SizedBox(
              key: const ValueKey<String>('ambient-launcher-panel'),
              width: panelWidth,
              child: Stack(
                children: <Widget>[
                  _buildAmbientSummaryCard(state, i18n, widthTier),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filledTonal(
                      key: const ValueKey<String>('ambient-launcher-close'),
                      tooltip: i18n.t('close'),
                      onPressed: () {
                        _setViewState(() {
                          _ambientLauncherExpanded = false;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            )
          : Material(
              key: const ValueKey<String>('ambient-launcher-toggle'),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  _setViewState(() {
                    _ambientLauncherExpanded = true;
                  });
                },
                child: Ink(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.94,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      Icon(
                        activeCount > 0
                            ? Icons.surround_sound_rounded
                            : Icons.music_note_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$activeCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAmbientSummaryCard(
    AppState state,
    AppI18n i18n,
    AppWidthTier widthTier,
  ) {
    final theme = Theme.of(context);
    final enabledSources = state.ambientSources
        .where((source) => source.enabled)
        .toList(growable: false);
    final previewCount = widthTier.isCompact ? 2 : 3;
    final shownNames = enabledSources
        .take(previewCount)
        .map((source) => localizedAmbientName(i18n, source))
        .toList(growable: false);
    final remainingCount = enabledSources.length - shownNames.length;
    final headline = enabledSources.isEmpty
        ? pickUiText(
            i18n,
            zh: '背景音未开启',
            en: 'Background audio is off',
            ja: '環境音はオフです',
            de: 'Hintergrundaudio ist aus',
            fr: 'L’audio d’ambiance est coupe',
            es: 'El audio ambiental esta apagado',
            ru: 'Фоновый звук выключен',
          )
        : pickUiText(
            i18n,
            zh: '已启用 ${enabledSources.length} 条背景音',
            en: '${enabledSources.length} ambient tracks enabled',
            ja: '${enabledSources.length} 個の環境音を有効化中',
            de: '${enabledSources.length} Hintergrundspuren aktiv',
            fr: '${enabledSources.length} pistes d’ambiance actives',
            es: '${enabledSources.length} pistas ambientales activas',
            ru: 'Активно ${enabledSources.length} фоновых дорожек',
          );
    final details = enabledSources.isEmpty
        ? pickUiText(
            i18n,
            zh: '进入背景音面板后可以快速切换雨声、白噪音、图书馆等专注声景。',
            en: 'Open the audio panel to quickly switch between rain, noise, library, and other focus scenes.',
            ja: 'パネルを開くと、雨音、ノイズ、図書館などの集中サウンドをすばやく切り替えられます。',
            de: 'Im Audiobereich koennen Regen, Rauschen, Bibliothek und weitere Fokus-Szenen schnell umgeschaltet werden.',
            fr: 'Ouvrez le panneau audio pour basculer rapidement entre pluie, bruit, bibliotheque et autres ambiances.',
            es: 'Abre el panel para cambiar rapidamente entre lluvia, ruido, biblioteca y otras escenas de enfoque.',
            ru: 'Откройте панель аудио, чтобы быстро переключаться между дождём, шумом, библиотекой и другими звуковыми сценами.',
          )
        : '${shownNames.join(' · ')}${remainingCount > 0 ? ' +$remainingCount' : ''}';
    final progressColor = enabledSources.isEmpty
        ? theme.colorScheme.outlineVariant
        : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primaryContainer.withValues(alpha: 0.92),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.74),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  enabledSources.isEmpty
                      ? Icons.music_off_rounded
                      : Icons.surround_sound_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('ambientAudio'),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(headline, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(details, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(
                avatar: const Icon(Icons.graphic_eq_rounded, size: 18),
                label: Text(
                  '${i18n.t('masterVolume')} ${(state.ambientMasterVolume * 100).round()}%',
                ),
              ),
              Chip(
                avatar: const Icon(Icons.queue_music_rounded, size: 18),
                label: Text(
                  enabledSources.isEmpty
                      ? pickUiText(
                          i18n,
                          zh: '未启用音轨',
                          en: 'No active tracks',
                          ja: '有効な音源なし',
                          de: 'Keine aktiven Spuren',
                          fr: 'Aucune piste active',
                          es: 'Sin pistas activas',
                          ru: 'Нет активных дорожек',
                        )
                      : pickUiText(
                          i18n,
                          zh: '${enabledSources.length} 条音轨',
                          en: '${enabledSources.length} tracks',
                          ja: '${enabledSources.length} トラック',
                          de: '${enabledSources.length} Spuren',
                          fr: '${enabledSources.length} pistes',
                          es: '${enabledSources.length} pistas',
                          ru: '${enabledSources.length} дорожек',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: state.ambientMasterVolume.clamp(0.0, 1.0),
              color: progressColor,
              backgroundColor: theme.colorScheme.surface.withValues(
                alpha: 0.48,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAmbientAudioSheet(context),
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '打开背景音设置',
                  en: 'Open background audio settings',
                  ja: '環境音設定を開く',
                  de: 'Hintergrundaudio-Einstellungen oeffnen',
                  fr: 'Ouvrir les reglages audio',
                  es: 'Abrir ajustes de audio ambiental',
                  ru: 'Открыть настройки фонового звука',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(
    TomatoTimerState timerState,
    TomatoTimerConfig config,
    AppI18n i18n,
    AppWidthTier widthTier,
    String timerStyle,
  ) => FocusTimerDisplayCard(
    timerState: timerState,
    config: config,
    i18n: i18n,
    widthTier: widthTier,
    timerStyle: timerStyle,
    lastCompletedPhase: _pageController.lastCompletedPhase,
  );

  Widget _buildTimerControls(
    FocusService focus,
    TomatoTimerState timerState,
    AppI18n i18n,
  ) => FocusTimerControlsCard(
    focus: focus,
    timerState: timerState,
    i18n: i18n,
    onConfirmStop: () => _confirmStop(focus, i18n),
  );

  Widget _buildTimerConfig(
    FocusService focus,
    TomatoTimerConfig config,
    AppI18n i18n,
    double maxWidth,
    AppWidthTier widthTier,
  ) {
    final contentWidth = (maxWidth - 32).clamp(0.0, maxWidth).toDouble();
    final itemWidth = _responsiveItemWidth(contentWidth, widthTier, columns: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t('timerConfig'),
              subtitle: pickUiText(
                i18n,
                zh: '专注时长、休息节奏与提醒方式会在这里统一调整。',
                en: 'Tune session length, break cadence, and reminders in one place.',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: itemWidth,
                  child: _buildDurationCard(
                    label: i18n.t('focusMinutes'),
                    totalSeconds: config.focusDurationSeconds,
                    i18n: i18n,
                    onChanged: (seconds) => focus.saveConfig(
                      config.copyWith(focusDurationSeconds: seconds),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildDurationCard(
                    label: i18n.t('breakMinutes'),
                    totalSeconds: config.breakDurationSeconds,
                    i18n: i18n,
                    onChanged: (seconds) => focus.saveConfig(
                      config.copyWith(breakDurationSeconds: seconds),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildConfigField(
                    label: i18n.t('rounds'),
                    value: config.rounds,
                    min: 1,
                    max: 12,
                    onChanged: (value) =>
                        focus.saveConfig(config.copyWith(rounds: value)),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildReminderCard(focus, config, i18n),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildConfigToggle(
                    label: i18n.t('autoStartBreak'),
                    value: config.autoStartBreak,
                    onChanged: (value) => focus.saveConfig(
                      config.copyWith(autoStartBreak: value),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildConfigToggle(
                    label: i18n.t('autoStartNextRound'),
                    value: config.autoStartNextRound,
                    onChanged: (value) => focus.saveConfig(
                      config.copyWith(autoStartNextRound: value),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard({
    required String label,
    required int totalSeconds,
    required AppI18n i18n,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              _formatUnitSummary(totalSeconds, i18n),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _showDurationPicker(
                  title: label,
                  totalSeconds: totalSeconds,
                  i18n: i18n,
                  onChanged: onChanged,
                ),
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '滚轮精调',
                    en: 'Wheel picker',
                    ja: 'ホイールで調整',
                    de: 'Mit Rad anpassen',
                    fr: 'Ajuster avec la molette',
                    es: 'Ajustar con rueda',
                    ru: 'Настроить колесом',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    FocusService focus,
    TomatoTimerConfig config,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);
    final reminder = config.reminder;

    Widget buildSwitch({
      required String label,
      required bool value,
      required TimerReminderConfig Function(bool next) map,
    }) {
      return SwitchListTile.adaptive(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: theme.textTheme.bodyMedium),
        value: value,
        onChanged: (next) => focus.saveReminderConfig(map(next)),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(i18n.t('reminderSettings'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            buildSwitch(
              label: i18n.t('reminderHaptic'),
              value: reminder.haptic,
              map: (next) => reminder.copyWith(haptic: next),
            ),
            buildSwitch(
              label: i18n.t('reminderSound'),
              value: reminder.sound,
              map: (next) => reminder.copyWith(sound: next),
            ),
            buildSwitch(
              label: i18n.t('reminderVoice'),
              value: reminder.voice,
              map: (next) => reminder.copyWith(voice: next),
            ),
            buildSwitch(
              label: i18n.t('reminderPauseAmbient'),
              value: reminder.pauseAmbient,
              map: (next) => reminder.copyWith(pauseAmbient: next),
            ),
            buildSwitch(
              label: i18n.t('reminderVisual'),
              value: reminder.visual,
              map: (next) => reminder.copyWith(visual: next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigField({
    required String label,
    required int value,
    int min = 1,
    int max = 60,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(label),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTodayStats(
    FocusService focus,
    AppI18n i18n,
    double maxWidth,
    AppWidthTier widthTier,
  ) {
    final contentWidth = (maxWidth - 32).clamp(0.0, maxWidth).toDouble();
    final itemWidth = _responsiveItemWidth(contentWidth, widthTier, columns: 3);
    final items = <_StatItem>[
      _StatItem(
        icon: Icons.timer_outlined,
        value: '${focus.getTodayFocusMinutes()}',
        label: i18n.t('focusMinutesLabel'),
      ),
      _StatItem(
        icon: Icons.schedule_rounded,
        value: '${focus.getTodaySessionMinutes()}',
        label: i18n.t('sessionMinutesLabel'),
      ),
      _StatItem(
        icon: Icons.refresh_rounded,
        value: '${focus.getTodayRoundsCompleted()}',
        label: i18n.t('roundsLabel'),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t('todayStats'),
              subtitle: pickUiText(
                i18n,
                zh: '今天的专注投入会按相同宽度的统计卡展示。',
                en: 'Today’s focus progress is summarized in equal-width cards.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      height: 122,
                      child: _buildStatCard(item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Icon(item.icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(item.value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

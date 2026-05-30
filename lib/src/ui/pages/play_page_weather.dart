part of 'play_page.dart';

extension _PlayPageWeather on _PlayPageState {
  Widget _buildHeaderAction(
    BuildContext context,
    AppI18n i18n,
    AppState state, {
    required bool isPlaybackPaused,
  }) {
    final statusBadge = StatusBadge(
      label: isPlaybackPaused
          ? i18n.t('inline.ui.pages.play_page_weather.paused_e99815')
          : state.isPlaying
          ? i18n.t('toolbox.sound.focus.stagePulseMoving')
          : i18n.t('timerIdle'),
      icon: isPlaybackPaused
          ? Icons.pause_circle_filled_rounded
          : state.isPlaying
          ? Icons.graphic_eq_rounded
          : Icons.play_circle_outline_rounded,
    );
    if (!state.weatherEnabled) {
      return statusBadge;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[_buildWeatherBadge(context, i18n, state), statusBadge],
    );
  }

  Widget _buildWeatherBadge(
    BuildContext context,
    AppI18n i18n,
    AppState state,
  ) {
    final snapshot = state.weatherSnapshot;
    final theme = Theme.of(context);
    final icon = snapshot == null
        ? Icons.cloud_sync_rounded
        : weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay);
    final tooltip = snapshot == null
        ? i18n.t(
            state.weatherLoading
                ? 'play.weather.refreshingTooltip'
                : 'play.weather.openDetailsTooltip',
          )
        : '${snapshot.city} · ${snapshot.temperatureCelsius.round()}°C · ${weatherCodeLabel(i18n, snapshot.weatherCode, isDay: snapshot.isDay)}';
    final temperatureLabel = snapshot == null
        ? '--'
        : '${snapshot.temperatureCelsius.round()}°';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey<String>('play-weather-badge'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showWeatherDetails(context, i18n),
          child: Ink(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.88),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(icon, size: 24, color: theme.colorScheme.primary),
                Positioned(
                  bottom: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      child: Text(
                        temperatureLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.weatherLoading)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: theme.colorScheme.primary,
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

  Future<void> _showWeatherDetails(BuildContext context, AppI18n i18n) async {
    final state = ref.read(appStateProvider);
    if (!state.weatherLoading && state.weatherSnapshot == null) {
      unawaited(state.refreshWeather(force: true));
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (sheetContext, ref, _) {
            final state = ref.watch(appStateProvider);
            final snapshot = state.weatherSnapshot;
            final theme = Theme.of(sheetContext);
            final todayHigh = snapshot?.todayMaxTemperatureCelsius;
            final todayLow = snapshot?.todayMinTemperatureCelsius;
            final forecastDays =
                snapshot?.forecastDays ?? const <WeatherForecastDay>[];
            final upcomingDays = forecastDays.length <= 1
                ? const <WeatherForecastDay>[]
                : forecastDays.skip(1).toList(growable: false);
            final currentCondition = snapshot == null
                ? i18n.t(
                    'inline.ui.pages.play_page_weather.loading_weather_cac6b1',
                  )
                : weatherCodeLabel(
                    i18n,
                    snapshot.weatherCode,
                    isDay: snapshot.isDay,
                  );
            final currentIcon = snapshot == null
                ? Icons.cloud_sync_rounded
                : weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          currentIcon,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              snapshot == null
                                  ? i18n.t(
                                      'inline.ui.pages.play_page_weather.local_weather_895d0a',
                                    )
                                  : '${snapshot.city}, ${snapshot.countryCode}',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentCondition,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: i18n.t(
                          'inline.plan295.life.refresh.bea0dc8c1c92',
                        ),
                        onPressed: state.weatherLoading
                            ? null
                            : () => state.refreshWeather(force: true),
                        icon: state.weatherLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  if (state.weatherLoading) ...<Widget>[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 18),
                  if (snapshot == null)
                    Text(
                      i18n.t(
                        'inline.ui.pages.play_page_weather.fetching_local_weather_refresh_in_a_moment_for_more_deta_cf7362',
                      ),
                      style: theme.textTheme.bodyMedium,
                    )
                  else ...<Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${snapshot.temperatureCelsius.round()}°C',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  i18n.t(
                                    'inline.ui.pages.play_page_weather.feels_like_snapshot_apparenttemperaturecelsius_round_c_2ffa66',
                                    params: <String, Object?>{
                                      'snapshotApparentTemperatureCelsius':
                                          snapshot.apparentTemperatureCelsius
                                              .round(),
                                    },
                                  ),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (todayHigh != null && todayLow != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  i18n.t(
                                    'inline.ui.pages.play_page_weather.today_h_l_dec6e7',
                                  ),
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${todayHigh.round()}° / ${todayLow.round()}°',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _buildWeatherMetricChip(
                          context: sheetContext,
                          label: i18n.t('ambientNameNatureWind'),
                          value: '${snapshot.windSpeedKph.round()} km/h',
                        ),
                        _buildWeatherMetricChip(
                          context: sheetContext,
                          label: i18n.t(
                            'inline.ui.pages.play_page_weather.condition_4faac4',
                          ),
                          value: currentCondition,
                        ),
                        if (todayHigh != null && todayLow != null)
                          _buildWeatherMetricChip(
                            context: sheetContext,
                            label: i18n.t(
                              'inline.ui.pages.play_page_weather.high_low_6eaab2',
                            ),
                            value:
                                '${todayHigh.round()}° / ${todayLow.round()}°',
                          ),
                      ],
                    ),
                    if (upcomingDays.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Text(
                        i18n.t(
                          'inline.ui.pages.play_page_weather.upcoming_forecast_ed9efb',
                        ),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      for (final day in upcomingDays.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildWeatherForecastRow(
                            context: sheetContext,
                            i18n: i18n,
                            day: day,
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherMetricChip({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildWeatherForecastRow({
    required BuildContext context,
    required AppI18n i18n,
    required WeatherForecastDay day,
  }) {
    final theme = Theme.of(context);
    final label = _weatherDayLabel(context, i18n, day.date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            weatherCodeIcon(day.weatherCode, isDay: true),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  weatherCodeLabel(i18n, day.weatherCode, isDay: true),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${day.maxTemperatureCelsius.round()}° / ${day.minTemperatureCelsius.round()}°',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  String _weatherDayLabel(BuildContext context, AppI18n i18n, DateTime date) {
    final today = DateTime.now();
    if (DateUtils.isSameDay(date, today)) {
      return i18n.t('inline.ui.app_shell.today_23dc4e');
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (DateUtils.isSameDay(date, tomorrow)) {
      return i18n.t('inline.ui.app_shell.tomorrow_08dc97');
    }
    return MaterialLocalizations.of(context).formatShortDate(date);
  }
}

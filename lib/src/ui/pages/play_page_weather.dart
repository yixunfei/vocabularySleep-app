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
          ? pickUiText(i18n, zh: '已暂停', en: 'Paused')
          : state.isPlaying
          ? pickUiText(i18n, zh: '播放中', en: 'Playing')
          : pickUiText(i18n, zh: '待播放', en: 'Ready'),
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
        ? pickUiText(
            i18n,
            zh: state.weatherLoading ? '正在更新天气' : '点击查看天气详情',
            en: state.weatherLoading
                ? 'Refreshing weather'
                : 'Open weather details',
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
                ? pickUiText(i18n, zh: '天气获取中', en: 'Loading weather')
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
                                  ? pickUiText(
                                      i18n,
                                      zh: '当前城市天气',
                                      en: 'Local weather',
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
                        tooltip: pickUiText(i18n, zh: '刷新天气', en: 'Refresh'),
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
                      pickUiText(
                        i18n,
                        zh: '正在获取当前位置天气，稍后可下拉刷新查看更完整信息。',
                        en: 'Fetching local weather. Refresh in a moment for more details.',
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
                                  pickUiText(
                                    i18n,
                                    zh: '体感 ${snapshot.apparentTemperatureCelsius.round()}°C',
                                    en: 'Feels like ${snapshot.apparentTemperatureCelsius.round()}°C',
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
                                  pickUiText(
                                    i18n,
                                    zh: '今日高/低',
                                    en: 'Today H/L',
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
                          label: pickUiText(i18n, zh: '风速', en: 'Wind'),
                          value: '${snapshot.windSpeedKph.round()} km/h',
                        ),
                        _buildWeatherMetricChip(
                          context: sheetContext,
                          label: pickUiText(i18n, zh: '天气', en: 'Condition'),
                          value: currentCondition,
                        ),
                        if (todayHigh != null && todayLow != null)
                          _buildWeatherMetricChip(
                            context: sheetContext,
                            label: pickUiText(
                              i18n,
                              zh: '最高/最低',
                              en: 'High / Low',
                            ),
                            value:
                                '${todayHigh.round()}° / ${todayLow.round()}°',
                          ),
                      ],
                    ),
                    if (upcomingDays.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Text(
                        pickUiText(i18n, zh: '未来天气', en: 'Upcoming forecast'),
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
      return pickUiText(i18n, zh: '今天', en: 'Today');
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (DateUtils.isSameDay(date, tomorrow)) {
      return pickUiText(i18n, zh: '明天', en: 'Tomorrow');
    }
    return MaterialLocalizations.of(context).formatShortDate(date);
  }
}

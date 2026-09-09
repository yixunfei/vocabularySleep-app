import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../../models/sleep_support_session.dart';

/// Immediate support without waiting for stored profile data.
class SleepNightHome extends StatelessWidget {
  const SleepNightHome({
    super.key,
    required this.i18n,
    required this.onIntent,
    required this.onDaytime,
  });

  final AppI18n i18n;
  final ValueChanged<SleepSupportIntent> onIntent;
  final VoidCallback onDaytime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n.t('toolbox.sleep.night.home.title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t('toolbox.sleep.night.home.body'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        _intentTile(
          context,
          intent: SleepSupportIntent.prepareForSleep,
          icon: Icons.bedtime_outlined,
          name: 'prepare',
          titleKey: 'toolbox.sleep.night.intent.prepare',
        ),
        const SizedBox(height: 12),
        _intentTile(
          context,
          intent: SleepSupportIntent.nightWaking,
          icon: Icons.nights_stay_outlined,
          name: 'awake',
          titleKey: 'toolbox.sleep.night.intent.awake',
        ),
        const SizedBox(height: 12),
        _intentTile(
          context,
          intent: SleepSupportIntent.distressed,
          icon: Icons.spa_outlined,
          name: 'distressed',
          titleKey: 'toolbox.sleep.night.intent.distressed',
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const ValueKey('sleep-daytime-entry'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.all(14),
          ),
          onPressed: onDaytime,
          icon: const Icon(Icons.wb_sunny_outlined),
          label: Text(i18n.t('toolbox.sleep.night.home.daytime')),
        ),
        const SizedBox(height: 8),
        Text(
          i18n.t('toolbox.sleep.night.home.daytime_hint'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _intentTile(
    BuildContext context, {
    required SleepSupportIntent intent,
    required IconData icon,
    required String name,
    required String titleKey,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('sleep-intent-$name'),
        onTap: () => onIntent(intent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  i18n.t(titleKey),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

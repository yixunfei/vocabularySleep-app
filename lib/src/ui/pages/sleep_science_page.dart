import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'toolbox_tool_shell.dart';

class SleepSciencePage extends StatelessWidget {
  const SleepSciencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    Widget themed(Widget child) {
      return sleepModuleTheme(
        context: context,
        enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
        child: child,
      );
    }

    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return themed(
        ToolboxToolPage(
          title: i18n.t('toolbox.sleep.core.title'),
          subtitle: i18n.t('toolbox.sleep.core.disabled'),
          child: ModuleDisabledView(
            i18n: i18n,
            moduleId: ModuleIds.toolboxSleepAssistant,
          ),
        ),
      );
    }

    return themed(
      ToolboxToolPage(
        title: i18n.t('toolbox.sleep.science.title'),
        subtitle: i18n.t('toolbox.sleep.science.intro'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ScienceNotice(i18n: i18n),
            const SizedBox(height: 12),
            _SciencePrinciples(i18n: i18n),
            const SizedBox(height: 12),
            ..._manualSections(i18n).map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScienceExpansion(section: section),
              ),
            ),
            const SizedBox(height: 2),
            _ScienceReferenceIndex(i18n: i18n),
          ],
        ),
      ),
    );
  }
}

class _ScienceNotice extends StatelessWidget {
  const _ScienceNotice({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.health_and_safety_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                i18n.t('toolbox.sleep.science.disclaimer'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SciencePrinciples extends StatelessWidget {
  const _SciencePrinciples({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final cards = <_SciencePrinciple>[
      _SciencePrinciple(
        icon: Icons.wb_sunny_rounded,
        title: i18n.t('toolbox.sleep.science.anchorRhythm'),
        body: i18n.t('toolbox.sleep.science.anchorRhythmBody'),
        accent: const Color(0xFFB08B33),
      ),
      _SciencePrinciple(
        icon: Icons.hotel_rounded,
        title: i18n.t('toolbox.sleep.science.keepBedForSleep'),
        body: i18n.t('toolbox.sleep.science.keepBedForSleepBody'),
        accent: const Color(0xFF517D6E),
      ),
      _SciencePrinciple(
        icon: Icons.edit_note_rounded,
        title: i18n.t('toolbox.sleep.science.logLightly'),
        body: i18n.t('toolbox.sleep.science.logLightlyBody'),
        accent: const Color(0xFF4E74A8),
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map((item) => _SciencePrincipleCard(item: item))
          .toList(growable: false),
    );
  }
}

class _SciencePrinciple {
  const _SciencePrinciple({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}

class _SciencePrincipleCard extends StatelessWidget {
  const _SciencePrincipleCard({required this.item});

  final _SciencePrinciple item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 760 ? width - 32 : 186.0;
    final accent = sleepReadableAccent(context, item.accent);
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(item.icon, color: accent),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(item.body, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScienceManualSection {
  const _ScienceManualSection({
    required this.title,
    required this.summary,
    required this.icon,
    required this.bullets,
  });

  final String title;
  final String summary;
  final IconData icon;
  final List<String> bullets;
}

class _ScienceExpansion extends StatelessWidget {
  const _ScienceExpansion({required this.section});

  final _ScienceManualSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          leading: Icon(section.icon, color: theme.colorScheme.primary),
          title: Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(section.summary),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: section.bullets
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ScienceReferenceIndex extends StatelessWidget {
  const _ScienceReferenceIndex({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.source_rounded, color: theme.colorScheme.primary),
          title: Text(
            i18n.t('toolbox.sleep.science.referenceIndex'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            i18n.t('toolbox.sleep.science.referenceSource'),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: <Widget>[
            _ReferenceGroup(
              title: i18n.t('toolbox.sleep.science.refGroupCbti'),
              body: i18n.t('toolbox.sleep.science.refGroupCbtiBody'),
            ),
            _ReferenceGroup(
              title: i18n.t('toolbox.sleep.science.refGroupRhythm'),
              body: i18n.t('toolbox.sleep.science.refGroupRhythmBody'),
            ),
            _ReferenceGroup(
              title: i18n.t('toolbox.sleep.science.refGroupMedical'),
              body: i18n.t('toolbox.sleep.science.refGroupMedicalBody'),
            ),
            _ReferenceGroup(
              title: i18n.t('toolbox.sleep.science.refGroupPopular'),
              body: i18n.t('toolbox.sleep.science.refGroupPopularBody'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceGroup extends StatelessWidget {
  const _ReferenceGroup({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

List<_ScienceManualSection> _manualSections(AppI18n i18n) {
  return <_ScienceManualSection>[
    _ScienceManualSection(
      icon: Icons.warning_amber_rounded,
      title: i18n.t('toolbox.sleep.science.riskFirst'),
      summary: i18n.t('toolbox.sleep.science.riskFirstBody'),
      bullets: <String>[
        i18n.t('toolbox.sleep.science.riskSnoring'),
        i18n.t('toolbox.sleep.science.riskMental'),
        i18n.t('toolbox.sleep.science.riskMedical'),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.wb_sunny_rounded,
      title: i18n.t('toolbox.sleep.science.dayAnchors'),
      summary: i18n.t('toolbox.sleep.science.dayAnchorsBody'),
      bullets: <String>[
        i18n.t('toolbox.sleep.science.fixWakeTime'),
        i18n.t('toolbox.sleep.science.caffeineRule'),
        i18n.t('toolbox.sleep.science.napRule'),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.nights_stay_rounded,
      title: i18n.t('toolbox.sleep.science.windDownSm'),
      summary: i18n.t('toolbox.sleep.science.windDownSmBody'),
      bullets: <String>[
        i18n.t('toolbox.sleep.science.windDownDetail1'),
        i18n.t('toolbox.sleep.science.windDownDetail2'),
        i18n.t('toolbox.sleep.science.windDownDetail3'),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.self_improvement_rounded,
      title: i18n.t('toolbox.sleep.science.nightWaking'),
      summary: i18n.t('toolbox.sleep.science.nightWakingBody'),
      bullets: <String>[
        i18n.t('toolbox.sleep.science.nightWakingDetail1'),
        i18n.t('toolbox.sleep.science.nightWakingDetail2'),
        i18n.t('toolbox.sleep.science.nightWakingDetail3'),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.rule_rounded,
      title: i18n.t('toolbox.sleep.science.easyMisuse'),
      summary: i18n.t('toolbox.sleep.science.easyMisuseIntro'),
      bullets: <String>[
        i18n.t('toolbox.sleep.science.eightHour'),
        i18n.t('toolbox.sleep.science.cycle90'),
        i18n.t('toolbox.sleep.science.hygiene'),
      ],
    ),
  ];
}

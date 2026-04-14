import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../models/sleep_routine_template.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import '../widgets/section_header.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_quick_tools.dart';
import 'sleep_routine_editor_page.dart';
import 'toolbox_mind_tools.dart';
import 'toolbox_soothing_music_v2_page.dart';
import 'toolbox_tool_shell.dart';

class SleepWindDownPage extends StatefulWidget {
  const SleepWindDownPage({super.key});

  @override
  State<SleepWindDownPage> createState() => _SleepWindDownPageState();
}

class _SleepWindDownPageState extends State<SleepWindDownPage> {
  late final TextEditingController _thoughtController;
  late final TextEditingController _reframeController;
  Timer? _ticker;
  double _intensity = 3;

  @override
  void initState() {
    super.initState();
    _thoughtController = TextEditingController();
    _reframeController = TextEditingController();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _thoughtController.dispose();
    _reframeController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final appState = context.read<AppState>();
      if (appState.sleepRoutineRunnerState.isRunning &&
          !appState.sleepRoutineRunnerState.isPaused) {
        appState.tickSleepRoutine();
      }
    });
  }

  void _saveThought() {
    final content = _thoughtController.text.trim();
    if (content.isEmpty) {
      return;
    }
    final appState = context.read<AppState>();
    appState.saveSleepThoughtEntry(
      SleepThoughtEntry(
        dateKey: todaySleepDateKey(),
        entryType: 'worry_unload',
        content: content,
        reframedContent: _reframeController.text.trim().isEmpty
            ? null
            : _reframeController.text.trim(),
        intensity: _intensity.round(),
        createdAt: DateTime.now(),
      ),
    );
    _thoughtController.clear();
    _reframeController.clear();
    final i18n = AppI18n(appState.uiLanguage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickSleepText(i18n, zh: '思绪卸载已保存', en: 'Thought unload saved'),
        ),
      ),
    );
  }

  void _openEditor(SleepRoutineTemplate? template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SleepRoutineEditorPage(template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return ToolboxToolPage(
        title: pickSleepText(i18n, zh: '睡眠助手', en: 'Sleep assistant'),
        subtitle: pickSleepText(
          i18n,
          zh: '模块已停用，无法继续访问睡眠助手页面。',
          en: 'This module is disabled and unavailable right now.',
        ),
        child: ModuleDisabledView(
          i18n: i18n,
          moduleId: ModuleIds.toolboxSleepAssistant,
        ),
      );
    }
    final templates = appState.sleepRoutineTemplates;
    final activeTemplate = appState.activeSleepRoutineTemplate;
    final currentStep = appState.currentSleepRoutineStep;
    final recentThoughts = appState.sleepThoughtEntries
        .take(4)
        .toList(growable: false);

    return ToolboxToolPage(
      title: pickSleepText(i18n, zh: '今晚流程', en: 'Tonight routine'),
      subtitle: pickSleepText(
        i18n,
        zh: '把睡前流程做成可选模板、可执行步骤和更温和的结束动作。',
        en: 'Turn wind-down into editable templates, runnable steps, and a quieter ending.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: pickSleepText(i18n, zh: '流程模板', en: 'Templates'),
            subtitle: pickSleepText(
              i18n,
              zh: '可直接开始，也可以复制后自定义。',
              en: 'Start them directly or duplicate into your own custom version.',
            ),
            trailing: FilledButton.tonalIcon(
              onPressed: () => _openEditor(null),
              icon: const Icon(Icons.add_rounded),
              label: Text(pickSleepText(i18n, zh: '新建', en: 'New')),
            ),
          ),
          const SizedBox(height: 12),
          ...templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RoutineTemplateCard(
                template: template,
                i18n: i18n,
                selected: activeTemplate?.id == template.id,
                onTap: () => context
                    .read<AppState>()
                    .setSleepActiveRoutineTemplate(template.id),
                onEdit: () => _openEditor(template),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '流程执行器', en: 'Routine runner'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (activeTemplate != null) ...<Widget>[
                    Text(
                      activeTemplate.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: appState.sleepRoutineProgress,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentStep == null
                          ? pickSleepText(
                              i18n,
                              zh: '还未开始',
                              en: 'Not started yet',
                            )
                          : '${currentStep.label} · ${sleepSecondsLabel(appState.sleepRoutineRunnerState.remainingSeconds, i18n: i18n)}',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed:
                              appState.sleepRoutineRunnerState.isRunning ||
                                  appState.sleepRoutineRunnerState.isPaused
                              ? null
                              : () => context
                                    .read<AppState>()
                                    .startSleepRoutine(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            pickSleepText(i18n, zh: '开始', en: 'Start'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: appState.sleepRoutineRunnerState.isRunning
                              ? () =>
                                    context.read<AppState>().pauseSleepRoutine()
                              : null,
                          icon: const Icon(Icons.pause_rounded),
                          label: Text(
                            pickSleepText(i18n, zh: '暂停', en: 'Pause'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: appState.sleepRoutineRunnerState.isPaused
                              ? () => context
                                    .read<AppState>()
                                    .resumeSleepRoutine()
                              : null,
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          label: Text(
                            pickSleepText(i18n, zh: '继续', en: 'Resume'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              appState
                                      .sleepRoutineRunnerState
                                      .activeTemplateId ==
                                  null
                              ? null
                              : () => context
                                    .read<AppState>()
                                    .advanceSleepRoutine(),
                          icon: const Icon(Icons.skip_next_rounded),
                          label: Text(
                            pickSleepText(i18n, zh: '下一步', en: 'Next'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              appState
                                      .sleepRoutineRunnerState
                                      .activeTemplateId ==
                                  null
                              ? null
                              : () =>
                                    context.read<AppState>().stopSleepRoutine(),
                          icon: const Icon(Icons.stop_rounded),
                          label: Text(
                            pickSleepText(i18n, zh: '停止', en: 'Stop'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '担忧卸载', en: 'Thought unload'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _thoughtController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: pickSleepText(
                        i18n,
                        zh: '此刻最占脑子的念头',
                        en: 'Most active thought right now',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reframeController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: pickSleepText(
                        i18n,
                        zh: '更温和的替代表述',
                        en: 'Gentler reframe',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${pickSleepText(i18n, zh: '强度', en: 'Intensity')} ${_intensity.round()}/5',
                  ),
                  Slider(
                    value: _intensity,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => _intensity = value),
                  ),
                  FilledButton.icon(
                    onPressed: _saveThought,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(
                      pickSleepText(
                        i18n,
                        zh: '保存卸载条目',
                        en: 'Save unload entry',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '小工具', en: 'Quick tools'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '白噪音',
                          en: 'White noise',
                        ),
                        icon: Icons.graphic_eq_rounded,
                        onTap: () => showSleepWhiteNoiseSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '咖啡因截止线',
                          en: 'Caffeine cutoff',
                        ),
                        icon: Icons.local_cafe_rounded,
                        onTap: () => showCaffeineCutoffCalculatorSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(i18n, zh: '呼吸练习', en: 'Breathing'),
                        icon: Icons.air_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BreathingToolPage(),
                            ),
                          );
                        },
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '舒缓声音',
                          en: 'Soothing audio',
                        ),
                        icon: Icons.spa_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SoothingMusicV2Page(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (recentThoughts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickSleepText(
                        i18n,
                        zh: '最近卸载内容',
                        en: 'Recent unload entries',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...recentThoughts.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(entry.content),
                              if ((entry.reframedContent ?? '')
                                  .trim()
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  '${pickSleepText(i18n, zh: '替代表述', en: 'Reframe')}: ${entry.reframedContent}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineTemplateCard extends StatelessWidget {
  const _RoutineTemplateCard({
    required this.template,
    required this.i18n,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  final SleepRoutineTemplate template;
  final AppI18n i18n;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (template.builtIn)
                    Chip(
                      label: Text(
                        pickSleepText(i18n, zh: '内置', en: 'Built-in'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              Text('${template.totalMinutes} min'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: template.steps
                    .map(
                      (step) => Chip(
                        label: Text(
                          '${sleepRoutineStepTypeLabel(i18n, step.type)} ${step.durationSeconds ~/ 60}m',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              if (selected) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  pickSleepText(i18n, zh: '当前已选中', en: 'Currently selected'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

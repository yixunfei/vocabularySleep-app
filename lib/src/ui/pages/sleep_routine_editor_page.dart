import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/sleep_routine_template.dart';
import '../../state/app_state.dart';
import 'sleep_assistant_ui_support.dart';
import 'toolbox_tool_shell.dart';

class SleepRoutineEditorPage extends StatefulWidget {
  const SleepRoutineEditorPage({
    super.key,
    this.template,
  });

  final SleepRoutineTemplate? template;

  @override
  State<SleepRoutineEditorPage> createState() => _SleepRoutineEditorPageState();
}

class _SleepRoutineEditorPageState extends State<SleepRoutineEditorPage> {
  late final TextEditingController _nameController;
  late List<SleepRoutineStep> _steps;
  late bool _editingCustom;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _editingCustom = template != null && !template.builtIn;
    _nameController = TextEditingController(
      text: template == null
          ? '自定义流程'
          : template.builtIn
          ? '${template.name} 自定义版'
          : template.name,
    );
    _steps = List<SleepRoutineStep>.from(
      template?.steps ??
          const <SleepRoutineStep>[
            SleepRoutineStep(
              type: SleepRoutineStepType.dimLights,
              label: '调暗灯光',
              durationSeconds: 120,
            ),
            SleepRoutineStep(
              type: SleepRoutineStepType.unloadThoughts,
              label: '卸载思绪',
              durationSeconds: 300,
            ),
            SleepRoutineStep(
              type: SleepRoutineStepType.breathing,
              label: '呼吸放松',
              durationSeconds: 300,
            ),
            SleepRoutineStep(
              type: SleepRoutineStepType.goToBed,
              label: '上床准备睡',
              durationSeconds: 180,
            ),
          ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final appState = context.read<AppState>();
    final template = SleepRoutineTemplate(
      id: _editingCustom ? (widget.template?.id ?? '') : '',
      name: _nameController.text.trim(),
      totalMinutes: 0,
      steps: _steps,
      builtIn: false,
      updatedAt: DateTime.now(),
    );
    appState.saveSleepRoutineTemplate(template);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    final target = widget.template;
    if (target == null || target.builtIn) {
      return;
    }
    context.read<AppState>().deleteSleepRoutineTemplate(target.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    return ToolboxToolPage(
      title: pickSleepText(i18n, zh: '流程编辑器', en: 'Routine editor'),
      subtitle: pickSleepText(
        i18n,
        zh: '把今晚流程拆成更短、更具体、可执行的小步骤。',
        en: 'Split the routine into smaller, more executable steps.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: pickSleepText(i18n, zh: '模板名称', en: 'Template name'),
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoutineEditorStepCard(
                index: entry.key,
                step: entry.value,
                i18n: i18n,
                canMoveUp: entry.key > 0,
                canMoveDown: entry.key < _steps.length - 1,
                onChanged: (step) {
                  setState(() => _steps[entry.key] = step);
                },
                onMoveUp: () {
                  setState(() {
                    final current = _steps.removeAt(entry.key);
                    _steps.insert(entry.key - 1, current);
                  });
                },
                onMoveDown: () {
                  setState(() {
                    final current = _steps.removeAt(entry.key);
                    _steps.insert(entry.key + 1, current);
                  });
                },
                onDelete: () {
                  setState(() => _steps.removeAt(entry.key));
                },
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _steps.add(
                  SleepRoutineStep(
                    type: SleepRoutineStepType.whiteNoise,
                    label: pickSleepText(i18n, zh: '新增步骤', en: 'New step'),
                    durationSeconds: 180,
                  ),
                );
              });
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(pickSleepText(i18n, zh: '添加步骤', en: 'Add step')),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: _steps.isEmpty ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(pickSleepText(i18n, zh: '保存模板', en: 'Save template')),
              ),
              const SizedBox(width: 12),
              if (_editingCustom)
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(pickSleepText(i18n, zh: '删除', en: 'Delete')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineEditorStepCard extends StatelessWidget {
  const _RoutineEditorStepCard({
    required this.index,
    required this.step,
    required this.i18n,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final int index;
  final SleepRoutineStep step;
  final AppI18n i18n;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<SleepRoutineStep> onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  pickSleepText(
                    i18n,
                    zh: '步骤 ${index + 1}',
                    en: 'Step ${index + 1}',
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: canMoveUp ? onMoveUp : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  onPressed: canMoveDown ? onMoveDown : null,
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            DropdownButtonFormField<SleepRoutineStepType>(
              initialValue: step.type,
              decoration: InputDecoration(
                labelText: pickSleepText(i18n, zh: '类型', en: 'Step type'),
              ),
              items: SleepRoutineStepType.values
                  .map(
                    (type) => DropdownMenuItem<SleepRoutineStepType>(
                      value: type,
                      child: Text(sleepRoutineStepTypeLabel(i18n, type)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                onChanged(step.copyWith(type: value));
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: step.label,
              decoration: InputDecoration(
                labelText: pickSleepText(i18n, zh: '步骤文案', en: 'Step label'),
              ),
              onChanged: (value) => onChanged(step.copyWith(label: value)),
            ),
            const SizedBox(height: 12),
            Text(
              pickSleepText(
                i18n,
                zh: '时长 ${sleepSecondsLabel(step.durationSeconds, i18n: i18n)}',
                en: 'Duration ${sleepSecondsLabel(step.durationSeconds, i18n: i18n)}',
              ),
            ),
            Slider(
              value: step.durationSeconds.toDouble().clamp(30, 900),
              min: 30,
              max: 900,
              divisions: 29,
              onChanged: (value) => onChanged(
                step.copyWith(durationSeconds: value.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

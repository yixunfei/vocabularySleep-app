import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import '../../i18n/app_i18n.dart';
import '../../services/app_log_service.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/toolbox_audio_volume_service.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_human_tests_action.dart';
part 'toolbox_human_tests_aim.dart';
part 'toolbox_human_tests_aim_widgets.dart';
part 'toolbox_human_tests_cognition.dart';
part 'toolbox_human_tests_typing.dart';
part 'toolbox_human_tests_typing_copy.dart';
part 'toolbox_human_tests_typing_data.dart';
part 'toolbox_human_tests_typing_widgets.dart';
part 'toolbox_human_tests_dynamic_vision.dart';
part 'toolbox_human_tests_dynamic_vision_parts.dart';
part 'toolbox_human_tests_dynamic_vision_ui.dart';
part 'toolbox_human_tests_visual_search.dart';
part 'toolbox_human_tests_auditory.dart';
part 'toolbox_human_tests_auditory_lab.dart';
part 'toolbox_human_tests_switching.dart';
part 'toolbox_human_tests_drag_tracking.dart';
part 'toolbox_human_tests_bimanual.dart';
part 'toolbox_human_tests_hand_eye.dart';
part 'toolbox_human_tests_hand_eye_joystick.dart';
part 'toolbox_human_tests_hand_eye_parts.dart';
part 'toolbox_human_tests_hand_eye_fullscreen.dart';
part 'toolbox_human_tests_hand_eye_reports.dart';
part 'toolbox_human_tests_hand_eye_settings.dart';
part 'toolbox_human_tests_reaction.dart';
part 'toolbox_human_tests_number_memory_models.dart';
part 'toolbox_human_tests_verbal_memory_data.dart';
part 'toolbox_human_tests_number_memory.dart';
part 'toolbox_human_tests_number_memory_view.dart';
part 'toolbox_human_tests_number_memory_widgets.dart';
part 'toolbox_human_tests_verbal_memory_models.dart';
part 'toolbox_human_tests_verbal_memory.dart';
part 'toolbox_human_tests_verbal_memory_view.dart';
part 'toolbox_human_tests_verbal_memory_widgets.dart';
part 'toolbox_human_tests_memory.dart';
part 'toolbox_human_tests_shared.dart';
part 'toolbox_human_tests_time_perception.dart';
part 'toolbox_human_tests_visual_memory.dart';
part 'toolbox_human_tests_visual_memory_widgets.dart';
part 'toolbox_human_tests_visual.dart';
part 'toolbox_human_tests_visual_widgets.dart';

class HumanTestsToolPage extends StatelessWidget {
  const HumanTestsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '人类测试', en: 'Human tests'),
      subtitle: pickUiText(
        i18n,
        zh: '参考 Human Benchmark 条目组织的本地趣味测试，覆盖反应、记忆、视觉搜索、听觉、声学实验、打字、手眼协调、双任务切换、计算和注意力。',
        en: 'A local set of Human Benchmark-inspired tests covering reaction, memory, visual search, sound, acoustic experiments, typing, coordination, switching, calculation, and attention.',
      ),
      child: const _HumanTestsHub(),
    );
  }
}

const List<DeviceOrientation> _humanTestAllOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

bool _supportsHumanTestOrientationLock() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> _enterHumanTestLandscapeFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (_supportsHumanTestOrientationLock()) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

Future<void> _exitHumanTestFullscreen() async {
  if (_supportsHumanTestOrientationLock()) {
    await SystemChrome.setPreferredOrientations(_humanTestAllOrientations);
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class _HumanTestsHub extends StatefulWidget {
  const _HumanTestsHub();

  @override
  State<_HumanTestsHub> createState() => _HumanTestsHubState();
}

class _HumanTestsHubState extends State<_HumanTestsHub> {
  static List<String> _storedEntryOrder = const <String>[];
  static Set<String> _storedQuickEntryIds = const <String>{};

  List<String> _entryOrder = const <String>[];
  List<String> _previewEntryOrder = const <String>[];
  Set<String> _quickEntryIds = const <String>{};
  final GlobalKey _quickDockLayoutKey = GlobalKey();
  String? _draggingEntryId;
  String? _hoveredEntryId;
  bool _quickTargetActive = false;

  @override
  void initState() {
    super.initState();
    _entryOrder = List<String>.from(_storedEntryOrder);
    _previewEntryOrder = List<String>.from(_storedEntryOrder);
    _quickEntryIds = Set<String>.from(_storedQuickEntryIds);
  }

  void _persistLayout() {
    _storedEntryOrder = List<String>.from(_entryOrder);
    _storedQuickEntryIds = Set<String>.from(_quickEntryIds);
  }

  static bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  List<String> _normalizeEntryOrder(
    List<String> preferredOrder,
    List<_HumanTestEntry> entries,
  ) {
    final entriesById = <String, _HumanTestEntry>{
      for (final entry in entries) entry.id: entry,
    };
    final normalizedIds = <String>[];
    for (final id in preferredOrder) {
      if (entriesById.containsKey(id) && !normalizedIds.contains(id)) {
        normalizedIds.add(id);
      }
    }
    for (final entry in entries) {
      if (!normalizedIds.contains(entry.id)) {
        normalizedIds.add(entry.id);
      }
    }
    return normalizedIds;
  }

  List<String> _defaultOrder(List<_HumanTestEntry> entries) {
    const preferredOrder = <String>[
      'reaction',
      'aim',
      'tap_speed',
      'number_memory',
      'visual_memory',
      'sequence_memory',
      'verbal_memory',
      'chimp',
      'visual_search',
      'color_vision',
      'dynamic_vision',
      'auditory',
      'acoustic_experiment',
      'stroop',
      'calculation',
      'sustained_attention',
      'dual_task',
      'time_perception',
      'hand_eye',
      'joystick',
      'fine_drag',
      'bimanual',
      'typing',
      'luck',
    ];
    final entryIds = entries.map((entry) => entry.id).toSet();
    return <String>[
      for (final id in preferredOrder)
        if (entryIds.contains(id)) id,
      for (final entry in entries)
        if (!preferredOrder.contains(entry.id)) entry.id,
    ];
  }

  List<_HumanTestEntry> _orderedEntries(List<_HumanTestEntry> entries) {
    final committedSource = _entryOrder.isEmpty
        ? _defaultOrder(entries)
        : _entryOrder;
    final normalizedCommittedIds = _normalizeEntryOrder(
      committedSource,
      entries,
    );

    if (_draggingEntryId == null) {
      if (_entryOrder.isEmpty ||
          normalizedCommittedIds.length != _entryOrder.length ||
          !_sameStringList(normalizedCommittedIds, _entryOrder)) {
        _entryOrder = normalizedCommittedIds;
        _persistLayout();
      }
      if (_previewEntryOrder.isEmpty ||
          _previewEntryOrder.length != normalizedCommittedIds.length ||
          !_sameStringList(_previewEntryOrder, normalizedCommittedIds)) {
        _previewEntryOrder = List<String>.from(normalizedCommittedIds);
      }
      return normalizedCommittedIds
          .map((id) => entries.firstWhere((entry) => entry.id == id))
          .toList(growable: false);
    }

    final previewSource = _previewEntryOrder.isEmpty
        ? normalizedCommittedIds
        : _previewEntryOrder;
    final normalizedPreviewIds = _normalizeEntryOrder(previewSource, entries);
    return normalizedPreviewIds
        .map((id) => entries.firstWhere((entry) => entry.id == id))
        .toList(growable: false);
  }

  List<_HumanTestEntry> _quickEntries(List<_HumanTestEntry> orderedEntries) {
    final normalizedQuickIds = _quickEntryIds
        .where((id) => orderedEntries.any((entry) => entry.id == id))
        .toSet();
    if (normalizedQuickIds.length != _quickEntryIds.length) {
      _quickEntryIds = normalizedQuickIds;
      _persistLayout();
    }
    return orderedEntries
        .where((entry) => normalizedQuickIds.contains(entry.id))
        .toList(growable: false);
  }

  void _startDrag(String entryId) {
    setState(() {
      _previewEntryOrder = List<String>.from(_entryOrder);
      _draggingEntryId = entryId;
      _hoveredEntryId = entryId;
      _quickTargetActive = false;
    });
  }

  void _endDrag({bool accepted = false}) {
    if (_draggingEntryId == null &&
        _hoveredEntryId == null &&
        !_quickTargetActive &&
        _previewEntryOrder.isEmpty) {
      return;
    }
    final quickEntryId = _quickTargetActive ? _draggingEntryId : null;
    final shouldAddQuickEntry =
        quickEntryId != null && !_quickEntryIds.contains(quickEntryId);
    final shouldCommit =
        accepted || !_sameStringList(_previewEntryOrder, _entryOrder);
    final nextOrder = _previewEntryOrder.isEmpty
        ? List<String>.from(_entryOrder)
        : List<String>.from(_previewEntryOrder);
    setState(() {
      if (shouldAddQuickEntry) {
        _quickEntryIds = <String>{..._quickEntryIds, quickEntryId};
      }
      if (shouldCommit) {
        _entryOrder = nextOrder;
        _previewEntryOrder = List<String>.from(nextOrder);
      } else {
        _previewEntryOrder = List<String>.from(_entryOrder);
      }
      _draggingEntryId = null;
      _hoveredEntryId = null;
      _quickTargetActive = false;
    });
    if (shouldCommit || shouldAddQuickEntry) {
      _persistLayout();
    }
  }

  void _previewMoveEntry(String draggedId, String targetId) {
    if (draggedId == targetId) {
      return;
    }
    setState(() {
      final nextOrder = List<String>.from(_previewEntryOrder);
      final oldIndex = nextOrder.indexOf(draggedId);
      final targetIndex = nextOrder.indexOf(targetId);
      if (oldIndex < 0 || targetIndex < 0) {
        return;
      }
      nextOrder.removeAt(oldIndex);
      final adjustedTargetIndex = nextOrder.indexOf(targetId);
      nextOrder.insert(
        adjustedTargetIndex < 0 ? targetIndex : adjustedTargetIndex,
        draggedId,
      );
      _previewEntryOrder = nextOrder;
      _hoveredEntryId = targetId;
    });
  }

  bool _quickDockContains(Offset globalPosition) {
    final renderObject = _quickDockLayoutKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final localPosition = renderObject.globalToLocal(globalPosition);
    return (Offset.zero & renderObject.size).contains(localPosition);
  }

  void _handleEntryDragPosition(String entryId, Offset globalPosition) {
    final shouldActivate =
        !_quickEntryIds.contains(entryId) && _quickDockContains(globalPosition);
    if (_quickTargetActive == shouldActivate) {
      return;
    }
    setState(() => _quickTargetActive = shouldActivate);
  }

  void _addQuickEntry(String entryId) {
    setState(() {
      _quickEntryIds = <String>{..._quickEntryIds, entryId};
      _draggingEntryId = null;
      _hoveredEntryId = null;
      _quickTargetActive = false;
    });
    _persistLayout();
  }

  void _removeQuickEntry(String entryId) {
    setState(() {
      final nextIds = <String>{..._quickEntryIds}..remove(entryId);
      _quickEntryIds = nextIds;
    });
    _persistLayout();
  }

  void _showAddQuickEntrySheet(
    BuildContext context,
    AppI18n i18n,
    List<_HumanTestEntry> entries,
  ) {
    final availableEntries = entries
        .where((entry) => !_quickEntryIds.contains(entry.id))
        .toList(growable: false);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: <Widget>[
              Text(
                pickUiText(i18n, zh: '添加快捷工具', en: 'Add quick tool'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pickUiText(
                  i18n,
                  zh: '选择常用测试加入顶部入口，也可以长按下方卡片拖到顶部。',
                  en: 'Choose common tests for the top bar, or drag a card upward into My tools.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              if (availableEntries.isEmpty)
                _HumanPanel(
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '所有测试都已加入快捷入口。',
                      en: 'All tests are already in My tools.',
                    ),
                  ),
                )
              else
                for (final entry in availableEntries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () {
                          _addQuickEntry(entry.id);
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: entry.accent.withValues(alpha: 0.20),
                          ),
                        ),
                        tileColor: entry.accent.withValues(alpha: 0.06),
                        leading: CircleAvatar(
                          backgroundColor: entry.accent.withValues(alpha: 0.16),
                          foregroundColor: entry.accent,
                          child: Icon(entry.icon),
                        ),
                        title: Text(entry.title),
                        subtitle: Text(entry.subtitle),
                        trailing: FilledButton.tonalIcon(
                          onPressed: () {
                            _addQuickEntry(entry.id);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text(pickUiText(i18n, zh: '添加', en: 'Add')),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final entries = _orderedEntries(_humanTestEntries(i18n));
    final quickEntries = _quickEntries(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(i18n, zh: '测试中心', en: 'Test hub'),
          subtitle: pickUiText(
            i18n,
            zh: '选择一个测试开始，结果只在本次页面中展示，不写入用户数据。',
            en: 'Choose a test to begin. Results are shown locally on this page only.',
          ),
        ),
        const SizedBox(height: 12),
        _HumanTestQuickDock(
          layoutKey: _quickDockLayoutKey,
          i18n: i18n,
          entries: quickEntries,
          active: _quickTargetActive,
          onAddTap: () => _showAddQuickEntrySheet(context, i18n, entries),
          onAccept: _addQuickEntry,
          onRemove: _removeQuickEntry,
          onDragEntered: () {
            if (!_quickTargetActive) {
              setState(() => _quickTargetActive = true);
            }
          },
          onDragExited: () {
            if (_quickTargetActive) {
              setState(() => _quickTargetActive = false);
            }
          },
          onDragEnd: () => _endDrag(accepted: true),
        ),
        const SizedBox(height: 16),
        _HumanTestReorderGrid(
          entries: entries,
          draggingEntryId: _draggingEntryId,
          hoveredEntryId: _hoveredEntryId,
          onDragStarted: _startDrag,
          onDragEnd: _endDrag,
          onDragPosition: _handleEntryDragPosition,
          onHover: _previewMoveEntry,
        ),
      ],
    );
  }
}

class _HumanTestQuickDock extends StatelessWidget {
  const _HumanTestQuickDock({
    required this.layoutKey,
    required this.i18n,
    required this.entries,
    required this.active,
    required this.onAddTap,
    required this.onAccept,
    required this.onRemove,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDragEnd,
  });

  final Key layoutKey;
  final AppI18n i18n;
  final List<_HumanTestEntry> entries;
  final bool active;
  final VoidCallback onAddTap;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onRemove;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      key: layoutKey,
      padding: EdgeInsets.zero,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          onDragEntered();
          return entries.every((entry) => entry.id != details.data);
        },
        onLeave: (_) => onDragExited(),
        onAcceptWithDetails: (details) {
          onAccept(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final highlighted = active || candidateData.isNotEmpty;
          return AnimatedContainer(
            key: const ValueKey<String>('human_tests_quick_dock'),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primaryContainer.withValues(
                    alpha: highlighted ? 0.52 : 0.24,
                  ),
                  colorScheme.surfaceContainerLowest,
                ],
              ),
              border: Border.all(
                color: highlighted
                    ? colorScheme.primary.withValues(alpha: 0.52)
                    : colorScheme.outlineVariant,
              ),
              boxShadow: highlighted
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.widgets_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            pickUiText(i18n, zh: '我的工具', en: 'My tools'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            pickUiText(
                              i18n,
                              zh: '添加或拖入常用测试',
                              en: 'Add or drag tests',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      key: const ValueKey<String>(
                        'human_tests_add_quick_button',
                      ),
                      onPressed: onAddTap,
                      visualDensity: VisualDensity.compact,
                      tooltip: pickUiText(
                        i18n,
                        zh: '添加快捷工具',
                        en: 'Add quick tool',
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 46),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: highlighted
                            ? colorScheme.primary.withValues(alpha: 0.34)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.72,
                              ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      highlighted
                          ? pickUiText(i18n, zh: '松开即可添加', en: 'Release to add')
                          : pickUiText(
                              i18n,
                              zh: '暂无快捷工具',
                              en: 'No quick tools yet',
                            ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: highlighted
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entries
                        .map(
                          (entry) => _HumanTestQuickTile(
                            entry: entry,
                            onRemove: () => onRemove(entry.id),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HumanTestQuickTile extends StatelessWidget {
  const _HumanTestQuickTile({required this.entry, required this.onRemove});

  final _HumanTestEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('human_tests_quick_${entry.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => entry.pageBuilder()));
        },
        onLongPress: onRemove,
        child: Ink(
          width: 64,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: entry.accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: entry.accent.withValues(alpha: 0.20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(entry.icon, size: 18, color: entry.accent),
              const SizedBox(height: 3),
              Text(
                entry.shortTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  height: 1.05,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HumanTestReorderGrid extends StatefulWidget {
  const _HumanTestReorderGrid({
    required this.entries,
    required this.draggingEntryId,
    required this.hoveredEntryId,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragPosition,
    required this.onHover,
  });

  final List<_HumanTestEntry> entries;
  final String? draggingEntryId;
  final String? hoveredEntryId;
  final ValueChanged<String> onDragStarted;
  final void Function({bool accepted}) onDragEnd;
  final void Function(String entryId, Offset globalPosition) onDragPosition;
  final void Function(String draggedId, String targetId) onHover;

  @override
  State<_HumanTestReorderGrid> createState() => _HumanTestReorderGridState();
}

class _HumanTestReorderGridState extends State<_HumanTestReorderGrid> {
  final GlobalKey _gridKey = GlobalKey();

  String? _targetEntryIdForPosition(
    Offset localPosition,
    List<_HumanTestEntry> entries,
    int columns,
    double cardWidth,
    double cardHeight,
    double spacing,
  ) {
    if (entries.isEmpty) {
      return null;
    }
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < entries.length; index += 1) {
      final center = Offset(
        (index % columns) * (cardWidth + spacing) + cardWidth / 2,
        (index ~/ columns) * (cardHeight + spacing) + cardHeight / 2,
      );
      final distance =
          (localPosition.dx - center.dx) * (localPosition.dx - center.dx) +
          (localPosition.dy - center.dy) * (localPosition.dy - center.dy);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return entries[bestIndex].id;
  }

  void _handleDragPosition({
    required String draggedId,
    required Offset globalPosition,
    required List<_HumanTestEntry> entries,
    required int columns,
    required double cardWidth,
    required double cardHeight,
    required double spacing,
  }) {
    widget.onDragPosition(draggedId, globalPosition);
    final renderObject = _gridKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }
    final targetId = _targetEntryIdForPosition(
      renderObject.globalToLocal(globalPosition),
      entries,
      columns,
      cardWidth,
      cardHeight,
      spacing,
    );
    if (targetId == null) {
      return;
    }
    widget.onHover(draggedId, targetId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const cardHeight = 118.0;
        final columns = constraints.maxWidth < 260 ? 1 : 2;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final rowCount = (widget.entries.length / columns).ceil();
        final height = rowCount * cardHeight + (rowCount - 1) * spacing;

        return SizedBox(
          key: _gridKey,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (var index = 0; index < widget.entries.length; index += 1)
                AnimatedPositioned(
                  key: ValueKey<String>(
                    'human_tests_grid_slot_${widget.entries[index].id}',
                  ),
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                  left: (index % columns) * (cardWidth + spacing),
                  top: (index ~/ columns) * (cardHeight + spacing),
                  width: cardWidth,
                  height: cardHeight,
                  child: _HumanTestDraggableEntryCard(
                    entry: widget.entries[index],
                    dragging:
                        widget.draggingEntryId == widget.entries[index].id,
                    highlighted:
                        widget.hoveredEntryId == widget.entries[index].id &&
                        widget.draggingEntryId != widget.entries[index].id,
                    onDragStarted: () =>
                        widget.onDragStarted(widget.entries[index].id),
                    onDragPosition: (globalPosition) => _handleDragPosition(
                      draggedId: widget.entries[index].id,
                      globalPosition: globalPosition,
                      entries: widget.entries,
                      columns: columns,
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      spacing: spacing,
                    ),
                    onDragEnd: widget.onDragEnd,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HumanTestDraggableEntryCard extends StatefulWidget {
  const _HumanTestDraggableEntryCard({
    required this.entry,
    required this.dragging,
    required this.highlighted,
    required this.onDragStarted,
    required this.onDragPosition,
    required this.onDragEnd,
  });

  final _HumanTestEntry entry;
  final bool dragging;
  final bool highlighted;
  final VoidCallback onDragStarted;
  final ValueChanged<Offset> onDragPosition;
  final void Function({bool accepted}) onDragEnd;

  @override
  State<_HumanTestDraggableEntryCard> createState() =>
      _HumanTestDraggableEntryCardState();
}

class _HumanTestDraggableEntryCardState
    extends State<_HumanTestDraggableEntryCard> {
  static const double _dragStartDistance = 8.0;

  int? _activePointer;
  Offset? _pointerDownPosition;
  bool _dragStarted = false;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
    _dragStarted = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer || _pointerDownPosition == null) {
      return;
    }
    if (!_dragStarted) {
      final distance = (event.position - _pointerDownPosition!).distance;
      if (distance < _dragStartDistance) {
        return;
      }
      _dragStarted = true;
      widget.onDragStarted();
    }
    widget.onDragPosition(event.position);
  }

  void _endDrag() {
    if (_activePointer == null) {
      return;
    }
    if (_dragStarted) {
      widget.onDragEnd(accepted: false);
    }
    _activePointer = null;
    _pointerDownPosition = null;
    _dragStarted = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: ValueKey<String>('human_tests_entry_${widget.entry.id}'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _endDrag(),
      onPointerCancel: (_) => _endDrag(),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: widget.dragging ? const Offset(0, -0.03) : Offset.zero,
        child: _HumanTestEntryCard(
          entry: widget.entry,
          compact: true,
          highlighted: widget.highlighted,
          dragging: widget.dragging,
        ),
      ),
    );
  }
}

List<_HumanTestEntry> _humanTestEntries(AppI18n i18n) {
  return <_HumanTestEntry>[
    _HumanTestEntry(
      id: 'reaction',
      title: pickUiText(i18n, zh: '反应测试', en: 'Reaction test'),
      shortTitle: pickUiText(i18n, zh: '反应', en: 'Reaction'),
      subtitle: pickUiText(
        i18n,
        zh: '经典松手、方向滑动与颜色匹配三种反应模式。',
        en: 'Classic release, direction-swipe, and color-match reaction modes.',
      ),
      icon: Icons.flash_on_rounded,
      accent: const Color(0xFF2F8D8E),
      pageBuilder: () => const ReactionTestPage(),
    ),
    _HumanTestEntry(
      id: 'number_memory',
      title: pickUiText(i18n, zh: '数字记忆', en: 'Number memory'),
      shortTitle: pickUiText(i18n, zh: '数字', en: 'Numbers'),
      subtitle: pickUiText(
        i18n,
        zh: '支持数字串、彩色数字、多数字目标与计算式，毫秒级停留和随机化可调。',
        en: 'Train digit strings, colored digits, multi-number targets, and equations with millisecond timing and randomization.',
      ),
      icon: Icons.pin_rounded,
      accent: const Color(0xFF536CC7),
      pageBuilder: () => const NumberMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'chimp',
      title: pickUiText(i18n, zh: '黑猩猩测试', en: 'Chimp test'),
      shortTitle: pickUiText(i18n, zh: '黑猩猩', en: 'Chimp'),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典、顺序数字与颜色顺序三种模式，并可调切换速度与难度。',
        en: 'Classic, sequential-number, and color-sequence modes with tunable speed/difficulty.',
      ),
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF6C8D42),
      pageBuilder: () => const ChimpTestPage(),
    ),
    _HumanTestEntry(
      id: 'typing',
      title: pickUiText(i18n, zh: '打字测试', en: 'Typing test'),
      shortTitle: pickUiText(i18n, zh: '打字', en: 'Typing'),
      subtitle: pickUiText(
        i18n,
        zh: '多语言语料、趣味模式、实时纠错和完成报告，训练速度、准确率与节奏稳定性。',
        en: 'Multi-language passages, playful modes, live correction, and reports for speed, accuracy, and rhythm.',
      ),
      icon: Icons.keyboard_alt_rounded,
      accent: const Color(0xFFC27A37),
      pageBuilder: () => const TypingTestPage(),
    ),
    _HumanTestEntry(
      id: 'visual_memory',
      title: pickUiText(i18n, zh: '视觉记忆', en: 'Visual memory'),
      shortTitle: pickUiText(i18n, zh: '视觉记忆', en: 'Visual'),
      subtitle: pickUiText(
        i18n,
        zh: '支持动态网格、颜色目标、指定颜色与干扰格，难度随等级阶梯提升。',
        en: 'Dynamic grids, color targets, target-color recall, and distractors with stepped difficulty.',
      ),
      icon: Icons.dashboard_customize_rounded,
      accent: const Color(0xFF8B6BC8),
      pageBuilder: () => const VisualMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'visual_search',
      title: pickUiText(i18n, zh: '视觉搜索', en: 'Visual search'),
      shortTitle: pickUiText(i18n, zh: '搜索', en: 'Search'),
      subtitle: pickUiText(
        i18n,
        zh: '在密集特征网格中快速找目标，并在双面板对照模式中辨别细微差异。',
        en: 'Scan dense grids for the target, then compare paired boards to spot a subtle difference.',
      ),
      icon: Icons.manage_search_rounded,
      accent: const Color(0xFF457B9D),
      pageBuilder: () => const VisualSearchTestPage(),
    ),
    _HumanTestEntry(
      id: 'aim',
      title: pickUiText(i18n, zh: '瞄准测试', en: 'Aim test'),
      shortTitle: pickUiText(i18n, zh: '瞄准', en: 'Aim'),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典点靶、降级放大、移动靶和真假干扰，统计命中质量与连击。',
        en: 'Classic, reveal-grow, moving, and decoy target modes with accuracy and streak feedback.',
      ),
      icon: Icons.adjust_rounded,
      accent: const Color(0xFFC24D5A),
      pageBuilder: () => const AimTestPage(),
    ),
    _HumanTestEntry(
      id: 'color_vision',
      title: pickUiText(i18n, zh: '色觉测试', en: 'Color vision'),
      shortTitle: pickUiText(i18n, zh: '色觉', en: 'Color'),
      subtitle: pickUiText(
        i18n,
        zh: '找不同、混色匹配、提示记录和可读报告，分析色差、色相与差异类型弱项。',
        en: 'Odd-tile and mixed-match modes with hints and readable reports for hue, delta, and contrast weaknesses.',
      ),
      icon: Icons.palette_rounded,
      accent: const Color(0xFF3F9A6B),
      pageBuilder: () => const ColorVisionTestPage(),
    ),
    _HumanTestEntry(
      id: 'auditory',
      title: pickUiText(i18n, zh: '听觉测试', en: 'Auditory test'),
      shortTitle: pickUiText(i18n, zh: '听觉', en: 'Hearing'),
      subtitle: pickUiText(
        i18n,
        zh: '覆盖频率、灵敏度与声音空间三类本地听感测试。',
        en: 'Local hearing checks for frequency, sensitivity, and sound space.',
      ),
      icon: Icons.hearing_rounded,
      accent: const Color(0xFF6E9BC3),
      pageBuilder: () => const AuditoryReactionTestPage(),
    ),
    _HumanTestEntry(
      id: 'acoustic_experiment',
      title: pickUiText(i18n, zh: '声学实验', en: 'Acoustic experiment'),
      shortTitle: pickUiText(i18n, zh: '声学', en: 'Acoustic'),
      subtitle: pickUiText(
        i18n,
        zh: '通过麦克风观察低音、高音、持续发声和噪声分贝的相对曲线。',
        en: 'Use the microphone to observe relative curves for low tone, high tone, sustain, and ambient noise dB.',
      ),
      icon: Icons.mic_external_on_rounded,
      accent: const Color(0xFF7F8B55),
      pageBuilder: () => const AcousticExperimentTestPage(),
    ),
    _HumanTestEntry(
      id: 'stroop',
      title: pickUiText(i18n, zh: '斯特鲁普', en: 'Stroop test'),
      shortTitle: pickUiText(i18n, zh: '斯特鲁普', en: 'Stroop'),
      subtitle: pickUiText(
        i18n,
        zh: '可配置 3-12 种颜色，判断词义与显示颜色是否一致。',
        en: 'Configure 3-12 colors and judge meaning-vs-ink consistency.',
      ),
      icon: Icons.contrast_rounded,
      accent: const Color(0xFF5B82C2),
      pageBuilder: () => const StroopTestPage(),
    ),
    _HumanTestEntry(
      id: 'verbal_memory',
      title: pickUiText(i18n, zh: '词汇记忆', en: 'Verbal memory'),
      shortTitle: pickUiText(i18n, zh: '词汇', en: 'Verbal'),
      subtitle: pickUiText(
        i18n,
        zh: '支持分领域词库、随机数字串与空间箭头序列，并可自定义展示高度。',
        en: 'Domain word banks, random digit strings, and arrow sequences with custom stage height.',
      ),
      icon: Icons.menu_book_rounded,
      accent: const Color(0xFF8F6C45),
      pageBuilder: () => const VerbalMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'sequence_memory',
      title: pickUiText(i18n, zh: '序列记忆', en: 'Sequence memory'),
      shortTitle: pickUiText(i18n, zh: '序列', en: 'Sequence'),
      subtitle: pickUiText(
        i18n,
        zh: '记住灯光顺序并原样复现。',
        en: 'Remember the light sequence and repeat it.',
      ),
      icon: Icons.auto_awesome_motion_rounded,
      accent: const Color(0xFF7C6BC8),
      pageBuilder: () => const SequenceMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'luck',
      title: pickUiText(i18n, zh: '运气测试', en: 'Luck test'),
      shortTitle: pickUiText(i18n, zh: '运气', en: 'Luck'),
      subtitle: pickUiText(
        i18n,
        zh: '支持单抽、十连、二十连、概率自定义、目标抽取和幸运指数报告。',
        en: 'Single, 10x, and 20x draws with custom odds, goals, and luck-index reports.',
      ),
      icon: Icons.casino_rounded,
      accent: const Color(0xFFD0923A),
      pageBuilder: () => const LuckTestPage(),
    ),
    _HumanTestEntry(
      id: 'tap_speed',
      title: pickUiText(i18n, zh: '手速测试', en: 'Tap speed'),
      shortTitle: pickUiText(i18n, zh: '手速', en: 'Tap'),
      subtitle: pickUiText(
        i18n,
        zh: '10 秒内尽可能多次点击按钮。',
        en: 'Tap as many times as possible in 10 seconds.',
      ),
      icon: Icons.touch_app_rounded,
      accent: const Color(0xFFC05180),
      pageBuilder: () => const TapSpeedTestPage(),
    ),
    _HumanTestEntry(
      id: 'time_perception',
      title: pickUiText(i18n, zh: '时间感知测试', en: 'Time perception'),
      shortTitle: pickUiText(i18n, zh: '时间', en: 'Time'),
      subtitle: pickUiText(
        i18n,
        zh: '连续多个时间节点感知：在指定时刻点击对应数字。',
        en: 'Multi-node time perception: tap matching numbers at planned moments.',
      ),
      icon: Icons.timer_rounded,
      accent: const Color(0xFF4D8C9E),
      pageBuilder: () => const TimePerceptionTestPage(),
    ),
    _HumanTestEntry(
      id: 'hand_eye',
      title: pickUiText(i18n, zh: '手眼协调测试', en: 'Hand-eye coordination'),
      shortTitle: pickUiText(i18n, zh: '手眼', en: 'Hand-eye'),
      subtitle: pickUiText(
        i18n,
        zh: '随机目标快速出现、移动并消失，统计成功、漏点、点空和反应延迟。',
        en: 'Fast random targets appear, move, and vanish while tracking hits, misses, blanks, and latency.',
      ),
      icon: Icons.center_focus_strong_rounded,
      accent: const Color(0xFFB55D42),
      pageBuilder: () => const HandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'fine_drag',
      title: pickUiText(i18n, zh: '精细拖拽追踪', en: 'Fine drag tracking'),
      shortTitle: pickUiText(i18n, zh: '拖动', en: 'Drag'),
      subtitle: pickUiText(
        i18n,
        zh: '沿窄轨迹拖动光标，记录偏离距离、离轨次数和完成时间。',
        en: 'Drag a small cursor along a narrow track while watching deviation, off-track events, and completion time.',
      ),
      icon: Icons.gesture_rounded,
      accent: const Color(0xFF4E8B6B),
      pageBuilder: () => const FineDragTrackingTestPage(),
    ),
    _HumanTestEntry(
      id: 'joystick',
      title: pickUiText(i18n, zh: '摇杆手眼协调', en: 'Joystick coordination'),
      shortTitle: pickUiText(i18n, zh: '摇杆', en: 'Joystick'),
      subtitle: pickUiText(
        i18n,
        zh: '用虚拟摇杆移动准星并点击射击，支持限时和目标总数两种测试。',
        en: 'Move a crosshair with a virtual joystick and fire in timed or target-count modes.',
      ),
      icon: Icons.gamepad_rounded,
      accent: const Color(0xFF8A6849),
      pageBuilder: () => const JoystickHandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'bimanual',
      title: pickUiText(i18n, zh: '双手协调', en: 'Bimanual coordination'),
      shortTitle: pickUiText(i18n, zh: '双手', en: 'Bimanual'),
      subtitle: pickUiText(
        i18n,
        zh: '在脑裂指令、陷阱、长按和同步窗口中同时调度左右手，挑战节奏、抑制和双手分工。',
        en: 'Run both hands through split-brain cues, traps, holds, and sync-window strikes for rhythm, inhibition, and coordination.',
      ),
      icon: Icons.pan_tool_alt_rounded,
      accent: const Color(0xFFD08A3A),
      pageBuilder: () => const BimanualCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'calculation',
      title: pickUiText(i18n, zh: '计算能力测试', en: 'Calculation test'),
      shortTitle: pickUiText(i18n, zh: '计算', en: 'Math'),
      subtitle: pickUiText(
        i18n,
        zh: '按难度、题型、题量或限时训练口算，完成后查看速度与准确率分析。',
        en: 'Train arithmetic by difficulty, operation type, fixed rounds, or time limit with speed and accuracy analysis.',
      ),
      icon: Icons.calculate_rounded,
      accent: const Color(0xFF6178B8),
      pageBuilder: () => const CalculationTestPage(),
    ),
    _HumanTestEntry(
      id: 'dynamic_vision',
      title: pickUiText(i18n, zh: '动态视力测试', en: 'Dynamic vision'),
      shortTitle: pickUiText(i18n, zh: '动态视力', en: 'Dynamic'),
      subtitle: pickUiText(
        i18n,
        zh: '字符识别支持字符集、轨迹、干扰与报告；小球数量随等级提升速度和数量。',
        en: 'Symbol recognition adds sets, paths, distractors, and reports; ball counting raises speed and count by level.',
      ),
      icon: Icons.remove_red_eye_rounded,
      accent: const Color(0xFF407E92),
      pageBuilder: () => const DynamicVisionTestPage(),
    ),
    _HumanTestEntry(
      id: 'dual_task',
      title: pickUiText(i18n, zh: '双任务切换', en: 'Dual-task switching'),
      shortTitle: pickUiText(i18n, zh: '切换', en: 'Switch'),
      subtitle: pickUiText(
        i18n,
        zh: '在数字与颜色判断之间来回切换注意力，并统计切换代价。',
        en: 'Switch between two judgment rules and track switch cost, repeat cost, and response speed.',
      ),
      icon: Icons.swap_horiz_rounded,
      accent: const Color(0xFFB05C5C),
      pageBuilder: () => const DualTaskSwitchTestPage(),
    ),
    _HumanTestEntry(
      id: 'sustained_attention',
      title: pickUiText(i18n, zh: '持续注意力测试', en: 'Sustained attention'),
      shortTitle: pickUiText(i18n, zh: '注意力', en: 'Focus'),
      subtitle: pickUiText(
        i18n,
        zh: '目标点击、低频目标和 n-back 三类任务，统计命中、漏点、误点与反应时。',
        en: 'Go/no-go, oddball, and n-back tasks with hit, miss, false-alarm, and reaction-time stats.',
      ),
      icon: Icons.track_changes_rounded,
      accent: const Color(0xFF6D8657),
      pageBuilder: () => const SustainedAttentionTestPage(),
    ),
  ];
}

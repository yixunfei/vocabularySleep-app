import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../i18n/app_i18n.dart';
import '../../services/app_log_service.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/toolbox_audio_volume_service.dart';
import '../../state/app_state_provider.dart';
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
      title: i18n.t('inline.ui.module.module_access.human_tests_b16d34'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.a_set_of_quick_tests_for_reaction_memory_visual_search_h_42d9fd',
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
      'visual_memory',
      'dynamic_vision',
      'joystick',
      'hand_eye',
      'color_vision',
      'sequence_memory',
      'chimp',
      'stroop',
      'bimanual',
      'luck',
      'time_perception',
      'aim',
      'visual_search',
      'number_memory',
      'verbal_memory',
      'tap_speed',
      'auditory',
      'acoustic_experiment',
      'dual_task',
      'calculation',
      'sustained_attention',
      'fine_drag',
      'typing',
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
                i18n.t('inline.plan294.life_hub.add_quick_tool_881c5f49'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests.choose_common_tests_for_the_top_bar_or_drag_a_card_upwar_90f049',
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
                    i18n.t(
                      'inline.ui.pages.toolbox_human_tests.all_tests_are_already_in_my_tools_edd94d',
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
                          label: Text(
                            i18n.t('inline.plan295.life.add.d800ae076568'),
                          ),
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
          title: i18n.t('inline.ui.pages.toolbox_human_tests.test_hub_7a77cf'),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests.choose_a_test_to_begin_results_stay_on_this_screen_for_q_215aaa',
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
        const SizedBox(height: 14),
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primaryContainer.withValues(
                    alpha: highlighted ? 0.46 : 0.20,
                  ),
                  colorScheme.surfaceContainerLow,
                ],
              ),
              border: Border.all(
                color: highlighted
                    ? colorScheme.primary.withValues(alpha: 0.48)
                    : colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: highlighted
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.widgets_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            i18n.t(
                              'inline.ui.pages.toolbox_human_tests.my_tools_23590a',
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            i18n.t(
                              'inline.ui.pages.toolbox_human_tests.add_or_drag_tests_7074f3',
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
                      tooltip: i18n.t(
                        'inline.plan294.life_hub.add_quick_tool_881c5f49',
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: highlighted
                            ? colorScheme.primary.withValues(alpha: 0.36)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.50,
                              ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      highlighted
                          ? i18n.t(
                              'inline.ui.pages.toolbox_human_tests.release_to_add_12ede1',
                            )
                          : i18n.t(
                              'inline.ui.pages.toolbox_human_tests.no_quick_tools_yet_878194',
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
                    spacing: 10,
                    runSpacing: 10,
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
          width: 68,
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: entry.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: entry.accent.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(entry.icon, size: 20, color: entry.accent),
              const SizedBox(height: 4),
              Text(
                entry.shortTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  height: 1.05,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
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
        final double spacing;
        final double cardHeight;
        if (constraints.maxWidth < 360) {
          spacing = 8.0;
          cardHeight = 118.0;
        } else if (constraints.maxWidth < 500) {
          spacing = 10.0;
          cardHeight = 118.0;
        } else {
          spacing = 12.0;
          cardHeight = 118.0;
        }
        final columns = constraints.maxWidth < 260 ? 1 : 2;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final rowCount = (widget.entries.length / columns).ceil();
        final height = rowCount * cardHeight + (rowCount - 1) * spacing;

        final isReordering = widget.draggingEntryId != null;
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
                  duration: Duration(milliseconds: isReordering ? 150 : 0),
                  curve: Curves.easeOutCubic,
                  left: (index % columns) * (cardWidth + spacing),
                  top: (index ~/ columns) * (cardHeight + spacing),
                  width: cardWidth,
                  height: cardHeight,
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (details) {
                      widget.onHover(details.data, widget.entries[index].id);
                      return true;
                    },
                    onMove: (details) {
                      widget.onHover(details.data, widget.entries[index].id);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return _HumanTestDraggableEntryCard(
                        entry: widget.entries[index],
                        dragging:
                            widget.draggingEntryId == widget.entries[index].id,
                        highlighted:
                            (widget.hoveredEntryId ==
                                    widget.entries[index].id ||
                                candidateData.isNotEmpty) &&
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
                      );
                    },
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
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 160.0;
        return SizedBox(
          key: ValueKey<String>('human_tests_entry_${widget.entry.id}'),
          width: double.infinity,
          height: double.infinity,
          child: LongPressDraggable<String>(
            data: widget.entry.id,
            delay: const Duration(milliseconds: 360),
            dragAnchorStrategy: childDragAnchorStrategy,
            maxSimultaneousDrags: 1,
            onDragStarted: () {
              HapticFeedback.selectionClick();
              widget.onDragStarted();
            },
            onDragUpdate: (details) =>
                widget.onDragPosition(details.globalPosition),
            onDragEnd: (details) =>
                widget.onDragEnd(accepted: details.wasAccepted),
            feedback: SizedBox(
              width: width,
              height: 118,
              child: IgnorePointer(
                child: _HumanTestEntryCard(
                  entry: widget.entry,
                  compact: true,
                  dragging: true,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.34,
              child: _HumanTestEntryCard(
                entry: widget.entry,
                compact: true,
                highlighted: false,
              ),
            ),
            child: _HumanTestEntryCard(
              entry: widget.entry,
              compact: true,
              highlighted: widget.highlighted,
              dragging: widget.dragging,
            ),
          ),
        );
      },
    );
  }
}

List<_HumanTestEntry> _humanTestEntries(AppI18n i18n) {
  return <_HumanTestEntry>[
    _HumanTestEntry(
      id: 'reaction',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_reaction.reaction_test_916776',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.reaction_4c2f3e'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.release_direction_swipe_and_color_match_reaction_modes_1675a2',
      ),
      icon: Icons.flash_on_rounded,
      accent: const Color(0xFF2F8D8E),
      pageBuilder: () => const ReactionTestPage(),
    ),
    _HumanTestEntry(
      id: 'number_memory',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.number_memory_f515d6',
      ),
      shortTitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_typing_copy.numbers_7ef41c',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.digit_strings_colored_digits_and_equation_memory_with_ad_605760',
      ),
      icon: Icons.pin_rounded,
      accent: const Color(0xFF536CC7),
      pageBuilder: () => const NumberMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'chimp',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.chimp_test_705527',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.chimp_5f43bf'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.classic_sequential_number_and_color_sequence_modes_with_0a6f17',
      ),
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF6C8D42),
      pageBuilder: () => const ChimpTestPage(),
    ),
    _HumanTestEntry(
      id: 'typing',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_typing.typing_test_13f37f',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.typing_e312b7'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.multi_language_typing_with_live_correction_stats_for_spe_414916',
      ),
      icon: Icons.keyboard_alt_rounded,
      accent: const Color(0xFFC27A37),
      pageBuilder: () => const TypingTestPage(),
    ),
    _HumanTestEntry(
      id: 'visual_memory',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.visual_memory_152214',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.visual_975f26'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.remember_color_positions_in_dynamic_grids_with_stepped_d_36194a',
      ),
      icon: Icons.dashboard_customize_rounded,
      accent: const Color(0xFF8B6BC8),
      pageBuilder: () => const VisualMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'visual_search',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_search.visual_search_71d706',
      ),
      shortTitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_search.search_79b8d4',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.find_targets_in_dense_grids_or_spot_differences_between_b1f699',
      ),
      icon: Icons.manage_search_rounded,
      accent: const Color(0xFF457B9D),
      pageBuilder: () => const VisualSearchTestPage(),
    ),
    _HumanTestEntry(
      id: 'aim',
      title: i18n.t('inline.ui.pages.toolbox_human_tests_aim.aim_test_70f27c'),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.aim_55bc86'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.classic_reveal_grow_moving_and_decoy_target_modes_with_h_31a8cd',
      ),
      icon: Icons.adjust_rounded,
      accent: const Color(0xFFC24D5A),
      pageBuilder: () => const AimTestPage(),
    ),
    _HumanTestEntry(
      id: 'color_vision',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.color_vision_26e312',
      ),
      shortTitle: i18n.t('inline.plan300.human_tests.visual.short_title'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.odd_tile_and_mixed_match_modes_for_color_vision_and_cont_84a4d0',
      ),
      icon: Icons.palette_rounded,
      accent: const Color(0xFF3F9A6B),
      pageBuilder: () => const ColorVisionTestPage(),
    ),
    _HumanTestEntry(
      id: 'auditory',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.auditory_test_65f8f1',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.hearing_04e950'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.frequency_sensitivity_and_spatial_hearing_tests_ba2339',
      ),
      icon: Icons.hearing_rounded,
      accent: const Color(0xFF6E9BC3),
      pageBuilder: () => const AuditoryReactionTestPage(),
    ),
    _HumanTestEntry(
      id: 'acoustic_experiment',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_experiment_36e23d',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.acoustic_295bc5'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.use_the_microphone_to_observe_tone_vocal_sustain_and_amb_4839d1',
      ),
      icon: Icons.mic_external_on_rounded,
      accent: const Color(0xFF7F8B55),
      pageBuilder: () => const AcousticExperimentTestPage(),
    ),
    _HumanTestEntry(
      id: 'stroop',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.stroop_test_171f46',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.stroop_34da2e'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.configure_3_12_colors_and_judge_meaning_vs_ink_consisten_72ac37',
      ),
      icon: Icons.contrast_rounded,
      accent: const Color(0xFF5B82C2),
      pageBuilder: () => const StroopTestPage(),
    ),
    _HumanTestEntry(
      id: 'verbal_memory',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory.verbal_memory_4a3a76',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.verbal_5f5770'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.domain_word_banks_digit_strings_and_spatial_arrow_sequen_1f4328',
      ),
      icon: Icons.menu_book_rounded,
      accent: const Color(0xFF8F6C45),
      pageBuilder: () => const VerbalMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'sequence_memory',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.sequence_memory_8c2989',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.sequence_530f88'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.remember_the_light_sequence_and_repeat_it_322e96',
      ),
      icon: Icons.auto_awesome_motion_rounded,
      accent: const Color(0xFF7C6BC8),
      pageBuilder: () => const SequenceMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'luck',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.luck_test_e69b0c',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.luck_0ddf94'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.single_10x_and_20x_draws_with_custom_odds_and_luck_index_ea46cd',
      ),
      icon: Icons.casino_rounded,
      accent: const Color(0xFFD0923A),
      pageBuilder: () => const LuckTestPage(),
    ),
    _HumanTestEntry(
      id: 'tap_speed',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.tap_speed_1d5f49',
      ),
      shortTitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.tap_speed_1d5f49',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.classic_target_chase_and_rhythm_hit_modes_for_speed_and_349b91',
      ),
      icon: Icons.touch_app_rounded,
      accent: const Color(0xFFC05180),
      pageBuilder: () => const TapSpeedTestPage(),
    ),
    _HumanTestEntry(
      id: 'time_perception',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_time_perception.time_perception_9a38e9',
      ),
      shortTitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_typing.time_b4685a',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.tap_buttons_at_planned_moments_to_test_continuous_time_p_e528f8',
      ),
      icon: Icons.timer_rounded,
      accent: const Color(0xFF4D8C9E),
      pageBuilder: () => const TimePerceptionTestPage(),
    ),
    _HumanTestEntry(
      id: 'hand_eye',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye.hand_eye_coordination_b6b32b',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.hand_eye_2a6db7'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.tap_random_fast_moving_targets_and_track_hits_misses_and_e0f9fd',
      ),
      icon: Icons.center_focus_strong_rounded,
      accent: const Color(0xFFB55D42),
      pageBuilder: () => const HandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'fine_drag',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_drag_tracking.fine_drag_tracking_85aebd',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.drag_60b8b4'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_drag_tracking.drag_a_cursor_along_a_narrow_track_for_fine_movement_con_b64547',
      ),
      icon: Icons.gesture_rounded,
      accent: const Color(0xFF4E8B6B),
      pageBuilder: () => const FineDragTrackingTestPage(),
    ),
    _HumanTestEntry(
      id: 'joystick',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.joystick_coordination_128f3b',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.joystick_d0f3fc'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.virtual_joystick_aim_and_fire_in_timed_or_target_count_m_a0a8ef',
      ),
      icon: Icons.gamepad_rounded,
      accent: const Color(0xFF8A6849),
      pageBuilder: () => const JoystickHandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'bimanual',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.bimanual_coordination_a59f9d',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.bimanual_eb9a34'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.both_hands_respond_to_separate_cues_training_independent_23d438',
      ),
      icon: Icons.pan_tool_alt_rounded,
      accent: const Color(0xFFD08A3A),
      pageBuilder: () => const BimanualCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'calculation',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.calculation_test_b7f071',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.math_6e6d26'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.train_arithmetic_by_difficulty_and_operation_type_with_s_fa2af4',
      ),
      icon: Icons.calculate_rounded,
      accent: const Color(0xFF6178B8),
      pageBuilder: () => const CalculationTestPage(),
    ),
    _HumanTestEntry(
      id: 'dynamic_vision',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.dynamic_vision_4255de',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.dynamic_cf5d86'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.fast_moving_symbol_recognition_and_ball_counting_with_le_2978ad',
      ),
      icon: Icons.remove_red_eye_rounded,
      accent: const Color(0xFF407E92),
      pageBuilder: () => const DynamicVisionTestPage(),
    ),
    _HumanTestEntry(
      id: 'dual_task',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_switching.dual_task_switching_ed2cb8',
      ),
      shortTitle: i18n.t('inline.ui.pages.toolbox_human_tests.switch_1b50e5'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.alternate_between_digit_and_color_judgments_to_measure_s_cab194',
      ),
      icon: Icons.swap_horiz_rounded,
      accent: const Color(0xFFB05C5C),
      pageBuilder: () => const DualTaskSwitchTestPage(),
    ),
    _HumanTestEntry(
      id: 'sustained_attention',
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.sustained_attention_4512af',
      ),
      shortTitle: i18n.t('ambientCategoryFocus'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests.go_no_go_oddball_and_n_back_tasks_with_hit_miss_and_reac_40075d',
      ),
      icon: Icons.track_changes_rounded,
      accent: const Color(0xFF6D8657),
      pageBuilder: () => const SustainedAttentionTestPage(),
    ),
  ];
}

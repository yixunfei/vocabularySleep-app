import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      title: pickUiText(
        i18n,
        zh: '人类测试',
        en: 'Human tests',
        ja: '人間テスト',
        de: 'Menschliche Tests',
        fr: 'Tests humains',
        es: 'Pruebas humanas',
        ru: 'Тесты человека',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '一组轻量测试，覆盖反应、记忆、视觉搜索、听觉、声学、打字、手眼协调、切换、计算和注意力。',
        en: 'A set of quick tests for reaction, memory, visual search, hearing, acoustics, typing, coordination, switching, calculation, and attention.',
        ja: '反応、記憶、視覚探索、聴覚、音響、タイピング、協調、切り替え、計算、注意を気軽に試せます。',
        de: 'Kurze Tests für Reaktion, Gedächtnis, visuelle Suche, Hören, Akustik, Tippen, Koordination, Wechsel, Rechnen und Aufmerksamkeit.',
        fr: 'Des tests rapides pour la réaction, la mémoire, la recherche visuelle, l’audition, l’acoustique, la frappe, la coordination, le calcul et l’attention.',
        es: 'Pruebas rápidas de reacción, memoria, búsqueda visual, audición, acústica, escritura, coordinación, cálculo y atención.',
        ru: 'Короткие тесты на реакцию, память, зрительный поиск, слух, акустику, набор текста, координацию, переключение, счет и внимание.',
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
                pickUiText(
                  i18n,
                  zh: '添加快捷工具',
                  en: 'Add quick tool',
                  ja: 'クイックツールを追加',
                  de: 'Add quick tool',
                  fr: 'Add quick tool',
                  es: 'Añadir herramienta rápida',
                  ru: 'Добавить быстрый инструмент',
                ),
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
                  ja: 'トップバーの一般的なテストを選択するか、マイツールにカードを上にドラッグします。',
                  de: 'Choose common tests for the top bar, or drag a card upward into My tools.',
                  fr: 'Choisissez des tests courants pour la barre supérieure, ou faites glisser une carte vers le haut dans Mes outils.',
                  es: 'Elija pruebas comunes para la barra superior, o arrastre una tarjeta hacia arriba en Mis herramientas.',
                  ru: 'Выберите общие тесты для верхней панели или перетащите карту вверх в Мои инструменты.',
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
                      ja: 'すべてのテストは既にマイツールにあります。',
                      de: 'All tests are already in My tools.',
                      fr: 'All tests are already in My tools.',
                      es: 'Todas las pruebas ya están en Mis herramientas.',
                      ru: 'Все тесты уже в моих инструментах.',
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
                            pickUiText(
                              i18n,
                              zh: '添加',
                              en: 'Add',
                              ja: '追加',
                              de: 'Add',
                              fr: 'Add',
                              es: 'Añadir',
                              ru: 'Добавить',
                            ),
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
          title: pickUiText(
            i18n,
            zh: '测试中心',
            en: 'Test hub',
            ja: 'テストセンター',
            de: 'Testzentrum',
            fr: 'Centre de tests',
            es: 'Centro de pruebas',
            ru: 'Центр тестов',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '选择一个测试开始。结果只保留在当前页面，方便随手对照。',
            en: 'Choose a test to begin. Results stay on this screen for quick comparison.',
            ja: 'テストを選んで始めます。結果はこの画面に残り、すぐ見比べられます。',
            de: 'Wähle einen Test aus. Die Ergebnisse bleiben zum schnellen Vergleich auf diesem Bildschirm.',
            fr: 'Choisissez un test pour commencer. Les résultats restent sur cet écran pour comparer facilement.',
            es: 'Elige una prueba para comenzar. Los resultados se quedan en esta pantalla para comparar fácilmente.',
            ru: 'Выберите тест и начните. Результаты остаются на этом экране для быстрого сравнения.',
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
                            pickUiText(
                              i18n,
                              zh: '我的工具',
                              en: 'My tools',
                              ja: 'My tools',
                              de: 'My tools',
                              fr: 'Mes outils',
                              es: 'Mis herramientas',
                              ru: 'Мои инструменты',
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            pickUiText(
                              i18n,
                              zh: '添加或拖入常用测试',
                              en: 'Add or drag tests',
                              ja: 'テストの追加またはドラッグ',
                              de: 'Add or drag tests',
                              fr: 'Add or drag tests',
                              es: 'Agregar o arrastrar pruebas',
                              ru: 'Добавить или перетащить тесты',
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
                        ja: 'クイックツールを追加',
                        de: 'Add quick tool',
                        fr: 'Add quick tool',
                        es: 'Añadir herramienta rápida',
                        ru: 'Добавить быстрый инструмент',
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
                          ? pickUiText(
                              i18n,
                              zh: '松开即可添加',
                              en: 'Release to add',
                              ja: 'Release to add',
                              de: 'Release to add',
                              fr: 'Publication à ajouter',
                              es: 'Lanzamiento a añadir',
                              ru: 'Выпуск Добавить',
                            )
                          : pickUiText(
                              i18n,
                              zh: '暂无快捷工具',
                              en: 'No quick tools yet',
                              ja: 'No quick tools yet',
                              de: 'No quick tools yet',
                              fr: 'Pas encore d\'outils rapides',
                              es: 'Aún no hay herramientas rápidas',
                              ru: 'Быстрых инструментов пока нет',
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
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              offset: widget.dragging ? const Offset(0, -0.045) : Offset.zero,
              child: _HumanTestEntryCard(
                entry: widget.entry,
                compact: true,
                highlighted: widget.highlighted,
                dragging: widget.dragging,
              ),
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
      title: pickUiText(
        i18n,
        zh: '反应测试',
        en: 'Reaction test',
        ja: 'Reaction test',
        de: 'Reaction test',
        fr: 'Essai de réaction',
        es: 'Prueba de reacción',
        ru: 'Реакционный тест',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '反应',
        en: 'Reaction',
        ja: 'Reaction',
        de: 'Reaction',
        fr: 'Réaction',
        es: 'Reacción',
        ru: 'Реакция',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '经典松手、方向滑动与颜色匹配三种反应模式。',
        en: 'Classic release, direction-swipe, and color-match reaction modes.',
        ja: 'クラシックリリース、方向スワイプ、カラーマッチのリアクションモード。',
        de: 'Classic release, direction-swipe, and color-match reaction modes.',
        fr: 'Modes classiques de libération, de balayage de direction et de réaction par correspondance de couleur.',
        es: 'Modos clásicos de liberación, dirección-swipe, y reacción de captura de color.',
        ru: 'Классические режимы выпуска, направления и цветового соответствия.',
      ),
      icon: Icons.flash_on_rounded,
      accent: const Color(0xFF2F8D8E),
      pageBuilder: () => const ReactionTestPage(),
    ),
    _HumanTestEntry(
      id: 'number_memory',
      title: pickUiText(
        i18n,
        zh: '数字记忆',
        en: 'Number memory',
        ja: 'Number memory',
        de: 'Number memory',
        fr: 'Mémoire numérique',
        es: 'Número de memoria',
        ru: 'Номер памяти',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '数字',
        en: 'Numbers',
        ja: 'Numbers',
        de: 'Numbers',
        fr: 'Nombres',
        es: 'Números',
        ru: 'Числа',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持数字串、彩色数字、多数字目标与计算式，毫秒级停留和随机化可调。',
        en: 'Train digit strings, colored digits, multi-number targets, and equations with millisecond timing and randomization.',
        ja: 'Train digit strings, colored digits, multi-number targets, and equations with millisecond timing and randomization.',
        de: 'Train digit strings, colored digits, multi-number targets, and equations with millisecond timing and randomization.',
        fr: 'Chaînes à chiffres de train, chiffres colorés, cibles à nombres multiples et équations avec chronométrage et randomisation en millisecondes.',
        es: 'Entrenar cadenas de dígitos, dígitos de colores, objetivos multinúmeros y ecuaciones con el tiempo de milisegundos y aleatorización.',
        ru: 'Цифровые строки поезда, цветные цифры, многочисленные цели и уравнения с миллисекундным временем и рандомизацией.',
      ),
      icon: Icons.pin_rounded,
      accent: const Color(0xFF536CC7),
      pageBuilder: () => const NumberMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'chimp',
      title: pickUiText(
        i18n,
        zh: '黑猩猩测试',
        en: 'Chimp test',
        ja: 'CHIMP TEST',
        de: 'Chimp test',
        fr: 'Essai de chimie',
        es: 'Prueba de chimpancé',
        ru: 'шимпанзе',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '黑猩猩',
        en: 'Chimp',
        ja: 'CHIMP',
        de: 'Chimp',
        fr: 'Chimp',
        es: 'Chimp',
        ru: 'Конопля',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典、顺序数字与颜色顺序三种模式，并可调切换速度与难度。',
        en: 'Classic, sequential-number, and color-sequence modes with tunable speed/difficulty.',
        ja: '速度/難易度を調整可能なクラシック、シーケンシャルナンバー、カラーシーケンスモード。',
        de: 'Classic, sequential-number, and color-sequence modes with tunable speed/difficulty.',
        fr: 'Modes classiques, séquentielle et séquentielle avec vitesse/difficulté réglable.',
        es: 'modos clásicos, número secuencial y secuencia de color con velocidad/dificultad ajustable.',
        ru: 'Классические, последовательные и цветовые режимы с настраиваемой скоростью / сложностью.',
      ),
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF6C8D42),
      pageBuilder: () => const ChimpTestPage(),
    ),
    _HumanTestEntry(
      id: 'typing',
      title: pickUiText(
        i18n,
        zh: '打字测试',
        en: 'Typing test',
        ja: 'Typing test',
        de: 'Typing test',
        fr: 'Essai de dactylographie',
        es: 'Prueba de clasificación',
        ru: 'Тест на ввод текста',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '打字',
        en: 'Typing',
        ja: 'Typing',
        de: 'Typing',
        fr: 'Dactylographie',
        es: 'Tipografía',
        ru: 'написание',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '多语言语料、趣味模式、实时纠错和完成报告，训练速度、准确率与节奏稳定性。',
        en: 'Multi-language passages, playful modes, live correction, and reports for speed, accuracy, and rhythm.',
        ja: 'Multi-language passages, playful modes, live correction, and reports for speed, accuracy, and rhythm.',
        de: 'Multi-language passages, playful modes, live correction, and reports for speed, accuracy, and rhythm.',
        fr: 'Passages en plusieurs langues, modes ludiques, correction en direct et rapports pour la vitesse, la précision et le rythme.',
        es: 'Pasajes multilingües, modos lúdicos, corrección en vivo e informes para velocidad, precisión y ritmo.',
        ru: 'Многоязычные пассажи, игровые режимы, живая коррекция и отчеты о скорости, точности и ритме.',
      ),
      icon: Icons.keyboard_alt_rounded,
      accent: const Color(0xFFC27A37),
      pageBuilder: () => const TypingTestPage(),
    ),
    _HumanTestEntry(
      id: 'visual_memory',
      title: pickUiText(
        i18n,
        zh: '视觉记忆',
        en: 'Visual memory',
        ja: 'Visual memory',
        de: 'Visual memory',
        fr: 'Mémoire visuelle',
        es: 'Memoria visual',
        ru: 'Визуальная память',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '视觉记忆',
        en: 'Visual',
        ja: 'Visual',
        de: 'Visual',
        fr: 'Visuel',
        es: 'Visual',
        ru: 'визуальный',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持动态网格、颜色目标、指定颜色与干扰格，难度随等级阶梯提升。',
        en: 'Dynamic grids, color targets, target-color recall, and distractors with stepped difficulty.',
        ja: 'Dynamic grids, color targets, target-color recall, and distractors with stepped difficulty.',
        de: 'Dynamic grids, color targets, target-color recall, and distractors with stepped difficulty.',
        fr: 'Grilles dynamiques, cibles de couleur, rappel de couleur cible, et disjoncteurs avec difficulté de marche.',
        es: 'Cuadrículas dinámicas, objetivos de color, memoria de color blanco, y distracciones con dificultad paso.',
        ru: 'Динамические сетки, цветовые мишени, запоминание цвета цели и отвлекающие факторы со ступенчатой сложностью.',
      ),
      icon: Icons.dashboard_customize_rounded,
      accent: const Color(0xFF8B6BC8),
      pageBuilder: () => const VisualMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'visual_search',
      title: pickUiText(
        i18n,
        zh: '视觉搜索',
        en: 'Visual search',
        ja: 'Visual search',
        de: 'Visual search',
        fr: 'Recherche visuelle',
        es: 'Búsqueda visual',
        ru: 'Визуальный поиск',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '搜索',
        en: 'Search',
        ja: 'Search',
        de: 'Search',
        fr: 'Recherche',
        es: 'Búsqueda',
        ru: 'Поиск',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在密集特征网格中快速找目标，并在双面板对照模式中辨别细微差异。',
        en: 'Scan dense grids for the target, then compare paired boards to spot a subtle difference.',
        ja: 'Scan dense grids for the target, then compare paired boards to spot a subtle difference.',
        de: 'Scan dense grids for the target, then compare paired boards to spot a subtle difference.',
        fr: 'Scanner des grilles denses pour la cible, puis comparer les planches appariées pour repérer une différence subtile.',
        es: 'Analizar rejillas densas para el objetivo, luego comparar tablas emparejadas para detectar una diferencia sutil.',
        ru: 'Сканируйте плотные сетки для цели, затем сравните парные доски, чтобы обнаружить тонкую разницу.',
      ),
      icon: Icons.manage_search_rounded,
      accent: const Color(0xFF457B9D),
      pageBuilder: () => const VisualSearchTestPage(),
    ),
    _HumanTestEntry(
      id: 'aim',
      title: pickUiText(
        i18n,
        zh: '瞄准测试',
        en: 'Aim test',
        ja: '照準テスト',
        de: 'Aim test',
        fr: 'Aim test',
        es: 'Prueba de objetivos',
        ru: 'Цель испытания',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '瞄准',
        en: 'Aim',
        ja: '狙い',
        de: 'Aim',
        fr: 'Aim',
        es: 'Aim',
        ru: 'Цель',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典点靶、降级放大、移动靶和真假干扰，统计命中质量与连击。',
        en: 'Classic, reveal-grow, moving, and decoy target modes with accuracy and streak feedback.',
        ja: '精度とストリークフィードバックを備えたクラシック、露出成長、移動、おとりターゲットモード。',
        de: 'Classic, reveal-grow, moving, and decoy target modes with accuracy and streak feedback.',
        fr: 'Modes de cible classique, de révélation, de déplacement et de leurre avec précision et retour de stries.',
        es: 'Modos de blanco clásico, revelador, en movimiento y decodificar con precisión y retroalimentación.',
        ru: 'Классические, раскрывающие, движущиеся и приманивающие целевые режимы с точностью и полосовой обратной связью.',
      ),
      icon: Icons.adjust_rounded,
      accent: const Color(0xFFC24D5A),
      pageBuilder: () => const AimTestPage(),
    ),
    _HumanTestEntry(
      id: 'color_vision',
      title: pickUiText(
        i18n,
        zh: '色觉测试',
        en: 'Color vision',
        ja: 'Color vision',
        de: 'Color vision',
        fr: 'Vision des couleurs',
        es: 'Visión de color',
        ru: 'Цветовое зрение',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '色觉',
        en: 'Color',
        ja: 'Color',
        de: 'Color',
        fr: 'Couleur',
        es: 'Color',
        ru: 'цвет',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '找不同、混色匹配、提示记录和可读报告，分析色差、色相与差异类型弱项。',
        en: 'Odd-tile and mixed-match modes with hints and readable reports for hue, delta, and contrast weaknesses.',
        ja: 'Odd-tile and mixed-match modes with hints and readable reports for hue, delta, and contrast weaknesses.',
        de: 'Odd-tile and mixed-match modes with hints and readable reports for hue, delta, and contrast weaknesses.',
        fr: 'Modes od-tile et mixte avec des conseils et des rapports lisibles pour les nuances, le delta et les faiblesses de contraste.',
        es: 'Modos extraños y mixtos con insinuaciones e informes legibles para debilidades de hue, delta y contraste.',
        ru: 'Нечеткие и смешанные режимы с подсказками и читаемыми отчетами для слабых сторон оттенка, дельты и контраста.',
      ),
      icon: Icons.palette_rounded,
      accent: const Color(0xFF3F9A6B),
      pageBuilder: () => const ColorVisionTestPage(),
    ),
    _HumanTestEntry(
      id: 'auditory',
      title: pickUiText(
        i18n,
        zh: '听觉测试',
        en: 'Auditory test',
        ja: '聴覚テスト',
        de: 'Auditory test',
        fr: 'Test auditif',
        es: 'Prueba de auditoria',
        ru: 'Слуховой тест',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '听觉',
        en: 'Hearing',
        ja: 'Hearing',
        de: 'Hearing',
        fr: 'Audition',
        es: 'Audiencia',
        ru: 'слушание',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '覆盖频率、灵敏度与声音空间三类听感测试。',
        en: 'Hearing checks for frequency, sensitivity, and sound space.',
        ja: 'Hearing checks for frequency, sensitivity, and sound space.',
        de: 'Hearing checks for frequency, sensitivity, and sound space.',
        fr: 'Vérification de la fréquence, de la sensibilité et de l\'espace sonore.',
        es: 'Controles auditivos para frecuencia, sensibilidad y espacio de sonido.',
        ru: 'Слушание проверяет частоту, чувствительность и звуковое пространство.',
      ),
      icon: Icons.hearing_rounded,
      accent: const Color(0xFF6E9BC3),
      pageBuilder: () => const AuditoryReactionTestPage(),
    ),
    _HumanTestEntry(
      id: 'acoustic_experiment',
      title: pickUiText(
        i18n,
        zh: '声学实验',
        en: 'Acoustic experiment',
        ja: '音響実験',
        de: 'Akustiktest',
        fr: 'Expérience acoustique',
        es: 'Experimento acústico',
        ru: 'Акустический тест',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '声学',
        en: 'Acoustic',
        ja: 'ア コ ー ス テ ィ ッ ク',
        de: 'Acoustic',
        fr: 'Acoustic',
        es: 'Acústico',
        ru: 'акустический',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '用麦克风观察低音、高音、持续发声和环境噪声的变化曲线。',
        en: 'Use the microphone to watch low tone, high tone, vocal sustain, and ambient noise trends.',
        ja: 'Use the microphone to watch low tone, high tone, vocal sustain, and ambient noise trends.',
        de: 'Use the microphone to watch low tone, high tone, vocal sustain, and ambient noise trends.',
        fr: 'Utilisez le microphone pour observer les tendances sonores basses, élevées, vocales et ambiantes.',
        es: 'Utilice el micrófono para ver las tendencias de tono bajo, tono alto, sostenimiento vocal y ruido ambiente.',
        ru: 'Используйте микрофон, чтобы следить за низким тоном, высоким тоном, вокальной устойчивостью и тенденциями окружающего шума.',
      ),
      icon: Icons.mic_external_on_rounded,
      accent: const Color(0xFF7F8B55),
      pageBuilder: () => const AcousticExperimentTestPage(),
    ),
    _HumanTestEntry(
      id: 'stroop',
      title: pickUiText(
        i18n,
        zh: '斯特鲁普',
        en: 'Stroop test',
        ja: 'Stroop test',
        de: 'Stroop test',
        fr: 'Essai de serrage',
        es: 'Prueba Stroop',
        ru: 'Испытание штурвалом',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '斯特鲁普',
        en: 'Stroop',
        ja: 'Stroop',
        de: 'Stroop',
        fr: 'Couper',
        es: 'Stroop',
        ru: 'Струп',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '可配置 3-12 种颜色，判断词义与显示颜色是否一致。',
        en: 'Configure 3-12 colors and judge meaning-vs-ink consistency.',
        ja: '3〜12色を設定し、意味とインクの一貫性を判断します。',
        de: 'Configure 3-12 colors and judge meaning-vs-ink consistency.',
        fr: 'Configurez 3-12 couleurs et jugez la cohérence sens-vs-ink.',
        es: 'Configure 3-12 colores y juzgue la consistencia de tinta-vs.',
        ru: 'Настройте 3-12 цветов и судите о последовательности смысл-vs-чернила.',
      ),
      icon: Icons.contrast_rounded,
      accent: const Color(0xFF5B82C2),
      pageBuilder: () => const StroopTestPage(),
    ),
    _HumanTestEntry(
      id: 'verbal_memory',
      title: pickUiText(
        i18n,
        zh: '词汇记忆',
        en: 'Verbal memory',
        ja: 'Verbal memory',
        de: 'Verbal memory',
        fr: 'Mémoire verbale',
        es: 'Memoria verbal',
        ru: 'Вербальная память',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '词汇',
        en: 'Verbal',
        ja: 'Verbal',
        de: 'Verbal',
        fr: 'Verbal',
        es: 'Verbal',
        ru: 'вербальный',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持分领域词库、随机数字串与空间箭头序列，并可自定义展示高度。',
        en: 'Domain word banks, random digit strings, and arrow sequences with custom stage height.',
        ja: 'Domain word banks, random digit strings, and arrow sequences with custom stage height.',
        de: 'Domain word banks, random digit strings, and arrow sequences with custom stage height.',
        fr: 'Banques de mots de domaine, chaînes à chiffres aléatoires et séquences de flèches avec hauteur de scène personnalisée.',
        es: 'Bancos de palabras de dominio, cadenas de dígitos aleatorios y secuencias de flechas con altura de etapa personalizada.',
        ru: 'Банки доменных слов, строки случайных цифр и последовательности стрелок с пользовательской высотой сцены.',
      ),
      icon: Icons.menu_book_rounded,
      accent: const Color(0xFF8F6C45),
      pageBuilder: () => const VerbalMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'sequence_memory',
      title: pickUiText(
        i18n,
        zh: '序列记忆',
        en: 'Sequence memory',
        ja: 'Sequence memory',
        de: 'Sequence memory',
        fr: 'Mémoire de séquence',
        es: 'Memoria de secuencias',
        ru: 'память последовательностей',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '序列',
        en: 'Sequence',
        ja: 'Sequence',
        de: 'Sequence',
        fr: 'Séquence',
        es: 'Secuencia',
        ru: 'последовательность',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '记住灯光顺序并原样复现。',
        en: 'Remember the light sequence and repeat it.',
        ja: 'Remember the light sequence and repeat it.',
        de: 'Remember the light sequence and repeat it.',
        fr: 'Rappelez-vous la séquence de lumière et répétez-la.',
        es: 'Recuerda la secuencia de luz y repetirla.',
        ru: 'Запомните световую последовательность и повторите ее.',
      ),
      icon: Icons.auto_awesome_motion_rounded,
      accent: const Color(0xFF7C6BC8),
      pageBuilder: () => const SequenceMemoryTestPage(),
    ),
    _HumanTestEntry(
      id: 'luck',
      title: pickUiText(
        i18n,
        zh: '运气测试',
        en: 'Luck test',
        ja: 'Luck test',
        de: 'Luck test',
        fr: 'Essai de chance',
        es: 'Prueba de suerte',
        ru: 'Удачный тест',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '运气',
        en: 'Luck',
        ja: 'Luck',
        de: 'Luck',
        fr: 'Bonne chance',
        es: 'Luck',
        ru: 'удача',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持单抽、十连、二十连、概率自定义、目标抽取和幸运指数报告。',
        en: 'Single, 10x, and 20x draws with custom odds, goals, and luck-index reports.',
        ja: 'Single, 10x, and 20x draws with custom odds, goals, and luck-index reports.',
        de: 'Single, 10x, and 20x draws with custom odds, goals, and luck-index reports.',
        fr: 'Single, 10x, et 20x dessine avec des cotes personnalisées, des buts, et des rapports de chance-index.',
        es: 'Single, 10x y 20x dibuja con probabilidades personalizadas, metas y reportes de índice de suerte.',
        ru: 'Одиночные, 10x и 20x розыгрыши с пользовательскими коэффициентами, целями и индексами удачи.',
      ),
      icon: Icons.casino_rounded,
      accent: const Color(0xFFD0923A),
      pageBuilder: () => const LuckTestPage(),
    ),
    _HumanTestEntry(
      id: 'tap_speed',
      title: pickUiText(
        i18n,
        zh: '手速测试',
        en: 'Tap speed',
        ja: 'Tap speed',
        de: 'Tap speed',
        fr: 'Vitesse de la touche',
        es: 'Velocidad',
        ru: 'Скорость нажатия',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '手速',
        en: 'Tap',
        ja: 'Tap',
        de: 'Tap',
        fr: 'Appuyez sur',
        es: 'Tap',
        ru: 'нажатие',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '10 秒内尽可能多次点击按钮。',
        en: 'Tap as many times as possible in 10 seconds.',
        ja: 'Tap as many times as possible in 10 seconds.',
        de: 'Tap as many times as possible in 10 seconds.',
        fr: 'Tapez autant de fois que possible en 10 secondes.',
        es: 'Pulsa lo más posible en 10 segundos.',
        ru: 'Нажмите как можно больше раз за 10 секунд.',
      ),
      icon: Icons.touch_app_rounded,
      accent: const Color(0xFFC05180),
      pageBuilder: () => const TapSpeedTestPage(),
    ),
    _HumanTestEntry(
      id: 'time_perception',
      title: pickUiText(
        i18n,
        zh: '时间感知测试',
        en: 'Time perception',
        ja: 'Time perception',
        de: 'Time perception',
        fr: 'Perception du temps',
        es: 'Percepción del tiempo',
        ru: 'Восприятие времени',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '时间',
        en: 'Time',
        ja: 'Time',
        de: 'Time',
        fr: 'Heure',
        es: 'Hora',
        ru: 'Время',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '连续多个时间节点感知：在指定时刻点击对应数字。',
        en: 'Multi-node time perception: tap matching numbers at planned moments.',
        ja: 'Multi-node time perception: tap matching numbers at planned moments.',
        de: 'Multi-node time perception: tap matching numbers at planned moments.',
        fr: 'Perception multi-noeud du temps: tapotez les numéros correspondants aux moments prévus.',
        es: 'Percepción de tiempo multinodo: pulsar números coincidentes en los momentos previstos.',
        ru: 'Восприятие многоузлового времени: использование совпадающих чисел в запланированные моменты.',
      ),
      icon: Icons.timer_rounded,
      accent: const Color(0xFF4D8C9E),
      pageBuilder: () => const TimePerceptionTestPage(),
    ),
    _HumanTestEntry(
      id: 'hand_eye',
      title: pickUiText(
        i18n,
        zh: '手眼协调测试',
        en: 'Hand-eye coordination',
        ja: 'Hand-eye coordination',
        de: 'Hand-eye coordination',
        fr: 'Coordination des yeux de la main',
        es: 'Coordinación de la mano-ojo',
        ru: 'Координация рук и глаз',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '手眼',
        en: 'Hand-eye',
        ja: 'Hand-eye',
        de: 'Hand-eye',
        fr: 'Oeil manuel',
        es: 'Mano-eye',
        ru: 'Рука об руку',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '随机目标快速出现、移动并消失，统计成功、漏点、点空和反应延迟。',
        en: 'Fast random targets appear, move, and vanish while tracking hits, misses, blanks, and latency.',
        ja: 'Fast random targets appear, move, and vanish while tracking hits, misses, blanks, and latency.',
        de: 'Fast random targets appear, move, and vanish while tracking hits, misses, blanks, and latency.',
        fr: 'Des cibles aléatoires rapides apparaissent, bougent et disparaissent tout en traquant les coups, les ratés, les blancs et la latence.',
        es: 'Los objetivos aleatorios rápidos aparecen, se mueven y desaparecen mientras rastrean golpes, señoritas, blancos y latencia.',
        ru: 'Быстрые случайные цели появляются, перемещаются и исчезают при отслеживании попаданий, промахов, пробелов и задержки.',
      ),
      icon: Icons.center_focus_strong_rounded,
      accent: const Color(0xFFB55D42),
      pageBuilder: () => const HandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'fine_drag',
      title: pickUiText(
        i18n,
        zh: '精细拖拽追踪',
        en: 'Fine drag tracking',
        ja: 'Fine drag tracking',
        de: 'Fine drag tracking',
        fr: 'Traçage fin de la traînée',
        es: 'Seguimiento de la arrastre',
        ru: 'Отличное отслеживание сопротивления',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '拖动',
        en: 'Drag',
        ja: 'Drag',
        de: 'Drag',
        fr: 'Faites glisser',
        es: 'Arrastre',
        ru: 'драка',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '沿窄轨迹拖动光标，记录偏离距离、离轨次数和完成时间。',
        en: 'Drag a small cursor along a narrow track while watching deviation, off-track events, and completion time.',
        ja: 'Drag a small cursor along a narrow track while watching deviation, off-track events, and completion time.',
        de: 'Drag a small cursor along a narrow track while watching deviation, off-track events, and completion time.',
        fr: 'Faites glisser un petit curseur le long d\'une piste étroite tout en regardant la déviation, les événements hors piste, et le temps d\'achèvement.',
        es: 'Arrastre un cursor pequeño a lo largo de una pista estrecha mientras observa la desviación, eventos fuera de pista y tiempo de terminación.',
        ru: 'Перетащите небольшой курсор по узкой дорожке, наблюдая за отклонениями, внедорожными событиями и временем завершения.',
      ),
      icon: Icons.gesture_rounded,
      accent: const Color(0xFF4E8B6B),
      pageBuilder: () => const FineDragTrackingTestPage(),
    ),
    _HumanTestEntry(
      id: 'joystick',
      title: pickUiText(
        i18n,
        zh: '摇杆手眼协调',
        en: 'Joystick coordination',
        ja: 'Joystick coordination',
        de: 'Joystick coordination',
        fr: 'Coordination des joysticks',
        es: 'Coordinación de Joystick',
        ru: 'Джойстик координация',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '摇杆',
        en: 'Joystick',
        ja: 'Joystick',
        de: 'Joystick',
        fr: 'Joystick',
        es: 'Joystick',
        ru: 'джойстик',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '用虚拟摇杆移动准星并点击射击，支持限时和目标总数两种测试。',
        en: 'Move a crosshair with a virtual joystick and fire in timed or target-count modes.',
        ja: 'Move a crosshair with a virtual joystick and fire in timed or target-count modes.',
        de: 'Move a crosshair with a virtual joystick and fire in timed or target-count modes.',
        fr: 'Déplacez un crosshair avec un joystick virtuel et feu en mode chronométré ou cible-compte.',
        es: 'Mueva un crosshair con un joystick virtual y fuego en modos temporizados o de venta de objetivos.',
        ru: 'Переместите перекрестье с виртуальным джойстиком и огнём в режимах времени или счета целей.',
      ),
      icon: Icons.gamepad_rounded,
      accent: const Color(0xFF8A6849),
      pageBuilder: () => const JoystickHandEyeCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'bimanual',
      title: pickUiText(
        i18n,
        zh: '双手协调',
        en: 'Bimanual coordination',
        ja: 'バイマニュアルコーディネート',
        de: 'Bimanual coordination',
        fr: 'Coordination bimanuelle',
        es: 'Coordinación bimanual',
        ru: 'Двухсторонняя координация',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '双手',
        en: 'Bimanual',
        ja: 'バイマニュアル',
        de: 'Bimanual',
        fr: 'Bimanuel',
        es: 'Bimanual',
        ru: 'двуязычный',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在脑裂指令、陷阱、长按和同步窗口中同时调度左右手，挑战节奏、抑制和双手分工。',
        en: 'Run both hands through split-brain cues, traps, holds, and sync-window strikes for rhythm, inhibition, and coordination.',
        ja: 'Run both hands through split-brain cues, traps, holds, and sync-window strikes for rhythm, inhibition, and coordination.',
        de: 'Run both hands through split-brain cues, traps, holds, and sync-window strikes for rhythm, inhibition, and coordination.',
        fr: 'Exécutez les deux mains à travers des repères, des pièges, des cales et des frappes de synchronisation pour le rythme, l\'inhibition et la coordination.',
        es: 'Ejecute ambas manos a través de cues, trampas, retenes y huelgas de sincronización para el ritmo, la inhibición y la coordinación.',
        ru: 'Проведите обе руки через сигналы разделенного мозга, ловушки, трюмы и удары синхронного окна для ритма, торможения и координации.',
      ),
      icon: Icons.pan_tool_alt_rounded,
      accent: const Color(0xFFD08A3A),
      pageBuilder: () => const BimanualCoordinationTestPage(),
    ),
    _HumanTestEntry(
      id: 'calculation',
      title: pickUiText(
        i18n,
        zh: '计算能力测试',
        en: 'Calculation test',
        ja: '計算テスト',
        de: 'Calculation test',
        fr: 'Essai de calcul',
        es: 'Prueba de cálculo',
        ru: 'Тест на расчет',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '计算',
        en: 'Math',
        ja: 'Math',
        de: 'Math',
        fr: 'Mathématiques',
        es: 'Matemáticas',
        ru: 'математика',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '按难度、题型、题量或限时训练口算，完成后查看速度与准确率分析。',
        en: 'Train arithmetic by difficulty, operation type, fixed rounds, or time limit with speed and accuracy analysis.',
        ja: 'Train arithmetic by difficulty, operation type, fixed rounds, or time limit with speed and accuracy analysis.',
        de: 'Train arithmetic by difficulty, operation type, fixed rounds, or time limit with speed and accuracy analysis.',
        fr: 'Arithmétique du train par difficulté, type de fonctionnement, rondes fixes ou limite de temps avec analyse de vitesse et de précision.',
        es: 'Entrenar aritmética por dificultad, tipo de operación, rondas fijas o límite de tiempo con análisis de velocidad y precisión.',
        ru: 'Арифметика поезда по сложности, типу операции, фиксированным раундам или пределу времени с анализом скорости и точности.',
      ),
      icon: Icons.calculate_rounded,
      accent: const Color(0xFF6178B8),
      pageBuilder: () => const CalculationTestPage(),
    ),
    _HumanTestEntry(
      id: 'dynamic_vision',
      title: pickUiText(
        i18n,
        zh: '动态视力测试',
        en: 'Dynamic vision',
        ja: 'Dynamic vision',
        de: 'Dynamic vision',
        fr: 'Vision dynamique',
        es: 'Visión dinámica',
        ru: 'Динамическое зрение',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '动态视力',
        en: 'Dynamic',
        ja: 'Dynamic',
        de: 'Dynamic',
        fr: 'Dynamique',
        es: 'Dinámica dinámica',
        ru: 'динамический',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '字符识别支持字符集、轨迹、干扰与报告；小球数量随等级提升速度和数量。',
        en: 'Symbol recognition adds sets, paths, distractors, and reports; ball counting raises speed and count by level.',
        ja: 'Symbol recognition adds sets, paths, distractors, and reports; ball counting raises speed and count by level.',
        de: 'Symbol recognition adds sets, paths, distractors, and reports; ball counting raises speed and count by level.',
        fr: 'La reconnaissance des symboles ajoute des ensembles, des chemins, des disjoncteurs et des rapports; le comptage des boules augmente la vitesse et le nombre par niveau.',
        es: 'El reconocimiento de símbolos añade conjuntos, caminos, distracciones e informes; el conteo de bolas aumenta la velocidad y cuenta por nivel.',
        ru: 'Распознавание символов добавляет наборы, пути, отвлекающие факторы и отчеты; подсчет мяча повышает скорость и счет по уровню.',
      ),
      icon: Icons.remove_red_eye_rounded,
      accent: const Color(0xFF407E92),
      pageBuilder: () => const DynamicVisionTestPage(),
    ),
    _HumanTestEntry(
      id: 'dual_task',
      title: pickUiText(
        i18n,
        zh: '双任务切换',
        en: 'Dual-task switching',
        ja: 'Dual-task switching',
        de: 'Dual-task switching',
        fr: 'Interrupteur à double tâche',
        es: 'Interruptor de dos discos',
        ru: 'Двойное задание',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '切换',
        en: 'Switch',
        ja: 'Switch',
        de: 'Switch',
        fr: 'Commutateur',
        es: 'Cambio',
        ru: 'переключатель',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在数字与颜色判断之间来回切换注意力，并统计切换代价。',
        en: 'Switch between two judgment rules and track switch cost, repeat cost, and response speed.',
        ja: 'Switch between two judgment rules and track switch cost, repeat cost, and response speed.',
        de: 'Switch between two judgment rules and track switch cost, repeat cost, and response speed.',
        fr: 'Interchanger entre deux règles de jugement et le coût de l\'interrupteur de voie, le coût de répétition et la vitesse de réponse.',
        es: 'Interruptor entre dos reglas de juicio y el coste de cambio de pista, coste de repetición y velocidad de respuesta.',
        ru: 'Переключитесь между двумя правилами суждения и стоимостью коммутатора трека, стоимостью повторения и скоростью ответа.',
      ),
      icon: Icons.swap_horiz_rounded,
      accent: const Color(0xFFB05C5C),
      pageBuilder: () => const DualTaskSwitchTestPage(),
    ),
    _HumanTestEntry(
      id: 'sustained_attention',
      title: pickUiText(
        i18n,
        zh: '持续注意力测试',
        en: 'Sustained attention',
        ja: 'Sustained attention',
        de: 'Sustained attention',
        fr: 'Une attention soutenue',
        es: 'Atención sostenida',
        ru: 'Постоянное внимание',
      ),
      shortTitle: pickUiText(
        i18n,
        zh: '注意力',
        en: 'Focus',
        ja: 'Focus',
        de: 'Focus',
        fr: 'Objectif',
        es: 'Focus',
        ru: 'Фокус',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '目标点击、低频目标和 n-back 三类任务，统计命中、漏点、误点与反应时。',
        en: 'Go/no-go, oddball, and n-back tasks with hit, miss, false-alarm, and reaction-time stats.',
        ja: 'Go/no-go, oddball, and n-back tasks with hit, miss, false-alarm, and reaction-time stats.',
        de: 'Go/no-go, oddball, and n-back tasks with hit, miss, false-alarm, and reaction-time stats.',
        fr: 'Go/no-go, impairball, et n-back tâches avec succès, miss, faux bras, et des statistiques de temps de réaction.',
        es: 'Go/no-go, oddball, y tareas n-back con éxito, señorita, falsa alarma y estadísticas de tiempo de reacción.',
        ru: 'Go/no-go, нечетные и n-back задачи с хитом, промахом, ложной тревогой и статистикой времени реакции.',
      ),
      icon: Icons.track_changes_rounded,
      accent: const Color(0xFF6D8657),
      pageBuilder: () => const SustainedAttentionTestPage(),
    ),
  ];
}

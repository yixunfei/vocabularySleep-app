import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../i18n/app_i18n.dart';
import '../models/play_config.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/wordbook.dart';
import '../services/asr_service.dart';
import '../state/app_state.dart';
import 'legacy_style.dart';

const List<_TtsApiModelOption> _ttsApiModels = <_TtsApiModelOption>[
  _TtsApiModelOption(
    id: 'FunAudioLLM/CosyVoice2-0.5B',
    name: 'CosyVoice2-0.5B',
    voices: <String>[
      'alex',
      'anna',
      'bella',
      'benjamin',
      'charles',
      'claire',
      'david',
      'diana',
    ],
  ),
  _TtsApiModelOption(
    id: 'fnlp/MOSS-TTSD-v0.5',
    name: 'MOSS-TTSD-v0.5',
    voices: <String>[
      'alex',
      'anna',
      'bella',
      'benjamin',
      'charles',
      'claire',
      'david',
      'diana',
    ],
  ),
  _TtsApiModelOption(
    id: 'fishaudio/fish-speech-1.4',
    name: 'FishSpeech-1.4',
    voices: <String>['anna', 'bella', 'maru', 'risuke'],
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumpPrefixController = TextEditingController();
  final TextEditingController _startPositionController = TextEditingController(
    text: '1',
  );
  final FocusNode _startPositionFocusNode = FocusNode();
  final ScrollController _pageScrollController = ScrollController();

  bool _sidebarCollapsed = false;
  bool _showBackToTop = false;
  bool _showPlaybackPanel = true;
  double _lastPageScrollOffset = 0;

  static const List<String> _letterJumpOptions = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];
  static const Map<AsrProviderType, String> _asrOfflineModelSizeHints =
      <AsrProviderType, String>{
        AsrProviderType.offline: '~150 MB',
        AsrProviderType.offlineSmall: '~250 MB',
      };

  @override
  void initState() {
    super.initState();
    _pageScrollController.addListener(_handleScrollChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().init();
    });
  }

  void _handleScrollChange() {
    if (!_pageScrollController.hasClients) return;
    final position = _pageScrollController.position;
    final offset = position.pixels;
    final maxOffset = position.maxScrollExtent;

    final showBackToTop = offset > 220;
    final atBottom = (maxOffset - offset) <= 8;
    final scrollingDown = offset > (_lastPageScrollOffset + 0.5);
    final scrollingUp = offset < (_lastPageScrollOffset - 0.5);

    var showPlaybackPanel = _showPlaybackPanel;
    if (atBottom || scrollingUp) {
      showPlaybackPanel = true;
    } else if (scrollingDown) {
      showPlaybackPanel = false;
    }

    final backChanged = showBackToTop != _showBackToTop;
    final panelChanged = showPlaybackPanel != _showPlaybackPanel;
    if (backChanged || panelChanged) {
      setState(() {
        _showBackToTop = showBackToTop;
        _showPlaybackPanel = showPlaybackPanel;
      });
    }
    _lastPageScrollOffset = offset;
  }

  Future<void> _scrollToWordAnchor() async {
    if (!_pageScrollController.hasClients) return;
    await _pageScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jumpPrefixController.dispose();
    _startPositionController.dispose();
    _startPositionFocusNode.dispose();
    _pageScrollController
      ..removeListener(_handleScrollChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final i18n = AppI18n(state.uiLanguage);
        final message = state.error;
        if (message != null && message.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            state.clearMessage();
          });
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.black,
            toolbarHeight: 72,
            centerTitle: true,
            foregroundColor: LegacyStyle.primary,
            title: Text(
              i18n.t('appTitle'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: LegacyStyle.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            actions: <Widget>[
              _buildTopLanguageSwitcher(state, i18n),
              const SizedBox(width: 10),
            ],
          ),
          drawer: _WordbookDrawer(
            state: state,
            i18n: i18n,
            onCreate: () => _openCreateWordbookDialog(context),
            onRename: (wordbookId, oldName) =>
                _openRenameWordbookDialog(context, wordbookId, oldName),
            onDelete: (wordbookId, name) =>
                _confirmDeleteWordbook(context, wordbookId, name),
            onMerge: () => _openMergeWordbooksDialog(context, state),
            onAddSingleWord: (book) => _openWordbookWordImportDialog(
              context,
              state,
              book,
              initialTab: 0,
            ),
            onImportJsonWords: (book) => _openWordbookWordImportDialog(
              context,
              state,
              book,
              initialTab: 1,
            ),
            onImportWordbook: () =>
                _importWordbookWithNamePrompt(context, state),
            onExportTaskWordbook: () =>
                _exportTaskWordbookWithNamePrompt(context, state),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: LegacyStyle.pageGradient),
            child: state.initializing
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppState state) {
    final i18n = AppI18n(state.uiLanguage);
    if (state.selectedWordbook == null) {
      return Center(child: Text(i18n.t('noWordbookYet')));
    }

    final current = state.currentWord;
    final scopedWords = state.visibleWords;
    final scopedIndex = current == null
        ? 0
        : scopedWords.indexWhere((item) => item.word == current.word);
    final displayIndex = scopedWords.isEmpty
        ? 1
        : ((scopedIndex >= 0 ? scopedIndex : 0) + 1);
    if (!_startPositionFocusNode.hasFocus &&
        _startPositionController.text != '$displayIndex') {
      _startPositionController.text = '$displayIndex';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final sidebarWidth = _sidebarCollapsed ? 74.0 : 318.0;
        final pagePadding = EdgeInsets.fromLTRB(
          isDesktop ? 16 : 10,
          8,
          isDesktop ? 56 : 10,
          12,
        );
        final minContentHeight = max(
          0.0,
          constraints.maxHeight - pagePadding.vertical,
        );
        final detailPanel = _WordDetailPanel(
          state: state,
          i18n: i18n,
          onEdit: (word) => _openWordEditorDialog(context, word),
          onDelete: (word) => _confirmDeleteWord(context, word),
          onFollowAlong: (word) => _openFollowAlongDialog(context, state, word),
          onCopyField: (field) => _copyField(context, field),
          onEditField: (word, field) =>
              _openFieldEditDialog(context, word, field),
          onDeleteField: (word, field) =>
              _confirmDeleteField(context, word, field),
          testModeEnabled: state.testModeEnabled,
          testModeRevealed: state.testModeRevealed,
          testModeHintRevealed: state.testModeHintRevealed,
          onToggleReveal: state.toggleTestModeReveal,
          onToggleHint: state.toggleTestModeHint,
        );
        final menuPanel = AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: sidebarWidth,
          child: _GlassPanel(
            child: _SideMenuPanel(
              state: state,
              i18n: i18n,
              collapsed: _sidebarCollapsed,
              searchController: _searchController,
              jumpPrefixController: _jumpPrefixController,
              letterJumpOptions: _letterJumpOptions,
              onToggleCollapse: () {
                setState(() {
                  _sidebarCollapsed = !_sidebarCollapsed;
                });
              },
              onSelectWordbook: (book) => state.selectWordbook(book),
              onRenameWordbook: (book) =>
                  _openRenameWordbookDialog(context, book.id, book.name),
              onDeleteWordbook: (book) =>
                  _confirmDeleteWordbook(context, book.id, book.name),
              onCreateWordbook: () => _openCreateWordbookDialog(context),
              onImportWordbook: () =>
                  _importWordbookWithNamePrompt(context, state),
              onImportLegacy: state.importLegacyDatabaseByPicker,
              onMergeWordbooks: () => _openMergeWordbooksDialog(context, state),
              onExportTask: () =>
                  _exportTaskWordbookWithNamePrompt(context, state),
              onClearTask: state.clearTaskWordbook,
              onJumpByInitial: (value) => _jumpByInitial(context, state, value),
              onJumpByPrefix: (value) => _jumpByPrefix(context, state, value),
              onAddSingleWord: (book) => _openWordbookWordImportDialog(
                context,
                state,
                book,
                initialTab: 0,
              ),
              onImportJsonWords: (book) => _openWordbookWordImportDialog(
                context,
                state,
                book,
                initialTab: 1,
              ),
            ),
          ),
        );
        final pageBody = isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  menuPanel,
                  const SizedBox(width: 12),
                  Expanded(child: _GlassPanel(child: detailPanel)),
                ],
              )
            : _GlassPanel(child: detailPanel);
        final playbackLeft = isDesktop
            ? pagePadding.left + sidebarWidth + 12
            : pagePadding.left;
        final playbackRight = pagePadding.right;

        return Stack(
          children: <Widget>[
            Padding(
              padding: pagePadding,
              child: Scrollbar(
                controller: _pageScrollController,
                thumbVisibility: isDesktop,
                trackVisibility: isDesktop,
                thickness: isDesktop ? 10 : null,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  controller: _pageScrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minContentHeight),
                    child: pageBody,
                  ),
                ),
              ),
            ),
            Positioned(
              left: playbackLeft,
              right: playbackRight,
              bottom: 14,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                offset: _showPlaybackPanel
                    ? Offset.zero
                    : const Offset(0, 0.15),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _showPlaybackPanel ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_showPlaybackPanel,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: _buildFloatingPlaybackPanel(state, i18n),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: _buildFloatingRightActions(state, i18n),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingPlaybackPanel(AppState state, AppI18n i18n) {
    final actionLabel = !state.isPlaying
        ? i18n.t('play')
        : (state.isPaused ? i18n.t('resume') : i18n.t('pause'));
    final actionIcon = !state.isPlaying
        ? Icons.play_arrow_rounded
        : (state.isPaused
              ? Icons.play_circle_fill_rounded
              : Icons.pause_rounded);
    final actionBackground = !state.isPlaying
        ? null
        : (state.isPaused ? const Color(0xFF16A34A) : const Color(0xFFEAB308));
    final actionForeground = !state.isPlaying
        ? null
        : (state.isPaused ? Colors.white : Colors.black87);

    final showPlayingBadge =
        state.isPlaying &&
        state.isPlayingDifferentWordbook &&
        state.playingWordbookName != null;

    const rowHeight = 52.0;
    const controlSize = 42.0;
    const horizontalGap = 6.0;
    const navButtonWidth = 112.0;
    const fieldHeight = 40.0;
    final sectionFill = Colors.white.withValues(alpha: 0.68);
    final sectionBorder = LegacyStyle.border.withValues(alpha: 0.9);
    final navButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(navButtonWidth, fieldHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    Widget buildPill({
      required Widget child,
      EdgeInsetsGeometry? padding,
      double minHeight = rowHeight,
    }) {
      return Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: sectionFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sectionBorder, width: 1),
        ),
        child: child,
      );
    }

    Widget buildControlButton({
      required IconData icon,
      required VoidCallback? onPressed,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: SizedBox(
          width: controlSize,
          height: controlSize,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            onPressed: onPressed,
            child: Icon(icon, size: 20),
          ),
        ),
      );
    }

    final playingBadge = buildPill(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => state.jumpToPlayingWordbook(),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.isPaused
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: horizontalGap),
              const Icon(Icons.library_books_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${i18n.t('currentPlayingList')}: ${state.playingWordbookName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12),
            ],
          ),
        ),
      ),
    );

    final playbackControls = buildPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildControlButton(
            icon: Icons.skip_previous_rounded,
            tooltip: i18n.t('prev'),
            onPressed: state.isPlaying
                ? () async {
                    await state.movePlaybackPreviousWord();
                    if (!mounted) return;
                    await _scrollToWordAnchor();
                  }
                : null,
          ),
          SizedBox(width: horizontalGap),
          Tooltip(
            message: actionLabel,
            child: SizedBox(
              width: controlSize,
              height: controlSize,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: actionBackground,
                  foregroundColor: actionForeground,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (state.isPlaying || state.wordsAvailable)
                    ? () async {
                        if (!state.isPlaying) {
                          await state.play();
                        } else {
                          await state.pauseOrResume();
                        }
                      }
                    : null,
                child: Transform.translate(
                  offset: actionIcon == Icons.play_arrow_rounded
                      ? const Offset(1, 0)
                      : Offset.zero,
                  child: Icon(actionIcon, size: 22),
                ),
              ),
            ),
          ),
          SizedBox(width: horizontalGap),
          buildControlButton(
            icon: Icons.skip_next_rounded,
            tooltip: i18n.t('next'),
            onPressed: state.isPlaying
                ? () async {
                    await state.movePlaybackNextWord();
                    if (!mounted) return;
                    await _scrollToWordAnchor();
                  }
                : null,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );

    final navControls = buildPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                i18n.t('startFrom'),
                style: const TextStyle(
                  color: LegacyStyle.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: horizontalGap),
              SizedBox(
                width: 78,
                height: fieldHeight,
                child: TextField(
                  controller: _startPositionController,
                  focusNode: _startPositionFocusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _jumpToStartPosition(state),
                ),
              ),
            ],
          ),
          SizedBox(width: horizontalGap),
          if (state.isPlayingDifferentWordbook) ...<Widget>[
            FilledButton.tonal(
              style: navButtonStyle,
              onPressed: () => state.playCurrentWordbook(),
              child: Text(i18n.t('playCurrent')),
            ),
            SizedBox(width: horizontalGap),
          ],
          FilledButton.tonalIcon(
            style: navButtonStyle,
            onPressed: state.wordsAvailable
                ? () async {
                    await state.playPreviousWord();
                    if (!mounted) return;
                    await _scrollToWordAnchor();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(i18n.t('prev')),
          ),
          SizedBox(width: horizontalGap),
          FilledButton.tonalIcon(
            style: navButtonStyle,
            onPressed: state.wordsAvailable
                ? () async {
                    await state.playNextWord();
                    if (!mounted) return;
                    await _scrollToWordAnchor();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(i18n.t('next')),
          ),
        ],
      ),
    );

    final modeButton = SizedBox(
      width: double.infinity,
      height: rowHeight,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: state.testModeEnabled
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.7),
          foregroundColor: state.testModeEnabled
              ? const Color(0xFF0369A1)
              : LegacyStyle.textPrimary,
        ),
        onPressed: () => state.setTestModeEnabled(!state.testModeEnabled),
        icon: Icon(
          state.testModeEnabled ? Icons.psychology : Icons.psychology_outlined,
        ),
        label: Text(i18n.t('testMode')),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: LegacyStyle.panelDecoration,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (showPlayingBadge) ...<Widget>[
                  Align(alignment: Alignment.center, child: playingBadge),
                  const SizedBox(height: 6),
                ],
                Align(alignment: Alignment.center, child: playbackControls),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: navControls,
                ),
                const SizedBox(height: 6),
                modeButton,
              ],
            );
          }

          Widget buildGridRow({
            required Widget left,
            required Widget right,
            bool stretchRight = false,
            Alignment leftAlignment = Alignment.centerLeft,
          }) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Align(alignment: leftAlignment, child: left),
                ),
                SizedBox(width: horizontalGap),
                Expanded(
                  flex: 8,
                  child: stretchRight
                      ? right
                      : Align(alignment: Alignment.centerRight, child: right),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showPlayingBadge)
                buildGridRow(
                  left: SizedBox(width: double.infinity, child: playingBadge),
                  right: navControls,
                  leftAlignment: Alignment.center,
                )
              else
                buildGridRow(
                  left: playbackControls,
                  right: navControls,
                  leftAlignment: Alignment.center,
                ),
              const SizedBox(height: 6),
              buildGridRow(
                left: showPlayingBadge
                    ? playbackControls
                    : const SizedBox.shrink(),
                right: modeButton,
                stretchRight: true,
                leftAlignment: Alignment.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingRightActions(AppState state, AppI18n i18n) {
    final visible = _showBackToTop;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildRoundFloatButton(
          icon: Icons.music_note,
          tooltip: i18n.t('ambientAudio'),
          onTap: () => _openAmbientDialog(context, state),
        ),
        const SizedBox(height: 10),
        _buildRoundFloatButton(
          icon: Icons.settings,
          tooltip: i18n.t('settings'),
          onTap: () => _openSettingsDialog(context, state),
        ),
        const SizedBox(height: 10),
        AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !visible,
            child: _buildRoundFloatButton(
              icon: Icons.expand_less,
              tooltip: i18n.t('backToTop'),
              background: Colors.white,
              foreground: LegacyStyle.textSecondary,
              onTap: () => _pageScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundFloatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color background = LegacyStyle.primary,
    Color foreground = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        elevation: 6,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(icon, color: foreground),
          ),
        ),
      ),
    );
  }

  Widget _buildTopLanguageSwitcher(AppState state, AppI18n i18n) {
    final currentLanguage = AppI18n.normalizeLanguageCode(state.uiLanguage);
    return PopupMenuButton<String>(
      tooltip: i18n.t('language'),
      initialValue: currentLanguage,
      onSelected: (value) => state.setUiLanguage(value),
      itemBuilder: (context) => AppI18n.supportedLanguages
          .map(
            (code) => PopupMenuItem<String>(
              value: code,
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(i18n.languageName(code))),
                  if (code == currentLanguage)
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: LegacyStyle.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LegacyStyle.primary.withValues(alpha: 0.45),
          ),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.language, size: 18),
            const SizedBox(width: 6),
            Text(
              currentLanguage.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _jumpToStartPosition(AppState state) {
    final scopedWords = state.visibleWords;
    if (scopedWords.isEmpty) return;
    final raw = _startPositionController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null) return;
    final targetIndex = parsed.clamp(1, scopedWords.length) - 1;
    state.selectWordEntry(scopedWords[targetIndex]);
  }

  Future<void> _copyField(BuildContext context, WordFieldItem field) async {
    await Clipboard.setData(ClipboardData(text: field.asText()));
    if (!context.mounted) return;
    final i18n = AppI18n(context.read<AppState>().uiLanguage);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(i18n.t('fieldCopied'))));
  }

  Future<void> _openFieldEditDialog(
    BuildContext context,
    WordEntry word,
    WordFieldItem field,
  ) async {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final keyController = TextEditingController(text: field.key);
    final labelController = TextEditingController(text: field.label);
    final valueController = TextEditingController(text: field.asText());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.t('editFieldTitle', params: {'field': field.label})),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  _editorField(i18n.t('fieldKey'), keyController),
                  const SizedBox(height: 8),
                  _editorField(i18n.t('fieldLabel'), labelController),
                  const SizedBox(height: 8),
                  _editorField(
                    i18n.t('fieldContent'),
                    valueController,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('save')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final baseFields = word.fields.isNotEmpty
        ? word.fields
        : buildFieldItemsFromRecord(<String, Object?>{
            'meaning': word.meaning,
            'examples': word.examples,
          });
    final nextKey = keyController.text.trim();
    if (nextKey.isEmpty) return;
    final nextLabel = labelController.text.trim().isEmpty
        ? nextKey
        : labelController.text.trim();
    final nextValue = valueController.text.trim();

    final updated = <WordFieldItem>[];
    for (final item in baseFields) {
      if (item.key == field.key && item.label == field.label) {
        updated.add(
          WordFieldItem(key: nextKey, label: nextLabel, value: nextValue),
        );
      } else {
        updated.add(item);
      }
    }

    await state.saveWord(
      original: word,
      word: word.word,
      fields: mergeFieldItems(updated),
      rawContent: word.rawContent,
    );
  }

  Future<void> _confirmDeleteField(
    BuildContext context,
    WordEntry word,
    WordFieldItem field,
  ) async {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.t('deleteFieldTitle')),
          content: Text(
            i18n.t('deleteFieldMessage', params: {'field': field.label}),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('delete')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final baseFields = word.fields.isNotEmpty
        ? word.fields
        : buildFieldItemsFromRecord(<String, Object?>{
            'meaning': word.meaning,
            'examples': word.examples,
          });
    final remained = baseFields
        .where((item) => !(item.key == field.key && item.label == field.label))
        .toList(growable: false);
    await state.saveWord(
      original: word,
      word: word.word,
      fields: remained,
      rawContent: word.rawContent,
    );
  }

  void _jumpByInitial(BuildContext context, AppState state, String initial) {
    final i18n = AppI18n(state.uiLanguage);
    final ok = state.jumpByInitial(initial);
    if (ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n.t('jumpNoMatch', params: {'value': initial})),
      ),
    );
  }

  void _jumpByPrefix(BuildContext context, AppState state, String prefix) {
    final i18n = AppI18n(state.uiLanguage);
    final ok = state.jumpByPrefix(prefix);
    if (ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(i18n.t('jumpNoMatch', params: {'value': prefix}))),
    );
  }

  Future<void> _openCreateWordbookDialog(BuildContext context) async {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.t('createWordbook')),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: i18n.t('wordbookName'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('create')),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await state.createWordbook(controller.text.trim());
    }
  }

  Future<String?> _promptWordbookNameDialog(
    BuildContext context, {
    required String title,
    required String initialName,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: initialName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return null;
    final name = controller.text.trim();
    return name.isEmpty ? null : name;
  }

  Future<void> _importWordbookWithNamePrompt(
    BuildContext context,
    AppState state,
  ) async {
    final i18n = AppI18n(state.uiLanguage);
    await state.importWordbookByPicker(
      requestName: (suggestedName) async {
        if (!context.mounted) return null;
        return _promptWordbookNameDialog(
          context,
          title: i18n.t('importWordbook'),
          initialName: suggestedName,
          confirmLabel: i18n.t('importWordbook'),
        );
      },
    );
  }

  Future<void> _exportTaskWordbookWithNamePrompt(
    BuildContext context,
    AppState state,
  ) async {
    final i18n = AppI18n(state.uiLanguage);
    final defaultName =
        'Task Export ${DateTime.now().toString().substring(0, 19)}';
    final name = await _promptWordbookNameDialog(
      context,
      title: i18n.t('exportTaskWordbook'),
      initialName: defaultName,
      confirmLabel: i18n.t('exportTaskWordbook'),
    );
    if (name == null || name.trim().isEmpty) return;
    await state.exportTaskWordbook(name.trim());
  }

  Future<void> _openWordbookWordImportDialog(
    BuildContext context,
    AppState state,
    Wordbook wordbook, {
    int initialTab = 0,
  }) async {
    if (state.selectedWordbook?.id != wordbook.id) {
      await state.selectWordbook(wordbook);
    }
    if (!context.mounted) return;

    final i18n = AppI18n(state.uiLanguage);
    final wordController = TextEditingController();
    final meaningController = TextEditingController();
    final examplesController = TextEditingController();
    final jsonController = TextEditingController(
      text:
          '[\n  {\n    "word": "example",\n    "meaning": "示例释义",\n    "examples": ["This is an example sentence."]\n  }\n]',
    );
    var activeTab = initialTab.clamp(0, 1);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          initialIndex: activeTab,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 860,
                  height: 640,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${wordbook.name} 鐠?${i18n.t('addWord')}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        onTap: (index) {
                          setStateDialog(() => activeTab = index);
                        },
                        tabs: const <Tab>[
                          Tab(text: 'Single Add'),
                          Tab(text: 'JSON Batch'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: ListView(
                                children: <Widget>[
                                  TextField(
                                    controller: wordController,
                                    decoration: InputDecoration(
                                      labelText: i18n.t('fieldWord'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: meaningController,
                                    minLines: 3,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      labelText: i18n.t('fieldMeaning'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: examplesController,
                                    minLines: 3,
                                    maxLines: 8,
                                    decoration: InputDecoration(
                                      labelText: i18n.t('fieldExamples'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: ListView(
                                children: <Widget>[
                                  const Text(
                                    '闂傚倷娴囬妴鈧柛瀣尰閵囧嫰寮介妸褉妲堥梺浼欏瘜閸ｏ綁骞冨Δ鍛仺婵炲牊瀵ч弫顖炴⒑閼恒儳澧悗姘嵆閻涱喚鈧綆鍠栭崘鈧梺闈涱煭闂勫嫰顢欏鍥╃＝闁稿本鐟чˇ锕傛倵濮樸儱濮傞柛鈹惧亾濡炪倖宸婚崑鎾绘煕婵犲啯鍊愰柟顕€缂氶ˇ鏌ユ煃缂佹ɑ宕屾俊顐㈠暙閳藉螣濞嗘儳鏁奸梻鍌欑閹诧繝鎮ч弴銏犵疇閹兼番鍔岀粻?word闂傚倷绶氬褍螞閺傚簱鏌﹂柣鎺撳彠ning闂傚倷绶氬褍螞閺冨牏鍙曢柣鐔锋▍mples闂傚倷绶氬褍螞閺冨牏鍙曢柣鐔峰墯mology闂傚倷绶氬褍螞閺冨倹瀚婚柣鐘殿煻ts闂傚倷绶氬褍螞閺傛鍟呮い褏鎯宨xes闂傚倷绶氬褍螞閺冨倻涓嶇€瑰嫭顒琲ations闂傚倷绶氬褍螞閺傚簱鏌﹂柣鎺撳敥ory闂傚倷绶氬褍螞閺冣偓瀵板嫰鎮為—绁寉闂傚倷绶氬褍螞閺冨牆绀傞柣鐐电亙lds',
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: jsonController,
                                    minLines: 20,
                                    maxLines: 26,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(i18n.t('cancel')),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                activeTab == 0
                                    ? i18n.t('save')
                                    : i18n.t('importWordbook'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    if (activeTab == 0) {
      final word = wordController.text.trim();
      if (word.isEmpty) return;
      final meaning = meaningController.text.trim();
      final examples = examplesController.text
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      final fields = buildFieldItemsFromRecord(<String, Object?>{
        'meaning': meaning.isEmpty ? null : meaning,
        'examples': examples.isEmpty ? null : examples,
      });
      await state.saveWord(
        word: word,
        fields: fields,
        rawContent: _buildRawContentFromFields(fields),
      );
      return;
    }

    try {
      final payloads = _parseBatchWordPayloads(jsonController.text);
      if (payloads.isEmpty) return;
      await state.importWordsBatch(payloads);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'JSON 闂傚倷娴囬褍霉閻戣棄鏋侀柟闂寸閸屻劎鎲搁弬璺ㄦ殾闁挎繂顦獮銏′繆椤栨繃顏犵紒鎰仱閺屸剝寰勬繝鍕拡闂佺顑呴ˇ鎶铰? $error',
          ),
        ),
      );
    }
  }

  List<WordEntryPayload> _parseBatchWordPayloads(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final items = decoded is List ? decoded : <Object?>[decoded];
    final payloads = <WordEntryPayload>[];

    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      if (entry is! Map) {
        throw FormatException('Item ${i + 1} is not an object');
      }

      final map = <String, Object?>{
        for (final kv in entry.entries) '${kv.key}': kv.value,
      };

      String word = '';
      String rawContent = '';
      for (final kv in map.entries) {
        if (isWordKey(kv.key)) {
          word = '${kv.value ?? ''}'.trim();
        } else if (rawContent.isEmpty && isContentKey(kv.key)) {
          rawContent = '${kv.value ?? ''}'.trim();
        }
      }
      if (word.isEmpty) {
        throw FormatException('Item ${i + 1} missing word field');
      }

      final fieldItems = <WordFieldItem>[];
      final fieldsRaw = map['fields'];
      if (fieldsRaw is List) {
        for (final item in fieldsRaw) {
          if (item is! Map) continue;
          final key = normalizeFieldKey('${item['key'] ?? ''}');
          if (key.isEmpty) continue;
          final label = '${item['label'] ?? key}'.trim();
          final value = normalizeFieldValue(item['value']);
          if (value == null) continue;
          fieldItems.add(
            WordFieldItem(
              key: key,
              label: label.isEmpty ? key : label,
              value: value,
            ),
          );
        }
      }

      final fieldsJsonRaw = map['fields_json'];
      if (fieldsJsonRaw is String && fieldsJsonRaw.trim().isNotEmpty) {
        fieldItems.addAll(parseFieldItemsJson(fieldsJsonRaw));
      }

      final dynamicRecord = <String, Object?>{};
      for (final kv in map.entries) {
        final lower = kv.key.toLowerCase();
        if (isWordKey(kv.key) ||
            isContentKey(kv.key) ||
            lower == 'fields' ||
            lower == 'fields_json') {
          continue;
        }
        dynamicRecord[kv.key] = kv.value;
      }
      fieldItems.addAll(buildFieldItemsFromRecord(dynamicRecord));
      final merged = mergeFieldItems(fieldItems);

      payloads.add(
        WordEntryPayload(
          word: word,
          fields: merged,
          rawContent: rawContent.isEmpty
              ? _buildRawContentFromFields(merged)
              : rawContent,
        ),
      );
    }

    return payloads;
  }

  Future<void> _openRenameWordbookDialog(
    BuildContext context,
    int wordbookId,
    String oldName,
  ) async {
    final i18n = AppI18n(context.read<AppState>().uiLanguage);
    final controller = TextEditingController(text: oldName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.t('renameWordbook')),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('save')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final state = context.read<AppState>();
    final wordbook = state.wordbooks.firstWhere(
      (item) => item.id == wordbookId,
    );
    await state.renameWordbook(wordbook, controller.text.trim());
  }

  Future<void> _confirmDeleteWordbook(
    BuildContext context,
    int wordbookId,
    String name,
  ) async {
    final i18n = AppI18n(context.read<AppState>().uiLanguage);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.t('deleteWordbook')),
          content: Text(
            i18n.t('confirmDeleteWordbook', params: {'name': name}),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('delete')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final state = context.read<AppState>();
    final wordbook = state.wordbooks.firstWhere(
      (item) => item.id == wordbookId,
    );
    await state.deleteWordbook(wordbook);
  }

  Future<void> _openMergeWordbooksDialog(
    BuildContext context,
    AppState state,
  ) async {
    final i18n = AppI18n(state.uiLanguage);
    final editableBooks = state.wordbooks
        .where((book) => !book.isSystem)
        .toList(growable: false);
    if (editableBooks.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(i18n.t('needTwoWordbooks'))));
      return;
    }

    var sourceId = editableBooks.first.id;
    var targetId = editableBooks[1].id;
    var deleteSource = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final sourceItems = editableBooks;
            final targetItems = editableBooks
                .where((book) => book.id != sourceId)
                .toList(growable: false);
            if (!targetItems.any((book) => book.id == targetId)) {
              targetId = targetItems.first.id;
            }

            return AlertDialog(
              title: Text(i18n.t('mergeDialogTitle')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<int>(
                      initialValue: sourceId,
                      decoration: InputDecoration(
                        labelText: i18n.t('sourceWordbook'),
                      ),
                      items: sourceItems
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() {
                          sourceId = value;
                          if (targetId == sourceId) {
                            final fallback = editableBooks.firstWhere(
                              (book) => book.id != sourceId,
                            );
                            targetId = fallback.id;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: targetId,
                      decoration: InputDecoration(
                        labelText: i18n.t('targetWordbook'),
                      ),
                      items: targetItems
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() => targetId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: deleteSource,
                      title: Text(i18n.t('deleteSourceAfterMerge')),
                      onChanged: (value) =>
                          setStateDialog(() => deleteSource = value),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(i18n.t('cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(i18n.t('mergeWordbooks')),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;

    await state.mergeWordbooks(
      sourceWordbookId: sourceId,
      targetWordbookId: targetId,
      deleteSourceAfterMerge: deleteSource,
    );
  }

  Future<void> _openWordEditorDialog(
    BuildContext context,
    WordEntry? existing,
  ) async {
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final wordController = TextEditingController(text: existing?.word ?? '');
    final addKeyController = TextEditingController();
    final addLabelController = TextEditingController();

    final schemaLabels = _collectFieldSchemaLabels(state.words);

    var nextFieldId = 0;
    _EditableFieldDraft createDraft({
      required String key,
      required String label,
      required String content,
      required bool startsEmptyNonCore,
    }) {
      return _EditableFieldDraft(
        id: nextFieldId++,
        key: key,
        label: label,
        content: content,
        startsEmptyNonCore: startsEmptyNonCore,
      );
    }

    final fieldDrafts = <_EditableFieldDraft>[];
    final draftMap = <String, _EditableFieldDraft>{};

    void addOrMergeDraft(_EditableFieldDraft draft) {
      final normalized = normalizeFieldKey(draft.key);
      if (normalized.isEmpty) return;
      final existingDraft = draftMap[normalized];
      if (existingDraft != null) {
        if (existingDraft.label.trim().isEmpty &&
            draft.label.trim().isNotEmpty) {
          existingDraft.label = draft.label.trim();
        }
        if (existingDraft.content.trim().isEmpty &&
            draft.content.trim().isNotEmpty) {
          existingDraft.content = draft.content.trim();
        }
        return;
      }
      draftMap[normalized] = draft;
      fieldDrafts.add(draft);
    }

    final existingItems = existing == null
        ? <WordFieldItem>[]
        : mergeFieldItems(<WordFieldItem>[
            ...existing.fields,
            ...buildFieldItemsFromRecord(<String, Object?>{
              'meaning': existing.meaning,
              'examples': existing.examples,
            }),
          ]);

    for (final item in existingItems) {
      addOrMergeDraft(
        createDraft(
          key: item.key,
          label: item.label,
          content: item.asText(),
          startsEmptyNonCore: false,
        ),
      );
    }

    for (final key in <String>['meaning', 'examples']) {
      if (draftMap.containsKey(key)) continue;
      addOrMergeDraft(
        createDraft(
          key: key,
          label: legacyFieldLabels[key] ?? key,
          content: '',
          startsEmptyNonCore: false,
        ),
      );
    }

    for (final entry in schemaLabels.entries) {
      if (draftMap.containsKey(entry.key)) continue;
      addOrMergeDraft(
        createDraft(
          key: entry.key,
          label: entry.value,
          content: '',
          startsEmptyNonCore: !_isCoreFieldKey(entry.key),
        ),
      );
    }

    fieldDrafts.sort((a, b) {
      final aCore = _isCoreFieldKey(a.key);
      final bCore = _isCoreFieldKey(b.key);
      if (aCore != bCore) return aCore ? -1 : 1;
      final aEmpty = a.content.trim().isEmpty;
      final bEmpty = b.content.trim().isEmpty;
      if (aEmpty != bEmpty) return aEmpty ? 1 : -1;
      return a.label.compareTo(b.label);
    });

    var showEmptyNonCore = false;
    var deleteRequested = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final emptyNonCoreCount = fieldDrafts
                .where(
                  (field) =>
                      !_isCoreFieldKey(field.key) &&
                      field.content.trim().isEmpty,
                )
                .length;
            final visibleFields = fieldDrafts
                .where((field) {
                  if (_isCoreFieldKey(field.key)) return true;
                  if (!field.startsEmptyNonCore) return true;
                  if (field.content.trim().isNotEmpty) return true;
                  return showEmptyNonCore;
                })
                .toList(growable: false);

            return Dialog(
              insetPadding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: LegacyStyle.border),
              ),
              child: SizedBox(
                width: 1360,
                height: 920,
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 16, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: LegacyStyle.border),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              existing == null
                                  ? i18n.t('addWordTitle')
                                  : i18n.t('editWordTitle'),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                        child: Column(
                          children: <Widget>[
                            _editorField(i18n.t('fieldWord'), wordController),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: LegacyStyle.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    i18n.t('addField'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextField(
                                          controller: addKeyController,
                                          decoration: InputDecoration(
                                            hintText: i18n.t(
                                              'fieldKeyPlaceholder',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: addLabelController,
                                          decoration: InputDecoration(
                                            hintText: i18n.t(
                                              'fieldLabelPlaceholder',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 176,
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            final keyInput = addKeyController
                                                .text
                                                .trim();
                                            final labelInput =
                                                addLabelController.text.trim();
                                            var key = normalizeFieldKey(
                                              keyInput,
                                            );
                                            if (key.isEmpty &&
                                                labelInput.isNotEmpty) {
                                              key = normalizeFieldKey(
                                                labelInput,
                                              );
                                            }
                                            if (key.isEmpty) return;

                                            final existingIndex = fieldDrafts
                                                .indexWhere(
                                                  (field) =>
                                                      normalizeFieldKey(
                                                        field.key,
                                                      ) ==
                                                      key,
                                                );
                                            setStateDialog(() {
                                              if (existingIndex >= 0) {
                                                if (labelInput.isNotEmpty) {
                                                  fieldDrafts[existingIndex]
                                                          .label =
                                                      labelInput;
                                                }
                                                showEmptyNonCore = true;
                                              } else {
                                                final label =
                                                    labelInput.isNotEmpty
                                                    ? labelInput
                                                    : (schemaLabels[key] ??
                                                          legacyFieldLabels[key] ??
                                                          key);
                                                fieldDrafts.add(
                                                  createDraft(
                                                    key: key,
                                                    label: label,
                                                    content: '',
                                                    startsEmptyNonCore: false,
                                                  ),
                                                );
                                                showEmptyNonCore = true;
                                              }
                                            });
                                            addKeyController.clear();
                                            addLabelController.clear();
                                          },
                                          icon: const Icon(Icons.add),
                                          label: Text(i18n.t('addField')),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (emptyNonCoreCount > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                decoration: LegacyStyle.cardDecoration,
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        i18n.t(
                                          'emptyFieldsDetected',
                                          params: {'count': emptyNonCoreCount},
                                        ),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setStateDialog(() {
                                          showEmptyNonCore = !showEmptyNonCore;
                                        });
                                      },
                                      icon: Icon(
                                        showEmptyNonCore
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                      label: Text(
                                        showEmptyNonCore
                                            ? i18n.t('collapseEmptyFields')
                                            : i18n.t('expandEmptyFields'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            for (final field in visibleFields) ...[
                              _EditableFieldCard(
                                field: field,
                                i18n: i18n,
                                onChanged: () {
                                  setStateDialog(() {});
                                },
                                onDelete: _isCoreFieldKey(field.key)
                                    ? null
                                    : () {
                                        setStateDialog(() {
                                          fieldDrafts.removeWhere(
                                            (item) => item.id == field.id,
                                          );
                                        });
                                      },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: LegacyStyle.border),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          if (existing != null)
                            IconButton(
                              onPressed: () {
                                deleteRequested = true;
                                Navigator.pop(context, true);
                              },
                              tooltip: i18n.t('deleteWordInEditor'),
                              color: Colors.red.shade700,
                              icon: const Icon(Icons.delete_outline),
                            ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(i18n.t('cancel')),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.save_outlined),
                            label: Text(i18n.t('save')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final wordText = wordController.text.trim();
    wordController.dispose();
    addKeyController.dispose();
    addLabelController.dispose();

    if (confirmed != true) return;
    if (!context.mounted) return;

    if (deleteRequested && existing != null) {
      await _confirmDeleteWord(context, existing);
      return;
    }

    final normalizedFields = _normalizeFieldDrafts(fieldDrafts);
    final rawContent = _buildRawContentFromFields(normalizedFields);

    await state.saveWord(
      original: existing,
      word: wordText,
      fields: normalizedFields,
      rawContent: rawContent,
    );
  }

  Map<String, String> _collectFieldSchemaLabels(List<WordEntry> words) {
    final labels = <String, String>{};
    for (final word in words) {
      for (final field in word.fields) {
        final key = normalizeFieldKey(field.key);
        if (key.isEmpty) continue;
        final label = field.label.trim().isEmpty ? key : field.label.trim();
        labels.putIfAbsent(key, () => label);
      }
    }
    return labels;
  }

  List<WordFieldItem> _normalizeFieldDrafts(List<_EditableFieldDraft> drafts) {
    final items = <WordFieldItem>[];
    for (final draft in drafts) {
      final key = normalizeFieldKey(draft.key);
      if (key.isEmpty) continue;
      final content = draft.content.trim();
      if (content.isEmpty) continue;
      final label = draft.label.trim().isEmpty
          ? (legacyFieldLabels[key] ?? key)
          : draft.label.trim();

      Object value = content;
      if (key == 'examples') {
        final rows = content
            .split(RegExp(r'\r?\n'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        value = rows.isEmpty ? content : rows;
      }

      items.add(WordFieldItem(key: key, label: label, value: value));
    }
    return mergeFieldItems(items);
  }

  String _buildRawContentFromFields(List<WordFieldItem> fields) {
    final sections = fields
        .where((field) {
          final key = normalizeFieldKey(field.key);
          return !_isCoreFieldKey(key) && field.asText().trim().isNotEmpty;
        })
        .map((field) => '### ${field.label}\n${field.asText().trim()}')
        .toList(growable: false);
    return sections.join('\n\n');
  }

  bool _isCoreFieldKey(String key) {
    final normalized = normalizeFieldKey(key);
    return normalized == 'meaning' ||
        normalized == 'examples' ||
        normalized == 'spelling';
  }

  Widget _editorField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _confirmDeleteWord(BuildContext context, WordEntry word) async {
    final i18n = AppI18n(context.read<AppState>().uiLanguage);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.t('delete')),
          content: Text(
            i18n.t('confirmDeleteWord', params: {'word': word.word}),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('delete')),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteWord(word);
    }
  }

  Future<void> _openFollowAlongDialog(
    BuildContext context,
    AppState state,
    WordEntry word,
  ) async {
    final i18n = AppI18n(state.uiLanguage);
    if (!state.config.asr.enabled) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(i18n.t('enableAsrFirst'))));
      return;
    }

    final shouldResumePlayback = state.isPlaying && !state.isPaused;
    if (shouldResumePlayback) {
      await state.pauseOrResume();
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _FollowAlongDialog(state: state, word: word),
    );

    await state.cancelAsrRecording();
    state.stopAsrProcessing();

    if (shouldResumePlayback && state.isPlaying && state.isPaused) {
      await state.pauseOrResume();
    }
  }

  Future<void> _openSettingsDialog(BuildContext context, AppState state) async {
    var draft = state.config;
    final localVoices = await state.fetchLocalTtsVoices();
    if (!context.mounted) return;
    final coreRepeats = Map<String, int>.from(draft.repeats);
    final fieldSettings = Map<String, FieldPlaybackSetting>.from(
      draft.fieldSettings,
    );
    final ttsApiKeyController = TextEditingController(
      text: draft.tts.apiKey ?? '',
    );
    final ttsApiBaseUrlController = TextEditingController(
      text: draft.tts.baseUrl ?? '',
    );
    final ttsCustomModelController = TextEditingController(
      text: draft.tts.model ?? '',
    );
    final asrApiKeyController = TextEditingController(
      text: draft.asr.apiKey ?? '',
    );
    final asrApiBaseUrlController = TextEditingController(
      text: draft.asr.baseUrl ?? '',
    );
    final asrModelController = TextEditingController(text: draft.asr.model);
    final asrLanguageController = TextEditingController(
      text: draft.asr.language,
    );
    var asrLanguageCustomMode =
        _resolveAsrLanguageOption(draft.asr.language) == 'custom';
    final delayController = TextEditingController(
      text: '${draft.delayBetweenUnitsMs}',
    );
    var nonCoreBatchRepeat = 0;

    final nonCoreFieldKeys = <String>{};
    for (final word in state.words) {
      for (final field in word.fields) {
        final key = normalizeFieldKey(field.key);
        if (key.isEmpty) continue;
        if (_isCoreFieldKey(key)) continue;
        nonCoreFieldKeys.add(key);
      }
    }
    if (nonCoreFieldKeys.isEmpty) {
      nonCoreFieldKeys.addAll(<String>[
        'etymology',
        'roots',
        'affixes',
        'variations',
        'memory',
        'story',
      ]);
    }
    final nonCoreRepeats = <String, int>{
      for (final key in nonCoreFieldKeys)
        key:
            fieldSettings[key]?.repeat ??
            (coreRepeats.containsKey(key) ? coreRepeats[key]! : 0),
    };
    var appearanceThemeDraft = 'flat';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final draftI18n = AppI18n(state.uiLanguage);
              return Dialog(
                insetPadding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: LegacyStyle.border),
                ),
                child: SizedBox(
                  width: 1240,
                  height: 820,
                  child: Column(
                    children: <Widget>[
                      _settingsDialogHeader(
                        context: context,
                        title: draftI18n.t('settings'),
                        onClose: () => Navigator.pop(context, false),
                      ),
                      TabBar(
                        tabs: <Tab>[
                          Tab(text: draftI18n.t('settingsTabPlayback')),
                          Tab(text: draftI18n.t('settingsTabVoice')),
                          Tab(text: draftI18n.t('settingsTabAsr')),
                          Tab(text: draftI18n.t('settingsTabAppearance')),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: <Widget>[
                            _settingsPlaybackTab(
                              draft: draft,
                              draftI18n: draftI18n,
                              coreRepeats: coreRepeats,
                              nonCoreRepeats: nonCoreRepeats,
                              delayController: delayController,
                              nonCoreBatchRepeat: nonCoreBatchRepeat,
                              onDraftChanged: (next) {
                                setStateDialog(() => draft = next);
                              },
                              onCoreRepeatChanged: (key, value) {
                                setStateDialog(() => coreRepeats[key] = value);
                              },
                              onApplyNonCoreRepeat: () {
                                setStateDialog(() {
                                  for (final key in nonCoreRepeats.keys) {
                                    nonCoreRepeats[key] = nonCoreBatchRepeat
                                        .clamp(0, 20);
                                  }
                                });
                              },
                              onNonCoreRepeatChanged: (key, value) {
                                setStateDialog(
                                  () => nonCoreRepeats[key] = value,
                                );
                              },
                              onNonCoreBatchRepeatChanged: (value) {
                                setStateDialog(
                                  () => nonCoreBatchRepeat = value.clamp(0, 20),
                                );
                              },
                            ),
                            _settingsVoiceTab(
                              draft: draft,
                              draftI18n: draftI18n,
                              localVoices: localVoices,
                              ttsApiKeyController: ttsApiKeyController,
                              ttsApiBaseUrlController: ttsApiBaseUrlController,
                              ttsCustomModelController:
                                  ttsCustomModelController,
                              onDraftChanged: (next) {
                                setStateDialog(() => draft = next);
                              },
                            ),
                            _settingsAsrTab(
                              draft: draft,
                              draftI18n: draftI18n,
                              asrLanguageController: asrLanguageController,
                              asrModelController: asrModelController,
                              asrApiKeyController: asrApiKeyController,
                              asrApiBaseUrlController: asrApiBaseUrlController,
                              asrLanguageCustomMode: asrLanguageCustomMode,
                              onAsrLanguageCustomModeChanged: (value) {
                                setStateDialog(
                                  () => asrLanguageCustomMode = value,
                                );
                              },
                              onDraftChanged: (next) {
                                setStateDialog(() => draft = next);
                              },
                            ),
                            _settingsAppearanceTab(
                              draftI18n: draftI18n,
                              selectedTheme: appearanceThemeDraft,
                              onThemeChanged: (value) {
                                setStateDialog(
                                  () => appearanceThemeDraft = value,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(draftI18n.t('cancel')),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(draftI18n.t('saveAndApply')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (confirmed == true) {
      final delayMs = int.tryParse(delayController.text.trim());
      final mergedFieldSettings = Map<String, FieldPlaybackSetting>.from(
        fieldSettings,
      );
      for (final entry in nonCoreRepeats.entries) {
        final repeat = entry.value.clamp(0, 20);
        mergedFieldSettings[entry.key] =
            (mergedFieldSettings[entry.key] ?? const FieldPlaybackSetting())
                .copyWith(
                  repeat: repeat,
                  enabled: repeat > 0,
                  label: mergedFieldSettings[entry.key]?.label ?? entry.key,
                );
        if (coreRepeats.containsKey(entry.key)) {
          coreRepeats[entry.key] = repeat;
        }
      }

      final nextTts = _sanitizeTtsConfig(
        draft.tts.copyWith(
          apiKey: ttsApiKeyController.text.trim(),
          baseUrl: ttsApiBaseUrlController.text.trim(),
          model: draft.tts.provider == TtsProviderType.customApi
              ? ttsCustomModelController.text.trim()
              : draft.tts.model,
        ),
        localVoices: localVoices,
      );
      final nextDraft = draft.copyWith(
        repeats: coreRepeats,
        fieldSettings: mergedFieldSettings,
        delayBetweenUnitsMs: delayMs ?? draft.delayBetweenUnitsMs,
        tts: nextTts,
        asr: draft.asr.copyWith(
          apiKey:
              (draft.asr.provider == AsrProviderType.api ||
                  draft.asr.provider == AsrProviderType.customApi)
              ? asrApiKeyController.text.trim()
              : draft.asr.apiKey,
          model:
              (draft.asr.provider == AsrProviderType.api ||
                  draft.asr.provider == AsrProviderType.customApi)
              ? (asrModelController.text.trim().isEmpty
                    ? draft.asr.model
                    : asrModelController.text.trim())
              : draft.asr.model,
          language: asrLanguageController.text.trim().isEmpty
              ? draft.asr.language
              : asrLanguageController.text.trim(),
          baseUrl: draft.asr.provider == AsrProviderType.customApi
              ? asrApiBaseUrlController.text.trim()
              : draft.asr.baseUrl,
        ),
      );
      if (mounted) {
        state.updateConfig(nextDraft);
      }
    }

    // Intentionally keep controllers undisposed here to avoid transient
    // "used after being disposed" during dialog dismiss animations.
  }

  _TtsApiModelOption _resolveApiTtsModel(String? id) {
    final resolvedId = id?.trim() ?? '';
    for (final model in _ttsApiModels) {
      if (model.id == resolvedId) return model;
    }
    return _ttsApiModels.first;
  }

  TtsConfig _sanitizeTtsConfig(
    TtsConfig draftTts, {
    required List<String> localVoices,
  }) {
    final provider = draftTts.provider;
    final trimmedLocalVoice = draftTts.localVoice.trim();
    final trimmedRemoteVoice = draftTts.remoteVoice.trim();
    final trimmedApiKey = (draftTts.apiKey ?? '').trim();
    final trimmedBaseUrl = (draftTts.baseUrl ?? '').trim();

    if (provider == TtsProviderType.local) {
      final localVoice = localVoices.isEmpty
          ? trimmedLocalVoice
          : localVoices.contains(trimmedLocalVoice)
          ? trimmedLocalVoice
          : '';
      return draftTts.copyWith(
        voice: localVoice,
        localVoice: localVoice,
        language: 'auto',
        apiKey: trimmedApiKey,
      );
    }

    if (provider == TtsProviderType.api) {
      final model = _resolveApiTtsModel(draftTts.model);
      final options = model.voices;
      final remoteVoice = options.contains(trimmedRemoteVoice)
          ? trimmedRemoteVoice
          : options.first;
      return draftTts.copyWith(
        model: model.id,
        voice: remoteVoice,
        remoteVoice: remoteVoice,
        remoteVoiceTypes: <String>[remoteVoice],
        language: 'auto',
        apiKey: trimmedApiKey,
      );
    }

    final customModel = (draftTts.model ?? '').trim().isEmpty
        ? _resolveApiTtsModel(null).id
        : draftTts.model!.trim();
    final options = _resolveApiTtsModel(customModel).voices;
    final fallbackVoice = options.isNotEmpty ? options.first : 'alex';
    final remoteVoice = trimmedRemoteVoice.isNotEmpty
        ? trimmedRemoteVoice
        : fallbackVoice;

    return draftTts.copyWith(
      model: customModel,
      baseUrl: trimmedBaseUrl,
      voice: remoteVoice,
      remoteVoice: remoteVoice,
      remoteVoiceTypes: <String>[remoteVoice],
      language: 'auto',
      apiKey: trimmedApiKey,
    );
  }

  List<String> _resolveRemoteVoiceOptions(TtsConfig tts) {
    final modelVoices = _resolveApiTtsModel(tts.model).voices;
    final merged = <String>[];
    void addItem(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return;
      if (!merged.contains(value)) merged.add(value);
    }

    for (final item in modelVoices) {
      addItem(item);
    }
    addItem(tts.remoteVoice);
    if (merged.isEmpty) {
      addItem('alex');
    }
    return merged;
  }

  String _resolveAsrLanguageOption(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.isEmpty || normalized == 'auto') return 'auto';
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('zh')) return 'zh';
    if (normalized.startsWith('ja')) return 'ja';
    if (normalized.startsWith('fr')) return 'fr';
    if (normalized.startsWith('de')) return 'de';
    if (normalized.startsWith('es')) return 'es';
    return 'custom';
  }

  Future<void> _showAsrOfflineNotice({
    required BuildContext context,
    required AppI18n i18n,
    required AsrProviderType provider,
  }) async {
    final sizeHint = _asrOfflineModelSizeHints[provider] ?? '~150 MB';
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(i18n.t('asrOfflineNoticeTitle')),
          content: Text(
            i18n.t(
              'asrOfflineNoticeBody',
              params: <String, Object?>{'size': sizeHint},
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(i18n.t('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _settingsDialogHeader({
    required BuildContext context,
    required String title,
    required VoidCallback onClose,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 14, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LegacyStyle.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _settingsPlaybackTab({
    required PlayConfig draft,
    required AppI18n draftI18n,
    required Map<String, int> coreRepeats,
    required Map<String, int> nonCoreRepeats,
    required TextEditingController delayController,
    required int nonCoreBatchRepeat,
    required ValueChanged<PlayConfig> onDraftChanged,
    required void Function(String key, int value) onCoreRepeatChanged,
    required VoidCallback onApplyNonCoreRepeat,
    required void Function(String key, int value) onNonCoreRepeatChanged,
    required ValueChanged<int> onNonCoreBatchRepeatChanged,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: delayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: draftI18n.t('delayBetweenUnits'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${draftI18n.t('playbackVolume')}: ${(draft.tts.volume * 100).round()}%',
          ),
          Slider(
            value: draft.tts.volume.clamp(0, 1),
            onChanged: (value) => onDraftChanged(
              draft.copyWith(tts: draft.tts.copyWith(volume: value)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${draftI18n.t('playbackSpeed')}: ${draft.tts.speed.toStringAsFixed(2)}x',
          ),
          Slider(
            value: draft.tts.speed.clamp(0.5, 2.0),
            min: 0.5,
            max: 2.0,
            divisions: 30,
            onChanged: (value) => onDraftChanged(
              draft.copyWith(
                tts: draft.tts.copyWith(
                  speed: (value * 100).roundToDouble() / 100,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.showText,
            onChanged: (value) =>
                onDraftChanged(draft.copyWith(showText: value)),
            title: Text(draftI18n.t('showText')),
          ),
          const SizedBox(height: 8),
          Text(
            draftI18n.t('coreRepeat'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _repeatRow(
            draftI18n.t('wordRepeat'),
            coreRepeats['word'] ?? 1,
            (value) => onCoreRepeatChanged('word', value),
          ),
          _repeatRow(
            draftI18n.t('meaningRepeat'),
            coreRepeats['meaning'] ?? 1,
            (value) => onCoreRepeatChanged('meaning', value),
          ),
          _repeatRow(
            draftI18n.t('exampleRepeat'),
            coreRepeats['example'] ?? 1,
            (value) => onCoreRepeatChanged('example', value),
          ),
          _repeatRow(
            draftI18n.t('spellingLabel'),
            coreRepeats['spelling'] ?? 0,
            (value) => onCoreRepeatChanged('spelling', value),
          ),
          _repeatRow(
            draftI18n.t('overallLoop'),
            draft.overallRepeat,
            (value) => onDraftChanged(draft.copyWith(overallRepeat: value)),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: Text(
              draftI18n.t('nonCoreRepeat'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => onNonCoreBatchRepeatChanged(
                      (nonCoreBatchRepeat - 1).clamp(0, 20),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$nonCoreBatchRepeat',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => onNonCoreBatchRepeatChanged(
                      (nonCoreBatchRepeat + 1).clamp(0, 20),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: onApplyNonCoreRepeat,
                    child: Text(draftI18n.t('applyToAllNonCore')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final key in nonCoreRepeats.keys.toList()..sort())
                _repeatRow(
                  key,
                  nonCoreRepeats[key] ?? 0,
                  (value) => onNonCoreRepeatChanged(key, value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsVoiceTab({
    required PlayConfig draft,
    required AppI18n draftI18n,
    required List<String> localVoices,
    required TextEditingController ttsApiKeyController,
    required TextEditingController ttsApiBaseUrlController,
    required TextEditingController ttsCustomModelController,
    required ValueChanged<PlayConfig> onDraftChanged,
  }) {
    final currentModel = _resolveApiTtsModel(draft.tts.model);
    final provider = draft.tts.provider;
    final isRemote = provider != TtsProviderType.local;
    final isPresetApi = provider == TtsProviderType.api;
    final isCustomApi = provider == TtsProviderType.customApi;
    final remoteVoiceOptions = _resolveRemoteVoiceOptions(draft.tts);
    final selectedLocalVoice = localVoices.isEmpty
        ? draft.tts.localVoice.trim()
        : localVoices.contains(draft.tts.localVoice.trim())
        ? draft.tts.localVoice.trim()
        : '';
    final selectedRemoteVoice =
        remoteVoiceOptions.contains(draft.tts.remoteVoice.trim())
        ? draft.tts.remoteVoice.trim()
        : (remoteVoiceOptions.isEmpty ? 'alex' : remoteVoiceOptions.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<TtsProviderType>(
            initialValue: draft.tts.provider,
            decoration: InputDecoration(labelText: draftI18n.t('ttsProvider')),
            items: <DropdownMenuItem<TtsProviderType>>[
              DropdownMenuItem(
                value: TtsProviderType.local,
                child: Text(draftI18n.t('local')),
              ),
              DropdownMenuItem(
                value: TtsProviderType.api,
                child: Text(draftI18n.t('siliconFlowApi')),
              ),
              DropdownMenuItem(
                value: TtsProviderType.customApi,
                child: Text(draftI18n.t('customApi')),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              if (value == TtsProviderType.local) {
                final localVoice = localVoices.isEmpty
                    ? draft.tts.localVoice.trim()
                    : localVoices.contains(draft.tts.localVoice.trim())
                    ? draft.tts.localVoice.trim()
                    : '';
                onDraftChanged(
                  draft.copyWith(
                    tts: draft.tts.copyWith(
                      provider: value,
                      voice: localVoice,
                      localVoice: localVoice,
                      language: 'auto',
                    ),
                  ),
                );
                return;
              }

              if (value == TtsProviderType.api) {
                final model = _resolveApiTtsModel(draft.tts.model);
                final options = model.voices;
                final remoteVoice = options.contains(draft.tts.remoteVoice)
                    ? draft.tts.remoteVoice
                    : options.first;
                ttsCustomModelController.text = model.id;
                onDraftChanged(
                  draft.copyWith(
                    tts: draft.tts.copyWith(
                      provider: value,
                      model: model.id,
                      voice: remoteVoice,
                      remoteVoice: remoteVoice,
                      remoteVoiceTypes: <String>[remoteVoice],
                      language: 'auto',
                    ),
                  ),
                );
                return;
              }

              final options = _resolveRemoteVoiceOptions(
                draft.tts.copyWith(provider: TtsProviderType.customApi),
              );
              final remoteVoice = draft.tts.remoteVoice.trim().isNotEmpty
                  ? draft.tts.remoteVoice.trim()
                  : (options.isEmpty ? 'alex' : options.first);
              if (ttsCustomModelController.text.trim().isEmpty) {
                ttsCustomModelController.text =
                    draft.tts.model?.trim().isNotEmpty == true
                    ? draft.tts.model!.trim()
                    : _resolveApiTtsModel(null).id;
              }
              onDraftChanged(
                draft.copyWith(
                  tts: draft.tts.copyWith(
                    provider: value,
                    model: ttsCustomModelController.text.trim().isEmpty
                        ? draft.tts.model
                        : ttsCustomModelController.text.trim(),
                    voice: remoteVoice,
                    remoteVoice: remoteVoice,
                    remoteVoiceTypes: <String>[remoteVoice],
                    language: 'auto',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          if (isPresetApi) ...<Widget>[
            DropdownButtonFormField<String>(
              initialValue: currentModel.id,
              decoration: InputDecoration(labelText: draftI18n.t('ttsModel')),
              items: _ttsApiModels
                  .map(
                    (model) => DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(model.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                final model = _resolveApiTtsModel(value);
                final nextVoice = model.voices.contains(draft.tts.remoteVoice)
                    ? draft.tts.remoteVoice
                    : model.voices.first;
                onDraftChanged(
                  draft.copyWith(
                    tts: draft.tts.copyWith(
                      model: model.id,
                      voice: nextVoice,
                      remoteVoice: nextVoice,
                      remoteVoiceTypes: <String>[nextVoice],
                      language: 'auto',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          if (provider == TtsProviderType.local)
            DropdownButtonFormField<String>(
              initialValue: selectedLocalVoice,
              decoration: InputDecoration(labelText: draftI18n.t('voice')),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(draftI18n.t('defaultVoice')),
                ),
                if (selectedLocalVoice.isNotEmpty &&
                    !localVoices.contains(selectedLocalVoice))
                  DropdownMenuItem<String>(
                    value: selectedLocalVoice,
                    child: Text(selectedLocalVoice),
                  ),
                ...localVoices.map(
                  (voice) => DropdownMenuItem<String>(
                    value: voice,
                    child: Text(voice),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onDraftChanged(
                  draft.copyWith(
                    tts: draft.tts.copyWith(
                      voice: value,
                      localVoice: value,
                      language: 'auto',
                    ),
                  ),
                );
              },
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedRemoteVoice,
              decoration: InputDecoration(labelText: draftI18n.t('voice')),
              items: remoteVoiceOptions
                  .map(
                    (voice) => DropdownMenuItem<String>(
                      value: voice,
                      child: Text(voice),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                onDraftChanged(
                  draft.copyWith(
                    tts: draft.tts.copyWith(
                      voice: value,
                      remoteVoice: value,
                      remoteVoiceTypes: <String>[value],
                      language: 'auto',
                    ),
                  ),
                );
              },
            ),
          if (isCustomApi) ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: ttsApiBaseUrlController,
              decoration: InputDecoration(
                labelText: draftI18n.t('ttsApiBaseUrl'),
              ),
              onChanged: (value) {
                onDraftChanged(
                  draft.copyWith(
                    tts: draft.tts.copyWith(baseUrl: value.trim()),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ttsCustomModelController,
              decoration: InputDecoration(
                labelText: draftI18n.t('ttsModel'),
                hintText: draftI18n.t('ttsModelIdHint'),
              ),
              onChanged: (value) {
                onDraftChanged(
                  draft.copyWith(tts: draft.tts.copyWith(model: value.trim())),
                );
              },
            ),
          ],
          if (isRemote) ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: ttsApiKeyController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(labelText: draftI18n.t('ttsApiKey')),
            ),
          ],
          if (provider == TtsProviderType.local &&
              localVoices.isEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                draftI18n.t('localVoicesNotFound'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LegacyStyle.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _settingsAsrTab({
    required PlayConfig draft,
    required AppI18n draftI18n,
    required TextEditingController asrLanguageController,
    required TextEditingController asrModelController,
    required TextEditingController asrApiKeyController,
    required TextEditingController asrApiBaseUrlController,
    required bool asrLanguageCustomMode,
    required ValueChanged<bool> onAsrLanguageCustomModeChanged,
    required ValueChanged<PlayConfig> onDraftChanged,
  }) {
    final provider = draft.asr.provider;
    final isApiProvider =
        provider == AsrProviderType.api ||
        provider == AsrProviderType.customApi;
    final isCustomApi = provider == AsrProviderType.customApi;
    final resolvedAsrLanguageOption = _resolveAsrLanguageOption(
      asrLanguageController.text,
    );
    final asrLanguageOption = asrLanguageCustomMode
        ? 'custom'
        : resolvedAsrLanguageOption;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.asr.enabled,
            title: Text(draftI18n.t('enableAsr')),
            onChanged: (enabled) {
              onDraftChanged(
                draft.copyWith(asr: draft.asr.copyWith(enabled: enabled)),
              );
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AsrProviderType>(
            initialValue: draft.asr.provider,
            decoration: InputDecoration(labelText: draftI18n.t('asrProvider')),
            items: <DropdownMenuItem<AsrProviderType>>[
              DropdownMenuItem(
                value: AsrProviderType.api,
                child: Text(draftI18n.t('siliconFlowApi')),
              ),
              DropdownMenuItem(
                value: AsrProviderType.customApi,
                child: Text(draftI18n.t('customApi')),
              ),
              DropdownMenuItem(
                value: AsrProviderType.offline,
                child: Text(draftI18n.t('offlineWhisperBase')),
              ),
              DropdownMenuItem(
                value: AsrProviderType.offlineSmall,
                child: Text(draftI18n.t('offlineWhisperSmall')),
              ),
            ],
            onChanged: (value) async {
              if (value == null) return;
              if (value == AsrProviderType.offline ||
                  value == AsrProviderType.offlineSmall) {
                await _showAsrOfflineNotice(
                  context: context,
                  i18n: draftI18n,
                  provider: value,
                );
              }
              onDraftChanged(
                draft.copyWith(asr: draft.asr.copyWith(provider: value)),
              );
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: asrLanguageOption,
            decoration: InputDecoration(labelText: draftI18n.t('asrLanguage')),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: 'auto',
                child: Text(draftI18n.t('asrLanguageAuto')),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(draftI18n.t('asrLanguageEnglish')),
              ),
              DropdownMenuItem(
                value: 'zh',
                child: Text(draftI18n.t('asrLanguageChinese')),
              ),
              DropdownMenuItem(
                value: 'ja',
                child: Text(draftI18n.t('asrLanguageJapanese')),
              ),
              DropdownMenuItem(
                value: 'fr',
                child: Text(draftI18n.t('asrLanguageFrench')),
              ),
              DropdownMenuItem(
                value: 'de',
                child: Text(draftI18n.t('asrLanguageGerman')),
              ),
              DropdownMenuItem(
                value: 'es',
                child: Text(draftI18n.t('asrLanguageSpanish')),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text(draftI18n.t('asrLanguageCustom')),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              if (value == 'custom') {
                onAsrLanguageCustomModeChanged(true);
                return;
              }
              onAsrLanguageCustomModeChanged(false);
              asrLanguageController.text = value;
              onDraftChanged(
                draft.copyWith(asr: draft.asr.copyWith(language: value)),
              );
            },
          ),
          if (asrLanguageOption == 'custom' ||
              resolvedAsrLanguageOption == 'custom') ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: asrLanguageController,
              decoration: InputDecoration(
                labelText: draftI18n.t('asrLanguageCustomInput'),
                hintText: 'e.g. pt-BR / it',
              ),
              onChanged: (value) {
                onDraftChanged(
                  draft.copyWith(asr: draft.asr.copyWith(language: value)),
                );
              },
            ),
          ],
          if (isCustomApi) ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: asrApiBaseUrlController,
              decoration: InputDecoration(
                labelText: draftI18n.t('asrApiBaseUrl'),
              ),
              onChanged: (value) {
                onDraftChanged(
                  draft.copyWith(
                    asr: draft.asr.copyWith(baseUrl: value.trim()),
                  ),
                );
              },
            ),
          ],
          if (isApiProvider) ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: asrModelController,
              decoration: InputDecoration(labelText: draftI18n.t('asrModel')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: asrApiKeyController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(labelText: draftI18n.t('asrApiKey')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _settingsAppearanceTab({
    required AppI18n draftI18n,
    required String selectedTheme,
    required ValueChanged<String> onThemeChanged,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: <Widget>[
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              draftI18n.t('appearanceThemeTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    <String>[
                          'flat',
                          'tech',
                          'dark',
                          'fantasy',
                          'nature',
                          'sunset',
                          'ocean',
                          'mono',
                        ]
                        .map((theme) {
                          final selected = selectedTheme == theme;
                          return InkWell(
                            onTap: () => onThemeChanged(theme),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 148,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? LegacyStyle.primary
                                      : LegacyStyle.border,
                                ),
                                color: selected
                                    ? LegacyStyle.primary.withValues(
                                        alpha: 0.08,
                                      )
                                    : Colors.transparent,
                              ),
                              child: Text(_themeLabel(draftI18n, theme)),
                            ),
                          );
                        })
                        .toList(growable: false),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              draftI18n.t('appearanceLayoutTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(draftI18n.t('appearanceLayoutHint')),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              draftI18n.t('appearanceColorsTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(draftI18n.t('appearanceColorsHint')),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              draftI18n.t('appearanceBackgroundTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(draftI18n.t('appearanceBackgroundHint')),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              draftI18n.t('appearanceFieldSectionsTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(draftI18n.t('appearanceFieldSectionsHint')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppI18n i18n, String themeKey) => switch (themeKey) {
    'flat' => i18n.t('themeFlat'),
    'tech' => i18n.t('themeTech'),
    'dark' => i18n.t('themeDark'),
    'fantasy' => i18n.t('themeFantasy'),
    'nature' => i18n.t('themeNature'),
    'sunset' => i18n.t('themeSunset'),
    'ocean' => i18n.t('themeOcean'),
    'mono' => i18n.t('themeMono'),
    _ => themeKey,
  };
  Widget _repeatRow(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: LegacyStyle.cardDecoration,
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          IconButton(
            onPressed: () => onChanged((value - 1).clamp(0, 20)),
            icon: const Icon(Icons.remove),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            onPressed: () => onChanged((value + 1).clamp(0, 20)),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _openAmbientDialog(BuildContext context, AppState state) async {
    final i18n = AppI18n(state.uiLanguage);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final sources = state.ambientSources;
            final active = sources
                .where((source) => source.enabled)
                .toList(growable: false);
            final builtins = sources
                .where((source) => source.isAsset)
                .toList(growable: false);
            final imported = sources
                .where((source) => !source.isAsset)
                .toList(growable: false);

            String categoryOf(String id) {
              if (id.startsWith('noise_')) {
                return i18n.t('ambientCategoryNoise');
              }
              if (id.startsWith('nature_')) {
                return i18n.t('ambientCategoryNature');
              }
              if (id.startsWith('rain_')) return i18n.t('ambientCategoryRain');
              return i18n.t('ambientCategoryFocus');
            }

            final categories = <String, List<dynamic>>{};
            for (final source in builtins) {
              final category = categoryOf(source.id);
              categories.putIfAbsent(category, () => <dynamic>[]).add(source);
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: LegacyStyle.border),
              ),
              child: SizedBox(
                width: 1400,
                height: 820,
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: LegacyStyle.border),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            i18n.t('ambientAudio'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              if (active.isEmpty) {
                                final first = sources.firstOrNull;
                                if (first != null) {
                                  await state.setAmbientSourceEnabled(
                                    first.id,
                                    true,
                                  );
                                }
                              } else {
                                for (final source in active) {
                                  await state.setAmbientSourceEnabled(
                                    source.id,
                                    false,
                                  );
                                }
                              }
                              setStateDialog(() {});
                            },
                            icon: Icon(
                              active.isEmpty ? Icons.play_arrow : Icons.pause,
                            ),
                            label: Text(
                              active.isEmpty
                                  ? i18n.t('resume')
                                  : i18n.t('pause'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              await state.addAmbientFileSource();
                              setStateDialog(() {});
                            },
                            icon: const Icon(Icons.library_music_outlined),
                            label: Text(i18n.t('importAudio')),
                          ),
                          const Spacer(),
                          Text(
                            '${i18n.t('currentPlayingList')}: ${active.length}',
                            style: const TextStyle(
                              color: LegacyStyle.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(i18n.t('close')),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${i18n.t('masterVolume')}: ${(state.ambientMasterVolume * 100).round()}%',
                                  ),
                                  Slider(
                                    value: state.ambientMasterVolume,
                                    min: 0,
                                    max: 1,
                                    divisions: 100,
                                    onChanged: (value) async {
                                      await state.setAmbientMasterVolume(value);
                                      setStateDialog(() {});
                                    },
                                  ),
                                  const Divider(),
                                  for (final category in categories.keys) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 6,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: categories[category]!
                                          .map((item) {
                                            final source = item;
                                            final enabled =
                                                source.enabled as bool;
                                            return InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              onTap: () async {
                                                await state
                                                    .setAmbientSourceEnabled(
                                                      source.id as String,
                                                      !enabled,
                                                    );
                                                setStateDialog(() {});
                                              },
                                              child: Container(
                                                width: 320,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: enabled
                                                        ? LegacyStyle.primary
                                                        : LegacyStyle.border,
                                                  ),
                                                  color: enabled
                                                      ? LegacyStyle.primary
                                                            .withValues(
                                                              alpha: 0.07,
                                                            )
                                                      : Colors.white,
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      enabled
                                                          ? Icons.check_box
                                                          : Icons
                                                                .check_box_outline_blank,
                                                      color: enabled
                                                          ? LegacyStyle.primary
                                                          : LegacyStyle
                                                                .textSecondary,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        source.name as String,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(growable: false),
                                    ),
                                  ],
                                  if (imported.isNotEmpty) ...[
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 6,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        i18n.t('importedAudio'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    for (final source in imported)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(source.name),
                                        leading: Switch(
                                          value: source.enabled,
                                          onChanged: (enabled) async {
                                            await state.setAmbientSourceEnabled(
                                              source.id,
                                              enabled,
                                            );
                                            setStateDialog(() {});
                                          },
                                        ),
                                        trailing: IconButton(
                                          onPressed: () async {
                                            await state.removeAmbientSource(
                                              source.id,
                                            );
                                            setStateDialog(() {});
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    i18n.t('currentPlayingList'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  if (active.isEmpty)
                                    Expanded(
                                      child: Center(
                                        child: Text(i18n.t('noAudioSources')),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: active.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final source = active[index];
                                          return Container(
                                            decoration:
                                                LegacyStyle.cardDecoration,
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Text(source.name),
                                                    ),
                                                    IconButton(
                                                      onPressed: () async {
                                                        if (!source.isAsset) {
                                                          await state
                                                              .removeAmbientSource(
                                                                source.id,
                                                              );
                                                        } else {
                                                          await state
                                                              .setAmbientSourceEnabled(
                                                                source.id,
                                                                false,
                                                              );
                                                        }
                                                        setStateDialog(() {});
                                                      },
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Slider(
                                                  value: source.volume,
                                                  min: 0,
                                                  max: 1,
                                                  divisions: 100,
                                                  onChanged: (value) async {
                                                    await state
                                                        .setAmbientSourceVolume(
                                                          source.id,
                                                          value,
                                                        );
                                                    setStateDialog(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: LegacyStyle.panelDecoration,
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}

class _SideMenuPanel extends StatelessWidget {
  const _SideMenuPanel({
    required this.state,
    required this.i18n,
    required this.collapsed,
    required this.searchController,
    required this.jumpPrefixController,
    required this.letterJumpOptions,
    required this.onToggleCollapse,
    required this.onSelectWordbook,
    required this.onRenameWordbook,
    required this.onDeleteWordbook,
    required this.onCreateWordbook,
    required this.onImportWordbook,
    required this.onImportLegacy,
    required this.onMergeWordbooks,
    required this.onExportTask,
    required this.onClearTask,
    required this.onJumpByInitial,
    required this.onJumpByPrefix,
    required this.onAddSingleWord,
    required this.onImportJsonWords,
  });

  final AppState state;
  final AppI18n i18n;
  final bool collapsed;
  final TextEditingController searchController;
  final TextEditingController jumpPrefixController;
  final List<String> letterJumpOptions;
  final VoidCallback onToggleCollapse;
  final ValueChanged<Wordbook> onSelectWordbook;
  final ValueChanged<Wordbook> onRenameWordbook;
  final ValueChanged<Wordbook> onDeleteWordbook;
  final VoidCallback onCreateWordbook;
  final VoidCallback onImportWordbook;
  final VoidCallback onImportLegacy;
  final VoidCallback onMergeWordbooks;
  final VoidCallback onExportTask;
  final VoidCallback onClearTask;
  final ValueChanged<String> onJumpByInitial;
  final ValueChanged<String> onJumpByPrefix;
  final ValueChanged<Wordbook> onAddSingleWord;
  final ValueChanged<Wordbook> onImportJsonWords;

  @override
  Widget build(BuildContext context) {
    final builtins = state.wordbooks
        .where((book) => book.isSystem && !book.isSpecial)
        .toList(growable: false);
    final customBooks = state.wordbooks
        .where((book) => !book.isSystem)
        .toList(growable: false);
    final specialBooks = state.wordbooks
        .where((book) => book.isSpecial)
        .toList(growable: false);

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              onPressed: onToggleCollapse,
              icon: const Icon(Icons.menu_open_rounded),
            ),
            const SizedBox(height: 10),
            for (final book in <Wordbook>[...builtins, ...specialBooks])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _miniBookButton(
                  book: book,
                  selected: state.selectedWordbook?.id == book.id,
                ),
              ),
            const SizedBox(height: 6),
            IconButton(
              tooltip: i18n.t('newWordbook'),
              onPressed: onCreateWordbook,
              icon: const Icon(Icons.add_box_outlined),
            ),
            IconButton(
              tooltip: i18n.t('importWordbook'),
              onPressed: onImportWordbook,
              icon: const Icon(Icons.file_upload_outlined),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: onToggleCollapse,
            icon: const Icon(Icons.menu_open_rounded),
            label: const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          _buildSectionTitle(context, i18n.t('wordbooks')),
          _buildGroupList(context, books: builtins, allowManage: false),
          const SizedBox(height: 8),
          _buildSectionTitle(context, i18n.t('specialWordbooks')),
          _buildGroupList(context, books: specialBooks, allowManage: false),
          const SizedBox(height: 8),
          _buildSectionTitle(context, i18n.t('manageWordbook')),
          _buildGroupList(context, books: customBooks, allowManage: true),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: state.setSearchQuery,
            decoration: InputDecoration(
              hintText: i18n.t('searchPlaceholder'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        state.setSearchQuery('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _SearchModeChip(
                selected: state.searchMode == SearchMode.all,
                label: i18n.t('all'),
                onTap: () => state.setSearchMode(SearchMode.all),
              ),
              _SearchModeChip(
                selected: state.searchMode == SearchMode.word,
                label: i18n.t('word'),
                onTap: () => state.setSearchMode(SearchMode.word),
              ),
              _SearchModeChip(
                selected: state.searchMode == SearchMode.meaning,
                label: i18n.t('meaning'),
                onTap: () => state.setSearchMode(SearchMode.meaning),
              ),
              _SearchModeChip(
                selected: state.searchMode == SearchMode.fuzzy,
                label: i18n.t('fuzzy'),
                onTap: () => state.setSearchMode(SearchMode.fuzzy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSectionTitle(context, i18n.t('jumpByLetter')),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: letterJumpOptions
                .map(
                  (letter) => SizedBox(
                    width: 38,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => onJumpByInitial(letter),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(letter),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: jumpPrefixController,
                  onSubmitted: onJumpByPrefix,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: i18n.t('jumpByPrefix'),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => onJumpByPrefix(jumpPrefixController.text),
                child: Text(i18n.t('go')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onCreateWordbook,
            child: Text(i18n.t('newWordbook')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onImportWordbook,
            style: FilledButton.styleFrom(backgroundColor: LegacyStyle.accent),
            child: Text(i18n.t('importWordbook')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onImportLegacy,
            child: Text(i18n.t('migrateLegacy')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onMergeWordbooks,
            child: Text(i18n.t('mergeWordbooks')),
          ),
          if (state.selectedWordbook?.path == 'builtin:task') ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onExportTask,
              child: Text(i18n.t('exportTaskWordbook')),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onClearTask,
              child: Text(i18n.t('clearTaskWordbook')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: LegacyStyle.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGroupList(
    BuildContext context, {
    required List<Wordbook> books,
    required bool allowManage,
  }) {
    return Column(
      children: books
          .map((book) {
            final selected = state.selectedWordbook?.id == book.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: LegacyStyle.cardDecoration.copyWith(
                gradient: selected ? LegacyStyle.chipGradient : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onTap: () => onSelectWordbook(book),
                title: Text(
                  book.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  i18n.t('wordsCount', params: {'count': book.wordCount}),
                  style: const TextStyle(color: LegacyStyle.textSecondary),
                ),
                trailing: !allowManage
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'add_single') onAddSingleWord(book);
                          if (value == 'add_json') onImportJsonWords(book);
                          if (value == 'rename') onRenameWordbook(book);
                          if (value == 'delete') onDeleteWordbook(book);
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'add_single',
                            child: Text(i18n.t('addWord')),
                          ),
                          const PopupMenuItem<String>(
                            value: 'add_json',
                            child: Text('JSON Batch Import'),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'rename',
                            child: Text(i18n.t('rename')),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(i18n.t('delete')),
                          ),
                        ],
                      ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _miniBookButton({required Wordbook book, required bool selected}) {
    final label = book.name.trim();
    final short = label.isEmpty ? '?' : label.substring(0, 1);
    return Tooltip(
      message: label,
      child: Material(
        color: selected ? LegacyStyle.primary : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelectWordbook(book),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: Text(
                short.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : LegacyStyle.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchModeChip extends StatelessWidget {
  const _SearchModeChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: LegacyStyle.primary.withValues(alpha: 0.18),
      side: BorderSide(color: LegacyStyle.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => onTap(),
    );
  }
}

class _WordDetailPanel extends StatelessWidget {
  const _WordDetailPanel({
    required this.state,
    required this.i18n,
    required this.onEdit,
    required this.onDelete,
    required this.onFollowAlong,
    required this.onCopyField,
    required this.onEditField,
    required this.onDeleteField,
    required this.testModeEnabled,
    required this.testModeRevealed,
    required this.testModeHintRevealed,
    required this.onToggleReveal,
    required this.onToggleHint,
  });

  final AppState state;
  final AppI18n i18n;
  final ValueChanged<WordEntry> onEdit;
  final ValueChanged<WordEntry> onDelete;
  final ValueChanged<WordEntry> onFollowAlong;
  final ValueChanged<WordFieldItem> onCopyField;
  final void Function(WordEntry word, WordFieldItem field) onEditField;
  final void Function(WordEntry word, WordFieldItem field) onDeleteField;
  final bool testModeEnabled;
  final bool testModeRevealed;
  final bool testModeHintRevealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onToggleHint;

  @override
  Widget build(BuildContext context) {
    final word = state.currentWord;
    if (word == null) return Center(child: Text(i18n.t('selectWord')));

    final baseFields = word.fields.isNotEmpty
        ? word.fields
        : buildFieldItemsFromRecord(<String, Object?>{
            'meaning': word.meaning,
            'examples': word.examples,
          });
    final fields = _resolveDisplayFields(baseFields);
    final totalWords = max(
      state.selectedWordbook?.wordCount ?? state.words.length,
      1,
    );
    final progressCurrent = min(max(state.currentWordIndex + 1, 1), totalWords);
    final progress = progressCurrent / totalWords;

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: LegacyStyle.cardDecoration.copyWith(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.menu_book_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    i18n.t('currentWord'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${i18n.t('progress')}: $progressCurrent / $totalWords',
                style: const TextStyle(color: LegacyStyle.textSecondary),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      word.word,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: LegacyStyle.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: i18n.t('edit'),
                    onPressed: () => onEdit(word),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: i18n.t('followAlong'),
                    onPressed: () => onFollowAlong(word),
                    icon: const Icon(Icons.mic_none_outlined),
                  ),
                  IconButton(
                    tooltip: i18n.t('toggleTask'),
                    onPressed: () => state.toggleTaskWord(word),
                    icon: Icon(
                      state.taskWords.contains(word.word)
                          ? Icons.remove_circle_outline
                          : Icons.add,
                      color: state.taskWords.contains(word.word)
                          ? Colors.redAccent
                          : Colors.teal,
                    ),
                  ),
                  IconButton(
                    tooltip: i18n.t('toggleFavorite'),
                    onPressed: () => state.toggleFavorite(word),
                    icon: Icon(
                      state.favorites.contains(word.word)
                          ? Icons.star
                          : Icons.star_border,
                      color: state.favorites.contains(word.word)
                          ? Colors.amber
                          : null,
                    ),
                  ),
                  IconButton(
                    tooltip: i18n.t('delete'),
                    onPressed: () => onDelete(word),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (testModeEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 6,
                    spacing: 8,
                    children: <Widget>[
                      Text(i18n.t('testModeEnabledHint')),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: onToggleHint,
                            child: Text(
                              testModeHintRevealed
                                  ? i18n.t('hideHint')
                                  : i18n.t('showHint'),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: onToggleReveal,
                            child: Text(
                              testModeRevealed
                                  ? i18n.t('hideAnswer')
                                  : i18n.t('revealAnswer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              for (var index = 0; index < fields.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                _WordFieldCard(
                  field: fields[index],
                  accent: _fieldAccentColor(fields[index].key),
                  i18n: i18n,
                  canEditWord: true,
                  onCopyField: onCopyField,
                  onEditField: () => onEditField(word, fields[index]),
                  onDeleteField: () => onDeleteField(word, fields[index]),
                ),
              ],
              const SizedBox(height: 128),
            ],
          ),
        ),
      ],
    );
  }

  List<WordFieldItem> _resolveDisplayFields(List<WordFieldItem> baseFields) {
    if (!testModeEnabled) return baseFields;
    if (testModeRevealed) return baseFields;
    if (testModeHintRevealed) {
      return baseFields.where((field) => !_isMeaningField(field.key)).toList();
    }
    return const <WordFieldItem>[];
  }

  bool _isMeaningField(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized == 'meaning' ||
        normalized == 'definition' ||
        normalized == 'translation';
  }

  Color _fieldAccentColor(String key) {
    final code = key.runes.fold<int>(0, (sum, item) => sum + item);
    final hue = (code * 37) % 360;
    return HSVColor.fromAHSV(1, hue.toDouble(), 0.6, 0.62).toColor();
  }
}

class _EditableFieldDraft {
  _EditableFieldDraft({
    required this.id,
    required this.key,
    required this.label,
    required this.content,
    required this.startsEmptyNonCore,
  });

  final int id;
  String key;
  String label;
  String content;
  final bool startsEmptyNonCore;
}

class _EditableFieldCard extends StatelessWidget {
  const _EditableFieldCard({
    required this.field,
    required this.i18n,
    required this.onChanged,
    required this.onDelete,
  });

  final _EditableFieldDraft field;
  final AppI18n i18n;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: LegacyStyle.cardDecoration.copyWith(
        border: Border.all(color: LegacyStyle.border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('editable-field-key-${field.id}'),
                  initialValue: field.key,
                  onChanged: (value) {
                    field.key = value;
                  },
                  decoration: InputDecoration(labelText: i18n.t('fieldKey')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('editable-field-label-${field.id}'),
                  initialValue: field.label,
                  onChanged: (value) {
                    field.label = value;
                  },
                  decoration: InputDecoration(labelText: i18n.t('fieldLabel')),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 132,
                child: FilledButton.tonalIcon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(i18n.t('delete')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey<String>('editable-field-content-${field.id}'),
            initialValue: field.content,
            minLines: 2,
            maxLines: 8,
            onChanged: (value) {
              field.content = value;
              onChanged();
            },
            decoration: InputDecoration(labelText: i18n.t('fieldContent')),
          ),
        ],
      ),
    );
  }
}

class _WordFieldCard extends StatelessWidget {
  const _WordFieldCard({
    required this.field,
    required this.accent,
    required this.i18n,
    required this.canEditWord,
    required this.onCopyField,
    required this.onEditField,
    required this.onDeleteField,
  });

  final WordFieldItem field;
  final Color accent;
  final AppI18n i18n;
  final bool canEditWord;
  final ValueChanged<WordFieldItem> onCopyField;
  final VoidCallback onEditField;
  final VoidCallback onDeleteField;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LegacyStyle.cardDecoration.copyWith(
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent.withValues(alpha: 0.95),
                  ),
                ),
              ),
              IconButton(
                tooltip: i18n.t('copyField'),
                onPressed: () => onCopyField(field),
                icon: const Icon(Icons.content_copy_outlined, size: 19),
              ),
              IconButton(
                tooltip: i18n.t('editField'),
                onPressed: canEditWord ? onEditField : null,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: i18n.t('deleteField'),
                onPressed: canEditWord ? onDeleteField : null,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 19,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            field.asText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FollowAlongDialog extends StatefulWidget {
  const _FollowAlongDialog({required this.state, required this.word});

  final AppState state;
  final WordEntry word;

  @override
  State<_FollowAlongDialog> createState() => _FollowAlongDialogState();
}

class _FollowAlongDialogState extends State<_FollowAlongDialog> {
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recognizedText;
  PronunciationComparison? _comparison;
  String? _error;
  AsrProgress? _progress;

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;
    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
      _recognizedText = null;
      _comparison = null;
      _progress = null;
    });

    final path = await widget.state.startAsrRecording();
    if (!mounted) return;
    if (path == null || path.trim().isEmpty) {
      final i18n = AppI18n(widget.state.uiLanguage);
      setState(() {
        _error = i18n.t('startRecordingFailed');
      });
      return;
    }

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopAndTranscribe() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _error = null;
      _progress = const AsrProgress(
        stage: 'recording',
        messageKey: 'asrProgressStoppingRecording',
        progress: null,
      );
    });

    try {
      final audioPath = await widget.state.stopAsrRecording();
      if (!mounted) return;
      if (audioPath == null || audioPath.trim().isEmpty) {
        final i18n = AppI18n(widget.state.uiLanguage);
        setState(() {
          _error = i18n.t('recordingFailed');
        });
        return;
      }

      final result = await widget.state.transcribeRecording(
        audioPath,
        expectedText: widget.word.word,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
          });
        },
      );
      if (!mounted) return;

      if (!result.success) {
        final i18n = AppI18n(widget.state.uiLanguage);
        setState(() {
          _error = result.error == null
              ? i18n.t('recognitionFailed')
              : i18n.t(result.error!, params: result.errorParams);
          _recognizedText = null;
          _comparison = null;
        });
        return;
      }

      final text = result.text?.trim() ?? '';
      final compare = widget.state.comparePronunciation(widget.word.word, text);
      setState(() {
        _recognizedText = text;
        _comparison = compare;
        _progress = const AsrProgress(
          stage: 'done',
          messageKey: 'asrProgressDone',
          progress: 1,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _playReference() async {
    await widget.state.previewPronunciation(widget.word.word);
  }

  String _formatDifference(AppI18n i18n, String item) {
    if (item.startsWith('missing::')) {
      return i18n.t(
        'pronunciationDiffMissing',
        params: <String, Object?>{'value': item.substring('missing::'.length)},
      );
    }
    if (item.startsWith('extra::')) {
      return i18n.t(
        'pronunciationDiffExtra',
        params: <String, Object?>{'value': item.substring('extra::'.length)},
      );
    }
    if (item.startsWith('replace::')) {
      final payload = item.substring('replace::'.length).split('::');
      if (payload.length == 2) {
        return i18n.t(
          'pronunciationDiffReplace',
          params: <String, Object?>{'from': payload[0], 'to': payload[1]},
        );
      }
    }
    return item;
  }

  @override
  void dispose() {
    widget.state.cancelAsrRecording();
    widget.state.stopAsrProcessing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(widget.state.uiLanguage);
    final comparison = _comparison;
    final progress = _progress;

    return AlertDialog(
      title: Text(i18n.t('followAlongTitle')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.word.word,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _playReference,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(i18n.t('playPronunciation')),
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton(
                  onPressed: _isProcessing ? null : _toggleRecording,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(22),
                    backgroundColor: _isRecording ? Colors.red : null,
                  ),
                  child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 28),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording
                    ? i18n.t('tapToStopRecord')
                    : _isProcessing
                    ? i18n.t('recognizing')
                    : i18n.t('tapToStartRecord'),
                textAlign: TextAlign.center,
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                Text(
                  i18n.t(progress.messageKey, params: progress.messageParams),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress.progress),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              if (comparison != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          comparison.isCorrect
                              ? i18n.t('great')
                              : i18n.t('needsPractice'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          i18n.t(
                            'recognizedText',
                            params: {'text': _recognizedText ?? ''},
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          i18n.t(
                            'similarity',
                            params: {
                              'score': (comparison.similarity * 100).round(),
                            },
                          ),
                        ),
                        if (comparison.differences.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(i18n.t('differences')),
                          const SizedBox(height: 4),
                          for (final item in comparison.differences)
                            Text('- ${_formatDifference(i18n, item)}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(i18n.t('close')),
        ),
      ],
    );
  }
}

class _WordbookDrawer extends StatelessWidget {
  const _WordbookDrawer({
    required this.state,
    required this.i18n,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
    required this.onMerge,
    required this.onAddSingleWord,
    required this.onImportJsonWords,
    required this.onImportWordbook,
    required this.onExportTaskWordbook,
  });

  final AppState state;
  final AppI18n i18n;
  final VoidCallback onCreate;
  final void Function(int id, String oldName) onRename;
  final void Function(int id, String name) onDelete;
  final VoidCallback onMerge;
  final ValueChanged<Wordbook> onAddSingleWord;
  final ValueChanged<Wordbook> onImportJsonWords;
  final VoidCallback onImportWordbook;
  final VoidCallback onExportTaskWordbook;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    i18n.t('wordbooks'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(onPressed: onCreate, icon: const Icon(Icons.add)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.wordbooks.length,
              itemBuilder: (context, index) {
                final wordbook = state.wordbooks[index];
                return ListTile(
                  selected: state.selectedWordbook?.id == wordbook.id,
                  title: Text(wordbook.name),
                  subtitle: Text(
                    i18n.t('wordsCount', params: {'count': wordbook.wordCount}),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    state.selectWordbook(wordbook);
                  },
                  trailing: wordbook.isSystem
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'add_single') {
                              onAddSingleWord(wordbook);
                            }
                            if (value == 'add_json') {
                              onImportJsonWords(wordbook);
                            }
                            if (value == 'rename') {
                              onRename(wordbook.id, wordbook.name);
                            }
                            if (value == 'delete') {
                              onDelete(wordbook.id, wordbook.name);
                            }
                          },
                          itemBuilder: (_) => <PopupMenuEntry<String>>[
                            PopupMenuItem(
                              value: 'add_single',
                              child: Text(i18n.t('addWord')),
                            ),
                            const PopupMenuItem(
                              value: 'add_json',
                              child: Text('JSON Batch Import'),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(i18n.t('rename')),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(i18n.t('delete')),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: onImportWordbook,
                  child: Text(i18n.t('importWordbook')),
                ),
                const SizedBox(height: 6),
                FilledButton.tonal(
                  onPressed: onMerge,
                  child: Text(i18n.t('mergeWordbooks')),
                ),
                const SizedBox(height: 6),
                FilledButton.tonal(
                  onPressed: onExportTaskWordbook,
                  child: Text(i18n.t('exportTaskWordbook')),
                ),
                const SizedBox(height: 6),
                FilledButton.tonal(
                  onPressed: () => state.clearTaskWordbook(),
                  child: Text(i18n.t('clearTaskWordbook')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TtsApiModelOption {
  const _TtsApiModelOption({
    required this.id,
    required this.name,
    required this.voices,
  });

  final String id;
  final String name;
  final List<String> voices;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

extension on AppState {
  bool get wordsAvailable =>
      selectedWordbook != null && visibleWords.isNotEmpty;
}

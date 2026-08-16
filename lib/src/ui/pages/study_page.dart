import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/study_startup_tab.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../ui_copy.dart';
import '../wordbook_localization.dart';
import 'library_page.dart';
import 'play_page.dart';

class StudyPage extends ConsumerWidget {
  const StudyPage({
    super.key,
    required this.selectedTab,
    required this.onSelectTab,
    required this.onOpenPractice,
    required this.onAttachLibraryScrollToTop,
  });

  final StudyStartupTab selectedTab;
  final ValueChanged<StudyStartupTab> onSelectTab;
  final VoidCallback onOpenPractice;
  final ValueChanged<VoidCallback> onAttachLibraryScrollToTop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(
      appStateProvider.select(_StudyPageRebuildToken.fromState),
    );
    final state = ref.read(appStateProvider);
    final i18n = AppI18n(token.uiLanguage);
    if (!token.studyEnabled) {
      return ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.study);
    }
    final studyLocked = state.wordbookImportActive;
    final selectedWordbookName = localizedWordbookName(
      i18n,
      state.selectedWordbook,
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ultraCompact = constraints.maxWidth < 420;
              final compact = constraints.maxWidth < 560;

              final playCard = _StudyEntryCard(
                compact: compact,
                ultraCompact: ultraCompact,
                selected: selectedTab == StudyStartupTab.play,
                icon: Icons.play_circle_rounded,
                title: pageLabelPlay(i18n),
                summary: _playSummary(
                  i18n,
                  state: state,
                  selectedWordbookName: selectedWordbookName,
                  ultraCompact: ultraCompact,
                ),
                hint: i18n.t(
                  'inline.ui.pages.study_page.open_continuous_playback_progress_jump_and_playback_mode_cf6dc5',
                ),
                onTap: studyLocked
                    ? null
                    : () => onSelectTab(StudyStartupTab.play),
              );

              final libraryCard = _StudyEntryCard(
                compact: compact,
                ultraCompact: ultraCompact,
                selected: selectedTab == StudyStartupTab.library,
                icon: Icons.menu_book_rounded,
                title: pageLabelLibrary(i18n),
                summary: _librarySummary(
                  i18n,
                  state: state,
                  selectedWordbookName: selectedWordbookName,
                  ultraCompact: ultraCompact,
                ),
                hint: i18n.t(
                  'inline.ui.pages.study_page.open_search_prefix_jump_add_word_and_library_browsing_to_c16875',
                ),
                onTap: studyLocked
                    ? null
                    : () => onSelectTab(StudyStartupTab.library),
              );

              return Row(
                children: <Widget>[
                  Expanded(child: playCard),
                  SizedBox(width: ultraCompact ? 8 : 12),
                  Expanded(child: libraryCard),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: studyLocked
              ? _StudyImportLockPanel(state: state, i18n: i18n)
              : IndexedStack(
                  index: selectedTab == StudyStartupTab.play ? 0 : 1,
                  children: <Widget>[
                    PlayPage(
                      onOpenPractice: onOpenPractice,
                      onOpenLibrary: () => onSelectTab(StudyStartupTab.library),
                    ),
                    LibraryPage(
                      onAttachScrollToTop: onAttachLibraryScrollToTop,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _playSummary(
    AppI18n i18n, {
    required AppState state,
    required String selectedWordbookName,
    required bool ultraCompact,
  }) {
    if (ultraCompact) {
      if (state.selectedWordbook == null) {
        return i18n.t('inline.ui.pages.study_page.pick_a_book_ab7267');
      }
      return i18n.t(
        'inline.ui.pages.study_page.state_visiblewordcount_words_9edc10',
        params: <String, Object?>{'count': state.visibleWordCount},
      );
    }
    if (state.selectedWordbook == null) {
      return i18n.t(
        'inline.ui.pages.study_page.choose_a_wordbook_then_start_playback_and_follow_along_f_a72207',
      );
    }
    return i18n.t(
      'inline.ui.pages.study_page.selectedwordbookname_state_visiblewordcount_words_ready_3d99e5',
      params: <String, Object?>{
        'wordbook': selectedWordbookName,
        'count': state.visibleWordCount,
      },
    );
  }

  String _librarySummary(
    AppI18n i18n, {
    required AppState state,
    required String selectedWordbookName,
    required bool ultraCompact,
  }) {
    if (ultraCompact) {
      if (state.selectedWordbook == null) {
        return i18n.t('inline.ui.pages.study_page.import_books_4df67b');
      }
      return i18n.t('inline.ui.pages.study_page.search_sort_e351d6');
    }
    if (state.selectedWordbook == null) {
      return i18n.t(
        'inline.ui.pages.study_page.import_create_and_browse_wordbooks_to_build_your_study_s_724cbc',
      );
    }
    return i18n.t(
      'inline.ui.pages.study_page.search_jump_through_and_organize_entries_in_selectedword_307e60',
      params: <String, Object?>{'wordbook': selectedWordbookName},
    );
  }
}

class _StudyPageRebuildToken {
  const _StudyPageRebuildToken({
    required this.uiLanguage,
    required this.studyEnabled,
    required this.wordbookImportActive,
    required this.wordbookImportProcessedEntries,
    required this.wordbookImportTotalEntries,
    required this.wordbookImportProgress,
    required this.selectedWordbookId,
    required this.selectedWordbookName,
    required this.selectedWordbookPath,
    required this.selectedWordbookWordCount,
    required this.selectedWordbookLoaded,
    required this.wordsVersion,
    required this.searchQuery,
    required this.searchMode,
  });

  factory _StudyPageRebuildToken.fromState(AppState state) {
    final selected = state.selectedWordbook;
    return _StudyPageRebuildToken(
      uiLanguage: state.uiLanguage,
      studyEnabled: state.isModuleEnabled(ModuleIds.study),
      wordbookImportActive: state.wordbookImportActive,
      wordbookImportProcessedEntries: state.wordbookImportProcessedEntries,
      wordbookImportTotalEntries: state.wordbookImportTotalEntries,
      wordbookImportProgress: state.wordbookImportProgress,
      selectedWordbookId: selected?.id,
      selectedWordbookName: selected?.name ?? '',
      selectedWordbookPath: selected?.path ?? '',
      selectedWordbookWordCount: selected?.wordCount ?? 0,
      selectedWordbookLoaded: state.selectedWordbookLoaded,
      wordsVersion: state.wordsVersion,
      searchQuery: state.searchQuery,
      searchMode: state.searchMode,
    );
  }

  final String uiLanguage;
  final bool studyEnabled;
  final bool wordbookImportActive;
  final int wordbookImportProcessedEntries;
  final int? wordbookImportTotalEntries;
  final double? wordbookImportProgress;
  final int? selectedWordbookId;
  final String selectedWordbookName;
  final String selectedWordbookPath;
  final int selectedWordbookWordCount;
  final bool selectedWordbookLoaded;
  final int wordsVersion;
  final String searchQuery;
  final SearchMode searchMode;

  @override
  bool operator ==(Object other) {
    return other is _StudyPageRebuildToken &&
        other.uiLanguage == uiLanguage &&
        other.studyEnabled == studyEnabled &&
        other.wordbookImportActive == wordbookImportActive &&
        other.wordbookImportProcessedEntries ==
            wordbookImportProcessedEntries &&
        other.wordbookImportTotalEntries == wordbookImportTotalEntries &&
        other.wordbookImportProgress == wordbookImportProgress &&
        other.selectedWordbookId == selectedWordbookId &&
        other.selectedWordbookName == selectedWordbookName &&
        other.selectedWordbookPath == selectedWordbookPath &&
        other.selectedWordbookWordCount == selectedWordbookWordCount &&
        other.selectedWordbookLoaded == selectedWordbookLoaded &&
        other.wordsVersion == wordsVersion &&
        other.searchQuery == searchQuery &&
        other.searchMode == searchMode;
  }

  @override
  int get hashCode => Object.hash(
    uiLanguage,
    studyEnabled,
    wordbookImportActive,
    wordbookImportProcessedEntries,
    wordbookImportTotalEntries,
    wordbookImportProgress,
    selectedWordbookId,
    selectedWordbookName,
    selectedWordbookPath,
    selectedWordbookWordCount,
    selectedWordbookLoaded,
    wordsVersion,
    searchQuery,
    searchMode,
  );
}

class _StudyEntryCard extends StatelessWidget {
  const _StudyEntryCard({
    required this.compact,
    required this.ultraCompact,
    required this.selected,
    required this.icon,
    required this.title,
    required this.summary,
    required this.hint,
    required this.onTap,
  });

  final bool compact;
  final bool ultraCompact;
  final bool selected;
  final IconData icon;
  final String title;
  final String summary;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final titleStyle = ultraCompact
        ? theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)
        : compact
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    final summaryStyle = ultraCompact
        ? theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)
        : compact
        ? theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final selectedBackground = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        theme.colorScheme.primaryContainer,
        theme.colorScheme.surfaceContainerHigh,
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected ? selectedBackground : null,
        color: selected ? null : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ultraCompact ? 20 : 24),
        border: Border.all(
          color: selected ? accent : theme.colorScheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: ultraCompact ? 12 : 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ultraCompact ? 20 : 24),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(
              ultraCompact
                  ? 10
                  : compact
                  ? 14
                  : 16,
            ),
            child: Row(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: ultraCompact
                      ? 34
                      : compact
                      ? 42
                      : 46,
                  height: ultraCompact
                      ? 34
                      : compact
                      ? 42
                      : 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.12)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(ultraCompact ? 10 : 14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: accent,
                    size: ultraCompact ? 18 : 22,
                  ),
                ),
                SizedBox(width: ultraCompact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        summary,
                        maxLines: ultraCompact
                            ? 1
                            : compact
                            ? 2
                            : 1,
                        overflow: TextOverflow.ellipsis,
                        style: summaryStyle,
                      ),
                      if (!compact) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(hint, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: ultraCompact ? 4 : 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: ultraCompact
                      ? (selected ? 18 : 14)
                      : selected
                      ? 22
                      : 18,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyImportLockPanel extends StatelessWidget {
  const _StudyImportLockPanel({required this.state, required this.i18n});

  final AppState state;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final progress = state.wordbookImportProgress;
    final processed = state.wordbookImportProcessedEntries;
    final total = state.wordbookImportTotalEntries;
    final detail = total == null || total <= 0
        ? i18n.t('inline.ui.app_shell.parsing_and_importing_please_wait_1b254d')
        : i18n.t(
            'inline.ui.app_shell.processed_processed_total_11a7cb',
            params: <String, Object?>{'processed': processed, 'total': total},
          );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t(
                    'inline.ui.pages.study_page.study_import_in_progress_4938fd',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.t(
                    'inline.ui.pages.study_page.wordbook_is_importing_in_background_study_modules_will_a_dbf110',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress, minHeight: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

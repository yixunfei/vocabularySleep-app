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
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.study)) {
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
                hint: pickUiText(
                  i18n,
                  zh: '进入连续播放、进度跳转与播放模式控制。',
                  en: 'Open continuous playback, progress jump, and playback mode controls.',
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
                hint: pickUiText(
                  i18n,
                  zh: '进入搜索、前缀跳转、加词和词条浏览。',
                  en: 'Open search, prefix jump, add-word, and library browsing tools.',
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
        return pickUiText(i18n, zh: '先选词库', en: 'Pick a book');
      }
      return pickUiText(
        i18n,
        zh: '${state.visibleWordCount} 词待播',
        en: '${state.visibleWordCount} words',
      );
    }
    if (state.selectedWordbook == null) {
      return pickUiText(
        i18n,
        zh: '先选择词库，再从这里直接开始播放和跟读。',
        en: 'Choose a wordbook, then start playback and follow-along from here.',
      );
    }
    return pickUiText(
      i18n,
      zh: '$selectedWordbookName · ${state.visibleWordCount} 个词待播放',
      en: '$selectedWordbookName · ${state.visibleWordCount} words ready to play',
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
        return pickUiText(i18n, zh: '导入词库', en: 'Import books');
      }
      return pickUiText(i18n, zh: '搜索整理', en: 'Search & sort');
    }
    if (state.selectedWordbook == null) {
      return pickUiText(
        i18n,
        zh: '导入、创建并浏览词库，建立自己的学习范围。',
        en: 'Import, create, and browse wordbooks to build your study scope.',
      );
    }
    return pickUiText(
      i18n,
      zh: '搜索、跳转并整理 $selectedWordbookName 的词条。',
      en: 'Search, jump through, and organize entries in $selectedWordbookName.',
    );
  }
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
        ? pickUiText(
            i18n,
            zh: '正在解析并导入，请稍候…',
            en: 'Parsing and importing, please wait...',
          )
        : pickUiText(
            i18n,
            zh: '已处理 $processed / $total',
            en: 'Processed $processed / $total',
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
                  pickUiText(
                    i18n,
                    zh: '学习模块导入中',
                    en: 'Study import in progress',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '词本正在后台导入，导入完成后将自动启用学习模块。',
                    en: 'Wordbook is importing in background. Study modules will auto-enable when complete.',
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

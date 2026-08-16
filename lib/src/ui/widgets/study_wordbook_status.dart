import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../wordbook_localization.dart';
import 'wordbook_switcher.dart';

class StudyWordbookStatusBar extends StatelessWidget {
  const StudyWordbookStatusBar({
    super.key,
    required this.state,
    required this.i18n,
    required this.onTap,
    this.visibleCount,
    this.searching = false,
    this.currentWordbookEmpty = false,
    this.onLoadCurrent,
  });

  final AppState state;
  final AppI18n i18n;
  final VoidCallback onTap;
  final int? visibleCount;
  final bool searching;
  final bool currentWordbookEmpty;
  final Future<bool> Function()? onLoadCurrent;

  @override
  Widget build(BuildContext context) {
    final wordbook = state.selectedWordbook;
    final requiresLoad = studyWordbookNeedsExplicitLoad(state);
    final actionLabel = requiresLoad
        ? i18n.t('study.wordbook.action.load_current')
        : wordbook == null
        ? i18n.t('study.wordbook.action.choose')
        : i18n.t('study.wordbook.action.switch');
    final actionIcon = requiresLoad
        ? Icons.download_done_rounded
        : wordbook == null
        ? Icons.add_rounded
        : Icons.swap_horiz_rounded;
    final semanticLabel = requiresLoad
        ? i18n.t('study.wordbook.semantic.load_or_switch')
        : wordbook == null
        ? i18n.t('study.wordbook.action.choose')
        : i18n.t('study.wordbook.action.switch');

    return WordbookSwitcher(
      wordbook: wordbook,
      title: wordbook == null
          ? i18n.t('study.wordbook.status.none_title')
          : localizedWordbookName(i18n, wordbook),
      subtitle: studyWordbookStatusMessage(
        state,
        i18n,
        visibleCount: visibleCount,
        searching: searching,
        currentWordbookEmpty: currentWordbookEmpty,
      ),
      semanticLabel: semanticLabel,
      tooltip: semanticLabel,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onTap: onTap,
      onActionTap: requiresLoad && onLoadCurrent != null
          ? () => onLoadCurrent!()
          : onTap,
    );
  }
}

String studyWordbookStatusMessage(
  AppState state,
  AppI18n i18n, {
  int? visibleCount,
  bool searching = false,
  bool currentWordbookEmpty = false,
}) {
  final wordbook = state.selectedWordbook;
  if (wordbook == null) {
    return i18n.t('noWordbookYet');
  }
  final count = _studyWordbookCount(state, visibleCount);
  if (state.selectedWordbookRequiresOnDemandLoad) {
    return i18n.t(
      'study.library.wordbook.deferred.summary',
      params: <String, Object?>{
        'wordbook': localizedWordbookName(i18n, wordbook),
        'count': count,
      },
    );
  }
  if (studyWordbookNeedsExplicitLoad(state)) {
    return i18n.t('study.wordbook.sheet.lazy_builtin');
  }
  if (searching && count <= 0) {
    return i18n.t('study.wordbook.status.search_empty');
  }
  if (currentWordbookEmpty ||
      (state.selectedWordbookLoaded && state.words.isEmpty)) {
    return i18n.t('study.wordbook.status.selected_empty');
  }
  return i18n.t(
    'study.wordbook.status.loaded',
    params: <String, Object?>{'count': count},
  );
}

bool studyWordbookNeedsExplicitLoad(AppState state) {
  final wordbook = state.selectedWordbook;
  if (wordbook == null) return false;
  if (state.selectedWordbookRequiresOnDemandLoad) return true;
  return !state.selectedWordbookLoaded &&
      wordbook.path.startsWith('builtin:dict:') &&
      wordbook.wordCount <= 0;
}

String studyWordbookSheetSubtitle(AppState state, AppI18n i18n, Wordbook book) {
  final isLazyBuiltIn =
      book.path.startsWith('builtin:dict:') && book.wordCount <= 0;
  if (isLazyBuiltIn) {
    return i18n.t('study.wordbook.sheet.lazy_builtin');
  }
  if (state.selectedWordbook?.id == book.id &&
      studyWordbookNeedsExplicitLoad(state)) {
    return studyWordbookStatusMessage(
      state,
      i18n,
      visibleCount: state.visibleWordCount,
    );
  }
  return i18n.t(
    'study.wordbook.sheet.item_count',
    params: <String, Object?>{'count': book.wordCount},
  );
}

Future<void> showStudyWordbookSheet({
  required BuildContext context,
  required AppState state,
  required AppI18n i18n,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(
              i18n.t('study.wordbook.sheet.title'),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (state.wordbooks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(i18n.t('noWordbookYet')),
              )
            else
              for (final book in state.wordbooks) ...<Widget>[
                Card(
                  child: ListTile(
                    selected: state.selectedWordbook?.id == book.id,
                    leading: Icon(
                      state.selectedWordbook?.id == book.id
                          ? Icons.check_circle_rounded
                          : Icons.menu_book_rounded,
                    ),
                    title: Text(localizedWordbookName(i18n, book)),
                    subtitle: Text(
                      studyWordbookSheetSubtitle(state, i18n, book),
                    ),
                    trailing:
                        state.selectedWordbook?.id == book.id &&
                            studyWordbookNeedsExplicitLoad(state)
                        ? TextButton(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await state.loadSelectedWordbook();
                            },
                            child: Text(
                              i18n.t('study.wordbook.action.load_current'),
                            ),
                          )
                        : null,
                    onTap: () async {
                      if (state.selectedWordbook?.id == book.id &&
                          studyWordbookNeedsExplicitLoad(state)) {
                        Navigator.of(sheetContext).pop();
                        await state.loadSelectedWordbook();
                        return;
                      }
                      final confirmed = await confirmStudyWordbookLoadIfNeeded(
                        context: sheetContext,
                        state: state,
                        i18n: i18n,
                        book: book,
                      );
                      if (!confirmed) return;
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      await state.selectWordbook(book);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      );
    },
  );
}

Future<bool> confirmStudyWordbookLoadIfNeeded({
  required BuildContext context,
  required AppState state,
  required AppI18n i18n,
  required Wordbook book,
}) {
  if (!state.requiresWordbookLoadConfirmation(book)) {
    return Future<bool>.value(true);
  }
  return showConfirmDialog(
    context: context,
    title: i18n.t('study.wordbook.load_confirm.title'),
    message: i18n.t(
      'study.wordbook.load_confirm.message',
      params: <String, Object?>{
        'wordbook': localizedWordbookName(i18n, book),
        'count': book.wordCount,
      },
    ),
    confirmText: i18n.t('study.wordbook.action.switch'),
  );
}

int _studyWordbookCount(AppState state, int? visibleCount) {
  final count = visibleCount ?? state.visibleWordCount;
  if (count > 0) return count;
  final bookCount = state.selectedWordbook?.wordCount ?? 0;
  if (bookCount > 0) return bookCount;
  return count;
}

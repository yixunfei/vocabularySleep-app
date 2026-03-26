import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/study_startup_tab.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import 'library_page.dart';
import 'play_page.dart';

class StudyPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.select<AppState, String>((s) => s.uiLanguage));

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<StudyStartupTab>(
              segments: <ButtonSegment<StudyStartupTab>>[
                ButtonSegment<StudyStartupTab>(
                  value: StudyStartupTab.play,
                  label: Text(pageLabelPlay(i18n)),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
                ButtonSegment<StudyStartupTab>(
                  value: StudyStartupTab.library,
                  label: Text(pageLabelLibrary(i18n)),
                  icon: const Icon(Icons.menu_book_outlined),
                ),
              ],
              selected: <StudyStartupTab>{selectedTab},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                onSelectTab(selection.first);
              },
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: selectedTab == StudyStartupTab.play ? 0 : 1,
            children: <Widget>[
              PlayPage(
                onOpenPractice: onOpenPractice,
                onOpenLibrary: () => onSelectTab(StudyStartupTab.library),
              ),
              LibraryPage(onAttachScrollToTop: onAttachLibraryScrollToTop),
            ],
          ),
        ),
      ],
    );
  }
}

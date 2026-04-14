import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import 'toolbox/toolbox_page_content.dart';
import 'toolbox/toolbox_page_widgets.dart';
import 'toolbox/toolbox_ui_tokens.dart';

class ToolboxPage extends ConsumerWidget {
  const ToolboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.toolbox)) {
      return ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.toolbox);
    }

    final sections = buildToolboxSections(
      i18n,
      isModuleEnabled: state.isModuleEnabled,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ToolboxUiTokens.pageHorizontalPadding,
        ToolboxUiTokens.pageTopPadding,
        ToolboxUiTokens.pageHorizontalPadding,
        ToolboxUiTokens.pageBottomPadding,
      ),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ToolboxUiTokens.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PageHeader(
                  eyebrow: pageLabelToolbox(i18n),
                  title: pickUiText(
                    i18n,
                    zh: '多功能工具箱',
                    en: 'Multi-tool toolbox',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh: '把声音、专注、放松和小决策工具整理成一套更清晰、更适合移动端使用的本地工具集。',
                    en: 'A calmer, clearer local toolbox for sound, focus, decompression, and small everyday rituals.',
                  ),
                ),
                const SizedBox(height: 18),
                ToolboxIntroPanel(
                  title: pickUiText(
                    i18n,
                    zh: '入口已按使用场景重新整理',
                    en: 'The toolbox is regrouped by use case',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh: '这轮重建重点增强了入口层次、按压反馈和移动端浏览节奏，同时保持各工具功能与跳转逻辑不变。',
                    en: 'This pass strengthens hierarchy, press feedback, and mobile browsing rhythm while keeping tool behavior and navigation unchanged.',
                  ),
                  highlights: <String>[
                    pickUiText(i18n, zh: '睡眠支持', en: 'Sleep'),
                    pickUiText(i18n, zh: '声音工具', en: 'Sound'),
                    pickUiText(i18n, zh: '专注训练', en: 'Focus'),
                    pickUiText(i18n, zh: '静心减压', en: 'Calm'),
                  ],
                ),
                const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                for (final section in sections) ...<Widget>[
                  ToolboxSection(section: section),
                  const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

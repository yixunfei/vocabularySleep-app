import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';

class ToolboxPage extends StatelessWidget {
  const ToolboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.watch<AppState>().uiLanguage);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        PageHeader(
          eyebrow: pageLabelToolbox(i18n),
          title: pickUiText(i18n, zh: '工具箱', en: 'Toolbox'),
          subtitle: pickUiText(
            i18n,
            zh: '这里预留给后续扩展工具，目前先保持一个清晰入口。',
            en: 'This area is reserved for upcoming utility tools.',
          ),
        ),
        const SizedBox(height: 18),
        EmptyStateView(
          icon: Icons.build_circle_outlined,
          title: 'TODO',
          message: pickUiText(
            i18n,
            zh: '工具箱页已预留，后续工具会逐步放到这里。',
            en: 'Toolbox page reserved. Future utilities will appear here.',
          ),
        ),
      ],
    );
  }
}

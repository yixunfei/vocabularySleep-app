import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import 'toolbox/toolbox_ui_tokens.dart';

class ToolboxToolPage extends StatelessWidget {
  const ToolboxToolPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.appBarActions,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: appBarActions),
      body: ListView(
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
                    eyebrow: pickUiText(
                      AppI18n(Localizations.localeOf(context).languageCode),
                      zh: '工具箱',
                      en: 'Toolbox',
                    ),
                    title: title,
                    subtitle: subtitle,
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ToolboxMetricCard extends StatelessWidget {
  const ToolboxMetricCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ToolboxUiTokens.shellCardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

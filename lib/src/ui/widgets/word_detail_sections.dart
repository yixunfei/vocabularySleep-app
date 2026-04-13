import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/word_field.dart';
import '../ui_copy.dart';
import 'section_header.dart';

class WordDetailOverviewCard extends StatelessWidget {
  const WordDetailOverviewCard({
    super.key,
    required this.i18n,
    required this.word,
    required this.groupedFields,
  });

  final AppI18n i18n;
  final WordEntry word;
  final List<WordEntryFieldGroup> groupedFields;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _OverviewChip(
        icon: Icons.layers_rounded,
        label: pickUiText(
          i18n,
          zh: '${groupedFields.length} 个分组',
          en: '${groupedFields.length} groups',
        ),
      ),
      _OverviewChip(
        icon: Icons.view_list_rounded,
        label: pickUiText(
          i18n,
          zh: '${word.fields.length} 个字段',
          en: '${word.fields.length} fields',
        ),
      ),
    ];
    final schemaVersion = (word.schemaVersion ?? '').trim();
    if (schemaVersion.isNotEmpty) {
      chips.add(
        _OverviewChip(icon: Icons.schema_rounded, label: schemaVersion),
      );
    }
    final primaryGloss = word.primaryGloss?.trim() ?? '';
    if (primaryGloss.isNotEmpty && primaryGloss != word.displayMeaning.trim()) {
      chips.add(
        _OverviewChip(icon: Icons.short_text_rounded, label: primaryGloss),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: pickUiText(i18n, zh: '阅读导览', en: 'Reading guide'),
              subtitle: pickUiText(
                i18n,
                zh: '先看核心字段，再按需展开用法和补充信息，减少移动端长内容干扰。',
                en: 'Start with the core fields, then expand usage and supporting sections only when needed.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      ),
    );
  }
}

class WordFieldGroupCard extends StatelessWidget {
  const WordFieldGroupCard({
    super.key,
    required this.i18n,
    required this.group,
  });

  final AppI18n i18n;
  final WordEntryFieldGroup group;

  bool get _initiallyExpanded => group.groupKey == 'core';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fieldLabels = group.fields
        .map((field) => localizedFieldLabel(i18n, field))
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: _initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          localizedWordFieldGroupLabel(i18n, group.groupKey),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          pickUiText(
            i18n,
            zh: '${group.fields.length} 个字段 · ${fieldLabels.join(' / ')}',
            en: '${group.fields.length} fields · ${fieldLabels.join(' / ')}',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: group.fields
            .map(
              (field) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _WordFieldDetailTile(
                  i18n: i18n,
                  field: field,
                  emphasize: group.groupKey == 'core',
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _WordFieldDetailTile extends StatelessWidget {
  const _WordFieldDetailTile({
    required this.i18n,
    required this.field,
    required this.emphasize,
  });

  final AppI18n i18n;
  final WordFieldItem field;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: emphasize
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            localizedFieldLabel(i18n, field),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          _ExpandableFieldText(i18n: i18n, field: field),
        ],
      ),
    );
  }
}

class _ExpandableFieldText extends StatefulWidget {
  const _ExpandableFieldText({required this.i18n, required this.field});

  final AppI18n i18n;
  final WordFieldItem field;

  @override
  State<_ExpandableFieldText> createState() => _ExpandableFieldTextState();
}

class _ExpandableFieldTextState extends State<_ExpandableFieldText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rows = widget.field.asList();
    final lines = rows.isNotEmpty
        ? rows
        : widget.field
              .asText()
              .split(RegExp(r'\r?\n'))
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList(growable: false);
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    const collapsedLineLimit = 4;
    final canExpand = lines.length > collapsedLineLimit;
    final visibleLines = _expanded || !canExpand
        ? lines
        : lines.take(collapsedLineLimit).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final line in visibleLines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              lines.length == 1 ? line : '• $line',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (canExpand)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            icon: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            label: Text(
              _expanded
                  ? pickUiText(widget.i18n, zh: '收起长内容', en: 'Collapse')
                  : pickUiText(widget.i18n, zh: '展开完整内容', en: 'Expand'),
            ),
          ),
      ],
    );
  }
}

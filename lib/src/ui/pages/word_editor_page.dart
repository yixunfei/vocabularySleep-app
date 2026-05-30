import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../models/word_field.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';

class WordEditorPage extends ConsumerStatefulWidget {
  const WordEditorPage({super.key, this.original});

  final WordEntry? original;

  @override
  ConsumerState<WordEditorPage> createState() => _WordEditorPageState();
}

class _WordEditorPageState extends ConsumerState<WordEditorPage> {
  late final TextEditingController _wordController;
  late final List<_FieldDraft> _drafts;

  @override
  void initState() {
    super.initState();
    final payload = widget.original?.toPayload();
    _wordController = TextEditingController(text: payload?.word ?? '');
    final initialFields = payload?.fields ?? const <WordFieldItem>[];
    _drafts = initialFields.isEmpty
        ? <_FieldDraft>[
            _FieldDraft.fromItem(
              const WordFieldItem(key: 'meaning', label: 'Meaning', value: ''),
            ),
          ]
        : initialFields.map(_FieldDraft.fromItem).toList(growable: true);
  }

  @override
  void dispose() {
    _wordController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = ref.read(appStateProvider);
    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n(state.uiLanguage).t(
              'inline.ui.pages.word_editor_page.please_enter_a_word_first_be1137',
            ),
          ),
        ),
      );
      return;
    }

    final fields = mergeFieldItems(
      _drafts
          .map((draft) {
            final keyInput = draft.keyController.text.trim();
            final labelInput = draft.labelController.text.trim();
            final valueInput = draft.valueController.text.trim();
            final key = normalizeFieldKey(
              keyInput.isEmpty ? labelInput : keyInput,
            );
            final value = key == 'examples'
                ? valueInput
                      .split(RegExp(r'\r?\n'))
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .toList(growable: false)
                : valueInput;
            return WordFieldItem(
              key: key,
              label: labelInput.isEmpty ? key : labelInput,
              value: value,
            );
          })
          .where((item) => item.key.trim().isNotEmpty)
          .toList(growable: false),
    );
    final rawContent = fields
        .where((item) => item.key == 'meaning')
        .map((item) => item.asText())
        .join('\n')
        .trim();

    final success = await state.saveWord(
      original: widget.original,
      word: _wordController.text,
      fields: fields,
      rawContent: rawContent,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _addField(AppI18n i18n) async {
    final label = await showTextPromptDialog(
      context: context,
      title: i18n.t('inline.ui.pages.word_editor_page.add_field_698af3'),
      subtitle: i18n.t(
        'inline.ui.pages.word_editor_page.enter_a_display_label_and_a_field_key_will_be_generated_a5f5af',
      ),
    );
    if (!mounted || label == null || label.trim().isEmpty) return;
    setState(() {
      _drafts.add(
        _FieldDraft(
          keyController: TextEditingController(
            text: normalizeFieldKey(label.trim()),
          ),
          labelController: TextEditingController(text: label.trim()),
          valueController: TextEditingController(),
        ),
      );
    });
  }

  void _addPresetField(String key, String label) {
    setState(() {
      _drafts.add(
        _FieldDraft(
          keyController: TextEditingController(text: key),
          labelController: TextEditingController(text: label),
          valueController: TextEditingController(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.original == null
              ? i18n.t('addWordTitle')
              : i18n.t('editWordTitle'),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'examples':
                  _addPresetField(
                    'examples',
                    localizedFieldLabel(
                      i18n,
                      const WordFieldItem(
                        key: 'examples',
                        label: 'Examples',
                        value: '',
                      ),
                    ),
                  );
                case 'etymology':
                  _addPresetField(
                    'etymology',
                    localizedFieldLabel(
                      i18n,
                      const WordFieldItem(
                        key: 'etymology',
                        label: 'Etymology',
                        value: '',
                      ),
                    ),
                  );
                case 'memory':
                  _addPresetField(
                    'memory',
                    localizedFieldLabel(
                      i18n,
                      const WordFieldItem(
                        key: 'memory',
                        label: 'Memory',
                        value: '',
                      ),
                    ),
                  );
                case 'custom':
                  _addField(i18n);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'examples',
                child: Text(
                  i18n.t(
                    'inline.ui.pages.word_editor_page.add_examples_426596',
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'etymology',
                child: Text(
                  i18n.t(
                    'inline.ui.pages.word_editor_page.add_etymology_1403cc',
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'memory',
                child: Text(
                  i18n.t('inline.ui.pages.word_editor_page.add_memory_101a3d'),
                ),
              ),
              PopupMenuItem(
                value: 'custom',
                child: Text(
                  i18n.t(
                    'inline.ui.pages.word_editor_page.add_custom_field_5855af',
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            tooltip: i18n.t('save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          TextField(
            controller: _wordController,
            decoration: InputDecoration(
              labelText: i18n.t('fieldWord'),
              hintText: i18n.t(
                'inline.ui.pages.word_editor_page.for_example_serendipity_cbba60',
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _drafts.length; index += 1) ...[
            _FieldEditorCard(
              index: index,
              draft: _drafts[index],
              canRemove: _drafts.length > 1,
              i18n: i18n,
              onRemove: () {
                setState(() {
                  final removed = _drafts.removeAt(index);
                  removed.dispose();
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _addField(i18n),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              i18n.t('inline.ui.pages.word_editor_page.add_field_698af3'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(
              i18n.t('inline.ui.pages.word_editor_page.save_changes_a21d29'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldEditorCard extends StatelessWidget {
  const _FieldEditorCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.i18n,
    required this.onRemove,
  });

  final int index;
  final _FieldDraft draft;
  final bool canRemove;
  final AppI18n i18n;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '#${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: draft.labelController,
              decoration: InputDecoration(labelText: i18n.t('fieldLabel')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: draft.keyController,
              decoration: InputDecoration(labelText: i18n.t('fieldKey')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: draft.valueController,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: i18n.t('fieldContent')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldDraft {
  _FieldDraft({
    required this.keyController,
    required this.labelController,
    required this.valueController,
  });

  factory _FieldDraft.fromItem(WordFieldItem item) {
    return _FieldDraft(
      keyController: TextEditingController(text: item.key),
      labelController: TextEditingController(text: item.label),
      valueController: TextEditingController(text: item.asText()),
    );
  }

  final TextEditingController keyController;
  final TextEditingController labelController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    labelController.dispose();
    valueController.dispose();
  }
}

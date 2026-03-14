import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../wordbook_localization.dart';
import 'wordbook_editor_page.dart';

class WordbookManagementPage extends StatefulWidget {
  const WordbookManagementPage({super.key});

  @override
  State<WordbookManagementPage> createState() => _WordbookManagementPageState();
}

class _WordbookManagementPageState extends State<WordbookManagementPage> {
  bool _onlineBusy = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pickUiText(
            i18n,
            zh: '词本管理',
            en: 'Wordbook management',
            ja: '単語帳管理',
            de: 'Wortbuchverwaltung',
            fr: 'Gestion des livres de mots',
            es: 'Gestion del libro de palabras',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          _QuickActionCard(
            i18n: i18n,
            onlineBusy: _onlineBusy,
            onCreate: () => _createWordbook(context, state, i18n),
            onImport: () => _importWordbook(context, state, i18n),
            onDownloadOnline: () =>
                _downloadOnlineWordbook(context, state, i18n),
          ),
          const SizedBox(height: 16),
          for (final book in state.wordbooks) ...<Widget>[
            _WordbookCard(
              book: book,
              isCurrent: state.selectedWordbook?.id == book.id,
              i18n: i18n,
              onSelect: () => _selectWordbook(context, state, i18n, book),
              onOpenEditor: () => _openEditor(context, state, book),
              onRename: book.isSystem
                  ? null
                  : () => _renameWordbook(context, state, i18n, book),
              onDelete: book.isSystem
                  ? null
                  : () => _deleteWordbook(context, state, i18n, book),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          FilledButton.tonalIcon(
            onPressed: () => _mergeWordbooks(context, state, i18n),
            icon: const Icon(Icons.merge_type_rounded),
            label: Text(pickUiText(i18n, zh: '合并词本', en: 'Merge wordbooks')),
          ),
        ],
      ),
    );
  }

  Future<void> _createWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '新建词本', en: 'New wordbook'),
      hintText: pickUiText(
        i18n,
        zh: '例如：睡前复习',
        en: 'For example: Night review',
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await state.createWordbook(name.trim());
  }

  Future<void> _importWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '导入单词本', en: 'Import wordbook'),
      message: pickUiText(
        i18n,
        zh: '单词本可能较大，导入与初始化需要一些时间。确认后将继续选择文件，请耐心等待。',
        en: 'Wordbooks can be large, so import and initialization may take a while. Continue to choose a file and please wait patiently.',
      ),
      confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
    );
    if (!confirmed) return;
    await state.importWordbookByPicker(
      requestName: (suggestedName) {
        return showTextPromptDialog(
          context: context,
          title: pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
          subtitle: pickUiText(
            i18n,
            zh: '可以直接使用文件名，也可以在这里修改词本名称。',
            en: 'Use the file name as-is, or rename the wordbook before import.',
          ),
          initialValue: suggestedName,
          hintText: pickUiText(i18n, zh: '词本名称', en: 'Wordbook name'),
          confirmText: pickUiText(i18n, zh: '导入', en: 'Import'),
        );
      },
    );
  }

  Future<void> _selectWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) async {
    if (state.requiresWordbookLoadConfirmation(book)) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: pickUiText(i18n, zh: '初始化单词本', en: 'Initialize wordbook'),
        message: pickUiText(
          i18n,
          zh: '${localizedWordbookName(i18n, book)} 可能较大，首次加载会初始化内容并需要一些时间。确认后继续，请耐心等待。',
          en: '${localizedWordbookName(i18n, book)} may be large. The first load will initialize its contents and may take a while. Continue and please wait patiently.',
        ),
        confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
      );
      if (!confirmed) return;
    }
    await state.selectWordbook(book);
  }

  Future<void> _downloadOnlineWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    if (_onlineBusy) return;
    setState(() {
      _onlineBusy = true;
    });

    List<RemoteWordbookEntry> entries;
    try {
      entries = await GitHubWordbookCatalog.fetch();
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(
        context,
        pickUiText(
          i18n,
          zh: '在线词本列表读取失败：$error',
          en: 'Failed to load online wordbooks: $error',
          ja: 'オンライン単語帳の読み込みに失敗しました: $error',
          de: 'Online-Wortbuecher konnten nicht geladen werden: $error',
          fr: 'Echec du chargement des livres en ligne : $error',
          es: 'No se pudieron cargar los libros en linea: $error',
        ),
      );
      setState(() {
        _onlineBusy = false;
      });
      return;
    }

    if (!context.mounted) return;
    setState(() {
      _onlineBusy = false;
    });

    if (entries.isEmpty) {
      _showMessage(
        context,
        pickUiText(
          i18n,
          zh: '当前仓库中未找到可下载的 JSON 词本。',
          en: 'No downloadable JSON wordbooks were found in the repository.',
          ja: 'リポジトリ内にダウンロード可能な JSON 単語帳が見つかりませんでした。',
          de: 'Im Repository wurden keine herunterladbaren JSON-Wortbuecher gefunden.',
          fr: 'Aucun livre JSON telechargeable n’a ete trouve dans le depot.',
          es: 'No se encontraron libros JSON descargables en el repositorio.',
        ),
      );
      return;
    }

    final selected = await _showOnlineWordbookPicker(context, i18n, entries);
    if (!context.mounted || selected == null) return;

    final importName = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '在线词本导入', en: 'Import online wordbook'),
      subtitle: pickUiText(
        i18n,
        zh: '已选择 ${selected.fileName}，可在导入前调整词本名称。',
        en: 'Selected ${selected.fileName}. You can rename it before import.',
      ),
      initialValue: selected.displayName,
      hintText: pickUiText(i18n, zh: '词本名称', en: 'Wordbook name'),
      confirmText: pickUiText(i18n, zh: '下载并导入', en: 'Download & import'),
    );
    if (!context.mounted || importName == null || importName.trim().isEmpty) {
      return;
    }

    setState(() {
      _onlineBusy = true;
    });

    File? tempFile;
    try {
      final response = await http.get(selected.downloadUri);
      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: selected.downloadUri,
        );
      }

      final tempDir = await getTemporaryDirectory();
      final safeName = selected.fileName.replaceAll(RegExp(r'[^\w\-.]+'), '_');
      tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}_$safeName',
      );
      await tempFile.writeAsBytes(response.bodyBytes, flush: true);
      await state.importWordbookFile(tempFile.path, importName.trim());
    } catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          pickUiText(
            i18n,
            zh: '在线词本下载或导入失败：$error',
            en: 'Failed to download or import the online wordbook: $error',
            ja: 'オンライン単語帳のダウンロードまたはインポートに失敗しました: $error',
            de: 'Das Online-Wortbuch konnte nicht heruntergeladen oder importiert werden: $error',
            fr: 'Le telechargement ou l’importation du livre en ligne a echoue : $error',
            es: 'No se pudo descargar o importar el libro en linea: $error',
          ),
        );
      }
    } finally {
      if (tempFile != null) {
        unawaited(() async {
          try {
            await tempFile!.delete();
          } catch (_) {}
        }());
      }
      if (mounted) {
        setState(() {
          _onlineBusy = false;
        });
      }
    }
  }

  Future<RemoteWordbookEntry?> _showOnlineWordbookPicker(
    BuildContext context,
    AppI18n i18n,
    List<RemoteWordbookEntry> entries,
  ) {
    return showModalBottomSheet<RemoteWordbookEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(
                    i18n,
                    zh: '在线词本',
                    en: 'Online wordbooks',
                    ja: 'オンライン単語帳',
                    de: 'Online-Wortbuecher',
                    fr: 'Livres de mots en ligne',
                    es: 'Libros de palabras en linea',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '来源：GitHub / yixunfei / GPT-WordBooks。选择后将下载对应 JSON 文件并导入应用。',
                    en: 'Source: GitHub / yixunfei / GPT-WordBooks. Pick a JSON file to download and import into the app.',
                    ja: 'ソース: GitHub / yixunfei / GPT-WordBooks。JSON ファイルを選択してアプリへ取り込みます。',
                    de: 'Quelle: GitHub / yixunfei / GPT-WordBooks. Waehlen Sie eine JSON-Datei zum Herunterladen und Importieren.',
                    fr: 'Source : GitHub / yixunfei / GPT-WordBooks. Choisissez un fichier JSON a telecharger puis importer.',
                    es: 'Origen: GitHub / yixunfei / GPT-WordBooks. Elige un archivo JSON para descargarlo e importarlo en la app.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.download_rounded),
                          ),
                          title: Text(entry.displayName),
                          subtitle: Text(entry.fileName),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(entry),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Wordbook book,
  ) async {
    await _selectWordbook(context, state, AppI18n(state.uiLanguage), book);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WordbookEditorPage(wordbookId: book.id),
      ),
    );
  }

  Future<void> _renameWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) async {
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '重命名词本', en: 'Rename wordbook'),
      initialValue: book.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await state.renameWordbook(book, name.trim());
  }

  Future<void> _deleteWordbook(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '删除词本', en: 'Delete wordbook'),
      message: pickUiText(
        i18n,
        zh: '确定删除“${book.name}”吗？',
        en: 'Delete "${book.name}"?',
      ),
      danger: true,
      confirmText: pickUiText(i18n, zh: '删除', en: 'Delete'),
    );
    if (!confirmed) return;
    await state.deleteWordbook(book);
  }

  Future<void> _mergeWordbooks(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final books = state.wordbooks.where((item) => !item.isSystem).toList();
    if (books.length < 2) {
      _showMessage(
        context,
        pickUiText(
          i18n,
          zh: '至少需要两个普通词本才能合并。',
          en: 'You need at least two regular wordbooks to merge.',
        ),
      );
      return;
    }

    var source = books.first;
    var target = books[1];
    var deleteSource = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final targetChoices = books
                .where((item) => item.id != source.id)
                .toList(growable: false);
            if (!targetChoices.any((item) => item.id == target.id)) {
              target = targetChoices.first;
            }
            return AlertDialog(
              title: Text(pickUiText(i18n, zh: '合并词本', en: 'Merge wordbooks')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<Wordbook>(
                    initialValue: source,
                    decoration: InputDecoration(
                      labelText: pickUiText(i18n, zh: '来源词本', en: 'Source'),
                    ),
                    items: books
                        .map(
                          (item) => DropdownMenuItem<Wordbook>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        source = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Wordbook>(
                    initialValue: target,
                    decoration: InputDecoration(
                      labelText: pickUiText(i18n, zh: '目标词本', en: 'Target'),
                    ),
                    items: targetChoices
                        .map(
                          (item) => DropdownMenuItem<Wordbook>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        target = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pickUiText(
                        i18n,
                        zh: '合并后删除来源词本',
                        en: 'Delete source after merge',
                      ),
                    ),
                    value: deleteSource,
                    onChanged: (value) {
                      setStateDialog(() {
                        deleteSource = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    await state.mergeWordbooks(
      sourceWordbookId: source.id,
      targetWordbookId: target.id,
      deleteSourceAfterMerge: deleteSource,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.i18n,
    required this.onlineBusy,
    required this.onCreate,
    required this.onImport,
    required this.onDownloadOnline,
  });

  final AppI18n i18n;
  final bool onlineBusy;
  final VoidCallback onCreate;
  final VoidCallback onImport;
  final VoidCallback onDownloadOnline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '快速操作', en: 'Quick actions'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '新建、导入，或从 GitHub 在线词库下载对应的 JSON 词本。./dict 目录下的 JSON 会被识别为内置词本，并在首次打开时加载。',
                en: 'Create, import, or download matching JSON wordbooks from GitHub. JSON files under ./dict become built-ins and load on first open.',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(pickUiText(i18n, zh: '新增词本', en: 'New wordbook')),
                ),
                FilledButton.tonalIcon(
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    pickUiText(i18n, zh: '导入词本', en: 'Import wordbook'),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onlineBusy ? null : onDownloadOnline,
                  icon: Icon(
                    onlineBusy
                        ? Icons.downloading_rounded
                        : Icons.cloud_download_rounded,
                  ),
                  label: Text(
                    onlineBusy
                        ? pickUiText(i18n, zh: '处理中…', en: 'Processing...')
                        : pickUiText(
                            i18n,
                            zh: '下载在线词本',
                            en: 'Download online wordbooks',
                            ja: 'オンライン単語帳をダウンロード',
                            de: 'Online-Wortbuecher laden',
                            fr: 'Telecharger des livres en ligne',
                            es: 'Descargar libros en linea',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WordbookCard extends StatelessWidget {
  const _WordbookCard({
    required this.book,
    required this.isCurrent,
    required this.i18n,
    required this.onSelect,
    required this.onOpenEditor,
    this.onRename,
    this.onDelete,
  });

  final Wordbook book;
  final bool isCurrent;
  final AppI18n i18n;
  final VoidCallback onSelect;
  final VoidCallback onOpenEditor;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = pickUiText(
      i18n,
      zh: book.isSystem
          ? '${book.wordCount} 个词 · 内置词本'
          : '${book.wordCount} 个词 · 自定义词本',
      en: book.isSystem
          ? '${book.wordCount} words · built-in'
          : '${book.wordCount} words · custom',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                child: Icon(
                  book.isSystem
                      ? Icons.inventory_2_rounded
                      : Icons.collections_bookmark_rounded,
                ),
              ),
              title: Text(localizedWordbookName(i18n, book)),
              subtitle: Text(subtitle),
              selected: isCurrent,
              onTap: onSelect,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: isCurrent ? null : onSelect,
                    icon: Icon(
                      isCurrent
                          ? Icons.check_circle_rounded
                          : Icons.navigation_rounded,
                    ),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: isCurrent ? '当前使用' : '设为当前',
                        en: isCurrent ? 'Current' : 'Use',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenEditor,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(pickUiText(i18n, zh: '编辑', en: 'Edit')),
                  ),
                  if (onRename != null)
                    OutlinedButton.icon(
                      onPressed: onRename,
                      icon: const Icon(Icons.drive_file_rename_outline_rounded),
                      label: Text(pickUiText(i18n, zh: '重命名', en: 'Rename')),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteWordbookEntry {
  const RemoteWordbookEntry({
    required this.fileName,
    required this.repositoryPath,
  });

  final String fileName;
  final String repositoryPath;

  String get displayName =>
      fileName.replaceFirst(RegExp(r'\.json$', caseSensitive: false), '');

  Uri get downloadUri => Uri.parse(
    'https://raw.githubusercontent.com/'
    '${GitHubWordbookCatalog.owner}/'
    '${GitHubWordbookCatalog.repository}/'
    '${GitHubWordbookCatalog.branch}/'
    '${Uri.encodeComponent(repositoryPath).replaceAll('%2F', '/')}',
  );
}

class GitHubWordbookCatalog {
  const GitHubWordbookCatalog._();

  static const String owner = 'yixunfei';
  static const String repository = 'GPT-WordBooks';
  static const String branch = 'main';

  static Uri get repositoryUri =>
      Uri.parse('https://github.com/$owner/$repository');

  static Future<List<RemoteWordbookEntry>> fetch({http.Client? client}) async {
    final activeClient = client ?? http.Client();
    final shouldClose = client == null;
    try {
      final response = await activeClient.get(
        repositoryUri,
        headers: const <String, String>{'accept': 'text/html'},
      );
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: repositoryUri);
      }
      return parseRepositoryHtml(response.body);
    } finally {
      if (shouldClose) {
        activeClient.close();
      }
    }
  }

  @visibleForTesting
  static List<RemoteWordbookEntry> parseRepositoryHtml(String html) {
    final scriptMatch = RegExp(
      r'react-app\.embeddedData">(.+?)</script>',
      dotAll: true,
    ).firstMatch(html);
    if (scriptMatch != null) {
      try {
        final payload =
            json.decode(scriptMatch.group(1)!) as Map<String, dynamic>;
        final payloadMap = payload['payload'];
        final route = payloadMap is Map<String, dynamic>
            ? payloadMap['codeViewRepoRoute']
            : null;
        final tree = route is Map<String, dynamic> ? route['tree'] : null;
        final items = tree is Map<String, dynamic> ? tree['items'] : null;
        if (items is List) {
          final entries = items
              .whereType<Map>()
              .map((item) {
                final name = '${item['name'] ?? ''}'.trim();
                final path = '${item['path'] ?? ''}'.trim();
                final type = '${item['contentType'] ?? ''}'.trim();
                if (type != 'file' || !name.toLowerCase().endsWith('.json')) {
                  return null;
                }
                return RemoteWordbookEntry(
                  fileName: name,
                  repositoryPath: path,
                );
              })
              .whereType<RemoteWordbookEntry>()
              .toList(growable: false);
          if (entries.isNotEmpty) {
            return entries;
          }
        }
      } catch (_) {}
    }

    final matches = RegExp(r'"path":"([^"]+\.json)"').allMatches(html);
    final seen = <String>{};
    final entries = <RemoteWordbookEntry>[];
    for (final match in matches) {
      final path = match.group(1);
      if (path == null || !seen.add(path)) continue;
      entries.add(
        RemoteWordbookEntry(
          fileName: path.split('/').last,
          repositoryPath: path,
        ),
      );
    }
    return entries;
  }
}

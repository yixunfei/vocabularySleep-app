import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/wordbook.dart';
import '../services/database_service.dart';
import '../services/wordbook_import_service.dart';
import '../utils/search_text_normalizer.dart' as search_text;
import 'app_state.dart' show SearchMode;

class WordbookState extends ChangeNotifier {
  WordbookState({required AppDatabaseService database}) : _database = database;

  final AppDatabaseService _database;

  List<Wordbook> _wordbooks = <Wordbook>[];
  Wordbook? _selectedWordbook;
  List<WordEntry> _words = <WordEntry>[];
  int _currentWordIndex = 0;
  int _wordsVersion = 0;

  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  List<WordEntry>? _visibleWordsCache;
  int _visibleWordsCacheVersion = -1;
  String _visibleWordsCacheQuery = '';
  SearchMode _visibleWordsCacheMode = SearchMode.all;

  Set<String> _favorites = <String>{};
  Set<String> _taskWords = <String>{};
  Set<String> _rememberedWords = <String>{};

  bool _wordbookImportActive = false;
  String _wordbookImportName = '';
  int _wordbookImportProcessedEntries = 0;
  int? _wordbookImportTotalEntries;

  List<Wordbook> get wordbooks => List.unmodifiable(_wordbooks);
  Wordbook? get selectedWordbook => _selectedWordbook;
  List<WordEntry> get words => List.unmodifiable(_words);
  int get currentWordIndex => _currentWordIndex;
  int get wordsVersion => _wordsVersion;
  String get searchQuery => _searchQuery;
  SearchMode get searchMode => _searchMode;
  Set<String> get favorites => Set.unmodifiable(_favorites);
  Set<String> get taskWords => Set.unmodifiable(_taskWords);
  Set<String> get rememberedWords => Set.unmodifiable(_rememberedWords);
  bool get wordbookImportActive => _wordbookImportActive;
  String get wordbookImportName => _wordbookImportName;
  int get wordbookImportProcessedEntries => _wordbookImportProcessedEntries;
  int? get wordbookImportTotalEntries => _wordbookImportTotalEntries;

  double? get wordbookImportProgress {
    final total = _wordbookImportTotalEntries;
    if (!_wordbookImportActive || total == null || total <= 0) return null;
    return (_wordbookImportProcessedEntries / total).clamp(0.0, 1.0);
  }

  List<WordEntry> get visibleWords {
    if (_visibleWordsCacheVersion == _wordsVersion &&
        _visibleWordsCacheQuery == _searchQuery &&
        _visibleWordsCacheMode == _searchMode) {
      return _visibleWordsCache ?? _words;
    }
    _visibleWordsCache = _computeVisibleWords();
    _visibleWordsCacheVersion = _wordsVersion;
    _visibleWordsCacheQuery = _searchQuery;
    _visibleWordsCacheMode = _searchMode;
    return _visibleWordsCache ?? _words;
  }

  int get visibleWordCount => visibleWords.length;
  int get totalWordCount => _words.length;
  int get favoriteCount => _favorites.length;
  int get taskWordCount => _taskWords.length;

  List<WordEntry> _computeVisibleWords() {
    final query = _searchQuery.trim();
    if (query.isEmpty && _searchMode == SearchMode.all) return _words;

    final normalizedQuery = search_text.normalizeSearchText(query);

    return _words.where((word) {
      if (_searchMode == SearchMode.word) {
        return search_text
            .normalizeSearchText(word.word)
            .contains(normalizedQuery);
      }
      if (_searchMode == SearchMode.meaning) {
        return (word.meaning ?? '').toLowerCase().contains(query.toLowerCase());
      }
      if (_searchMode == SearchMode.fuzzy) {
        return _matchesFuzzy(word, normalizedQuery);
      }
      return word.word.toLowerCase().contains(query.toLowerCase()) ||
          (word.meaning ?? '').toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  bool _matchesFuzzy(WordEntry word, String normalizedQuery) {
    final wordText = search_text.normalizeSearchText(word.word);
    if (wordText.contains(normalizedQuery)) return true;

    final queryChars = normalizedQuery.split('');
    int wordIndex = 0;
    for (final char in queryChars) {
      wordIndex = wordText.indexOf(char, wordIndex);
      if (wordIndex == -1) return false;
      wordIndex++;
    }
    return true;
  }

  Future<void> loadWordbooks() async {
    _wordbooks = _database.getWordbooks();
    notifyListeners();
  }

  Future<bool> selectWordbook(
    Wordbook? wordbook, {
    String? focusWord,
    int? focusWordId,
  }) async {
    if (wordbook == null) return false;

    if (_database.isLazyBuiltInPath(wordbook.path) && wordbook.wordCount <= 0) {
      final lazyWordbookName = wordbook.name;
      final lazyPath = wordbook.path;

      _wordbookImportActive = true;
      _wordbookImportName = lazyWordbookName;
      _wordbookImportProcessedEntries = 0;
      notifyListeners();

      try {
        await _database.ensureBuiltInWordbookLoaded(
          lazyPath,
          onProgress: (progress) {
            _wordbookImportProcessedEntries =
                (((progress.receivedBytes ?? 0) / (progress.totalBytes ?? 1)) *
                        100)
                    .toInt();
            _wordbookImportTotalEntries = 100;
            notifyListeners();
          },
        );
        await loadWordbooks();
        wordbook =
            _wordbooks
                .where((item) => item.path == lazyPath)
                .cast<Wordbook?>()
                .firstOrNull ??
            wordbook;
      } catch (error) {
        debugPrint('Lazy built-in wordbook load failed: $error');
        _wordbookImportActive = false;
        notifyListeners();
        return false;
      } finally {
        _wordbookImportActive = false;
        notifyListeners();
      }
    }

    _selectedWordbook = wordbook;
    _words = _database.getWords(wordbook.id);
    _currentWordIndex = 0;
    _wordsVersion++;

    if (focusWordId != null) {
      final index = _words.indexWhere((item) => item.id == focusWordId);
      if (index >= 0) _currentWordIndex = index;
    } else if ((focusWord ?? '').isNotEmpty) {
      final index = _words.indexWhere((item) => item.word == focusWord!.trim());
      if (index >= 0) _currentWordIndex = index;
    }

    _invalidateVisibleWordsCache();
    notifyListeners();
    return true;
  }

  void _invalidateVisibleWordsCache() {
    _visibleWordsCache = null;
    _visibleWordsCacheVersion = -1;
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _invalidateVisibleWordsCache();
    notifyListeners();
  }

  void setSearchMode(SearchMode mode) {
    if (_searchMode == mode) return;
    _searchMode = mode;
    _invalidateVisibleWordsCache();
    notifyListeners();
  }

  Future<void> toggleFavorite(String word) async {
    final favoritesBook = _wordbooks
        .where((item) => item.path == 'builtin:favorites')
        .cast<Wordbook?>()
        .firstOrNull;
    if (favoritesBook == null) return;

    final wasFavorite = _favorites.contains(word);
    if (wasFavorite) {
      _favorites.remove(word);
      _database.deleteWord(favoritesBook.id, word);
    } else {
      _favorites.add(word);
    }
    _persistSpecialWordSet('favorites', _favorites);
    _updateWordbookCount(favoritesBook.path, wasFavorite ? -1 : 1);
    notifyListeners();
  }

  Future<void> toggleTaskWord(String word) async {
    final taskBook = _wordbooks
        .where((item) => item.path == 'builtin:task')
        .cast<Wordbook?>()
        .firstOrNull;
    if (taskBook == null) return;

    final wasTaskWord = _taskWords.contains(word);
    if (wasTaskWord) {
      _taskWords.remove(word);
      _database.deleteWord(taskBook.id, word);
    } else {
      _taskWords.add(word);
    }
    _persistSpecialWordSet('taskWords', _taskWords);
    _updateWordbookCount(taskBook.path, wasTaskWord ? -1 : 1);
    notifyListeners();
  }

  void _persistSpecialWordSet(String type, Set<String> words) {
    final filename = type == 'favorites' ? 'favorites.txt' : 'task.txt';
    final file = File(path.join(path.dirname(_database.dbPath), filename));
    file.writeAsStringSync(words.join('\n'));
  }

  void _updateWordbookCount(String path, int delta) {
    final index = _wordbooks.indexWhere((item) => item.path == path);
    if (index == -1) return;
    final book = _wordbooks[index];
    _wordbooks[index] = Wordbook(
      id: book.id,
      name: book.name,
      path: book.path,
      wordCount: (book.wordCount + delta).clamp(0, 999999),
      createdAt: book.createdAt,
    );
  }

  void startWordbookImport(String name, int totalEntries) {
    _wordbookImportActive = true;
    _wordbookImportName = name;
    _wordbookImportProcessedEntries = 0;
    _wordbookImportTotalEntries = totalEntries;
    notifyListeners();
  }

  void updateImportProgress(int processedEntries) {
    _wordbookImportProcessedEntries = processedEntries;
    notifyListeners();
  }

  void finishWordbookImport() {
    _wordbookImportActive = false;
    _wordbookImportName = '';
    _wordbookImportProcessedEntries = 0;
    _wordbookImportTotalEntries = null;
    notifyListeners();
  }

  void cancelWordbookImport() {
    _wordbookImportActive = false;
    _wordbookImportName = '';
    _wordbookImportProcessedEntries = 0;
    _wordbookImportTotalEntries = null;
    notifyListeners();
  }

  Future<List<WordEntry>> getVisibleWordsPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final allWords = visibleWords;
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= allWords.length) return <WordEntry>[];

    final endIndex = (startIndex + pageSize).clamp(0, allWords.length);
    return allWords.sublist(startIndex, endIndex);
  }

  Future<bool> importKaikkiJson(File jsonFile, {String? wordbookName}) async {
    try {
      final content = await jsonFile.readAsString();
      final data = jsonDecode(content);

      if (data is! List) {
        throw FormatException('Invalid kaikki.org JSON format: expected array');
      }

      final wordbook = await _createOrUpdateWordbook(
        wordbookName ?? path.basenameWithoutExtension(jsonFile.path),
      );

      await _processKaikkiData(data, wordbook);

      await loadWordbooks();
      return true;
    } catch (error) {
      debugPrint('Kaikki JSON import failed: $error');
      return false;
    }
  }

  Future<Wordbook> _createOrUpdateWordbook(String name) async {
    final existing = _wordbooks
        .where((w) => w.name == name)
        .cast<Wordbook?>()
        .firstOrNull;

    if (existing != null) return existing;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = 'imported/$name-$timestamp';

    _database.ensureSpecialWordbooks();

    final entries = <WordEntryPayload>[];
    await _database.importWordbook(
      sourcePath: newPath,
      name: name,
      entries: entries,
      replaceExisting: true,
    );

    await loadWordbooks();
    final created = _wordbooks
        .where((w) => w.path == newPath)
        .cast<Wordbook?>()
        .firstOrNull;
    if (created == null) {
      throw StateError('Failed to create wordbook: $name');
    }
    return created;
  }

  Future<void> _processKaikkiData(List<dynamic> data, Wordbook wordbook) async {
    final payloads = <WordEntryPayload>[];

    for (final entry in data) {
      if (entry is! Map) continue;

      final payload = _parseKaikkiEntry(entry);
      if (payload == null) continue;

      payloads.add(payload);

      if (payloads.length >= 100) {
        await _importBatch(wordbook, payloads);
        payloads.clear();
      }
    }

    if (payloads.isNotEmpty) {
      await _importBatch(wordbook, payloads);
    }
  }

  Future<void> _importBatch(
    Wordbook wordbook,
    List<WordEntryPayload> payloads,
  ) async {
    await _database.importWordbookAsync(
      sourcePath: wordbook.path,
      name: wordbook.name,
      entries: payloads,
      replaceExisting: false,
      onProgress: (processed, total) {
        if (total != null) {
          _wordbookImportProcessedEntries += processed;
          notifyListeners();
        }
      },
    );
  }

  WordEntryPayload? _parseKaikkiEntry(Map entry) {
    final word = entry['word'] as String?;
    if (word == null || word.trim().isEmpty) return null;

    final rawFields = <String, Object?>{};
    final dynamicFields = <WordFieldItem>[];

    if (entry['sense'] is List) {
      final senses = entry['sense'] as List;
      final meanings = <String>[];
      final examples = <String>[];

      for (final sense in senses) {
        if (sense is! Map) continue;

        final glosses = sense['glosses'] as List?;
        if (glosses != null) {
          meanings.addAll(glosses.where((g) => g is String).cast<String>());
        }

        final senseExamples = sense['examples'] as List?;
        if (senseExamples != null) {
          for (final ex in senseExamples) {
            if (ex is Map) {
              final text = ex['text'] as String?;
              if (text != null && text.isNotEmpty) {
                examples.add(text);
              }
            }
          }
        }
      }

      if (meanings.isNotEmpty) {
        rawFields['meaning'] = meanings.join('; ');
      }
      if (examples.isNotEmpty) {
        rawFields['examples'] = examples;
      }
    }

    if (entry['sounds'] is List) {
      final sounds = entry['sounds'] as List;
      final ipas = <String>[];
      final audioUrls = <String>[];

      for (final sound in sounds) {
        if (sound is! Map) continue;

        final ipa = sound['ipa'] as String?;
        if (ipa != null && ipa.isNotEmpty) {
          ipas.add(ipa);
        }

        final wavUrl = sound['wav'] as String?;
        final oggUrl = sound['ogg'] as String?;
        if (wavUrl != null && wavUrl.isNotEmpty) {
          audioUrls.add(wavUrl);
        } else if (oggUrl != null && oggUrl.isNotEmpty) {
          audioUrls.add(oggUrl);
        }
      }

      if (ipas.isNotEmpty) {
        rawFields['ipa'] = ipas.join('; ');
      }
      if (audioUrls.isNotEmpty) {
        rawFields['audio_urls'] = audioUrls;
      }
    }

    entry.forEach((key, value) {
      if (key is! String) return;
      if (key == 'word' ||
          key == 'lang_code' ||
          key == 'pos' ||
          key == 'sense' ||
          key == 'sounds') {
        return;
      }

      final normalizedKey = normalizeFieldKey(key);
      if (normalizedKey.isNotEmpty && value != null) {
        dynamicFields.add(
          WordFieldItem(key: normalizedKey, label: key, value: value),
        );
      }
    });

    final allFields = mergeFieldItems(<WordFieldItem>[
      ...buildFieldItemsFromRecord(rawFields),
      ...dynamicFields,
    ]);

    return WordEntryPayload(
      word: word!.trim(),
      fields: allFields,
      rawContent: jsonEncode(entry),
    );
  }

  Future<bool> importDynamicJson(
    File jsonFile, {
    String? wordbookName,
    Map<String, String>? fieldMappings,
  }) async {
    try {
      final content = await jsonFile.readAsString();
      final data = jsonDecode(content);

      List<dynamic> entries;
      if (data is List) {
        entries = data;
      } else if (data is Map && data['words'] is List) {
        entries = data['words'] as List;
      } else if (data is Map) {
        entries = [data];
      } else {
        throw FormatException('Unsupported JSON structure');
      }

      final wordbook = await _createOrUpdateWordbook(
        wordbookName ?? path.basenameWithoutExtension(jsonFile.path),
      );

      await _processDynamicJsonData(entries, wordbook, fieldMappings ?? {});

      await loadWordbooks();
      return true;
    } catch (error) {
      debugPrint('Dynamic JSON import failed: $error');
      return false;
    }
  }

  Future<void> _processDynamicJsonData(
    List<dynamic> entries,
    Wordbook wordbook,
    Map<String, String> fieldMappings,
  ) async {
    final payloads = <WordEntryPayload>[];

    for (final entry in entries) {
      if (entry is! Map) continue;

      final payload = _parseDynamicEntry(entry, fieldMappings);
      if (payload == null) continue;

      payloads.add(payload);

      if (payloads.length >= 100) {
        await _importBatch(wordbook, payloads);
        payloads.clear();
      }
    }

    if (payloads.isNotEmpty) {
      await _importBatch(wordbook, payloads);
    }
  }

  WordEntryPayload? _parseDynamicEntry(
    Map entry,
    Map<String, String> fieldMappings,
  ) {
    String? word;
    final rawFields = <String, Object?>{};
    final dynamicFields = <WordFieldItem>[];

    entry.forEach((key, value) {
      if (key is! String) return;

      final normalizedKey = normalizeFieldKey(key);
      final mappedKey = fieldMappings[normalizedKey] ?? normalizedKey;

      if (isWordKey(key)) {
        word = '$value'.trim();
      } else if (mappedKey.isNotEmpty && value != null) {
        final fieldValue = normalizeFieldValue(value);
        if (fieldValue != null) {
          rawFields[mappedKey] = fieldValue;
          dynamicFields.add(
            WordFieldItem(key: normalizedKey, label: key, value: fieldValue),
          );
        }
      }
    });

    if (word == null || (word!).trim().isEmpty) return null;

    final allFields = mergeFieldItems(<WordFieldItem>[
      ...buildFieldItemsFromRecord(rawFields),
      ...dynamicFields,
    ]);

    return WordEntryPayload(
      word: (word!).trim(),
      fields: allFields,
      rawContent: jsonEncode(entry),
    );
  }

  @override
  void dispose() {
    _wordbooks.clear();
    _words.clear();
    _favorites.clear();
    _taskWords.clear();
    _rememberedWords.clear();
    super.dispose();
  }
}

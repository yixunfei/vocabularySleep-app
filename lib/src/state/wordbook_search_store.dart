import '../models/word_entry.dart';

class WordbookSearchSnapshot {
  const WordbookSearchSnapshot({
    required this.signature,
    required this.loading,
    required this.entries,
    required this.totalCount,
  });

  static const idle = WordbookSearchSnapshot(
    signature: '',
    loading: false,
    entries: <WordEntry>[],
    totalCount: 0,
  );

  final String signature;
  final bool loading;
  final List<WordEntry> entries;
  final int totalCount;
}

class WordbookSearchRequest {
  const WordbookSearchRequest({
    required this.generation,
    required this.wordbookId,
    required this.query,
    required this.mode,
    required this.signature,
  });

  final int generation;
  final int wordbookId;
  final String query;
  final String mode;
  final String signature;
}

class WordbookSearchStore {
  WordbookSearchSnapshot _snapshot = WordbookSearchSnapshot.idle;
  WordbookSearchRequest? _pendingRequest;
  int _generation = 0;
  int _revision = 0;

  WordbookSearchSnapshot get snapshot => _snapshot;
  int get revision => _revision;

  void schedule({
    required int wordbookId,
    required String query,
    required String mode,
  }) {
    final generation = ++_generation;
    final signature = wordbookSearchSignature(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    _pendingRequest = WordbookSearchRequest(
      generation: generation,
      wordbookId: wordbookId,
      query: query,
      mode: mode,
      signature: signature,
    );
    _snapshot = WordbookSearchSnapshot(
      signature: signature,
      loading: true,
      entries: const <WordEntry>[],
      totalCount: 0,
    );
    _revision += 1;
  }

  WordbookSearchRequest? takePendingRequest() {
    final request = _pendingRequest;
    _pendingRequest = null;
    return request;
  }

  bool complete({
    required WordbookSearchRequest request,
    required List<WordEntry> entries,
    required int totalCount,
  }) {
    if (request.generation != _generation ||
        _snapshot.signature != request.signature) {
      return false;
    }
    _snapshot = WordbookSearchSnapshot(
      signature: request.signature,
      loading: false,
      entries: entries,
      totalCount: totalCount,
    );
    _revision += 1;
    return true;
  }

  void cancel() {
    _generation += 1;
    _pendingRequest = null;
    if (_snapshot == WordbookSearchSnapshot.idle) {
      return;
    }
    _snapshot = WordbookSearchSnapshot.idle;
    _revision += 1;
  }
}

String wordbookSearchSignature({
  required int wordbookId,
  required String query,
  required String mode,
}) => '$wordbookId\u0000$mode\u0000${query.trim()}';

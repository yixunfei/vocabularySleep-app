import 'dart:typed_data';

/// Platform-neutral resource contract. Implementations may persist bytes
/// differently, but callers never depend on a native File or Directory.
abstract interface class ResourceStore {
  Future<List<String>> listKeys(String prefix);
  Future<Uint8List> readBytes(
    String key, {
    void Function(int, int)? onProgress,
  });
  Future<String> readText(String key, {void Function(int, int)? onProgress});
  Future<bool> contains(String key);
  Future<void> remove(String key);
  Future<void> close();
}

/// In-memory browser resource store. Remote fetching is intentionally explicit
/// through [fetch], so Web callers can use URL/HTTP without native file APIs.
class WebResourceStore implements ResourceStore {
  WebResourceStore({this.fetch});

  final Future<Uint8List> Function(String key)? fetch;
  final Map<String, Uint8List> _values = <String, Uint8List>{};

  @override
  Future<List<String>> listKeys(String prefix) async => _values.keys
      .where((key) => key.startsWith(prefix))
      .toList(growable: false);

  @override
  Future<Uint8List> readBytes(
    String key, {
    void Function(int, int)? onProgress,
  }) async {
    final cached = _values[key];
    if (cached != null) return Uint8List.fromList(cached);
    final loader = fetch;
    if (loader == null) throw StateError('Web resource is unavailable: $key');
    final bytes = await loader(key);
    _values[key] = Uint8List.fromList(bytes);
    onProgress?.call(bytes.length, bytes.length);
    return Uint8List.fromList(bytes);
  }

  @override
  Future<String> readText(
    String key, {
    void Function(int, int)? onProgress,
  }) async =>
      String.fromCharCodes(await readBytes(key, onProgress: onProgress));

  @override
  Future<bool> contains(String key) async => _values.containsKey(key);

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> close() async => _values.clear();
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const String _moodistTreeApi =
    'https://api.github.com/repos/remvze/moodist/git/trees/main?recursive=1';
const String _moodistRawBase =
    'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds';

const List<_RemoteResource> _legacyLofiResources = <_RemoteResource>[
  _RemoteResource(
    url: 'https://www.ppbzy.com/audio/Lofi/Chill/Lofi%20chill%201.m4a',
    relativePath: 'music/legacy_lofi/chill/chill-1.m4a',
    source: 'legacy_ppbzy',
  ),
  _RemoteResource(
    url: 'https://www.ppbzy.com/audio/Lofi/Study/Lofi%20study%201.m4a',
    relativePath: 'music/legacy_lofi/study/study-1.m4a',
    source: 'legacy_ppbzy',
  ),
  _RemoteResource(
    url: 'https://www.ppbzy.com/audio/Lofi/Sleep/Lofi%20sleep%201.m4a',
    relativePath: 'music/legacy_lofi/sleep/sleep-1.m4a',
    source: 'legacy_ppbzy',
  ),
  _RemoteResource(
    url: 'https://www.ppbzy.com/audio/Lofi/Jazz/Lofi%20jazz%201.m4a',
    relativePath: 'music/legacy_lofi/jazz/jazz-1.m4a',
    source: 'legacy_ppbzy',
  ),
  _RemoteResource(
    url: 'https://www.ppbzy.com/audio/Lofi/Piano/Lofi%20piano%201.m4a',
    relativePath: 'music/legacy_lofi/piano/piano-1.m4a',
    source: 'legacy_ppbzy',
  ),
];

Future<void> main(List<String> args) async {
  final outputRoot = args.isEmpty ? 'modlist_music' : args.first;
  final rootDir = Directory(outputRoot);
  await rootDir.create(recursive: true);

  final client = http.Client();
  try {
    final manifest = <Map<String, Object?>>[];

    await _copyDirectory(
      source: Directory('music'),
      destination: Directory(p.join(rootDir.path, 'music')),
      manifest: manifest,
      sourceLabel: 'local_music',
    );
    await _copyDirectory(
      source: Directory('assets/wordbooks'),
      destination: Directory(p.join(rootDir.path, 'wordbooks')),
      manifest: manifest,
      sourceLabel: 'wordbook_fallback',
    );

    final moodistResources = await _fetchMoodistResources(client);
    final remoteResources = <_RemoteResource>[
      ...moodistResources,
      ..._legacyLofiResources,
    ];

    var completed = 0;
    for (final resource in remoteResources) {
      completed += 1;
      final targetFile = File(p.join(rootDir.path, resource.relativePath));
      await targetFile.parent.create(recursive: true);
      if (await targetFile.exists() && await targetFile.length() > 0) {
        stdout.writeln(
          '[skip $completed/${remoteResources.length}] ${resource.relativePath}',
        );
        manifest.add(<String, Object?>{
          'type': 'remote',
          'status': 'cached',
          'source': resource.source,
          'url': resource.url,
          'path': resource.relativePath,
          'size': await targetFile.length(),
        });
        continue;
      }

      stdout.writeln(
        '[download $completed/${remoteResources.length}] ${resource.relativePath}',
      );
      try {
        final response = await client.get(Uri.parse(resource.url));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'HTTP ${response.statusCode}',
            uri: Uri.parse(resource.url),
          );
        }
        await targetFile.writeAsBytes(response.bodyBytes, flush: true);
        manifest.add(<String, Object?>{
          'type': 'remote',
          'status': 'downloaded',
          'source': resource.source,
          'url': resource.url,
          'path': resource.relativePath,
          'size': response.bodyBytes.length,
        });
      } catch (error) {
        manifest.add(<String, Object?>{
          'type': 'remote',
          'status': 'failed',
          'source': resource.source,
          'url': resource.url,
          'path': resource.relativePath,
          'error': '$error',
        });
        stderr.writeln('[failed] ${resource.relativePath}: $error');
      }
    }

    final manifestFile = File(p.join(rootDir.path, 'resource-manifest.json'));
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'generatedAt': DateTime.now().toIso8601String(),
        'outputRoot': p.normalize(rootDir.path),
        'items': manifest,
      }),
      flush: true,
    );
    stdout.writeln('Manifest written to ${manifestFile.path}');
  } finally {
    client.close();
  }
}

Future<List<_RemoteResource>> _fetchMoodistResources(http.Client client) async {
  final response = await client.get(
    Uri.parse(_moodistTreeApi),
    headers: const <String, String>{'User-Agent': 'Codex'},
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to fetch Moodist tree: ${response.statusCode}',
      uri: Uri.parse(_moodistTreeApi),
    );
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map || decoded['tree'] is! List) {
    throw const FormatException('Unexpected Moodist tree response');
  }

  final resources = <_RemoteResource>[];
  for (final item in decoded['tree'] as List) {
    if (item is! Map) continue;
    final type = '${item['type'] ?? ''}'.trim();
    final path = '${item['path'] ?? ''}'.trim();
    final isAudio = path.endsWith('.mp3') || path.endsWith('.wav');
    if (type != 'blob' || !path.startsWith('public/sounds/') || !isAudio) {
      continue;
    }
    final relativePath = path.substring('public/sounds/'.length);
    resources.add(
      _RemoteResource(
        url: '$_moodistRawBase/$relativePath',
        relativePath: p.join('ambient', 'moodist', relativePath),
        source: 'moodist',
      ),
    );
  }

  resources.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return resources;
}

Future<void> _copyDirectory({
  required Directory source,
  required Directory destination,
  required List<Map<String, Object?>> manifest,
  required String sourceLabel,
}) async {
  if (!await source.exists()) {
    return;
  }
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: source.path);
    final target = File(p.join(destination.path, relative));
    await target.parent.create(recursive: true);
    await entity.copy(target.path);
    manifest.add(<String, Object?>{
      'type': 'local_copy',
      'status': 'copied',
      'source': sourceLabel,
      'from': p.normalize(entity.path),
      'path': p.relative(target.path, from: destination.parent.path),
      'size': await target.length(),
    });
  }
}

class _RemoteResource {
  const _RemoteResource({
    required this.url,
    required this.relativePath,
    required this.source,
  });

  final String url;
  final String relativePath;
  final String source;
}

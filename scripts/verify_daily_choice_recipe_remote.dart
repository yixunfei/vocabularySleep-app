import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:vocabulary_sleep_app/src/services/s3_bucket_probe.dart';

Future<void> main(List<String> args) async {
  final endpoint = _envOrArg('S3_ENDPOINT', args, '--endpoint');
  final bucket = _envOrArg('S3_BUCKET', args, '--bucket');
  final accessKeyId = _envOrArg('S3_ACCESS_KEY_ID', args, '--access-key-id');
  final secretAccessKey = _envOrArg(
    'S3_SECRET_ACCESS_KEY',
    args,
    '--secret-access-key',
  );
  final region = _envOrArg(
    'S3_REGION',
    args,
    '--region',
    fallback: 'us-east-1',
  );
  final userAgent = _envOrArg('S3_USER_AGENT', args, '--user-agent');
  final key = _argValue(
    args,
    '--key',
    fallback: 'cook_data/daily_choice_recipe_library.db',
  );
  final expectedCount = int.tryParse(
    _argValue(args, '--expected-count', fallback: '7772'),
  );
  final keepDownload = args.contains('--keep');

  if (endpoint.isEmpty ||
      bucket.isEmpty ||
      accessKeyId.isEmpty ||
      secretAccessKey.isEmpty) {
    stderr.writeln(
      'Missing S3 configuration. Provide env vars or args for endpoint, '
      'bucket, access key, and secret.',
    );
    exitCode = 64;
    return;
  }

  final client = S3BucketProbeClient(
    config: S3BucketProbeConfig(
      endpoint: endpoint,
      bucket: bucket,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      region: region,
      userAgent: userAgent.isEmpty ? null : userAgent,
    ),
  );
  final tempDirectory = await Directory.systemTemp.createTemp(
    'daily_choice_recipe_remote_verify_',
  );
  final databaseFile = File(
    '${tempDirectory.path}${Platform.pathSeparator}daily_choice_recipe_library.db',
  );

  try {
    stdout.writeln('Remote key: $key');
    final head = await client.headObject(key);
    _require(head.contentLength > 0, 'Remote DB has empty content length.');
    stdout.writeln('Content-Length: ${head.contentLength}');
    stdout.writeln('Last-Modified: ${head.lastModified}');

    await client.downloadObjectToFile(key, databaseFile);
    final downloadedBytes = await databaseFile.length();
    _require(
      downloadedBytes == head.contentLength,
      'Downloaded size $downloadedBytes does not match HEAD ${head.contentLength}.',
    );
    stdout.writeln('Downloaded: ${databaseFile.path}');

    final db = sqlite3.open(databaseFile.path);
    try {
      final hasV1Summary = _tableExists(
        db,
        'daily_choice_eat_recipe_summaries',
      );
      final hasV1Detail = _tableExists(db, 'daily_choice_eat_recipe_details');
      _require(hasV1Summary, 'Missing v1 summary table.');
      _require(hasV1Detail, 'Missing v1 detail table.');

      final summaryCount = _countRows(db, 'daily_choice_eat_recipe_summaries');
      final detailCount = _countRows(db, 'daily_choice_eat_recipe_details');
      _require(summaryCount > 0, 'No recipe summaries found.');
      _require(detailCount > 0, 'No recipe details found.');
      if (expectedCount != null && expectedCount > 0) {
        _require(
          summaryCount == expectedCount,
          'Expected $expectedCount summaries but found $summaryCount.',
        );
      }
      stdout.writeln('v1 summaries: $summaryCount');
      stdout.writeln('v1 details: $detailCount');

      final meta = _readMeta(db);
      stdout.writeln('library_id: ${meta['library_id'] ?? ''}');
      stdout.writeln('library_version: ${meta['library_version'] ?? ''}');
      stdout.writeln('schema_version: ${meta['schema_version'] ?? ''}');
      stdout.writeln('book_recipe_count: ${meta['local_library_count'] ?? ''}');
      stdout.writeln('cook_recipe_count: ${meta['cook_recipe_count'] ?? ''}');

      final sample = db.select('''
        SELECT id, title_zh
        FROM daily_choice_eat_recipe_summaries
        ORDER BY sort_key ASC, id ASC
        LIMIT 1
      ''').first;
      final sampleId = '${sample['id'] ?? ''}';
      final detailRows = db.select(
        '''
        SELECT materials_zh_json, steps_zh_json
        FROM daily_choice_eat_recipe_details
        WHERE recipe_id = ?
        LIMIT 1
        ''',
        <Object?>[sampleId],
      );
      _require(detailRows.isNotEmpty, 'Sample detail row is missing.');
      stdout.writeln('sample: $sampleId / ${sample['title_zh'] ?? ''}');
      stdout.writeln(
        'sample_detail_bytes: '
        '${'${detailRows.first['materials_zh_json'] ?? ''}'.length + '${detailRows.first['steps_zh_json'] ?? ''}'.length}',
      );

      final hasV2Recipes = _tableExists(db, 'daily_choice_recipes');
      stdout.writeln('v2 detected: $hasV2Recipes');
      if (hasV2Recipes) {
        stdout.writeln('v2 recipes: ${_countRows(db, 'daily_choice_recipes')}');
        stdout.writeln(
          'v2 sets: ${_countRows(db, 'daily_choice_recipe_sets')}',
        );
        stdout.writeln(
          'v2 ingredients: '
          '${_countRows(db, 'daily_choice_recipe_ingredient_index')}',
        );
      }

      stdout.writeln('Remote recipe DB smoke passed.');
    } finally {
      db.dispose();
    }
  } finally {
    await client.close();
    if (!keepDownload && await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

String _argValue(List<String> args, String name, {required String fallback}) {
  final index = args.indexOf(name);
  if (index < 0 || index >= args.length - 1) {
    return fallback;
  }
  return args[index + 1].trim();
}

String _envOrArg(
  String envKey,
  List<String> args,
  String argKey, {
  String fallback = '',
}) {
  final env = Platform.environment[envKey];
  if (env != null && env.trim().isNotEmpty) {
    return env.trim();
  }
  return _argValue(args, argKey, fallback: fallback);
}

void _require(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

bool _tableExists(Database db, String tableName) {
  final rows = db.select(
    '''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table' AND name = ?
    LIMIT 1
    ''',
    <Object?>[tableName],
  );
  return rows.isNotEmpty;
}

int _countRows(Database db, String tableName) {
  final rows = db.select('SELECT COUNT(*) AS total FROM $tableName');
  return (rows.first['total'] as num).toInt();
}

Map<String, String> _readMeta(Database db) {
  if (!_tableExists(db, 'daily_choice_eat_recipe_meta')) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final row in db.select(
      'SELECT key, value FROM daily_choice_eat_recipe_meta',
    ))
      '${row['key'] ?? ''}': '${row['value'] ?? ''}',
  };
}

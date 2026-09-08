import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'toolbox_calculator_session_snapshot.dart';
import 'toolbox_calculator_session_store.dart';

const _maxSessionBytes = 512 * 1024;

ToolboxCalculatorSessionStore createPlatformCalculatorSessionStore() {
  return const FileToolboxCalculatorSessionStore();
}

class FileToolboxCalculatorSessionStore
    implements ToolboxCalculatorSessionStore {
  const FileToolboxCalculatorSessionStore({this.supportDirectoryProvider});

  final Future<Directory> Function()? supportDirectoryProvider;

  Future<File> _resolveFile() async {
    final supportDirectory =
        await (supportDirectoryProvider?.call() ??
            getApplicationSupportDirectory());
    final directory = Directory(
      p.join(supportDirectory.path, 'toolbox', 'advanced_calculator'),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(p.join(directory.path, 'session_v1.json'));
  }

  @override
  Future<ToolboxCalculatorSessionSnapshot?> load() async {
    try {
      final file = await _resolveFile();
      return await _loadFile(file) ?? await _loadFile(_backupFor(file));
    } on Object {
      return null;
    }
  }

  Future<ToolboxCalculatorSessionSnapshot?> _loadFile(File file) async {
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length <= 0 || length > _maxSessionBytes) return null;
    final raw = await file.readAsString();
    if (utf8.encode(raw).length > _maxSessionBytes) return null;
    try {
      return ToolboxCalculatorSessionSnapshot.fromJsonValue(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot) async {
    final encoded = jsonEncode(snapshot.toJson());
    if (utf8.encode(encoded).length > _maxSessionBytes) {
      throw const FileSystemException('Calculator session exceeds 512 KiB');
    }
    final file = await _resolveFile();
    final temporary = File('${file.path}.tmp');
    final backup = _backupFor(file);
    try {
      await temporary.writeAsString(encoded, flush: true);
      if (await backup.exists()) await backup.delete();
      if (await file.exists()) await file.rename(backup.path);
      try {
        await temporary.rename(file.path);
      } on Object {
        if (!await file.exists() && await backup.exists()) {
          await backup.rename(file.path);
        }
        rethrow;
      }
      if (await backup.exists()) await backup.delete();
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  File _backupFor(File file) => File('${file.path}.bak');
}

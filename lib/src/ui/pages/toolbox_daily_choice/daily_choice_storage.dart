import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'daily_choice_models.dart';

class DailyChoiceStorageService {
  const DailyChoiceStorageService();

  static const String _fileName = 'toolbox_daily_choice_v1.json';

  Future<DailyChoiceCustomState> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return DailyChoiceCustomState.empty;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return DailyChoiceCustomState.empty;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return DailyChoiceCustomState.empty;
      }
      return DailyChoiceCustomState.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return DailyChoiceCustomState.empty;
    }
  }

  Future<void> save(DailyChoiceCustomState state) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(state.toJson()));
  }

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_models.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_snapshot.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_store_native.dart';

void main() {
  group('FileToolboxCalculatorSessionStore', () {
    late Directory supportDirectory;
    late FileToolboxCalculatorSessionStore store;

    setUp(() async {
      supportDirectory = await Directory.systemTemp.createTemp(
        'calculator-session-store-',
      );
      store = FileToolboxCalculatorSessionStore(
        supportDirectoryProvider: () async => supportDirectory,
      );
    });

    tearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });

    test('atomically replaces and reloads the newest snapshot', () async {
      await store.save(_snapshot('1'));
      await store.save(_snapshot('2'));

      final loaded = await store.load();
      final file = _sessionFile(supportDirectory);

      expect(loaded?.answerExpression, '2');
      expect(await file.exists(), isTrue);
      expect(await File('${file.path}.bak').exists(), isFalse);
      expect(await File('${file.path}.tmp').exists(), isFalse);
    });

    test(
      'recovers the last valid snapshot from an interrupted backup',
      () async {
        await store.save(_snapshot('7'));
        final file = _sessionFile(supportDirectory);
        await file.rename('${file.path}.bak');
        await file.writeAsString('{damaged', flush: true);

        final loaded = await store.load();

        expect(loaded?.answerExpression, '7');
        expect(loaded?.result?.exact, '7');
      },
    );
  });
}

ToolboxCalculatorSessionSnapshot _snapshot(String value) {
  return ToolboxCalculatorSessionSnapshot(
    answerExpression: value,
    result: ToolboxCalculatorResult(
      operation: ToolboxCalculatorOperation.evaluate,
      exact: value,
      latex: value,
      approximate: value,
      type: ToolboxCalculatorResultType.expression,
      backend: ToolboxCalculatorBackend.numeric,
    ),
  );
}

File _sessionFile(Directory supportDirectory) {
  return File(
    p.join(
      supportDirectory.path,
      'toolbox',
      'advanced_calculator',
      'session_v1.json',
    ),
  );
}

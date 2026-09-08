import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_engine.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_definitions.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_models.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_controller.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_snapshot.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_store.dart';

void main() {
  group('ToolboxCalculatorSessionController', () {
    test('shares Ans and Mem across consecutive requests', () async {
      final engine = _CallbackCalculatorEngine((request) async {
        return switch (request.expression) {
          '1+1' => _result('2'),
          'ans+3' => _result('5'),
          'mem*2' => _result('10'),
          _ => _result('0'),
        };
      });
      final controller = ToolboxCalculatorSessionController(engine: engine);
      addTearDown(controller.dispose);

      await controller.evaluate('1+1');
      expect(controller.answerExpression, '2');
      expect(controller.history, hasLength(1));

      await controller.evaluate('ans+3');
      expect(engine.requests[1].substitutions, <String, String>{'ans': '2'});
      expect(controller.answerExpression, '5');

      controller.storeMemory();
      expect(controller.memoryExpression, '5');
      await controller.evaluate('mem*2');

      expect(engine.requests[2].substitutions, <String, String>{
        'ans': '5',
        'mem': '5',
      });
      expect(controller.result?.exact, '10');
      expect(controller.history.map((entry) => entry.expression), <String>[
        'mem*2',
        'ans+3',
        '1+1',
      ]);
    });

    test('ignores a stale completion after a newer request wins', () async {
      final pending = <Completer<ToolboxCalculatorResult>>[];
      final engine = _CallbackCalculatorEngine((request) {
        final completer = Completer<ToolboxCalculatorResult>();
        pending.add(completer);
        return completer.future;
      });
      final controller = ToolboxCalculatorSessionController(engine: engine);
      addTearDown(controller.dispose);

      final first = controller.evaluate('slow');
      final second = controller.evaluate('fast');
      expect(pending, hasLength(2));

      pending[1].complete(_result('2'));
      await second;
      expect(controller.result?.exact, '2');
      expect(controller.history.single.expression, 'fast');

      pending[0].complete(_result('1'));
      await first;
      expect(controller.result?.exact, '2');
      expect(controller.history.single.expression, 'fast');
    });

    test('cancels a pending completion after the user edits', () async {
      final pending = Completer<ToolboxCalculatorResult>();
      final controller = ToolboxCalculatorSessionController(
        engine: _CallbackCalculatorEngine((request) => pending.future),
      );
      addTearDown(controller.dispose);

      final calculation = controller.evaluate('slow');
      expect(controller.status, ToolboxCalculatorSessionStatus.calculating);

      controller.markUserInteraction();
      expect(controller.status, ToolboxCalculatorSessionStatus.idle);

      pending.complete(_result('stale-result'));
      await calculation;
      expect(controller.result, isNull);
      expect(controller.history, isEmpty);
    });

    test('cancels a pending completion when the angle mode changes', () async {
      final pending = Completer<ToolboxCalculatorResult>();
      final controller = ToolboxCalculatorSessionController(
        engine: _CallbackCalculatorEngine((request) => pending.future),
      );
      addTearDown(controller.dispose);

      final calculation = controller.evaluate('sin(30)');
      controller.setDegreeMode(true);
      pending.complete(_result('stale-angle-result'));
      await calculation;

      expect(controller.degreeMode, isTrue);
      expect(controller.status, ToolboxCalculatorSessionStatus.idle);
      expect(controller.result, isNull);
      expect(controller.history, isEmpty);
    });

    test(
      'falls back to the numeric calculator when CAS is unavailable',
      () async {
        final engine = _CallbackCalculatorEngine((request) {
          throw const ToolboxCalculatorEngineException(
            ToolboxCalculatorFailureCode.engineUnavailable,
          );
        });
        final controller = ToolboxCalculatorSessionController(engine: engine);
        addTearDown(controller.dispose);
        controller.setDegreeMode(true);

        await controller.evaluate('sin(30)');

        expect(controller.status, ToolboxCalculatorSessionStatus.success);
        expect(controller.result?.backend, ToolboxCalculatorBackend.numeric);
        expect(double.parse(controller.result!.exact), closeTo(0.5, 1e-12));
        expect(controller.answerExpression, controller.result?.exact);
      },
    );

    test(
      'reports non-finite numeric fallbacks as computation errors',
      () async {
        final engine = _CallbackCalculatorEngine((request) {
          throw const ToolboxCalculatorEngineException(
            ToolboxCalculatorFailureCode.engineUnavailable,
          );
        });
        final controller = ToolboxCalculatorSessionController(engine: engine);
        addTearDown(controller.dispose);

        await controller.evaluate('1/0');

        expect(controller.status, ToolboxCalculatorSessionStatus.error);
        expect(
          controller.error?.code,
          ToolboxCalculatorFailureCode.computation,
        );
        expect(controller.result, isNull);
        expect(controller.history, isEmpty);
      },
    );

    test('keeps non-expression results out of Ans and memory', () async {
      final engine = _CallbackCalculatorEngine(
        (request) async => ToolboxCalculatorResult(
          operation: request.operation,
          exact: '[[1,0],[0,1]]',
          latex: r'\begin{bmatrix}1&0\\0&1\end{bmatrix}',
          type: ToolboxCalculatorResultType.matrix,
          backend: ToolboxCalculatorBackend.algebrite,
        ),
      );
      final controller = ToolboxCalculatorSessionController(engine: engine);
      addTearDown(controller.dispose);

      await controller.submit(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.inverse,
          matrix: <List<String>>[
            <String>['1', '0'],
            <String>['0', '1'],
          ],
        ),
        expressionLabel: 'A^-1',
      );
      controller.storeMemory();

      expect(controller.answerExpression, isNull);
      expect(controller.memoryExpression, isNull);
      expect(
        controller.history.single.result.type,
        ToolboxCalculatorResultType.matrix,
      );
    });

    test('clears results, memory, and history independently', () async {
      final engine = _CallbackCalculatorEngine(
        (request) async => _result(request.expression ?? '0'),
      );
      final controller = ToolboxCalculatorSessionController(engine: engine);
      addTearDown(controller.dispose);

      await controller.evaluate('7');
      controller.storeMemory();
      controller.clearResult();

      expect(controller.status, ToolboxCalculatorSessionStatus.idle);
      expect(controller.result, isNull);
      expect(controller.memoryExpression, '7');
      expect(controller.history, hasLength(1));

      controller.clearMemory();
      controller.clearHistory();
      expect(controller.memoryExpression, isNull);
      expect(controller.history, isEmpty);
    });

    test('clearResult clears errors and cancels pending completions', () async {
      final pending = Completer<ToolboxCalculatorResult>();
      var requestCount = 0;
      final controller = ToolboxCalculatorSessionController(
        engine: _CallbackCalculatorEngine((request) {
          requestCount += 1;
          if (requestCount == 1) {
            throw const ToolboxCalculatorEngineException(
              ToolboxCalculatorFailureCode.computation,
            );
          }
          return pending.future;
        }),
      );
      addTearDown(controller.dispose);

      await controller.evaluate('invalid');
      expect(controller.status, ToolboxCalculatorSessionStatus.error);
      expect(controller.error, isNotNull);

      controller.clearResult();
      expect(controller.status, ToolboxCalculatorSessionStatus.idle);
      expect(controller.error, isNull);

      final calculation = controller.evaluate('slow');
      expect(controller.status, ToolboxCalculatorSessionStatus.calculating);
      controller.clearResult();
      expect(controller.status, ToolboxCalculatorSessionStatus.idle);
      expect(controller.result, isNull);
      expect(controller.error, isNull);

      pending.complete(_result('stale-result'));
      await calculation;
      expect(controller.status, ToolboxCalculatorSessionStatus.idle);
      expect(controller.result, isNull);
      expect(controller.history, isEmpty);
    });

    test('restores and serializes a complete bounded session', () async {
      final snapshot = ToolboxCalculatorSessionSnapshot(
        history: <ToolboxCalculatorHistoryEntry>[
          ToolboxCalculatorHistoryEntry(
            id: 7,
            expression: 'f(2)',
            result: _result('7'),
            createdAt: DateTime.utc(2026, 8, 30),
          ),
        ],
        answerExpression: '7',
        memoryExpression: '3',
        result: _result('7'),
        angleUnit: ToolboxCalculatorAngleUnit.degree,
        definitions: const <ToolboxCalculatorDefinition>[
          ToolboxCalculatorDefinition(name: 'offset', expression: '3'),
          ToolboxCalculatorDefinition(
            name: 'f',
            expression: 'x^2+offset',
            parameters: <String>['x'],
          ),
        ],
      );
      final decoded = ToolboxCalculatorSessionSnapshot.fromJsonValue(
        snapshot.toJson(),
      );
      final store = _MemorySessionStore(snapshot: decoded);
      final engine = _CallbackCalculatorEngine((request) async => _result('0'));
      final controller = ToolboxCalculatorSessionController(
        engine: engine,
        sessionStore: store,
      );
      addTearDown(controller.dispose);

      await controller.restore();

      expect(controller.degreeMode, isTrue);
      expect(controller.answerExpression, '7');
      expect(controller.memoryExpression, '3');
      expect(controller.result?.exact, '7');
      expect(controller.history.single.id, 7);
      expect(controller.definitions.map((item) => item.name), <String>[
        'offset',
        'f',
      ]);
    });

    test('does not apply a restore after the user starts editing', () async {
      final restore = Completer<ToolboxCalculatorSessionSnapshot?>();
      final store = _DeferredRestoreStore(restore.future);
      final controller = ToolboxCalculatorSessionController(
        engine: _CallbackCalculatorEngine(
          (request) async => _result(request.expression ?? '0'),
        ),
        sessionStore: store,
      );
      addTearDown(controller.dispose);

      final pendingRestore = controller.restore();
      controller.markUserInteraction();
      restore.complete(
        const ToolboxCalculatorSessionSnapshot(
          answerExpression: '99',
          angleUnit: ToolboxCalculatorAngleUnit.degree,
        ),
      );
      await pendingRestore;

      expect(controller.answerExpression, isNull);
      expect(controller.degreeMode, isFalse);
    });

    test('serializes polar inputs and structured result parts', () {
      const request = ToolboxCalculatorRequest(
        operation: ToolboxCalculatorOperation.complexFromPolar,
        radius: 'sqrt(2)',
        angle: '45',
      );
      final requestJson = request.toJson();
      expect(requestJson['radius'], 'sqrt(2)');
      expect(requestJson['angle'], '45');

      const structured = ToolboxCalculatorResult(
        operation: ToolboxCalculatorOperation.qrDecomposition,
        exact: 'Q=[[1,0],[0,1]]; R=[[1,0],[0,1]]',
        latex: r'Q=I\quad R=I',
        type: ToolboxCalculatorResultType.unknown,
        backend: ToolboxCalculatorBackend.nerdamerPrime,
        parts: <ToolboxCalculatorResultPart>[
          ToolboxCalculatorResultPart(
            id: 'Q',
            exact: '[[1,0],[0,1]]',
            latex: r'\begin{bmatrix}1&0\\0&1\end{bmatrix}',
            type: ToolboxCalculatorResultType.matrix,
          ),
          ToolboxCalculatorResultPart(
            id: 'R',
            exact: '[[1,0],[0,1]]',
            latex: r'\begin{bmatrix}1&0\\0&1\end{bmatrix}',
            type: ToolboxCalculatorResultType.matrix,
          ),
        ],
      );
      final decoded = ToolboxCalculatorSessionSnapshot.fromJsonValue(
        const ToolboxCalculatorSessionSnapshot(result: structured).toJson(),
      );

      expect(decoded.result?.isComposite, isTrue);
      expect(decoded.result?.parts.map((part) => part.id), <String>['Q', 'R']);
      expect(
        decoded.result?.parts.first.type,
        ToolboxCalculatorResultType.matrix,
      );
    });

    test('rejects an empty decoded calculator result', () {
      expect(
        () => ToolboxCalculatorResult.fromJson(<String, Object?>{
          'exact': '   ',
          'latex': '',
          'type': 'expression',
          'backend': 'nerdamer-prime',
        }, ToolboxCalculatorOperation.evaluate),
        throwsFormatException,
      );
    });

    test('adds angle and validated definitions to every request', () async {
      final engine = _CallbackCalculatorEngine((request) async => _result('7'));
      final controller = ToolboxCalculatorSessionController(engine: engine);
      addTearDown(controller.dispose);
      controller.setDegreeMode(true);
      controller.upsertDefinition(
        const ToolboxCalculatorDefinition(name: 'offset', expression: '3'),
      );
      controller.upsertDefinition(
        const ToolboxCalculatorDefinition(
          name: 'f',
          expression: 'x^2+offset',
          parameters: <String>['x'],
        ),
      );

      await controller.evaluate('f(2)');

      expect(
        engine.requests.single.angleUnit,
        ToolboxCalculatorAngleUnit.degree,
      );
      expect(engine.requests.single.definitions, hasLength(2));
      expect(engine.requests.single.definitions.last.name, 'f');
    });

    test('rejects reserved names and cyclic definitions', () {
      final controller = ToolboxCalculatorSessionController(
        engine: _CallbackCalculatorEngine(
          (request) async => _result(request.expression ?? '0'),
        ),
      );
      addTearDown(controller.dispose);

      expect(
        () => controller.upsertDefinition(
          const ToolboxCalculatorDefinition(name: 'sin', expression: '1'),
        ),
        throwsA(
          isA<ToolboxCalculatorDefinitionException>().having(
            (error) => error.failure,
            'failure',
            ToolboxCalculatorDefinitionFailure.reservedName,
          ),
        ),
      );
      controller.upsertDefinition(
        const ToolboxCalculatorDefinition(name: 'a', expression: 'b+1'),
      );
      expect(
        () => controller.upsertDefinition(
          const ToolboxCalculatorDefinition(name: 'b', expression: 'a+1'),
        ),
        throwsA(
          isA<ToolboxCalculatorDefinitionException>().having(
            (error) => error.failure,
            'failure',
            ToolboxCalculatorDefinitionFailure.cyclicDependency,
          ),
        ),
      );
    });

    test('coalesces pending writes and persists the newest snapshot', () async {
      final store = _BlockingSaveStore();
      final controller = ToolboxCalculatorSessionController(
        engine: _CallbackCalculatorEngine(
          (request) async => _result(request.expression ?? '0'),
        ),
        sessionStore: store,
      );
      addTearDown(controller.dispose);

      controller.setDegreeMode(true);
      await store.firstSaveStarted.future;
      controller.setDegreeMode(false);
      controller.setDegreeMode(true);
      controller.setDegreeMode(false);
      store.releaseFirstSave.complete();
      await controller.flushPersistence();

      expect(store.saved, hasLength(2));
      expect(store.saved.first.angleUnit, ToolboxCalculatorAngleUnit.degree);
      expect(store.saved.last.angleUnit, ToolboxCalculatorAngleUnit.radian);
    });
  });
}

ToolboxCalculatorResult _result(String exact) {
  return ToolboxCalculatorResult(
    operation: ToolboxCalculatorOperation.evaluate,
    exact: exact,
    latex: exact,
    approximate: exact,
    type: ToolboxCalculatorResultType.expression,
    backend: ToolboxCalculatorBackend.nerdamerPrime,
  );
}

class _CallbackCalculatorEngine implements ToolboxCalculatorEngine {
  _CallbackCalculatorEngine(this._calculate);

  final Future<ToolboxCalculatorResult> Function(
    ToolboxCalculatorRequest request,
  )
  _calculate;
  final List<ToolboxCalculatorRequest> requests = <ToolboxCalculatorRequest>[];

  @override
  Future<ToolboxCalculatorResult> calculate(ToolboxCalculatorRequest request) {
    requests.add(request);
    return _calculate(request);
  }

  @override
  Future<void> dispose() async {}
}

class _MemorySessionStore implements ToolboxCalculatorSessionStore {
  _MemorySessionStore({this.snapshot});

  ToolboxCalculatorSessionSnapshot? snapshot;

  @override
  Future<ToolboxCalculatorSessionSnapshot?> load() async => snapshot;

  @override
  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

class _DeferredRestoreStore implements ToolboxCalculatorSessionStore {
  _DeferredRestoreStore(this.restore);

  final Future<ToolboxCalculatorSessionSnapshot?> restore;

  @override
  Future<ToolboxCalculatorSessionSnapshot?> load() => restore;

  @override
  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot) async {}
}

class _BlockingSaveStore implements ToolboxCalculatorSessionStore {
  final Completer<void> firstSaveStarted = Completer<void>();
  final Completer<void> releaseFirstSave = Completer<void>();
  final List<ToolboxCalculatorSessionSnapshot> saved =
      <ToolboxCalculatorSessionSnapshot>[];

  @override
  Future<ToolboxCalculatorSessionSnapshot?> load() async => null;

  @override
  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot) async {
    saved.add(snapshot);
    if (saved.length == 1) {
      firstSaveStarted.complete();
      await releaseFirstSave.future;
    }
  }
}

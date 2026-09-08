import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_engine.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_models.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_snapshot.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_session_store.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_life_tools.dart';

void main() {
  group('advanced calculator mobile workflow', () {
    testWidgets('fits 375dp and exposes all keypad layers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final engine = _WorkflowCalculatorEngine();

      await _openCalculator(tester, engine);

      expect(find.text('Advanced scientific calculator'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('advanced_calculator_expression')),
        findsOneWidget,
      );
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Scientific'), findsOneWidget);
      expect(find.text('Symbols'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(
        find
            .byKey(const ValueKey<String>('advanced_calculator_equals'))
            .hitTestable(),
        findsOneWidget,
      );

      await _tapVisible(tester, find.text('Scientific'));
      expect(find.text('sin'), findsOneWidget);
      expect(find.text('nCr'), findsOneWidget);

      await _tapVisible(tester, find.text('Symbols'));
      expect(find.text('π'), findsOneWidget);
      expect(find.text('∫'), findsOneWidget);
      expect(find.text('A⁻¹'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('continues results and shares Ans, Mem, and history', (
      tester,
    ) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );

      await tester.enterText(expression, '1+2');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      expect(engine.requests.single.expression, '1+2');

      await _tapVisible(tester, find.text('+'));
      await _tapVisible(tester, find.text('4'));
      expect(_fieldText(tester, expression), '(3)+4');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      expect(engine.requests[1].expression, '(3)+4');
      expect(engine.requests[1].substitutions, <String, String>{'ans': '3'});

      await _tapVisible(tester, find.text('MS'));
      expect(find.text('Mem = 7'), findsOneWidget);
      await _tapVisible(tester, find.text('AC'));
      await _tapVisible(tester, find.text('MR'));
      await _tapVisible(tester, find.text('×'));
      await _tapVisible(tester, find.text('2'));
      expect(_fieldText(tester, expression), 'mem*2');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      expect(engine.requests[2].substitutions, <String, String>{
        'ans': '7',
        'mem': '7',
      });

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_history_command'),
        ),
      );
      expect(find.text('mem*2'), findsWidgets);
      await _tapVisible(tester, find.text('(3)+4'));
      expect(_fieldText(tester, expression), '(3)+4');
      expect(tester.takeException(), isNull);
    });

    testWidgets('keypad edits cancel a calculation with stale input', (
      tester,
    ) async {
      final engine = _DeferredCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );
      await tester.enterText(expression, '1');

      final equals = find.byKey(
        const ValueKey<String>('advanced_calculator_equals'),
      );
      await _ensureHitTestable(tester, equals);
      await tester.tap(equals.first);
      await tester.pump();
      expect(engine.pending, hasLength(1));

      final two = find.text('2').hitTestable();
      expect(two, findsOneWidget);
      await tester.tap(two);
      await tester.pump();
      expect(_fieldText(tester, expression), '12');

      engine.pending.single.complete(_widgetResult('stale-result'));
      await tester.pumpAndSettle();
      expect(find.text('stale-result'), findsNothing);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
      expect(
        find
            .byKey(const ValueKey<String>('advanced_calculator_equals'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'rapid equals taps stay single-flight and isolate haptic failures',
      (tester) async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        var hapticCalls = 0;
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls += 1;
            throw PlatformException(code: 'haptic_unavailable');
          }
          return null;
        });
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final engine = _DeferredCalculatorEngine();
        await _openCalculator(tester, engine);
        final expression = find.byKey(
          const ValueKey<String>('advanced_calculator_expression'),
        );
        await tester.enterText(expression, '6*7');
        final equals = find.byKey(
          const ValueKey<String>('advanced_calculator_equals'),
        );
        await _ensureHitTestable(tester, equals);

        await tester.tap(equals.first);
        await tester.tap(equals.first);
        await tester.tap(equals.first);
        await tester.pump();

        expect(engine.pending, hasLength(1));
        expect(hapticCalls, 1);
        expect(tester.takeException(), isNull);

        engine.pending.single.complete(_widgetResult('42'));
        await tester.pumpAndSettle();
        expect(find.text('Complete'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('AC cancels a calculation and rejects its late result', (
      tester,
    ) async {
      final engine = _DeferredCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );
      await tester.enterText(expression, 'slow_expression');
      final equals = find.byKey(
        const ValueKey<String>('advanced_calculator_equals'),
      );
      await _ensureHitTestable(tester, equals);
      await tester.tap(equals.first);
      await tester.pump();
      expect(engine.pending, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.tap(find.text('AC').hitTestable());
      await tester.pump();

      expect(_fieldText(tester, expression), isEmpty);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
      expect(equals.hitTestable(), findsOneWidget);

      engine.pending.single.complete(_widgetResult('stale-result'));
      await tester.pumpAndSettle();
      expect(find.text('stale-result'), findsNothing);
      expect(find.text('Ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AC clears an error and leaves evaluation reusable', (
      tester,
    ) async {
      final engine = _FailThenSucceedCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );
      await tester.enterText(expression, 'invalid');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      expect(find.text('Check input'), findsOneWidget);

      await _tapVisible(tester, find.text('AC'));
      expect(_fieldText(tester, expression), isEmpty);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Check input'), findsNothing);

      await tester.enterText(expression, '1+1');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      expect(find.text('2'), findsWidgets);
      expect(engine.requests, hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens tools and switches matrix grid and text editors', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
      );
      expect(find.text('Advanced math tools'), findsOneWidget);
      await _tapVisible(tester, find.text('Linear algebra'));
      expect(find.text('Symbolic matrices'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('matrix_grid')),
        findsNWidgets(2),
      );

      final textMode = find.byTooltip('Text editor').first;
      await _tapVisible(tester, textMode);
      expect(find.byKey(const ValueKey<String>('matrix_text')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('matrix_grid')), findsOneWidget);

      await _tapVisible(tester, find.text('Probability'));
      expect(find.text('Probability and distributions'), findsOneWidget);
      expect(find.text('Binomial PMF'), findsOneWidget);
      expect(find.text('Normal CDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('searches the catalog and inserts or opens an entry', (
      tester,
    ) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_catalog_action'),
        ),
      );
      expect(find.text('Function and symbol catalog'), findsWidgets);
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('advanced_calculator_catalog_search'),
        ),
        'sqrt',
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('√x  sqrt(x)'));
      expect(_fieldText(tester, expression), 'sqrt()');

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_catalog_action'),
        ),
      );
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('advanced_calculator_catalog_search'),
        ),
        'QR',
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('A = QR'));
      expect(find.text('Subspaces and decompositions'), findsOneWidget);
      expect(find.text('QR decomposition'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('runs complex tools with direct and polar inputs', (
      tester,
    ) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );
      await tester.enterText(expression, '3+4*i');

      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
      );
      await _tapVisible(tester, find.text('Complex'));
      expect(find.text('Complex analysis'), findsOneWidget);
      await _tapVisible(tester, find.text('Magnitude'));
      expect(
        engine.requests.last.operation,
        ToolboxCalculatorOperation.complexMagnitude,
      );
      expect(engine.requests.last.expression, '3+4*i');

      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
      );
      await _tapVisible(tester, find.text('Complex'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_from_polar')),
      );
      expect(
        engine.requests.last.operation,
        ToolboxCalculatorOperation.complexFromPolar,
      );
      expect(engine.requests.last.radius, '1');
      expect(engine.requests.last.angle, '0');
      expect(tester.takeException(), isNull);
    });

    testWidgets('restores a structured history part into matrix A', (
      tester,
    ) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
      );
      await _tapVisible(tester, find.text('Linear algebra'));
      await _tapVisible(tester, find.text('QR decomposition'));
      expect(
        find.byKey(const ValueKey<String>('advanced_calculator_result_part_Q')),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_history_command'),
        ),
      );
      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_history_part_Q'),
        ),
      );
      await _tapVisible(tester, find.text('Matrix A'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
      );
      await _tapVisible(tester, find.text('Linear algebra'));
      await _tapVisible(tester, find.text('Determinant'));

      expect(engine.requests.last.matrix, <List<String>>[
        <String>['1', '0'],
        <String>['0', '1'],
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('creates a function definition and inserts it into the input', (
      tester,
    ) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_definitions_action'),
        ),
      );
      expect(find.text('Named variables and functions'), findsOneWidget);
      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_add_definition'),
        ),
      );
      await _tapVisible(tester, find.text('Function'));
      await tester.enterText(
        find.byKey(const ValueKey<String>('calculator_definition_name')),
        'f',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('calculator_definition_parameters')),
        'x',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('calculator_definition_expression')),
        'x^2+1',
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('calculator_definition_save')),
      );
      expect(find.text('f(x)'), findsOneWidget);
      await _tapVisible(tester, find.text('f(x)'));
      expect(_fieldText(tester, expression), 'f()');

      await tester.enterText(expression, 'f(3)');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      expect(engine.requests.single.definitions.single.name, 'f');
      expect(engine.requests.single.definitions.single.parameters, <String>[
        'x',
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('undoes and redoes system keyboard edits', (tester) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );

      await tester.enterText(expression, '1');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(expression, '12');
      await tester.pump(const Duration(milliseconds: 600));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_undo')),
      );
      expect(_fieldText(tester, expression), '1');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_redo')),
      );
      expect(_fieldText(tester, expression), '12');
    });

    testWidgets('routes a matrix result into matrix A', (tester) async {
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine);
      final expression = find.byKey(
        const ValueKey<String>('advanced_calculator_expression'),
      );

      await tester.enterText(expression, 'matrix_case');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_equals')),
      );
      await _tapVisible(tester, find.text('Continue calculating'));
      await _tapVisible(tester, find.text('Matrix A'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
      );
      await _tapVisible(tester, find.text('Linear algebra'));
      await _tapVisible(tester, find.text('Determinant'));

      final request = engine.requests.last;
      expect(request.operation, ToolboxCalculatorOperation.determinant);
      expect(request.matrix, <List<String>>[
        <String>['1', '2'],
        <String>['3', '4'],
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restores persisted history and fits a 320dp viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = _MemoryCalculatorSessionStore(
        ToolboxCalculatorSessionSnapshot(
          history: <ToolboxCalculatorHistoryEntry>[
            ToolboxCalculatorHistoryEntry(
              id: 1,
              expression: 'restored+1',
              result: _widgetResult('9'),
              createdAt: DateTime.utc(2026, 8, 30),
            ),
          ],
          answerExpression: '9',
          result: _widgetResult('9'),
        ),
      );
      final engine = _WorkflowCalculatorEngine();
      await _openCalculator(tester, engine, store: store);

      expect(
        find.byKey(const ValueKey<String>('advanced_calculator_expression')),
        findsOneWidget,
      );
      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey<String>('advanced_calculator_history_command'),
        ),
      );
      expect(find.text('restored+1'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'keeps catalog and tool categories usable at 320dp text scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final engine = _WorkflowCalculatorEngine();
        await _openCalculator(
          tester,
          engine,
          textScaler: const TextScaler.linear(1.3),
        );

        await _tapVisible(
          tester,
          find.byKey(
            const ValueKey<String>('advanced_calculator_catalog_action'),
          ),
        );
        expect(find.text('Function and symbol catalog'), findsWidgets);
        expect(tester.takeException(), isNull);
        await _tapVisible(tester, find.byIcon(Icons.close_rounded));
        await _tapVisible(
          tester,
          find.byKey(const ValueKey<String>('advanced_calculator_open_tools')),
        );
        expect(find.text('Complex'), findsOneWidget);
        expect(find.text('Probability'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Future<void> _openCalculator(
  WidgetTester tester,
  ToolboxCalculatorEngine engine, {
  ToolboxCalculatorSessionStore? store,
  TextScaler? textScaler,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppI18n.supportedLanguages
          .map(Locale.new)
          .toList(growable: false),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true),
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
      home: Scaffold(
        body: LifeToolsHubPage(
          advancedCalculatorEngineFactory: () => engine,
          advancedCalculatorSessionStoreFactory: () =>
              store ?? _MemoryCalculatorSessionStore(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final search = find.byKey(const ValueKey<String>('life_tools_search_field'));
  await tester.enterText(search, 'advanced_calculator');
  await tester.pumpAndSettle();
  final card = find.byKey(
    const ValueKey<String>('life_tool_card_advanced_calculator'),
  );
  await _tapVisible(tester, card);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _ensureHitTestable(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _ensureHitTestable(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets);
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find
          .ancestor(of: target, matching: find.byType(Scrollable))
          .last,
    );
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

String _fieldText(WidgetTester tester, Finder finder) {
  return tester.widget<TextField>(finder).controller!.text;
}

class _WorkflowCalculatorEngine implements ToolboxCalculatorEngine {
  final List<ToolboxCalculatorRequest> requests = <ToolboxCalculatorRequest>[];

  @override
  Future<ToolboxCalculatorResult> calculate(
    ToolboxCalculatorRequest request,
  ) async {
    requests.add(request);
    if (request.operation == ToolboxCalculatorOperation.qrDecomposition) {
      return const ToolboxCalculatorResult(
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
    }
    final exact = switch (request.expression) {
      '1+2' => '3',
      '(3)+4' => '7',
      'mem*2' => '14',
      'matrix_case' => '[[1,2],[3,4]]',
      '3+4*i' => '5',
      _ => request.expression ?? '0',
    };
    return ToolboxCalculatorResult(
      operation: request.operation,
      exact: exact,
      latex: exact,
      approximate: '$exact.0',
      type: request.expression == 'matrix_case'
          ? ToolboxCalculatorResultType.matrix
          : ToolboxCalculatorResultType.expression,
      backend: ToolboxCalculatorBackend.nerdamerPrime,
    );
  }

  @override
  Future<void> dispose() async {}
}

class _DeferredCalculatorEngine implements ToolboxCalculatorEngine {
  final List<Completer<ToolboxCalculatorResult>> pending =
      <Completer<ToolboxCalculatorResult>>[];

  @override
  Future<ToolboxCalculatorResult> calculate(ToolboxCalculatorRequest request) {
    final completer = Completer<ToolboxCalculatorResult>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> dispose() async {}
}

class _FailThenSucceedCalculatorEngine implements ToolboxCalculatorEngine {
  final List<ToolboxCalculatorRequest> requests = <ToolboxCalculatorRequest>[];

  @override
  Future<ToolboxCalculatorResult> calculate(
    ToolboxCalculatorRequest request,
  ) async {
    requests.add(request);
    if (requests.length == 1) {
      throw const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.computation,
      );
    }
    return _widgetResult('2');
  }

  @override
  Future<void> dispose() async {}
}

ToolboxCalculatorResult _widgetResult(String exact) {
  return ToolboxCalculatorResult(
    operation: ToolboxCalculatorOperation.evaluate,
    exact: exact,
    latex: exact,
    approximate: exact,
    type: ToolboxCalculatorResultType.expression,
    backend: ToolboxCalculatorBackend.nerdamerPrime,
  );
}

class _MemoryCalculatorSessionStore implements ToolboxCalculatorSessionStore {
  _MemoryCalculatorSessionStore([this.snapshot]);

  ToolboxCalculatorSessionSnapshot? snapshot;

  @override
  Future<ToolboxCalculatorSessionSnapshot?> load() async => snapshot;

  @override
  Future<void> save(ToolboxCalculatorSessionSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

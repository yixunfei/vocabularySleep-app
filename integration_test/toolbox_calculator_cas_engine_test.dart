import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_cas_engine_native.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_engine.dart';
import 'package:vocabulary_sleep_app/src/services/calculator/toolbox_calculator_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ToolboxCalculatorCasEngine', () {
    late ToolboxCalculatorCasEngine engine;

    setUpAll(() {
      engine = ToolboxCalculatorCasEngine(
        calculationTimeout: const Duration(seconds: 8),
      );
    });

    tearDownAll(() => engine.dispose());

    test(
      'keeps exact arithmetic and provides a decimal approximation',
      () async {
        final result = await engine.calculate(
          const ToolboxCalculatorRequest(
            operation: ToolboxCalculatorOperation.evaluate,
            expression: '1/3+sqrt(2)',
          ),
        );

        expect(result.exact, contains('sqrt(2)'));
        expect(result.exact, contains('1/3'));
        expect(result.latex, contains(r'\sqrt{2}'));
        expect(result.approximate, startsWith('1.7475'));
        expect(result.backend, ToolboxCalculatorBackend.nerdamerPrime);
      },
    );

    test('simplifies, factors, and solves an equation system', () async {
      final simplified = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.simplify,
          expression: 'sin(x)^2+cos(x)^2',
        ),
      );
      final factored = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.factor,
          expression: 'x^2-1',
        ),
      );
      final solved = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.solveSystem,
          equations: <String>['x+y=3', 'x-y=1'],
          variables: <String>['x', 'y'],
        ),
      );

      expect(simplified.exact, '1');
      expect(factored.exact, contains('(-1+x)'));
      expect(solved.exact, 'x=2, y=1');
      expect(solved.type, ToolboxCalculatorResultType.equationSet);

      final empty = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.solveEquation,
          expression: 'exp(x)=0',
          variable: 'x',
        ),
      );
      expect(empty.exact, '∅');
      expect(empty.latex, r'\varnothing');

      final identity = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.solveEquation,
          expression: 'x=x',
          variable: 'x',
        ),
      );
      final contradiction = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.solveEquation,
          expression: 'x=x+1',
          variable: 'x',
        ),
      );
      final underdetermined = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.solveSystem,
          equations: <String>['x+y=2'],
          variables: <String>['x', 'y'],
        ),
      );
      final inconsistent = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.solveSystem,
          equations: <String>['x+y=1', 'x+y=2'],
          variables: <String>['x', 'y'],
        ),
      );
      expect(identity.exact, 'x∈ℂ');
      expect(contradiction.exact, '∅');
      expect(underdetermined.exact, 'x=-y+2, y∈ℂ');
      expect(inconsistent.exact, '∅');
    });

    test('covers symbolic calculus and transforms', () async {
      final integral = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.integrate,
          expression: '2*x*cos(x^2)',
          variable: 'x',
        ),
      );
      final definiteIntegral = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.definiteIntegral,
          expression: 'sin(x)',
          variable: 'x',
          lowerBound: '0',
          upperBound: 'pi',
        ),
      );
      final limit = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.limit,
          expression: 'sin(x)/x',
          variable: 'x',
          point: '0',
        ),
      );
      final taylor = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.taylor,
          expression: 'exp(x)',
          variable: 'x',
          point: '0',
          order: 5,
        ),
      );
      final laplace = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.laplace,
          expression: 'sin(t)',
          variable: 't',
          targetVariable: 's',
        ),
      );

      expect(integral.exact, 'sin(x^2)');
      expect(definiteIntegral.exact, '2');
      expect(limit.exact, '1');
      expect(taylor.exact, matches(RegExp(r'\(?1/120\)?\*x\^5')));
      expect(laplace.exact, contains('(1+s^2)^(-1)'));
    });

    test('performs exact symbolic matrix operations', () async {
      const matrix = <List<String>>[
        <String>['a', 'b'],
        <String>['c', 'd'],
      ];
      final determinant = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.determinant,
          matrix: matrix,
        ),
      );
      final inverse = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.inverse,
          matrix: matrix,
        ),
      );
      final characteristic = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.characteristicPolynomial,
          matrix: matrix,
          targetVariable: 'lambda',
        ),
      );
      final reduced = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.rref,
          matrix: <List<String>>[
            <String>['1', '2'],
            <String>['2', '4'],
          ],
        ),
      );

      expect(determinant.exact, 'a*d-b*c');
      expect(inverse.exact, contains('d/(a*d-b*c)'));
      expect(characteristic.exact, contains('lambda^2'));
      expect(reduced.exact, '[[1,2],[0,0]]');
      expect(inverse.type, ToolboxCalculatorResultType.matrix);

      await expectLater(
        engine.calculate(
          const ToolboxCalculatorRequest(
            operation: ToolboxCalculatorOperation.rref,
            matrix: <List<String>>[
              <String>['x'],
            ],
          ),
        ),
        throwsA(
          isA<ToolboxCalculatorEngineException>().having(
            (error) => error.code,
            'code',
            ToolboxCalculatorFailureCode.unsupported,
          ),
        ),
      );
      final prioritizedPivot = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.rref,
          matrix: <List<String>>[
            <String>['x', '1'],
            <String>['1', '0'],
          ],
        ),
      );
      expect(prioritizedPivot.exact, '[[1,0],[0,1]]');
    });

    test('supports multivariable and vector operations', () async {
      final gradient = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.gradient,
          expression: 'x^2+y^2',
          variables: <String>['x', 'y'],
        ),
      );
      final hessian = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.hessian,
          expression: 'x^2+x*y+y^2',
          variables: <String>['x', 'y'],
        ),
      );
      final cross = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.crossProduct,
          vector: <String>['a', 'b', 'c'],
          secondaryVector: <String>['x', 'y', 'z'],
        ),
      );

      expect(gradient.exact, '[2*x,2*y]');
      expect(hessian.exact, '[[2,1],[1,2]]');
      expect(cross.exact, contains('-c*y+b*z'));
    });

    test('covers advanced linear algebra with structured factors', () async {
      final nullSpace = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.nullSpace,
          matrix: <List<String>>[
            <String>['1', '2'],
            <String>['2', '4'],
          ],
        ),
      );
      final lu = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.luDecomposition,
          matrix: <List<String>>[
            <String>['0', '2'],
            <String>['1', '3'],
          ],
        ),
      );
      final qr = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.qrDecomposition,
          matrix: <List<String>>[
            <String>['3', '0'],
            <String>['4', '5'],
          ],
        ),
      );
      final leastSquares = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.leastSquares,
          matrix: <List<String>>[
            <String>['1', '0'],
            <String>['0', '1'],
            <String>['1', '1'],
          ],
          vector: <String>['1', '2', '4'],
        ),
      );

      expect(nullSpace.exact, '[[-2,1]]');
      expect(lu.isComposite, isTrue);
      expect(lu.parts.map((part) => part.id), <String>['P', 'L', 'U']);
      expect(lu.parts.last.exact, '[[1,3],[0,2]]');
      expect(qr.parts.map((part) => part.id), <String>['Q', 'R']);
      expect(qr.parts.first.exact, '[[3/5,-4/5],[4/5,3/5]]');
      expect(qr.parts.last.exact, '[[5,4],[0,3]]');
      expect(leastSquares.exact, '[4/3,7/3]');

      final complexQr = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.qrDecomposition,
          matrix: <List<String>>[
            <String>['i', '0'],
            <String>['0', '1'],
          ],
        ),
      );
      final complexLeastSquares = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.leastSquares,
          matrix: <List<String>>[
            <String>['1'],
            <String>['i'],
          ],
          vector: <String>['1', 'i'],
        ),
      );
      final complexNorm = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.vectorNorm,
          vector: <String>['1', 'i'],
        ),
      );
      expect(complexQr.parts.first.exact, '[[i,0],[0,1]]');
      expect(complexQr.parts.last.exact, '[[1,0],[0,1]]');
      expect(complexLeastSquares.exact, '[1]');
      expect(complexNorm.exact, 'sqrt(2)');
    });

    test('converts complex values in radians and degrees', () async {
      final magnitude = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.complexMagnitude,
          expression: '3+4*i',
        ),
      );
      final argument = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.complexArgument,
          expression: '1+i',
          angleUnit: ToolboxCalculatorAngleUnit.degree,
        ),
      );
      final polar = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.complexPolarForm,
          expression: '3+4*i',
        ),
      );
      final rectangular = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.complexFromPolar,
          radius: '2',
          angle: '90',
          angleUnit: ToolboxCalculatorAngleUnit.degree,
        ),
      );

      expect(magnitude.exact, '5');
      expect(argument.approximate, '45');
      expect(polar.parts.map((part) => part.id), <String>[
        'magnitude',
        'argument',
      ]);
      expect(rectangular.exact, '2*i');
    });

    test('applies DEG only to closed direct trigonometry', () async {
      final direct = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.evaluate,
          expression: 'sin(30)',
          angleUnit: ToolboxCalculatorAngleUnit.degree,
        ),
      );
      final inverse = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.approximate,
          expression: 'asin(1/2)',
          angleUnit: ToolboxCalculatorAngleUnit.degree,
        ),
      );
      final symbolic = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.differentiate,
          expression: 'sin(x)',
          variable: 'x',
          angleUnit: ToolboxCalculatorAngleUnit.degree,
        ),
      );

      expect(direct.exact, '1/2');
      expect(inverse.approximate, '30');
      expect(symbolic.exact, 'cos(x)');
    });

    test('scopes definitions and substitutions to one request', () async {
      const definitions = <ToolboxCalculatorDefinition>[
        ToolboxCalculatorDefinition(name: 'offset', expression: '1'),
        ToolboxCalculatorDefinition(
          name: 'f',
          expression: 'x^2+offset',
          parameters: <String>['x'],
        ),
      ];
      final function = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.evaluate,
          expression: 'f(3)',
          definitions: definitions,
        ),
      );
      final matrix = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.determinant,
          matrix: <List<String>>[
            <String>['ans', '0'],
            <String>['0', 'mem'],
          ],
          substitutions: <String, String>{'ans': '3', 'mem': '4'},
        ),
      );
      final isolated = await engine.calculate(
        const ToolboxCalculatorRequest(
          operation: ToolboxCalculatorOperation.evaluate,
          expression: 'offset',
        ),
      );

      expect(function.exact, '10');
      expect(matrix.exact, '12');
      expect(isolated.exact, 'offset');
    });

    test('rejects persistent CAS assignments', () async {
      await expectLater(
        engine.calculate(
          const ToolboxCalculatorRequest(
            operation: ToolboxCalculatorOperation.evaluate,
            expression: 'f(x):=x^2',
          ),
        ),
        throwsA(
          isA<ToolboxCalculatorEngineException>().having(
            (error) => error.code,
            'code',
            ToolboxCalculatorFailureCode.invalidInput,
          ),
        ),
      );
    });

    test(
      'does not resurrect an engine disposed during asset loading',
      () async {
        final assets = _GatedAssetBundle(rootBundle);
        final disposableEngine = ToolboxCalculatorCasEngine(
          assetBundle: assets,
          calculationTimeout: const Duration(seconds: 8),
        );
        final calculation = disposableEngine.calculate(
          const ToolboxCalculatorRequest(
            operation: ToolboxCalculatorOperation.evaluate,
            expression: '1+1',
          ),
        );
        await assets.started.future;
        final expectation = expectLater(
          calculation,
          throwsA(
            isA<ToolboxCalculatorEngineException>().having(
              (error) => error.code,
              'code',
              ToolboxCalculatorFailureCode.engineUnavailable,
            ),
          ),
        );
        final disposal = disposableEngine.dispose();
        assets.release.complete();

        await expectation;
        await disposal;
        await expectLater(
          disposableEngine.calculate(
            const ToolboxCalculatorRequest(
              operation: ToolboxCalculatorOperation.evaluate,
              expression: '2+2',
            ),
          ),
          throwsA(isA<ToolboxCalculatorEngineException>()),
        );
      },
    );
  });
}

class _GatedAssetBundle extends CachingAssetBundle {
  _GatedAssetBundle(this.delegate);

  final AssetBundle delegate;
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();

  @override
  Future<ByteData> load(String key) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return delegate.load(key);
  }
}

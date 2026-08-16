import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_scientific_calculator_service.dart';

void main() {
  group('ToolboxScientificCalculatorService', () {
    const calculator = ToolboxScientificCalculatorService();

    test('evaluates scientific expressions with angle modes', () {
      expect(calculator.evaluate('sin(30)'), closeTo(0.5, 1e-12));
      expect(
        calculator.evaluate(
          'sin(pi / 2)',
          angleMode: ScientificAngleMode.radian,
        ),
        closeTo(1, 1e-12),
      );
      expect(calculator.evaluate('sqrt(9) + log(100)'), closeTo(5, 1e-12));
    });

    test('supports calculator-style algebra and scientific functions', () {
      expect(
        calculator.evaluate('2pi', angleMode: ScientificAngleMode.radian),
        closeTo(2 * math.pi, 1e-12),
      );
      expect(calculator.evaluate('3(2 + 4)'), closeTo(18, 1e-12));
      expect(calculator.evaluate('5! + nCr(6, 2)'), closeTo(135, 1e-12));
      expect(calculator.evaluate('nPr(5, 2)'), closeTo(20, 1e-12));
      expect(
        calculator.evaluate('gcd(84, 30) + lcm(6, 8)'),
        closeTo(30, 1e-12),
      );
      expect(calculator.evaluate('root(3, 27)'), closeTo(3, 1e-12));
      expect(calculator.evaluate('pow(2, 8)'), closeTo(256, 1e-12));
      expect(calculator.evaluate('log(2, 32)'), closeTo(5, 1e-12));
      expect(calculator.evaluate('cosh(0) + tanh(0)'), closeTo(1, 1e-12));
    });

    test('estimates integral derivative limit and root numerically', () {
      expect(
        calculator.integrate(
          'sin(x)',
          lower: 0,
          upper: math.pi,
          angleMode: ScientificAngleMode.radian,
        ),
        closeTo(2, 1e-8),
      );
      expect(calculator.derivative('x^3', at: 2), closeTo(12, 1e-4));

      final limit = calculator.limit(
        'sin(x) / x',
        at: 0,
        angleMode: ScientificAngleMode.radian,
      );
      expect(limit.converged, isTrue);
      expect(limit.value, closeTo(1, 1e-8));

      final root = calculator.solveRoot('x^2 - 2', leftBound: 0, rightBound: 2);
      expect(root.value, closeTo(math.sqrt2, 1e-9));
      expect(root.residual.abs(), lessThan(1e-8));
    });

    test('handles linear algebra and probability helpers', () {
      final matrix = calculator.parseMatrix('1, 2; 3, 4');
      expect(calculator.determinant(matrix), closeTo(-2, 1e-12));
      final solution = calculator.solveLinear(
        calculator.parseMatrix('2, 1; 1, -1'),
        calculator.parseVector('5, 1'),
      );
      expect(solution[0], closeTo(2, 1e-12));
      expect(solution[1], closeTo(1, 1e-12));

      expect(calculator.combination(10, 3), closeTo(120, 1e-12));
      expect(
        calculator.binomialPmf(n: 10, k: 3, p: 0.5),
        closeTo(0.1171875, 1e-12),
      );
      expect(
        calculator.normalCdf(mean: 0, standardDeviation: 1, x: 0),
        closeTo(0.5, 1e-7),
      );
    });
  });
}

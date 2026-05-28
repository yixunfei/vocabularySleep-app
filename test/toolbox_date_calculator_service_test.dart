import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_date_calculator_service.dart';

void main() {
  group('toolbox date calculator service', () {
    final service = ToolboxDateCalculatorService();

    test('computes calendar diff with second-level remainder', () {
      final diff = service.difference(
        DateTime(2026, 1, 31, 23, 59, 30),
        DateTime(2027, 3, 1, 1, 0, 45),
      );

      expect(diff.isNegative, isFalse);
      expect(diff.years, 1);
      expect(diff.months, 1);
      expect(diff.days, 0);
      expect(diff.hours, 1);
      expect(diff.minutes, 1);
      expect(diff.seconds, 15);
      expect(diff.totalSeconds, greaterThan(0));
      expect(diff.approxYears, greaterThan(1));
    });

    test('supports fractional and percent years in date math', () {
      final halfYear = service.offset(
        ToolboxDateOffsetInput(
          start: DateTime(2026),
          direction: ToolboxDateMathDirection.add,
          years: '0.5',
        ),
      );
      final percentYear = service.offset(
        ToolboxDateOffsetInput(
          start: DateTime(2026),
          direction: ToolboxDateMathDirection.add,
          years: '50%',
        ),
      );

      expect(halfYear.end, percentYear.end);
      expect(halfYear.fractionalYearSeconds, greaterThan(0));
      expect(halfYear.calendarYears, 0);
      expect(halfYear.end, DateTime(2026, 7, 2, 12));
    });

    test('uses calendar month clamp for whole month offsets', () {
      final result = service.offset(
        ToolboxDateOffsetInput(
          start: DateTime(2026, 1, 31, 10),
          direction: ToolboxDateMathDirection.add,
          months: '1',
        ),
      );

      expect(result.end, DateTime(2026, 2, 28, 10));
      expect(result.calendarMonths, 1);
    });

    test('computes current period progress and remaining time', () {
      final now = DateTime(2026, 5, 27, 12, 30, 15);
      final progress = service.currentPeriodProgress(now);
      final hour = progress.firstWhere((item) => item.key == 'hour');
      final day = progress.firstWhere((item) => item.key == 'day');

      expect(hour.remaining, const Duration(minutes: 29, seconds: 45));
      expect(hour.progress, closeTo(0.504166, 0.0001));
      expect(
        day.remaining,
        const Duration(hours: 11, minutes: 29, seconds: 45),
      );
      expect(
        progress.map((item) => item.key),
        containsAll(<String>['hour', 'day', 'week', 'month', 'year']),
      );
    });

    test('computes target progress and life candle ratio', () {
      final target = service.targetProgress(
        start: DateTime(2026),
        target: DateTime(2026, 1, 11),
        now: DateTime(2026, 1, 6),
      );
      final life = service.lifeCandle(
        birth: DateTime(2000),
        expectedYears: 80,
        now: DateTime(2040),
      );

      expect(target.progress, closeTo(0.5, 0.0001));
      expect(target.remaining, const Duration(days: 5));
      expect(life.burnedRatio, closeTo(0.5, 0.002));
      expect(life.expectedEnd.year, 2080);
    });
  });
}

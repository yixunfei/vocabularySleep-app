import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_number_mark_service.dart';

void main() {
  group('toolbox number mark service', () {
    test('converts chemistry text into superscript marks', () {
      final result = ToolboxNumberMarkService.transform(
        'H2O + CO2',
        mode: ToolboxNumberMarkMode.superscript,
      );

      expect(result.output, 'H²O ⁺ CO²');
      expect(result.changedCount, greaterThanOrEqualTo(3));
      expect(result.unsupportedCount, 4);
    });

    test('supports longest-match circled numbers', () {
      final result = ToolboxNumberMarkService.transform(
        '12 20',
        mode: ToolboxNumberMarkMode.circled,
      );

      expect(result.output, '⑫ ⑳');
    });

    test('normalizes bracketed markers back to plain text', () {
      final result = ToolboxNumberMarkService.transform(
        '⑴⑵⑶',
        mode: ToolboxNumberMarkMode.parenthesized,
        reverse: true,
      );

      expect(result.output, '123');
    });
  });
}

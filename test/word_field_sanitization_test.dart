import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_field.dart';

void main() {
  test('sanitizeDisplayText decodes known escapes for UI rendering', () {
    final input = r'line1\nline2 \"quote\" \\path\/to\tok';
    final cleaned = sanitizeDisplayText(input);

    expect(cleaned, 'line1\nline2 "quote" \\path/to ok');
    expect(cleaned.contains(r'\n'), false);
    expect(cleaned.contains(r'\"'), false);
    expect(cleaned.contains(r'\\path'), false);
  });

  test('sanitizeDisplayText keeps legitimate backslashes', () {
    expect(sanitizeDisplayText(r'C:\\Users\\foo'), r'C:\Users\foo');
    expect(sanitizeDisplayText(r'\\w+'), r'\w+');
    expect(sanitizeDisplayText(r'A\\B'), r'A\B');
  });

  test('field builders sanitize escaped meaning/examples values', () {
    final items = buildFieldItemsFromRecord(<String, Object?>{
      'meaning': r'alpha\nbeta',
      'examples': <String>[r'\"A\"', r'B\\C'],
    });

    final meaning = items.where((item) => item.key == 'meaning').first;
    final examples = items.where((item) => item.key == 'examples').first;

    expect(meaning.asText(), 'alpha\nbeta');
    expect(examples.asList(), <String>['"A"', r'B\C']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/models/word_field.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/word_card.dart';

void main() {
  testWidgets('word card next button switches to the next word', (
    tester,
  ) async {
    await tester.pumpWidget(const _WordCardHarness());

    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('word card supports swipe anywhere to change words', (
    tester,
  ) async {
    await tester.pumpWidget(const _WordCardHarness());

    expect(find.text('Alpha'), findsOneWidget);

    await tester.drag(find.byType(WordCard), const Offset(-320, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Beta'), findsOneWidget);
  });
}

class _WordCardHarness extends StatefulWidget {
  const _WordCardHarness();

  @override
  State<_WordCardHarness> createState() => _WordCardHarnessState();
}

class _WordCardHarnessState extends State<_WordCardHarness> {
  static const List<WordEntry> _words = <WordEntry>[
    WordEntry(
      wordbookId: 1,
      word: 'Alpha',
      meaning: 'First letter',
      fields: <WordFieldItem>[
        WordFieldItem(key: 'meaning', label: 'Meaning', value: 'First letter'),
      ],
    ),
    WordEntry(
      wordbookId: 1,
      word: 'Beta',
      meaning: 'Second letter',
      fields: <WordFieldItem>[
        WordFieldItem(key: 'meaning', label: 'Meaning', value: 'Second letter'),
      ],
    ),
  ];

  int _index = 0;
  int _direction = 1;

  void _move(int delta) {
    setState(() {
      _direction = delta >= 0 ? 1 : -1;
      _index = (_index + delta + _words.length) % _words.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(PlayConfig.defaults.appearance),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WordCard(
            word: _words[_index],
            i18n: AppI18n('en'),
            transitionStyle: WordPageTransitionStyle.pageFlip,
            transitionDirection: _direction,
            isFavorite: _index == 1,
            onPreviousWord: () => _move(-1),
            onNextWord: () => _move(1),
            onSwipePrevious: () => _move(-1),
            onSwipeNext: () => _move(1),
          ),
        ),
      ),
    );
  }
}

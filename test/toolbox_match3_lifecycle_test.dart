import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_mini_games.dart';

void main() {
  testWidgets('restarting during a cascade preserves the new board', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MatchThreeGamePage()));
    await tester.pump();
    final move = _findMove(_boardIcons(tester));
    final cells = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    tester.widget<GestureDetector>(cells.at(move.$1)).onTap!();
    tester.widget<GestureDetector>(cells.at(move.$2)).onTap!();
    await tester.pump(const Duration(milliseconds: 90));
    final restart = find.widgetWithText(FilledButton, 'New game');
    tester.widget<FilledButton>(restart).onPressed!();
    await tester.pump();
    final board = _boardIcons(tester);
    expect(find.text('1200'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump(const Duration(milliseconds: 130));
    expect(_boardIcons(tester), board);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new game cannot be changed by a pending swap', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatchThreeGamePage()));
    await tester.pump();
    final cells = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    // Exercise the tile callbacks without advancing the 90ms swap animation.
    tester.widget<GestureDetector>(cells.at(0)).onTap!();
    tester.widget<GestureDetector>(cells.at(1)).onTap!();
    final restart = find.widgetWithText(FilledButton, 'New game');
    tester.widget<FilledButton>(restart).onPressed!();
    await tester.pump();
    final board = _boardIcons(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_boardIcons(tester), board);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving during a swap cancels its pending timer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MatchThreeGamePage()));
    await tester.pump();
    final cells = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    );
    tester.widget<GestureDetector>(cells.at(0)).onTap!();
    tester.widget<GestureDetector>(cells.at(1)).onTap!();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    // flutter_test also checks that no pending timer survives teardown.
  });
}

List<IconData?> _boardIcons(WidgetTester tester) => tester
    .widgetList<Icon>(
      find.descendant(of: find.byType(GridView), matching: find.byType(Icon)),
    )
    .map((icon) => icon.icon)
    .toList();

(int, int) _findMove(List<IconData?> icons) {
  for (var first = 0; first < 64; first++) {
    for (final second in [
      if (first % 8 < 7) first + 1,
      if (first < 56) first + 8,
    ]) {
      final board = List<IconData?>.of(icons);
      board[first] = icons[second];
      board[second] = icons[first];
      for (var index = 0; index < 64; index++) {
        final horizontal =
            index % 8 < 6 &&
            board[index] == board[index + 1] &&
            board[index] == board[index + 2];
        final vertical =
            index < 48 &&
            board[index] == board[index + 8] &&
            board[index] == board[index + 16];
        if (horizontal || vertical) return (first, second);
      }
    }
  }
  throw StateError('Generated board has no playable move');
}

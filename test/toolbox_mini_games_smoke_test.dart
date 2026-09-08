import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_mini_games.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mini games hub removes randomizer and shows match-3', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MiniGamesToolPage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Choice spinner'), findsNothing);
    expect(find.text('Match-3'), findsOneWidget);
  });

  testWidgets('match-3 page paints the board and controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatchThreeGamePage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Match-3'), findsWidgets);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Row clear'), findsOneWidget);
    expect(find.text('Column clear'), findsOneWidget);
    expect(find.text('Bomb'), findsOneWidget);
    expect(find.text('Rainbow'), findsOneWidget);
    expect(find.text('Obstacle'), findsOneWidget);
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Reshuffle'), findsOneWidget);
  });

  testWidgets('match-3 board accepts repeated swipe attempts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatchThreeGamePage()));
    await tester.pump();

    final board = find.byType(GridView);
    expect(board, findsOneWidget);
    await tester.ensureVisible(board);
    await tester.pump();

    await tester.drag(board, const Offset(58, 0));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);

    await tester.drag(board, const Offset(0, 58));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(find.text('New game'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tetris compact layout fits a narrow phone viewport', (
    tester,
  ) async {
    final view = tester.view;
    final oldPhysicalSize = view.physicalSize;
    final oldDevicePixelRatio = view.devicePixelRatio;
    view
      ..physicalSize = const Size(375, 667)
      ..devicePixelRatio = 1;
    addTearDown(() {
      view
        ..physicalSize = oldPhysicalSize
        ..devicePixelRatio = oldDevicePixelRatio;
    });

    await tester.pumpWidget(const MaterialApp(home: TetrisGamePage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Tetris'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sokoban page paints a generated level', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SokobanGamePage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Sokoban'), findsWidgets);
    expect(find.text('New level'), findsOneWidget);
  });

  testWidgets('sokoban can switch and regenerate triple-box levels rapidly', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SokobanGamePage()));
    await tester.pump();

    await tester.tap(find.text('Triple').first);
    await tester.pump();
    for (var index = 0; index < 8; index += 1) {
      final newLevel = find.text('New level').first;
      await tester.ensureVisible(newLevel);
      await tester.pump();
      await tester.tap(newLevel);
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Triple'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sokoban compact layout fits a narrow phone viewport', (
    tester,
  ) async {
    final view = tester.view;
    final oldPhysicalSize = view.physicalSize;
    final oldDevicePixelRatio = view.devicePixelRatio;
    view
      ..physicalSize = const Size(375, 667)
      ..devicePixelRatio = 1;
    addTearDown(() {
      view
        ..physicalSize = oldPhysicalSize
        ..devicePixelRatio = oldDevicePixelRatio;
    });

    await tester.pumpWidget(const MaterialApp(home: SokobanGamePage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Sokoban'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

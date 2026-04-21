import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_soothing_music/playback_intent_policy.dart';

void main() {
  group('Soothing playback intent', () {
    testWidgets('keeps autoplay intent during rapid next-track taps', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _PlaybackIntentHarness())),
      );

      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
      expect(find.text('track:0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('next-track')));
      await tester.tap(find.byKey(const Key('next-track')));
      await tester.tap(find.byKey(const Key('next-track')));

      await tester.pump(const Duration(milliseconds: 8));
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('track:3'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
    });

    testWidgets('does not auto-resume when playback intent is off', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _PlaybackIntentHarness())),
      );

      await tester.tap(find.byKey(const Key('pause-toggle')));
      await tester.pump();
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('next-track')));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('track:1'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });
  });
}

class _PlaybackIntentHarness extends StatefulWidget {
  const _PlaybackIntentHarness();

  @override
  State<_PlaybackIntentHarness> createState() => _PlaybackIntentHarnessState();
}

class _PlaybackIntentHarnessState extends State<_PlaybackIntentHarness> {
  bool _playing = true;
  bool _loading = false;
  bool _playbackIntent = true;
  int _trackIndex = 0;
  int _pendingLoads = 0;

  bool get _visualActive => SoothingPlaybackIntentPolicy.visualActive(
    playing: _playing,
    loading: _loading,
    playbackIntent: _playbackIntent,
  );

  Future<void> _nextTrack() async {
    final shouldKeepPlaying =
        SoothingPlaybackIntentPolicy.resolveShouldAutoplay(
          playing: _playing,
          playbackIntent: _playbackIntent,
        );
    setState(() {
      _pendingLoads += 1;
      _loading = true;
      _playbackIntent = shouldKeepPlaying;
      // Simulate transient pause event while switching tracks.
      _playing = false;
    });
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 24), () {
        if (!mounted) {
          return;
        }
        final shouldResume = SoothingPlaybackIntentPolicy.resolveShouldAutoplay(
          playing: _playing,
          playbackIntent: _playbackIntent,
        );
        setState(() {
          _trackIndex += 1;
          _pendingLoads -= 1;
          _loading = _pendingLoads > 0;
          _playing = shouldResume;
        });
      }),
    );
  }

  void _pause() {
    setState(() {
      _playing = false;
      _playbackIntent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          _visualActive
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
        ),
        Text('track:$_trackIndex'),
        ElevatedButton(
          key: const Key('next-track'),
          onPressed: _nextTrack,
          child: const Text('next'),
        ),
        ElevatedButton(
          key: const Key('pause-toggle'),
          onPressed: _pause,
          child: const Text('pause'),
        ),
      ],
    );
  }
}

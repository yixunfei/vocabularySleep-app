part of '../toolbox_sound_tools.dart';

class _PianoKeyboardSlice {
  const _PianoKeyboardSlice({
    required this.whiteKeys,
    required this.blackKeys,
    required this.label,
  });

  final List<_PianoKey> whiteKeys;
  final List<_PianoBlackKeyPlacement> blackKeys;
  final String label;
}

class _PianoPitchSet {
  const _PianoPitchSet({required this.id, required this.intervals});

  final String id;
  final List<int> intervals;
}

class _PianoKeyLayoutPreset {
  const _PianoKeyLayoutPreset({
    required this.id,
    required this.keyCount,
    required this.startMidi,
  });

  final String id;
  final int keyCount;
  final int startMidi;
}

class _PianoBlackKeyPlacement {
  const _PianoBlackKeyPlacement({required this.key, required this.slot});

  final _PianoKey key;
  final int slot;
}

class _PianoChordSpec {
  const _PianoChordSpec({
    required this.id,
    required this.highlightIntervals,
    required this.voicedIntervals,
    required this.staggerMs,
  });

  final String id;
  final List<int> highlightIntervals;
  final List<int> voicedIntervals;
  final int staggerMs;
}

class _PianoKeyboardStyle {
  const _PianoKeyboardStyle({
    required this.id,
    required this.whiteTop,
    required this.whiteBottom,
    required this.whiteAccentTop,
    required this.whiteAccentBottom,
    required this.blackTop,
    required this.blackBottom,
    required this.blackAccentTop,
    required this.blackAccentBottom,
    required this.shellTop,
    required this.shellBottom,
    required this.railColor,
    required this.sideGlow,
  });

  final String id;
  final Color whiteTop;
  final Color whiteBottom;
  final Color whiteAccentTop;
  final Color whiteAccentBottom;
  final Color blackTop;
  final Color blackBottom;
  final Color blackAccentTop;
  final Color blackAccentBottom;
  final Color shellTop;
  final Color shellBottom;
  final Color railColor;
  final Color sideGlow;
}

class _PianoViewportSpec {
  const _PianoViewportSpec({
    required this.octaveSpan,
    required this.whiteKeyExtent,
    required this.stageHeight,
    required this.compactLabels,
  });

  final int octaveSpan;
  final double whiteKeyExtent;
  final double stageHeight;
  final bool compactLabels;
}

class _PianoStageMetrics {
  const _PianoStageMetrics({
    required this.size,
    required this.whiteKeyExtent,
    required this.blackKeyWidth,
    required this.blackKeyHeight,
    required this.blackKeyInset,
    required this.blackKeyHitPadding,
  });

  final Size size;
  final double whiteKeyExtent;
  final double blackKeyWidth;
  final double blackKeyHeight;
  final double blackKeyInset;
  final double blackKeyHitPadding;

  double whiteTopFor(int index) => index * whiteKeyExtent;

  double blackTopFor(int slot) {
    final top = whiteKeyExtent * (slot + 1) - blackKeyHeight / 2;
    return top.clamp(4.0, math.max(4.0, size.height - blackKeyHeight - 4.0));
  }

  Rect _blackRectForSlot(int slot, {bool expanded = false}) {
    final left = size.width - blackKeyWidth - blackKeyInset;
    final top = blackTopFor(slot);
    if (!expanded) {
      return Rect.fromLTWH(left, top, blackKeyWidth, blackKeyHeight);
    }
    final expandedLeft = math.max(0.0, left - blackKeyHitPadding);
    final expandedTop = math.max(0.0, top - blackKeyHitPadding * 0.5);
    final expandedRight = math.min(
      size.width,
      left + blackKeyWidth + math.min(blackKeyInset + blackKeyHitPadding, 14.0),
    );
    final expandedBottom = math.min(
      size.height,
      top + blackKeyHeight + blackKeyHitPadding * 0.5,
    );
    return Rect.fromLTRB(
      expandedLeft,
      expandedTop,
      expandedRight,
      expandedBottom,
    );
  }

  Rect? rectForKey(_PianoKeyboardSlice slice, _PianoKey key) {
    if (key.isSharp) {
      for (final placement in slice.blackKeys) {
        if (placement.key.id != key.id) continue;
        return _blackRectForSlot(placement.slot);
      }
      return null;
    }
    final index = slice.whiteKeys.indexWhere((item) => item.id == key.id);
    if (index < 0) {
      return null;
    }
    return Rect.fromLTWH(0, whiteTopFor(index), size.width, whiteKeyExtent);
  }

  _PianoKey? hitTest(_PianoKeyboardSlice slice, Offset position) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }
    for (final placement in slice.blackKeys.reversed) {
      final rect = _blackRectForSlot(placement.slot, expanded: true);
      if (rect.contains(position)) {
        return placement.key;
      }
    }
    final index = (position.dy / whiteKeyExtent).floor().clamp(
      0,
      slice.whiteKeys.length - 1,
    );
    return slice.whiteKeys[index];
  }
}

class _PianoOverlayChip extends StatelessWidget {
  const _PianoOverlayChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PianoCompactDeckFocus { low, high }

enum _PianoTopBarAction { toggleCompact, openSettings }

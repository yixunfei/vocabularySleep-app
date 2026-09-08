import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    'assets/toolbox/history_timeline/prehistoric.webp',
    'assets/toolbox/history_timeline/neolithic.webp',
    'assets/toolbox/history_timeline/bronze_age.webp',
    'assets/toolbox/history_timeline/shang_zhou.webp',
    'assets/toolbox/history_timeline/qin_han.webp',
    'assets/toolbox/history_timeline/six_dynasties.webp',
    'assets/toolbox/history_timeline/tang_song.webp',
    'assets/toolbox/history_timeline/yuan_ming.webp',
    'assets/toolbox/history_timeline/qing.webp',
    'assets/toolbox/history_timeline/late_qing.webp',
    'assets/toolbox/history_timeline/republic.webp',
    'assets/toolbox/history_timeline/modern.webp',
  ];

  test('history timeline WebP assets are bundled and decodable', () async {
    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes, isNotEmpty, reason: 'Expected bytes for $asset');

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: asset);
      expect(frame.image.height, greaterThan(0), reason: asset);
      frame.image.dispose();
      codec.dispose();
    }
  });
}

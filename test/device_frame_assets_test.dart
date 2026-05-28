import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    'assets/toolbox/device_frames/iphone_titanium_frame.png',
    'assets/toolbox/device_frames/iphone_titanium_shadow.png',
    'assets/toolbox/device_frames/iphone_titanium_glare.png',
    'assets/toolbox/device_frames/iphone_obsidian_frame.png',
    'assets/toolbox/device_frames/iphone_obsidian_shadow.png',
    'assets/toolbox/device_frames/iphone_obsidian_glare.png',
    'assets/toolbox/device_frames/android_graphite_frame.png',
    'assets/toolbox/device_frames/android_graphite_shadow.png',
    'assets/toolbox/device_frames/android_graphite_glare.png',
    'assets/toolbox/device_frames/android_frost_frame.png',
    'assets/toolbox/device_frames/android_frost_shadow.png',
    'assets/toolbox/device_frames/android_frost_glare.png',
  ];

  test('device frame assets are bundled', () async {
    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'Expected asset bytes for $asset',
      );
    }
  });
}

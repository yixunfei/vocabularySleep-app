import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_meme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toolbox meme service renders a png meme image', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 240, 180),
      Paint()..color = const Color(0xFF3563FF),
    );
    canvas.drawCircle(
      const Offset(180, 40),
      28,
      Paint()..color = const Color(0xFFFFD166),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(240, 180);

    final bytes = await ToolboxMemeService.renderPng(
      ToolboxMemeRenderRequest(
        sourceImage: image,
        layers: <ToolboxMemeTextLayer>[
          const ToolboxMemeTextLayer(
            id: 'top',
            text: 'HELLO',
            centerX: 0.5,
            centerY: 0.18,
            bubbleStyle: ToolboxMemeBubbleStyle.classic,
            zIndex: 0,
          ),
          const ToolboxMemeTextLayer(
            id: 'bottom',
            text: 'WORLD 2.0',
            centerX: 0.5,
            centerY: 0.84,
            bubbleStyle: ToolboxMemeBubbleStyle.classic,
            zIndex: 1,
          ),
          ToolboxMemeTextLayer(
            id: 'sticker',
            text: 'Test meme',
            centerX: 0.72,
            centerY: 0.72,
            scale: 0.82,
            bubbleStyle: ToolboxMemeBubbleStyle.sticker,
            fontFamily: ToolboxMemeFontFamily.monospace,
            zIndex: 2,
            textColor: Colors.white,
            strokeColor: Colors.black,
            panelColor: Colors.black.withValues(alpha: 0.58),
          ),
        ],
      ),
    );

    image.dispose();

    expect(bytes, isA<Uint8List>());
    expect(bytes.length, greaterThan(1000));
    expect(bytes.sublist(0, 4), <int>[137, 80, 78, 71]);
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_image_to_web_service.dart';

void main() {
  group('ToolboxImageToWebService', () {
    test('builds a single-file HTML page with escaped metadata', () {
      final imageBytes = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final html = ToolboxImageToWebService.buildHtml(
        ToolboxImageToWebRequest(
          imageBytes: imageBytes,
          fileName: 'cat.png',
          width: 320,
          height: 240,
          title: 'Cat <demo> "quote"',
          altText: 'orange & white "friend"',
          fit: ToolboxImageToWebFit.cover,
          background: ToolboxImageToWebBackground.checker,
        ),
      );

      expect(html, contains('<!doctype html>'));
      expect(html, contains('Cat &lt;demo&gt;'));
      expect(html, contains('&quot;quote&quot;'));
      expect(html, contains('orange &amp; white &quot;friend&quot;'));
      expect(html, contains('data:image/png;base64,'));
      expect(html, contains(base64Encode(imageBytes)));
      expect(html, contains('fit-cover'));
      expect(html, contains('bg-checker'));
    });

    test('parses Uguu upload JSON response', () {
      final result = ToolboxImageToWebService.parseUguuUploadResponse(
        jsonEncode(<String, Object?>{
          'success': true,
          'files': <Map<String, Object?>>[
            <String, Object?>{
              'hash': 'abc',
              'name': 'cat.png',
              'url': 'https://files.catbox.test/cat.png',
              'size': '1234',
            },
          ],
        }),
      );

      expect(result.url.toString(), 'https://files.catbox.test/cat.png');
      expect(result.name, 'cat.png');
      expect(result.hash, 'abc');
      expect(result.sizeBytes, 1234);
    });

    test('detects common image mime types', () {
      expect(
        ToolboxImageToWebService.detectImageMimeType(
          'photo.jpg',
          Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]),
        ),
        'image/jpeg',
      );
      expect(
        ToolboxImageToWebService.detectImageMimeType(
          'still.webp',
          Uint8List.fromList(<int>[
            0x52,
            0x49,
            0x46,
            0x46,
            0,
            0,
            0,
            0,
            0x57,
            0x45,
            0x42,
            0x50,
          ]),
        ),
        'image/webp',
      );
    });
  });
}

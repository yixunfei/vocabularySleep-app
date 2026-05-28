import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vocabulary_sleep_app/src/services/toolbox_qr_service.dart';

void main() {
  group('toolbox qr service', () {
    test('builds Wi-Fi payload with escaped delimiters', () {
      final result = ToolboxQrService.buildPayload(
        const ToolboxQrPayloadInput(
          type: ToolboxQrPayloadType.wifi,
          wifiSsid: 'Cafe;Guest',
          wifiPassword: r'p:a,s\s',
          wifiEncryption: ToolboxQrWifiEncryption.wpa,
          wifiHidden: true,
        ),
      );

      expect(result.payload, r'WIFI:T:WPA;S:Cafe\;Guest;P:p\:a\,s\\s;H:true;;');
    });

    test('builds vCard payload with contact fields', () {
      final result = ToolboxQrService.buildPayload(
        const ToolboxQrPayloadInput(
          type: ToolboxQrPayloadType.contact,
          contactName: 'Alex Chen',
          contactPhone: '+86 138',
          contactEmail: 'alex@example.com',
          contactOrg: 'Vocabulary Sleep',
        ),
      );

      expect(result.payload, contains('BEGIN:VCARD'));
      expect(result.payload, contains('FN:Alex Chen'));
      expect(result.payload, contains('TEL;TYPE=CELL:+86 138'));
      expect(result.payload, contains('EMAIL:alex@example.com'));
    });

    test('builds UTC calendar payload', () {
      final result = ToolboxQrService.buildPayload(
        ToolboxQrPayloadInput(
          type: ToolboxQrPayloadType.calendar,
          eventTitle: 'Review',
          eventLocation: 'Room A',
          eventStart: DateTime.utc(2026, 5, 27, 8, 30),
          eventEnd: DateTime.utc(2026, 5, 27, 9, 0),
        ),
      );

      expect(result.payload, contains('BEGIN:VEVENT'));
      expect(result.payload, contains('SUMMARY:Review'));
      expect(result.payload, contains('DTSTART:20260527T083000Z'));
      expect(result.payload, contains('DTEND:20260527T090000Z'));
    });

    test('compresses small image into data URL payload', () {
      final image = img.Image(width: 48, height: 48);
      img.fill(image, color: img.ColorRgb8(20, 120, 200));
      final source = Uint8List.fromList(img.encodePng(image));

      final result = ToolboxQrService.encodeImageToDataUrl(
        source,
        maxSide: 24,
        jpegQuality: 50,
      );

      expect(result.dataUrl, startsWith('data:image/jpeg;base64,'));
      expect(result.width, 24);
      expect(result.height, 24);
      expect(result.dataUrlBytes, greaterThan(result.bytes.length));
    });

    test('auto-compresses noisy large images toward QR payload target', () {
      final image = img.Image(width: 768, height: 512);
      for (var y = 0; y < image.height; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          image.setPixelRgb(
            x,
            y,
            (x * 17 + y * 3) % 256,
            (x * 5 + y * 29) % 256,
            (x * 11 + y * 7) % 256,
          );
        }
      }
      final source = Uint8List.fromList(img.encodeJpg(image, quality: 95));

      final result = ToolboxQrService.encodeImageToDataUrl(
        source,
        maxSide: 144,
        jpegQuality: 82,
        targetDataUrlBytes: 2200,
      );

      expect(result.autoCompressed, isTrue);
      expect(result.sourceWidth, 768);
      expect(result.sourceHeight, 512);
      expect(result.sourceBytesLength, source.length);
      expect(result.width, lessThanOrEqualTo(144));
      expect(result.dataUrlBytes, lessThanOrEqualTo(2200));
      expect(result.attemptCount, greaterThan(1));
      expect(result.compressionNote, contains('->'));
    });

    test('prepares large art image for QR preview rendering', () {
      final image = img.Image(width: 1600, height: 1000);
      for (var y = 0; y < image.height; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          image.setPixelRgb(
            x,
            y,
            (x * 13 + y * 17) % 256,
            (x * 19 + y * 7) % 256,
            (x * 5 + y * 23) % 256,
          );
        }
      }
      final source = Uint8List.fromList(img.encodeJpg(image, quality: 95));

      final result = ToolboxQrService.prepareArtImage(
        source,
        maxSide: 720,
        jpegQuality: 82,
        targetBytes: 256 * 1024,
      );

      expect(result.autoCompressed, isTrue);
      expect(result.sourceWidth, 1600);
      expect(result.sourceHeight, 1000);
      expect(result.sourceBytesLength, source.length);
      expect(result.width, lessThanOrEqualTo(720));
      expect(result.bytes.length, lessThanOrEqualTo(256 * 1024));
      expect(result.compressionNote, contains('JPEG'));
    });
  });
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum ToolboxQrPayloadType {
  text,
  url,
  wifi,
  contact,
  email,
  sms,
  phone,
  geo,
  calendar,
  imageDataUrl,
}

extension ToolboxQrPayloadTypeInfo on ToolboxQrPayloadType {
  String get id {
    return switch (this) {
      ToolboxQrPayloadType.text => 'text',
      ToolboxQrPayloadType.url => 'url',
      ToolboxQrPayloadType.wifi => 'wifi',
      ToolboxQrPayloadType.contact => 'contact',
      ToolboxQrPayloadType.email => 'email',
      ToolboxQrPayloadType.sms => 'sms',
      ToolboxQrPayloadType.phone => 'phone',
      ToolboxQrPayloadType.geo => 'geo',
      ToolboxQrPayloadType.calendar => 'calendar',
      ToolboxQrPayloadType.imageDataUrl => 'image_data_url',
    };
  }

  String get label {
    return switch (this) {
      ToolboxQrPayloadType.text => 'Text',
      ToolboxQrPayloadType.url => 'URL',
      ToolboxQrPayloadType.wifi => 'Wi-Fi',
      ToolboxQrPayloadType.contact => 'vCard',
      ToolboxQrPayloadType.email => 'Email',
      ToolboxQrPayloadType.sms => 'SMS',
      ToolboxQrPayloadType.phone => 'Phone',
      ToolboxQrPayloadType.geo => 'Geo',
      ToolboxQrPayloadType.calendar => 'Calendar',
      ToolboxQrPayloadType.imageDataUrl => 'Image Data URL',
    };
  }
}

enum ToolboxQrEncodingStandard { qrCode, dataMatrix, aztec, pdf417 }

extension ToolboxQrEncodingStandardInfo on ToolboxQrEncodingStandard {
  String get id {
    return switch (this) {
      ToolboxQrEncodingStandard.qrCode => 'qr_code',
      ToolboxQrEncodingStandard.dataMatrix => 'data_matrix',
      ToolboxQrEncodingStandard.aztec => 'aztec',
      ToolboxQrEncodingStandard.pdf417 => 'pdf417',
    };
  }

  String get label {
    return switch (this) {
      ToolboxQrEncodingStandard.qrCode => 'QR Code',
      ToolboxQrEncodingStandard.dataMatrix => 'Data Matrix',
      ToolboxQrEncodingStandard.aztec => 'Aztec',
      ToolboxQrEncodingStandard.pdf417 => 'PDF417',
    };
  }

  bool get supportsRichQrStyle => this == ToolboxQrEncodingStandard.qrCode;
}

enum ToolboxQrWifiEncryption { wpa, wep, nopass }

extension ToolboxQrWifiEncryptionInfo on ToolboxQrWifiEncryption {
  String get id {
    return switch (this) {
      ToolboxQrWifiEncryption.wpa => 'WPA',
      ToolboxQrWifiEncryption.wep => 'WEP',
      ToolboxQrWifiEncryption.nopass => 'nopass',
    };
  }

  String get label {
    return switch (this) {
      ToolboxQrWifiEncryption.wpa => 'WPA/WPA2/WPA3',
      ToolboxQrWifiEncryption.wep => 'WEP',
      ToolboxQrWifiEncryption.nopass => 'No password',
    };
  }
}

enum ToolboxQrImageCodec { png, jpeg }

extension ToolboxQrImageCodecInfo on ToolboxQrImageCodec {
  String get mimeType {
    return switch (this) {
      ToolboxQrImageCodec.png => 'image/png',
      ToolboxQrImageCodec.jpeg => 'image/jpeg',
    };
  }

  String get extension {
    return switch (this) {
      ToolboxQrImageCodec.png => 'png',
      ToolboxQrImageCodec.jpeg => 'jpg',
    };
  }
}

@immutable
class ToolboxQrPayloadInput {
  const ToolboxQrPayloadInput({
    required this.type,
    this.text = '',
    this.url = '',
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.wifiEncryption = ToolboxQrWifiEncryption.wpa,
    this.wifiHidden = false,
    this.contactName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.contactOrg = '',
    this.emailTo = '',
    this.emailSubject = '',
    this.emailBody = '',
    this.smsPhone = '',
    this.smsBody = '',
    this.phoneNumber = '',
    this.latitude = '',
    this.longitude = '',
    this.geoLabel = '',
    this.eventTitle = '',
    this.eventLocation = '',
    this.eventStart,
    this.eventEnd,
    this.imageDataUrl = '',
  });

  final ToolboxQrPayloadType type;
  final String text;
  final String url;
  final String wifiSsid;
  final String wifiPassword;
  final ToolboxQrWifiEncryption wifiEncryption;
  final bool wifiHidden;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String contactOrg;
  final String emailTo;
  final String emailSubject;
  final String emailBody;
  final String smsPhone;
  final String smsBody;
  final String phoneNumber;
  final String latitude;
  final String longitude;
  final String geoLabel;
  final String eventTitle;
  final String eventLocation;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final String imageDataUrl;
}

@immutable
class ToolboxQrPayloadResult {
  const ToolboxQrPayloadResult({
    required this.payload,
    required this.byteLength,
    required this.displaySummary,
    this.warning = '',
  });

  final String payload;
  final int byteLength;
  final String displaySummary;
  final String warning;
}

@immutable
class ToolboxQrImageDataResult {
  const ToolboxQrImageDataResult({
    required this.dataUrl,
    required this.bytes,
    required this.width,
    required this.height,
    required this.codec,
    required this.sha256Short,
    this.sourceBytesLength = 0,
    this.sourceWidth = 0,
    this.sourceHeight = 0,
    this.targetDataUrlBytes = 0,
    this.autoCompressed = false,
    this.attemptCount = 1,
    this.compressionNote = '',
  });

  final String dataUrl;
  final Uint8List bytes;
  final int width;
  final int height;
  final ToolboxQrImageCodec codec;
  final String sha256Short;
  final int sourceBytesLength;
  final int sourceWidth;
  final int sourceHeight;
  final int targetDataUrlBytes;
  final bool autoCompressed;
  final int attemptCount;
  final String compressionNote;

  int get dataUrlBytes => utf8.encode(dataUrl).length;
}

@immutable
class ToolboxQrArtImageResult {
  const ToolboxQrArtImageResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.sha256Short,
    this.sourceBytesLength = 0,
    this.sourceWidth = 0,
    this.sourceHeight = 0,
    this.targetBytes = 0,
    this.autoCompressed = false,
    this.attemptCount = 1,
    this.compressionNote = '',
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String sha256Short;
  final int sourceBytesLength;
  final int sourceWidth;
  final int sourceHeight;
  final int targetBytes;
  final bool autoCompressed;
  final int attemptCount;
  final String compressionNote;
}

@immutable
class _ToolboxQrImageEncodeCandidate {
  const _ToolboxQrImageEncodeCandidate({
    required this.dataUrl,
    required this.bytes,
    required this.width,
    required this.height,
    required this.codec,
    required this.maxSide,
    required this.jpegQuality,
  });

  final String dataUrl;
  final Uint8List bytes;
  final int width;
  final int height;
  final ToolboxQrImageCodec codec;
  final int maxSide;
  final int jpegQuality;

  int get dataUrlBytes => dataUrl.length;

  String get summary {
    final format = codec == ToolboxQrImageCodec.jpeg
        ? 'JPEG q$jpegQuality'
        : 'PNG';
    return '$format ${width}x$height';
  }
}

@immutable
class _ToolboxQrArtImageCandidate {
  const _ToolboxQrArtImageCandidate({
    required this.bytes,
    required this.width,
    required this.height,
    required this.maxSide,
    required this.jpegQuality,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int maxSide;
  final int jpegQuality;

  String get summary => 'JPEG q$jpegQuality ${width}x$height';
}

class ToolboxQrService {
  const ToolboxQrService._();

  static ToolboxQrPayloadResult buildPayload(ToolboxQrPayloadInput input) {
    final payload = switch (input.type) {
      ToolboxQrPayloadType.text => input.text.trim().isEmpty ? ' ' : input.text,
      ToolboxQrPayloadType.url => _normalizeUrlPayload(input.url),
      ToolboxQrPayloadType.wifi => _buildWifiPayload(input),
      ToolboxQrPayloadType.contact => _buildVCardPayload(input),
      ToolboxQrPayloadType.email => _buildEmailPayload(input),
      ToolboxQrPayloadType.sms => _buildSmsPayload(input),
      ToolboxQrPayloadType.phone => 'tel:${input.phoneNumber.trim()}',
      ToolboxQrPayloadType.geo => _buildGeoPayload(input),
      ToolboxQrPayloadType.calendar => _buildCalendarPayload(input),
      ToolboxQrPayloadType.imageDataUrl => input.imageDataUrl.trim(),
    };
    final byteLength = utf8.encode(payload).length;
    final warning = _payloadWarning(input.type, byteLength);
    return ToolboxQrPayloadResult(
      payload: payload,
      byteLength: byteLength,
      displaySummary: _payloadSummary(input, payload),
      warning: warning,
    );
  }

  static ToolboxQrImageDataResult encodeImageToDataUrl(
    Uint8List sourceBytes, {
    int maxSide = 96,
    int jpegQuality = 62,
    ToolboxQrImageCodec codec = ToolboxQrImageCodec.jpeg,
    int targetDataUrlBytes = 2200,
    bool allowAutoCompress = true,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('Unsupported image bytes.');
    }
    final oriented = img.bakeOrientation(decoded);
    final clampedMaxSide = maxSide.clamp(24, 192).toInt();
    final clampedQuality = jpegQuality.clamp(12, 92).toInt();
    final targetBytes = math.max(600, targetDataUrlBytes);
    final initial = _encodeImageCandidate(
      oriented,
      codec: codec,
      maxSide: clampedMaxSide,
      jpegQuality: clampedQuality,
    );

    var selected = initial;
    var attemptCount = 1;
    if (allowAutoCompress && initial.dataUrlBytes > targetBytes) {
      for (final side in _autoImageSides(clampedMaxSide)) {
        for (final quality in _autoJpegQualities(clampedQuality)) {
          final candidate = _encodeImageCandidate(
            oriented,
            codec: ToolboxQrImageCodec.jpeg,
            maxSide: side,
            jpegQuality: quality,
          );
          attemptCount += 1;
          if (candidate.dataUrlBytes < selected.dataUrlBytes) {
            selected = candidate;
          }
          if (candidate.dataUrlBytes <= targetBytes) {
            selected = candidate;
            break;
          }
        }
        if (selected.dataUrlBytes <= targetBytes) {
          break;
        }
      }
    }

    final output = selected.bytes;
    final digest = sha256.convert(output).toString().substring(0, 12);
    final autoCompressed =
        oriented.width != selected.width ||
        oriented.height != selected.height ||
        selected.bytes.length < sourceBytes.length ||
        selected.codec != codec ||
        selected.maxSide != clampedMaxSide ||
        selected.jpegQuality != clampedQuality;
    final compressionNote = selected == initial
        ? selected.summary
        : '${initial.summary} -> ${selected.summary}';
    return ToolboxQrImageDataResult(
      dataUrl: selected.dataUrl,
      bytes: output,
      width: selected.width,
      height: selected.height,
      codec: selected.codec,
      sha256Short: digest,
      sourceBytesLength: sourceBytes.length,
      sourceWidth: oriented.width,
      sourceHeight: oriented.height,
      targetDataUrlBytes: targetBytes,
      autoCompressed: autoCompressed,
      attemptCount: attemptCount,
      compressionNote: compressionNote,
    );
  }

  static ToolboxQrArtImageResult prepareArtImage(
    Uint8List sourceBytes, {
    int maxSide = 720,
    int jpegQuality = 78,
    int targetBytes = 720 * 1024,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('Unsupported image bytes.');
    }
    final oriented = img.bakeOrientation(decoded);
    final clampedMaxSide = maxSide.clamp(128, 1200).toInt();
    final clampedQuality = jpegQuality.clamp(40, 92).toInt();
    final safeTargetBytes = math.max(128 * 1024, targetBytes);
    final initial = _encodeArtImageCandidate(
      oriented,
      maxSide: clampedMaxSide,
      jpegQuality: clampedQuality,
    );

    var selected = initial;
    var attemptCount = 1;
    if (initial.bytes.length > safeTargetBytes) {
      for (final side in _autoArtImageSides(clampedMaxSide)) {
        for (final quality in _autoArtJpegQualities(clampedQuality)) {
          final candidate = _encodeArtImageCandidate(
            oriented,
            maxSide: side,
            jpegQuality: quality,
          );
          attemptCount += 1;
          if (candidate.bytes.length < selected.bytes.length) {
            selected = candidate;
          }
          if (candidate.bytes.length <= safeTargetBytes) {
            selected = candidate;
            break;
          }
        }
        if (selected.bytes.length <= safeTargetBytes) {
          break;
        }
      }
    }

    final output = selected.bytes;
    final digest = sha256.convert(output).toString().substring(0, 12);
    final autoCompressed =
        oriented.width != selected.width ||
        oriented.height != selected.height ||
        selected.bytes.length < sourceBytes.length ||
        selected.maxSide != clampedMaxSide ||
        selected.jpegQuality != clampedQuality;
    final compressionNote = selected == initial
        ? selected.summary
        : '${initial.summary} -> ${selected.summary}';
    return ToolboxQrArtImageResult(
      bytes: output,
      width: selected.width,
      height: selected.height,
      sha256Short: digest,
      sourceBytesLength: sourceBytes.length,
      sourceWidth: oriented.width,
      sourceHeight: oriented.height,
      targetBytes: safeTargetBytes,
      autoCompressed: autoCompressed,
      attemptCount: attemptCount,
      compressionNote: compressionNote,
    );
  }

  static _ToolboxQrImageEncodeCandidate _encodeImageCandidate(
    img.Image oriented, {
    required ToolboxQrImageCodec codec,
    required int maxSide,
    required int jpegQuality,
  }) {
    final safeMaxSide = maxSide.clamp(24, 192).toInt();
    final safeQuality = jpegQuality.clamp(12, 92).toInt();
    final longestSide = math.max(oriented.width, oriented.height);
    final resized = longestSide <= safeMaxSide
        ? oriented
        : img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? safeMaxSide : null,
            height: oriented.height > oriented.width ? safeMaxSide : null,
            interpolation: img.Interpolation.average,
          );
    final output = switch (codec) {
      ToolboxQrImageCodec.png => Uint8List.fromList(img.encodePng(resized)),
      ToolboxQrImageCodec.jpeg => Uint8List.fromList(
        img.encodeJpg(
          resized,
          quality: safeQuality,
          chroma: img.JpegChroma.yuv420,
        ),
      ),
    };
    final dataUrl = 'data:${codec.mimeType};base64,${base64Encode(output)}';
    return _ToolboxQrImageEncodeCandidate(
      dataUrl: dataUrl,
      bytes: output,
      width: resized.width,
      height: resized.height,
      codec: codec,
      maxSide: safeMaxSide,
      jpegQuality: safeQuality,
    );
  }

  static _ToolboxQrArtImageCandidate _encodeArtImageCandidate(
    img.Image oriented, {
    required int maxSide,
    required int jpegQuality,
  }) {
    final safeMaxSide = maxSide.clamp(128, 1200).toInt();
    final safeQuality = jpegQuality.clamp(40, 92).toInt();
    final longestSide = math.max(oriented.width, oriented.height);
    final resized = longestSide <= safeMaxSide
        ? oriented
        : img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? safeMaxSide : null,
            height: oriented.height > oriented.width ? safeMaxSide : null,
            interpolation: img.Interpolation.average,
          );
    final output = Uint8List.fromList(
      img.encodeJpg(
        resized,
        quality: safeQuality,
        chroma: img.JpegChroma.yuv420,
      ),
    );
    return _ToolboxQrArtImageCandidate(
      bytes: output,
      width: resized.width,
      height: resized.height,
      maxSide: safeMaxSide,
      jpegQuality: safeQuality,
    );
  }

  static Iterable<int> _autoImageSides(int requestedMaxSide) sync* {
    final seen = <int>{};
    for (final side in <int>[
      requestedMaxSide,
      96,
      80,
      72,
      64,
      56,
      48,
      40,
      32,
      24,
    ]) {
      final safe = side.clamp(24, 192).toInt();
      if (seen.add(safe)) {
        yield safe;
      }
    }
  }

  static Iterable<int> _autoArtImageSides(int requestedMaxSide) sync* {
    final seen = <int>{};
    for (final side in <int>[
      requestedMaxSide,
      960,
      840,
      720,
      640,
      560,
      480,
      384,
      320,
      256,
    ]) {
      final safe = side.clamp(128, 1200).toInt();
      if (seen.add(safe)) {
        yield safe;
      }
    }
  }

  static Iterable<int> _autoArtJpegQualities(int requestedQuality) sync* {
    final seen = <int>{};
    for (final quality in <int>[
      requestedQuality,
      82,
      76,
      70,
      64,
      58,
      52,
      46,
      40,
    ]) {
      final safe = quality.clamp(40, 92).toInt();
      if (seen.add(safe)) {
        yield safe;
      }
    }
  }

  static Iterable<int> _autoJpegQualities(int requestedQuality) sync* {
    final seen = <int>{};
    for (final quality in <int>[requestedQuality, 56, 48, 40, 32, 24, 18, 12]) {
      final safe = quality.clamp(12, 92).toInt();
      if (seen.add(safe)) {
        yield safe;
      }
    }
  }

  static String _normalizeUrlPayload(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return 'https://example.com';
    }
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed)) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  static String _buildWifiPayload(ToolboxQrPayloadInput input) {
    final encryption = input.wifiEncryption.id;
    final ssid = _escapeWifi(input.wifiSsid.trim());
    final password = _escapeWifi(input.wifiPassword);
    final hidden = input.wifiHidden ? 'true' : 'false';
    return 'WIFI:T:$encryption;S:$ssid;P:$password;H:$hidden;;';
  }

  static String _buildVCardPayload(ToolboxQrPayloadInput input) {
    final name = _escapeVCard(
      input.contactName.trim().isEmpty ? 'Contact' : input.contactName.trim(),
    );
    final phone = _escapeVCard(input.contactPhone.trim());
    final email = _escapeVCard(input.contactEmail.trim());
    final org = _escapeVCard(input.contactOrg.trim());
    return <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:$name',
      if (org.isNotEmpty) 'ORG:$org',
      if (phone.isNotEmpty) 'TEL;TYPE=CELL:$phone',
      if (email.isNotEmpty) 'EMAIL:$email',
      'END:VCARD',
    ].join('\n');
  }

  static String _buildEmailPayload(ToolboxQrPayloadInput input) {
    final query = <String, String>{
      if (input.emailSubject.trim().isNotEmpty)
        'subject': input.emailSubject.trim(),
      if (input.emailBody.trim().isNotEmpty) 'body': input.emailBody.trim(),
    };
    return Uri(
      scheme: 'mailto',
      path: input.emailTo.trim(),
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  static String _buildSmsPayload(ToolboxQrPayloadInput input) {
    final phone = input.smsPhone.trim();
    final body = input.smsBody.trim();
    return body.isEmpty
        ? 'SMSTO:$phone:'
        : 'SMSTO:$phone:${body.replaceAll('\n', ' ')}';
  }

  static String _buildGeoPayload(ToolboxQrPayloadInput input) {
    final lat = double.tryParse(input.latitude.trim()) ?? 0;
    final lon = double.tryParse(input.longitude.trim()) ?? 0;
    final label = input.geoLabel.trim();
    final safeLat = lat.clamp(-90.0, 90.0).toStringAsFixed(6);
    final safeLon = lon.clamp(-180.0, 180.0).toStringAsFixed(6);
    if (label.isEmpty) {
      return 'geo:$safeLat,$safeLon';
    }
    return 'geo:$safeLat,$safeLon?q=$safeLat,$safeLon(${Uri.encodeComponent(label)})';
  }

  static String _buildCalendarPayload(ToolboxQrPayloadInput input) {
    final start = input.eventStart ?? DateTime.now();
    final end = input.eventEnd ?? start.add(const Duration(hours: 1));
    return <String>[
      'BEGIN:VEVENT',
      'SUMMARY:${_escapeICalendar(input.eventTitle.trim().isEmpty ? 'Event' : input.eventTitle.trim())}',
      'DTSTART:${_formatUtcIcs(start)}',
      'DTEND:${_formatUtcIcs(end.isAfter(start) ? end : start.add(const Duration(hours: 1)))}',
      if (input.eventLocation.trim().isNotEmpty)
        'LOCATION:${_escapeICalendar(input.eventLocation.trim())}',
      'END:VEVENT',
    ].join('\n');
  }

  static String _payloadSummary(ToolboxQrPayloadInput input, String payload) {
    return switch (input.type) {
      ToolboxQrPayloadType.text => 'Text, ${payload.runes.length} chars',
      ToolboxQrPayloadType.url => payload,
      ToolboxQrPayloadType.wifi => 'Wi-Fi ${input.wifiSsid.trim()}',
      ToolboxQrPayloadType.contact => 'vCard ${input.contactName.trim()}',
      ToolboxQrPayloadType.email => 'Email ${input.emailTo.trim()}',
      ToolboxQrPayloadType.sms => 'SMS ${input.smsPhone.trim()}',
      ToolboxQrPayloadType.phone => 'Phone ${input.phoneNumber.trim()}',
      ToolboxQrPayloadType.geo => 'Geo ${input.latitude}, ${input.longitude}',
      ToolboxQrPayloadType.calendar => 'Calendar ${input.eventTitle.trim()}',
      ToolboxQrPayloadType.imageDataUrl => 'Image Data URL',
    };
  }

  static String _payloadWarning(ToolboxQrPayloadType type, int bytes) {
    if (type == ToolboxQrPayloadType.imageDataUrl) {
      if (bytes > 2400) {
        return 'Image payload is large. Many phone scanners may fail; use logo mode for reliable sharing.';
      }
      if (bytes > 1400) {
        return 'Image payload is near the practical scan limit. Test before sharing.';
      }
    }
    if (bytes > 2200) {
      return 'Payload is large for QR scanning. Use high contrast, larger size, and high error correction.';
    }
    return '';
  }

  static String _escapeWifi(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:');
  }

  static String _escapeVCard(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
  }

  static String _escapeICalendar(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
  }

  static String _formatUtcIcs(DateTime dateTime) {
    final utc = dateTime.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}'
        '${two(utc.month)}'
        '${two(utc.day)}T'
        '${two(utc.hour)}'
        '${two(utc.minute)}'
        '${two(utc.second)}Z';
  }
}

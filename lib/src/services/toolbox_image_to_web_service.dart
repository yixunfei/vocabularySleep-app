import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

enum ToolboxImageToWebFit { contain, cover, natural }

enum ToolboxImageToWebBackground { light, dark, checker }

class ToolboxImageToWebRequest {
  const ToolboxImageToWebRequest({
    required this.imageBytes,
    required this.fileName,
    required this.width,
    required this.height,
    required this.title,
    required this.altText,
    required this.fit,
    required this.background,
  });

  final Uint8List imageBytes;
  final String fileName;
  final int width;
  final int height;
  final String title;
  final String altText;
  final ToolboxImageToWebFit fit;
  final ToolboxImageToWebBackground background;
}

class ToolboxImageToWebUploadResult {
  const ToolboxImageToWebUploadResult({
    required this.url,
    required this.name,
    required this.hash,
    required this.sizeBytes,
  });

  final Uri url;
  final String name;
  final String hash;
  final int? sizeBytes;
}

class ToolboxImageToWebService {
  const ToolboxImageToWebService._();

  static const String uguuUploadEndpoint = 'https://uguu.se/upload';

  static String buildHtml(ToolboxImageToWebRequest request) {
    final title = _escapeHtml(_fallback(request.title, request.fileName));
    final alt = _escapeHtml(_fallback(request.altText, request.fileName));
    final fileName = _escapeHtml(request.fileName);
    final mimeType = detectImageMimeType(request.fileName, request.imageBytes);
    final dataUri = 'data:$mimeType;base64,${base64Encode(request.imageBytes)}';
    final backgroundClass = switch (request.background) {
      ToolboxImageToWebBackground.light => 'bg-light',
      ToolboxImageToWebBackground.dark => 'bg-dark',
      ToolboxImageToWebBackground.checker => 'bg-checker',
    };
    final imageClass = switch (request.fit) {
      ToolboxImageToWebFit.contain => 'fit-contain',
      ToolboxImageToWebFit.cover => 'fit-cover',
      ToolboxImageToWebFit.natural => 'fit-natural',
    };
    final width = request.width <= 0 ? 'unknown' : '${request.width}px';
    final height = request.height <= 0 ? 'unknown' : '${request.height}px';

    return '''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <style>
    :root {
      color-scheme: light dark;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    * { box-sizing: border-box; }
    body {
      min-height: 100vh;
      margin: 0;
      display: grid;
      grid-template-rows: auto 1fr auto;
      color: #182034;
    }
    .bg-light { background: #f7f4ee; }
    .bg-dark { background: #141821; color: #f6f3ea; }
    .bg-checker {
      background-color: #f7f4ee;
      background-image:
        linear-gradient(45deg, #dde2ea 25%, transparent 25%),
        linear-gradient(-45deg, #dde2ea 25%, transparent 25%),
        linear-gradient(45deg, transparent 75%, #dde2ea 75%),
        linear-gradient(-45deg, transparent 75%, #dde2ea 75%);
      background-size: 24px 24px;
      background-position: 0 0, 0 12px, 12px -12px, -12px 0;
    }
    header, footer {
      width: min(960px, calc(100vw - 32px));
      margin: 0 auto;
      padding: 20px 0;
    }
    h1 {
      margin: 0 0 6px;
      font-size: clamp(22px, 4vw, 42px);
      line-height: 1.08;
      letter-spacing: 0;
    }
    .meta {
      margin: 0;
      color: currentColor;
      opacity: .72;
      font-size: 14px;
      overflow-wrap: anywhere;
    }
    main {
      width: min(1120px, calc(100vw - 24px));
      margin: 0 auto;
      display: grid;
      place-items: center;
      padding: 8px 0 24px;
    }
    .stage {
      width: 100%;
      min-height: min(72vh, 760px);
      display: grid;
      place-items: center;
      padding: 12px;
      border: 1px solid rgb(145 153 170 / .38);
      border-radius: 22px;
      background: rgb(255 255 255 / .64);
      box-shadow: 0 18px 48px rgb(24 32 52 / .14);
      backdrop-filter: blur(16px);
    }
    .bg-dark .stage {
      background: rgb(255 255 255 / .08);
      border-color: rgb(255 255 255 / .22);
      box-shadow: 0 18px 54px rgb(0 0 0 / .36);
    }
    img {
      display: block;
      border-radius: 14px;
      box-shadow: 0 12px 34px rgb(24 32 52 / .22);
    }
    .fit-contain {
      max-width: 100%;
      max-height: min(70vh, 720px);
      object-fit: contain;
    }
    .fit-cover {
      width: 100%;
      height: min(70vh, 720px);
      object-fit: cover;
    }
    .fit-natural {
      max-width: 100%;
      height: auto;
    }
    footer {
      font-size: 12px;
      opacity: .62;
    }
  </style>
</head>
<body class="$backgroundClass">
  <header>
    <h1>$title</h1>
    <p class="meta">$fileName - $width x $height - embedded $mimeType</p>
  </header>
  <main>
    <section class="stage" aria-label="$alt">
      <img class="$imageClass" src="$dataUri" alt="$alt">
    </section>
  </main>
  <footer>Single-file image page generated locally.</footer>
</body>
</html>
''';
  }

  static Future<ToolboxImageToWebUploadResult> uploadToUguu({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(uguuUploadEndpoint),
    );
    request.headers.addAll(const <String, String>{
      'Accept': 'application/json,text/plain,*/*',
      'User-Agent': 'vocabulary-sleep-app',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'files[]',
        imageBytes,
        filename: safeBaseName(fileName, fallback: 'image.png'),
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Uguu upload failed: HTTP ${response.statusCode}',
        Uri.parse(uguuUploadEndpoint),
      );
    }
    return parseUguuUploadResponse(body);
  }

  static ToolboxImageToWebUploadResult parseUguuUploadResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Uguu response is not a JSON map.');
    }
    final files = decoded['files'];
    final success = decoded['success'] == true || decoded['success'] == 'true';
    if (!success || files is! List || files.isEmpty) {
      final description =
          decoded['description']?.toString() ??
          decoded['error']?.toString() ??
          'Uguu did not return uploaded files.';
      throw FormatException(description);
    }
    final first = files.first;
    if (first is! Map) {
      throw const FormatException('Uguu file info is malformed.');
    }
    final rawUrl = first['url']?.toString().trim() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Uguu returned an invalid URL.');
    }
    return ToolboxImageToWebUploadResult(
      url: uri,
      name: first['name']?.toString() ?? '',
      hash: first['hash']?.toString() ?? '',
      sizeBytes: _parseInt(first['size']),
    );
  }

  static String detectImageMimeType(String fileName, Uint8List bytes) {
    if (_startsWith(bytes, const <int>[0x89, 0x50, 0x4E, 0x47])) {
      return 'image/png';
    }
    if (_startsWith(bytes, const <int>[0xFF, 0xD8, 0xFF])) {
      return 'image/jpeg';
    }
    if (_startsWith(bytes, const <int>[0x47, 0x49, 0x46, 0x38])) {
      return 'image/gif';
    }
    if (_startsWith(bytes, const <int>[0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    if (_startsWith(bytes, const <int>[0x3C, 0x73, 0x76, 0x67]) ||
        _startsWith(bytes, const <int>[0x3C, 0x3F, 0x78, 0x6D, 0x6C])) {
      return 'image/svg+xml';
    }

    return switch (path.extension(fileName).toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.svg' => 'image/svg+xml',
      '.bmp' => 'image/bmp',
      '.avif' => 'image/avif',
      _ => 'image/png',
    };
  }

  static String suggestedHtmlFileName(String sourceName) {
    final base = safeBaseName(path.basenameWithoutExtension(sourceName));
    return '${base.isEmpty ? 'image_page' : base}_image_page.html';
  }

  static String safeBaseName(String value, {String fallback = 'image_page'}) {
    final normalized = path.basename(value.trim());
    final safe = normalized
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    return safe.isEmpty ? fallback : safe;
  }

  static String _escapeHtml(String value) {
    return const HtmlEscape(HtmlEscapeMode.attribute).convert(value);
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) {
      return false;
    }
    for (var index = 0; index < prefix.length; index += 1) {
      if (bytes[index] != prefix[index]) {
        return false;
      }
    }
    return true;
  }

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

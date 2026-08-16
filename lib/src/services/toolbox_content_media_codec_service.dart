import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as img;

import 'toolbox_crypto_service.dart';

enum ToolboxContentMediaFormat { imagePng, audioWav }

enum ToolboxContentMediaImageFillMode { softGradient, paperGrain, duskNoise }

enum ToolboxContentMediaDamageLevel { light, medium }

class ToolboxContentMediaException implements Exception {
  const ToolboxContentMediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolboxContentMediaEncodeResult {
  const ToolboxContentMediaEncodeResult({
    required this.format,
    required this.bytes,
    required this.fileName,
    required this.envelopeBytes,
    required this.envelopeSha256,
    required this.outputSha256,
    required this.plainBytes,
    required this.cipherPreview,
    this.imageWidth,
    this.imageHeight,
    this.sampleRate,
    this.duration,
  });

  final ToolboxContentMediaFormat format;
  final Uint8List bytes;
  final String fileName;
  final Uint8List envelopeBytes;
  final String envelopeSha256;
  final String outputSha256;
  final int plainBytes;
  final String cipherPreview;
  final int? imageWidth;
  final int? imageHeight;
  final int? sampleRate;
  final Duration? duration;
}

class ToolboxContentMediaDecodeResult {
  const ToolboxContentMediaDecodeResult({
    required this.format,
    required this.plainBytes,
    required this.envelopeBytes,
    required this.envelopeSha256,
    required this.mediaBytes,
    required this.algorithm,
    required this.strength,
    required this.cipherPreview,
    this.fileName,
    this.mediaType,
  });

  final ToolboxContentMediaFormat format;
  final Uint8List plainBytes;
  final Uint8List envelopeBytes;
  final String envelopeSha256;
  final int mediaBytes;
  final ToolboxCryptoAlgorithm algorithm;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
  final String? fileName;
  final String? mediaType;
}

class ToolboxContentMediaAttemptPolicy {
  const ToolboxContentMediaAttemptPolicy({
    required this.maxDecrypts,
    required this.maxErrors,
    required this.successfulDecrypts,
    required this.failedAttempts,
  });

  final int maxDecrypts;
  final int maxErrors;
  final int successfulDecrypts;
  final int failedAttempts;

  bool get blocksBeforeDecrypt =>
      maxDecrypts > 0 && successfulDecrypts >= maxDecrypts;

  bool get clearsAfterDecryptSuccess =>
      maxDecrypts > 0 && successfulDecrypts + 1 >= maxDecrypts;

  bool get clearsAfterDecryptFailure =>
      maxErrors > 0 && failedAttempts + 1 >= maxErrors;
}

class ToolboxContentMediaSecureWiper {
  const ToolboxContentMediaSecureWiper._();

  static void randomOverwrite(Uint8List? bytes, {int passes = 1}) {
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    final rounds = passes.clamp(1, 8).toInt();
    for (var round = 0; round < rounds; round += 1) {
      for (var index = 0; index < bytes.length; index += 1) {
        bytes[index] = ToolboxContentMediaCodecService._secureRandom.nextInt(
          256,
        );
      }
    }
  }
}

class ToolboxContentMediaCodecService {
  static const int version = 1;
  static const int maxMediaEnvelopeBytes = 32 * 1024 * 1024;
  static const int maxImagePixels = 16 * 1024 * 1024;
  static const int pngMinimumWidth = 32;
  static const int pngMaximumMinimumDimension = 4096;
  static const int networkImageMaxRedirects = 3;
  static const int wavSampleRate = 44100;

  static const int _payloadHeaderBytes = 48;
  static const int _wavBitsPerSample = 16;
  static const int _wavChannels = 1;
  static const int _wavAmplitudeShift = 7;
  static final Uint8List _payloadMagic = Uint8List.fromList(
    ascii.encode('VSCMED1!'),
  );
  static final math.Random _secureRandom = math.Random.secure();

  final ToolboxCryptoService _cryptoService = ToolboxCryptoService();

  static Uri normalizeNetworkImageUri(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const ToolboxContentMediaException('Network image URL is empty.');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      throw const ToolboxContentMediaException('Network image URL is invalid.');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw const ToolboxContentMediaException(
        'Only HTTPS image URLs are supported.',
      );
    }
    if (isBlockedNetworkImageHost(uri.host)) {
      throw const ToolboxContentMediaException(
        'Network image host is local or private.',
      );
    }
    return uri;
  }

  static bool isBlockedNetworkImageHost(String host) {
    var normalized = host.trim().toLowerCase();
    if (normalized.startsWith('[') && normalized.endsWith(']')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    if (normalized.isEmpty ||
        normalized == 'localhost' ||
        normalized.endsWith('.localhost')) {
      return true;
    }
    final octets = normalized.split('.');
    if (octets.length == 4 &&
        octets.every((part) => RegExp(r'^\d{1,3}$').hasMatch(part))) {
      final values = octets.map(int.parse).toList(growable: false);
      if (values.any((value) => value < 0 || value > 255)) {
        return true;
      }
      final first = values[0];
      final second = values[1];
      return first == 0 ||
          first == 10 ||
          first == 127 ||
          (first == 169 && second == 254) ||
          (first == 172 && second >= 16 && second <= 31) ||
          (first == 192 && second == 168);
    }
    if (!normalized.contains(':')) {
      return false;
    }
    return normalized == '::1' ||
        normalized.startsWith('fe80:') ||
        normalized.startsWith('fc') ||
        normalized.startsWith('fd');
  }

  static bool allowsNetworkImageContentType(String? mimeType) {
    final normalized = mimeType?.toLowerCase().split(';').first.trim() ?? '';
    if (normalized.isEmpty) {
      return true;
    }
    return normalized == 'image/png' ||
        normalized == 'application/octet-stream' ||
        normalized == 'binary/octet-stream';
  }

  static bool hasPngSignature(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) {
      return false;
    }
    for (var index = 0; index < signature.length; index += 1) {
      if (bytes[index] != signature[index]) {
        return false;
      }
    }
    return true;
  }

  static String networkImageFileName(Uri uri) {
    final rawName = uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.last.trim();
    final sanitized = rawName
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final safeName = sanitized.isEmpty || sanitized == '.' || sanitized == '..'
        ? 'network_encrypted_media.png'
        : sanitized;
    final lower = safeName.toLowerCase();
    return lower.endsWith('.png') ? safeName : '$safeName.png';
  }

  ToolboxContentMediaEncodeResult encryptToPngImage({
    required Uint8List plainBytes,
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    required String passphrase,
    Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode =
        ToolboxCryptoSignatureMode.ecdsaSha256,
    String outputFileName = 'vocabulary_sleep_content_media.png',
    int minimumImageWidth = pngMinimumWidth,
    int minimumImageHeight = 1,
    ToolboxContentMediaImageFillMode fillMode =
        ToolboxContentMediaImageFillMode.softGradient,
    bool naturalizePayload = true,
  }) {
    final encrypted = _cryptoService.encryptBytes(
      plainBytes: plainBytes,
      algorithm: algorithm,
      strength: strength,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final payload = _wrapEnvelope(encrypted.envelopeBytes);
    final requiredChannelCount = naturalizePayload
        ? payload.length * 2
        : payload.length;
    final pixelCount = (requiredChannelCount + 2) ~/ 3;
    if (pixelCount > maxImagePixels) {
      throw const ToolboxContentMediaException(
        'Encrypted payload is too large for image media.',
      );
    }
    final dimensions = _imageDimensions(
      pixelCount,
      minimumWidth: minimumImageWidth,
      minimumHeight: minimumImageHeight,
    );
    final image = img.Image(
      width: dimensions.width,
      height: dimensions.height,
      numChannels: 4,
    );
    final pixelBytes = _naturalImageChannels(
      width: dimensions.width,
      height: dimensions.height,
      fillMode: fillMode,
    );
    if (naturalizePayload) {
      _writePayloadNibbles(pixelBytes, payload);
    } else {
      pixelBytes.setRange(0, payload.length, payload);
      _fillRandom(pixelBytes, payload.length);
    }

    var offset = 0;
    for (var y = 0; y < dimensions.height; y += 1) {
      for (var x = 0; x < dimensions.width; x += 1) {
        image.setPixelRgba(
          x,
          y,
          pixelBytes[offset],
          pixelBytes[offset + 1],
          pixelBytes[offset + 2],
          255,
        );
        offset += 3;
      }
    }

    final bytes = Uint8List.fromList(img.encodePng(image, level: 1));
    return ToolboxContentMediaEncodeResult(
      format: ToolboxContentMediaFormat.imagePng,
      bytes: bytes,
      fileName: _normalizedFileName(outputFileName, 'png'),
      envelopeBytes: encrypted.envelopeBytes,
      envelopeSha256: _hexDigest(
        crypto.sha256.convert(encrypted.envelopeBytes),
      ),
      outputSha256: _hexDigest(crypto.sha256.convert(bytes)),
      plainBytes: encrypted.plainBytes,
      cipherPreview: encrypted.cipherPreview,
      imageWidth: dimensions.width,
      imageHeight: dimensions.height,
    );
  }

  Uint8List simulatePngTransferDamage({
    required Uint8List imageBytes,
    ToolboxContentMediaDamageLevel level = ToolboxContentMediaDamageLevel.light,
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const ToolboxContentMediaException(
        'Image media is invalid or unsupported.',
      );
    }
    if (decoded.width * decoded.height > maxImagePixels) {
      throw const ToolboxContentMediaException(
        'Image media dimensions are too large.',
      );
    }
    final channels = _extractImageChannels(decoded);
    try {
      _unwrapEnvelope(_readPayloadNibbles(channels));
    } on ToolboxContentMediaException {
      throw const ToolboxContentMediaException(
        'Damage simulation requires naturalized PNG media.',
      );
    }

    final damaged = img.Image.from(decoded);
    final scratchCount = switch (level) {
      ToolboxContentMediaDamageLevel.light => 4,
      ToolboxContentMediaDamageLevel.medium => 10,
    };
    final blockCount = switch (level) {
      ToolboxContentMediaDamageLevel.light => 5,
      ToolboxContentMediaDamageLevel.medium => 14,
    };

    for (var line = 0; line < scratchCount; line += 1) {
      final y = _secureRandom.nextInt(damaged.height);
      final thickness =
          1 +
          _secureRandom.nextInt(
            level == ToolboxContentMediaDamageLevel.light ? 2 : 4,
          );
      final high = _secureRandom.nextInt(16) << 4;
      for (var dy = 0; dy < thickness && y + dy < damaged.height; dy += 1) {
        for (var x = 0; x < damaged.width; x += 1) {
          _rewritePixelHighNibbles(damaged, x, y + dy, high, high, high);
        }
      }
    }

    for (var block = 0; block < blockCount; block += 1) {
      final x0 = _secureRandom.nextInt(damaged.width);
      final y0 = _secureRandom.nextInt(damaged.height);
      final w =
          4 +
          _secureRandom.nextInt(
            level == ToolboxContentMediaDamageLevel.light ? 16 : 42,
          );
      final h =
          3 +
          _secureRandom.nextInt(
            level == ToolboxContentMediaDamageLevel.light ? 10 : 28,
          );
      final rHigh = _secureRandom.nextInt(16) << 4;
      final gHigh = _secureRandom.nextInt(16) << 4;
      final bHigh = _secureRandom.nextInt(16) << 4;
      for (var y = y0; y < math.min(damaged.height, y0 + h); y += 1) {
        for (var x = x0; x < math.min(damaged.width, x0 + w); x += 1) {
          _rewritePixelHighNibbles(damaged, x, y, rHigh, gHigh, bHigh);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(damaged, level: 1));
  }

  ToolboxContentMediaEncodeResult encryptToWavAudio({
    required Uint8List plainBytes,
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    required String passphrase,
    Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode =
        ToolboxCryptoSignatureMode.ecdsaSha256,
    String outputFileName = 'vocabulary_sleep_content_media.wav',
  }) {
    final encrypted = _cryptoService.encryptBytes(
      plainBytes: plainBytes,
      algorithm: algorithm,
      strength: strength,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final payload = _wrapEnvelope(encrypted.envelopeBytes);
    final sampleCount = math.max(payload.length, 2048);
    final pcm = Uint8List(sampleCount * 2);
    final data = ByteData.sublistView(pcm);
    for (var index = 0; index < sampleCount; index += 1) {
      final value = index < payload.length
          ? payload[index]
          : _secureRandom.nextInt(256);
      final sample = (value - 128) << _wavAmplitudeShift;
      data.setInt16(index * 2, sample, Endian.little);
    }
    final bytes = _wavBytesFromPcm(pcm, sampleRate: wavSampleRate);
    return ToolboxContentMediaEncodeResult(
      format: ToolboxContentMediaFormat.audioWav,
      bytes: bytes,
      fileName: _normalizedFileName(outputFileName, 'wav'),
      envelopeBytes: encrypted.envelopeBytes,
      envelopeSha256: _hexDigest(
        crypto.sha256.convert(encrypted.envelopeBytes),
      ),
      outputSha256: _hexDigest(crypto.sha256.convert(bytes)),
      plainBytes: encrypted.plainBytes,
      cipherPreview: encrypted.cipherPreview,
      sampleRate: wavSampleRate,
      duration: Duration(
        microseconds: (sampleCount * 1000000 / wavSampleRate).round(),
      ),
    );
  }

  ToolboxContentMediaDecodeResult decryptFromPngImage({
    required Uint8List imageBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    final img.Image decoded;
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw const ToolboxContentMediaException(
          'Image media is invalid or unsupported.',
        );
      }
      decoded = image;
    } on ToolboxContentMediaException {
      rethrow;
    } catch (_) {
      throw const ToolboxContentMediaException(
        'Image media is invalid or unsupported.',
      );
    }
    if (decoded.width * decoded.height > maxImagePixels) {
      throw const ToolboxContentMediaException(
        'Image media dimensions are too large.',
      );
    }
    final envelope = _unwrapImageEnvelope(_extractImageChannels(decoded));
    return _decryptEnvelope(
      format: ToolboxContentMediaFormat.imagePng,
      mediaBytes: imageBytes.length,
      envelopeBytes: envelope,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
  }

  ToolboxContentMediaDecodeResult decryptFromWavAudio({
    required Uint8List wavBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    final wav = _parseWavPcm16Mono(wavBytes);
    final payload = Uint8List(wav.sampleCount);
    final data = ByteData.sublistView(wavBytes);
    for (var index = 0; index < wav.sampleCount; index += 1) {
      final sample = data.getInt16(
        wav.dataOffset + index * wav.bytesPerSample,
        Endian.little,
      );
      payload[index] = ((sample >> _wavAmplitudeShift) + 128) & 255;
    }
    final envelope = _unwrapEnvelope(payload);
    return _decryptEnvelope(
      format: ToolboxContentMediaFormat.audioWav,
      mediaBytes: wavBytes.length,
      envelopeBytes: envelope,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
  }

  ToolboxContentMediaDecodeResult decryptFromMediaBytes({
    required Uint8List mediaBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
    String? extension,
  }) {
    final normalized = extension?.toLowerCase().replaceFirst('.', '').trim();
    if (normalized == 'png') {
      return decryptFromPngImage(
        imageBytes: mediaBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    }
    if (normalized == 'wav' || normalized == 'wave') {
      return decryptFromWavAudio(
        wavBytes: mediaBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    }
    try {
      return decryptFromPngImage(
        imageBytes: mediaBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    } on ToolboxContentMediaException {
      return decryptFromWavAudio(
        wavBytes: mediaBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    }
  }

  ToolboxContentMediaDecodeResult _decryptEnvelope({
    required ToolboxContentMediaFormat format,
    required int mediaBytes,
    required Uint8List envelopeBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    final decrypted = _cryptoService.decryptBytes(
      envelopeBytes: envelopeBytes,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
    return ToolboxContentMediaDecodeResult(
      format: format,
      plainBytes: decrypted.plainBytes,
      envelopeBytes: envelopeBytes,
      envelopeSha256: _hexDigest(crypto.sha256.convert(envelopeBytes)),
      mediaBytes: mediaBytes,
      algorithm: decrypted.algorithm,
      strength: decrypted.strength,
      cipherPreview: decrypted.cipherPreview,
      fileName: decrypted.fileName,
      mediaType: decrypted.mediaType,
    );
  }

  Uint8List _wrapEnvelope(Uint8List envelopeBytes) {
    if (envelopeBytes.isEmpty) {
      throw const ToolboxContentMediaException('Encrypted envelope is empty.');
    }
    if (envelopeBytes.length > maxMediaEnvelopeBytes) {
      throw const ToolboxContentMediaException(
        'Encrypted envelope is too large for media encoding.',
      );
    }
    final output = Uint8List(_payloadHeaderBytes + envelopeBytes.length);
    output.setRange(0, _payloadMagic.length, _payloadMagic);
    output[_payloadMagic.length] = version;
    output[_payloadMagic.length + 1] = _payloadHeaderBytes;
    _writeUint16(output, _payloadMagic.length + 2, 0);
    _writeUint32(output, 12, envelopeBytes.length);
    output.setRange(16, 48, crypto.sha256.convert(envelopeBytes).bytes);
    output.setRange(_payloadHeaderBytes, output.length, envelopeBytes);
    return output;
  }

  Uint8List _unwrapEnvelope(Uint8List payloadBytes) {
    if (payloadBytes.length < _payloadHeaderBytes) {
      throw const ToolboxContentMediaException(
        'Media payload header is incomplete.',
      );
    }
    for (var index = 0; index < _payloadMagic.length; index += 1) {
      if (payloadBytes[index] != _payloadMagic[index]) {
        throw const ToolboxContentMediaException(
          'No encrypted media payload found.',
        );
      }
    }
    if (payloadBytes[_payloadMagic.length] != version ||
        payloadBytes[_payloadMagic.length + 1] != _payloadHeaderBytes) {
      throw const ToolboxContentMediaException(
        'Unsupported encrypted media payload version.',
      );
    }
    final envelopeLength = _readUint32(payloadBytes, 12);
    if (envelopeLength <= 0 || envelopeLength > maxMediaEnvelopeBytes) {
      throw const ToolboxContentMediaException(
        'Encrypted media payload length is invalid.',
      );
    }
    final end = _payloadHeaderBytes + envelopeLength;
    if (end > payloadBytes.length) {
      throw const ToolboxContentMediaException(
        'Encrypted media payload is incomplete.',
      );
    }
    final envelope = Uint8List.fromList(
      payloadBytes.sublist(_payloadHeaderBytes, end),
    );
    final expectedDigest = payloadBytes.sublist(16, 48);
    final actualDigest = crypto.sha256.convert(envelope).bytes;
    if (!_constantTimeBytesEquals(expectedDigest, actualDigest)) {
      throw const ToolboxContentMediaException(
        'Encrypted media payload checksum failed.',
      );
    }
    return envelope;
  }

  Uint8List _unwrapImageEnvelope(Uint8List packedChannels) {
    try {
      return _unwrapEnvelope(packedChannels);
    } on ToolboxContentMediaException {
      return _unwrapEnvelope(_readPayloadNibbles(packedChannels));
    }
  }

  _ImageDimensions _imageDimensions(
    int requiredPixels, {
    required int minimumWidth,
    required int minimumHeight,
  }) {
    final rawWidth = math.sqrt(requiredPixels).ceil();
    final minWidth = _boundedMinimumDimension(
      minimumWidth,
      fallback: pngMinimumWidth,
    );
    final minHeight = _boundedMinimumDimension(minimumHeight, fallback: 1);
    final width = math.max(minWidth, rawWidth);
    final height = math.max(minHeight, (requiredPixels + width - 1) ~/ width);
    if (width * height > maxImagePixels) {
      throw const ToolboxContentMediaException(
        'Encrypted payload is too large for image media.',
      );
    }
    return _ImageDimensions(width: width, height: height);
  }

  int _boundedMinimumDimension(int value, {required int fallback}) {
    if (value <= 0) {
      return fallback;
    }
    return value.clamp(1, pngMaximumMinimumDimension).toInt();
  }

  Uint8List _extractImageChannels(img.Image decoded) {
    final packed = Uint8List(decoded.width * decoded.height * 3);
    var offset = 0;
    for (var y = 0; y < decoded.height; y += 1) {
      for (var x = 0; x < decoded.width; x += 1) {
        final pixel = decoded.getPixel(x, y);
        packed[offset] = pixel.r.toInt() & 255;
        packed[offset + 1] = pixel.g.toInt() & 255;
        packed[offset + 2] = pixel.b.toInt() & 255;
        offset += 3;
      }
    }
    return packed;
  }

  Uint8List _naturalImageChannels({
    required int width,
    required int height,
    required ToolboxContentMediaImageFillMode fillMode,
  }) {
    final channels = Uint8List(width * height * 3);
    var offset = 0;
    final safeWidth = math.max(1, width - 1);
    final safeHeight = math.max(1, height - 1);
    for (var y = 0; y < height; y += 1) {
      final fy = y / safeHeight;
      for (var x = 0; x < width; x += 1) {
        final fx = x / safeWidth;
        final grain = _grain(x, y);
        final wave = math.sin((fx * 5.4 + fy * 3.2) * math.pi);
        final values = switch (fillMode) {
          ToolboxContentMediaImageFillMode.softGradient => <int>[
            (120 + fx * 54 + wave * 12 + grain * 0.32).round(),
            (142 + fy * 42 + wave * 7 + grain * 0.26).round(),
            (148 + (1 - fx) * 48 + wave * 10 + grain * 0.22).round(),
          ],
          ToolboxContentMediaImageFillMode.paperGrain => <int>[
            (186 + fx * 26 - fy * 18 + grain * 0.42).round(),
            (174 + fy * 22 + wave * 6 + grain * 0.34).round(),
            (139 + (1 - fx) * 20 + grain * 0.30).round(),
          ],
          ToolboxContentMediaImageFillMode.duskNoise => <int>[
            (74 + fx * 48 + wave * 14 + grain * 0.30).round(),
            (89 + fy * 42 + wave * 9 + grain * 0.24).round(),
            (126 + (1 - fy) * 54 + wave * 11 + grain * 0.28).round(),
          ],
        };
        channels[offset] = _withRandomLowNibble(values[0]);
        channels[offset + 1] = _withRandomLowNibble(values[1]);
        channels[offset + 2] = _withRandomLowNibble(values[2]);
        offset += 3;
      }
    }
    return channels;
  }

  int _withRandomLowNibble(int value) {
    final clamped = value.clamp(0, 255).toInt();
    return (clamped & 0xF0) | _secureRandom.nextInt(16);
  }

  int _grain(int x, int y) {
    var value = x * 374761393 + y * 668265263;
    value = (value ^ (value >> 13)) * 1274126177;
    return ((value ^ (value >> 16)) & 255) - 128;
  }

  void _writePayloadNibbles(Uint8List channels, Uint8List payload) {
    final requiredChannels = payload.length * 2;
    if (requiredChannels > channels.length) {
      throw const ToolboxContentMediaException(
        'Encrypted payload is too large for image media.',
      );
    }
    var channelOffset = 0;
    for (final value in payload) {
      channels[channelOffset] =
          (channels[channelOffset] & 0xF0) | ((value >> 4) & 0x0F);
      channels[channelOffset + 1] =
          (channels[channelOffset + 1] & 0xF0) | (value & 0x0F);
      channelOffset += 2;
    }
  }

  Uint8List _readPayloadNibbles(Uint8List channels) {
    final output = Uint8List(channels.length ~/ 2);
    var out = 0;
    for (var index = 0; index + 1 < channels.length; index += 2) {
      output[out] =
          ((channels[index] & 0x0F) << 4) | (channels[index + 1] & 0x0F);
      out += 1;
    }
    return output;
  }

  void _rewritePixelHighNibbles(
    img.Image image,
    int x,
    int y,
    int rHigh,
    int gHigh,
    int bHigh,
  ) {
    final pixel = image.getPixel(x, y);
    image.setPixelRgba(
      x,
      y,
      (rHigh & 0xF0) | (pixel.r.toInt() & 0x0F),
      (gHigh & 0xF0) | (pixel.g.toInt() & 0x0F),
      (bHigh & 0xF0) | (pixel.b.toInt() & 0x0F),
      pixel.a.toInt() & 255,
    );
  }

  Uint8List _wavBytesFromPcm(Uint8List pcm, {required int sampleRate}) {
    final byteRate = sampleRate * _wavChannels * _wavBitsPerSample ~/ 8;
    final blockAlign = _wavChannels * _wavBitsPerSample ~/ 8;
    final output = Uint8List(44 + pcm.length);
    final data = ByteData.sublistView(output);
    output.setRange(0, 4, ascii.encode('RIFF'));
    data.setUint32(4, output.length - 8, Endian.little);
    output.setRange(8, 12, ascii.encode('WAVE'));
    output.setRange(12, 16, ascii.encode('fmt '));
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, _wavChannels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, blockAlign, Endian.little);
    data.setUint16(34, _wavBitsPerSample, Endian.little);
    output.setRange(36, 40, ascii.encode('data'));
    data.setUint32(40, pcm.length, Endian.little);
    output.setRange(44, output.length, pcm);
    return output;
  }

  _WavInfo _parseWavPcm16Mono(Uint8List bytes) {
    if (bytes.length < 44 ||
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != 'WAVE') {
      throw const ToolboxContentMediaException(
        'Audio media is not a supported WAV file.',
      );
    }
    final data = ByteData.sublistView(bytes);
    int? channels;
    int? bitsPerSample;
    int? dataOffset;
    int? dataLength;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkId = ascii.decode(
        bytes.sublist(offset, offset + 4),
        allowInvalid: true,
      );
      final chunkLength = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;
      final nextOffset =
          chunkDataOffset + chunkLength + (chunkLength.isOdd ? 1 : 0);
      if (chunkDataOffset + chunkLength > bytes.length) {
        throw const ToolboxContentMediaException('WAV media is damaged.');
      }
      if (chunkId == 'fmt ') {
        if (chunkLength < 16) {
          throw const ToolboxContentMediaException('WAV fmt chunk is invalid.');
        }
        final audioFormat = data.getUint16(chunkDataOffset, Endian.little);
        channels = data.getUint16(chunkDataOffset + 2, Endian.little);
        bitsPerSample = data.getUint16(chunkDataOffset + 14, Endian.little);
        if (audioFormat != 1) {
          throw const ToolboxContentMediaException(
            'Audio media must be PCM WAV.',
          );
        }
      } else if (chunkId == 'data') {
        dataOffset = chunkDataOffset;
        dataLength = chunkLength;
      }
      offset = nextOffset;
    }
    if (channels != _wavChannels || bitsPerSample != _wavBitsPerSample) {
      throw const ToolboxContentMediaException(
        'Audio media must be mono PCM16 WAV.',
      );
    }
    final bodyOffset = dataOffset;
    final bodyLength = dataLength;
    if (bodyOffset == null || bodyLength == null || bodyLength < 2) {
      throw const ToolboxContentMediaException('WAV data chunk is missing.');
    }
    return _WavInfo(
      dataOffset: bodyOffset,
      dataLength: bodyLength,
      bytesPerSample: 2,
    );
  }

  void _fillRandom(Uint8List bytes, int start) {
    for (var index = start; index < bytes.length; index += 1) {
      bytes[index] = _secureRandom.nextInt(256);
    }
  }

  void _writeUint16(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 8) & 255;
    bytes[offset + 1] = value & 255;
  }

  void _writeUint32(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 24) & 255;
    bytes[offset + 1] = (value >> 16) & 255;
    bytes[offset + 2] = (value >> 8) & 255;
    bytes[offset + 3] = value & 255;
  }

  int _readUint32(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      throw const ToolboxContentMediaException(
        'Encrypted media payload header is invalid.',
      );
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  bool _constantTimeBytesEquals(List<int> left, List<int> right) {
    var diff = left.length ^ right.length;
    final maxLength = math.max(left.length, right.length);
    for (var index = 0; index < maxLength; index += 1) {
      final l = index < left.length ? left[index] : 0;
      final r = index < right.length ? right[index] : 0;
      diff |= l ^ r;
    }
    return diff == 0;
  }

  String _normalizedFileName(String fileName, String extension) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return 'vocabulary_sleep_content_media.$extension';
    }
    final lower = trimmed.toLowerCase();
    if (lower.endsWith('.$extension')) {
      return trimmed;
    }
    return '$trimmed.$extension';
  }

  String _hexDigest(crypto.Digest digest) {
    return digest.toString();
  }
}

class _ImageDimensions {
  const _ImageDimensions({required this.width, required this.height});

  final int width;
  final int height;
}

class _WavInfo {
  const _WavInfo({
    required this.dataOffset,
    required this.dataLength,
    required this.bytesPerSample,
  });

  final int dataOffset;
  final int dataLength;
  final int bytesPerSample;

  int get sampleCount => dataLength ~/ bytesPerSample;
}

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'toolbox_crypto_service.dart';

enum ToolboxSteganographyMediaKind { image, audio, video }

enum ToolboxSteganographyPayloadKind { text, file }

extension ToolboxSteganographyPayloadKindInfo
    on ToolboxSteganographyPayloadKind {
  String get id {
    return switch (this) {
      ToolboxSteganographyPayloadKind.text => 'text',
      ToolboxSteganographyPayloadKind.file => 'file',
    };
  }
}

class ToolboxSteganographyException implements Exception {
  const ToolboxSteganographyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolboxSteganographyEmbedResult {
  const ToolboxSteganographyEmbedResult({
    required this.bytes,
    required this.outputExtension,
    required this.payloadBytes,
    required this.sourceBytes,
    required this.outputBytes,
    required this.cipherPreview,
    required this.carrierDetail,
    this.capacityBytes,
  });

  final Uint8List bytes;
  final String outputExtension;
  final int payloadBytes;
  final int sourceBytes;
  final int outputBytes;
  final String cipherPreview;
  final String carrierDetail;
  final int? capacityBytes;
}

class ToolboxSteganographyRevealResult {
  const ToolboxSteganographyRevealResult({
    required this.text,
    required this.encryption,
    required this.strength,
    required this.payloadBytes,
    required this.cipherPreview,
    required this.carrierDetail,
  });

  final String text;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final int payloadBytes;
  final String cipherPreview;
  final String carrierDetail;
}

class ToolboxSteganographyFileRevealResult {
  const ToolboxSteganographyFileRevealResult({
    required this.bytes,
    required this.fileName,
    required this.mediaType,
    required this.encryption,
    required this.strength,
    required this.payloadBytes,
    required this.cipherPreview,
    required this.carrierDetail,
  });

  final Uint8List bytes;
  final String? fileName;
  final String? mediaType;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final int payloadBytes;
  final String cipherPreview;
  final String carrierDetail;
}

class ToolboxSteganographyService {
  static final List<int> _blockMagic = ascii.encode('VSSG1');
  static final List<int> _tailMagic = ascii.encode('VSSGT1');
  final ToolboxCryptoService _cryptoService = ToolboxCryptoService();

  ToolboxSteganographyEmbedResult embedText({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String text,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    String? sourceExtension,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (text.isEmpty) {
      throw const ToolboxSteganographyException('Secret text is empty.');
    }
    if (encryption.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }

    final envelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.text,
      text: text,
      encryption: encryption,
      passphrase: passphrase,
      strength: strength,
      keyFileBytes: keyFileBytes,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final block = _buildBlock(envelope.jsonBytes);

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedInImage(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
      ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _embedInTail(
        mediaKind: mediaKind,
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
      ),
    };
  }

  ToolboxSteganographyEmbedResult embedFile({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List fileBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    String? sourceExtension,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (fileBytes.isEmpty) {
      throw const ToolboxSteganographyException('Secret file is empty.');
    }
    if (encryption.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }

    final envelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.file,
      plainBytes: fileBytes,
      encryption: encryption,
      passphrase: passphrase,
      strength: strength,
      keyFileBytes: keyFileBytes,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final block = _buildBlock(envelope.jsonBytes);

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedInImage(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
      ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _embedInTail(
        mediaKind: mediaKind,
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
      ),
    };
  }

  ToolboxSteganographyRevealResult revealText({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }

    final block = switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _extractImageBlock(carrierBytes),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _extractTailBlock(carrierBytes),
    };
    final map = _parseBlock(block);
    final envelope = _parseEnvelope(
      map,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );

    return ToolboxSteganographyRevealResult(
      text: envelope.text,
      encryption: envelope.encryption,
      strength: envelope.strength,
      payloadBytes: block.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: _carrierDetailForReveal(mediaKind, carrierBytes),
    );
  }

  ToolboxSteganographyFileRevealResult revealFile({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }

    final block = switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _extractImageBlock(carrierBytes),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _extractTailBlock(carrierBytes),
    };
    final map = _parseBlock(block);
    final envelope = _parseFileEnvelope(
      map,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );

    return ToolboxSteganographyFileRevealResult(
      bytes: envelope.bytes,
      fileName: envelope.fileName,
      mediaType: envelope.mediaType,
      encryption: envelope.encryption,
      strength: envelope.strength,
      payloadBytes: block.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: _carrierDetailForReveal(mediaKind, carrierBytes),
    );
  }

  ToolboxSteganographyEmbedResult _embedInImage({
    required Uint8List carrierBytes,
    required Uint8List block,
    required _EnvelopeBuildResult envelope,
  }) {
    final decoded = img.decodeImage(carrierBytes);
    if (decoded == null) {
      throw const ToolboxSteganographyException(
        'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.',
      );
    }
    final image = img.bakeOrientation(decoded);
    final capacity = (image.width * image.height * 3) ~/ 8;
    if (block.length > capacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this image. Capacity: $capacity B, need: ${block.length} B.',
      );
    }

    final stegoImage = img.Image.from(image);
    _writeLsbBlock(stegoImage, block);
    final output = Uint8List.fromList(img.encodePng(stegoImage, level: 6));
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: 'png',
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail:
          '${image.width}x${image.height}, capacity ${_formatBytes(capacity)}',
      capacityBytes: capacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedInTail({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List block,
    required _EnvelopeBuildResult envelope,
    String? sourceExtension,
  }) {
    final output = Uint8List(
      carrierBytes.length + block.length + 4 + _tailMagic.length,
    );
    var offset = 0;
    output.setRange(offset, offset + carrierBytes.length, carrierBytes);
    offset += carrierBytes.length;
    output.setRange(offset, offset + block.length, block);
    offset += block.length;
    output.setRange(offset, offset + 4, _uint32Bytes(block.length));
    offset += 4;
    output.setRange(offset, offset + _tailMagic.length, _tailMagic);

    final fallbackExtension = mediaKind == ToolboxSteganographyMediaKind.audio
        ? 'wav'
        : 'mp4';
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: _cleanExtension(sourceExtension) ?? fallbackExtension,
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: 'tail payload +${_formatBytes(block.length)}',
    );
  }

  Uint8List _extractImageBlock(Uint8List carrierBytes) {
    final decoded = img.decodeImage(carrierBytes);
    if (decoded == null) {
      throw const ToolboxSteganographyException(
        'Unsupported image format or no hidden payload found.',
      );
    }
    final image = img.bakeOrientation(decoded);
    final headerLength = _blockMagic.length + 4;
    final capacity = (image.width * image.height * 3) ~/ 8;
    if (capacity < headerLength) {
      throw const ToolboxSteganographyException('Image is too small.');
    }
    final header = _readLsbBytes(image, headerLength);
    if (!_startsWith(header, _blockMagic)) {
      throw const ToolboxSteganographyException(
        'No hidden image payload found.',
      );
    }
    final payloadLength = _readUint32(header, _blockMagic.length);
    final blockLength = headerLength + payloadLength;
    if (blockLength > capacity) {
      throw const ToolboxSteganographyException(
        'Hidden image payload is damaged or incomplete.',
      );
    }
    return _readLsbBytes(image, blockLength);
  }

  Uint8List _extractTailBlock(Uint8List carrierBytes) {
    final minimum = _tailMagic.length + 4 + _blockMagic.length + 4;
    if (carrierBytes.length < minimum) {
      throw const ToolboxSteganographyException('No hidden payload found.');
    }
    final magicOffset = carrierBytes.length - _tailMagic.length;
    if (!_rangeEquals(carrierBytes, magicOffset, _tailMagic)) {
      throw const ToolboxSteganographyException('No hidden payload found.');
    }
    final lengthOffset = magicOffset - 4;
    final blockLength = _readUint32(carrierBytes, lengthOffset);
    final blockOffset = lengthOffset - blockLength;
    if (blockLength <= 0 || blockOffset < 0) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    return Uint8List.fromList(
      carrierBytes.sublist(blockOffset, blockOffset + blockLength),
    );
  }

  _EnvelopeBuildResult _buildEnvelope({
    required ToolboxSteganographyPayloadKind payloadKind,
    String? text,
    Uint8List? plainBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    required ToolboxCryptoStrength strength,
    required Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    final bytes = plainBytes ?? Uint8List.fromList(utf8.encode(text ?? ''));
    final encrypted = _cryptoService.encryptBytes(
      plainBytes: bytes,
      algorithm: encryption,
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
    final envelope = <String, Object?>{
      'version': 2,
      'payloadKind': payloadKind.id,
      'encoding': payloadKind == ToolboxSteganographyPayloadKind.text
          ? 'utf8'
          : 'bytes',
      'fileName': fileName,
      'mediaType': mediaType,
      'cryptoEnvelope': base64Encode(encrypted.envelopeBytes),
    };
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    return _EnvelopeBuildResult(
      jsonBytes: jsonBytes,
      cipherPreview: encrypted.cipherPreview,
    );
  }

  _EnvelopeParseResult _parseEnvelope(
    Map<String, Object?> map, {
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    final version = map['version'];
    if (version == 2) {
      final payloadKind = map['payloadKind'] as String? ?? 'text';
      if (payloadKind != ToolboxSteganographyPayloadKind.text.id) {
        throw const ToolboxSteganographyException(
          'Hidden payload is not text.',
        );
      }
      final envelopeText = map['cryptoEnvelope'];
      if (envelopeText is! String) {
        throw const ToolboxSteganographyException('Hidden payload is invalid.');
      }
      final decrypted = _runCryptoDecrypt(
        envelopeBytes: Uint8List.fromList(base64Decode(envelopeText)),
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
      try {
        return _EnvelopeParseResult(
          text: utf8.decode(decrypted.plainBytes),
          encryption: decrypted.algorithm,
          strength: decrypted.strength,
          cipherPreview: decrypted.cipherPreview,
        );
      } on FormatException {
        throw const ToolboxSteganographyException(
          'Payload text is not valid UTF-8.',
        );
      }
    }
    if (version != 1) {
      throw const ToolboxSteganographyException('Unsupported payload version.');
    }
    return _parseLegacyEnvelope(map, passphrase);
  }

  _FileEnvelopeParseResult _parseFileEnvelope(
    Map<String, Object?> map, {
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    final version = map['version'];
    if (version != 2) {
      throw const ToolboxSteganographyException(
        'This payload does not contain a hidden file.',
      );
    }
    final payloadKind = map['payloadKind'] as String? ?? 'text';
    if (payloadKind != ToolboxSteganographyPayloadKind.file.id) {
      throw const ToolboxSteganographyException(
        'This payload does not contain a hidden file.',
      );
    }
    final envelopeText = map['cryptoEnvelope'];
    if (envelopeText is! String) {
      throw const ToolboxSteganographyException('Hidden payload is invalid.');
    }
    final decrypted = _runCryptoDecrypt(
      envelopeBytes: Uint8List.fromList(base64Decode(envelopeText)),
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
    return _FileEnvelopeParseResult(
      bytes: decrypted.plainBytes,
      fileName: decrypted.fileName ?? map['fileName'] as String?,
      mediaType: decrypted.mediaType ?? map['mediaType'] as String?,
      encryption: decrypted.algorithm,
      strength: decrypted.strength,
      cipherPreview: decrypted.cipherPreview,
    );
  }

  _EnvelopeParseResult _parseLegacyEnvelope(
    Map<String, Object?> map,
    String passphrase,
  ) {
    final cipherId = map['cipher'];
    final nonceText = map['nonce'];
    final cipherText = map['ciphertext'];
    final plainSha = map['plainSha256'];
    final mac = map['mac'];
    if (cipherId is! String ||
        nonceText is! String ||
        cipherText is! String ||
        plainSha is! String ||
        mac is! String) {
      throw const ToolboxSteganographyException('Hidden payload is invalid.');
    }
    final encryption = _legacyAlgorithmFromId(cipherId);
    if (encryption.requiresSecret && passphrase.trim().isEmpty) {
      throw const ToolboxSteganographyException(
        'This payload requires a passphrase.',
      );
    }
    final nonce = Uint8List.fromList(base64Decode(nonceText));
    final cipherBytes = Uint8List.fromList(base64Decode(cipherText));
    if (encryption.requiresSecret) {
      final expectedMac = _legacyHmacHex(
        passphrase: passphrase,
        nonce: nonce,
        cipherId: encryption.id,
        cipherBytes: cipherBytes,
      );
      if (!_constantTimeEquals(mac, expectedMac)) {
        throw const ToolboxSteganographyException(
          'Passphrase mismatch or payload is damaged.',
        );
      }
    } else {
      final expectedMac = _hexDigest(sha256.convert(cipherBytes).bytes);
      if (!_constantTimeEquals(mac, expectedMac)) {
        throw const ToolboxSteganographyException('Payload is damaged.');
      }
    }

    final plainBytes = switch (encryption) {
      ToolboxCryptoAlgorithm.none => cipherBytes,
      ToolboxCryptoAlgorithm.sha256Stream => _xorWithSha256Stream(
        cipherBytes,
        _legacyDeriveKey(passphrase, nonce, 'sha256-stream'),
        nonce,
      ),
      ToolboxCryptoAlgorithm.rc4Legacy => _rc4(
        cipherBytes,
        _legacyDeriveKey(passphrase, nonce, 'rc4-legacy'),
      ),
      _ => throw const ToolboxSteganographyException(
        'Unsupported encryption algorithm.',
      ),
    };
    final actualSha = _hexDigest(sha256.convert(plainBytes).bytes);
    if (!_constantTimeEquals(actualSha, plainSha)) {
      throw const ToolboxSteganographyException('Payload checksum failed.');
    }

    try {
      return _EnvelopeParseResult(
        text: utf8.decode(plainBytes),
        encryption: encryption,
        strength: ToolboxCryptoStrength.standard,
        cipherPreview: _previewBase64(cipherBytes),
      );
    } on FormatException {
      throw const ToolboxSteganographyException(
        'Payload text is not valid UTF-8.',
      );
    }
  }

  Uint8List _buildBlock(Uint8List jsonBytes) {
    return Uint8List.fromList(<int>[
      ..._blockMagic,
      ..._uint32Bytes(jsonBytes.length),
      ...jsonBytes,
    ]);
  }

  Map<String, Object?> _parseBlock(Uint8List block) {
    if (block.length < _blockMagic.length + 4 ||
        !_startsWith(block, _blockMagic)) {
      throw const ToolboxSteganographyException(
        'Hidden payload header is invalid.',
      );
    }
    final jsonLength = _readUint32(block, _blockMagic.length);
    final jsonOffset = _blockMagic.length + 4;
    if (jsonLength <= 0 || jsonOffset + jsonLength != block.length) {
      throw const ToolboxSteganographyException(
        'Hidden payload length is invalid.',
      );
    }
    final decoded = jsonDecode(utf8.decode(block.sublist(jsonOffset)));
    if (decoded is! Map<String, Object?>) {
      throw const ToolboxSteganographyException(
        'Hidden payload body is invalid.',
      );
    }
    return decoded;
  }

  void _writeLsbBlock(img.Image image, Uint8List block) {
    var bitIndex = 0;
    final totalBits = block.length * 8;
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        var r = pixel.r.toInt();
        var g = pixel.g.toInt();
        var b = pixel.b.toInt();
        final a = pixel.a.toInt();
        for (var channel = 0; channel < 3; channel += 1) {
          if (bitIndex >= totalBits) {
            image.setPixelRgba(x, y, r, g, b, a);
            return;
          }
          final bit = _bitAt(block, bitIndex);
          switch (channel) {
            case 0:
              r = (r & 0xfe) | bit;
            case 1:
              g = (g & 0xfe) | bit;
            case 2:
              b = (b & 0xfe) | bit;
          }
          bitIndex += 1;
        }
        image.setPixelRgba(x, y, r, g, b, a);
      }
    }
  }

  Uint8List _readLsbBytes(img.Image image, int byteCount) {
    final output = Uint8List(byteCount);
    var bitIndex = 0;
    final totalBits = byteCount * 8;
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        final channels = <int>[
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        ];
        for (final channel in channels) {
          if (bitIndex >= totalBits) {
            return output;
          }
          output[bitIndex >> 3] |= (channel & 1) << (7 - (bitIndex & 7));
          bitIndex += 1;
        }
      }
    }
    if (bitIndex < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden payload is incomplete.',
      );
    }
    return output;
  }

  int _bitAt(Uint8List bytes, int bitIndex) {
    return (bytes[bitIndex >> 3] >> (7 - (bitIndex & 7))) & 1;
  }

  Uint8List _xorWithSha256Stream(
    Uint8List input,
    Uint8List key,
    Uint8List nonce,
  ) {
    final output = Uint8List(input.length);
    var offset = 0;
    var counter = 0;
    while (offset < input.length) {
      final streamBlock = sha256.convert(<int>[
        ...key,
        ...nonce,
        ..._uint64Bytes(counter),
      ]).bytes;
      for (var i = 0; i < streamBlock.length && offset < input.length; i += 1) {
        output[offset] = input[offset] ^ streamBlock[i];
        offset += 1;
      }
      counter += 1;
    }
    return output;
  }

  Uint8List _rc4(Uint8List input, Uint8List key) {
    final s = List<int>.generate(256, (index) => index);
    var j = 0;
    for (var i = 0; i < 256; i += 1) {
      j = (j + s[i] + key[i % key.length]) & 255;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
    }
    var i = 0;
    j = 0;
    final output = Uint8List(input.length);
    for (var k = 0; k < input.length; k += 1) {
      i = (i + 1) & 255;
      j = (j + s[i]) & 255;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
      output[k] = input[k] ^ s[(s[i] + s[j]) & 255];
    }
    return output;
  }

  ToolboxCryptoDecryptResult _runCryptoDecrypt({
    required Uint8List envelopeBytes,
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    try {
      return _cryptoService.decryptBytes(
        envelopeBytes: envelopeBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    } on ToolboxCryptoException catch (error) {
      throw ToolboxSteganographyException(error.message);
    }
  }

  Uint8List _legacyDeriveKey(
    String passphrase,
    Uint8List nonce,
    String purpose,
  ) {
    var state = Uint8List.fromList(
      sha256.convert(<int>[
        ...utf8.encode('vocabulary_sleep_steganography_v1'),
        0,
        ...utf8.encode(purpose),
        0,
        ...nonce,
        0,
        ...utf8.encode(passphrase),
      ]).bytes,
    );
    for (var round = 0; round < 4096; round += 1) {
      state = Uint8List.fromList(
        sha256.convert(<int>[
          ...state,
          ...nonce,
          round & 255,
          (round >> 8) & 255,
        ]).bytes,
      );
    }
    return state;
  }

  String _legacyHmacHex({
    required String passphrase,
    required Uint8List nonce,
    required String cipherId,
    required Uint8List cipherBytes,
  }) {
    final key = _legacyDeriveKey(passphrase, nonce, 'mac-$cipherId');
    final digest = Hmac(
      sha256,
      key,
    ).convert(<int>[...utf8.encode(cipherId), 0, ...nonce, 0, ...cipherBytes]);
    return _hexDigest(digest.bytes);
  }

  ToolboxCryptoAlgorithm _legacyAlgorithmFromId(String id) {
    return switch (id) {
      'none' => ToolboxCryptoAlgorithm.none,
      'sha256_stream' => ToolboxCryptoAlgorithm.sha256Stream,
      'rc4_legacy' => ToolboxCryptoAlgorithm.rc4Legacy,
      _ => throw const ToolboxSteganographyException(
        'Unsupported encryption algorithm.',
      ),
    };
  }

  Uint8List _uint32Bytes(int value) {
    if (value < 0 || value > 0xffffffff) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    return Uint8List.fromList(<int>[
      (value >> 24) & 255,
      (value >> 16) & 255,
      (value >> 8) & 255,
      value & 255,
    ]);
  }

  Uint8List _uint64Bytes(int value) {
    return Uint8List.fromList(
      List<int>.generate(8, (index) => (value >> ((7 - index) * 8)) & 255),
    );
  }

  int _readUint32(List<int> bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      throw const ToolboxSteganographyException('Payload length is missing.');
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  bool _startsWith(List<int> bytes, List<int> prefix) {
    return bytes.length >= prefix.length && _rangeEquals(bytes, 0, prefix);
  }

  bool _rangeEquals(List<int> bytes, int offset, List<int> expected) {
    if (offset < 0 || offset + expected.length > bytes.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i += 1) {
      if (bytes[offset + i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  bool _constantTimeEquals(String a, String b) {
    final left = a.codeUnits;
    final right = b.codeUnits;
    var diff = left.length ^ right.length;
    final maxLength = math.max(left.length, right.length);
    for (var i = 0; i < maxLength; i += 1) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      diff |= l ^ r;
    }
    return diff == 0;
  }

  String _hexDigest(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  String _previewBase64(Uint8List bytes) {
    final text = base64Encode(bytes);
    if (text.length <= 96) {
      return text;
    }
    return '${text.substring(0, 96)}...';
  }

  String _carrierDetailForReveal(
    ToolboxSteganographyMediaKind mediaKind,
    Uint8List carrierBytes,
  ) {
    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image =>
        'image ${_formatBytes(carrierBytes.length)}',
      ToolboxSteganographyMediaKind.audio =>
        'audio ${_formatBytes(carrierBytes.length)}',
      ToolboxSteganographyMediaKind.video =>
        'video ${_formatBytes(carrierBytes.length)}',
    };
  }

  String? _cleanExtension(String? extension) {
    final value = extension?.replaceFirst('.', '').trim().toLowerCase();
    if (value == null || value.isEmpty || value.length > 8) {
      return null;
    }
    return value.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}

class _EnvelopeBuildResult {
  const _EnvelopeBuildResult({
    required this.jsonBytes,
    required this.cipherPreview,
  });

  final Uint8List jsonBytes;
  final String cipherPreview;
}

class _EnvelopeParseResult {
  const _EnvelopeParseResult({
    required this.text,
    required this.encryption,
    required this.strength,
    required this.cipherPreview,
  });

  final String text;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
}

class _FileEnvelopeParseResult {
  const _FileEnvelopeParseResult({
    required this.bytes,
    required this.fileName,
    required this.mediaType,
    required this.encryption,
    required this.strength,
    required this.cipherPreview,
  });

  final Uint8List bytes;
  final String? fileName;
  final String? mediaType;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
}

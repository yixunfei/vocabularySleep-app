import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

enum ToolboxCryptoHmacAlgorithm { sha1, sha256, sha512 }

extension ToolboxCryptoHmacAlgorithmInfo on ToolboxCryptoHmacAlgorithm {
  String get id {
    return switch (this) {
      ToolboxCryptoHmacAlgorithm.sha1 => 'sha1',
      ToolboxCryptoHmacAlgorithm.sha256 => 'sha256',
      ToolboxCryptoHmacAlgorithm.sha512 => 'sha512',
    };
  }
}

enum ToolboxCryptoPasswordMode { password, passphrase }

enum ToolboxCryptoOtpAlgorithm { sha1, sha256, sha512 }

extension ToolboxCryptoOtpAlgorithmInfo on ToolboxCryptoOtpAlgorithm {
  String get id {
    return switch (this) {
      ToolboxCryptoOtpAlgorithm.sha1 => 'sha1',
      ToolboxCryptoOtpAlgorithm.sha256 => 'sha256',
      ToolboxCryptoOtpAlgorithm.sha512 => 'sha512',
    };
  }
}

class ToolboxCryptoExtraException implements Exception {
  const ToolboxCryptoExtraException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolboxCryptoHmacResult {
  const ToolboxCryptoHmacResult({
    required this.algorithm,
    required this.hex,
    required this.base64,
    required this.inputBytes,
    required this.keyBytes,
  });

  final ToolboxCryptoHmacAlgorithm algorithm;
  final String hex;
  final String base64;
  final int inputBytes;
  final int keyBytes;
}

class ToolboxCryptoPasswordResult {
  const ToolboxCryptoPasswordResult({
    required this.mode,
    required this.value,
    required this.entropyBits,
    required this.symbolSpace,
  });

  final ToolboxCryptoPasswordMode mode;
  final String value;
  final double entropyBits;
  final int symbolSpace;
}

class ToolboxCryptoOtpResult {
  const ToolboxCryptoOtpResult({
    required this.algorithm,
    required this.code,
    required this.counter,
    required this.digits,
    this.secondsRemaining,
  });

  final ToolboxCryptoOtpAlgorithm algorithm;
  final String code;
  final int counter;
  final int digits;
  final int? secondsRemaining;
}

class ToolboxCryptoShamirShare {
  const ToolboxCryptoShamirShare({
    required this.threshold,
    required this.index,
    required this.bytes,
    required this.text,
    required this.fingerprint,
  });

  final int threshold;
  final int index;
  final Uint8List bytes;
  final String text;
  final String fingerprint;
}

class ToolboxCryptoShamirSplitResult {
  const ToolboxCryptoShamirSplitResult({
    required this.threshold,
    required this.shareCount,
    required this.secretBytes,
    required this.shares,
  });

  final int threshold;
  final int shareCount;
  final int secretBytes;
  final List<ToolboxCryptoShamirShare> shares;
}

class ToolboxCryptoShamirRecoverResult {
  const ToolboxCryptoShamirRecoverResult({
    required this.threshold,
    required this.usedShares,
    required this.secretBytes,
  });

  final int threshold;
  final int usedShares;
  final Uint8List secretBytes;

  String? get utf8Text {
    try {
      return utf8.decode(secretBytes);
    } on FormatException {
      return null;
    }
  }

  String get base64 => base64Encode(secretBytes);
}

class ToolboxCryptoSaltedPasswordDefinition {
  const ToolboxCryptoSaltedPasswordDefinition({
    required this.text,
    required this.salt,
    required this.iterations,
    required this.derivedBytes,
    required this.fingerprint,
  });

  final String text;
  final String salt;
  final int iterations;
  final Uint8List derivedBytes;
  final String fingerprint;
}

class ToolboxCryptoExtraService {
  static const int maxHmacInputBytes = 8 * 1024 * 1024;
  static const int maxHmacKeyBytes = 64 * 1024;
  static const int maxShamirSecretBytes = 64 * 1024;
  static const int maxPasswordBatchCount = 50;
  static const int defaultSaltedPasswordIterations = 60000;
  static const int minSaltedPasswordIterations = 10000;
  static const int maxSaltedPasswordIterations = 200000;
  static const String defaultPasswordExcludedCharacters = '0Ool1I|';
  static const int minOtpDigits = 6;
  static const int maxOtpDigits = 8;
  static const int minOtpPeriodSeconds = 10;
  static const int maxOtpPeriodSeconds = 300;
  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const String _shamirPrefix = 'vss1';
  static const String _saltedPasswordPrefix = 'vspwd1';
  static final math.Random _secureRandom = math.Random.secure();

  static String generateSaltText({int bytes = 16, math.Random? random}) {
    final normalizedBytes = bytes.clamp(8, 64).toInt();
    final rng = random ?? _secureRandom;
    final saltBytes = Uint8List.fromList(
      List<int>.generate(normalizedBytes, (_) => rng.nextInt(256)),
    );
    return base64UrlEncode(saltBytes).replaceAll('=', '');
  }

  ToolboxCryptoHmacResult calculateHmac({
    required Uint8List inputBytes,
    required String secret,
    required ToolboxCryptoHmacAlgorithm algorithm,
  }) {
    if (inputBytes.isEmpty) {
      throw const ToolboxCryptoExtraException('Input bytes are empty.');
    }
    if (inputBytes.length > maxHmacInputBytes) {
      throw const ToolboxCryptoExtraException('Input is too large for HMAC.');
    }
    final keyBytes = Uint8List.fromList(utf8.encode(secret));
    if (keyBytes.isEmpty) {
      throw const ToolboxCryptoExtraException('HMAC key is required.');
    }
    if (keyBytes.length > maxHmacKeyBytes) {
      throw const ToolboxCryptoExtraException('HMAC key is too large.');
    }
    final digest = _hmacBytes(
      algorithm: algorithm,
      key: keyBytes,
      bytes: inputBytes,
    );
    return ToolboxCryptoHmacResult(
      algorithm: algorithm,
      hex: _hexDigest(digest),
      base64: base64Encode(digest),
      inputBytes: inputBytes.length,
      keyBytes: keyBytes.length,
    );
  }

  bool? hmacDigestMatches({
    required String expected,
    required ToolboxCryptoHmacResult result,
  }) {
    final normalizedExpected = _compactDigest(expected);
    if (normalizedExpected.isEmpty) {
      return null;
    }
    final expectedBytes = _decodeDigest(
      normalizedExpected,
      byteLength: _digestLength(result.algorithm),
    );
    if (expectedBytes == null) {
      return false;
    }
    final actual = _hexToBytes(result.hex);
    return actual != null && _constantTimeBytesEquals(expectedBytes, actual);
  }

  ToolboxCryptoPasswordResult generatePassword({
    required int length,
    required bool includeLowercase,
    required bool includeUppercase,
    required bool includeDigits,
    required bool includeSymbols,
    bool avoidAmbiguous = false,
    String customCharacterSet = '',
    String excludedCharacters = '',
    math.Random? random,
  }) {
    final normalizedLength = length.clamp(8, 128).toInt();
    final excluded = <String>{
      if (avoidAmbiguous)
        ..._passwordCharacters(defaultPasswordExcludedCharacters),
      ..._passwordCharacters(excludedCharacters),
    };
    final classes =
        <String>[
              if (includeLowercase) 'abcdefghijklmnopqrstuvwxyz',
              if (includeUppercase) 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
              if (includeDigits) '0123456789',
              if (includeSymbols) r'!@#$%^&*()-_=+[]{};:,.?/|~',
              if (customCharacterSet.isNotEmpty) customCharacterSet,
            ]
            .map((value) => _normalizePasswordClass(value, excluded))
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
    if (classes.isEmpty) {
      throw const ToolboxCryptoExtraException(
        'At least one character set is required.',
      );
    }
    final rng = random ?? _secureRandom;
    final pool = _mergePasswordPool(classes);
    final chars = <String>[
      for (final set in classes) set[rng.nextInt(set.length)],
    ];
    while (chars.length < normalizedLength) {
      chars.add(pool[rng.nextInt(pool.length)]);
    }
    _shuffle(chars, rng);
    final entropyBits = normalizedLength * _log2(pool.length);
    return ToolboxCryptoPasswordResult(
      mode: ToolboxCryptoPasswordMode.password,
      value: chars.join(),
      entropyBits: entropyBits,
      symbolSpace: pool.length,
    );
  }

  List<ToolboxCryptoPasswordResult> generatePasswords({
    required int count,
    required int length,
    required bool includeLowercase,
    required bool includeUppercase,
    required bool includeDigits,
    required bool includeSymbols,
    bool avoidAmbiguous = false,
    String customCharacterSet = '',
    String excludedCharacters = '',
    math.Random? random,
  }) {
    final normalizedCount = count.clamp(1, maxPasswordBatchCount).toInt();
    final rng = random ?? _secureRandom;
    return List<ToolboxCryptoPasswordResult>.generate(
      normalizedCount,
      (_) => generatePassword(
        length: length,
        includeLowercase: includeLowercase,
        includeUppercase: includeUppercase,
        includeDigits: includeDigits,
        includeSymbols: includeSymbols,
        avoidAmbiguous: avoidAmbiguous,
        customCharacterSet: customCharacterSet,
        excludedCharacters: excludedCharacters,
        random: rng,
      ),
      growable: false,
    );
  }

  ToolboxCryptoSaltedPasswordDefinition defineSaltedPassword({
    required String password,
    required String salt,
    int iterations = defaultSaltedPasswordIterations,
  }) {
    if (password.isEmpty) {
      throw const ToolboxCryptoExtraException('Password is required.');
    }
    if (salt.isEmpty) {
      throw const ToolboxCryptoExtraException('Salt is required.');
    }
    final normalizedIterations = iterations
        .clamp(minSaltedPasswordIterations, maxSaltedPasswordIterations)
        .toInt();
    final saltBytes = Uint8List.fromList(utf8.encode(salt));
    final derivedBytes = _pbkdf2HmacSha256(
      passwordBytes: utf8.encode(password),
      saltBytes: saltBytes,
      iterations: normalizedIterations,
      outputLength: 32,
    );
    final saltSegment = _base64UrlNoPadding(saltBytes);
    final materialSegment = _base64UrlNoPadding(derivedBytes);
    final fingerprint = _hexDigest(
      crypto.sha256.convert(<int>[...saltBytes, ...derivedBytes]).bytes,
    ).substring(0, 12);
    return ToolboxCryptoSaltedPasswordDefinition(
      text:
          '$_saltedPasswordPrefix:$normalizedIterations:$saltSegment:$materialSegment:$fingerprint',
      salt: salt,
      iterations: normalizedIterations,
      derivedBytes: derivedBytes,
      fingerprint: fingerprint,
    );
  }

  ToolboxCryptoPasswordResult generatePassphrase({
    required int wordCount,
    required String separator,
    required bool capitalizeWords,
    required bool appendNumber,
    math.Random? random,
  }) {
    final normalizedCount = wordCount.clamp(3, 12);
    final rng = random ?? _secureRandom;
    final words = <String>[];
    for (var index = 0; index < normalizedCount; index += 1) {
      var word = _passphraseWords[rng.nextInt(_passphraseWords.length)];
      if (capitalizeWords) {
        word = '${word.substring(0, 1).toUpperCase()}${word.substring(1)}';
      }
      words.add(word);
    }
    var value = words.join(separator);
    var entropyBits = normalizedCount * _log2(_passphraseWords.length);
    if (appendNumber) {
      value = '$value${rng.nextInt(100).toString().padLeft(2, '0')}';
      entropyBits += _log2(100);
    }
    return ToolboxCryptoPasswordResult(
      mode: ToolboxCryptoPasswordMode.passphrase,
      value: value,
      entropyBits: entropyBits,
      symbolSpace: _passphraseWords.length,
    );
  }

  String generateOtpSecret({int bytes = 20, math.Random? random}) {
    final normalizedBytes = bytes.clamp(10, 64);
    final rng = random ?? _secureRandom;
    return encodeBase32(
      Uint8List.fromList(
        List<int>.generate(normalizedBytes, (_) => rng.nextInt(256)),
      ),
    );
  }

  String encodeBase32(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ToolboxCryptoExtraException('OTP secret is empty.');
    }
    final buffer = StringBuffer();
    var bitBuffer = 0;
    var bitCount = 0;
    for (final byte in bytes) {
      bitBuffer = (bitBuffer << 8) | (byte & 0xff);
      bitCount += 8;
      while (bitCount >= 5) {
        final index = (bitBuffer >> (bitCount - 5)) & 31;
        buffer.write(_base32Alphabet[index]);
        bitCount -= 5;
      }
    }
    if (bitCount > 0) {
      final index = (bitBuffer << (5 - bitCount)) & 31;
      buffer.write(_base32Alphabet[index]);
    }
    return buffer.toString();
  }

  Uint8List decodeBase32Secret(String secret) {
    final normalized = secret.toUpperCase().replaceAll(RegExp(r'[\s\-=]'), '');
    if (normalized.isEmpty) {
      throw const ToolboxCryptoExtraException('OTP secret is required.');
    }
    var bitBuffer = 0;
    var bitCount = 0;
    final output = <int>[];
    for (final codeUnit in normalized.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final value = _base32Alphabet.indexOf(char);
      if (value < 0) {
        throw const ToolboxCryptoExtraException('OTP secret is not Base32.');
      }
      bitBuffer = (bitBuffer << 5) | value;
      bitCount += 5;
      while (bitCount >= 8) {
        output.add((bitBuffer >> (bitCount - 8)) & 0xff);
        bitCount -= 8;
      }
    }
    if (output.isEmpty) {
      throw const ToolboxCryptoExtraException('OTP secret is empty.');
    }
    return Uint8List.fromList(output);
  }

  ToolboxCryptoOtpResult hotp({
    required String secret,
    required int counter,
    required int digits,
    required ToolboxCryptoOtpAlgorithm algorithm,
  }) {
    _validateOtpDigits(digits);
    if (counter < 0) {
      throw const ToolboxCryptoExtraException('HOTP counter must be positive.');
    }
    final secretBytes = decodeBase32Secret(secret);
    final code = _otpCode(
      secretBytes: secretBytes,
      counter: counter,
      digits: digits,
      algorithm: algorithm,
    );
    return ToolboxCryptoOtpResult(
      algorithm: algorithm,
      code: code,
      counter: counter,
      digits: digits,
    );
  }

  ToolboxCryptoOtpResult totp({
    required String secret,
    required DateTime timestamp,
    required int periodSeconds,
    required int digits,
    required ToolboxCryptoOtpAlgorithm algorithm,
  }) {
    _validateOtpDigits(digits);
    if (periodSeconds < minOtpPeriodSeconds ||
        periodSeconds > maxOtpPeriodSeconds) {
      throw const ToolboxCryptoExtraException('TOTP period is out of range.');
    }
    final unixSeconds = timestamp.toUtc().millisecondsSinceEpoch ~/ 1000;
    final counter = unixSeconds ~/ periodSeconds;
    final result = hotp(
      secret: secret,
      counter: counter,
      digits: digits,
      algorithm: algorithm,
    );
    return ToolboxCryptoOtpResult(
      algorithm: algorithm,
      code: result.code,
      counter: counter,
      digits: digits,
      secondsRemaining: periodSeconds - (unixSeconds % periodSeconds),
    );
  }

  ToolboxCryptoShamirSplitResult splitShamirSecret({
    required Uint8List secretBytes,
    required int threshold,
    required int shareCount,
    math.Random? random,
  }) {
    if (secretBytes.isEmpty) {
      throw const ToolboxCryptoExtraException('Secret is empty.');
    }
    if (secretBytes.length > maxShamirSecretBytes) {
      throw const ToolboxCryptoExtraException('Secret is too large.');
    }
    if (threshold < 2 || threshold > 10) {
      throw const ToolboxCryptoExtraException(
        'Threshold must be between 2 and 10.',
      );
    }
    if (shareCount < threshold || shareCount > 16) {
      throw const ToolboxCryptoExtraException(
        'Share count must be between threshold and 16.',
      );
    }
    final rng = random ?? _secureRandom;
    final shareBytes = List<Uint8List>.generate(
      shareCount,
      (_) => Uint8List(secretBytes.length),
    );
    for (var byteIndex = 0; byteIndex < secretBytes.length; byteIndex += 1) {
      final coefficients = <int>[
        secretBytes[byteIndex],
        for (var index = 1; index < threshold; index += 1) rng.nextInt(256),
      ];
      for (var shareIndex = 0; shareIndex < shareCount; shareIndex += 1) {
        final x = shareIndex + 1;
        shareBytes[shareIndex][byteIndex] = _evaluateShamirPolynomial(
          coefficients,
          x,
        );
      }
    }
    final shares = <ToolboxCryptoShamirShare>[
      for (var index = 0; index < shareCount; index += 1)
        _encodeShamirShare(
          threshold: threshold,
          index: index + 1,
          bytes: shareBytes[index],
        ),
    ];
    return ToolboxCryptoShamirSplitResult(
      threshold: threshold,
      shareCount: shareCount,
      secretBytes: secretBytes.length,
      shares: shares,
    );
  }

  ToolboxCryptoShamirRecoverResult recoverShamirSecret({
    required List<String> shareTexts,
  }) {
    final parsed = shareTexts
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(_parseShamirShare)
        .toList(growable: false);
    if (parsed.isEmpty) {
      throw const ToolboxCryptoExtraException('No shares were provided.');
    }
    final threshold = parsed.first.threshold;
    final byteLength = parsed.first.bytes.length;
    final byIndex = <int, ToolboxCryptoShamirShare>{};
    for (final share in parsed) {
      if (share.threshold != threshold) {
        throw const ToolboxCryptoExtraException('Share thresholds differ.');
      }
      if (share.bytes.length != byteLength) {
        throw const ToolboxCryptoExtraException('Share lengths differ.');
      }
      if (byIndex.containsKey(share.index)) {
        throw const ToolboxCryptoExtraException('Duplicate share index.');
      }
      byIndex[share.index] = share;
    }
    if (byIndex.length < threshold) {
      throw const ToolboxCryptoExtraException(
        'Not enough shares for recovery.',
      );
    }
    final selected = byIndex.values.take(threshold).toList(growable: false);
    final output = Uint8List(byteLength);
    for (var byteIndex = 0; byteIndex < byteLength; byteIndex += 1) {
      var value = 0;
      for (var i = 0; i < threshold; i += 1) {
        final xi = selected[i].index;
        final yi = selected[i].bytes[byteIndex];
        var basis = 1;
        for (var j = 0; j < threshold; j += 1) {
          if (i == j) {
            continue;
          }
          final xj = selected[j].index;
          basis = _gfMul(basis, _gfDiv(xj, xi ^ xj));
        }
        value ^= _gfMul(yi, basis);
      }
      output[byteIndex] = value;
    }
    return ToolboxCryptoShamirRecoverResult(
      threshold: threshold,
      usedShares: threshold,
      secretBytes: output,
    );
  }

  Uint8List _hmacBytes({
    required ToolboxCryptoHmacAlgorithm algorithm,
    required Uint8List key,
    required List<int> bytes,
  }) {
    final digest = switch (algorithm) {
      ToolboxCryptoHmacAlgorithm.sha1 => crypto.sha1,
      ToolboxCryptoHmacAlgorithm.sha256 => crypto.sha256,
      ToolboxCryptoHmacAlgorithm.sha512 => crypto.sha512,
    };
    return Uint8List.fromList(crypto.Hmac(digest, key).convert(bytes).bytes);
  }

  String _otpCode({
    required Uint8List secretBytes,
    required int counter,
    required int digits,
    required ToolboxCryptoOtpAlgorithm algorithm,
  }) {
    final digest = _otpHmacBytes(
      algorithm: algorithm,
      key: secretBytes,
      bytes: _uint64Bytes(counter),
    );
    final offset = digest.last & 0x0f;
    final binary =
        ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);
    final modulo = math.pow(10, digits).toInt();
    return (binary % modulo).toString().padLeft(digits, '0');
  }

  Uint8List _otpHmacBytes({
    required ToolboxCryptoOtpAlgorithm algorithm,
    required Uint8List key,
    required Uint8List bytes,
  }) {
    final digest = switch (algorithm) {
      ToolboxCryptoOtpAlgorithm.sha1 => crypto.sha1,
      ToolboxCryptoOtpAlgorithm.sha256 => crypto.sha256,
      ToolboxCryptoOtpAlgorithm.sha512 => crypto.sha512,
    };
    return Uint8List.fromList(crypto.Hmac(digest, key).convert(bytes).bytes);
  }

  void _validateOtpDigits(int digits) {
    if (digits < minOtpDigits || digits > maxOtpDigits) {
      throw const ToolboxCryptoExtraException('OTP digits must be 6 to 8.');
    }
  }

  Uint8List _uint64Bytes(int value) {
    var active = value;
    final bytes = Uint8List(8);
    for (var index = 7; index >= 0; index -= 1) {
      bytes[index] = active & 0xff;
      active = active >> 8;
    }
    return bytes;
  }

  ToolboxCryptoShamirShare _encodeShamirShare({
    required int threshold,
    required int index,
    required Uint8List bytes,
  }) {
    final payload = base64UrlEncode(bytes);
    final fingerprint = _shamirFingerprint(
      threshold: threshold,
      index: index,
      payload: payload,
    );
    return ToolboxCryptoShamirShare(
      threshold: threshold,
      index: index,
      bytes: Uint8List.fromList(bytes),
      text: '$_shamirPrefix:$threshold:$index:$payload:$fingerprint',
      fingerprint: fingerprint,
    );
  }

  ToolboxCryptoShamirShare _parseShamirShare(String text) {
    final parts = text.trim().split(':');
    if (parts.length != 5 || parts.first != _shamirPrefix) {
      throw const ToolboxCryptoExtraException('Share format is invalid.');
    }
    final threshold = int.tryParse(parts[1]);
    final index = int.tryParse(parts[2]);
    final payload = parts[3];
    final fingerprint = parts[4].toLowerCase();
    if (threshold == null || threshold < 2 || threshold > 10) {
      throw const ToolboxCryptoExtraException('Share threshold is invalid.');
    }
    if (index == null || index < 1 || index > 255) {
      throw const ToolboxCryptoExtraException('Share index is invalid.');
    }
    final expected = _shamirFingerprint(
      threshold: threshold,
      index: index,
      payload: payload,
    );
    if (!_constantTimeAsciiEquals(fingerprint, expected)) {
      throw const ToolboxCryptoExtraException('Share checksum is invalid.');
    }
    try {
      final bytes = Uint8List.fromList(base64Url.decode(payload));
      if (bytes.isEmpty || bytes.length > maxShamirSecretBytes) {
        throw const ToolboxCryptoExtraException('Share payload is invalid.');
      }
      return ToolboxCryptoShamirShare(
        threshold: threshold,
        index: index,
        bytes: bytes,
        text: text.trim(),
        fingerprint: fingerprint,
      );
    } on FormatException {
      throw const ToolboxCryptoExtraException('Share payload is invalid.');
    }
  }

  String _shamirFingerprint({
    required int threshold,
    required int index,
    required String payload,
  }) {
    final digest = crypto.sha256.convert(
      utf8.encode('$_shamirPrefix:$threshold:$index:$payload'),
    );
    return _hexDigest(digest.bytes).substring(0, 12);
  }

  int _evaluateShamirPolynomial(List<int> coefficients, int x) {
    var result = 0;
    for (var index = coefficients.length - 1; index >= 0; index -= 1) {
      result = _gfMul(result, x) ^ coefficients[index];
    }
    return result;
  }

  int _gfMul(int a, int b) {
    var left = a & 0xff;
    var right = b & 0xff;
    var product = 0;
    while (right > 0) {
      if ((right & 1) != 0) {
        product ^= left;
      }
      final carry = left & 0x80;
      left = (left << 1) & 0xff;
      if (carry != 0) {
        left ^= 0x1b;
      }
      right >>= 1;
    }
    return product & 0xff;
  }

  int _gfPow(int value, int exponent) {
    var result = 1;
    var base = value & 0xff;
    var active = exponent;
    while (active > 0) {
      if ((active & 1) != 0) {
        result = _gfMul(result, base);
      }
      base = _gfMul(base, base);
      active >>= 1;
    }
    return result;
  }

  int _gfDiv(int numerator, int denominator) {
    if (denominator == 0) {
      throw const ToolboxCryptoExtraException('Share interpolation failed.');
    }
    if (numerator == 0) {
      return 0;
    }
    return _gfMul(numerator, _gfPow(denominator, 254));
  }

  int _digestLength(ToolboxCryptoHmacAlgorithm algorithm) {
    return switch (algorithm) {
      ToolboxCryptoHmacAlgorithm.sha1 => 20,
      ToolboxCryptoHmacAlgorithm.sha256 => 32,
      ToolboxCryptoHmacAlgorithm.sha512 => 64,
    };
  }

  String _compactDigest(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  Uint8List? _decodeDigest(String value, {required int byteLength}) {
    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(value) &&
        value.length == byteLength * 2) {
      return _hexToBytes(value);
    }
    final expectedBase64Length = ((byteLength + 2) ~/ 3) * 4;
    if (value.length != expectedBase64Length) {
      return null;
    }
    try {
      final decoded = Uint8List.fromList(base64Decode(value));
      return decoded.length == byteLength ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Uint8List? _hexToBytes(String value) {
    if (value.length.isOdd) {
      return null;
    }
    final output = Uint8List(value.length ~/ 2);
    for (var index = 0; index < value.length; index += 2) {
      final byte = int.tryParse(value.substring(index, index + 2), radix: 16);
      if (byte == null) {
        return null;
      }
      output[index ~/ 2] = byte;
    }
    return output;
  }

  String _hexDigest(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  bool _constantTimeBytesEquals(List<int> left, List<int> right) {
    var diff = left.length ^ right.length;
    final maxLength = math.max(left.length, right.length);
    for (var i = 0; i < maxLength; i += 1) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      diff |= l ^ r;
    }
    return diff == 0;
  }

  bool _constantTimeAsciiEquals(String left, String right) {
    return _constantTimeBytesEquals(ascii.encode(left), ascii.encode(right));
  }

  Uint8List _pbkdf2HmacSha256({
    required List<int> passwordBytes,
    required List<int> saltBytes,
    required int iterations,
    required int outputLength,
  }) {
    final output = <int>[];
    var blockIndex = 1;
    while (output.length < outputLength) {
      final blockSeed = <int>[
        ...saltBytes,
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ];
      var block = _hmacSha256(passwordBytes, blockSeed);
      final mixed = Uint8List.fromList(block);
      for (var index = 1; index < iterations; index += 1) {
        block = _hmacSha256(passwordBytes, block);
        for (var byteIndex = 0; byteIndex < mixed.length; byteIndex += 1) {
          mixed[byteIndex] ^= block[byteIndex];
        }
      }
      output.addAll(mixed);
      blockIndex += 1;
    }
    return Uint8List.fromList(
      output.take(outputLength).toList(growable: false),
    );
  }

  Uint8List _hmacSha256(List<int> key, List<int> bytes) {
    return Uint8List.fromList(
      crypto.Hmac(crypto.sha256, key).convert(bytes).bytes,
    );
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  List<String> _passwordCharacters(String value) {
    return value.runes.map(String.fromCharCode).toList(growable: false);
  }

  List<String> _normalizePasswordClass(String value, Set<String> excluded) {
    final seen = <String>{};
    final output = <String>[];
    for (final char in _passwordCharacters(value)) {
      if (excluded.contains(char) || !seen.add(char)) {
        continue;
      }
      output.add(char);
    }
    return output;
  }

  List<String> _mergePasswordPool(List<List<String>> classes) {
    final seen = <String>{};
    final output = <String>[];
    for (final set in classes) {
      for (final char in set) {
        if (seen.add(char)) {
          output.add(char);
        }
      }
    }
    if (output.isEmpty) {
      throw const ToolboxCryptoExtraException(
        'Character sets are empty after filtering.',
      );
    }
    return output;
  }

  void _shuffle(List<String> values, math.Random random) {
    for (var index = values.length - 1; index > 0; index -= 1) {
      final swapIndex = random.nextInt(index + 1);
      final temp = values[index];
      values[index] = values[swapIndex];
      values[swapIndex] = temp;
    }
  }

  double _log2(num value) {
    return math.log(value) / math.ln2;
  }
}

const List<String> _passphraseWords = <String>[
  'anchor',
  'apricot',
  'atlas',
  'aurora',
  'bamboo',
  'beacon',
  'binary',
  'breeze',
  'canvas',
  'cedar',
  'cinder',
  'cipher',
  'cobalt',
  'comet',
  'copper',
  'coral',
  'delta',
  'ember',
  'fable',
  'falcon',
  'fiber',
  'field',
  'fjord',
  'forest',
  'galaxy',
  'garden',
  'glacier',
  'granite',
  'harbor',
  'hazel',
  'helium',
  'horizon',
  'indigo',
  'island',
  'jasmine',
  'kernel',
  'lantern',
  'lattice',
  'linen',
  'lotus',
  'magnet',
  'maple',
  'matrix',
  'meadow',
  'meteor',
  'nebula',
  'nectar',
  'nickel',
  'onyx',
  'orbit',
  'orchid',
  'pebble',
  'plasma',
  'prairie',
  'quartz',
  'radar',
  'ripple',
  'saffron',
  'silver',
  'solace',
  'summit',
  'tensor',
  'timber',
  'topaz',
  'vector',
  'velvet',
  'violet',
  'willow',
  'zenith',
];

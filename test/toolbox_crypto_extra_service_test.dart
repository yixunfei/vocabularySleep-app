import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_crypto_extra_service.dart';

void main() {
  group('ToolboxCryptoExtraService', () {
    final service = ToolboxCryptoExtraService();

    test('calculates and verifies HMAC-SHA256 known vector', () {
      final result = service.calculateHmac(
        inputBytes: Uint8List.fromList(
          utf8.encode('what do ya want for nothing?'),
        ),
        secret: 'Jefe',
        algorithm: ToolboxCryptoHmacAlgorithm.sha256,
      );

      expect(
        result.hex,
        '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
      );
      expect(
        service.hmacDigestMatches(
          expected: result.hex.toUpperCase(),
          result: result,
        ),
        isTrue,
      );
      expect(
        service.hmacDigestMatches(expected: result.base64, result: result),
        isTrue,
      );
      expect(
        service.hmacDigestMatches(expected: 'not-a-digest', result: result),
        isFalse,
      );
      expect(
        service.hmacDigestMatches(expected: '   ', result: result),
        isNull,
      );
    });

    test('generates password with required character classes', () {
      final result = service.generatePassword(
        length: 24,
        includeLowercase: true,
        includeUppercase: true,
        includeDigits: true,
        includeSymbols: true,
        avoidAmbiguous: true,
        random: math.Random(7),
      );

      expect(result.value.length, 24);
      expect(result.value, matches(RegExp(r'[a-z]')));
      expect(result.value, matches(RegExp(r'[A-Z]')));
      expect(result.value, matches(RegExp(r'[0-9]')));
      expect(
        result.value,
        matches(RegExp(r'[!@#\$%\^&*()\-_=+\[\]{};:,.?/|~]')),
      );
      expect(result.value.contains(RegExp(r'[0Ool1I|]')), isFalse);
      expect(result.entropyBits, greaterThan(100));
    });

    test('generates password from custom character set after exclusions', () {
      final result = service.generatePassword(
        length: 12,
        includeLowercase: false,
        includeUppercase: false,
        includeDigits: false,
        includeSymbols: false,
        customCharacterSet: 'ABCXYZ',
        excludedCharacters: 'XYZ',
        random: math.Random(11),
      );

      expect(result.value.length, 12);
      expect(result.value, matches(RegExp(r'^[ABC]+$')));
      expect(result.symbolSpace, 3);
    });

    test('generates password batches with shared constraints', () {
      final results = service.generatePasswords(
        count: 4,
        length: 16,
        includeLowercase: true,
        includeUppercase: false,
        includeDigits: true,
        includeSymbols: false,
        excludedCharacters:
            ToolboxCryptoExtraService.defaultPasswordExcludedCharacters,
        random: math.Random(17),
      );

      expect(results, hasLength(4));
      for (final result in results) {
        expect(result.value.length, 16);
        expect(result.value, matches(RegExp(r'[a-z]')));
        expect(result.value, matches(RegExp(r'[0-9]')));
        expect(result.value.contains(RegExp(r'[0Ool1I|]')), isFalse);
      }
    });

    test('rejects password generation when exclusions clear all sets', () {
      expect(
        () => service.generatePassword(
          length: 12,
          includeLowercase: false,
          includeUppercase: false,
          includeDigits: true,
          includeSymbols: false,
          excludedCharacters: '0123456789',
          random: math.Random(5),
        ),
        throwsA(isA<ToolboxCryptoExtraException>()),
      );
    });

    test('generates passphrase with deterministic test random', () {
      final result = service.generatePassphrase(
        wordCount: 4,
        separator: '-',
        capitalizeWords: true,
        appendNumber: true,
        random: math.Random(3),
      );

      expect(result.value.split('-'), hasLength(4));
      expect(result.value, matches(RegExp(r'\d{2}$')));
      expect(result.entropyBits, greaterThan(20));
    });

    test('defines salted password material without exposing password', () {
      final definition = service.defineSaltedPassword(
        password: 'correct horse battery staple',
        salt: 'NaCl',
        iterations: ToolboxCryptoExtraService.minSaltedPasswordIterations,
      );

      expect(definition.text, startsWith('vspwd1:10000:'));
      expect(definition.text.contains('correct horse battery staple'), isFalse);
      expect(definition.salt, 'NaCl');
      expect(definition.derivedBytes, hasLength(32));
      expect(definition.fingerprint, hasLength(12));

      final split = service.splitShamirSecret(
        secretBytes: Uint8List.fromList(utf8.encode(definition.text)),
        threshold: 2,
        shareCount: 3,
        random: math.Random(19),
      );
      final recovered = service.recoverShamirSecret(
        shareTexts: <String>[split.shares[0].text, split.shares[2].text],
      );
      expect(recovered.utf8Text, definition.text);
    });

    test('generates deterministic salt text for tests', () {
      final salt = ToolboxCryptoExtraService.generateSaltText(
        bytes: 8,
        random: math.Random(23),
      );

      expect(salt, isNotEmpty);
      expect(salt.contains('='), isFalse);
    });

    test('matches RFC 4226 HOTP vectors', () {
      final secret = service.encodeBase32(
        Uint8List.fromList(utf8.encode('12345678901234567890')),
      );

      expect(
        service
            .hotp(
              secret: secret,
              counter: 0,
              digits: 6,
              algorithm: ToolboxCryptoOtpAlgorithm.sha1,
            )
            .code,
        '755224',
      );
      expect(
        service
            .hotp(
              secret: secret,
              counter: 1,
              digits: 6,
              algorithm: ToolboxCryptoOtpAlgorithm.sha1,
            )
            .code,
        '287082',
      );
    });

    test('matches RFC 6238 TOTP vectors', () {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        59 * 1000,
        isUtc: true,
      );
      final sha1Secret = service.encodeBase32(
        Uint8List.fromList(utf8.encode('12345678901234567890')),
      );
      final sha256Secret = service.encodeBase32(
        Uint8List.fromList(utf8.encode('12345678901234567890123456789012')),
      );
      final sha512Secret = service.encodeBase32(
        Uint8List.fromList(
          utf8.encode(
            '1234567890123456789012345678901234567890123456789012345678901234',
          ),
        ),
      );

      expect(
        service
            .totp(
              secret: sha1Secret,
              timestamp: timestamp,
              periodSeconds: 30,
              digits: 8,
              algorithm: ToolboxCryptoOtpAlgorithm.sha1,
            )
            .code,
        '94287082',
      );
      expect(
        service
            .totp(
              secret: sha256Secret,
              timestamp: timestamp,
              periodSeconds: 30,
              digits: 8,
              algorithm: ToolboxCryptoOtpAlgorithm.sha256,
            )
            .code,
        '46119246',
      );
      expect(
        service
            .totp(
              secret: sha512Secret,
              timestamp: timestamp,
              periodSeconds: 30,
              digits: 8,
              algorithm: ToolboxCryptoOtpAlgorithm.sha512,
            )
            .code,
        '90693936',
      );
    });

    test('splits and recovers Shamir shares', () {
      final split = service.splitShamirSecret(
        secretBytes: Uint8List.fromList(
          utf8.encode('correct horse battery staple'),
        ),
        threshold: 3,
        shareCount: 5,
        random: math.Random(42),
      );

      expect(split.shares, hasLength(5));
      final recovered = service.recoverShamirSecret(
        shareTexts: <String>[
          split.shares[0].text,
          split.shares[2].text,
          split.shares[4].text,
        ],
      );
      expect(recovered.threshold, 3);
      expect(recovered.utf8Text, 'correct horse battery staple');
    });

    test('rejects insufficient, duplicate, and tampered Shamir shares', () {
      final split = service.splitShamirSecret(
        secretBytes: Uint8List.fromList(utf8.encode('seed phrase')),
        threshold: 3,
        shareCount: 4,
        random: math.Random(9),
      );

      expect(
        () => service.recoverShamirSecret(
          shareTexts: <String>[split.shares[0].text, split.shares[1].text],
        ),
        throwsA(isA<ToolboxCryptoExtraException>()),
      );
      expect(
        () => service.recoverShamirSecret(
          shareTexts: <String>[
            split.shares[0].text,
            split.shares[0].text,
            split.shares[1].text,
          ],
        ),
        throwsA(isA<ToolboxCryptoExtraException>()),
      );
      final tampered = split.shares[0].text;
      final replacement = tampered.endsWith('0') ? '1' : '0';
      final badChecksum =
          '${tampered.substring(0, tampered.length - 1)}$replacement';
      expect(
        () => service.recoverShamirSecret(
          shareTexts: <String>[
            badChecksum,
            split.shares[1].text,
            split.shares[2].text,
          ],
        ),
        throwsA(isA<ToolboxCryptoExtraException>()),
      );
    });
  });
}

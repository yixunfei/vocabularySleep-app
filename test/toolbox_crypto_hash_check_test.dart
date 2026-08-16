import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_crypto_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_crypto_security.dart';

void main() {
  group('hash check digest comparison', () {
    const result = ToolboxCryptoHashResult(
      algorithm: ToolboxCryptoHashAlgorithm.sha256,
      hex: 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      base64: 'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YSABWto=',
    );

    test('matches hex digests case-insensitively', () {
      expect(
        toolboxCryptoHashDigestMatchesForTesting(
          expected: result.hex.toUpperCase(),
          result: result,
        ),
        isTrue,
      );
    });

    test('matches base64 digests case-sensitively', () {
      expect(
        toolboxCryptoHashDigestMatchesForTesting(
          expected: result.base64,
          result: result,
        ),
        isTrue,
      );
      expect(
        toolboxCryptoHashDigestMatchesForTesting(
          expected: result.base64.toLowerCase(),
          result: result,
        ),
        isFalse,
      );
    });

    test('rejects expected digests with invalid format or length', () {
      expect(
        toolboxCryptoHashDigestMatchesForTesting(
          expected: '${result.hex}00',
          result: result,
        ),
        isFalse,
      );
      expect(
        toolboxCryptoHashDigestMatchesForTesting(
          expected: result.base64.substring(0, result.base64.length - 1),
          result: result,
        ),
        isFalse,
      );
      expect(
        toolboxCryptoHashDigestMatchesForTesting(
          expected: 'not-a-digest',
          result: result,
        ),
        isFalse,
      );
    });

    test(
      'ignores whitespace and leaves empty expected digest unclassified',
      () {
        expect(
          toolboxCryptoHashDigestMatchesForTesting(
            expected:
                ' ${result.hex.substring(0, 32)}\n'
                '${result.hex.substring(32)} ',
            result: result,
          ),
          isTrue,
        );
        expect(
          toolboxCryptoHashDigestMatchesForTesting(
            expected: '   ',
            result: result,
          ),
          isNull,
        );
      },
    );
  });
}

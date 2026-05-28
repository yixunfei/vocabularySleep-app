import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_short_link_service.dart';

void main() {
  group('toolbox short link service', () {
    test('normalizes URLs without scheme', () {
      final uri = ToolboxShortLinkService.normalizeUrl('example.com/a?b=1');

      expect(uri.toString(), 'https://example.com/a?b=1');
    });

    test('rejects non-http URLs', () {
      expect(
        () => ToolboxShortLinkService.normalizeUrl('javascript:alert(1)'),
        throwsFormatException,
      );
    });

    test('sanitizes custom aliases', () {
      expect(
        ToolboxShortLinkService.sanitizeAlias('  My Link @ 2026  '),
        'My-Link-2026',
      );
    });

    test('builds deterministic local alias', () {
      final uri = ToolboxShortLinkService.normalizeUrl('example.com/a');

      final first = ToolboxShortLinkService.buildLocalAlias(uri);
      final second = ToolboxShortLinkService.buildLocalAlias(uri);

      expect(first, second);
      expect(first, hasLength(9));
    });

    test('local provider returns offline short code without network', () async {
      final result = await const ToolboxShortLinkService().shorten(
        inputUrl: 'https://example.com/long',
        provider: ToolboxShortLinkProvider.localAlias,
        alias: 'demo',
      );

      expect(result.shortUrl, 'vocab-sleep://short/demo');
      expect(result.provider.usesNetwork, isFalse);
      expect(result.warning, contains('offline'));
    });
  });
}

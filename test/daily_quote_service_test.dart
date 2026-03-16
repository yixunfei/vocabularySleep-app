import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vocabulary_sleep_app/src/services/daily_quote_service.dart';

void main() {
  test('fetchQuote strips html wrappers and keeps readable text', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://v.api.aa1.cn/api/yiyan/index.php',
      );
      return http.Response(
        '<p>Stay hungry<br/>Stay foolish</p>',
        200,
        headers: <String, String>{'content-type': 'text/html; charset=utf-8'},
      );
    });

    final quote = await DailyQuoteService(client: client).fetchQuote();

    expect(quote, 'Stay hungry\nStay foolish');
  });

  test('cleanQuoteBody collapses whitespace and decodes simple entities', () {
    expect(
      DailyQuoteService.cleanQuoteBody('  Hello&nbsp;&amp;&nbsp;world  '),
      'Hello & world',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vocabulary_sleep_app/src/services/daily_quote_service.dart';

void main() {
  test('fetchQuote parses json payload and appends source', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://v.api.aa1.cn/api/yiyan/index.php?type=json',
      );
      return http.Response(
        '{"yiyan":"Stay hungry","from":"Daily"}',
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });

    final quote = await DailyQuoteService(client: client).fetchQuote();

    expect(quote, 'Stay hungry\n- Daily');
  });

  test('cleanQuoteBody collapses whitespace and decodes simple entities', () {
    expect(
      DailyQuoteService.cleanQuoteBody('  Hello&nbsp;&amp;&nbsp;world  '),
      'Hello & world',
    );
  });

  test('parseQuotePayload rejects empty quote content', () {
    expect(
      () => DailyQuoteService.parseQuotePayload('{"yiyan":"","from":"一言"}'),
      throwsFormatException,
    );
  });
}

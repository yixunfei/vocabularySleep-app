import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ToolboxShortLinkProvider { tinyUrl, isGd, vGd, cleanUri, localAlias }

extension ToolboxShortLinkProviderInfo on ToolboxShortLinkProvider {
  String get id {
    return switch (this) {
      ToolboxShortLinkProvider.tinyUrl => 'tinyurl',
      ToolboxShortLinkProvider.isGd => 'isgd',
      ToolboxShortLinkProvider.vGd => 'vgd',
      ToolboxShortLinkProvider.cleanUri => 'cleanuri',
      ToolboxShortLinkProvider.localAlias => 'local_alias',
    };
  }

  String get label {
    return switch (this) {
      ToolboxShortLinkProvider.tinyUrl => 'TinyURL',
      ToolboxShortLinkProvider.isGd => 'is.gd',
      ToolboxShortLinkProvider.vGd => 'v.gd',
      ToolboxShortLinkProvider.cleanUri => 'CleanURI',
      ToolboxShortLinkProvider.localAlias => 'Local alias',
    };
  }

  bool get supportsCustomAlias {
    return switch (this) {
      ToolboxShortLinkProvider.isGd ||
      ToolboxShortLinkProvider.vGd ||
      ToolboxShortLinkProvider.localAlias => true,
      ToolboxShortLinkProvider.tinyUrl ||
      ToolboxShortLinkProvider.cleanUri => false,
    };
  }

  bool get usesNetwork => this != ToolboxShortLinkProvider.localAlias;
}

@immutable
class ToolboxShortLinkResult {
  const ToolboxShortLinkResult({
    required this.provider,
    required this.originalUrl,
    required this.shortUrl,
    required this.createdAt,
    this.alias = '',
    this.warning = '',
  });

  final ToolboxShortLinkProvider provider;
  final Uri originalUrl;
  final String shortUrl;
  final DateTime createdAt;
  final String alias;
  final String warning;
}

@immutable
class ToolboxShortLinkHop {
  const ToolboxShortLinkHop({
    required this.url,
    required this.statusCode,
    this.location,
  });

  final String url;
  final int statusCode;
  final String? location;

  bool get isRedirect =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}

@immutable
class ToolboxShortLinkResolveResult {
  const ToolboxShortLinkResolveResult({
    required this.inputUrl,
    required this.finalUrl,
    required this.hops,
    required this.reachedLimit,
  });

  final Uri inputUrl;
  final Uri finalUrl;
  final List<ToolboxShortLinkHop> hops;
  final bool reachedLimit;

  int get redirectCount => hops.where((hop) => hop.isRedirect).length;
}

class ToolboxShortLinkService {
  const ToolboxShortLinkService({http.Client? client}) : _client = client;

  final http.Client? _client;

  static Uri normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('URL is empty.');
    }
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed)
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.parse(withScheme);
    if (!uri.hasScheme || uri.host.trim().isEmpty) {
      throw FormatException('Invalid URL: $input');
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw FormatException('Only HTTP/HTTPS URLs are supported: $input');
    }
    return uri;
  }

  static String sanitizeAlias(String input) {
    final alias = input.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    return alias
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static String buildLocalAlias(Uri url, {String alias = ''}) {
    final cleanedAlias = sanitizeAlias(alias);
    if (cleanedAlias.isNotEmpty) {
      return cleanedAlias;
    }
    final digest = sha256.convert(utf8.encode(url.toString())).bytes;
    return base64Url.encode(digest).replaceAll('=', '').substring(0, 9);
  }

  Future<ToolboxShortLinkResult> shorten({
    required String inputUrl,
    required ToolboxShortLinkProvider provider,
    String alias = '',
  }) async {
    final normalizedUrl = normalizeUrl(inputUrl);
    final cleanedAlias = sanitizeAlias(alias);
    if (!provider.usesNetwork) {
      final localAlias = buildLocalAlias(normalizedUrl, alias: cleanedAlias);
      return ToolboxShortLinkResult(
        provider: provider,
        originalUrl: normalizedUrl,
        shortUrl: 'vocab-sleep://short/$localAlias',
        alias: localAlias,
        createdAt: DateTime.now(),
        warning:
            'Local aliases are offline labels. Keep the original URL or this app session mapping.',
      );
    }

    final client = _client ?? http.Client();
    final closeClient = _client == null;
    try {
      final shortUrl = switch (provider) {
        ToolboxShortLinkProvider.tinyUrl => await _shortenWithTinyUrl(
          client,
          normalizedUrl,
        ),
        ToolboxShortLinkProvider.isGd => await _shortenWithIsGd(
          client,
          normalizedUrl,
          cleanedAlias,
          host: 'is.gd',
        ),
        ToolboxShortLinkProvider.vGd => await _shortenWithIsGd(
          client,
          normalizedUrl,
          cleanedAlias,
          host: 'v.gd',
        ),
        ToolboxShortLinkProvider.cleanUri => await _shortenWithCleanUri(
          client,
          normalizedUrl,
        ),
        ToolboxShortLinkProvider.localAlias => throw StateError('unreachable'),
      };
      return ToolboxShortLinkResult(
        provider: provider,
        originalUrl: normalizedUrl,
        shortUrl: shortUrl,
        alias: cleanedAlias,
        createdAt: DateTime.now(),
      );
    } finally {
      if (closeClient) {
        client.close();
      }
    }
  }

  Future<ToolboxShortLinkResolveResult> resolve({
    required String inputUrl,
    int maxHops = 8,
  }) async {
    final start = normalizeUrl(inputUrl);
    final client = _client ?? http.Client();
    final closeClient = _client == null;
    final hops = <ToolboxShortLinkHop>[];
    var current = start;
    try {
      for (var index = 0; index <= maxHops; index += 1) {
        final response = await _sendNoFollow(client, current);
        final location = response.headers['location'];
        await response.stream.drain<void>();
        final resolvedLocation = location == null || location.trim().isEmpty
            ? null
            : current.resolve(location.trim()).toString();
        final hop = ToolboxShortLinkHop(
          url: current.toString(),
          statusCode: response.statusCode,
          location: resolvedLocation,
        );
        hops.add(hop);
        if (!hop.isRedirect || resolvedLocation == null) {
          return ToolboxShortLinkResolveResult(
            inputUrl: start,
            finalUrl: current,
            hops: List<ToolboxShortLinkHop>.unmodifiable(hops),
            reachedLimit: false,
          );
        }
        current = Uri.parse(resolvedLocation);
      }
      return ToolboxShortLinkResolveResult(
        inputUrl: start,
        finalUrl: current,
        hops: List<ToolboxShortLinkHop>.unmodifiable(hops),
        reachedLimit: true,
      );
    } finally {
      if (closeClient) {
        client.close();
      }
    }
  }

  static Future<String> _shortenWithTinyUrl(http.Client client, Uri url) async {
    final endpoint = Uri.https(
      'tinyurl.com',
      '/api-create.php',
      <String, String>{'url': url.toString()},
    );
    final response = await client
        .get(endpoint, headers: _headers)
        .timeout(const Duration(seconds: 12));
    _throwIfBadResponse(response);
    return _readPlainShortUrl(response.body, hostHint: 'tinyurl.com');
  }

  static Future<String> _shortenWithIsGd(
    http.Client client,
    Uri url,
    String alias, {
    required String host,
  }) async {
    final query = <String, String>{
      'format': 'simple',
      'url': url.toString(),
      if (alias.isNotEmpty) 'shorturl': alias,
    };
    final endpoint = Uri.https(host, '/create.php', query);
    final response = await client
        .get(endpoint, headers: _headers)
        .timeout(const Duration(seconds: 12));
    _throwIfBadResponse(response);
    return _readPlainShortUrl(response.body, hostHint: host);
  }

  static Future<String> _shortenWithCleanUri(
    http.Client client,
    Uri url,
  ) async {
    final endpoint = Uri.https('cleanuri.com', '/api/v1/shorten');
    final response = await client
        .post(
          endpoint,
          headers: const <String, String>{
            ..._headers,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: <String, String>{'url': url.toString()},
        )
        .timeout(const Duration(seconds: 12));
    _throwIfBadResponse(response);
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['result_url'] is String) {
      return _readPlainShortUrl('${decoded['result_url']}');
    }
    throw FormatException('Unexpected CleanURI response: ${response.body}');
  }

  static String _readPlainShortUrl(String body, {String hostHint = ''}) {
    final value = body.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return uri.toString();
    }
    throw FormatException(
      hostHint.isEmpty
          ? 'Short-link service returned an invalid URL.'
          : '$hostHint returned an invalid URL: $value',
    );
  }

  static void _throwIfBadResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final snippet = response.body.trim();
    throw HttpExceptionSummary(
      statusCode: response.statusCode,
      body: snippet.length > 160 ? snippet.substring(0, 160) : snippet,
    );
  }

  static Future<http.StreamedResponse> _sendNoFollow(
    http.Client client,
    Uri uri,
  ) async {
    Future<http.StreamedResponse> send(String method) {
      final request = http.Request(method, uri)
        ..followRedirects = false
        ..maxRedirects = 0
        ..headers.addAll(_headers);
      return client.send(request).timeout(const Duration(seconds: 12));
    }

    try {
      final response = await send('HEAD');
      if (response.statusCode != 405 && response.statusCode != 403) {
        return response;
      }
      await response.stream.drain<void>();
    } on TimeoutException {
      rethrow;
    } on Object {
      // Some short-link endpoints reject HEAD; retry with GET below.
    }
    return send('GET');
  }

  static const Map<String, String> _headers = <String, String>{
    'User-Agent': 'VocabularySleepLifeTools/1.0 (+short-link-tool)',
    'Accept': 'text/plain, application/json, */*',
  };
}

@immutable
class HttpExceptionSummary implements Exception {
  const HttpExceptionSummary({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() {
    final suffix = body.isEmpty ? '' : ': $body';
    return 'HTTP $statusCode$suffix';
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/play_config.dart';
import '../utils/speech_api_model_options.dart';

class SpeechRemoteModelService {
  const SpeechRemoteModelService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<String>> fetchTtsModelIds(TtsConfig config) async {
    final provider = config.provider;
    if (!ttsProviderCanFetchModels(provider)) {
      return const <String>[];
    }
    final endpoint = _resolveTtsModelsEndpoint(config);
    final models = await _fetchModelIds(
      endpoint: endpoint,
      apiKey: config.apiKey,
    );
    return filterTtsModelIdsForProvider(provider, models);
  }

  Future<List<String>> fetchAsrModelIds(AsrConfig config) async {
    final provider = config.provider;
    if (!asrProviderCanFetchModels(provider)) {
      return const <String>[];
    }
    final endpoint = _resolveAsrModelsEndpoint(config);
    return _fetchModelIds(endpoint: endpoint, apiKey: config.apiKey);
  }

  Future<List<String>> fetchVoiceInputModelIds(VoiceInputConfig config) async {
    final asrProvider = config.recordingProvider;
    if (!asrProviderCanFetchModels(asrProvider)) {
      return const <String>[];
    }
    final endpoint = _defaultModelsEndpointForAsr(asrProvider);
    return _fetchModelIds(endpoint: endpoint, apiKey: config.apiKey);
  }

  Future<List<String>> _fetchModelIds({
    required String endpoint,
    required String? apiKey,
  }) async {
    final key = (apiKey ?? '').trim();
    if (key.isEmpty) {
      throw StateError('speechRemoteApiKeyMissing');
    }
    final ownedClient = _client == null ? http.Client() : null;
    final client = _client ?? ownedClient!;
    try {
      final response = await client
          .get(
            Uri.parse(endpoint),
            headers: <String, String>{'Authorization': 'Bearer $key'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('speechRemoteModelFetchFailed:${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      return parseSpeechRemoteModelIds(decoded);
    } finally {
      ownedClient?.close();
    }
  }

  String _resolveTtsModelsEndpoint(TtsConfig config) {
    final provider = config.provider;
    if (provider == TtsProviderType.customApi) {
      return _openAiModelsEndpoint(config.baseUrl);
    }
    if (provider == TtsProviderType.aliyunBailian) {
      return 'https://dashscope.aliyuncs.com/compatible-mode/v1/models';
    }
    return 'https://api.siliconflow.cn/v1/models';
  }

  String _resolveAsrModelsEndpoint(AsrConfig config) {
    final provider = config.provider;
    if (provider == AsrProviderType.customApi) {
      return _openAiModelsEndpoint(config.baseUrl);
    }
    return _defaultModelsEndpointForAsr(provider);
  }

  String _defaultModelsEndpointForAsr(AsrProviderType provider) {
    return switch (provider) {
      AsrProviderType.aliyunBailian =>
        'https://dashscope.aliyuncs.com/compatible-mode/v1/models',
      AsrProviderType.doubao =>
        'https://ark.cn-beijing.volces.com/api/v3/models',
      _ => 'https://api.siliconflow.cn/v1/models',
    };
  }

  String _openAiModelsEndpoint(String? baseUrl) {
    final raw = (baseUrl ?? '').trim();
    if (raw.isEmpty) {
      throw StateError('speechRemoteBaseUrlMissing');
    }
    var normalized = raw.replaceAll(RegExp(r'/+$'), '');
    normalized = normalized
        .replaceFirst(RegExp(r'/audio/(speech|transcriptions)$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    if (normalized.toLowerCase().endsWith('/v1')) {
      return '$normalized/models';
    }
    return '$normalized/v1/models';
  }
}

List<String> parseSpeechRemoteModelIds(Object? decoded) {
  final ids = <String>[];
  void add(Object? value) {
    final id = '$value'.trim();
    if (id.isEmpty || id == 'null' || ids.contains(id)) return;
    ids.add(id);
  }

  void visit(Object? value) {
    if (value is Map) {
      add(
        value['id'] ?? value['model'] ?? value['model_name'] ?? value['name'],
      );
      final nested = value['data'] ?? value['models'] ?? value['items'];
      if (nested != null && !identical(nested, value)) {
        visit(nested);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        visit(item);
      }
    }
  }

  visit(decoded);
  return ids;
}

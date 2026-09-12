/// [风险] SEC-02: `playConfig` 持久化 JSON 中 tts/asr/voiceInput 的 apiKey
/// 属于敏感凭据，不允许随 settings 行或整库备份落盘。
/// 这里提供纯 JSON 文本级的提取/剥离/注入，供 SettingsService 与
/// 安全备份链路复用；不引入对模型或存储层的依赖。
library;

import 'dart:convert';

const String playConfigSettingKey = 'playConfig';

/// 三个承载 apiKey 的嵌套槽位。
const List<String> playConfigApiKeySlots = <String>['tts', 'asr', 'voiceInput'];

bool _isBlank(Object? value) =>
    value == null || (value is String && value.trim().isEmpty);

Map<String, Object?>? decodePlayConfigJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
  } catch (_) {
    // 损坏的 JSON 交由调用方按默认值处理。
  }
  return null;
}

/// 提取 playConfig JSON Map 中的明文 apiKey。
Map<String, String?> extractPlayConfigApiKeysFromJson(
  Map<String, Object?> json,
) {
  final result = <String, String?>{
    for (final slot in playConfigApiKeySlots) slot: null,
  };
  for (final slot in playConfigApiKeySlots) {
    final nested = json[slot];
    if (nested is Map) {
      final apiKey = nested['apiKey'];
      if (!_isBlank(apiKey)) {
        result[slot] = '$apiKey';
      }
    }
  }
  return result;
}

/// 提取 playConfig JSON 原文中的明文 apiKey（用于一次性迁移到安全存储）。
Map<String, String?> extractPlayConfigApiKeys(String? raw) {
  final json = decodePlayConfigJson(raw);
  if (json == null) {
    return <String, String?>{
      for (final slot in playConfigApiKeySlots) slot: null,
    };
  }
  return extractPlayConfigApiKeysFromJson(json);
}

/// 就地剥离三个槽位的 apiKey；用于落库前的 JSON 处理。
void stripPlayConfigApiKeysInJson(Map<String, Object?> json) {
  for (final slot in playConfigApiKeySlots) {
    final nested = json[slot];
    if (nested is Map && nested.containsKey('apiKey')) {
      nested['apiKey'] = null;
    }
  }
}

/// 文本级剥离：返回剥离后的 JSON 字符串；无需变更或解析失败时返回 null。
String? stripPlayConfigApiKeysFromRaw(String? raw) {
  final json = decodePlayConfigJson(raw);
  if (json == null) return null;
  stripPlayConfigApiKeysInJson(json);
  return jsonEncode(json);
}

/// 就地注入缓存中的密钥：只填充缺失或空白的 apiKey，不覆盖行内已有值。
/// 返回是否有变更。
bool injectPlayConfigApiKeys(
  Map<String, Object?> json,
  Map<String, String?> keys,
) {
  var changed = false;
  for (final slot in playConfigApiKeySlots) {
    final value = keys[slot];
    if (_isBlank(value)) continue;
    final nested = json[slot];
    if (nested is Map && _isBlank(nested['apiKey'])) {
      nested['apiKey'] = value;
      changed = true;
    }
  }
  return changed;
}

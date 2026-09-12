import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [风险] 可测试的安全键值抽象：默认实现委托系统 Keystore / Keychain /
/// Windows 凭据管理器。平台通道不可用（部分桌面/测试环境）时调用会抛出
/// 异常，调用方必须自行降级并记录日志，不得静默丢失用户凭据。
abstract class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String? value);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      _storage.write(key: key, value: value);
}

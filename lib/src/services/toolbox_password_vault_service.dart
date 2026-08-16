import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'toolbox_crypto_service.dart';

enum ToolboxPasswordVaultStrength { enhanced, extreme }

extension ToolboxPasswordVaultStrengthInfo on ToolboxPasswordVaultStrength {
  String get id {
    return switch (this) {
      ToolboxPasswordVaultStrength.enhanced => 'enhanced',
      ToolboxPasswordVaultStrength.extreme => 'extreme',
    };
  }

  ToolboxCryptoStrength get cryptoStrength {
    return switch (this) {
      ToolboxPasswordVaultStrength.enhanced => ToolboxCryptoStrength.strong,
      ToolboxPasswordVaultStrength.extreme => ToolboxCryptoStrength.extreme,
    };
  }

  ToolboxCryptoKeyBits get materialBits {
    return switch (this) {
      ToolboxPasswordVaultStrength.enhanced => ToolboxCryptoKeyBits.bits1024,
      ToolboxPasswordVaultStrength.extreme => ToolboxCryptoKeyBits.bits2048,
    };
  }
}

enum ToolboxPasswordVaultRuleMode { none, prefixSuffix, substitution, shift }

extension ToolboxPasswordVaultRuleModeInfo on ToolboxPasswordVaultRuleMode {
  String get id {
    return switch (this) {
      ToolboxPasswordVaultRuleMode.none => 'none',
      ToolboxPasswordVaultRuleMode.prefixSuffix => 'prefix_suffix',
      ToolboxPasswordVaultRuleMode.substitution => 'substitution',
      ToolboxPasswordVaultRuleMode.shift => 'shift',
    };
  }
}

enum ToolboxPasswordVaultUnlockMode { primary, shadow }

class ToolboxPasswordVaultException implements Exception {
  const ToolboxPasswordVaultException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolboxPasswordVaultMasterPasswordAssessment {
  const ToolboxPasswordVaultMasterPasswordAssessment({
    required this.entropyBits,
    required this.characterClasses,
    required this.issues,
  });

  final double entropyBits;
  final int characterClasses;
  final List<String> issues;

  bool get accepted => issues.isEmpty;
}

class ToolboxPasswordVaultAccessRule {
  const ToolboxPasswordVaultAccessRule.none()
    : mode = ToolboxPasswordVaultRuleMode.none,
      prefix = '',
      suffix = '',
      substitutionFrom = '',
      substitutionTo = '',
      shift = 0;

  const ToolboxPasswordVaultAccessRule.prefixSuffix({
    required this.prefix,
    required this.suffix,
  }) : mode = ToolboxPasswordVaultRuleMode.prefixSuffix,
       substitutionFrom = '',
       substitutionTo = '',
       shift = 0;

  const ToolboxPasswordVaultAccessRule.substitution({
    required this.substitutionFrom,
    required this.substitutionTo,
  }) : mode = ToolboxPasswordVaultRuleMode.substitution,
       prefix = '',
       suffix = '',
       shift = 0;

  const ToolboxPasswordVaultAccessRule.shift({required this.shift})
    : mode = ToolboxPasswordVaultRuleMode.shift,
      prefix = '',
      suffix = '',
      substitutionFrom = '',
      substitutionTo = '';

  final ToolboxPasswordVaultRuleMode mode;
  final String prefix;
  final String suffix;
  final String substitutionFrom;
  final String substitutionTo;
  final int shift;

  String apply(String password) {
    return switch (mode) {
      ToolboxPasswordVaultRuleMode.none => password,
      ToolboxPasswordVaultRuleMode.prefixSuffix => '$prefix$password$suffix',
      ToolboxPasswordVaultRuleMode.substitution => _applySubstitution(password),
      ToolboxPasswordVaultRuleMode.shift => _applyShift(password, shift),
    };
  }

  String _applySubstitution(String password) {
    final from = substitutionFrom.runes.toList(growable: false);
    final to = substitutionTo.runes.toList(growable: false);
    if (from.isEmpty || from.length != to.length) {
      throw const ToolboxPasswordVaultException(
        'Substitution rule must map the same number of characters.',
      );
    }
    final table = <int, int>{};
    for (var index = 0; index < from.length; index += 1) {
      table[from[index]] = to[index];
    }
    final buffer = StringBuffer();
    for (final rune in password.runes) {
      buffer.writeCharCode(table[rune] ?? rune);
    }
    return buffer.toString();
  }

  String _applyShift(String password, int shift) {
    final buffer = StringBuffer();
    for (final rune in password.runes) {
      if (rune >= 65 && rune <= 90) {
        buffer.writeCharCode(_shiftRune(rune, 65, 26, shift));
      } else if (rune >= 97 && rune <= 122) {
        buffer.writeCharCode(_shiftRune(rune, 97, 26, shift));
      } else if (rune >= 48 && rune <= 57) {
        buffer.writeCharCode(_shiftRune(rune, 48, 10, shift));
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  int _shiftRune(int rune, int base, int modulo, int shift) {
    final normalized = ((rune - base + shift) % modulo + modulo) % modulo;
    return base + normalized;
  }
}

class ToolboxPasswordVaultEntryIndex {
  const ToolboxPasswordVaultEntryIndex({
    required this.id,
    required this.channel,
    required this.account,
    required this.hint,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.shadow = false,
  });

  final String id;
  final String channel;
  final String account;
  final String hint;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool shadow;

  String get displayTitle => channel.trim().isEmpty ? account : channel;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'channel': channel,
      'account': account,
      'hint': hint,
      'note': note,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'shadow': shadow,
    };
  }

  factory ToolboxPasswordVaultEntryIndex.fromJson(Map<String, Object?> json) {
    return ToolboxPasswordVaultEntryIndex(
      id: _readVaultString(json, 'id'),
      channel: _readVaultString(json, 'channel'),
      account: _readVaultString(json, 'account'),
      hint: _readVaultString(json, 'hint'),
      note: _readVaultString(json, 'note'),
      createdAt: _readVaultDate(json, 'createdAt'),
      updatedAt: _readVaultDate(json, 'updatedAt'),
      shadow: _readOptionalVaultBool(json, 'shadow') ?? false,
    );
  }

  ToolboxPasswordVaultEntryIndex copyWith({
    String? channel,
    String? account,
    String? hint,
    String? note,
    DateTime? updatedAt,
    bool? shadow,
  }) {
    return ToolboxPasswordVaultEntryIndex(
      id: id,
      channel: channel ?? this.channel,
      account: account ?? this.account,
      hint: hint ?? this.hint,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shadow: shadow ?? this.shadow,
    );
  }
}

class ToolboxPasswordVaultEntry {
  const ToolboxPasswordVaultEntry({
    required this.id,
    required this.channel,
    required this.account,
    required this.password,
    required this.hint,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channel;
  final String account;
  final String password;
  final String hint;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle => channel.trim().isEmpty ? account : channel;

  ToolboxPasswordVaultEntryIndex toIndex({bool shadow = false}) {
    return ToolboxPasswordVaultEntryIndex(
      id: id,
      channel: channel,
      account: account,
      hint: hint,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      shadow: shadow,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'channel': channel,
      'account': account,
      'password': password,
      'hint': hint,
      'note': note,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ToolboxPasswordVaultEntry.fromJson(Map<String, Object?> json) {
    return ToolboxPasswordVaultEntry(
      id: _readVaultString(json, 'id'),
      channel: _readVaultString(json, 'channel'),
      account: _readVaultString(json, 'account'),
      password: _readVaultString(json, 'password'),
      hint: _readVaultString(json, 'hint'),
      note: _readVaultString(json, 'note'),
      createdAt: _readVaultDate(json, 'createdAt'),
      updatedAt: _readVaultDate(json, 'updatedAt'),
    );
  }

  ToolboxPasswordVaultEntry copyWith({
    String? channel,
    String? account,
    String? password,
    String? hint,
    String? note,
    DateTime? updatedAt,
  }) {
    return ToolboxPasswordVaultEntry(
      id: id,
      channel: channel ?? this.channel,
      account: account ?? this.account,
      password: password ?? this.password,
      hint: hint ?? this.hint,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ToolboxPasswordVaultSettings {
  const ToolboxPasswordVaultSettings({
    required this.id,
    required this.name,
    required this.strength,
    required this.visible,
    required this.shadowEnabled,
    required this.shadowMaxUnlocks,
    required this.shadowUnlocks,
    required this.keyFileSha256,
    required this.deleteRequiresPassword,
    required this.addEntryRequiresPassword,
    required this.editEntryRequiresPassword,
    required this.deleteEntryRequiresPassword,
    required this.biometricGateEnabled,
    required this.clipboardClearSeconds,
    required this.autoLockSeconds,
    required this.passwordHint,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final ToolboxPasswordVaultStrength strength;
  final bool visible;
  final bool shadowEnabled;
  final int shadowMaxUnlocks;
  final int shadowUnlocks;
  final String? keyFileSha256;
  final bool deleteRequiresPassword;
  final bool addEntryRequiresPassword;
  final bool editEntryRequiresPassword;
  final bool deleteEntryRequiresPassword;
  final bool biometricGateEnabled;
  final int clipboardClearSeconds;
  final int autoLockSeconds;
  final String passwordHint;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'strength': strength.id,
      'visible': visible,
      'shadowEnabled': shadowEnabled,
      'shadowMaxUnlocks': shadowMaxUnlocks,
      'shadowUnlocks': shadowUnlocks,
      'keyFileSha256': keyFileSha256,
      'deleteRequiresPassword': deleteRequiresPassword,
      'addEntryRequiresPassword': addEntryRequiresPassword,
      'editEntryRequiresPassword': editEntryRequiresPassword,
      'deleteEntryRequiresPassword': deleteEntryRequiresPassword,
      'biometricGateEnabled': biometricGateEnabled,
      'clipboardClearSeconds': clipboardClearSeconds,
      'autoLockSeconds': autoLockSeconds,
      'passwordHint': passwordHint,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ToolboxPasswordVaultSettings.fromJson(Map<String, Object?> json) {
    final maxUnlocks = _readOptionalVaultInt(json, 'shadowMaxUnlocks') ?? 0;
    final unlocks = _readOptionalVaultInt(json, 'shadowUnlocks') ?? 0;
    if (maxUnlocks < 0 || unlocks < 0) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    return ToolboxPasswordVaultSettings(
      id: _readVaultString(json, 'id'),
      name: _readVaultString(json, 'name'),
      strength: _readVaultStrength(json, 'strength'),
      visible: _readOptionalVaultBool(json, 'visible') ?? true,
      shadowEnabled: _readOptionalVaultBool(json, 'shadowEnabled') ?? false,
      shadowMaxUnlocks: maxUnlocks,
      shadowUnlocks: unlocks,
      keyFileSha256: _readOptionalVaultHex(json, 'keyFileSha256'),
      deleteRequiresPassword:
          _readOptionalVaultBool(json, 'deleteRequiresPassword') ?? true,
      addEntryRequiresPassword:
          _readOptionalVaultBool(json, 'addEntryRequiresPassword') ?? true,
      editEntryRequiresPassword:
          _readOptionalVaultBool(json, 'editEntryRequiresPassword') ?? true,
      deleteEntryRequiresPassword:
          _readOptionalVaultBool(json, 'deleteEntryRequiresPassword') ?? true,
      biometricGateEnabled:
          _readOptionalVaultBool(json, 'biometricGateEnabled') ?? false,
      clipboardClearSeconds: _readBoundedOptionalVaultInt(
        json,
        'clipboardClearSeconds',
        defaultValue: ToolboxPasswordVaultService.defaultClipboardClearSeconds,
        min: ToolboxPasswordVaultService.minClipboardClearSeconds,
        max: ToolboxPasswordVaultService.maxClipboardClearSeconds,
      ),
      autoLockSeconds: _readBoundedOptionalVaultInt(
        json,
        'autoLockSeconds',
        defaultValue: ToolboxPasswordVaultService.defaultAutoLockSeconds,
        min: ToolboxPasswordVaultService.minAutoLockSeconds,
        max: ToolboxPasswordVaultService.maxAutoLockSeconds,
      ),
      passwordHint: _readOptionalVaultString(json, 'passwordHint') ?? '',
      createdAt: _readVaultDate(json, 'createdAt'),
      updatedAt: _readVaultDate(json, 'updatedAt'),
    );
  }

  ToolboxPasswordVaultSettings copyWith({
    String? name,
    ToolboxPasswordVaultStrength? strength,
    bool? visible,
    bool? shadowEnabled,
    int? shadowMaxUnlocks,
    int? shadowUnlocks,
    String? keyFileSha256,
    bool clearKeyFileSha256 = false,
    bool? deleteRequiresPassword,
    bool? addEntryRequiresPassword,
    bool? editEntryRequiresPassword,
    bool? deleteEntryRequiresPassword,
    bool? biometricGateEnabled,
    int? clipboardClearSeconds,
    int? autoLockSeconds,
    String? passwordHint,
    DateTime? updatedAt,
  }) {
    return ToolboxPasswordVaultSettings(
      id: id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      visible: visible ?? this.visible,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      shadowMaxUnlocks: shadowMaxUnlocks ?? this.shadowMaxUnlocks,
      shadowUnlocks: shadowUnlocks ?? this.shadowUnlocks,
      keyFileSha256: clearKeyFileSha256
          ? null
          : keyFileSha256 ?? this.keyFileSha256,
      deleteRequiresPassword:
          deleteRequiresPassword ?? this.deleteRequiresPassword,
      addEntryRequiresPassword:
          addEntryRequiresPassword ?? this.addEntryRequiresPassword,
      editEntryRequiresPassword:
          editEntryRequiresPassword ?? this.editEntryRequiresPassword,
      deleteEntryRequiresPassword:
          deleteEntryRequiresPassword ?? this.deleteEntryRequiresPassword,
      biometricGateEnabled: biometricGateEnabled ?? this.biometricGateEnabled,
      clipboardClearSeconds:
          clipboardClearSeconds ?? this.clipboardClearSeconds,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      passwordHint: passwordHint ?? this.passwordHint,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ToolboxPasswordVaultEncryptedBlob {
  const ToolboxPasswordVaultEncryptedBlob({
    required this.contextSalt,
    required this.envelopeBase64,
  });

  final String contextSalt;
  final String envelopeBase64;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'contextSalt': contextSalt,
      'envelope': envelopeBase64,
    };
  }

  factory ToolboxPasswordVaultEncryptedBlob.fromJson(
    Map<String, Object?> json,
  ) {
    return ToolboxPasswordVaultEncryptedBlob(
      contextSalt: _readVaultString(json, 'contextSalt'),
      envelopeBase64: _readVaultString(json, 'envelope'),
    );
  }
}

class ToolboxPasswordVaultEncryptedRecord {
  const ToolboxPasswordVaultEncryptedRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.contextSalt,
    required this.metadataDigest,
    required this.secretDerivationContext,
    required this.cascadeFingerprint,
    required this.stageCount,
    required this.strength,
    required this.materialBits,
    required this.indexEnvelopeBase64,
    required this.passwordEnvelopeBase64,
    this.legacyEntryEnvelopeBase64,
    this.legacySecretDerivationContext = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contextSalt;
  final String metadataDigest;
  final String secretDerivationContext;
  final String cascadeFingerprint;
  final int stageCount;
  final ToolboxPasswordVaultStrength strength;
  final ToolboxCryptoKeyBits materialBits;
  final String indexEnvelopeBase64;
  final String passwordEnvelopeBase64;
  final String? legacyEntryEnvelopeBase64;
  final bool legacySecretDerivationContext;

  bool get isLegacyFullEntry => legacyEntryEnvelopeBase64 != null;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'contextSalt': contextSalt,
      'metadataDigest': metadataDigest,
      'secretDerivationContext': secretDerivationContext,
      'cascadeFingerprint': cascadeFingerprint,
      'stageCount': stageCount,
      'strength': strength.id,
      'materialBits': materialBits.id,
      'entryKeyVersion': ToolboxPasswordVaultService.entryKeyVersion,
      'cascadeVersion': ToolboxPasswordVaultService.cascadeVersion,
      'indexEnvelope': indexEnvelopeBase64,
      'passwordEnvelope': passwordEnvelopeBase64,
    };
  }

  factory ToolboxPasswordVaultEncryptedRecord.fromJson(
    Map<String, Object?> json,
  ) {
    final stageCount = _readVaultInt(json, 'stageCount');
    if (stageCount < 3 || stageCount > 5) {
      throw const ToolboxPasswordVaultException('Vault record is invalid.');
    }
    final legacyEnvelope = json['envelope'];
    final indexEnvelope = json['indexEnvelope'];
    final passwordEnvelope = json['passwordEnvelope'];
    final secretContext = _readRecordSecretDerivationContext(json);
    if (legacyEnvelope is String &&
        (indexEnvelope == null || passwordEnvelope == null)) {
      return ToolboxPasswordVaultEncryptedRecord(
        id: _readVaultString(json, 'id'),
        createdAt: _readVaultDate(json, 'createdAt'),
        updatedAt: _readVaultDate(json, 'updatedAt'),
        contextSalt: _readVaultString(json, 'contextSalt'),
        metadataDigest: _readVaultHex(json, 'metadataDigest'),
        secretDerivationContext: secretContext.value,
        cascadeFingerprint: _readVaultHex(
          json,
          'cascadeFingerprint',
          length: 16,
        ),
        stageCount: stageCount,
        strength: _readVaultStrength(json, 'strength'),
        materialBits: _readVaultMaterialBits(json),
        indexEnvelopeBase64: legacyEnvelope,
        passwordEnvelopeBase64: legacyEnvelope,
        legacyEntryEnvelopeBase64: legacyEnvelope,
        legacySecretDerivationContext: secretContext.legacy,
      );
    }
    return ToolboxPasswordVaultEncryptedRecord(
      id: _readVaultString(json, 'id'),
      createdAt: _readVaultDate(json, 'createdAt'),
      updatedAt: _readVaultDate(json, 'updatedAt'),
      contextSalt: _readVaultString(json, 'contextSalt'),
      metadataDigest: _readVaultHex(json, 'metadataDigest'),
      secretDerivationContext: secretContext.value,
      cascadeFingerprint: _readVaultHex(json, 'cascadeFingerprint', length: 16),
      stageCount: stageCount,
      strength: _readVaultStrength(json, 'strength'),
      materialBits: _readVaultMaterialBits(json),
      indexEnvelopeBase64: _readVaultString(json, 'indexEnvelope'),
      passwordEnvelopeBase64: _readVaultString(json, 'passwordEnvelope'),
      legacySecretDerivationContext: secretContext.legacy,
    );
  }
}

class ToolboxPasswordVaultSnapshot {
  const ToolboxPasswordVaultSnapshot({
    required this.settings,
    required this.records,
    required this.shadowRecords,
    this.primaryVerifier,
    this.shadowVerifier,
    this.primaryManifestVerifier,
    this.shadowManifestVerifier,
    this.shadowSyncEnvelope,
    this.legacyVersion = false,
  });

  final ToolboxPasswordVaultSettings settings;
  final List<ToolboxPasswordVaultEncryptedRecord> records;
  final List<ToolboxPasswordVaultEncryptedRecord> shadowRecords;
  final ToolboxPasswordVaultEncryptedBlob? primaryVerifier;
  final ToolboxPasswordVaultEncryptedBlob? shadowVerifier;
  final ToolboxPasswordVaultEncryptedBlob? primaryManifestVerifier;
  final ToolboxPasswordVaultEncryptedBlob? shadowManifestVerifier;
  final ToolboxPasswordVaultEncryptedBlob? shadowSyncEnvelope;
  final bool legacyVersion;

  bool get hasProtectedManifest =>
      primaryManifestVerifier != null || shadowManifestVerifier != null;

  ToolboxPasswordVaultSnapshot copyWith({
    ToolboxPasswordVaultSettings? settings,
    List<ToolboxPasswordVaultEncryptedRecord>? records,
    List<ToolboxPasswordVaultEncryptedRecord>? shadowRecords,
    ToolboxPasswordVaultEncryptedBlob? primaryVerifier,
    ToolboxPasswordVaultEncryptedBlob? shadowVerifier,
    ToolboxPasswordVaultEncryptedBlob? primaryManifestVerifier,
    ToolboxPasswordVaultEncryptedBlob? shadowManifestVerifier,
    ToolboxPasswordVaultEncryptedBlob? shadowSyncEnvelope,
    bool clearShadowVerifier = false,
    bool clearPrimaryManifestVerifier = false,
    bool clearShadowManifestVerifier = false,
    bool clearShadowSyncEnvelope = false,
    bool? legacyVersion,
  }) {
    return ToolboxPasswordVaultSnapshot(
      settings: settings ?? this.settings,
      records: records ?? this.records,
      shadowRecords: shadowRecords ?? this.shadowRecords,
      primaryVerifier: primaryVerifier ?? this.primaryVerifier,
      shadowVerifier: clearShadowVerifier
          ? null
          : shadowVerifier ?? this.shadowVerifier,
      primaryManifestVerifier: clearPrimaryManifestVerifier
          ? null
          : primaryManifestVerifier ?? this.primaryManifestVerifier,
      shadowManifestVerifier: clearShadowManifestVerifier
          ? null
          : shadowManifestVerifier ?? this.shadowManifestVerifier,
      shadowSyncEnvelope: clearShadowSyncEnvelope
          ? null
          : shadowSyncEnvelope ?? this.shadowSyncEnvelope,
      legacyVersion: legacyVersion ?? this.legacyVersion,
    );
  }
}

class ToolboxPasswordVaultUnlockResult {
  const ToolboxPasswordVaultUnlockResult({
    required this.snapshot,
    required this.indexes,
    required this.fileSha256,
    required this.mode,
    required this.shadowStateChanged,
    required this.shadowPurgeTriggered,
    this.recordDerivationMigrated = false,
    this.manifestAuthMigrated = false,
  });

  final ToolboxPasswordVaultSnapshot snapshot;
  final List<ToolboxPasswordVaultEntryIndex> indexes;
  final String fileSha256;
  final ToolboxPasswordVaultUnlockMode mode;
  final bool shadowStateChanged;
  final bool shadowPurgeTriggered;
  final bool recordDerivationMigrated;
  final bool manifestAuthMigrated;
}

class ToolboxPasswordVaultService {
  ToolboxPasswordVaultService({ToolboxCryptoService? cryptoService})
    : _cryptoService = cryptoService ?? ToolboxCryptoService();

  static const String format = 'vocabulary_sleep_password_vault';
  static const int legacyVersion = 1;
  static const int version = 2;
  static const int maxVaultBytes = 16 * 1024 * 1024;
  static const int maxRecords = 500;
  static const int maxEntryPlainBytes = 128 * 1024;
  static const int maxShortTextLength = 512;
  static const int maxPasswordLength = 4096;
  static const int maxNoteLength = 8192;
  static const int maxVaultNameLength = 96;
  static const int maxShadowUnlockLimit = 9999;
  static const int minMasterPasswordLength = 14;
  static const double minMasterPasswordEntropyBits = 64;
  static const int defaultClipboardClearSeconds = 15;
  static const int minClipboardClearSeconds = 5;
  static const int maxClipboardClearSeconds = 120;
  static const int defaultAutoLockSeconds = 300;
  static const int minAutoLockSeconds = 30;
  static const int maxAutoLockSeconds = 3600;
  static const String cascadeVersion =
      'aes_serpent_camellia_serpent_kuznyechik_v1';
  static const String entryKeyVersion = 'context_digest_hmac_v2';
  static const String keyFileFormat = 'vocabulary_sleep_password_vault_key';
  static const String _primaryManifestPurpose = 'primary_manifest_v1';
  static const String _shadowManifestPurpose = 'shadow_manifest_v1';
  static final math.Random _secureRandom = math.Random.secure();

  final ToolboxCryptoService _cryptoService;

  ToolboxPasswordVaultSettings createSettings({
    required String name,
    ToolboxPasswordVaultStrength strength =
        ToolboxPasswordVaultStrength.enhanced,
    bool visible = true,
    bool deleteRequiresPassword = true,
    bool addEntryRequiresPassword = true,
    bool editEntryRequiresPassword = true,
    bool deleteEntryRequiresPassword = true,
    bool biometricGateEnabled = false,
    int clipboardClearSeconds = defaultClipboardClearSeconds,
    int autoLockSeconds = defaultAutoLockSeconds,
    String passwordHint = '',
    Uint8List? keyFileBytes,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final normalizedName = _normalizeVaultName(name);
    final normalizedPasswordHint = passwordHint.trim();
    _validateTextLength(normalizedPasswordHint, maxShortTextLength);
    _validateSafetySeconds(
      clipboardClearSeconds,
      min: minClipboardClearSeconds,
      max: maxClipboardClearSeconds,
    );
    _validateSafetySeconds(
      autoLockSeconds,
      min: minAutoLockSeconds,
      max: maxAutoLockSeconds,
    );
    return ToolboxPasswordVaultSettings(
      id: _randomId(),
      name: normalizedName,
      strength: strength,
      visible: visible,
      shadowEnabled: false,
      shadowMaxUnlocks: 0,
      shadowUnlocks: 0,
      keyFileSha256: _keyFileSha256(keyFileBytes),
      deleteRequiresPassword: deleteRequiresPassword,
      addEntryRequiresPassword: addEntryRequiresPassword,
      editEntryRequiresPassword: editEntryRequiresPassword,
      deleteEntryRequiresPassword: deleteEntryRequiresPassword,
      biometricGateEnabled: biometricGateEnabled,
      clipboardClearSeconds: clipboardClearSeconds,
      autoLockSeconds: autoLockSeconds,
      passwordHint: normalizedPasswordHint,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  ToolboxPasswordVaultSnapshot createVaultSnapshot({
    required String name,
    required String masterPassword,
    Uint8List? keyFileBytes,
    ToolboxPasswordVaultStrength strength =
        ToolboxPasswordVaultStrength.enhanced,
    bool visible = true,
    bool deleteRequiresPassword = true,
    bool addEntryRequiresPassword = true,
    bool editEntryRequiresPassword = true,
    bool deleteEntryRequiresPassword = true,
    bool biometricGateEnabled = false,
    int clipboardClearSeconds = defaultClipboardClearSeconds,
    int autoLockSeconds = defaultAutoLockSeconds,
    String passwordHint = '',
    bool allowWeakMasterPassword = false,
    DateTime? now,
  }) {
    _validateNewMasterPassword(
      masterPassword,
      allowWeak: allowWeakMasterPassword,
    );
    final settings = createSettings(
      name: name,
      strength: strength,
      visible: visible,
      deleteRequiresPassword: deleteRequiresPassword,
      addEntryRequiresPassword: addEntryRequiresPassword,
      editEntryRequiresPassword: editEntryRequiresPassword,
      deleteEntryRequiresPassword: deleteEntryRequiresPassword,
      biometricGateEnabled: biometricGateEnabled,
      clipboardClearSeconds: clipboardClearSeconds,
      autoLockSeconds: autoLockSeconds,
      passwordHint: passwordHint,
      keyFileBytes: keyFileBytes,
      now: now,
    );
    final verifier = _encryptVerifier(
      settings: settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'primary',
    );
    final snapshot = ToolboxPasswordVaultSnapshot(
      settings: settings,
      records: const <ToolboxPasswordVaultEncryptedRecord>[],
      shadowRecords: const <ToolboxPasswordVaultEncryptedRecord>[],
      primaryVerifier: verifier,
    );
    return protectManifest(
      snapshot: snapshot,
      primaryMasterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
    );
  }

  ToolboxPasswordVaultEntry createEntry({
    required String channel,
    required String account,
    required String password,
    required String hint,
    required String note,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return ToolboxPasswordVaultEntry(
      id: _randomId(),
      channel: channel.trim(),
      account: account.trim(),
      password: password,
      hint: hint.trim(),
      note: note.trim(),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  ToolboxPasswordVaultEncryptedRecord encryptEntry({
    required ToolboxPasswordVaultEntry entry,
    required String masterPassword,
    required ToolboxPasswordVaultSettings settings,
    Uint8List? keyFileBytes,
    ToolboxPasswordVaultStrength? strength,
    bool shadow = false,
  }) {
    _validateEntry(entry);
    _validateKeyFile(settings, keyFileBytes);
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    final effectiveStrength = strength ?? settings.strength;
    final contextSalt = _base64UrlNoPadding(_randomBytes(24));
    final metadataDigest = _entryMetadataDigest(
      entry: entry,
      contextSalt: contextSalt,
    );
    final secretDerivationContext = _secretDerivationContext();
    final cascade = selectCascadeForEntry(
      entry: entry,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
    );
    final cascadeFingerprint = _cascadeFingerprint(
      cascade: cascade,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
    );
    final indexBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(entry.toIndex(shadow: shadow))),
    );
    final passwordBytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'id': entry.id,
          'password': entry.password,
        }),
      ),
    );
    if (indexBytes.length > maxEntryPlainBytes ||
        passwordBytes.length > maxEntryPlainBytes) {
      throw const ToolboxPasswordVaultException('Vault entry is too large.');
    }
    final indexEnvelope = _encryptRecordPayload(
      plainBytes: indexBytes,
      entry: entry,
      settings: settings,
      masterPassword: effectiveMaster,
      keyFileBytes: keyFileBytes,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
      cascade: cascade,
      strength: effectiveStrength,
      purpose: 'index',
      mediaType: 'application/vnd.vocabulary-sleep.password-entry-index+json',
    );
    final passwordEnvelope = _encryptRecordPayload(
      plainBytes: passwordBytes,
      entry: entry,
      settings: settings,
      masterPassword: effectiveMaster,
      keyFileBytes: keyFileBytes,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
      cascade: cascade,
      strength: effectiveStrength,
      purpose: 'secret',
      mediaType: 'application/vnd.vocabulary-sleep.password-entry-secret+json',
    );
    return ToolboxPasswordVaultEncryptedRecord(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
      cascadeFingerprint: cascadeFingerprint,
      stageCount: cascade.length,
      strength: effectiveStrength,
      materialBits: effectiveStrength.materialBits,
      indexEnvelopeBase64: base64Encode(indexEnvelope.envelopeBytes),
      passwordEnvelopeBase64: base64Encode(passwordEnvelope.envelopeBytes),
    );
  }

  ToolboxPasswordVaultEntryIndex decryptRecordIndex({
    required ToolboxPasswordVaultEncryptedRecord record,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    Uint8List? keyFileBytes,
  }) {
    if (record.isLegacyFullEntry) {
      return decryptRecord(
        record: record,
        settings: settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
      ).toIndex();
    }
    final decoded = _decryptRecordPayload(
      record: record,
      settings: settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'index',
      envelopeBase64: record.indexEnvelopeBase64,
    );
    if (decoded is! Map<String, Object?>) {
      throw const ToolboxPasswordVaultException('Vault entry is invalid.');
    }
    final index = ToolboxPasswordVaultEntryIndex.fromJson(decoded);
    if (index.id != record.id) {
      throw const ToolboxPasswordVaultException('Vault entry is invalid.');
    }
    return index;
  }

  String decryptRecordPassword({
    required ToolboxPasswordVaultEncryptedRecord record,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    Uint8List? keyFileBytes,
  }) {
    if (record.isLegacyFullEntry) {
      return decryptRecord(
        record: record,
        settings: settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
      ).password;
    }
    final decoded = _decryptRecordPayload(
      record: record,
      settings: settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'secret',
      envelopeBase64: record.passwordEnvelopeBase64,
    );
    if (decoded is! Map<String, Object?> ||
        _readVaultString(decoded, 'id') != record.id) {
      throw const ToolboxPasswordVaultException('Vault entry is invalid.');
    }
    return _readVaultString(decoded, 'password');
  }

  ToolboxPasswordVaultEncryptedRecord updateRecordIndex({
    required ToolboxPasswordVaultEncryptedRecord record,
    required ToolboxPasswordVaultEntryIndex index,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    Uint8List? keyFileBytes,
  }) {
    if (record.isLegacyFullEntry || index.id != record.id) {
      throw const ToolboxPasswordVaultException('Vault entry is invalid.');
    }
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    _validateKeyFile(settings, keyFileBytes);
    final normalizedIndex = index.copyWith(
      channel: index.channel.trim(),
      account: index.account.trim(),
      hint: index.hint.trim(),
      note: index.note.trim(),
    );
    final indexBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(normalizedIndex.toJson())),
    );
    if (indexBytes.length > maxEntryPlainBytes) {
      throw const ToolboxPasswordVaultException('Vault entry is too large.');
    }
    final entryShell = ToolboxPasswordVaultEntry(
      id: record.id,
      channel: normalizedIndex.channel,
      account: normalizedIndex.account,
      password: '',
      hint: normalizedIndex.hint,
      note: normalizedIndex.note,
      createdAt: record.createdAt,
      updatedAt: normalizedIndex.updatedAt,
    );
    final indexEnvelope = _encryptRecordPayload(
      plainBytes: indexBytes,
      entry: entryShell,
      settings: settings,
      masterPassword: effectiveMaster,
      keyFileBytes: keyFileBytes,
      contextSalt: record.contextSalt,
      metadataDigest: record.metadataDigest,
      secretDerivationContext: record.secretDerivationContext,
      cascade: _cascadeForIndexRefresh(record: record, index: normalizedIndex),
      strength: record.strength,
      purpose: 'index',
      mediaType: 'application/vnd.vocabulary-sleep.password-entry-index+json',
    );
    return ToolboxPasswordVaultEncryptedRecord(
      id: record.id,
      createdAt: record.createdAt,
      updatedAt: normalizedIndex.updatedAt,
      contextSalt: record.contextSalt,
      metadataDigest: record.metadataDigest,
      secretDerivationContext: record.secretDerivationContext,
      cascadeFingerprint: record.cascadeFingerprint,
      stageCount: record.stageCount,
      strength: record.strength,
      materialBits: record.materialBits,
      indexEnvelopeBase64: base64Encode(indexEnvelope.envelopeBytes),
      passwordEnvelopeBase64: record.passwordEnvelopeBase64,
    );
  }

  ToolboxPasswordVaultEntry decryptRecord({
    required ToolboxPasswordVaultEncryptedRecord record,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    Uint8List? keyFileBytes,
  }) {
    if (record.isLegacyFullEntry) {
      final decoded = _decryptLegacyFullEntry(
        record: record,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
      );
      final entry = ToolboxPasswordVaultEntry.fromJson(decoded);
      if (entry.id != record.id) {
        throw const ToolboxPasswordVaultException('Vault entry is invalid.');
      }
      return entry;
    }
    final index = decryptRecordIndex(
      record: record,
      settings: settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
    );
    final password = decryptRecordPassword(
      record: record,
      settings: settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
    );
    return ToolboxPasswordVaultEntry(
      id: index.id,
      channel: index.channel,
      account: index.account,
      password: password,
      hint: index.hint,
      note: index.note,
      createdAt: index.createdAt,
      updatedAt: index.updatedAt,
    );
  }

  ToolboxPasswordVaultUnlockResult unlockVaultBytes({
    required Uint8List bytes,
    required String masterPassword,
    Uint8List? keyFileBytes,
  }) {
    final snapshot = decodeVaultBytes(bytes);
    final fileSha256 = _hexDigest(crypto.sha256.convert(bytes).bytes);
    if (snapshot.primaryVerifier == null) {
      return _unlockLegacyVault(
        snapshot: snapshot,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        fileSha256: fileSha256,
      );
    }
    final shadowVerifier = snapshot.shadowVerifier;
    if (snapshot.settings.shadowEnabled && shadowVerifier != null) {
      final shadowOk = _canDecryptVerifier(
        shadowVerifier,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        purpose: 'shadow',
      );
      if (shadowOk) {
        final manifestRequired = _verifierRequiresManifestAuth(
          shadowVerifier,
          settings: snapshot.settings,
          masterPassword: masterPassword,
          keyFileBytes: keyFileBytes,
          purpose: 'shadow',
        );
        _verifyManifestVerifier(
          snapshot: snapshot,
          masterPassword: masterPassword,
          keyFileBytes: keyFileBytes,
          scope: _ToolboxPasswordVaultManifestScope.shadow,
          required: manifestRequired,
        );
        final manifestAuthMigrated = !_hasManifestVerifier(
          snapshot,
          _ToolboxPasswordVaultManifestScope.shadow,
        );
        final indexes = _decryptRecordIndexes(
          records: snapshot.shadowRecords,
          settings: snapshot.settings,
          masterPassword: masterPassword,
          keyFileBytes: keyFileBytes,
        );
        final migratedShadowRecords = _migrateLegacyRecordDerivationContexts(
          records: snapshot.shadowRecords,
          settings: snapshot.settings,
          masterPassword: masterPassword,
          keyFileBytes: keyFileBytes,
          shadow: true,
        );
        final migrated = !identical(
          migratedShadowRecords,
          snapshot.shadowRecords,
        );
        final unlocks = snapshot.settings.shadowUnlocks + 1;
        final purgeTriggered =
            snapshot.settings.shadowMaxUnlocks > 0 &&
            unlocks >= snapshot.settings.shadowMaxUnlocks;
        final updatedSettings = snapshot.settings.copyWith(
          shadowUnlocks: unlocks,
          updatedAt: DateTime.now().toUtc(),
        );
        final updatedSnapshot = snapshot.copyWith(
          settings: updatedSettings,
          shadowRecords: migratedShadowRecords,
          records: purgeTriggered
              ? const <ToolboxPasswordVaultEncryptedRecord>[]
              : snapshot.records,
        );
        final protectedSnapshot = protectManifest(
          snapshot: updatedSnapshot,
          shadowMasterPassword: masterPassword,
          keyFileBytes: keyFileBytes,
        );
        return ToolboxPasswordVaultUnlockResult(
          snapshot: protectedSnapshot,
          indexes: indexes,
          fileSha256: fileSha256,
          mode: ToolboxPasswordVaultUnlockMode.shadow,
          shadowStateChanged: true,
          shadowPurgeTriggered: purgeTriggered,
          recordDerivationMigrated: migrated,
          manifestAuthMigrated: manifestAuthMigrated,
        );
      }
    }
    final primaryOk = _canDecryptVerifier(
      snapshot.primaryVerifier!,
      settings: snapshot.settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'primary',
    );
    if (primaryOk) {
      final manifestRequired = _verifierRequiresManifestAuth(
        snapshot.primaryVerifier!,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        purpose: 'primary',
      );
      _verifyManifestVerifier(
        snapshot: snapshot,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        scope: _ToolboxPasswordVaultManifestScope.primary,
        required: manifestRequired,
      );
      final manifestAuthMigrated = !_hasManifestVerifier(
        snapshot,
        _ToolboxPasswordVaultManifestScope.primary,
      );
      final indexes = _decryptRecordIndexes(
        records: snapshot.records,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
      );
      final migratedRecords = _migrateLegacyRecordDerivationContexts(
        records: snapshot.records,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        shadow: false,
      );
      final migrated = !identical(migratedRecords, snapshot.records);
      var resultSnapshot = migrated
          ? snapshot.copyWith(records: migratedRecords, legacyVersion: false)
          : snapshot;
      if (manifestAuthMigrated || migrated) {
        resultSnapshot = protectManifest(
          snapshot: resultSnapshot,
          primaryMasterPassword: masterPassword,
          keyFileBytes: keyFileBytes,
        );
      }
      return ToolboxPasswordVaultUnlockResult(
        snapshot: resultSnapshot,
        indexes: indexes,
        fileSha256: fileSha256,
        mode: ToolboxPasswordVaultUnlockMode.primary,
        shadowStateChanged: false,
        shadowPurgeTriggered: false,
        recordDerivationMigrated: migrated,
        manifestAuthMigrated: manifestAuthMigrated,
      );
    }
    throw const ToolboxPasswordVaultException(
      'Vault unlock failed. Check the master password, key file, or file integrity.',
    );
  }

  void verifyPrimaryVaultPasswordBytes({
    required Uint8List bytes,
    required String masterPassword,
    Uint8List? keyFileBytes,
  }) {
    final snapshot = decodeVaultBytes(bytes);
    if (snapshot.primaryVerifier == null) {
      _unlockLegacyVault(
        snapshot: snapshot,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        fileSha256: _hexDigest(crypto.sha256.convert(bytes).bytes),
      );
      return;
    }
    try {
      final decoded = _decryptVerifier(
        snapshot.primaryVerifier!,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        purpose: 'primary',
      );
      if (decoded['vaultId'] != snapshot.settings.id ||
          decoded['purpose'] != 'primary') {
        throw const ToolboxPasswordVaultException('Vault file is invalid.');
      }
      _verifyManifestVerifier(
        snapshot: snapshot,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        scope: _ToolboxPasswordVaultManifestScope.primary,
        required: decoded['manifestAuthVersion'] == 1,
      );
    } on ToolboxPasswordVaultException {
      rethrow;
    } on Object {
      throw const ToolboxPasswordVaultException(
        'Primary vault password verification failed. Check the primary master password, key file, or file integrity.',
      );
    }
  }

  ToolboxPasswordVaultSnapshot decodeVaultBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return createVaultSnapshot(
        name: 'My passwords',
        masterPassword: 'Temporary-empty-vault-2026!',
      );
    }
    if (bytes.length > maxVaultBytes) {
      throw const ToolboxPasswordVaultException('Vault file is too large.');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    if (decoded['format'] != format) {
      throw const ToolboxPasswordVaultException('Vault file is unsupported.');
    }
    final rawVersion = decoded['version'];
    if (rawVersion == legacyVersion) {
      return _decodeLegacyVault(decoded);
    }
    if (rawVersion != version) {
      throw const ToolboxPasswordVaultException('Vault file is unsupported.');
    }
    final settingsJson = decoded['settings'];
    if (settingsJson is! Map<String, Object?>) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    final settings = ToolboxPasswordVaultSettings.fromJson(settingsJson);
    final records = _readRecordList(decoded['records']);
    final shadowRecords = _readRecordList(decoded['shadowRecords']);
    return ToolboxPasswordVaultSnapshot(
      settings: settings,
      records: records,
      shadowRecords: shadowRecords,
      primaryVerifier: _readOptionalBlob(decoded, 'primaryVerifier'),
      shadowVerifier: _readOptionalBlob(decoded, 'shadowVerifier'),
      primaryManifestVerifier: _readOptionalBlob(
        decoded,
        'primaryManifestVerifier',
      ),
      shadowManifestVerifier: _readOptionalBlob(
        decoded,
        'shadowManifestVerifier',
      ),
      shadowSyncEnvelope: _readOptionalBlob(decoded, 'shadowSyncEnvelope'),
    );
  }

  Uint8List encodeVaultBytes(ToolboxPasswordVaultSnapshot snapshot) {
    if (snapshot.records.length > maxRecords ||
        snapshot.shadowRecords.length > maxRecords) {
      throw const ToolboxPasswordVaultException('Vault has too many records.');
    }
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'format': format,
          'version': version,
          'createdBy': 'vocabulary_sleep_app',
          'settings': snapshot.settings.toJson(),
          'primaryVerifier': snapshot.primaryVerifier?.toJson(),
          'shadowVerifier': snapshot.shadowVerifier?.toJson(),
          'primaryManifestVerifier': snapshot.primaryManifestVerifier?.toJson(),
          'shadowManifestVerifier': snapshot.shadowManifestVerifier?.toJson(),
          'records': snapshot.records
              .map((record) => record.toJson())
              .toList(growable: false),
          'shadowRecords': snapshot.shadowRecords
              .map((record) => record.toJson())
              .toList(growable: false),
        }),
      ),
    );
    if (bytes.length > maxVaultBytes) {
      throw const ToolboxPasswordVaultException('Vault file is too large.');
    }
    return bytes;
  }

  Uint8List createEmptyVaultBytes() {
    return encodeVaultBytes(
      createVaultSnapshot(
        name: 'My passwords',
        masterPassword: 'Temporary-empty-vault-2026!',
      ),
    );
  }

  Uint8List createIndependentKeyFileBytes() {
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'format': keyFileFormat,
          'version': 1,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'material': base64Encode(_randomBytes(256)),
        }),
      ),
    );
  }

  Uint8List normalizeImportedKeyFile(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > ToolboxCryptoService.maxKeyFileBytes) {
      throw const ToolboxPasswordVaultException('Key file is invalid.');
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, Object?> &&
          decoded['format'] == keyFileFormat) {
        final material = base64Decode(_readVaultString(decoded, 'material'));
        if (material.length < 64 || material.length > 4096) {
          throw const ToolboxPasswordVaultException('Key file is invalid.');
        }
        return Uint8List.fromList(material);
      }
    } on ToolboxPasswordVaultException {
      rethrow;
    } on Object {
      // Raw random files are allowed as independent key files.
    }
    return Uint8List.fromList(bytes);
  }

  String? keyFileSha256(Uint8List? keyFileBytes) =>
      _keyFileSha256(keyFileBytes);

  ToolboxPasswordVaultSnapshot protectManifest({
    required ToolboxPasswordVaultSnapshot snapshot,
    String? primaryMasterPassword,
    String? shadowMasterPassword,
    Uint8List? keyFileBytes,
  }) {
    var nextSnapshot = snapshot;
    if (primaryMasterPassword != null && snapshot.primaryVerifier != null) {
      _requirePrimaryVerifierPassword(
        snapshot: nextSnapshot,
        masterPassword: primaryMasterPassword,
        keyFileBytes: keyFileBytes,
      );
      final primaryVerifier = _encryptVerifier(
        settings: nextSnapshot.settings,
        masterPassword: primaryMasterPassword,
        keyFileBytes: keyFileBytes,
        purpose: 'primary',
      );
      nextSnapshot = nextSnapshot.copyWith(primaryVerifier: primaryVerifier);
      nextSnapshot = nextSnapshot.copyWith(
        primaryManifestVerifier: _encryptManifestVerifier(
          snapshot: nextSnapshot,
          masterPassword: primaryMasterPassword,
          keyFileBytes: keyFileBytes,
          scope: _ToolboxPasswordVaultManifestScope.primary,
        ),
        legacyVersion: false,
      );
    }
    if (shadowMasterPassword != null &&
        snapshot.settings.shadowEnabled &&
        snapshot.shadowVerifier != null) {
      _requireVerifierPassword(
        snapshot.shadowVerifier!,
        settings: nextSnapshot.settings,
        masterPassword: shadowMasterPassword,
        keyFileBytes: keyFileBytes,
        purpose: 'shadow',
      );
      final shadowVerifier = _encryptVerifier(
        settings: nextSnapshot.settings,
        masterPassword: shadowMasterPassword,
        keyFileBytes: keyFileBytes,
        purpose: 'shadow',
      );
      nextSnapshot = nextSnapshot.copyWith(shadowVerifier: shadowVerifier);
      nextSnapshot = nextSnapshot.copyWith(
        shadowManifestVerifier: _encryptManifestVerifier(
          snapshot: nextSnapshot,
          masterPassword: shadowMasterPassword,
          keyFileBytes: keyFileBytes,
          scope: _ToolboxPasswordVaultManifestScope.shadow,
        ),
        legacyVersion: false,
      );
    }
    return nextSnapshot;
  }

  ToolboxPasswordVaultMasterPasswordAssessment assessMasterPassword(
    String masterPassword,
  ) {
    final password = masterPassword.trim();
    final issues = <String>[];
    final runes = password.runes.toList(growable: false);
    final length = runes.length;
    var hasLower = false;
    var hasUpper = false;
    var hasDigit = false;
    var hasSymbol = false;
    var hasUnicode = false;
    for (final rune in runes) {
      if (rune >= 97 && rune <= 122) {
        hasLower = true;
      } else if (rune >= 65 && rune <= 90) {
        hasUpper = true;
      } else if (rune >= 48 && rune <= 57) {
        hasDigit = true;
      } else if (rune > 0x7f) {
        hasUnicode = true;
      } else if (!_isWhitespaceRune(rune)) {
        hasSymbol = true;
      }
    }
    final characterClasses = <bool>[
      hasLower,
      hasUpper,
      hasDigit,
      hasSymbol,
      hasUnicode,
    ].where((value) => value).length;
    var pool = 0;
    if (hasLower) {
      pool += 26;
    }
    if (hasUpper) {
      pool += 26;
    }
    if (hasDigit) {
      pool += 10;
    }
    if (hasSymbol) {
      pool += 33;
    }
    if (hasUnicode) {
      pool += 64;
    }
    final entropyBits = length == 0 || pool == 0
        ? 0.0
        : length * (math.log(pool) / math.ln2);
    final words = password
        .split(RegExp(r'\s+'))
        .where((word) => word.runes.length >= 3)
        .length;
    final passphraseEntropy = words >= 4 ? words * 13.0 : 0.0;
    final effectiveEntropy = math.max(entropyBits, passphraseEntropy);
    final compact = password.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const weakValues = <String>{
      'password',
      'password1',
      'password123',
      'masterpassword',
      'qwerty123',
      'letmein',
      'admin123',
      'welcome123',
      '1234567890',
    };
    if (length < minMasterPasswordLength) {
      issues.add('length');
    }
    if (characterClasses < 3 && words < 4) {
      issues.add('classes');
    }
    if (effectiveEntropy < minMasterPasswordEntropyBits) {
      issues.add('entropy');
    }
    if (weakValues.contains(compact) ||
        RegExp(r'^(.)\1{7,}$').hasMatch(compact) ||
        RegExp(r'^(0123456789|1234567890)+$').hasMatch(compact)) {
      issues.add('common');
    }
    return ToolboxPasswordVaultMasterPasswordAssessment(
      entropyBits: effectiveEntropy,
      characterClasses: characterClasses,
      issues: List<String>.unmodifiable(issues),
    );
  }

  ToolboxPasswordVaultSnapshot updateSettings({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String name,
    required ToolboxPasswordVaultStrength strength,
    required bool visible,
    required bool deleteRequiresPassword,
    required bool addEntryRequiresPassword,
    required bool editEntryRequiresPassword,
    required bool deleteEntryRequiresPassword,
    required bool biometricGateEnabled,
    required int clipboardClearSeconds,
    required int autoLockSeconds,
    required String passwordHint,
    required int shadowMaxUnlocks,
  }) {
    _validateVaultName(name);
    final normalizedPasswordHint = passwordHint.trim();
    _validateTextLength(normalizedPasswordHint, maxShortTextLength);
    _validateSafetySeconds(
      clipboardClearSeconds,
      min: minClipboardClearSeconds,
      max: maxClipboardClearSeconds,
    );
    _validateSafetySeconds(
      autoLockSeconds,
      min: minAutoLockSeconds,
      max: maxAutoLockSeconds,
    );
    if (shadowMaxUnlocks < 0 || shadowMaxUnlocks > maxShadowUnlockLimit) {
      throw const ToolboxPasswordVaultException(
        'Shadow unlock limit is invalid.',
      );
    }
    return snapshot.copyWith(
      settings: snapshot.settings.copyWith(
        name: name.trim(),
        strength: strength,
        visible: visible,
        deleteRequiresPassword: deleteRequiresPassword,
        addEntryRequiresPassword: addEntryRequiresPassword,
        editEntryRequiresPassword: editEntryRequiresPassword,
        deleteEntryRequiresPassword: deleteEntryRequiresPassword,
        biometricGateEnabled: biometricGateEnabled,
        clipboardClearSeconds: clipboardClearSeconds,
        autoLockSeconds: autoLockSeconds,
        passwordHint: normalizedPasswordHint,
        shadowMaxUnlocks: shadowMaxUnlocks,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  ToolboxPasswordVaultSnapshot changeMasterPassword({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String oldMasterPassword,
    required String newMasterPassword,
    Uint8List? oldKeyFileBytes,
    Uint8List? newKeyFileBytes,
    bool allowWeakNewMasterPassword = false,
  }) {
    _validateNewMasterPassword(
      newMasterPassword,
      allowWeak: allowWeakNewMasterPassword,
    );
    if (snapshot.primaryVerifier == null) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    if (!_canDecryptVerifier(
      snapshot.primaryVerifier!,
      settings: snapshot.settings,
      masterPassword: oldMasterPassword,
      keyFileBytes: oldKeyFileBytes,
      purpose: 'primary',
    )) {
      throw const ToolboxPasswordVaultException(
        'Vault unlock failed. Check the master password, key file, or file integrity.',
      );
    }
    final entries = snapshot.records
        .map(
          (record) => MapEntry(
            record,
            decryptRecord(
              record: record,
              settings: snapshot.settings,
              masterPassword: oldMasterPassword,
              keyFileBytes: oldKeyFileBytes,
            ),
          ),
        )
        .toList(growable: false);
    final timestamp = DateTime.now().toUtc();
    final updatedSettings = snapshot.settings.copyWith(
      keyFileSha256: _keyFileSha256(newKeyFileBytes),
      clearKeyFileSha256: newKeyFileBytes == null,
      updatedAt: timestamp,
    );
    final primaryVerifier = _encryptVerifier(
      settings: updatedSettings,
      masterPassword: newMasterPassword,
      keyFileBytes: newKeyFileBytes,
      purpose: 'primary',
    );
    final records = entries
        .map(
          (recordEntry) => encryptEntry(
            entry: recordEntry.value,
            masterPassword: newMasterPassword,
            settings: updatedSettings,
            keyFileBytes: newKeyFileBytes,
            strength: recordEntry.key.strength,
          ),
        )
        .toList(growable: false);
    final nextSnapshot = snapshot.copyWith(
      settings: updatedSettings,
      records: records,
      primaryVerifier: primaryVerifier,
      clearShadowManifestVerifier: true,
      clearShadowSyncEnvelope: true,
      legacyVersion: false,
    );
    return protectManifest(
      snapshot: nextSnapshot,
      primaryMasterPassword: newMasterPassword,
      keyFileBytes: newKeyFileBytes,
    );
  }

  ToolboxPasswordVaultSnapshot enableShadowVault({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String primaryMasterPassword,
    required String shadowMasterPassword,
    required int shadowMaxUnlocks,
    Uint8List? keyFileBytes,
    bool allowWeakShadowMasterPassword = false,
  }) {
    if (snapshot.primaryVerifier == null) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    _validateNewMasterPassword(
      shadowMasterPassword,
      allowWeak: allowWeakShadowMasterPassword,
    );
    if (shadowMaxUnlocks < 0 || shadowMaxUnlocks > maxShadowUnlockLimit) {
      throw const ToolboxPasswordVaultException(
        'Shadow unlock limit is invalid.',
      );
    }
    if (!_canDecryptVerifier(
      snapshot.primaryVerifier!,
      settings: snapshot.settings,
      masterPassword: primaryMasterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'primary',
    )) {
      throw const ToolboxPasswordVaultException(
        'Vault unlock failed. Check the master password, key file, or file integrity.',
      );
    }
    if (_effectiveMasterPassword(shadowMasterPassword) ==
        _effectiveMasterPassword(primaryMasterPassword)) {
      throw const ToolboxPasswordVaultException(
        'Shadow master password must differ from primary master password.',
      );
    }
    final updatedSettings = snapshot.settings.copyWith(
      shadowEnabled: true,
      shadowMaxUnlocks: shadowMaxUnlocks,
      shadowUnlocks: 0,
      updatedAt: DateTime.now().toUtc(),
    );
    final shadowVerifier = _encryptVerifier(
      settings: updatedSettings,
      masterPassword: shadowMasterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'shadow',
    );
    final shadowRecords = _buildShadowRecords(
      snapshot: snapshot,
      primaryMasterPassword: primaryMasterPassword,
      shadowMasterPassword: shadowMasterPassword,
      keyFileBytes: keyFileBytes,
      settings: updatedSettings,
    );
    final nextSnapshot = snapshot.copyWith(
      settings: updatedSettings,
      shadowRecords: shadowRecords,
      shadowVerifier: shadowVerifier,
      clearShadowSyncEnvelope: true,
      legacyVersion: false,
    );
    return protectManifest(
      snapshot: nextSnapshot,
      primaryMasterPassword: primaryMasterPassword,
      shadowMasterPassword: shadowMasterPassword,
      keyFileBytes: keyFileBytes,
    );
  }

  ToolboxPasswordVaultSnapshot disableShadowVault({
    required ToolboxPasswordVaultSnapshot snapshot,
  }) {
    return snapshot.copyWith(
      settings: snapshot.settings.copyWith(
        shadowEnabled: false,
        shadowMaxUnlocks: 0,
        shadowUnlocks: 0,
        updatedAt: DateTime.now().toUtc(),
      ),
      shadowRecords: const <ToolboxPasswordVaultEncryptedRecord>[],
      clearShadowVerifier: true,
      clearShadowManifestVerifier: true,
      clearShadowSyncEnvelope: true,
    );
  }

  ToolboxPasswordVaultSnapshot syncShadowVault({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String primaryMasterPassword,
    required String shadowMasterPassword,
    Uint8List? keyFileBytes,
  }) {
    if (!snapshot.settings.shadowEnabled) {
      return snapshot;
    }
    final shadowRecords = _buildShadowRecords(
      snapshot: snapshot,
      primaryMasterPassword: primaryMasterPassword,
      shadowMasterPassword: shadowMasterPassword,
      keyFileBytes: keyFileBytes,
      settings: snapshot.settings,
    );
    return protectManifest(
      snapshot: snapshot.copyWith(shadowRecords: shadowRecords),
      shadowMasterPassword: shadowMasterPassword,
      keyFileBytes: keyFileBytes,
    );
  }

  List<ToolboxCryptoCascadeCipher> selectCascadeForEntry({
    required ToolboxPasswordVaultEntry entry,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
  }) {
    final digest = crypto.sha256.convert(
      utf8.encode(
        [
          cascadeVersion,
          contextSalt,
          metadataDigest,
          secretDerivationContext,
          _canonicalEntryJson(entry),
        ].join('|'),
      ),
    );
    final bytes = digest.bytes;
    final stageCount = 3 + (bytes[0] % 3);
    const pool = <ToolboxCryptoCascadeCipher>[
      ToolboxCryptoCascadeCipher.aes,
      ToolboxCryptoCascadeCipher.serpent,
      ToolboxCryptoCascadeCipher.camellia,
      ToolboxCryptoCascadeCipher.serpent,
      ToolboxCryptoCascadeCipher.kuznyechik,
    ];
    final selected = <ToolboxCryptoCascadeCipher>[];
    for (var index = 0; selected.length < stageCount; index += 1) {
      final digestByte = bytes[(index + 1) % bytes.length];
      selected.add(pool[(digestByte + index * 7) % pool.length]);
    }
    _ensureMinimumUniqueStages(selected, bytes);
    return List<ToolboxCryptoCascadeCipher>.unmodifiable(selected);
  }

  String describeCascade(List<ToolboxCryptoCascadeCipher> cascade) {
    return cascade.map((cipher) => cipher.id).join(' -> ');
  }

  List<ToolboxCryptoCascadeCipher> _cascadeForIndexRefresh({
    required ToolboxPasswordVaultEncryptedRecord record,
    required ToolboxPasswordVaultEntryIndex index,
  }) {
    final digest = crypto.sha256.convert(
      utf8.encode(
        [
          'password-vault-index-refresh-v1',
          cascadeVersion,
          record.contextSalt,
          record.cascadeFingerprint,
          jsonEncode(index.toJson()),
        ].join('|'),
      ),
    );
    final bytes = digest.bytes;
    final stageCount = record.stageCount.clamp(3, 5);
    const pool = <ToolboxCryptoCascadeCipher>[
      ToolboxCryptoCascadeCipher.aes,
      ToolboxCryptoCascadeCipher.serpent,
      ToolboxCryptoCascadeCipher.camellia,
      ToolboxCryptoCascadeCipher.serpent,
      ToolboxCryptoCascadeCipher.kuznyechik,
    ];
    final selected = <ToolboxCryptoCascadeCipher>[];
    for (var offset = 0; selected.length < stageCount; offset += 1) {
      final digestByte = bytes[(offset + 3) % bytes.length];
      selected.add(pool[(digestByte + offset * 5) % pool.length]);
    }
    _ensureMinimumUniqueStages(selected, bytes);
    return List<ToolboxCryptoCascadeCipher>.unmodifiable(selected);
  }

  ToolboxPasswordVaultUnlockResult _unlockLegacyVault({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String fileSha256,
  }) {
    final indexes = _decryptRecordIndexes(
      records: snapshot.records,
      settings: snapshot.settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
    );
    final migratedRecords = _migrateLegacyRecordDerivationContexts(
      records: snapshot.records,
      settings: snapshot.settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      shadow: false,
    );
    final migrated = !identical(migratedRecords, snapshot.records);
    return ToolboxPasswordVaultUnlockResult(
      snapshot: migrated
          ? snapshot.copyWith(records: migratedRecords, legacyVersion: false)
          : snapshot,
      indexes: indexes,
      fileSha256: fileSha256,
      mode: ToolboxPasswordVaultUnlockMode.primary,
      shadowStateChanged: false,
      shadowPurgeTriggered: false,
      recordDerivationMigrated: migrated,
    );
  }

  List<ToolboxPasswordVaultEntryIndex> _decryptRecordIndexes({
    required List<ToolboxPasswordVaultEncryptedRecord> records,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
  }) {
    try {
      final indexes = records
          .map(
            (record) => decryptRecordIndex(
              record: record,
              settings: settings,
              masterPassword: masterPassword,
              keyFileBytes: keyFileBytes,
            ),
          )
          .toList(growable: false);
      indexes.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return indexes;
    } on Object {
      throw const ToolboxPasswordVaultException(
        'Vault unlock failed. Check the master password, key file, or file integrity.',
      );
    }
  }

  List<ToolboxPasswordVaultEncryptedRecord>
  _migrateLegacyRecordDerivationContexts({
    required List<ToolboxPasswordVaultEncryptedRecord> records,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required bool shadow,
  }) {
    if (!records.any((record) => record.legacySecretDerivationContext)) {
      return records;
    }
    try {
      return records
          .map((record) {
            if (!record.legacySecretDerivationContext) {
              return record;
            }
            final entry = decryptRecord(
              record: record,
              settings: settings,
              masterPassword: masterPassword,
              keyFileBytes: keyFileBytes,
            );
            return encryptEntry(
              entry: entry,
              masterPassword: masterPassword,
              settings: settings,
              keyFileBytes: keyFileBytes,
              strength: record.strength,
              shadow: shadow,
            );
          })
          .toList(growable: false);
    } on Object {
      throw const ToolboxPasswordVaultException(
        'Vault unlock failed. Check the master password, key file, or file integrity.',
      );
    }
  }

  ToolboxPasswordVaultSnapshot _decodeLegacyVault(
    Map<String, Object?> decoded,
  ) {
    final rawRecords = decoded['records'];
    if (rawRecords is! List<Object?> || rawRecords.length > maxRecords) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    final records = rawRecords
        .map((item) {
          if (item is! Map<String, Object?>) {
            throw const ToolboxPasswordVaultException(
              'Vault record is invalid.',
            );
          }
          return ToolboxPasswordVaultEncryptedRecord.fromJson(item);
        })
        .toList(growable: false);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final settings = ToolboxPasswordVaultSettings(
      id: 'legacy',
      name: 'My passwords',
      strength: ToolboxPasswordVaultStrength.enhanced,
      visible: true,
      shadowEnabled: false,
      shadowMaxUnlocks: 0,
      shadowUnlocks: 0,
      keyFileSha256: null,
      deleteRequiresPassword: true,
      addEntryRequiresPassword: true,
      editEntryRequiresPassword: true,
      deleteEntryRequiresPassword: true,
      biometricGateEnabled: false,
      clipboardClearSeconds: defaultClipboardClearSeconds,
      autoLockSeconds: defaultAutoLockSeconds,
      passwordHint: '',
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    return ToolboxPasswordVaultSnapshot(
      settings: settings,
      records: records,
      shadowRecords: const <ToolboxPasswordVaultEncryptedRecord>[],
      legacyVersion: true,
    );
  }

  List<ToolboxPasswordVaultEncryptedRecord> _readRecordList(Object? value) {
    final rawRecords = value;
    if (rawRecords == null) {
      return const <ToolboxPasswordVaultEncryptedRecord>[];
    }
    if (rawRecords is! List<Object?> || rawRecords.length > maxRecords) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    return rawRecords
        .map((item) {
          if (item is! Map<String, Object?>) {
            throw const ToolboxPasswordVaultException(
              'Vault record is invalid.',
            );
          }
          return ToolboxPasswordVaultEncryptedRecord.fromJson(item);
        })
        .toList(growable: false);
  }

  ToolboxCryptoEncryptResult _encryptRecordPayload({
    required Uint8List plainBytes,
    required ToolboxPasswordVaultEntry entry,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
    required List<ToolboxCryptoCascadeCipher> cascade,
    required ToolboxPasswordVaultStrength strength,
    required String purpose,
    required String mediaType,
  }) {
    final passphrase = _recordPassphrase(
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      vaultId: settings.id,
      id: entry.id,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
      purpose: purpose,
    );
    final internalKey = _recordKeyFileBytes(
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      vaultId: settings.id,
      id: entry.id,
      createdAt: entry.createdAt,
      contextSalt: contextSalt,
      metadataDigest: metadataDigest,
      secretDerivationContext: secretDerivationContext,
      purpose: purpose,
      length: strength == ToolboxPasswordVaultStrength.extreme ? 256 : 128,
    );
    return _cryptoService.encryptBytes(
      plainBytes: plainBytes,
      algorithm: ToolboxCryptoAlgorithm.customCascade,
      strength: strength.cryptoStrength,
      passphrase: passphrase,
      keyFileBytes: _combineKeyFiles(keyFileBytes, internalKey),
      fileName: 'password-entry-${entry.id}-$purpose.json',
      mediaType: mediaType,
      cascade: cascade,
      keyBits: strength.materialBits,
      macAlgorithm: ToolboxCryptoMacAlgorithm.sha256,
      signatureMode: ToolboxCryptoSignatureMode.ecdsaSha256,
    );
  }

  Object? _decryptRecordPayload({
    required ToolboxPasswordVaultEncryptedRecord record,
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String purpose,
    required String envelopeBase64,
  }) {
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    _validateKeyFile(settings, keyFileBytes);
    final passphrase = _recordPassphrase(
      masterPassword: effectiveMaster,
      keyFileBytes: keyFileBytes,
      vaultId: settings.id,
      id: record.id,
      contextSalt: record.contextSalt,
      metadataDigest: record.metadataDigest,
      secretDerivationContext: record.secretDerivationContext,
      purpose: purpose,
    );
    final internalKey = _recordKeyFileBytes(
      masterPassword: effectiveMaster,
      keyFileBytes: keyFileBytes,
      vaultId: settings.id,
      id: record.id,
      createdAt: record.createdAt,
      contextSalt: record.contextSalt,
      metadataDigest: record.metadataDigest,
      secretDerivationContext: record.secretDerivationContext,
      purpose: purpose,
      length: record.strength == ToolboxPasswordVaultStrength.extreme
          ? 256
          : 128,
    );
    try {
      final envelopeBytes = Uint8List.fromList(base64Decode(envelopeBase64));
      final decrypted = _cryptoService.decryptBytes(
        envelopeBytes: envelopeBytes,
        passphrase: passphrase,
        keyFileBytes: _combineKeyFiles(keyFileBytes, internalKey),
      );
      if (decrypted.plainBytes.length > maxEntryPlainBytes) {
        throw const ToolboxPasswordVaultException('Vault entry is too large.');
      }
      return jsonDecode(utf8.decode(decrypted.plainBytes));
    } on ToolboxPasswordVaultException {
      rethrow;
    } on Object {
      throw const ToolboxPasswordVaultException(
        'Vault record cannot be decrypted.',
      );
    }
  }

  Map<String, Object?> _decryptLegacyFullEntry({
    required ToolboxPasswordVaultEncryptedRecord record,
    required String masterPassword,
    required Uint8List? keyFileBytes,
  }) {
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    final passphrase = _legacyRecordPassphrase(
      effectiveMaster: effectiveMaster,
      id: record.id,
      contextSalt: record.contextSalt,
      metadataDigest: record.metadataDigest,
      secretDerivationContext: record.secretDerivationContext,
    );
    final internalKey = _legacyRecordKeyFileBytes(
      effectiveMaster: effectiveMaster,
      id: record.id,
      createdAt: record.createdAt,
      contextSalt: record.contextSalt,
      metadataDigest: record.metadataDigest,
      secretDerivationContext: record.secretDerivationContext,
      length: record.strength == ToolboxPasswordVaultStrength.extreme
          ? 256
          : 128,
    );
    try {
      final envelopeBytes = Uint8List.fromList(
        base64Decode(record.legacyEntryEnvelopeBase64 ?? ''),
      );
      final decrypted = _cryptoService.decryptBytes(
        envelopeBytes: envelopeBytes,
        passphrase: passphrase,
        keyFileBytes: _combineKeyFiles(keyFileBytes, internalKey),
      );
      if (decrypted.plainBytes.length > maxEntryPlainBytes) {
        throw const ToolboxPasswordVaultException('Vault entry is too large.');
      }
      final decoded = jsonDecode(utf8.decode(decrypted.plainBytes));
      if (decoded is! Map<String, Object?>) {
        throw const ToolboxPasswordVaultException('Vault entry is invalid.');
      }
      return decoded;
    } on ToolboxPasswordVaultException {
      rethrow;
    } on Object {
      throw const ToolboxPasswordVaultException(
        'Vault record cannot be decrypted.',
      );
    }
  }

  ToolboxPasswordVaultEncryptedBlob _encryptVerifier({
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String purpose,
  }) {
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    _validateKeyFile(settings, keyFileBytes);
    final contextSalt = _base64UrlNoPadding(_randomBytes(24));
    final plainBytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'format': 'password_vault_master_verifier',
          'vaultId': settings.id,
          'purpose': purpose,
          'manifestAuthVersion': 1,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );
    final encrypted = _cryptoService.encryptBytes(
      plainBytes: plainBytes,
      algorithm: ToolboxCryptoAlgorithm.customCascade,
      strength: settings.strength.cryptoStrength,
      passphrase: _vaultPassphrase(
        masterPassword: effectiveMaster,
        keyFileBytes: keyFileBytes,
        vaultId: settings.id,
        contextSalt: contextSalt,
        purpose: 'verifier-$purpose',
      ),
      keyFileBytes: _verifierKeyFileBytes(
        masterPassword: effectiveMaster,
        keyFileBytes: keyFileBytes,
        vaultId: settings.id,
        contextSalt: contextSalt,
        purpose: purpose,
      ),
      fileName: 'password-vault-verifier-$purpose.json',
      mediaType:
          'application/vnd.vocabulary-sleep.password-vault-verifier+json',
      cascade: const <ToolboxCryptoCascadeCipher>[
        ToolboxCryptoCascadeCipher.aes,
        ToolboxCryptoCascadeCipher.serpent,
        ToolboxCryptoCascadeCipher.camellia,
        ToolboxCryptoCascadeCipher.kuznyechik,
      ],
      keyBits: settings.strength.materialBits,
      macAlgorithm: ToolboxCryptoMacAlgorithm.sha256,
      signatureMode: ToolboxCryptoSignatureMode.ecdsaSha256,
    );
    return ToolboxPasswordVaultEncryptedBlob(
      contextSalt: contextSalt,
      envelopeBase64: base64Encode(encrypted.envelopeBytes),
    );
  }

  bool _canDecryptVerifier(
    ToolboxPasswordVaultEncryptedBlob verifier, {
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String purpose,
  }) {
    try {
      final decoded = _decryptVerifier(
        verifier,
        settings: settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        purpose: purpose,
      );
      return decoded['vaultId'] == settings.id && decoded['purpose'] == purpose;
    } on Object {
      return false;
    }
  }

  void _requireVerifierPassword(
    ToolboxPasswordVaultEncryptedBlob verifier, {
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String purpose,
  }) {
    try {
      final decoded = _decryptVerifier(
        verifier,
        settings: settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        purpose: purpose,
      );
      if (decoded['vaultId'] == settings.id && decoded['purpose'] == purpose) {
        return;
      }
    } on Object {
      // Normalize wrong-password and corrupt-envelope failures for callers.
    }
    throw const ToolboxPasswordVaultException(
      'Vault unlock failed. Check the master password, key file, or file integrity.',
    );
  }

  void _requirePrimaryVerifierPassword({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String masterPassword,
    required Uint8List? keyFileBytes,
  }) {
    final verifier = snapshot.primaryVerifier;
    if (verifier == null) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    _requireVerifierPassword(
      verifier,
      settings: snapshot.settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      purpose: 'primary',
    );
  }

  bool _verifierRequiresManifestAuth(
    ToolboxPasswordVaultEncryptedBlob verifier, {
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String purpose,
  }) {
    final decoded = _decryptVerifier(
      verifier,
      settings: settings,
      masterPassword: masterPassword,
      keyFileBytes: keyFileBytes,
      purpose: purpose,
    );
    return decoded['manifestAuthVersion'] == 1;
  }

  Map<String, Object?> _decryptVerifier(
    ToolboxPasswordVaultEncryptedBlob verifier, {
    required ToolboxPasswordVaultSettings settings,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String purpose,
  }) {
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    _validateKeyFile(settings, keyFileBytes);
    final envelopeBytes = Uint8List.fromList(
      base64Decode(verifier.envelopeBase64),
    );
    final decrypted = _cryptoService.decryptBytes(
      envelopeBytes: envelopeBytes,
      passphrase: _vaultPassphrase(
        masterPassword: effectiveMaster,
        keyFileBytes: keyFileBytes,
        vaultId: settings.id,
        contextSalt: verifier.contextSalt,
        purpose: 'verifier-$purpose',
      ),
      keyFileBytes: _verifierKeyFileBytes(
        masterPassword: effectiveMaster,
        keyFileBytes: keyFileBytes,
        vaultId: settings.id,
        contextSalt: verifier.contextSalt,
        purpose: purpose,
      ),
    );
    final decoded = jsonDecode(utf8.decode(decrypted.plainBytes));
    if (decoded is! Map<String, Object?>) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    return decoded;
  }

  ToolboxPasswordVaultEncryptedBlob _encryptManifestVerifier({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required _ToolboxPasswordVaultManifestScope scope,
  }) {
    final settings = snapshot.settings;
    final effectiveMaster = _effectiveMasterPassword(masterPassword);
    _validateKeyFile(settings, keyFileBytes);
    final contextSalt = _base64UrlNoPadding(_randomBytes(24));
    final purpose = scope.verifierPurpose;
    final plainBytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'format': 'password_vault_manifest_verifier',
          'vaultId': settings.id,
          'purpose': purpose,
          'scope': scope.id,
          'manifestDigest': _manifestDigest(snapshot, scope: scope),
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );
    final encrypted = _cryptoService.encryptBytes(
      plainBytes: plainBytes,
      algorithm: ToolboxCryptoAlgorithm.customCascade,
      strength: settings.strength.cryptoStrength,
      passphrase: _vaultPassphrase(
        masterPassword: effectiveMaster,
        keyFileBytes: keyFileBytes,
        vaultId: settings.id,
        contextSalt: contextSalt,
        purpose: 'verifier-$purpose',
      ),
      keyFileBytes: _verifierKeyFileBytes(
        masterPassword: effectiveMaster,
        keyFileBytes: keyFileBytes,
        vaultId: settings.id,
        contextSalt: contextSalt,
        purpose: purpose,
      ),
      fileName: 'password-vault-$purpose.json',
      mediaType:
          'application/vnd.vocabulary-sleep.password-vault-manifest+json',
      cascade: const <ToolboxCryptoCascadeCipher>[
        ToolboxCryptoCascadeCipher.aes,
        ToolboxCryptoCascadeCipher.serpent,
        ToolboxCryptoCascadeCipher.camellia,
        ToolboxCryptoCascadeCipher.kuznyechik,
      ],
      keyBits: settings.strength.materialBits,
      macAlgorithm: ToolboxCryptoMacAlgorithm.sha256,
      signatureMode: ToolboxCryptoSignatureMode.ecdsaSha256,
    );
    return ToolboxPasswordVaultEncryptedBlob(
      contextSalt: contextSalt,
      envelopeBase64: base64Encode(encrypted.envelopeBytes),
    );
  }

  bool _hasManifestVerifier(
    ToolboxPasswordVaultSnapshot snapshot,
    _ToolboxPasswordVaultManifestScope scope,
  ) {
    return switch (scope) {
      _ToolboxPasswordVaultManifestScope.primary =>
        snapshot.primaryManifestVerifier != null,
      _ToolboxPasswordVaultManifestScope.shadow =>
        snapshot.shadowManifestVerifier != null,
    };
  }

  void _verifyManifestVerifier({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required _ToolboxPasswordVaultManifestScope scope,
    required bool required,
  }) {
    final verifier = switch (scope) {
      _ToolboxPasswordVaultManifestScope.primary =>
        snapshot.primaryManifestVerifier,
      _ToolboxPasswordVaultManifestScope.shadow =>
        snapshot.shadowManifestVerifier,
    };
    if (verifier == null) {
      if (required) {
        throw const ToolboxPasswordVaultException('Vault file is invalid.');
      }
      return;
    }
    try {
      final decoded = _decryptVerifier(
        verifier,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: keyFileBytes,
        purpose: scope.verifierPurpose,
      );
      final expectedDigest = _manifestDigest(snapshot, scope: scope);
      if (decoded['format'] != 'password_vault_manifest_verifier' ||
          decoded['vaultId'] != snapshot.settings.id ||
          decoded['purpose'] != scope.verifierPurpose ||
          decoded['scope'] != scope.id ||
          decoded['manifestDigest'] != expectedDigest) {
        throw const ToolboxPasswordVaultException('Vault file is invalid.');
      }
    } on ToolboxPasswordVaultException {
      rethrow;
    } on Object {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
  }

  String _manifestDigest(
    ToolboxPasswordVaultSnapshot snapshot, {
    required _ToolboxPasswordVaultManifestScope scope,
  }) {
    return _hexDigest(
      crypto.sha256
          .convert(utf8.encode(jsonEncode(_manifestPayload(snapshot, scope))))
          .bytes,
    );
  }

  Map<String, Object?> _manifestPayload(
    ToolboxPasswordVaultSnapshot snapshot,
    _ToolboxPasswordVaultManifestScope scope,
  ) {
    final settingsJson = Map<String, Object?>.from(snapshot.settings.toJson());
    if (scope == _ToolboxPasswordVaultManifestScope.primary) {
      // Shadow unlock count is mutable from a shadow unlock without the primary
      // password; the shadow manifest scope authenticates that counter.
      settingsJson['shadowUnlocks'] = 0;
      settingsJson['updatedAt'] = 'shadow-mutable';
    }
    return switch (scope) {
      _ToolboxPasswordVaultManifestScope.primary => <String, Object?>{
        'format': format,
        'version': version,
        'createdBy': 'vocabulary_sleep_app',
        'scope': scope.id,
        'settings': settingsJson,
        'primaryVerifier': snapshot.primaryVerifier?.toJson(),
      },
      _ToolboxPasswordVaultManifestScope.shadow => <String, Object?>{
        'format': format,
        'version': version,
        'createdBy': 'vocabulary_sleep_app',
        'scope': scope.id,
        'settings': settingsJson,
        'shadowVerifier': snapshot.shadowVerifier?.toJson(),
        'shadowRecords': snapshot.shadowRecords
            .map((record) => record.toJson())
            .toList(growable: false),
      },
    };
  }

  List<ToolboxPasswordVaultEncryptedRecord> _buildShadowRecords({
    required ToolboxPasswordVaultSnapshot snapshot,
    required String primaryMasterPassword,
    required String shadowMasterPassword,
    required Uint8List? keyFileBytes,
    required ToolboxPasswordVaultSettings settings,
  }) {
    final entries = snapshot.records
        .map(
          (record) => decryptRecord(
            record: record,
            settings: snapshot.settings,
            masterPassword: primaryMasterPassword,
            keyFileBytes: keyFileBytes,
          ),
        )
        .toList(growable: false);
    return entries
        .map(
          (entry) => encryptEntry(
            entry: entry.copyWith(password: _randomFakePassword()),
            masterPassword: shadowMasterPassword,
            settings: settings,
            keyFileBytes: keyFileBytes,
            strength: settings.strength,
            shadow: true,
          ),
        )
        .toList(growable: false);
  }

  String _effectiveMasterPassword(String masterPassword) {
    if (masterPassword.trim().isEmpty) {
      throw const ToolboxPasswordVaultException('Master password is required.');
    }
    return masterPassword;
  }

  void _validateNewMasterPassword(
    String masterPassword, {
    bool allowWeak = false,
  }) {
    _effectiveMasterPassword(masterPassword);
    final assessment = assessMasterPassword(masterPassword);
    if (!allowWeak && !assessment.accepted) {
      throw const ToolboxPasswordVaultException(
        'Master password does not meet local strength requirements.',
      );
    }
  }

  void _validateSafetySeconds(
    int seconds, {
    required int min,
    required int max,
  }) {
    if (seconds < min || seconds > max) {
      throw const ToolboxPasswordVaultException(
        'Vault safety setting is invalid.',
      );
    }
  }

  bool _isWhitespaceRune(int rune) {
    return rune == 0x09 ||
        rune == 0x0a ||
        rune == 0x0b ||
        rune == 0x0c ||
        rune == 0x0d ||
        rune == 0x20;
  }

  String _entryMetadataDigest({
    required ToolboxPasswordVaultEntry entry,
    required String contextSalt,
  }) {
    final value = <String, Object?>{
      'contextSalt': contextSalt,
      'id': entry.id,
      'channel': entry.channel,
      'account': entry.account,
      'hint': entry.hint,
      'note': entry.note,
      'createdAt': entry.createdAt.toUtc().toIso8601String(),
      'updatedAt': entry.updatedAt.toUtc().toIso8601String(),
    };
    return _hexDigest(
      crypto.sha256.convert(utf8.encode(jsonEncode(value))).bytes,
    );
  }

  String _secretDerivationContext() => _hexDigest(_randomBytes(32));

  String _cascadeFingerprint({
    required List<ToolboxCryptoCascadeCipher> cascade,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
  }) {
    return _hexDigest(
      crypto.sha256
          .convert(
            utf8.encode(
              [
                cascadeVersion,
                contextSalt,
                metadataDigest,
                secretDerivationContext,
                describeCascade(cascade),
              ].join('|'),
            ),
          )
          .bytes,
    ).substring(0, 16);
  }

  String _recordPassphrase({
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String vaultId,
    required String id,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
    required String purpose,
  }) {
    final digest =
        crypto.Hmac(
              crypto.sha512,
              utf8.encode(
                '$masterPassword|${_keyFileSha256(keyFileBytes) ?? 'no-key'}',
              ),
            )
            .convert(
              utf8.encode(
                [
                  'password-vault-record-passphrase-v2',
                  vaultId,
                  purpose,
                  id,
                  contextSalt,
                  metadataDigest,
                  secretDerivationContext,
                ].join('|'),
              ),
            )
            .bytes;
    return _base64UrlNoPadding(digest);
  }

  Uint8List _recordKeyFileBytes({
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String vaultId,
    required String id,
    required DateTime createdAt,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
    required String purpose,
    required int length,
  }) {
    final seed =
        crypto.Hmac(
              crypto.sha512,
              utf8.encode(
                '$masterPassword|${_keyFileSha256(keyFileBytes) ?? 'no-key'}',
              ),
            )
            .convert(
              utf8.encode(
                [
                  entryKeyVersion,
                  vaultId,
                  purpose,
                  id,
                  createdAt.toUtc().toIso8601String(),
                  contextSalt,
                  metadataDigest,
                  secretDerivationContext,
                ].join('|'),
              ),
            )
            .bytes;
    return _expandSha256(seed, length);
  }

  String _vaultPassphrase({
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String vaultId,
    required String contextSalt,
    required String purpose,
  }) {
    final digest =
        crypto.Hmac(
              crypto.sha512,
              utf8.encode(
                '$masterPassword|${_keyFileSha256(keyFileBytes) ?? 'no-key'}',
              ),
            )
            .convert(
              utf8.encode(
                [
                  'password-vault-master-passphrase-v2',
                  vaultId,
                  contextSalt,
                  purpose,
                ].join('|'),
              ),
            )
            .bytes;
    return _base64UrlNoPadding(digest);
  }

  Uint8List _verifierKeyFileBytes({
    required String masterPassword,
    required Uint8List? keyFileBytes,
    required String vaultId,
    required String contextSalt,
    required String purpose,
  }) {
    final seed =
        crypto.Hmac(
              crypto.sha512,
              utf8.encode(
                '$masterPassword|${_keyFileSha256(keyFileBytes) ?? 'no-key'}',
              ),
            )
            .convert(
              utf8.encode(
                [
                  'password-vault-master-keyfile-v2',
                  vaultId,
                  contextSalt,
                  purpose,
                ].join('|'),
              ),
            )
            .bytes;
    return _combineKeyFiles(keyFileBytes, _expandSha256(seed, 128));
  }

  String _legacyRecordPassphrase({
    required String effectiveMaster,
    required String id,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
  }) {
    final digest = crypto.Hmac(crypto.sha512, utf8.encode(effectiveMaster))
        .convert(
          utf8.encode(
            [
              'password-vault-record-passphrase-v1',
              id,
              contextSalt,
              metadataDigest,
              secretDerivationContext,
            ].join('|'),
          ),
        )
        .bytes;
    return _base64UrlNoPadding(digest);
  }

  Uint8List _legacyRecordKeyFileBytes({
    required String effectiveMaster,
    required String id,
    required DateTime createdAt,
    required String contextSalt,
    required String metadataDigest,
    required String secretDerivationContext,
    required int length,
  }) {
    final seed = crypto.Hmac(crypto.sha512, utf8.encode(effectiveMaster))
        .convert(
          utf8.encode(
            [
              'context_digest_hmac_v1',
              id,
              createdAt.toUtc().toIso8601String(),
              contextSalt,
              metadataDigest,
              secretDerivationContext,
            ].join('|'),
          ),
        )
        .bytes;
    return _expandSha256(seed, length);
  }

  Uint8List _combineKeyFiles(Uint8List? external, Uint8List internal) {
    if (external == null || external.isEmpty) {
      return internal;
    }
    final externalHash = crypto.sha512.convert(external).bytes;
    final combined = crypto.Hmac(crypto.sha512, externalHash).convert(<int>[
      ...utf8.encode('password-vault-combined-key-v2'),
      ...internal,
    ]).bytes;
    return Uint8List.fromList(<int>[...combined, ...internal]);
  }

  Uint8List _expandSha256(List<int> seed, int length) {
    final output = BytesBuilder(copy: false);
    var counter = 0;
    while (output.length < length) {
      output.add(
        crypto.sha256.convert(<int>[
          ...utf8.encode('password-vault-expand-v2'),
          ...seed,
          (counter >> 24) & 0xff,
          (counter >> 16) & 0xff,
          (counter >> 8) & 0xff,
          counter & 0xff,
        ]).bytes,
      );
      counter += 1;
    }
    return Uint8List.fromList(output.takeBytes().sublist(0, length));
  }

  void _ensureMinimumUniqueStages(
    List<ToolboxCryptoCascadeCipher> selected,
    List<int> digestBytes,
  ) {
    const uniquePool = <ToolboxCryptoCascadeCipher>[
      ToolboxCryptoCascadeCipher.aes,
      ToolboxCryptoCascadeCipher.serpent,
      ToolboxCryptoCascadeCipher.camellia,
      ToolboxCryptoCascadeCipher.kuznyechik,
    ];
    final seen = selected.toSet();
    if (seen.length >= 3) {
      return;
    }
    final missing = uniquePool
        .where((cipher) => !seen.contains(cipher))
        .toList(growable: false);
    var replacementIndex = digestBytes[2] % selected.length;
    for (final cipher in missing) {
      if (selected.toSet().length >= 3) {
        return;
      }
      selected[replacementIndex] = cipher;
      replacementIndex = (replacementIndex + 1) % selected.length;
    }
  }

  void _validateEntry(ToolboxPasswordVaultEntry entry) {
    if (entry.channel.trim().isEmpty && entry.account.trim().isEmpty) {
      throw const ToolboxPasswordVaultException(
        'Website/channel or account is required.',
      );
    }
    _validateTextLength(entry.channel, maxShortTextLength);
    _validateTextLength(entry.account, maxShortTextLength);
    _validateTextLength(entry.hint, maxShortTextLength);
    _validateTextLength(entry.password, maxPasswordLength);
    _validateTextLength(entry.note, maxNoteLength);
    if (entry.password.isEmpty) {
      throw const ToolboxPasswordVaultException('Password is required.');
    }
  }

  void _validateVaultName(String name) {
    if (name.trim().isEmpty || name.runes.length > maxVaultNameLength) {
      throw const ToolboxPasswordVaultException('Vault name is invalid.');
    }
  }

  String _normalizeVaultName(String name) {
    _validateVaultName(name);
    return name.trim();
  }

  void _validateTextLength(String value, int maxLength) {
    if (value.runes.length > maxLength) {
      throw const ToolboxPasswordVaultException(
        'Vault entry text is too long.',
      );
    }
  }

  void _validateKeyFile(
    ToolboxPasswordVaultSettings settings,
    Uint8List? keyFileBytes,
  ) {
    final expected = settings.keyFileSha256;
    if (expected == null) {
      return;
    }
    if (_keyFileSha256(keyFileBytes) != expected) {
      throw const ToolboxPasswordVaultException(
        'Key file is required or does not match this vault.',
      );
    }
  }

  String _canonicalEntryJson(ToolboxPasswordVaultEntry entry) {
    return jsonEncode(<String, Object?>{
      'id': entry.id,
      'channel': entry.channel,
      'account': entry.account,
      'password': entry.password,
      'hint': entry.hint,
      'note': entry.note,
      'createdAt': entry.createdAt.toUtc().toIso8601String(),
      'updatedAt': entry.updatedAt.toUtc().toIso8601String(),
    });
  }

  String _randomFakePassword() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%+=?';
    final length = 24 + _secureRandom.nextInt(17);
    return String.fromCharCodes(
      List<int>.generate(
        length,
        (_) => alphabet.codeUnitAt(_secureRandom.nextInt(alphabet.length)),
      ),
    );
  }

  String _randomId() => _base64UrlNoPadding(_randomBytes(16));

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
    );
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String? _keyFileSha256(Uint8List? keyFileBytes) {
    if (keyFileBytes == null || keyFileBytes.isEmpty) {
      return null;
    }
    return _hexDigest(crypto.sha256.convert(keyFileBytes).bytes);
  }
}

enum _ToolboxPasswordVaultManifestScope { primary, shadow }

extension _ToolboxPasswordVaultManifestScopeInfo
    on _ToolboxPasswordVaultManifestScope {
  String get id {
    return switch (this) {
      _ToolboxPasswordVaultManifestScope.primary => 'primary',
      _ToolboxPasswordVaultManifestScope.shadow => 'shadow',
    };
  }

  String get verifierPurpose {
    return switch (this) {
      _ToolboxPasswordVaultManifestScope.primary =>
        ToolboxPasswordVaultService._primaryManifestPurpose,
      _ToolboxPasswordVaultManifestScope.shadow =>
        ToolboxPasswordVaultService._shadowManifestPurpose,
    };
  }
}

ToolboxPasswordVaultEncryptedBlob? _readOptionalBlob(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! Map<String, Object?>) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return ToolboxPasswordVaultEncryptedBlob.fromJson(value);
}

String _readVaultString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

String? _readOptionalVaultString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

String? _readOptionalVaultHex(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  final normalized = value.toLowerCase();
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return normalized;
}

String _readVaultHex(Map<String, Object?> json, String key, {int length = 64}) {
  final value = _readVaultString(json, key).toLowerCase();
  if (!RegExp('^[0-9a-f]{$length}\$').hasMatch(value)) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

class _RecordSecretDerivationContext {
  const _RecordSecretDerivationContext({
    required this.value,
    required this.legacy,
  });

  final String value;
  final bool legacy;
}

_RecordSecretDerivationContext _readRecordSecretDerivationContext(
  Map<String, Object?> json,
) {
  final current = json['secretDerivationContext'];
  if (current is String) {
    final normalized = current.toLowerCase();
    if (RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      return _RecordSecretDerivationContext(value: normalized, legacy: false);
    }
  }
  final legacy = json['passwordProfileDigest'];
  if (legacy is String) {
    final normalized = legacy.toLowerCase();
    if (RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      return _RecordSecretDerivationContext(value: normalized, legacy: true);
    }
  }
  throw const ToolboxPasswordVaultException('Vault file is invalid.');
}

int _readVaultInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

int? _readOptionalVaultInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

int _readBoundedOptionalVaultInt(
  Map<String, Object?> json,
  String key, {
  required int defaultValue,
  required int min,
  required int max,
}) {
  final value = _readOptionalVaultInt(json, key) ?? defaultValue;
  if (value < min || value > max) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

bool? _readOptionalVaultBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  return value;
}

DateTime _readVaultDate(Map<String, Object?> json, String key) {
  final value = _readVaultString(json, key);
  try {
    return DateTime.parse(value).toUtc();
  } on FormatException {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
}

ToolboxPasswordVaultStrength _readVaultStrength(
  Map<String, Object?> json,
  String key,
) {
  final value = _readVaultString(json, key);
  return switch (value) {
    'enhanced' => ToolboxPasswordVaultStrength.enhanced,
    'extreme' => ToolboxPasswordVaultStrength.extreme,
    _ => throw const ToolboxPasswordVaultException('Vault file is invalid.'),
  };
}

ToolboxCryptoKeyBits _readVaultMaterialBits(Map<String, Object?> json) {
  final raw = json['materialBits'] ?? json['keyBits'];
  if (raw is! String) {
    throw const ToolboxPasswordVaultException('Vault file is invalid.');
  }
  final value = raw;
  return switch (value) {
    '1024' => ToolboxCryptoKeyBits.bits1024,
    '2048' => ToolboxCryptoKeyBits.bits2048,
    _ => throw const ToolboxPasswordVaultException('Vault file is invalid.'),
  };
}

String _hexDigest(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

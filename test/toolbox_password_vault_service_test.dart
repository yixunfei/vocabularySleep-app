import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_crypto_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_password_vault_service.dart';

void main() {
  group('ToolboxPasswordVaultService', () {
    final service = ToolboxPasswordVaultService();

    test(
      'encrypts searchable indexes and decrypts passwords on demand without plaintext leaks',
      () {
        final base = service.createVaultSnapshot(
          name: 'Primary vault',
          masterPassword: 'Master-Passphrase-2026!Safe',
          strength: ToolboxPasswordVaultStrength.enhanced,
          now: DateTime.utc(2026, 6, 16, 8),
        );
        final entry = service.createEntry(
          channel: 'example.com',
          account: 'alice@example.com',
          password: 'S3rpent-Camellia-Kuznyechik!',
          hint: 'primary account',
          note: 'recovery mail is offline',
          now: DateTime.utc(2026, 6, 16, 8),
        );
        final record = service.encryptEntry(
          entry: entry,
          masterPassword: 'Master-Passphrase-2026!Safe',
          settings: base.settings,
        );

        expect(record.stageCount, inInclusiveRange(3, 5));
        expect(record.materialBits.bits, greaterThanOrEqualTo(1024));
        expect(
          record.indexEnvelopeBase64,
          isNot(record.passwordEnvelopeBase64),
        );
        final snapshot = base.copyWith(
          records: <ToolboxPasswordVaultEncryptedRecord>[record],
        );
        final bytes = service.encodeVaultBytes(snapshot);
        final lossyText = utf8.decode(bytes, allowMalformed: true);
        expect(lossyText, isNot(contains('example.com')));
        expect(lossyText, isNot(contains('alice@example.com')));
        expect(lossyText, isNot(contains('S3rpent-Camellia')));
        expect(lossyText, isNot(contains('passwordProfileDigest')));
        expect(lossyText, contains('secretDerivationContext'));
        expect(lossyText, contains('"materialBits"'));
        expect(lossyText, isNot(contains('"keyBits"')));

        final unlocked = service.unlockVaultBytes(
          bytes: bytes,
          masterPassword: 'Master-Passphrase-2026!Safe',
        );
        expect(unlocked.mode, ToolboxPasswordVaultUnlockMode.primary);
        expect(unlocked.indexes, hasLength(1));
        expect(unlocked.indexes.single.channel, 'example.com');
        expect(unlocked.indexes.single.account, 'alice@example.com');
        expect(unlocked.fileSha256, hasLength(64));

        final password = service.decryptRecordPassword(
          record: unlocked.snapshot.records.single,
          settings: unlocked.snapshot.settings,
          masterPassword: 'Master-Passphrase-2026!Safe',
        );
        expect(password, 'S3rpent-Camellia-Kuznyechik!');
      },
    );

    test('migrates legacy derivation metadata when unlocking', () {
      final base = service.createVaultSnapshot(
        name: 'Legacy metadata vault',
        masterPassword: 'Legacy-Metadata-2026!Safe',
      );
      final entry = service.createEntry(
        channel: 'legacy.example',
        account: 'legacy-user',
        password: 'legacy-secret-value',
        hint: 'legacy',
        note: '',
      );
      final record = service.encryptEntry(
        entry: entry,
        masterPassword: 'Legacy-Metadata-2026!Safe',
        settings: base.settings,
      );
      final snapshot = base.copyWith(
        records: <ToolboxPasswordVaultEncryptedRecord>[record],
      );
      final decoded =
          jsonDecode(utf8.decode(service.encodeVaultBytes(snapshot)))
              as Map<String, Object?>;
      final records = decoded['records']! as List<Object?>;
      final legacyRecord = Map<String, Object?>.from(
        records.single! as Map<String, Object?>,
      );
      final legacyDigest =
          legacyRecord.remove('secretDerivationContext')! as String;
      final legacyMaterialBits = legacyRecord.remove('materialBits')! as String;
      legacyRecord['passwordProfileDigest'] = legacyDigest;
      legacyRecord['keyBits'] = legacyMaterialBits;
      records[0] = legacyRecord;
      final legacyBytes = Uint8List.fromList(utf8.encode(jsonEncode(decoded)));
      final legacyText = utf8.decode(legacyBytes);
      expect(legacyText, contains('passwordProfileDigest'));
      expect(legacyText, contains('"keyBits"'));

      final unlocked = service.unlockVaultBytes(
        bytes: legacyBytes,
        masterPassword: 'Legacy-Metadata-2026!Safe',
      );
      expect(unlocked.recordDerivationMigrated, isTrue);
      expect(
        unlocked.snapshot.records.single.legacySecretDerivationContext,
        isFalse,
      );
      final migratedText = utf8.decode(
        service.encodeVaultBytes(unlocked.snapshot),
      );
      expect(migratedText, isNot(contains('passwordProfileDigest')));
      expect(migratedText, isNot(contains('"keyBits"')));
      expect(migratedText, contains('"materialBits"'));
      expect(migratedText, isNot(contains(legacyDigest)));
      expect(
        service.decryptRecordPassword(
          record: unlocked.snapshot.records.single,
          settings: unlocked.snapshot.settings,
          masterPassword: 'Legacy-Metadata-2026!Safe',
        ),
        'legacy-secret-value',
      );
    });

    test('rejects protected manifest settings tampering', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Protected manifest',
        masterPassword: 'Manifest-Master-2026!Safe',
        deleteRequiresPassword: true,
      );
      final decoded =
          jsonDecode(utf8.decode(service.encodeVaultBytes(snapshot)))
              as Map<String, Object?>;
      expect(decoded['primaryManifestVerifier'], isNotNull);

      final settings = Map<String, Object?>.from(
        decoded['settings']! as Map<String, Object?>,
      );
      settings['deleteRequiresPassword'] = false;
      decoded['settings'] = settings;
      final tamperedBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(decoded)),
      );

      expect(
        () => service.unlockVaultBytes(
          bytes: tamperedBytes,
          masterPassword: 'Manifest-Master-2026!Safe',
        ),
        throwsA(
          isA<ToolboxPasswordVaultException>().having(
            (error) => error.message,
            'message',
            contains('Vault file is invalid'),
          ),
        ),
      );
    });

    test('rejects protected manifest verifier removal', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Downgrade guard',
        masterPassword: 'Manifest-Master-2026!Safe',
      );
      final decoded =
          jsonDecode(utf8.decode(service.encodeVaultBytes(snapshot)))
              as Map<String, Object?>;
      decoded.remove('primaryManifestVerifier');
      final downgradedBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(decoded)),
      );

      expect(
        () => service.unlockVaultBytes(
          bytes: downgradedBytes,
          masterPassword: 'Manifest-Master-2026!Safe',
        ),
        throwsA(
          isA<ToolboxPasswordVaultException>().having(
            (error) => error.message,
            'message',
            contains('Vault file is invalid'),
          ),
        ),
      );
    });

    test('does not let entry confirmation password replace vault master', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Wrong confirmation guard',
        masterPassword: 'Correct-Master-2026!Safe',
      );
      final entry = service.createEntry(
        channel: 'mail',
        account: 'alice',
        password: 'Entry-Password-Should-Not-Become-Master',
        hint: '',
        note: '',
      );
      final wrongRecord = service.encryptEntry(
        entry: entry,
        masterPassword: 'Entry-Password-Should-Not-Become-Master',
        settings: snapshot.settings,
      );

      expect(
        () => service.protectManifest(
          snapshot: snapshot.copyWith(
            records: <ToolboxPasswordVaultEncryptedRecord>[wrongRecord],
          ),
          primaryMasterPassword: 'Entry-Password-Should-Not-Become-Master',
        ),
        throwsA(
          isA<ToolboxPasswordVaultException>().having(
            (error) => error.message,
            'message',
            contains('Vault unlock failed'),
          ),
        ),
      );
      expect(
        service
            .unlockVaultBytes(
              bytes: service.encodeVaultBytes(snapshot),
              masterPassword: 'Correct-Master-2026!Safe',
            )
            .mode,
        ToolboxPasswordVaultUnlockMode.primary,
      );
    });

    test('keeps secondary rules as human guidance only', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Rule vault',
        masterPassword: 'Memory-Passphrase-2026!Safe',
      );
      final entry = service.createEntry(
        channel: 'bank',
        account: 'alice',
        password: 'vault-secret-1',
        hint: 'branch',
        note: '',
        now: DateTime.utc(2026, 6, 16, 9),
      );
      const rule = ToolboxPasswordVaultAccessRule.prefixSuffix(
        prefix: 'pre-',
        suffix: '-post',
      );
      final record = service.encryptEntry(
        entry: entry,
        masterPassword: 'Memory-Passphrase-2026!Safe',
        settings: snapshot.settings,
      );
      final bytes = service.encodeVaultBytes(
        snapshot.copyWith(
          records: <ToolboxPasswordVaultEncryptedRecord>[record],
        ),
      );

      expect(
        rule.apply('Memory-Passphrase-2026!Safe'),
        'pre-Memory-Passphrase-2026!Safe-post',
      );
      expect(
        service
            .unlockVaultBytes(
              bytes: bytes,
              masterPassword: 'Memory-Passphrase-2026!Safe',
            )
            .indexes,
        hasLength(1),
      );
      expect(
        () => service.unlockVaultBytes(
          bytes: bytes,
          masterPassword: rule.apply('Memory-Passphrase-2026!Safe'),
        ),
        throwsA(isA<ToolboxPasswordVaultException>()),
      );
    });

    test('preserves per-record strength when the master password changes', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Mixed strength vault',
        masterPassword: 'Old-Master-2026!Safe',
        strength: ToolboxPasswordVaultStrength.enhanced,
      );
      final enhancedEntry = service.createEntry(
        channel: 'mail',
        account: 'enhanced-user',
        password: 'enhanced-secret',
        hint: '',
        note: '',
      );
      final extremeEntry = service.createEntry(
        channel: 'admin',
        account: 'extreme-user',
        password: 'extreme-secret',
        hint: '',
        note: '',
      );
      final enhancedRecord = service.encryptEntry(
        entry: enhancedEntry,
        masterPassword: 'Old-Master-2026!Safe',
        settings: snapshot.settings,
        strength: ToolboxPasswordVaultStrength.enhanced,
      );
      final extremeRecord = service.encryptEntry(
        entry: extremeEntry,
        masterPassword: 'Old-Master-2026!Safe',
        settings: snapshot.settings,
        strength: ToolboxPasswordVaultStrength.extreme,
      );
      final mixed = snapshot.copyWith(
        records: <ToolboxPasswordVaultEncryptedRecord>[
          enhancedRecord,
          extremeRecord,
        ],
      );

      expect(enhancedRecord.materialBits, ToolboxCryptoKeyBits.bits1024);
      expect(extremeRecord.materialBits, ToolboxCryptoKeyBits.bits2048);

      final changed = service.changeMasterPassword(
        snapshot: mixed,
        oldMasterPassword: 'Old-Master-2026!Safe',
        newMasterPassword: 'New-Master-2026!Safe',
      );
      final changedById = <String, ToolboxPasswordVaultEncryptedRecord>{
        for (final record in changed.records) record.id: record,
      };

      expect(
        changedById[enhancedEntry.id]!.strength,
        ToolboxPasswordVaultStrength.enhanced,
      );
      expect(
        changedById[enhancedEntry.id]!.materialBits,
        ToolboxCryptoKeyBits.bits1024,
      );
      expect(
        changedById[extremeEntry.id]!.strength,
        ToolboxPasswordVaultStrength.extreme,
      );
      expect(
        changedById[extremeEntry.id]!.materialBits,
        ToolboxCryptoKeyBits.bits2048,
      );
      expect(
        service.decryptRecordPassword(
          record: changedById[extremeEntry.id]!,
          settings: changed.settings,
          masterPassword: 'New-Master-2026!Safe',
        ),
        'extreme-secret',
      );
    });

    test(
      'requires matching independent key file and supports master changes',
      () {
        final rawKeyFile = service.createIndependentKeyFileBytes();
        final keyFile = service.normalizeImportedKeyFile(rawKeyFile);
        final snapshot = service.createVaultSnapshot(
          name: 'Keyed vault',
          masterPassword: 'Old-Master-2026!Safe',
          keyFileBytes: keyFile,
        );
        final entry = service.createEntry(
          channel: 'mail',
          account: 'user',
          password: 'P@ssw0rd-2026',
          hint: '',
          note: '',
        );
        final record = service.encryptEntry(
          entry: entry,
          masterPassword: 'Old-Master-2026!Safe',
          settings: snapshot.settings,
          keyFileBytes: keyFile,
        );
        final bytes = service.encodeVaultBytes(
          snapshot.copyWith(
            records: <ToolboxPasswordVaultEncryptedRecord>[record],
          ),
        );

        expect(
          () => service.unlockVaultBytes(
            bytes: bytes,
            masterPassword: 'Old-Master-2026!Safe',
          ),
          throwsA(isA<ToolboxPasswordVaultException>()),
        );
        expect(
          service
              .unlockVaultBytes(
                bytes: bytes,
                masterPassword: 'Old-Master-2026!Safe',
                keyFileBytes: keyFile,
              )
              .indexes,
          hasLength(1),
        );

        final changed = service.changeMasterPassword(
          snapshot: service.decodeVaultBytes(bytes),
          oldMasterPassword: 'Old-Master-2026!Safe',
          newMasterPassword: 'New-Master-2026!Safe',
          oldKeyFileBytes: keyFile,
          newKeyFileBytes: keyFile,
        );
        final changedBytes = service.encodeVaultBytes(changed);
        expect(
          () => service.unlockVaultBytes(
            bytes: changedBytes,
            masterPassword: 'Old-Master-2026!Safe',
            keyFileBytes: keyFile,
          ),
          throwsA(isA<ToolboxPasswordVaultException>()),
        );
        expect(
          service
              .unlockVaultBytes(
                bytes: changedBytes,
                masterPassword: 'New-Master-2026!Safe',
                keyFileBytes: keyFile,
              )
              .indexes,
          hasLength(1),
        );
      },
    );

    test('creates shadow vaults and purges primary records after limit', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Shadowed',
        masterPassword: 'Real-Master-2026!Safe',
      );
      final entry = service.createEntry(
        channel: 'admin',
        account: 'root',
        password: 'real-secret',
        hint: 'real',
        note: 'protected',
      );
      final record = service.encryptEntry(
        entry: entry,
        masterPassword: 'Real-Master-2026!Safe',
        settings: snapshot.settings,
      );
      final withRecord = snapshot.copyWith(
        records: <ToolboxPasswordVaultEncryptedRecord>[record],
      );
      expect(
        () => service.enableShadowVault(
          snapshot: withRecord,
          primaryMasterPassword: 'Real-Master-2026!Safe',
          shadowMasterPassword: 'Real-Master-2026!Safe',
          shadowMaxUnlocks: 2,
        ),
        throwsA(isA<ToolboxPasswordVaultException>()),
      );
      final shadowed = service.enableShadowVault(
        snapshot: withRecord,
        primaryMasterPassword: 'Real-Master-2026!Safe',
        shadowMasterPassword: 'Shadow-Master-2026!Safe',
        shadowMaxUnlocks: 2,
      );
      final shadowedJson = utf8.decode(service.encodeVaultBytes(shadowed));
      expect(shadowedJson, isNot(contains('shadowSyncEnvelope')));
      expect(shadowedJson, isNot(contains('Shadow-Master-2026!Safe')));

      final primary = service.unlockVaultBytes(
        bytes: service.encodeVaultBytes(shadowed),
        masterPassword: 'Real-Master-2026!Safe',
      );
      expect(primary.mode, ToolboxPasswordVaultUnlockMode.primary);
      expect(primary.indexes, hasLength(1));

      final firstShadow = service.unlockVaultBytes(
        bytes: service.encodeVaultBytes(shadowed),
        masterPassword: 'Shadow-Master-2026!Safe',
      );
      expect(firstShadow.mode, ToolboxPasswordVaultUnlockMode.shadow);
      expect(firstShadow.shadowStateChanged, isTrue);
      expect(firstShadow.shadowPurgeTriggered, isFalse);
      final fakePassword = service.decryptRecordPassword(
        record: firstShadow.snapshot.shadowRecords.single,
        settings: firstShadow.snapshot.settings,
        masterPassword: 'Shadow-Master-2026!Safe',
      );
      expect(fakePassword, isNot('real-secret'));

      final secondShadow = service.unlockVaultBytes(
        bytes: service.encodeVaultBytes(firstShadow.snapshot),
        masterPassword: 'Shadow-Master-2026!Safe',
      );
      expect(secondShadow.shadowPurgeTriggered, isTrue);
      expect(secondShadow.snapshot.records, isEmpty);
      expect(secondShadow.snapshot.shadowRecords, isNotEmpty);
    });

    test('rejects protected shadow manifest counter tampering', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Shadow tamper vault',
        masterPassword: 'Real-Master-2026!Safe',
      );
      final shadowed = service.enableShadowVault(
        snapshot: snapshot,
        primaryMasterPassword: 'Real-Master-2026!Safe',
        shadowMasterPassword: 'Shadow-Master-2026!Safe',
        shadowMaxUnlocks: 2,
      );
      final decoded =
          jsonDecode(utf8.decode(service.encodeVaultBytes(shadowed)))
              as Map<String, Object?>;
      expect(decoded['shadowManifestVerifier'], isNotNull);
      final settings = Map<String, Object?>.from(
        decoded['settings']! as Map<String, Object?>,
      );
      settings['shadowUnlocks'] = 1;
      decoded['settings'] = settings;
      final tamperedBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(decoded)),
      );

      expect(
        () => service.unlockVaultBytes(
          bytes: tamperedBytes,
          masterPassword: 'Shadow-Master-2026!Safe',
        ),
        throwsA(
          isA<ToolboxPasswordVaultException>().having(
            (error) => error.message,
            'message',
            contains('Vault file is invalid'),
          ),
        ),
      );
    });

    test('requires primary password for destructive vault verification', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Delete guarded',
        masterPassword: 'Real-Master-2026!Safe',
      );
      final entry = service.createEntry(
        channel: 'admin',
        account: 'root',
        password: 'real-secret',
        hint: 'real',
        note: 'protected',
      );
      final record = service.encryptEntry(
        entry: entry,
        masterPassword: 'Real-Master-2026!Safe',
        settings: snapshot.settings,
      );
      final withRecord = snapshot.copyWith(
        records: <ToolboxPasswordVaultEncryptedRecord>[record],
      );
      final shadowed = service.enableShadowVault(
        snapshot: withRecord,
        primaryMasterPassword: 'Real-Master-2026!Safe',
        shadowMasterPassword: 'Shadow-Master-2026!Safe',
        shadowMaxUnlocks: 0,
      );
      final bytes = service.encodeVaultBytes(shadowed);

      expect(
        () => service.verifyPrimaryVaultPasswordBytes(
          bytes: bytes,
          masterPassword: 'Shadow-Master-2026!Safe',
        ),
        throwsA(
          isA<ToolboxPasswordVaultException>().having(
            (error) => error.message,
            'message',
            contains('Primary vault password verification failed'),
          ),
        ),
      );
      expect(
        () => service.verifyPrimaryVaultPasswordBytes(
          bytes: bytes,
          masterPassword: 'Real-Master-2026!Safe',
        ),
        returnsNormally,
      );
    });

    test('persists delete policy and password hint settings', () {
      final defaults = service.createVaultSnapshot(
        name: 'Default policy',
        masterPassword: 'Policy-Master-2026!Safe',
      );
      expect(defaults.settings.deleteRequiresPassword, isTrue);
      expect(defaults.settings.addEntryRequiresPassword, isTrue);
      expect(defaults.settings.editEntryRequiresPassword, isTrue);
      expect(defaults.settings.deleteEntryRequiresPassword, isTrue);
      expect(defaults.settings.biometricGateEnabled, isFalse);
      expect(
        defaults.settings.clipboardClearSeconds,
        ToolboxPasswordVaultService.defaultClipboardClearSeconds,
      );
      expect(
        defaults.settings.autoLockSeconds,
        ToolboxPasswordVaultService.defaultAutoLockSeconds,
      );
      expect(defaults.settings.passwordHint, isEmpty);

      expect(
        () => service.createVaultSnapshot(
          name: 'Weak policy',
          masterPassword: 'password',
        ),
        throwsA(
          isA<ToolboxPasswordVaultException>().having(
            (error) => error.message,
            'message',
            contains('strength requirements'),
          ),
        ),
      );
      final weakAllowed = service.createVaultSnapshot(
        name: 'Weak allowed',
        masterPassword: 'password',
        allowWeakMasterPassword: true,
      );
      expect(weakAllowed.settings.name, 'Weak allowed');

      final snapshot = service.createVaultSnapshot(
        name: 'Policy vault',
        masterPassword: 'Policy-Master-2026!Safe',
        deleteRequiresPassword: false,
        addEntryRequiresPassword: false,
        editEntryRequiresPassword: false,
        deleteEntryRequiresPassword: false,
        biometricGateEnabled: true,
        clipboardClearSeconds: 30,
        autoLockSeconds: 900,
        passwordHint: '  offline clue  ',
      );
      expect(snapshot.settings.deleteRequiresPassword, isFalse);
      expect(snapshot.settings.addEntryRequiresPassword, isFalse);
      expect(snapshot.settings.editEntryRequiresPassword, isFalse);
      expect(snapshot.settings.deleteEntryRequiresPassword, isFalse);
      expect(snapshot.settings.biometricGateEnabled, isTrue);
      expect(snapshot.settings.clipboardClearSeconds, 30);
      expect(snapshot.settings.autoLockSeconds, 900);
      expect(snapshot.settings.passwordHint, 'offline clue');

      final decoded = service.decodeVaultBytes(
        service.encodeVaultBytes(snapshot),
      );
      expect(decoded.settings.deleteRequiresPassword, isFalse);
      expect(decoded.settings.addEntryRequiresPassword, isFalse);
      expect(decoded.settings.editEntryRequiresPassword, isFalse);
      expect(decoded.settings.deleteEntryRequiresPassword, isFalse);
      expect(decoded.settings.biometricGateEnabled, isTrue);
      expect(decoded.settings.clipboardClearSeconds, 30);
      expect(decoded.settings.autoLockSeconds, 900);
      expect(decoded.settings.passwordHint, 'offline clue');

      final updated = service.updateSettings(
        snapshot: decoded,
        name: 'Policy vault',
        strength: decoded.settings.strength,
        visible: decoded.settings.visible,
        deleteRequiresPassword: true,
        addEntryRequiresPassword: true,
        editEntryRequiresPassword: true,
        deleteEntryRequiresPassword: true,
        biometricGateEnabled: false,
        clipboardClearSeconds: 60,
        autoLockSeconds: 1800,
        passwordHint: '  memory card  ',
        shadowMaxUnlocks: decoded.settings.shadowMaxUnlocks,
      );
      expect(updated.settings.deleteRequiresPassword, isTrue);
      expect(updated.settings.addEntryRequiresPassword, isTrue);
      expect(updated.settings.editEntryRequiresPassword, isTrue);
      expect(updated.settings.deleteEntryRequiresPassword, isTrue);
      expect(updated.settings.biometricGateEnabled, isFalse);
      expect(updated.settings.clipboardClearSeconds, 60);
      expect(updated.settings.autoLockSeconds, 1800);
      expect(updated.settings.passwordHint, 'memory card');

      final legacySettings =
          ToolboxPasswordVaultSettings.fromJson(<String, Object?>{
            'id': 'legacy-id',
            'name': 'Legacy',
            'strength': ToolboxPasswordVaultStrength.enhanced.id,
            'createdAt': DateTime.utc(2026, 6, 16).toIso8601String(),
            'updatedAt': DateTime.utc(2026, 6, 16).toIso8601String(),
          });
      expect(legacySettings.deleteRequiresPassword, isTrue);
      expect(legacySettings.addEntryRequiresPassword, isTrue);
      expect(legacySettings.editEntryRequiresPassword, isTrue);
      expect(legacySettings.deleteEntryRequiresPassword, isTrue);
      expect(legacySettings.biometricGateEnabled, isFalse);
      expect(
        legacySettings.clipboardClearSeconds,
        ToolboxPasswordVaultService.defaultClipboardClearSeconds,
      );
      expect(
        legacySettings.autoLockSeconds,
        ToolboxPasswordVaultService.defaultAutoLockSeconds,
      );
      expect(legacySettings.passwordHint, isEmpty);
    });

    test('allows weak replacement passwords only with explicit override', () {
      final snapshot = service.createVaultSnapshot(
        name: 'Weak override',
        masterPassword: 'Strong-Master-2026!Safe',
      );
      expect(
        () => service.changeMasterPassword(
          snapshot: snapshot,
          oldMasterPassword: 'Strong-Master-2026!Safe',
          newMasterPassword: 'password',
        ),
        throwsA(isA<ToolboxPasswordVaultException>()),
      );

      final changed = service.changeMasterPassword(
        snapshot: snapshot,
        oldMasterPassword: 'Strong-Master-2026!Safe',
        newMasterPassword: 'password',
        allowWeakNewMasterPassword: true,
      );
      service.verifyPrimaryVaultPasswordBytes(
        bytes: service.encodeVaultBytes(changed),
        masterPassword: 'password',
      );

      final shadowed = service.enableShadowVault(
        snapshot: snapshot,
        primaryMasterPassword: 'Strong-Master-2026!Safe',
        shadowMasterPassword: 'password',
        shadowMaxUnlocks: 1,
        allowWeakShadowMasterPassword: true,
      );
      expect(shadowed.settings.shadowEnabled, isTrue);
    });

    test(
      'updates searchable index without re-encrypting password envelope',
      () {
        final snapshot = service.createVaultSnapshot(
          name: 'Fast edit',
          masterPassword: 'Real-Master-2026!Safe',
        );
        final entry = service.createEntry(
          channel: 'mail',
          account: 'alice',
          password: 'stable-secret',
          hint: 'old hint',
          note: 'old note',
          now: DateTime.utc(2026, 6, 16, 12),
        );
        final record = service.encryptEntry(
          entry: entry,
          masterPassword: 'Real-Master-2026!Safe',
          settings: snapshot.settings,
        );
        final updatedIndex = entry.toIndex().copyWith(
          account: 'alice-renamed',
          hint: 'new hint',
          note: 'new note',
          updatedAt: DateTime.utc(2026, 6, 16, 13),
        );

        final updatedRecord = service.updateRecordIndex(
          record: record,
          index: updatedIndex,
          settings: snapshot.settings,
          masterPassword: 'Real-Master-2026!Safe',
        );

        expect(
          updatedRecord.passwordEnvelopeBase64,
          record.passwordEnvelopeBase64,
        );
        expect(updatedRecord.contextSalt, record.contextSalt);
        expect(updatedRecord.metadataDigest, record.metadataDigest);
        final decryptedIndex = service.decryptRecordIndex(
          record: updatedRecord,
          settings: snapshot.settings,
          masterPassword: 'Real-Master-2026!Safe',
        );
        expect(decryptedIndex.account, 'alice-renamed');
        expect(decryptedIndex.hint, 'new hint');
        expect(
          service.decryptRecordPassword(
            record: updatedRecord,
            settings: snapshot.settings,
            masterPassword: 'Real-Master-2026!Safe',
          ),
          'stable-secret',
        );
      },
    );

    test('supports substitution and shift tutorial helpers', () {
      const substitution = ToolboxPasswordVaultAccessRule.substitution(
        substitutionFrom: 'aeo',
        substitutionTo: '@30',
      );
      final shifted = const ToolboxPasswordVaultAccessRule.shift(
        shift: 2,
      ).apply('Az09!');

      expect(substitution.apply('memory'), 'm3m0ry');
      expect(shifted, 'Cb21!');
    });

    test('selects deterministic cascades from the requested algorithm pool', () {
      final entry = service.createEntry(
        channel: 'mail',
        account: 'user',
        password: 'P@ssw0rd-2026',
        hint: '',
        note: '',
        now: DateTime.utc(2026, 6, 16, 10),
      );
      final cascade = service.selectCascadeForEntry(
        entry: entry,
        contextSalt: 'stable-context',
        metadataDigest:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        secretDerivationContext:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      );
      final repeated = service.selectCascadeForEntry(
        entry: entry,
        contextSalt: 'stable-context',
        metadataDigest:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        secretDerivationContext:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      );

      expect(cascade, repeated);
      expect(cascade.length, inInclusiveRange(3, 5));
      expect(cascade.toSet().length, greaterThanOrEqualTo(3));
      expect(
        cascade.every(
          (cipher) => <String>{
            'aes_gcm',
            'serpent_gcm',
            'camellia_gcm',
            'kuznyechik_gcm',
          }.contains(cipher.id),
        ),
        isTrue,
      );
    });

    test('rejects unsupported or oversized vault files', () {
      final unsupported = Uint8List.fromList(
        utf8.encode(
          jsonEncode(<String, Object?>{'format': 'other', 'version': 2}),
        ),
      );
      expect(
        () => service.decodeVaultBytes(unsupported),
        throwsA(isA<ToolboxPasswordVaultException>()),
      );
      expect(
        () => service.decodeVaultBytes(
          Uint8List(ToolboxPasswordVaultService.maxVaultBytes + 1),
        ),
        throwsA(isA<ToolboxPasswordVaultException>()),
      );
    });
  });
}

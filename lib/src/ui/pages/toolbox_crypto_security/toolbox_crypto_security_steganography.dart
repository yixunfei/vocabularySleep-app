part of '../toolbox_crypto_security.dart';

enum _StegoMode { embed, reveal }

enum _CryptoWorkspace { steganography, file, hash }

enum _FileCryptoMode { encrypt, decrypt }

class _DecodeFailureStatus {
  const _DecodeFailureStatus({
    required this.windowCount,
    required this.locked,
    this.remaining,
  });

  final int windowCount;
  final bool locked;
  final Duration? remaining;
}

class _StegoEmbedTextRequest {
  const _StegoEmbedTextRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.text,
    required this.dualLayerEnabled,
    required this.coverText,
    required this.encryption,
    required this.passphrase,
    required this.coverPassphrase,
    required this.strength,
    required this.keyFileBytes,
    required this.sourceExtension,
    required this.cascade,
    required this.keyBits,
    required this.macAlgorithm,
    required this.signatureMode,
    required this.maxErrorAttempts,
    required this.maxSuccessfulReveals,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final String text;
  final bool dualLayerEnabled;
  final String coverText;
  final ToolboxCryptoAlgorithm encryption;
  final String passphrase;
  final String coverPassphrase;
  final ToolboxCryptoStrength strength;
  final Uint8List? keyFileBytes;
  final String? sourceExtension;
  final List<ToolboxCryptoCascadeCipher>? cascade;
  final ToolboxCryptoKeyBits keyBits;
  final ToolboxCryptoMacAlgorithm macAlgorithm;
  final ToolboxCryptoSignatureMode signatureMode;
  final int maxErrorAttempts;
  final int maxSuccessfulReveals;
  final ToolboxSteganographyLocatorAlgorithm locatorAlgorithm;
  final ToolboxSteganographyLocatorStrength locatorStrength;
}

class _StegoRevealTextRequest {
  const _StegoRevealTextRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.passphrase,
    required this.keyFileBytes,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final String passphrase;
  final Uint8List? keyFileBytes;
  final ToolboxSteganographyLocatorAlgorithm locatorAlgorithm;
  final ToolboxSteganographyLocatorStrength locatorStrength;
}

class _StegoEmbedFileRequest {
  const _StegoEmbedFileRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.fileBytes,
    required this.dualLayerEnabled,
    required this.coverFileBytes,
    required this.fileName,
    required this.coverFileName,
    required this.encryption,
    required this.passphrase,
    required this.coverPassphrase,
    required this.strength,
    required this.keyFileBytes,
    required this.sourceExtension,
    required this.mediaType,
    required this.coverMediaType,
    required this.cascade,
    required this.keyBits,
    required this.macAlgorithm,
    required this.signatureMode,
    required this.maxErrorAttempts,
    required this.maxSuccessfulReveals,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final Uint8List fileBytes;
  final bool dualLayerEnabled;
  final Uint8List? coverFileBytes;
  final String? fileName;
  final String? coverFileName;
  final ToolboxCryptoAlgorithm encryption;
  final String passphrase;
  final String coverPassphrase;
  final ToolboxCryptoStrength strength;
  final Uint8List? keyFileBytes;
  final String? sourceExtension;
  final String? mediaType;
  final String? coverMediaType;
  final List<ToolboxCryptoCascadeCipher>? cascade;
  final ToolboxCryptoKeyBits keyBits;
  final ToolboxCryptoMacAlgorithm macAlgorithm;
  final ToolboxCryptoSignatureMode signatureMode;
  final int maxErrorAttempts;
  final int maxSuccessfulReveals;
  final ToolboxSteganographyLocatorAlgorithm locatorAlgorithm;
  final ToolboxSteganographyLocatorStrength locatorStrength;
}

class _StegoRevealFileRequest {
  const _StegoRevealFileRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.passphrase,
    required this.keyFileBytes,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final String passphrase;
  final Uint8List? keyFileBytes;
  final ToolboxSteganographyLocatorAlgorithm locatorAlgorithm;
  final ToolboxSteganographyLocatorStrength locatorStrength;
}

class _StegoTextCapacityRequest {
  const _StegoTextCapacityRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.text,
    required this.dualLayerEnabled,
    required this.coverText,
    required this.encryption,
    required this.passphrase,
    required this.coverPassphrase,
    required this.strength,
    required this.keyFileBytes,
    required this.cascade,
    required this.keyBits,
    required this.macAlgorithm,
    required this.signatureMode,
    required this.maxErrorAttempts,
    required this.maxSuccessfulReveals,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final String text;
  final bool dualLayerEnabled;
  final String coverText;
  final ToolboxCryptoAlgorithm encryption;
  final String passphrase;
  final String coverPassphrase;
  final ToolboxCryptoStrength strength;
  final Uint8List? keyFileBytes;
  final List<ToolboxCryptoCascadeCipher>? cascade;
  final ToolboxCryptoKeyBits keyBits;
  final ToolboxCryptoMacAlgorithm macAlgorithm;
  final ToolboxCryptoSignatureMode signatureMode;
  final int maxErrorAttempts;
  final int maxSuccessfulReveals;
}

class _StegoFileCapacityRequest {
  const _StegoFileCapacityRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.fileBytes,
    required this.dualLayerEnabled,
    required this.coverFileBytes,
    required this.fileName,
    required this.coverFileName,
    required this.encryption,
    required this.passphrase,
    required this.coverPassphrase,
    required this.strength,
    required this.keyFileBytes,
    required this.mediaType,
    required this.coverMediaType,
    required this.cascade,
    required this.keyBits,
    required this.macAlgorithm,
    required this.signatureMode,
    required this.maxErrorAttempts,
    required this.maxSuccessfulReveals,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final Uint8List fileBytes;
  final bool dualLayerEnabled;
  final Uint8List? coverFileBytes;
  final String? fileName;
  final String? coverFileName;
  final ToolboxCryptoAlgorithm encryption;
  final String passphrase;
  final String coverPassphrase;
  final ToolboxCryptoStrength strength;
  final Uint8List? keyFileBytes;
  final String? mediaType;
  final String? coverMediaType;
  final List<ToolboxCryptoCascadeCipher>? cascade;
  final ToolboxCryptoKeyBits keyBits;
  final ToolboxCryptoMacAlgorithm macAlgorithm;
  final ToolboxCryptoSignatureMode signatureMode;
  final int maxErrorAttempts;
  final int maxSuccessfulReveals;
}

ToolboxSteganographyEmbedResult _runStegoEmbedText(
  _StegoEmbedTextRequest request,
) {
  if (request.dualLayerEnabled) {
    return ToolboxSteganographyService().embedDualText(
      mediaKind: request.mediaKind,
      carrierBytes: request.carrierBytes,
      coverText: request.coverText,
      hiddenText: request.text,
      encryption: request.encryption,
      coverPassphrase: request.coverPassphrase,
      hiddenPassphrase: request.passphrase,
      strength: request.strength,
      hiddenKeyFileBytes: request.keyFileBytes,
      sourceExtension: request.sourceExtension,
      cascade: request.cascade,
      keyBits: request.keyBits,
      macAlgorithm: request.macAlgorithm,
      signatureMode: request.signatureMode,
      maxErrorAttempts: request.maxErrorAttempts,
      maxSuccessfulReveals: request.maxSuccessfulReveals,
      locatorAlgorithm: request.locatorAlgorithm,
      locatorStrength: request.locatorStrength,
    );
  }
  return ToolboxSteganographyService().embedText(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    text: request.text,
    encryption: request.encryption,
    passphrase: request.passphrase,
    strength: request.strength,
    keyFileBytes: request.keyFileBytes,
    sourceExtension: request.sourceExtension,
    cascade: request.cascade,
    keyBits: request.keyBits,
    macAlgorithm: request.macAlgorithm,
    signatureMode: request.signatureMode,
    maxErrorAttempts: request.maxErrorAttempts,
    maxSuccessfulReveals: request.maxSuccessfulReveals,
    locatorAlgorithm: request.locatorAlgorithm,
    locatorStrength: request.locatorStrength,
  );
}

ToolboxSteganographyRevealResult _runStegoRevealText(
  _StegoRevealTextRequest request,
) {
  return ToolboxSteganographyService().revealText(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    passphrase: request.passphrase,
    keyFileBytes: request.keyFileBytes,
    locatorAlgorithm: request.locatorAlgorithm,
    locatorStrength: request.locatorStrength,
  );
}

ToolboxSteganographyEmbedResult _runStegoEmbedFile(
  _StegoEmbedFileRequest request,
) {
  if (request.dualLayerEnabled) {
    return ToolboxSteganographyService().embedDualFile(
      mediaKind: request.mediaKind,
      carrierBytes: request.carrierBytes,
      coverFileBytes: request.coverFileBytes ?? Uint8List(0),
      hiddenFileBytes: request.fileBytes,
      coverFileName: request.coverFileName,
      hiddenFileName: request.fileName,
      encryption: request.encryption,
      coverPassphrase: request.coverPassphrase,
      hiddenPassphrase: request.passphrase,
      strength: request.strength,
      hiddenKeyFileBytes: request.keyFileBytes,
      sourceExtension: request.sourceExtension,
      coverMediaType: request.coverMediaType,
      hiddenMediaType: request.mediaType,
      cascade: request.cascade,
      keyBits: request.keyBits,
      macAlgorithm: request.macAlgorithm,
      signatureMode: request.signatureMode,
      maxErrorAttempts: request.maxErrorAttempts,
      maxSuccessfulReveals: request.maxSuccessfulReveals,
      locatorAlgorithm: request.locatorAlgorithm,
      locatorStrength: request.locatorStrength,
    );
  }
  return ToolboxSteganographyService().embedFile(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    fileBytes: request.fileBytes,
    fileName: request.fileName,
    encryption: request.encryption,
    passphrase: request.passphrase,
    strength: request.strength,
    keyFileBytes: request.keyFileBytes,
    sourceExtension: request.sourceExtension,
    mediaType: request.mediaType,
    cascade: request.cascade,
    keyBits: request.keyBits,
    macAlgorithm: request.macAlgorithm,
    signatureMode: request.signatureMode,
    maxErrorAttempts: request.maxErrorAttempts,
    maxSuccessfulReveals: request.maxSuccessfulReveals,
    locatorAlgorithm: request.locatorAlgorithm,
    locatorStrength: request.locatorStrength,
  );
}

class _StegoSuccessfulRevealProtectionRequest {
  const _StegoSuccessfulRevealProtectionRequest({
    required this.mediaKind,
    required this.carrierBytes,
    required this.passphrase,
    required this.keyFileBytes,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final String passphrase;
  final Uint8List? keyFileBytes;
  final ToolboxSteganographyLocatorAlgorithm locatorAlgorithm;
  final ToolboxSteganographyLocatorStrength locatorStrength;
}

ToolboxSteganographySuccessfulRevealProtectionResult
_runStegoSuccessfulRevealProtection(
  _StegoSuccessfulRevealProtectionRequest request,
) {
  return ToolboxSteganographyService().applySuccessfulRevealProtection(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    passphrase: request.passphrase,
    keyFileBytes: request.keyFileBytes,
    locatorAlgorithm: request.locatorAlgorithm,
    locatorStrength: request.locatorStrength,
  );
}

ToolboxSteganographyFileRevealResult _runStegoRevealFile(
  _StegoRevealFileRequest request,
) {
  return ToolboxSteganographyService().revealFile(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    passphrase: request.passphrase,
    keyFileBytes: request.keyFileBytes,
    locatorAlgorithm: request.locatorAlgorithm,
    locatorStrength: request.locatorStrength,
  );
}

ToolboxSteganographyCapacityCheck _runStegoTextCapacityCheck(
  _StegoTextCapacityRequest request,
) {
  return ToolboxSteganographyService().checkTextWriteCapacity(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    text: request.text,
    dualLayerEnabled: request.dualLayerEnabled,
    coverText: request.coverText,
    encryption: request.encryption,
    passphrase: request.passphrase,
    coverPassphrase: request.coverPassphrase,
    strength: request.strength,
    keyFileBytes: request.keyFileBytes,
    cascade: request.cascade,
    keyBits: request.keyBits,
    macAlgorithm: request.macAlgorithm,
    signatureMode: request.signatureMode,
    maxErrorAttempts: request.maxErrorAttempts,
    maxSuccessfulReveals: request.maxSuccessfulReveals,
  );
}

ToolboxSteganographyCapacityCheck _runStegoFileCapacityCheck(
  _StegoFileCapacityRequest request,
) {
  return ToolboxSteganographyService().checkFileWriteCapacity(
    mediaKind: request.mediaKind,
    carrierBytes: request.carrierBytes,
    fileBytes: request.fileBytes,
    dualLayerEnabled: request.dualLayerEnabled,
    coverFileBytes: request.coverFileBytes,
    fileName: request.fileName,
    coverFileName: request.coverFileName,
    encryption: request.encryption,
    passphrase: request.passphrase,
    coverPassphrase: request.coverPassphrase,
    strength: request.strength,
    keyFileBytes: request.keyFileBytes,
    mediaType: request.mediaType,
    coverMediaType: request.coverMediaType,
    cascade: request.cascade,
    keyBits: request.keyBits,
    macAlgorithm: request.macAlgorithm,
    signatureMode: request.signatureMode,
    maxErrorAttempts: request.maxErrorAttempts,
    maxSuccessfulReveals: request.maxSuccessfulReveals,
  );
}

class _SteganographyToolPage extends StatefulWidget {
  const _SteganographyToolPage();

  @override
  State<_SteganographyToolPage> createState() => _SteganographyToolPageState();
}

class _SteganographyToolPageState extends State<_SteganographyToolPage> {
  final ToolboxSteganographyService _service = ToolboxSteganographyService();
  final ToolboxCryptoService _cryptoService = ToolboxCryptoService();
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _coverSecretController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _coverPassphraseController =
      TextEditingController();
  final TextEditingController _keyFileLengthController = TextEditingController(
    text: '256',
  );
  final TextEditingController _maxErrorAttemptsController =
      TextEditingController(text: '0');
  final TextEditingController _maxSuccessfulRevealsController =
      TextEditingController(text: '0');

  _CryptoWorkspace _workspace = _CryptoWorkspace.steganography;
  _StegoMode _mode = _StegoMode.embed;
  _FileCryptoMode _fileMode = _FileCryptoMode.encrypt;
  ToolboxSteganographyMediaKind _mediaKind =
      ToolboxSteganographyMediaKind.image;
  ToolboxCryptoAlgorithm _encryption = ToolboxCryptoAlgorithm.aesGcm;
  ToolboxCryptoStrength _strength = ToolboxCryptoStrength.standard;
  ToolboxCryptoHashAlgorithm _hashAlgorithm = ToolboxCryptoHashAlgorithm.sha256;
  ToolboxCryptoKeyBits _keyBits = ToolboxCryptoKeyBits.bits256;
  ToolboxCryptoMacAlgorithm _macAlgorithm = ToolboxCryptoMacAlgorithm.sha256;
  ToolboxCryptoSignatureMode _signatureMode = ToolboxCryptoSignatureMode.none;
  bool _dualLayerEnabled = false;
  ToolboxSteganographyLocatorAlgorithm _locatorAlgorithm =
      ToolboxSteganographyLocatorAlgorithm.sha256;
  ToolboxSteganographyLocatorStrength _locatorStrength =
      ToolboxSteganographyLocatorStrength.standard;
  List<ToolboxCryptoCascadeCipher> _cascade =
      const <ToolboxCryptoCascadeCipher>[
        ToolboxCryptoCascadeCipher.aes,
        ToolboxCryptoCascadeCipher.twofish,
      ];
  String? _sourceName;
  String? _sourcePath;
  String? _sourceExtension;
  Uint8List? _sourceBytes;
  bool _useKeyFiles = false;
  String? _keyFileName;
  Uint8List? _keyFileBytes;
  List<_KeyFileEntry> _keyFileEntries = const <_KeyFileEntry>[];
  String? _fileName;
  String? _fileExtension;
  Uint8List? _fileBytes;
  String? _coverFileName;
  String? _coverFileExtension;
  Uint8List? _coverFileBytes;
  Uint8List? _fileOutputBytes;
  ToolboxSteganographyEmbedResult? _fileEmbedResult;
  ToolboxSteganographyFileRevealResult? _fileRevealResult;
  ToolboxSteganographyCapacityCheck? _writePreview;
  int? _writePreviewOutputBytes;
  ToolboxCryptoHashResult? _hashResult;
  Uint8List? _outputBytes;
  ui.Image? _sourcePreview;
  ui.Image? _outputPreview;
  ToolboxSteganographyEmbedResult? _embedResult;
  ToolboxSteganographyRevealResult? _revealResult;
  bool _busy = false;
  String? _savedPath;
  String? _statusMessage;
  String? _error;
  bool _maxErrorRiskPromptShown = false;
  bool _successfulRevealRiskPromptShown = false;
  Timer? _decodeUnlockTimer;

  static const Duration _decodeErrorWindow = Duration(minutes: 5);
  static const Duration _decodeLockDuration = Duration(minutes: 5);
  static const int _decodeErrorLimit = 10;
  static const int _maxCombinedKeyFileBytes =
      8 * ToolboxCryptoService.maxKeyFileBytes;
  static final Map<String, List<DateTime>> _decodeErrorTimesByCarrier =
      <String, List<DateTime>>{};
  static final Map<String, DateTime> _decodeLockedUntilByCarrier =
      <String, DateTime>{};
  static final Map<String, int> _protectedDecodeFailuresByCarrier =
      <String, int>{};

  @override
  void dispose() {
    _clearSecretInputs();
    _secretController.dispose();
    _coverSecretController.dispose();
    _passphraseController.dispose();
    _coverPassphraseController.dispose();
    _keyFileLengthController.dispose();
    _maxErrorAttemptsController.dispose();
    _maxSuccessfulRevealsController.dispose();
    _decodeUnlockTimer?.cancel();
    _sourcePreview?.dispose();
    _outputPreview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.media_steganography.ae000f7887ea',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.crypto.encrypt_text_into_media_encrypt_file.6902c8ad0625',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStagePanel(context),
          const SizedBox(height: 12),
          if (_workspace == _CryptoWorkspace.steganography) ...<Widget>[
            _buildInputPanel(context),
            const SizedBox(height: 12),
            _buildActionPanel(context),
          ] else if (_workspace == _CryptoWorkspace.file) ...<Widget>[
            _buildFilePanel(context),
          ] else ...<Widget>[_buildHashPanel(context)],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildMessagePanel(
              context,
              text: _error!,
              icon: Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.errorContainer,
              foreground: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ],
          if (_statusMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildMessagePanel(
              context,
              text: _statusMessage!,
              icon: Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.secondaryContainer,
              foreground: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ],
          if (_savedPath != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildMessagePanel(
              context,
              text: _lifeI18nText(
                context,
                'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.saved.7b5e2b53bc',
                params: <String, Object?>{'_savedPath': _savedPath},
              ),
              icon: Icons.check_circle_outline_rounded,
              color: Theme.of(context).colorScheme.primaryContainer,
              foreground: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ],
          const SizedBox(height: 12),
          if (_workspace == _CryptoWorkspace.steganography) ...<Widget>[
            _buildResultPanel(context),
            if (_shouldShowPreviewPanel) ...<Widget>[
              const SizedBox(height: 12),
              _buildPreviewPanel(context),
            ],
          ] else if (_workspace == _CryptoWorkspace.file) ...<Widget>[
            _buildFileResultPanel(context),
            if (_shouldShowPreviewPanel) ...<Widget>[
              const SizedBox(height: 12),
              _buildPreviewPanel(context),
            ],
          ] else ...<Widget>[_buildHashResultPanel(context)],
          const SizedBox(height: 12),
          _buildBoundaryPanel(context),
        ],
      ),
    );
  }

  Widget _buildCryptoAdvancedPanel(BuildContext context) {
    return _LifePreviewFrame(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        maintainState: true,
        leading: Icon(
          Icons.tune_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        iconColor: Theme.of(context).colorScheme.primary,
        collapsedIconColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.20),
        collapsedBackgroundColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        title: Text(
          _lifeI18nText(
            context,
            'inline.plan295.crypto.advanced_crypto.3f9a90e0b348',
          ),
        ),
        subtitle: Text(
          '${_keyBits.bits}-bit · ${_macAlgorithm.id} · ${_signatureMode.label} · ${_locatorAlgorithm.label}/${_locatorStrength.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LifeSegmentedField<ToolboxCryptoKeyBits>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.key_bits.187269d6b250',
                ),
                value: _keyBits,
                options: const <_LifeOption<ToolboxCryptoKeyBits>>[
                  _LifeOption<ToolboxCryptoKeyBits>(
                    value: ToolboxCryptoKeyBits.bits256,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.256_bit_374d7d',
                  ),
                  _LifeOption<ToolboxCryptoKeyBits>(
                    value: ToolboxCryptoKeyBits.bits512,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.512_bit_74e578',
                  ),
                  _LifeOption<ToolboxCryptoKeyBits>(
                    value: ToolboxCryptoKeyBits.bits1024,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.1024_bit_5414a9',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _keyBits = value),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxCryptoMacAlgorithm>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.mac_hash.f7ae2017d6ed',
                ),
                value: _macAlgorithm,
                options: const <_LifeOption<ToolboxCryptoMacAlgorithm>>[
                  _LifeOption<ToolboxCryptoMacAlgorithm>(
                    value: ToolboxCryptoMacAlgorithm.sha256,
                    labelKey:
                        'literal.services.toolbox_crypto_service.sha_256_8104c0',
                  ),
                  _LifeOption<ToolboxCryptoMacAlgorithm>(
                    value: ToolboxCryptoMacAlgorithm.whirlpool,
                    labelKey:
                        'literal.services.toolbox_crypto_service.whirlpool_b998b2',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _macAlgorithm = value),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxCryptoSignatureMode>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.signature.a27f12dbd0aa',
                ),
                value: _signatureMode,
                options: const <_LifeOption<ToolboxCryptoSignatureMode>>[
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.none,
                    labelKey: 'ref.wordTransitionStyleNone',
                  ),
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.weakSha256,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.weak_fast_df2355',
                  ),
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.rsaSha256,
                    labelKey:
                        'literal.services.toolbox_crypto_service.sha_256_rsa_315a26',
                  ),
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.ecdsaSha256,
                    labelKey:
                        'literal.services.toolbox_crypto_service.ecdsa_890a3a',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _signatureMode = value),
              ),
              if (_effectiveSignatureMode !=
                  ToolboxCryptoSignatureMode.none) ...<Widget>[
                const SizedBox(height: 10),
                _buildInlineNotice(
                  context,
                  icon: Icons.timer_rounded,
                  text: _signaturePerformanceText(context),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                key: const ValueKey<String>('life_stego_dual_layer_switch'),
                contentPadding: EdgeInsets.zero,
                value: _dualLayerEnabled,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _dualLayerEnabled = value),
                secondary: const Icon(Icons.layers_rounded),
                title: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.dual_layer.9d7703c2e1ed',
                  ),
                ),
                subtitle: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.explicitly_writes_cover_and_hidden_c.a293ba98ad55',
                  ),
                ),
              ),
              if (_dualLayerEnabled) ...<Widget>[
                const SizedBox(height: 8),
                _buildInlineNotice(
                  context,
                  icon: Icons.privacy_tip_rounded,
                  text: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.dual_layer_mode_writes_cover_and_hid.688598b49f5a',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('life_stego_max_error_attempts'),
                controller: _maxErrorAttemptsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security_update_warning_rounded),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.max_wrong_attempts.6959d4319854',
                  ),
                  helperText: _maxErrorAttemptsRiskText(context),
                  helperMaxLines: 3,
                  helperStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onChanged: _handleMaxErrorAttemptsChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>(
                  'life_stego_max_successful_reveals',
                ),
                controller: _maxSuccessfulRevealsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.auto_delete_rounded),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.max_successful_reveals.a01dd55e3e17',
                  ),
                  helperText: _maxSuccessfulRevealsRiskText(context),
                  helperMaxLines: 4,
                  helperStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onChanged: _handleMaxSuccessfulRevealsChanged,
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxSteganographyLocatorAlgorithm>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.locator_algorithm.111bf25c9873',
                ),
                value: _locatorAlgorithm,
                options: const <_LifeOption<ToolboxSteganographyLocatorAlgorithm>>[
                  _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                    value: ToolboxSteganographyLocatorAlgorithm.sha256,
                    labelKey:
                        'literal.services.toolbox_crypto_service.sha_256_8104c0',
                  ),
                  _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                    value: ToolboxSteganographyLocatorAlgorithm.sha512,
                    labelKey:
                        'literal.services.toolbox_crypto_service.sha_512_746cf7',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _locatorAlgorithm = value),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxSteganographyLocatorStrength>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.locator_strength.1a07a07caf35',
                ),
                value: _locatorStrength,
                options: const <_LifeOption<ToolboxSteganographyLocatorStrength>>[
                  _LifeOption<ToolboxSteganographyLocatorStrength>(
                    value: ToolboxSteganographyLocatorStrength.standard,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.standard_4096_4d6ce0',
                  ),
                  _LifeOption<ToolboxSteganographyLocatorStrength>(
                    value: ToolboxSteganographyLocatorStrength.strong,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.strong_12000_325e9b',
                  ),
                  _LifeOption<ToolboxSteganographyLocatorStrength>(
                    value: ToolboxSteganographyLocatorStrength.extreme,
                    labelKey:
                        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.extreme_24000_ad0947',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _locatorStrength = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCascadeControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildInlineNotice(
          context,
          icon: Icons.account_tree_rounded,
          text: _lifeI18nText(
            context,
            'inline.plan295.crypto.custom_cascade_encrypts_in_the_order.5ccc9729aa9e',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ToolboxCryptoCascadeCipher.values
              .where(
                (cipher) => cipher != ToolboxCryptoCascadeCipher.sha256Stream,
              )
              .map((cipher) => _buildCascadeChip(context, cipher))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildRevealLocatorPanel(BuildContext context) {
    return _LifePreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.explore_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.locator.b1be49c6bc09',
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSegmentedField<ToolboxSteganographyLocatorAlgorithm>(
            label: _lifeI18nText(
              context,
              'inline.plan295.crypto.locator_algorithm.111bf25c9873',
            ),
            value: _locatorAlgorithm,
            options: const <_LifeOption<ToolboxSteganographyLocatorAlgorithm>>[
              _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                value: ToolboxSteganographyLocatorAlgorithm.sha256,
                labelKey:
                    'literal.services.toolbox_crypto_service.sha_256_8104c0',
              ),
              _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                value: ToolboxSteganographyLocatorAlgorithm.sha512,
                labelKey:
                    'literal.services.toolbox_crypto_service.sha_512_746cf7',
              ),
            ],
            onChanged: _busy
                ? (_) {}
                : (value) => setState(() => _locatorAlgorithm = value),
          ),
          const SizedBox(height: 12),
          _LifeSegmentedField<ToolboxSteganographyLocatorStrength>(
            label: _lifeI18nText(
              context,
              'inline.plan295.crypto.locator_strength.1a07a07caf35',
            ),
            value: _locatorStrength,
            options: const <_LifeOption<ToolboxSteganographyLocatorStrength>>[
              _LifeOption<ToolboxSteganographyLocatorStrength>(
                value: ToolboxSteganographyLocatorStrength.standard,
                labelKey:
                    'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.standard_4096_4d6ce0',
              ),
              _LifeOption<ToolboxSteganographyLocatorStrength>(
                value: ToolboxSteganographyLocatorStrength.strong,
                labelKey:
                    'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.strong_12000_325e9b',
              ),
              _LifeOption<ToolboxSteganographyLocatorStrength>(
                value: ToolboxSteganographyLocatorStrength.extreme,
                labelKey:
                    'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.extreme_24000_ad0947',
              ),
            ],
            onChanged: _busy
                ? (_) {}
                : (value) => setState(() => _locatorStrength = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStagePanel(BuildContext context) {
    final mediaLabel = _mediaLabel(context, _mediaKind);
    final modeLabel = switch (_workspace) {
      _CryptoWorkspace.steganography =>
        _mode == _StegoMode.embed
            ? _lifeI18nText(
                context,
                'inline.plan295.crypto.embed_secret.d269b139d092',
              )
            : _lifeI18nText(
                context,
                'inline.plan295.crypto.reveal_message.8ac6fa6d6d32',
              ),
      _CryptoWorkspace.file =>
        _fileMode == _FileCryptoMode.encrypt
            ? _lifeI18nText(
                context,
                'inline.plan295.crypto.embed_file.74e82c21375c',
              )
            : _lifeI18nText(
                context,
                'inline.plan295.crypto.reveal_file.9b10709f7962',
              ),
      _CryptoWorkspace.hash => _lifeI18nText(
        context,
        'inline.plan295.crypto.hash_digest.90114149c380',
      ),
    };
    final workspaceLabel = _workspaceLabel(context, _workspace);
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.crypto_stage.1c23c0810f0a',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.current_a_key_file_can_be.08fe5bc36b',
        params: <String, Object?>{
          'workspaceLabel': workspaceLabel,
          'modeLabel': modeLabel,
          'mediaLabel': mediaLabel,
        },
      ),
      children: <Widget>[
        _LifeSegmentedField<_CryptoWorkspace>(
          label: _lifeI18nText(
            context,
            'inline.plan295.crypto.function.3610cd5968f2',
          ),
          value: _workspace,
          options: const <_LifeOption<_CryptoWorkspace>>[
            _LifeOption<_CryptoWorkspace>(
              value: _CryptoWorkspace.steganography,
              labelKey: 'inline.plan295.crypto.stego.1cc36bd69b84',
            ),
            _LifeOption<_CryptoWorkspace>(
              value: _CryptoWorkspace.file,
              labelKey:
                  'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.file_225ba0',
            ),
            _LifeOption<_CryptoWorkspace>(
              value: _CryptoWorkspace.hash,
              labelKey: 'inline.plan295.crypto.hash.c499c69bcca6',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _workspace = value;
                    _clearSecretInputs();
                    _savedPath = null;
                    _statusMessage = null;
                    _error = null;
                  });
                },
        ),
        const SizedBox(height: 12),
        if (_workspace == _CryptoWorkspace.hash) ...<Widget>[
          _LifeSegmentedField<ToolboxCryptoHashAlgorithm>(
            label: _lifeI18nText(
              context,
              'inline.plan295.crypto.hash_algorithm.86a4a467de16',
            ),
            value: _hashAlgorithm,
            options: const <_LifeOption<ToolboxCryptoHashAlgorithm>>[
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.sha256,
                labelKey:
                    'literal.services.toolbox_crypto_service.sha_256_8104c0',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.sha512,
                labelKey:
                    'literal.services.toolbox_crypto_service.sha_512_746cf7',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.sha3_256,
                labelKey:
                    'literal.services.toolbox_crypto_service.sha3_256_226282',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.blake2b256,
                labelKey:
                    'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.blake2b_533777',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.whirlpool,
                labelKey:
                    'literal.services.toolbox_crypto_service.whirlpool_b998b2',
              ),
            ],
            onChanged: _busy
                ? (_) {}
                : (value) => setState(() => _hashAlgorithm = value),
          ),
        ] else ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (_workspace == _CryptoWorkspace.steganography) ...<Widget>[
                _buildModeChip(
                  context,
                  mode: _StegoMode.embed,
                  icon: Icons.lock_rounded,
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.embed.4540f8f9375d',
                  ),
                ),
                _buildModeChip(
                  context,
                  mode: _StegoMode.reveal,
                  icon: Icons.lock_open_rounded,
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.reveal.4317a923361e',
                  ),
                ),
              ] else ...<Widget>[
                _buildFileModeChip(
                  context,
                  mode: _FileCryptoMode.encrypt,
                  icon: Icons.lock_rounded,
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.encrypt.1fc135dfc95f',
                  ),
                ),
                _buildFileModeChip(
                  context,
                  mode: _FileCryptoMode.decrypt,
                  icon: Icons.lock_open_rounded,
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.decrypt.30d8321efe61',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSegmentedField<ToolboxSteganographyMediaKind>(
            label: _lifeI18nText(
              context,
              'inline.plan295.crypto.media_type.a93164fdf789',
            ),
            value: _mediaKind,
            options: const <_LifeOption<ToolboxSteganographyMediaKind>>[
              _LifeOption<ToolboxSteganographyMediaKind>(
                value: ToolboxSteganographyMediaKind.image,
                labelKey: 'inline.plan295.crypto.image.baebdc30e7e4',
              ),
              _LifeOption<ToolboxSteganographyMediaKind>(
                value: ToolboxSteganographyMediaKind.audio,
                labelKey: 'inline.plan295.crypto.audio.253158c06f3c',
              ),
              _LifeOption<ToolboxSteganographyMediaKind>(
                value: ToolboxSteganographyMediaKind.video,
                labelKey: 'inline.plan295.crypto.video.2074eae3b2ea',
              ),
            ],
            onChanged: _busy
                ? (_) {}
                : (value) {
                    setState(() {
                      _mediaKind = value;
                      _clearSourceAndResult();
                    });
                  },
          ),
          const SizedBox(height: 12),
          if (!_isRevealMode) ...<Widget>[
            _LifeSegmentedField<ToolboxCryptoAlgorithm>(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.encryption.8a35d6135b6c',
              ),
              value: _encryption,
              options: const <_LifeOption<ToolboxCryptoAlgorithm>>[
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesGcm,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.aes_strong_4821e8',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.chacha20Poly1305,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.chacha20_3538f3',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.twofishGcm,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.twofish_strong_f62d39',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.camelliaGcm,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.camellia_strong_9da626',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesTwofishGcm,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.aes_twofish_strong_ebec16',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesCamelliaGcm,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.aes_camellia_strong_12afe9',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.triple_strong_b76cc2',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.customCascade,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.custom_strong_634ee4',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.sha256RsaSignature,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.rsa_signed_9ebb16',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.ecdsaSignature,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.ecdsa_signed_5aa308',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.whirlpoolDigest,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.whirlpool_strong_e1298e',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.none,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.no_encryption_plain_549173',
                ),
              ],
              onChanged: _busy
                  ? (_) {}
                  : (value) => setState(() => _encryption = value),
            ),
            if (_encryption ==
                ToolboxCryptoAlgorithm.customCascade) ...<Widget>[
              const SizedBox(height: 12),
              _buildCustomCascadeControls(context),
            ],
            const SizedBox(height: 12),
            _buildAlgorithmSafetyNotice(context),
            const SizedBox(height: 12),
            _LifeSegmentedField<ToolboxCryptoStrength>(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.strength.6ceaff5bfe8e',
              ),
              value: _strength,
              options: const <_LifeOption<ToolboxCryptoStrength>>[
                _LifeOption<ToolboxCryptoStrength>(
                  value: ToolboxCryptoStrength.standard,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.standard_2_16_213606',
                ),
                _LifeOption<ToolboxCryptoStrength>(
                  value: ToolboxCryptoStrength.strong,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.strong_2_17_b7753b',
                ),
                _LifeOption<ToolboxCryptoStrength>(
                  value: ToolboxCryptoStrength.extreme,
                  labelKey:
                      'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.extreme_2_18_2a2353',
                ),
              ],
              onChanged: _busy
                  ? (_) {}
                  : (value) => setState(() => _strength = value),
            ),
            const SizedBox(height: 12),
            _buildCryptoAdvancedPanel(context),
          ] else ...<Widget>[_buildRevealLocatorPanel(context)],
        ],
      ],
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    final hasSource = _sourceBytes != null;
    final sourceText = hasSource
        ? '${_sourceName ?? _lifeI18nText(context, 'inline.plan295.crypto.unnamed_media.1a870df9500f')} · ${_formatBytes(_sourceBytes!.length)}'
        : _lifeI18nText(
            context,
            'inline.plan295.crypto.no_media_selected_yet.d02fab4a20b3',
          );
    return _LifeSettingsPanel(
      title: _mode == _StegoMode.embed
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.carrier_and_text.8ff488c78d48',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.media_to_reveal.482a64631786',
            ),
      subtitle: _mode == _StegoMode.embed
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.pick_a_media_file_and_enter_the_text.30c0565a208a',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.pick_a_generated_stego_media_file_an.4e6ecca4b30f',
            ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_stego_pick_button'),
                onPressed: _busy ? null : _pickMedia,
                style: _greenActionButtonStyle(context),
                icon: Icon(_mediaIcon(_mediaKind)),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.pick_media.8c87c919dd52',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan294.zen_sand.clear_ea17218b',
              ),
              onPressed: _busy ? null : _resetAll,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: Row(
            children: <Widget>[
              Icon(_mediaIcon(_mediaKind)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sourceText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (_mode == _StegoMode.embed) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('life_stego_secret_field'),
            controller: _secretController,
            maxLines: 5,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _dualLayerEnabled
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.crypto.hidden_layer_text.67996b8e305d',
                    )
                  : _lifeI18nText(
                      context,
                      'inline.plan295.crypto.secret_text.5afebe4c8226',
                    ),
            ),
          ),
          if (_dualLayerEnabled) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('life_stego_cover_secret_field'),
              controller: _coverSecretController,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.cover_layer_text.54090799a895',
                ),
                helperText: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.only_this_content_is_shown_when_reve.df0a084f484a',
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey<String>('life_stego_passphrase_field'),
          controller: _passphraseController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.vpn_key_rounded),
            labelText: _dualLayerEnabled
                ? _lifeI18nText(
                    context,
                    'inline.plan295.crypto.hidden_passphrase.e7d401009cf7',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.crypto.passphrase.92b3035c1d12',
                  ),
            helperText: _mode == _StegoMode.reveal
                ? _lifeI18nText(
                    context,
                    'inline.plan295.crypto.use_the_passphrase_and_key_file_from.32f6378125e0',
                  )
                : _encryption.requiresSecret
                ? _lifeI18nText(
                    context,
                    'inline.plan295.crypto.use_a_passphrase_or_key_file_the_sam.50193458ceb4',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.crypto.can_be_empty_for_no_encryption.83a3b9d640f9',
                  ),
          ),
        ),
        if (_mode == _StegoMode.embed && _dualLayerEnabled) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('life_stego_cover_passphrase_field'),
            controller: _coverPassphraseController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key_rounded),
              labelText: _lifeI18nText(
                context,
                'inline.plan295.crypto.cover_passphrase.42c7b5942bac',
              ),
              helperText: _lifeI18nText(
                context,
                'inline.plan295.crypto.must_differ_from_the_hidden_passphra.6ffee4a44b43',
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildKeyFileRow(context),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    final lockRemaining = _decodeLockRemaining;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (lockRemaining != null) ...<Widget>[
          _buildInlineNotice(
            context,
            icon: Icons.lock_clock_rounded,
            text: _decodeLockText(context, lockRemaining),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('life_stego_run_button'),
                onPressed:
                    _busy ||
                        _sourceBytes == null ||
                        _isUnsupportedMediaWrite ||
                        (_mode == _StegoMode.reveal && _isDecodeLocked)
                    ? null
                    : (_mode == _StegoMode.embed ? _embed : _reveal),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _mode == _StegoMode.embed
                            ? Icons.hide_image_rounded
                            : Icons.visibility_rounded,
                      ),
                label: Text(
                  _busy
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.crypto.working.c85bfe260dff',
                        )
                      : _mode == _StegoMode.embed
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.crypto.generate_stego.388ccea2136d',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.crypto.reveal_text.1382920ca59b',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('life_stego_save_button'),
                onPressed: _busy || _outputBytes == null ? null : _saveOutput,
                style: _greenActionButtonStyle(context),
                icon: const Icon(Icons.save_alt_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.export.f7657dd92440',
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_mode == _StegoMode.embed) ...<Widget>[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('life_stego_preview_write_button'),
              onPressed: _busy || _sourceBytes == null
                  ? null
                  : _previewTextWrite,
              icon: const Icon(Icons.fact_check_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.crypto.preview_write.01a4546d7dc0',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilePanel(BuildContext context) {
    final hasSource = _sourceBytes != null;
    final sourceText = hasSource
        ? '${_sourceName ?? _lifeI18nText(context, 'inline.plan295.crypto.unnamed_media.1a870df9500f')} · ${_formatBytes(_sourceBytes!.length)}'
        : _lifeI18nText(
            context,
            'inline.plan295.crypto.no_carrier_media_selected_yet.c4a640e196b0',
          );
    final hasFile = _fileBytes != null;
    final fileText = hasFile
        ? '${_fileName ?? _lifeI18nText(context, 'inline.plan295.crypto.unnamed_file.39c2b3e183d0')} · ${_formatBytes(_fileBytes!.length)}'
        : _lifeI18nText(
            context,
            'inline.plan295.crypto.no_file_selected_yet.c331376825ef',
          );
    final hasCoverFile = _coverFileBytes != null;
    final coverFileText = hasCoverFile
        ? '${_coverFileName ?? _lifeI18nText(context, 'inline.plan295.crypto.unnamed_cover_file.0d4ac9a6898e')} · ${_formatBytes(_coverFileBytes!.length)}'
        : _lifeI18nText(
            context,
            'inline.plan295.crypto.no_cover_file_selected_yet.144f37e90cec',
          );
    return _LifeSettingsPanel(
      title: _fileMode == _FileCryptoMode.encrypt
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.file_into_media.b8fde19df9ee',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.restore_file_from_media.4c481022de02',
            ),
      subtitle: _fileMode == _FileCryptoMode.encrypt
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.pick_a_carrier_and_a_file_encrypted.a6717f9525c5',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.pick_generated_stego_media_and_revea.65f0fe1ac220',
            ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_crypto_pick_carrier_button'),
                onPressed: _busy ? null : _pickMedia,
                style: _greenActionButtonStyle(context),
                icon: const Icon(Icons.perm_media_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.pick_carrier.6e113c7a6d6e',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan294.zen_sand.clear_ea17218b',
              ),
              onPressed: _busy ? null : _resetFileCarrier,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: Row(
            children: <Widget>[
              Icon(_mediaIcon(_mediaKind)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sourceText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (_fileMode == _FileCryptoMode.encrypt) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey<String>('life_crypto_pick_file_button'),
                  onPressed: _busy ? null : _pickCryptoFile,
                  style: _greenActionButtonStyle(context),
                  icon: const Icon(Icons.description_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.crypto.pick_file.32fb96644740',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.clear_file.b10cbf37539f',
                ),
                onPressed: _busy ? null : _resetFileCrypto,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LifePreviewFrame(
            child: Row(
              children: <Widget>[
                const Icon(Icons.description_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_dualLayerEnabled) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey<String>(
                      'life_crypto_pick_cover_file_button',
                    ),
                    onPressed: _busy ? null : _pickCoverCryptoFile,
                    style: _greenActionButtonStyle(context),
                    icon: const Icon(Icons.layers_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.crypto.pick_cover_file.2a4125dfc302',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.clear_cover_file.51459c53e3aa',
                  ),
                  onPressed: _busy ? null : _resetCoverFileCrypto,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _LifePreviewFrame(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.layers_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      coverFileText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _passphraseController,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.vpn_key_rounded),
            labelText: _dualLayerEnabled && _fileMode == _FileCryptoMode.encrypt
                ? _lifeI18nText(
                    context,
                    'inline.plan295.crypto.hidden_passphrase.e7d401009cf7',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.crypto.passphrase.92b3035c1d12',
                  ),
            helperText: _lifeI18nText(
              context,
              'inline.plan295.crypto.can_be_combined_with_a_key_file_and.1ffed2ca72be',
            ),
          ),
        ),
        if (_fileMode == _FileCryptoMode.encrypt &&
            _dualLayerEnabled) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('life_crypto_cover_passphrase_field'),
            controller: _coverPassphraseController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key_rounded),
              labelText: _lifeI18nText(
                context,
                'inline.plan295.crypto.cover_passphrase.42c7b5942bac',
              ),
              helperText: _lifeI18nText(
                context,
                'inline.plan295.crypto.the_cover_passphrase_reveals_only_th.e819e2ac0103',
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildKeyFileRow(context),
        if (_fileMode == _FileCryptoMode.decrypt &&
            _decodeLockRemaining != null) ...<Widget>[
          const SizedBox(height: 12),
          _buildInlineNotice(
            context,
            icon: Icons.lock_clock_rounded,
            text: _decodeLockText(context, _decodeLockRemaining!),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('life_crypto_file_run_button'),
                onPressed:
                    _busy ||
                        _sourceBytes == null ||
                        _isUnsupportedMediaWrite ||
                        (_fileMode == _FileCryptoMode.decrypt &&
                            _isDecodeLocked) ||
                        (_fileMode == _FileCryptoMode.encrypt &&
                            (_fileBytes == null ||
                                (_dualLayerEnabled && _coverFileBytes == null)))
                    ? null
                    : (_fileMode == _FileCryptoMode.encrypt
                          ? _encryptFile
                          : _decryptFile),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _fileMode == _FileCryptoMode.encrypt
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                      ),
                label: Text(
                  _busy
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.crypto.working.c85bfe260dff',
                        )
                      : _fileMode == _FileCryptoMode.encrypt
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.crypto.embed_file.0f9a763c4665',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.crypto.reveal_file.30110309c176',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('life_crypto_file_save_button'),
                onPressed: _busy || _fileOutputBytes == null
                    ? null
                    : _saveFileOutput,
                style: _greenActionButtonStyle(context),
                icon: const Icon(Icons.save_alt_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.export.0aea636010e0',
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_fileMode == _FileCryptoMode.encrypt) ...<Widget>[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('life_crypto_file_preview_button'),
              onPressed:
                  _busy ||
                      _sourceBytes == null ||
                      _fileBytes == null ||
                      (_dualLayerEnabled && _coverFileBytes == null)
                  ? null
                  : _previewFileWrite,
              icon: const Icon(Icons.fact_check_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.crypto.preview_write.01a4546d7dc0',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHashPanel(BuildContext context) {
    final source = _fileBytes ?? _sourceBytes;
    final name = _fileName ?? _sourceName;
    final sourceText = source == null
        ? _lifeI18nText(
            context,
            'inline.plan295.crypto.no_file_selected_yet.c331376825ef',
          )
        : '${name ?? _lifeI18nText(context, 'inline.plan295.crypto.unnamed_file.39c2b3e183d0')} · ${_formatBytes(source.length)}';
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.hash_digest.90114149c380',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.crypto.pick_any_file_and_calculate_a_digest.7236f3988537',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_crypto_hash_pick_button'),
                onPressed: _busy ? null : _pickHashFile,
                style: _greenActionButtonStyle(context),
                icon: const Icon(Icons.file_open_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.pick_file.32fb96644740',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan294.zen_sand.clear_ea17218b',
              ),
              onPressed: _busy ? null : _resetHash,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: Row(
            children: <Widget>[
              const Icon(Icons.tag_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sourceText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey<String>('life_crypto_hash_run_button'),
            onPressed: _busy || source == null ? null : _hashFile,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.functions_rounded),
            label: Text(
              _busy
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.crypto.working.c85bfe260dff',
                    )
                  : _lifeI18nText(
                      context,
                      'inline.plan295.crypto.calculate_hash.c14e85390338',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final embed = _embedResult;
    final reveal = _revealResult;
    if (embed == null && reveal == null) {
      final preview = _writePreview;
      if (_mode == _StegoMode.embed && preview != null) {
        return _buildWritePreviewPanel(context, preview);
      }
      return _LifeSettingsPanel(
        title: _lifeI18nText(
          context,
          'inline.ui.pages.toolbox_human_tests_memory.result_7f4e06',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.after_embedding_or_revealing_payload.faf76c822ad6',
        ),
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.no_result_yet.ec5979dbfff5',
            ),
          ),
        ],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.ui.pages.toolbox_human_tests_memory.result_7f4e06',
      ),
      subtitle: _mode == _StegoMode.embed
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.a_stego_media_file_is_ready_to_expor.30d737047505',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.text_has_been_revealed_from_the_medi.ad7d7073d832',
            ),
      children: <Widget>[
        if (embed != null) ...<Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.source.43c32f0f6d5f',
                ),
                value: _formatBytes(embed.sourceBytes),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.output.c96e3b239a69',
                ),
                value: _formatBytes(embed.outputBytes),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.payload.c49239eb0674',
                ),
                value: _formatBytes(embed.payloadBytes),
              ),
              if (embed.capacityBytes != null)
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.capacity.087427ad50cb',
                  ),
                  value: _formatBytes(embed.capacityBytes!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.cipher_preview.0d704547d0',
              params: <String, Object?>{'cipherPreview': embed.cipherPreview},
            ),
            key: const ValueKey<String>('life_stego_cipher_preview'),
          ),
        ],
        if (reveal != null) ...<Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.payload.c49239eb0674',
                ),
                value: _formatBytes(reveal.payloadBytes),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.algorithm.8435288f5f2f',
                ),
                value: _encryptionLabel(context, reveal.encryption),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.strength.6ceaff5bfe8e',
                ),
                value: _strengthLabel(context, reveal.strength),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            reveal.text,
            key: const ValueKey<String>('life_stego_revealed_text'),
          ),
        ],
      ],
    );
  }

  Widget _buildFileResultPanel(BuildContext context) {
    final embed = _fileEmbedResult;
    final reveal = _fileRevealResult;
    if (embed == null && reveal == null) {
      final preview = _writePreview;
      if (_fileMode == _FileCryptoMode.encrypt && preview != null) {
        return _buildWritePreviewPanel(context, preview);
      }
      return _LifeSettingsPanel(
        title: _lifeI18nText(
          context,
          'inline.plan295.crypto.file_result.aeb81128e66e',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.after_embedding_or_revealing_payload.882367be609c',
        ),
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.no_result_yet.ec5979dbfff5',
            ),
          ),
        ],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.file_result.aeb81128e66e',
      ),
      subtitle: _fileMode == _FileCryptoMode.encrypt
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.a_stego_media_file_is_ready_to_expor.30d737047505',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.the_hidden_file_has_been_revealed_an.b0014c24e865',
            ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.carrier.74dd5c193871',
              ),
              value: _formatBytes(_sourceBytes?.length ?? 0),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.ui.pages.toolbox_human_tests_auditory.output_dafb97',
              ),
              value: _formatBytes(_fileOutputBytes?.length ?? 0),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.algorithm.8435288f5f2f',
              ),
              value: _encryptionLabel(
                context,
                reveal?.encryption ?? _encryption,
              ),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.strength.6ceaff5bfe8e',
              ),
              value: _strengthLabel(context, reveal?.strength ?? _strength),
            ),
            if (embed?.capacityBytes != null)
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.capacity.087427ad50cb',
                ),
                value: _formatBytes(embed!.capacityBytes!),
              ),
          ],
        ),
        if (embed != null) ...<Widget>[
          const SizedBox(height: 12),
          SelectableText(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.cipher_preview.0d704547d0',
              params: <String, Object?>{'cipherPreview': embed.cipherPreview},
            ),
          ),
        ],
        if (reveal != null && reveal.fileName != null) ...<Widget>[
          const SizedBox(height: 12),
          SelectableText(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.file_name.a83051dc77',
              params: <String, Object?>{'fileName': reveal.fileName},
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWritePreviewPanel(
    BuildContext context,
    ToolboxSteganographyCapacityCheck check,
  ) {
    final outputBytes = _writePreviewOutputBytes;
    final usedBytes = check.dualLayer
        ? (check.coverRequiredBytes ?? 0) + (check.hiddenRequiredBytes ?? 0)
        : check.requiredBytes;
    final capacityLabel = check.dualLayer && check.perLayerCapacityBytes != null
        ? _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.per_layer.1bb9c04354',
            params: <String, Object?>{
              'p0': _formatBytes(check.perLayerCapacityBytes!),
            },
          )
        : _formatBytes(check.capacityBytes);
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.write_preview.204420b174fc',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.crypto.preflight_passed_review_capacity_out.3269f78636b0',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.carrier.6550a85a589f',
              ),
              value:
                  check.carrierLabel ?? _mediaLabel(context, check.mediaKind),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.capacity.087427ad50cb',
              ),
              value: capacityLabel,
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.payload_est.a432d1159362',
              ),
              value: _formatBytes(usedBytes),
            ),
            if (outputBytes != null)
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.crypto.output_est.55ee8a4f2cab',
                ),
                value: _formatBytes(outputBytes),
              ),
          ],
        ),
        if (check.dualLayer) ...<Widget>[
          const SizedBox(height: 12),
          _buildInlineNotice(
            context,
            icon: Icons.layers_rounded,
            text: _lifeI18nText(
              context,
              'inline.plan295.crypto.dual_layer_writing_creates_cover_and.e6e32eee8b05',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHashResultPanel(BuildContext context) {
    final result = _hashResult;
    if (result == null) {
      return _LifeSettingsPanel(
        title: _lifeI18nText(
          context,
          'inline.plan295.crypto.hash_result.f13a54ecd693',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.hex_and_base64_digests_appear_after.02e03fad9a32',
        ),
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.no_result_yet.ec5979dbfff5',
            ),
          ),
        ],
      );
    }
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.hash_result.f13a54ecd693',
      ),
      subtitle: _hashLabel(context, result.algorithm),
      children: <Widget>[
        SelectableText(
          result.hex,
          key: const ValueKey<String>('life_crypto_hash_hex'),
        ),
        const SizedBox(height: 10),
        SelectableText(result.base64),
      ],
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    if (_mediaKind != ToolboxSteganographyMediaKind.image) {
      return _LifeSettingsPanel(
        title: _lifeI18nText(
          context,
          'inline.plan295.crypto.media_preview.51b3df5ad671',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.audio_and_video_show_file_state_here.929cd3bce02f',
        ),
        children: <Widget>[
          _LifePreviewFrame(
            child: Text(
              _outputBytes == null
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.crypto.waiting_for_generate_or_reveal.404eae4246c4',
                    )
                  : _lifeI18nText(
                      context,
                      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.output_media_size.1a32d280bd',
                      params: <String, Object?>{
                        'p0': _formatBytes(_outputBytes!.length),
                      },
                    ),
            ),
          ),
        ],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.image_preview.0bc6c6304b1c',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.crypto.source_image_on_the_left_stego_png_o.cfaa355a469f',
      ),
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final tiles = <Widget>[
              Expanded(
                child: _imageTile(
                  context: context,
                  titleKey: 'inline.plan295.life.source.bd1f1bbdfe8e',
                  image: _sourcePreview,
                ),
              ),
              Expanded(
                child: _imageTile(
                  context: context,
                  titleKey: 'inline.plan295.crypto.stego.1cc36bd69b84',
                  image: _outputPreview,
                ),
              ),
            ];
            if (compact) {
              return Column(
                children: <Widget>[
                  _imageTile(
                    context: context,
                    titleKey: 'inline.plan295.life.source.bd1f1bbdfe8e',
                    image: _sourcePreview,
                  ),
                  const SizedBox(height: 10),
                  _imageTile(
                    context: context,
                    titleKey: 'inline.plan295.crypto.stego.1cc36bd69b84',
                    image: _outputPreview,
                  ),
                ],
              );
            }
            return Row(
              children: <Widget>[
                tiles.first,
                const SizedBox(width: 10),
                tiles.last,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBoundaryPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.crypto.boundaries.c3b0bac973d2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.crypto.this_tool_processes_files_locally_an.450bd6c842a1',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.crypto.images_use_lossless_png_randomized_p.268855c6e883',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.crypto.public_policy_headers_tamper_hints_a.77fe1d465c7b',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildModeChip(
    BuildContext context, {
    required _StegoMode mode,
    required IconData icon,
    required String label,
  }) {
    final selected = _mode == mode;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onSelected: _busy
          ? null
          : (_) {
              setState(() {
                if (_mode != mode) {
                  _mode = mode;
                  _clearSecretInputs();
                  _clearResults();
                }
              });
            },
    );
  }

  Widget _buildFileModeChip(
    BuildContext context, {
    required _FileCryptoMode mode,
    required IconData icon,
    required String label,
  }) {
    final selected = _fileMode == mode;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onSelected: _busy
          ? null
          : (_) {
              setState(() {
                if (_fileMode != mode) {
                  _fileMode = mode;
                  _clearSecretInputs();
                  _clearFileResults();
                }
              });
            },
    );
  }

  Widget _buildCascadeChip(
    BuildContext context,
    ToolboxCryptoCascadeCipher cipher,
  ) {
    final selected = _cascade.contains(cipher);
    return FilterChip(
      selected: selected,
      label: Text(_cascadeLabel(context, cipher)),
      onSelected: _busy
          ? null
          : (value) {
              if (!value && _cascade.length == 1) {
                return;
              }
              setState(() {
                if (value) {
                  _cascade = <ToolboxCryptoCascadeCipher>{
                    ..._cascade,
                    cipher,
                  }.toList(growable: false);
                } else {
                  _cascade = _cascade
                      .where((item) => item != cipher)
                      .toList(growable: false);
                }
              });
            },
    );
  }

  Widget _buildMessagePanel(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color color,
    required Color foreground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineNotice(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    return _LifePreviewFrame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildAlgorithmSafetyNotice(BuildContext context) {
    final icon = switch (_encryption) {
      ToolboxCryptoAlgorithm.none => Icons.warning_amber_rounded,
      ToolboxCryptoAlgorithm.sha256Stream ||
      ToolboxCryptoAlgorithm.rc4Legacy => Icons.history_rounded,
      _ => Icons.verified_user_rounded,
    };
    return _buildInlineNotice(
      context,
      icon: icon,
      text: _algorithmSafetyText(context, _encryption),
    );
  }

  Widget _buildKeyFileRow(BuildContext context) {
    final hasKeyFiles = _keyFileEntries.isNotEmpty;
    final summary = hasKeyFiles
        ? _keyFileSummary(context)
        : _lifeI18nText(
            context,
            'inline.plan295.crypto.no_key_files_selected.618b460527ba',
          );
    return _LifePreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.key_rounded, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.crypto.use_key_files.32a60283b1c6',
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.crypto.when_enabled_selected_files_are_sort.9ed0d7d6bfc9',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey<String>('life_crypto_use_key_file_switch'),
                value: _useKeyFiles,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _useKeyFiles = value),
              ),
            ],
          ),
          if (_useKeyFiles) ...<Widget>[
            const Divider(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  key: const ValueKey<String>('life_crypto_key_file_button'),
                  onPressed: _busy ? null : _pickKeyFile,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.ui.pages.wordbook_management_page.import_3c273d',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: _compactGreenButtonStyle(context),
                ),
                TextButton.icon(
                  key: const ValueKey<String>('life_crypto_generate_key_file'),
                  onPressed: _busy ? null : _showKeyFileDialog,
                  icon: const Icon(Icons.casino_rounded, size: 18),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.crypto.generate.5b935d8599b2',
                    ),
                  ),
                  style: _compactButtonStyle(),
                ),
                FilledButton.icon(
                  key: const ValueKey<String>('life_crypto_export_key_file'),
                  onPressed: _busy || _keyFileBytes == null
                      ? null
                      : _saveKeyFile,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.ui.pages.practice_notebook_page_actions.export_bc626a',
                    ),
                  ),
                  style: _compactGreenButtonStyle(context),
                ),
                IconButton.outlined(
                  tooltip: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.clear_key_files.6d4d47f368c7',
                  ),
                  onPressed: _busy || !hasKeyFiles ? null : _clearKeyFiles,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle _compactButtonStyle() {
    return const ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      minimumSize: WidgetStatePropertyAll<Size>(Size(0, 36)),
    );
  }

  ButtonStyle _greenActionButtonStyle(BuildContext context) {
    const green = Color(0xFF168A45);
    return FilledButton.styleFrom(
      backgroundColor: green,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest,
      disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      minimumSize: const Size(48, 48),
    );
  }

  ButtonStyle _compactGreenButtonStyle(BuildContext context) {
    return _greenActionButtonStyle(context).copyWith(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 36)),
    );
  }

  String _keyFileSummary(BuildContext context) {
    final count = _keyFileEntries.length;
    final names = _keyFileEntries.take(3).map((entry) => entry.name).join(', ');
    final suffix = count > 3 ? ' +${count - 3}' : '';
    final bytes = _keyFileBytes == null ? 0 : _keyFileBytes!.length;
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.key_file_s.83f8e7cf6c',
      params: <String, Object?>{
        'count': count,
        'p1': _formatBytes(bytes),
        'names': names,
        'suffix': suffix,
      },
    );
  }

  Widget _imageTile({
    required BuildContext context,
    required String titleKey,
    required ui.Image? image,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(context, titleKey),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: image == null
                ? Center(
                    child: Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.crypto.no_preview.b2c10e9d539d',
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RawImage(image: image, fit: BoxFit.contain),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    try {
      final type = switch (_mediaKind) {
        ToolboxSteganographyMediaKind.image => FileType.image,
        ToolboxSteganographyMediaKind.audio => FileType.audio,
        ToolboxSteganographyMediaKind.video => FileType.video,
      };
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: type,
        withData: false,
        withReadStream: true,
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      if (file == null) {
        return;
      }
      final bytes = await _readPickedFileBytes(
        file,
        maxBytes: _maxMediaPickBytes(_mediaKind),
      );
      if (bytes.isEmpty) {
        return;
      }

      ui.Image? preview;
      if (_mediaKind == ToolboxSteganographyMediaKind.image) {
        preview = await _decodePreview(bytes);
      }
      if (!mounted) {
        preview?.dispose();
        return;
      }

      final oldSource = _sourcePreview;
      setState(() {
        _sourceName = file.name;
        _sourcePath = file.path;
        _sourceExtension = file.extension;
        _sourceBytes = bytes;
        _sourcePreview = preview;
        if (_workspace == _CryptoWorkspace.file) {
          _clearFileResults();
        } else {
          _clearResults();
        }
      });
      oldSource?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.failed_to_pick_media.49d8cb7a65',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
    }
  }

  Future<void> _pickKeyFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
        withReadStream: true,
      );
      final files = picked?.files ?? const <PlatformFile>[];
      var totalSize = 0;
      final entries = <_KeyFileEntry>[];
      for (final file in files) {
        _validatePickedFileSize(
          file.size,
          ToolboxCryptoService.maxKeyFileBytes,
        );
        totalSize += file.size;
        if (totalSize > _maxCombinedKeyFileBytes) {
          throw ToolboxSteganographyException(
            'Selected key files are too large. Limit: ${_formatBytes(_maxCombinedKeyFileBytes)}.',
          );
        }
        final bytes = await _readPickedFileBytes(
          file,
          maxBytes: ToolboxCryptoService.maxKeyFileBytes,
        );
        if (bytes.isNotEmpty) {
          entries.add(_KeyFileEntry(name: file.name, bytes: bytes));
        }
      }
      if (entries.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _setKeyFileEntries(entries);
        _useKeyFiles = true;
        _savedPath = null;
        _statusMessage = null;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.failed_to_pick_key_file.bfbd8e09ee',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
    }
  }

  Future<void> _showKeyFileDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.generate_key_file.06f29dbbe70e',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life_crypto_key_file_length'),
                controller: _keyFileLengthController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.bytes.ac32cd01a7f2',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    'inline.plan295.crypto.recommended_at_least_256_bytes_range.d52faaf90aec',
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_lifeI18nText(context, 'cancel')),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _generateKeyFile();
              },
              icon: const Icon(Icons.casino_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.crypto.generate.5b935d8599b2',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateKeyFile() async {
    final length = int.tryParse(_keyFileLengthController.text.trim());
    if (length == null) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan295.crypto.key_file_length_must_be_a_number.d99d926bec5a',
        );
      });
      return;
    }
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = _cryptoService.generateKeyFile(
        length: length,
        fileName: 'vocabulary_sleep_key_${length}b_$timestamp.bin',
      );
      setState(() {
        _setKeyFileEntries(<_KeyFileEntry>[
          _KeyFileEntry(name: result.fileName, bytes: result.bytes),
        ]);
        _useKeyFiles = true;
        _savedPath = null;
        _statusMessage = null;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.key_file_generation_failed.0330236fb2',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
    }
  }

  Future<void> _saveKeyFile() async {
    final bytes = _keyFileBytes;
    if (bytes == null) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
    });
    try {
      final fileName = _keyFileName ?? 'vocabulary_sleep_keyfile.bin';
      final pickedPath = await _pickSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.save_key_file.b4a521515a1f',
        ),
        fileName: fileName,
        extension: 'bin',
        bytes: bytes,
      );
      if (!mounted) {
        return;
      }
      final savedPath = await _saveBytesWithFallback(
        pickedPath: pickedPath,
        bytes: bytes,
        fallbackSegments: <String>['life_tools', 'keys'],
        fallbackFileName: fileName,
      );
      if (!mounted) {
        return;
      }
      if (savedPath == null) {
        if (kIsWeb) {
          setState(() {
            _statusMessage = _lifeI18nText(
              context,
              'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
            );
          });
          return;
        }
        return;
      }
      setState(() => _savedPath = savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.save_key_file_failed.011bfe5571',
          params: <String, Object?>{'error': error},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickCryptoFile() async {
    await _pickAnyFile(
      maxBytes: ToolboxCryptoService.maxPlainBytes,
      onPicked: (file, bytes) {
        _fileName = file.name;
        _fileExtension = file.extension;
        _fileBytes = bytes;
        _clearFileResults();
      },
      errorZh: '选择文件失败',
      errorEn: 'Failed to pick file',
    );
  }

  Future<void> _pickCoverCryptoFile() async {
    await _pickAnyFile(
      maxBytes: ToolboxCryptoService.maxPlainBytes,
      onPicked: (file, bytes) {
        _coverFileName = file.name;
        _coverFileExtension = file.extension;
        _coverFileBytes = bytes;
        _clearFileResults();
      },
      errorZh: '选择表层文件失败',
      errorEn: 'Failed to pick cover file',
    );
  }

  Future<void> _pickHashFile() async {
    await _pickAnyFile(
      maxBytes: ToolboxCryptoService.maxPlainBytes,
      onPicked: (file, bytes) {
        _fileName = file.name;
        _fileExtension = file.extension;
        _fileBytes = bytes;
        _hashResult = null;
        _savedPath = null;
        _statusMessage = null;
        _error = null;
      },
      errorZh: '选择文件失败',
      errorEn: 'Failed to pick file',
    );
  }

  Future<void> _pickAnyFile({
    required int maxBytes,
    required void Function(PlatformFile file, Uint8List bytes) onPicked,
    required String errorZh,
    required String errorEn,
  }) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: false,
        withReadStream: true,
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      if (file == null) {
        return;
      }
      final bytes = await _readPickedFileBytes(file, maxBytes: maxBytes);
      if (bytes.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        onPicked(file, Uint8List.fromList(bytes));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.text.9286016a39',
          params: <String, Object?>{
            'errorZh': errorZh,
            'p1': _friendlyError(context, error),
            'errorEn': errorEn,
          },
        );
      });
    }
  }

  int _maxMediaPickBytes(ToolboxSteganographyMediaKind kind) {
    return switch (kind) {
      ToolboxSteganographyMediaKind.image =>
        ToolboxSteganographyService.maxImageCarrierBytes,
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video =>
        ToolboxSteganographyService.maxTailCarrierBytes,
    };
  }

  Future<Uint8List> _readPickedFileBytes(
    PlatformFile file, {
    required int maxBytes,
  }) async {
    _validatePickedFileSize(file.size, maxBytes);
    final readStream = file.readStream;
    if (readStream != null) {
      return _readStreamBytesBounded(readStream, maxBytes: maxBytes);
    }
    final filePath = file.path;
    if (!kIsWeb && filePath != null && filePath.trim().isNotEmpty) {
      final source = File(filePath);
      final diskLength = await source.length();
      _validatePickedFileSize(diskLength, maxBytes);
      return _readStreamBytesBounded(source.openRead(), maxBytes: maxBytes);
    }
    final bytes = file.bytes;
    if (bytes != null) {
      _validatePickedFileSize(bytes.length, maxBytes);
      return Uint8List.fromList(bytes);
    }
    throw const ToolboxSteganographyException(
      'Selected file cannot be read as a stream.',
    );
  }

  void _validatePickedFileSize(int size, int maxBytes) {
    if (size <= 0) {
      throw const ToolboxSteganographyException('Selected file is empty.');
    }
    if (size > maxBytes) {
      throw ToolboxSteganographyException(
        'Selected file is too large. Limit: ${_formatBytes(maxBytes)}.',
      );
    }
  }

  Future<Uint8List> _readStreamBytesBounded(
    Stream<List<int>> stream, {
    required int maxBytes,
  }) async {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in stream) {
      total += chunk.length;
      if (total > maxBytes) {
        throw ToolboxSteganographyException(
          'Selected file is too large. Limit: ${_formatBytes(maxBytes)}.',
        );
      }
      builder.add(chunk);
    }
    if (total <= 0) {
      throw const ToolboxSteganographyException('Selected file is empty.');
    }
    return builder.takeBytes();
  }

  Future<String?> _pickSavePath({
    required String dialogTitle,
    required String fileName,
    required String extension,
    required Uint8List bytes,
  }) async {
    try {
      return await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: <String>[extension],
        bytes: bytes,
      );
    } on UnimplementedError {
      return null;
    }
  }

  Future<String?> _saveBytesWithFallback({
    required String? pickedPath,
    required Uint8List bytes,
    required List<String> fallbackSegments,
    required String fallbackFileName,
  }) async {
    final normalizedPath = pickedPath?.trim();
    if (normalizedPath != null && normalizedPath.isNotEmpty) {
      if (!kIsWeb) {
        await File(normalizedPath).writeAsBytes(bytes, flush: true);
      }
      return normalizedPath;
    }
    if (kIsWeb) {
      return null;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      path.joinAll(<String>[appDir.path, ...fallbackSegments]),
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final fallback = File(path.join(exportDir.path, fallbackFileName));
    await fallback.writeAsBytes(bytes, flush: true);
    return fallback.path;
  }

  Future<bool> _confirmPlaintextIfNeeded() async {
    if (_encryption != ToolboxCryptoAlgorithm.none) {
      return true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.confirm_plaintext.5b54b2c87d91',
            ),
          ),
          content: Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.no_encryption_is_selected_the_payloa.d305dc3cb84d',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_lifeI18nText(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.crypto.generate_anyway.3cfb2d39c15b',
                ),
              ),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  void _handleMaxErrorAttemptsChanged(String value) {
    setState(() {});
    final attempts = int.tryParse(value.trim());
    if (attempts == null || attempts <= 0 || _maxErrorRiskPromptShown) {
      return;
    }
    _maxErrorRiskPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showMaxErrorAttemptsRiskDialog(attempts);
    });
  }

  void _handleMaxSuccessfulRevealsChanged(String value) {
    setState(() {});
    final attempts = int.tryParse(value.trim());
    if (attempts == null || attempts <= 0 || _successfulRevealRiskPromptShown) {
      return;
    }
    _successfulRevealRiskPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showMaxSuccessfulRevealsRiskDialog(attempts);
    });
  }

  Future<void> _showMaxErrorAttemptsRiskDialog(int attempts) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.wrong_passwords_can_wipe_hidden_data.2bca7d0dab83',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.set_to_during_reveal_reaching_this.555dd57402',
              params: <String, Object?>{'attempts': attempts},
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _lifeI18nText(context, 'inline.plan295.crypto.ok.4eccec341e82'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMaxSuccessfulRevealsRiskDialog(int attempts) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Row(
            children: <Widget>[
              Icon(Icons.auto_delete_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.crypto.successful_reveals_can_wipe_data.2746005621a5',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.hidden_data_will_be_cleaned_after.a96962c9b7',
              params: <String, Object?>{'attempts': attempts},
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _lifeI18nText(context, 'inline.plan295.crypto.ok.4eccec341e82'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _previewTextWrite() async {
    final source = _sourceBytes;
    if (source == null) {
      return;
    }
    final maxErrorAttempts = _readMaxErrorAttemptsSetting();
    if (maxErrorAttempts == null) {
      return;
    }
    final maxSuccessfulReveals = _readMaxSuccessfulRevealsSetting();
    if (maxSuccessfulReveals == null) {
      return;
    }
    await _ensureTextWriteCapacity(
      source: source,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );
  }

  Future<void> _embed() async {
    final source = _sourceBytes;
    if (source == null) {
      return;
    }
    final maxErrorAttempts = _readMaxErrorAttemptsSetting();
    if (maxErrorAttempts == null) {
      return;
    }
    final maxSuccessfulReveals = _readMaxSuccessfulRevealsSetting();
    if (maxSuccessfulReveals == null) {
      return;
    }
    if (!await _ensureTextWriteCapacity(
      source: source,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    )) {
      return;
    }
    if (!await _confirmPlaintextIfNeeded()) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
      _clearResults();
    });
    try {
      final result = await compute(
        _runStegoEmbedText,
        _StegoEmbedTextRequest(
          mediaKind: _mediaKind,
          carrierBytes: source,
          text: _secretController.text,
          dualLayerEnabled: _dualLayerEnabled,
          coverText: _coverSecretController.text,
          encryption: _encryption,
          passphrase: _passphraseController.text,
          coverPassphrase: _coverPassphraseController.text,
          strength: _strength,
          keyFileBytes: _activeKeyFileBytes,
          sourceExtension: _sourceExtension,
          cascade: _selectedCascade,
          keyBits: _keyBits,
          macAlgorithm: _macAlgorithm,
          signatureMode: _signatureMode,
          maxErrorAttempts: maxErrorAttempts,
          maxSuccessfulReveals: maxSuccessfulReveals,
          locatorAlgorithm: _locatorAlgorithm,
          locatorStrength: _locatorStrength,
        ),
      );
      ui.Image? preview;
      if (_mediaKind == ToolboxSteganographyMediaKind.image) {
        preview = await _decodePreview(result.bytes);
      }
      if (!mounted) {
        preview?.dispose();
        return;
      }
      final oldPreview = _outputPreview;
      setState(() {
        _embedResult = result;
        _outputBytes = result.bytes;
        _outputPreview = preview;
        _statusMessage = _lifeI18nText(
          context,
          'inline.plan295.crypto.stego_media_is_ready_export_the_resu.2d6f5c4298f1',
        );
      });
      oldPreview?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.generate_failed.9051755c17',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reveal() async {
    final source = _sourceBytes;
    if (source == null) {
      return;
    }
    if (!_ensureDecodeUnlocked()) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
      _clearResults();
    });
    try {
      final result = await compute(
        _runStegoRevealText,
        _StegoRevealTextRequest(
          mediaKind: _mediaKind,
          carrierBytes: source,
          passphrase: _passphraseController.text,
          keyFileBytes: _activeKeyFileBytes,
          locatorAlgorithm: _locatorAlgorithm,
          locatorStrength: _locatorStrength,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _revealResult = result;
        _statusMessage = _lifeI18nText(
          context,
          'inline.plan295.crypto.text_has_been_revealed_copy_the_data.5964183b7429',
        );
      });
      _registerDecodeSuccess(source);
      await _applySuccessfulRevealProtection(source);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final protectionMessage = await _applyDecodeFailureProtection(
        error,
        source,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final extra = protectionMessage == null ? '' : ' $protectionMessage';
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.reveal_failed.b7699c69e6',
          params: <String, Object?>{
            'p0': _friendlyError(context, error),
            'extra': extra,
          },
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _previewFileWrite() async {
    final carrier = _sourceBytes;
    final file = _fileBytes;
    if (carrier == null || file == null) {
      return;
    }
    if (_dualLayerEnabled &&
        (_coverFileBytes == null || _coverFileBytes!.isEmpty)) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan295.crypto.pick_a_cover_file_first.2c52c7321183',
        );
      });
      return;
    }
    final maxErrorAttempts = _readMaxErrorAttemptsSetting();
    if (maxErrorAttempts == null) {
      return;
    }
    final maxSuccessfulReveals = _readMaxSuccessfulRevealsSetting();
    if (maxSuccessfulReveals == null) {
      return;
    }
    await _ensureFileWriteCapacity(
      carrier: carrier,
      file: file,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );
  }

  Future<void> _encryptFile() async {
    final carrier = _sourceBytes;
    final file = _fileBytes;
    if (carrier == null || file == null) {
      return;
    }
    if (_dualLayerEnabled &&
        (_coverFileBytes == null || _coverFileBytes!.isEmpty)) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan295.crypto.pick_a_cover_file_first.2c52c7321183',
        );
      });
      return;
    }
    final maxErrorAttempts = _readMaxErrorAttemptsSetting();
    if (maxErrorAttempts == null) {
      return;
    }
    final maxSuccessfulReveals = _readMaxSuccessfulRevealsSetting();
    if (maxSuccessfulReveals == null) {
      return;
    }
    if (!await _ensureFileWriteCapacity(
      carrier: carrier,
      file: file,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    )) {
      return;
    }
    if (!await _confirmPlaintextIfNeeded()) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
      _clearFileResults();
    });
    try {
      final result = await compute(
        _runStegoEmbedFile,
        _StegoEmbedFileRequest(
          mediaKind: _mediaKind,
          carrierBytes: carrier,
          fileBytes: file,
          dualLayerEnabled: _dualLayerEnabled,
          coverFileBytes: _coverFileBytes,
          encryption: _encryption,
          passphrase: _passphraseController.text,
          coverPassphrase: _coverPassphraseController.text,
          strength: _strength,
          keyFileBytes: _activeKeyFileBytes,
          sourceExtension: _sourceExtension,
          fileName: _fileName,
          mediaType: _fileExtension,
          coverFileName: _coverFileName,
          coverMediaType: _coverFileExtension,
          cascade: _selectedCascade,
          keyBits: _keyBits,
          macAlgorithm: _macAlgorithm,
          signatureMode: _signatureMode,
          maxErrorAttempts: maxErrorAttempts,
          maxSuccessfulReveals: maxSuccessfulReveals,
          locatorAlgorithm: _locatorAlgorithm,
          locatorStrength: _locatorStrength,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _fileEmbedResult = result;
        _fileOutputBytes = result.bytes;
        _statusMessage = _lifeI18nText(
          context,
          'inline.plan295.crypto.stego_media_is_ready_export_the_resu.2d6f5c4298f1',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.file_encryption_failed.d42af41ff1',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _decryptFile() async {
    final carrier = _sourceBytes;
    if (carrier == null) {
      return;
    }
    if (!_ensureDecodeUnlocked()) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
      _clearFileResults();
    });
    try {
      final result = await compute(
        _runStegoRevealFile,
        _StegoRevealFileRequest(
          mediaKind: _mediaKind,
          carrierBytes: carrier,
          passphrase: _passphraseController.text,
          keyFileBytes: _activeKeyFileBytes,
          locatorAlgorithm: _locatorAlgorithm,
          locatorStrength: _locatorStrength,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _fileRevealResult = result;
        _fileOutputBytes = result.bytes;
        _statusMessage = _lifeI18nText(
          context,
          'inline.plan295.crypto.the_hidden_file_has_been_revealed_ex.59730d54ffe5',
        );
        if (result.fileName != null && result.fileName!.trim().isNotEmpty) {
          _fileName = result.fileName;
          _fileExtension = path
              .extension(result.fileName!)
              .replaceFirst('.', '')
              .trim();
        }
      });
      _registerDecodeSuccess(carrier);
      await _applySuccessfulRevealProtection(carrier);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final protectionMessage = await _applyDecodeFailureProtection(
        error,
        carrier,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final extra = protectionMessage == null ? '' : ' $protectionMessage';
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.file_decryption_failed.a153daac72',
          params: <String, Object?>{
            'p0': _friendlyError(context, error),
            'extra': extra,
          },
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _hashFile() async {
    final source = _fileBytes ?? _sourceBytes;
    if (source == null) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
      _hashResult = null;
    });
    try {
      final result = _cryptoService.hashBytes(
        bytes: source,
        algorithm: _hashAlgorithm,
      );
      if (!mounted) {
        return;
      }
      setState(() => _hashResult = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.hash_failed.127db70632',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveOutput() async {
    final result = _outputBytes;
    final embed = _embedResult;
    if (result == null || embed == null) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
    });
    try {
      final sourceName = _sourceName ?? 'media';
      final baseName = path.basenameWithoutExtension(sourceName);
      final fileName = '${baseName}_stego.${embed.outputExtension}';

      final pickedPath = await _pickSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.save_stego_media.f5e69b4bf942',
        ),
        fileName: fileName,
        extension: embed.outputExtension,
        bytes: result,
      );

      if (!mounted) {
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await _saveBytesWithFallback(
        pickedPath: pickedPath,
        bytes: result,
        fallbackSegments: <String>['life_tools', 'steganography'],
        fallbackFileName: '${baseName}_$timestamp.${embed.outputExtension}',
      );
      if (!mounted) {
        return;
      }
      if (savedPath == null) {
        if (kIsWeb) {
          setState(() {
            _statusMessage = _lifeI18nText(
              context,
              'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
            );
          });
          return;
        }
        return;
      }

      setState(() {
        _savedPath = savedPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.save_failed.733e2f2246',
          params: <String, Object?>{'error': error},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveFileOutput() async {
    final result = _fileOutputBytes;
    if (result == null) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
    });
    try {
      final shouldUnloadCarrier = _fileMode == _FileCryptoMode.decrypt;
      final sourceName = _fileMode == _FileCryptoMode.encrypt
          ? (_sourceName ?? 'media')
          : (_fileRevealResult?.fileName ?? _fileName ?? 'revealed_file.bin');
      final baseName = path.basenameWithoutExtension(sourceName);
      final outputExtension = _fileMode == _FileCryptoMode.encrypt
          ? (_fileEmbedResult?.outputExtension ??
                ToolboxSteganographyService.cleanExtension(_sourceExtension) ??
                (_mediaKind == ToolboxSteganographyMediaKind.image
                    ? 'png'
                    : _mediaKind == ToolboxSteganographyMediaKind.audio
                    ? 'wav'
                    : 'mp4'))
          : (ToolboxSteganographyService.cleanExtension(
                  path.extension(sourceName),
                ) ??
                'bin');
      final fileName = _fileMode == _FileCryptoMode.encrypt
          ? '${baseName}_file_stego.$outputExtension'
          : '${baseName}_revealed.$outputExtension';

      final pickedPath = await _pickSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'inline.plan295.crypto.save_file_result.93309a5473ff',
        ),
        fileName: fileName,
        extension: outputExtension,
        bytes: result,
      );

      if (!mounted) {
        return;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await _saveBytesWithFallback(
        pickedPath: pickedPath,
        bytes: result,
        fallbackSegments: <String>['life_tools', 'steganography'],
        fallbackFileName: '${baseName}_$timestamp.$outputExtension',
      );
      if (!mounted) {
        return;
      }
      if (savedPath == null) {
        if (kIsWeb) {
          ui.Image? oldSource;
          setState(() {
            _statusMessage = shouldUnloadCarrier
                ? _lifeI18nText(
                    context,
                    'inline.plan295.crypto.browser_download_started_check_your.9c21a0a61aae',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
                  );
            if (shouldUnloadCarrier) {
              oldSource = _detachCarrierState();
            }
          });
          oldSource?.dispose();
          return;
        }
        return;
      }
      ui.Image? oldSource;
      setState(() {
        _savedPath = savedPath;
        if (shouldUnloadCarrier) {
          oldSource = _detachCarrierState();
          _statusMessage = _lifeI18nText(
            context,
            'inline.plan295.crypto.the_file_was_exported_and_the_carrie.2dd13d997dc0',
          );
        }
      });
      oldSource?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.save_failed.733e2f2246',
          params: <String, Object?>{'error': error},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<ui.Image> _decodePreview(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _clearResults() {
    final oldOutput = _outputPreview;
    _outputBytes = null;
    _outputPreview = null;
    _embedResult = null;
    _revealResult = null;
    _savedPath = null;
    _statusMessage = null;
    _error = null;
    oldOutput?.dispose();
  }

  void _clearFileResults() {
    _fileOutputBytes = null;
    _fileEmbedResult = null;
    _fileRevealResult = null;
    _writePreview = null;
    _writePreviewOutputBytes = null;
    _savedPath = null;
    _statusMessage = null;
    _error = null;
  }

  void _clearKeyFiles() {
    setState(() {
      _keyFileName = null;
      _keyFileBytes = null;
      _keyFileEntries = const <_KeyFileEntry>[];
    });
  }

  void _setKeyFileEntries(List<_KeyFileEntry> entries) {
    final sorted = entries.toList(growable: false)
      ..sort(_compareKeyFileEntries);
    _keyFileEntries = sorted;
    _keyFileBytes = _combineKeyFileEntries(sorted);
    _keyFileName = sorted.length == 1
        ? sorted.first.name
        : 'vocabulary_sleep_key_bundle_${sorted.length}.bin';
  }

  int _compareKeyFileEntries(_KeyFileEntry left, _KeyFileEntry right) {
    final nameCompare = left.name.toLowerCase().compareTo(
      right.name.toLowerCase(),
    );
    if (nameCompare != 0) {
      return nameCompare;
    }
    final hashCompare = left.digestHex.compareTo(right.digestHex);
    if (hashCompare != 0) {
      return hashCompare;
    }
    return left.bytes.length.compareTo(right.bytes.length);
  }

  Uint8List _combineKeyFileEntries(List<_KeyFileEntry> entries) {
    if (entries.length == 1) {
      return Uint8List.fromList(entries.first.bytes);
    }
    final builder = BytesBuilder(copy: false)
      ..add(utf8.encode('vocabulary_sleep_keyfile_bundle_v1'))
      ..addByte(0);
    for (final entry in entries) {
      final nameBytes = utf8.encode(entry.name);
      final digestBytes = base64Decode(entry.digestBase64);
      builder
        ..add(_uint32Bytes(nameBytes.length))
        ..add(nameBytes)
        ..add(_uint32Bytes(entry.bytes.length))
        ..add(digestBytes)
        ..add(entry.bytes);
    }
    return builder.takeBytes();
  }

  void _resetFileCrypto() {
    setState(() {
      _fileName = null;
      _fileExtension = null;
      _fileBytes = null;
      _clearFileResults();
    });
  }

  void _resetCoverFileCrypto() {
    setState(() {
      _coverFileName = null;
      _coverFileExtension = null;
      _coverFileBytes = null;
      _clearFileResults();
    });
  }

  void _resetFileCarrier() {
    final oldSource = _sourcePreview;
    setState(() {
      _sourceName = null;
      _sourcePath = null;
      _sourceExtension = null;
      _sourceBytes = null;
      _sourcePreview = null;
      _clearFileResults();
    });
    oldSource?.dispose();
  }

  void _resetHash() {
    setState(() {
      _fileName = null;
      _fileExtension = null;
      _fileBytes = null;
      _coverFileName = null;
      _coverFileExtension = null;
      _coverFileBytes = null;
      _hashResult = null;
      _savedPath = null;
      _statusMessage = null;
      _error = null;
    });
  }

  void _clearSourceAndResult() {
    final oldSource = _sourcePreview;
    _sourceName = null;
    _sourcePath = null;
    _sourceExtension = null;
    _sourceBytes = null;
    _sourcePreview = null;
    _clearResults();
    _clearFileResults();
    oldSource?.dispose();
  }

  ui.Image? _detachCarrierState() {
    final oldSource = _sourcePreview;
    _sourceName = null;
    _sourcePath = null;
    _sourceExtension = null;
    _sourceBytes = null;
    _sourcePreview = null;
    return oldSource;
  }

  void _resetAll() {
    setState(() {
      _clearSourceAndResult();
      _clearSecretInputs();
    });
  }

  void _clearSecretInputs() {
    _useKeyFiles = false;
    _keyFileName = null;
    _keyFileBytes = null;
    _keyFileEntries = const <_KeyFileEntry>[];
    _secretController.clear();
    _coverSecretController.clear();
    _passphraseController.clear();
    _coverPassphraseController.clear();
  }

  List<ToolboxCryptoCascadeCipher>? get _selectedCascade =>
      _encryption == ToolboxCryptoAlgorithm.customCascade ? _cascade : null;

  ToolboxCryptoSignatureMode get _effectiveSignatureMode {
    return switch (_encryption) {
      ToolboxCryptoAlgorithm.sha256RsaSignature =>
        ToolboxCryptoSignatureMode.rsaSha256,
      ToolboxCryptoAlgorithm.ecdsaSignature =>
        ToolboxCryptoSignatureMode.ecdsaSha256,
      _ => _signatureMode,
    };
  }

  Uint8List? get _activeKeyFileBytes => _useKeyFiles ? _keyFileBytes : null;

  bool get _shouldShowPreviewPanel =>
      _sourcePreview != null || _outputPreview != null;

  Duration? get _decodeLockRemaining {
    final source = _sourceBytes;
    if (source == null) {
      return null;
    }
    return _decodeLockRemainingForKey(_currentSourceFailureKey(source));
  }

  Duration? _decodeLockRemainingForKey(String key) {
    final lockedUntil = _decodeLockedUntilByCarrier[key];
    if (lockedUntil == null) {
      return null;
    }
    final remaining = lockedUntil.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _decodeLockedUntilByCarrier.remove(key);
      return null;
    }
    return remaining;
  }

  bool get _isDecodeLocked => _decodeLockRemaining != null;

  bool get _isRevealMode {
    return switch (_workspace) {
      _CryptoWorkspace.steganography => _mode == _StegoMode.reveal,
      _CryptoWorkspace.file => _fileMode == _FileCryptoMode.decrypt,
      _CryptoWorkspace.hash => false,
    };
  }

  bool get _isUnsupportedMediaWrite {
    return false;
  }

  int? _readMaxErrorAttemptsSetting() {
    final raw = _maxErrorAttemptsController.text.trim();
    final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      _maxErrorAttemptsController.text = '0';
      _maxErrorAttemptsController.selection = TextSelection.collapsed(
        offset: _maxErrorAttemptsController.text.length,
      );
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan295.crypto.max_wrong_attempts_must_be_an_intege.aa06f0b0cb1f',
        );
      });
      return null;
    }
    return parsed;
  }

  int? _readMaxSuccessfulRevealsSetting() {
    final raw = _maxSuccessfulRevealsController.text.trim();
    final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      _maxSuccessfulRevealsController.text = '0';
      _maxSuccessfulRevealsController.selection = TextSelection.collapsed(
        offset: _maxSuccessfulRevealsController.text.length,
      );
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan295.crypto.max_successful_reveals_must_be_an_in.4d51465ac069',
        );
      });
      return null;
    }
    return parsed;
  }

  Future<bool> _ensureTextWriteCapacity({
    required Uint8List source,
    required int maxErrorAttempts,
    required int maxSuccessfulReveals,
  }) async {
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = _lifeI18nText(
        context,
        'inline.plan295.crypto.checking_carrier_capacity.ff0b23d0b83f',
      );
      _error = null;
    });
    try {
      final check = await compute(
        _runStegoTextCapacityCheck,
        _StegoTextCapacityRequest(
          mediaKind: _mediaKind,
          carrierBytes: source,
          text: _secretController.text,
          dualLayerEnabled: _dualLayerEnabled,
          coverText: _coverSecretController.text,
          encryption: _encryption,
          passphrase: _passphraseController.text,
          coverPassphrase: _coverPassphraseController.text,
          strength: _strength,
          keyFileBytes: _activeKeyFileBytes,
          cascade: _selectedCascade,
          keyBits: _keyBits,
          macAlgorithm: _macAlgorithm,
          signatureMode: _signatureMode,
          maxErrorAttempts: maxErrorAttempts,
          maxSuccessfulReveals: maxSuccessfulReveals,
        ),
      );
      if (!mounted) {
        return false;
      }
      if (!check.fits) {
        setState(() {
          _clearResults();
          _statusMessage = null;
          _writePreview = null;
          _writePreviewOutputBytes = null;
          _error = _capacityCheckText(context, check);
        });
        return false;
      }
      setState(() {
        _clearResults();
        _writePreview = check;
        _writePreviewOutputBytes = _estimatedOutputBytes(
          sourceBytes: source.length,
          check: check,
        );
        _statusMessage = null;
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _clearResults();
        _statusMessage = null;
        _writePreview = null;
        _writePreviewOutputBytes = null;
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.preflight_check_failed.c49c74dffb',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _ensureFileWriteCapacity({
    required Uint8List carrier,
    required Uint8List file,
    required int maxErrorAttempts,
    required int maxSuccessfulReveals,
  }) async {
    setState(() {
      _busy = true;
      _savedPath = null;
      _statusMessage = _lifeI18nText(
        context,
        'inline.plan295.crypto.checking_carrier_capacity.ff0b23d0b83f',
      );
      _error = null;
    });
    try {
      final check = await compute(
        _runStegoFileCapacityCheck,
        _StegoFileCapacityRequest(
          mediaKind: _mediaKind,
          carrierBytes: carrier,
          fileBytes: file,
          dualLayerEnabled: _dualLayerEnabled,
          coverFileBytes: _coverFileBytes,
          fileName: _fileName,
          coverFileName: _coverFileName,
          encryption: _encryption,
          passphrase: _passphraseController.text,
          coverPassphrase: _coverPassphraseController.text,
          strength: _strength,
          keyFileBytes: _activeKeyFileBytes,
          mediaType: _fileExtension,
          coverMediaType: _coverFileExtension,
          cascade: _selectedCascade,
          keyBits: _keyBits,
          macAlgorithm: _macAlgorithm,
          signatureMode: _signatureMode,
          maxErrorAttempts: maxErrorAttempts,
          maxSuccessfulReveals: maxSuccessfulReveals,
        ),
      );
      if (!mounted) {
        return false;
      }
      if (!check.fits) {
        setState(() {
          _clearFileResults();
          _statusMessage = null;
          _writePreview = null;
          _writePreviewOutputBytes = null;
          _error = _capacityCheckText(context, check);
        });
        return false;
      }
      setState(() {
        _clearFileResults();
        _writePreview = check;
        _writePreviewOutputBytes = _estimatedOutputBytes(
          sourceBytes: carrier.length,
          check: check,
        );
        _statusMessage = null;
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _clearFileResults();
        _statusMessage = null;
        _writePreview = null;
        _writePreviewOutputBytes = null;
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.preflight_check_failed.c49c74dffb',
          params: <String, Object?>{'p0': _friendlyError(context, error)},
        );
      });
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _capacityCheckText(
    BuildContext context,
    ToolboxSteganographyCapacityCheck check,
  ) {
    final side = math.max(1, math.sqrt(check.minimumPixels).ceil());
    if (check.mediaKind == ToolboxSteganographyMediaKind.audio) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.the_payload_exceeds_this_wav_pcm.357a1e2e89',
        params: <String, Object?>{
          'p0': _formatBytes(check.capacityBytes),
          'p1': _formatBytes(check.requiredBytes),
          'p2': _formatBytes(check.minimumCarrierBytes ?? 0),
          'p3': _formatBytes(ToolboxSteganographyService.maxTailCarrierBytes),
        },
      );
    }
    if (check.mediaKind == ToolboxSteganographyMediaKind.video) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.the_payload_exceeds_this_mp4_mov.b750508333',
        params: <String, Object?>{
          'p0': _formatBytes(check.capacityBytes),
          'p1': _formatBytes(check.requiredBytes),
          'p2': _formatBytes(ToolboxSteganographyService.maxTailCarrierBytes),
        },
      );
    }
    if (check.dualLayer) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.the_payload_exceeds_this_image_capacity.b5e206c196',
        params: <String, Object?>{
          'width': check.width,
          'height': check.height,
          'p2': _formatBytes(check.perLayerCapacityBytes ?? 0),
          'p3': _formatBytes(check.coverRequiredBytes ?? 0),
          'p4': _formatBytes(check.hiddenRequiredBytes ?? 0),
          'side': side,
          'maxImagePixels': ToolboxSteganographyService.maxImagePixels,
          'p7': _formatBytes(ToolboxSteganographyService.maxImageCarrierBytes),
        },
      );
    }
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.the_payload_exceeds_this_image_capacity.6da5ecf7a2',
      params: <String, Object?>{
        'width': check.width,
        'height': check.height,
        'p2': _formatBytes(check.capacityBytes),
        'p3': _formatBytes(check.requiredBytes),
        'side': side,
        'maxImagePixels': ToolboxSteganographyService.maxImagePixels,
        'p6': _formatBytes(ToolboxSteganographyService.maxImageCarrierBytes),
      },
    );
  }

  int _estimatedOutputBytes({
    required int sourceBytes,
    required ToolboxSteganographyCapacityCheck check,
  }) {
    return switch (check.mediaKind) {
      ToolboxSteganographyMediaKind.image => sourceBytes,
      ToolboxSteganographyMediaKind.audio => sourceBytes,
      ToolboxSteganographyMediaKind.video =>
        sourceBytes +
            (check.dualLayer
                ? check.requiredBytes
                : _estimatedMp4Growth(check.requiredBytes)),
    };
  }

  int _estimatedMp4Growth(int blockBytes) {
    const overhead = 8 + 23 + 36 + 255;
    return blockBytes + overhead;
  }

  String _maxErrorAttemptsRiskText(BuildContext context) {
    final raw = _maxErrorAttemptsController.text.trim();
    final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      return _lifeI18nText(
        context,
        'inline.plan295.crypto.invalid_input_use_0_255_it_will_rese.2082059fb1e5',
      );
    }
    final current = parsed == 0
        ? _lifeI18nText(context, 'inline.plan295.crypto.unlimited.f2b082dc2b60')
        : _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.attempt_s.791b90caaa',
            params: <String, Object?>{'parsed': parsed},
          );
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.current_maximum_255_reaching_the_limit.c2addfc0a4',
      params: <String, Object?>{'current': current},
    );
  }

  String _maxSuccessfulRevealsRiskText(BuildContext context) {
    final raw = _maxSuccessfulRevealsController.text.trim();
    final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      return _lifeI18nText(
        context,
        'inline.plan295.crypto.invalid_input_use_0_255_it_will_rese.f51193f604ca',
      );
    }
    final current = parsed == 0
        ? _lifeI18nText(context, 'inline.plan295.crypto.unlimited.7ab81d778468')
        : _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.reveal_s.ef7097bdac',
            params: <String, Object?>{'parsed': parsed},
          );
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.current_hidden_data_is_cleaned_after.5d209883f4',
      params: <String, Object?>{'current': current},
    );
  }

  bool _ensureDecodeUnlocked() {
    final source = _sourceBytes;
    if (source == null) {
      return true;
    }
    final key = _currentSourceFailureKey(source);
    final remaining = _decodeLockRemainingForKey(key);
    if (remaining == null) {
      return true;
    }
    setState(() {
      _error = _decodeLockText(context, remaining);
    });
    return false;
  }

  void _registerDecodeSuccess(Uint8List source) {
    final key = _currentSourceFailureKey(source);
    _decodeErrorTimesByCarrier.remove(key);
    _decodeLockedUntilByCarrier.remove(key);
    _protectedDecodeFailuresByCarrier.remove(key);
  }

  Future<void> _applySuccessfulRevealProtection(
    Uint8List sourceSnapshot,
  ) async {
    try {
      final result = await compute(
        _runStegoSuccessfulRevealProtection,
        _StegoSuccessfulRevealProtectionRequest(
          mediaKind: _mediaKind,
          carrierBytes: sourceSnapshot,
          passphrase: _passphraseController.text,
          keyFileBytes: _activeKeyFileBytes,
          locatorAlgorithm: _locatorAlgorithm,
          locatorStrength: _locatorStrength,
        ),
      );
      if (!mounted || !result.changed) {
        return;
      }
      var wroteSource = false;
      final sourcePath = _sourcePath;
      if (!kIsWeb && sourcePath != null && sourcePath.trim().isNotEmpty) {
        await File(sourcePath).writeAsBytes(result.bytes, flush: true);
        wroteSource = true;
      }
      if (result.removed) {
        if (!mounted) {
          return;
        }
        ui.Image? oldSource;
        setState(() {
          oldSource = _detachCarrierState();
          _statusMessage = wroteSource
              ? AppI18n(Localizations.localeOf(context).languageCode).t(
                  'inline.plan295.crypto.successful_reveal_limit_was_reached.5435e8975742',
                )
              : AppI18n(Localizations.localeOf(context).languageCode).t(
                  'inline.plan295.crypto.successful_reveal_limit_was_reached.7384f1352063',
                );
        });
        oldSource?.dispose();
        return;
      }
      ui.Image? preview;
      if (_mediaKind == ToolboxSteganographyMediaKind.image) {
        preview = await _decodePreview(result.bytes);
      }
      if (!mounted) {
        preview?.dispose();
        return;
      }
      final oldSource = _sourcePreview;
      setState(() {
        _sourceBytes = result.bytes;
        _sourcePreview = preview;
        _statusMessage = wroteSource
            ? AppI18n(Localizations.localeOf(context).languageCode).t(
                'inline.plan295.crypto.remaining_successful_reveals_result.c34efd72ab27',
                params: <String, Object?>{
                  'resultRemainingSuccessfulReveals':
                      result.remainingSuccessfulReveals,
                  'result.remainingSuccessfulReveals':
                      result.remainingSuccessfulReveals,
                },
              )
            : AppI18n(Localizations.localeOf(context).languageCode).t(
                'inline.plan295.crypto.remaining_successful_reveals_result.d4becbbdd62c',
                params: <String, Object?>{
                  'resultRemainingSuccessfulReveals':
                      result.remainingSuccessfulReveals,
                  'result.remainingSuccessfulReveals':
                      result.remainingSuccessfulReveals,
                },
              );
      });
      oldSource?.dispose();
    } on Object {
      // Successful reveal protection is best-effort; the revealed payload stays available.
    }
  }

  _DecodeFailureStatus _registerDecodeFailure(Uint8List source) {
    final key = _currentSourceFailureKey(source);
    final existingLock = _decodeLockRemainingForKey(key);
    if (existingLock != null) {
      return _DecodeFailureStatus(
        windowCount: _decodeErrorTimesByCarrier[key]?.length ?? 0,
        locked: true,
        remaining: existingLock,
      );
    }
    final now = DateTime.now();
    final times = _decodeErrorTimesByCarrier.putIfAbsent(
      key,
      () => <DateTime>[],
    );
    times.removeWhere((time) => now.difference(time) > _decodeErrorWindow);
    times.add(now);
    if (times.length >= _decodeErrorLimit) {
      times.clear();
      _decodeLockedUntilByCarrier[key] = now.add(_decodeLockDuration);
      _decodeUnlockTimer?.cancel();
      _decodeUnlockTimer = Timer(_decodeLockDuration, () {
        if (!mounted) {
          return;
        }
        _decodeLockRemainingForKey(key);
        setState(() {});
      });
      return const _DecodeFailureStatus(
        windowCount: _decodeErrorLimit,
        locked: true,
        remaining: _decodeLockDuration,
      );
    }
    return _DecodeFailureStatus(windowCount: times.length, locked: false);
  }

  Future<String?> _applyDecodeFailureProtection(
    Object error,
    Uint8List source,
  ) async {
    final key = _currentSourceFailureKey(source);
    final decodeStatus = _registerDecodeFailure(source);
    final message = switch (error) {
      ToolboxSteganographyException(:final message) => message,
      ToolboxCryptoException(:final message) => message,
      _ => null,
    };
    if (message == 'Hidden payload tamper check failed.') {
      return _wipeCurrentHiddenData(
        zhReason:
            '检测到隐写数据被修改；${_decodeFailureStatusText(context, decodeStatus)} 已尝试清理当前载体。',
        enReason:
            'Hidden data appears to be tampered with; ${_decodeFailureStatusText(context, decodeStatus)} The current carrier was cleaned when possible.',
        sourceSnapshot: source,
        sourceKey: key,
      );
    }

    try {
      final policy = _service.inspectProtectionPolicy(
        mediaKind: _mediaKind,
        carrierBytes: source,
        passphrase: _passphraseController.text,
        keyFileBytes: _activeKeyFileBytes,
        locatorAlgorithm: _locatorAlgorithm,
        locatorStrength: _locatorStrength,
      );
      final maxAttempts = policy.maxErrorAttempts;
      if (maxAttempts > 0) {
        final count = (_protectedDecodeFailuresByCarrier[key] ?? 0) + 1;
        _protectedDecodeFailuresByCarrier[key] = count;
        if (count >= maxAttempts) {
          _protectedDecodeFailuresByCarrier.remove(key);
          return _wipeCurrentHiddenData(
            zhReason:
                '${_decodeFailureStatusText(context, decodeStatus)} 已达到隐写载荷限制，已尝试清理当前载体。',
            enReason:
                '${_decodeFailureStatusText(context, decodeStatus)} The hidden payload attempt limit was reached. The current carrier was cleaned when possible.',
            sourceSnapshot: source,
            sourceKey: key,
          );
        }
        return _decodeFailureStatusText(context, decodeStatus);
      }
    } on Object {
      // If the policy cannot be read, the module-level lock still applies.
    }
    return _decodeFailureStatusText(context, decodeStatus);
  }

  String _decodeFailureStatusText(
    BuildContext context,
    _DecodeFailureStatus status,
  ) {
    if (status.locked) {
      return _decodeLockText(context, status.remaining ?? _decodeLockDuration);
    }
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.current_file_error_count.d454c2a872',
      params: <String, Object?>{'windowCount': status.windowCount},
    );
  }

  String _decodeLockText(BuildContext context, Duration remaining) {
    final minutes = math.max(1, remaining.inMinutes + 1);
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.reveal_for_the_current_file_is.c2ac6b41df',
      params: <String, Object?>{'minutes': minutes},
    );
  }

  String _currentSourceFailureKey(Uint8List source) {
    final digest = sha256.convert(source).toString();
    final sourcePath = _sourcePath;
    return sourcePath == null ? digest : '$sourcePath:$digest';
  }

  Future<String?> _wipeCurrentHiddenData({
    required String zhReason,
    required String enReason,
    required Uint8List sourceSnapshot,
    required String sourceKey,
  }) async {
    try {
      final stripped = _service.stripHiddenData(
        mediaKind: _mediaKind,
        carrierBytes: sourceSnapshot,
        passphrase: _passphraseController.text,
        keyFileBytes: _activeKeyFileBytes,
        locatorAlgorithm: _locatorAlgorithm,
        locatorStrength: _locatorStrength,
      );
      if (!stripped.removed) {
        return null;
      }
      _decodeErrorTimesByCarrier.remove(sourceKey);
      _decodeLockedUntilByCarrier.remove(sourceKey);
      _protectedDecodeFailuresByCarrier.remove(sourceKey);
      var wroteSource = false;
      final sourcePath = _sourcePath;
      if (!kIsWeb && sourcePath != null && sourcePath.trim().isNotEmpty) {
        await File(sourcePath).writeAsBytes(stripped.bytes, flush: true);
        wroteSource = true;
      }
      if (!mounted) {
        return null;
      }
      final oldOutput = _outputPreview;
      ui.Image? oldSource;
      setState(() {
        oldSource = _detachCarrierState();
        _outputBytes = null;
        _outputPreview = null;
        _embedResult = null;
        _revealResult = null;
        _fileOutputBytes = null;
        _fileEmbedResult = null;
        _fileRevealResult = null;
      });
      oldSource?.dispose();
      oldOutput?.dispose();
      final target = wroteSource
          ? _lifeI18nText(
              context,
              'inline.plan295.crypto.source_file_was_overwritten_and_the.fa084b5dac75',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.crypto.current_in_memory_carrier_was_cleane.42b8531024cf',
            );
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.text.6aa573903c',
        params: <String, Object?>{
          'zhReason': zhReason,
          'target': target,
          'enReason': enReason,
        },
      );
    } on Object {
      return null;
    }
  }

  IconData _mediaIcon(ToolboxSteganographyMediaKind kind) {
    return switch (kind) {
      ToolboxSteganographyMediaKind.image => Icons.image_rounded,
      ToolboxSteganographyMediaKind.audio => Icons.audiotrack_rounded,
      ToolboxSteganographyMediaKind.video => Icons.movie_rounded,
    };
  }

  String _mediaLabel(BuildContext context, ToolboxSteganographyMediaKind kind) {
    return switch (kind) {
      ToolboxSteganographyMediaKind.image => _lifeI18nText(
        context,
        'inline.plan295.crypto.image.baebdc30e7e4',
      ),
      ToolboxSteganographyMediaKind.audio => _lifeI18nText(
        context,
        'inline.plan295.crypto.audio.253158c06f3c',
      ),
      ToolboxSteganographyMediaKind.video => _lifeI18nText(
        context,
        'inline.plan295.crypto.video.2074eae3b2ea',
      ),
    };
  }

  String _workspaceLabel(BuildContext context, _CryptoWorkspace workspace) {
    return switch (workspace) {
      _CryptoWorkspace.steganography => _lifeI18nText(
        context,
        'inline.plan295.crypto.stego.1cc36bd69b84',
      ),
      _CryptoWorkspace.file => _lifeI18nText(
        context,
        'inline.plan295.crypto.file_crypto.4c82d6da1401',
      ),
      _CryptoWorkspace.hash => _lifeI18nText(
        context,
        'inline.plan295.crypto.hash.c499c69bcca6',
      ),
    };
  }

  String _algorithmSafetyText(
    BuildContext context,
    ToolboxCryptoAlgorithm encryption,
  ) {
    return switch (encryption) {
      ToolboxCryptoAlgorithm.none => _lifeI18nText(
        context,
        'inline.plan295.crypto.safety_plaintext_payloads_are_not_en.c9d14d506bae',
      ),
      ToolboxCryptoAlgorithm.sha256Stream => _lifeI18nText(
        context,
        'inline.plan295.crypto.safety_weak_reveal_only_for_legacy_p.61ee18060c48',
      ),
      ToolboxCryptoAlgorithm.rc4Legacy => _lifeI18nText(
        context,
        'inline.plan295.crypto.safety_weak_reveal_only_for_legacy_r.b2d2476f90d6',
      ),
      ToolboxCryptoAlgorithm.aesTwofishGcm ||
      ToolboxCryptoAlgorithm.aesCamelliaGcm ||
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm ||
      ToolboxCryptoAlgorithm.customCascade => _lifeI18nText(
        context,
        'inline.plan295.crypto.safety_strong_uses_scrypt_from_2_16.8feed7f300b8',
      ),
      _ => _lifeI18nText(
        context,
        'inline.plan295.crypto.safety_strong_uses_at_least_256_bit.613a35fa8bda',
      ),
    };
  }

  String _signaturePerformanceText(BuildContext context) {
    return switch (_effectiveSignatureMode) {
      ToolboxCryptoSignatureMode.weakSha256 => _lifeI18nText(
        context,
        'inline.plan295.crypto.weak_signature_is_a_fast_lightweight.f453d8022986',
      ),
      ToolboxCryptoSignatureMode.rsaSha256 ||
      ToolboxCryptoSignatureMode.ecdsaSha256 => _lifeI18nText(
        context,
        'inline.plan295.crypto.rsa_ecdsa_are_high_cost_integrity_ch.4d07d07f51af',
      ),
      ToolboxCryptoSignatureMode.none => '',
    };
  }

  String _encryptionLabel(
    BuildContext context,
    ToolboxCryptoAlgorithm encryption,
  ) {
    return switch (encryption) {
      ToolboxCryptoAlgorithm.aesGcm => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.aes_gcm_110e45',
      ),
      ToolboxCryptoAlgorithm.chacha20Poly1305 => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.chacha20_poly1305_6ca5b2',
      ),
      ToolboxCryptoAlgorithm.twofishGcm => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.twofish_gcm_5aebe0',
      ),
      ToolboxCryptoAlgorithm.camelliaGcm => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.camellia_gcm_55360c',
      ),
      ToolboxCryptoAlgorithm.aesTwofishGcm => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.aes_twofish_d984ce',
      ),
      ToolboxCryptoAlgorithm.aesCamelliaGcm => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.aes_camellia_37b745',
      ),
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm => _lifeI18nText(
        context,
        'literal.services.toolbox_crypto_service.aes_twofish_camellia_a9f46e',
      ),
      ToolboxCryptoAlgorithm.customCascade => _lifeI18nText(
        context,
        'inline.plan295.crypto.custom_cascade.d93fe5b2930c',
      ),
      ToolboxCryptoAlgorithm.sha256RsaSignature => _lifeI18nText(
        context,
        'inline.plan295.crypto.sha_256_rsa_signature.4ad2344cb150',
      ),
      ToolboxCryptoAlgorithm.ecdsaSignature => _lifeI18nText(
        context,
        'inline.plan295.crypto.ecdsa_signature.703fd2ae2949',
      ),
      ToolboxCryptoAlgorithm.whirlpoolDigest => _lifeI18nText(
        context,
        'inline.plan295.crypto.whirlpool_mac.c8b95dda4d12',
      ),
      ToolboxCryptoAlgorithm.sha256Stream => _lifeI18nText(
        context,
        'inline.plan295.crypto.sha256_stream.497d6a375d82',
      ),
      ToolboxCryptoAlgorithm.rc4Legacy => _lifeI18nText(
        context,
        'inline.plan295.crypto.rc4_legacy.4fb4fec5554f',
      ),
      ToolboxCryptoAlgorithm.none => _lifeI18nText(
        context,
        'inline.plan295.crypto.no_encryption.86752caad95a',
      ),
    };
  }

  String _cascadeLabel(
    BuildContext context,
    ToolboxCryptoCascadeCipher cipher,
  ) {
    return switch (cipher) {
      ToolboxCryptoCascadeCipher.aes => 'AES',
      ToolboxCryptoCascadeCipher.chacha20 => 'ChaCha20',
      ToolboxCryptoCascadeCipher.twofish => 'Twofish',
      ToolboxCryptoCascadeCipher.camellia => 'Camellia',
      ToolboxCryptoCascadeCipher.sha256Stream => _lifeI18nText(
        context,
        'inline.plan295.crypto.sha256_stream.497d6a375d82',
      ),
    };
  }

  String _strengthLabel(BuildContext context, ToolboxCryptoStrength strength) {
    return switch (strength) {
      ToolboxCryptoStrength.standard => _lifeI18nText(
        context,
        'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
      ),
      ToolboxCryptoStrength.strong => _lifeI18nText(
        context,
        'inline.plan295.crypto.strong.1871a3e17f16',
      ),
      ToolboxCryptoStrength.extreme => _lifeI18nText(
        context,
        'inline.plan295.crypto.extreme.9e40ee107b5e',
      ),
    };
  }

  String _hashLabel(
    BuildContext context,
    ToolboxCryptoHashAlgorithm algorithm,
  ) {
    return switch (algorithm) {
      ToolboxCryptoHashAlgorithm.sha256 => 'SHA-256',
      ToolboxCryptoHashAlgorithm.sha512 => 'SHA-512',
      ToolboxCryptoHashAlgorithm.sha3_256 => 'SHA3-256',
      ToolboxCryptoHashAlgorithm.sha3_512 => 'SHA3-512',
      ToolboxCryptoHashAlgorithm.blake2b256 => 'BLAKE2b-256',
      ToolboxCryptoHashAlgorithm.blake2b512 => 'BLAKE2b-512',
      ToolboxCryptoHashAlgorithm.whirlpool => 'Whirlpool',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  Uint8List _uint32Bytes(int value) {
    return Uint8List.fromList(<int>[
      (value >> 24) & 255,
      (value >> 16) & 255,
      (value >> 8) & 255,
      value & 255,
    ]);
  }

  String _friendlyError(BuildContext context, Object error) {
    final message = switch (error) {
      ToolboxSteganographyException(:final message) => message,
      ToolboxCryptoException(:final message) => message,
      _ => null,
    };
    if (message == null) {
      return '$error';
    }
    return switch (message) {
      'Source media is empty.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.source_media_is_empty_f981db',
      ),
      'Input bytes are empty.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.input_bytes_are_empty_963697',
      ),
      'Secret text is empty.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.secret_text_is_empty_8db87a',
      ),
      'This encryption mode requires a passphrase or key file.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.this_encryption_mode_requires_a_passphrase_or_key_file_682033',
      ),
      'This encryption mode requires a passphrase.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.this_encryption_mode_requires_a_passphrase_ef206a',
      ),
      'Passphrase or key file is required.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.passphrase_or_key_file_is_required_2c18e5',
      ),
      'Key file mismatch or missing key file.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.key_file_mismatch_or_missing_key_file_866ed2',
      ),
      'Legacy or weak algorithms can only decrypt existing payloads.' =>
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.legacy_or_weak_algorithms_can_only_decrypt_existing_payl_8b8564',
        ),
      'SHA256 stream can only decrypt existing legacy payloads.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.sha256_stream_can_only_decrypt_existing_legacy_payloads_6cc0e2',
      ),
      'Audio steganography requires a frequency-domain backend before new payloads can be generated.' =>
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.audio_steganography_requires_a_frequency_domain_backend_5d676c',
        ),
      'Video steganography requires a frame-level or motion-vector backend before new payloads can be generated.' =>
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.video_steganography_requires_a_frame_level_or_motion_vec_193d4a',
        ),
      'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.' =>
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.unsupported_image_format_pick_png_jpg_webp_gif_style_ima_e5fc6b',
        ),
      'Unsupported image format or no hidden payload found.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.unsupported_image_format_or_no_hidden_payload_found_aa3cff',
      ),
      'Image is too small.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.image_is_too_small_cea140',
      ),
      'No hidden image payload found.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.no_hidden_image_payload_found_620d89',
      ),
      'Hidden image payload is damaged or incomplete.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_image_payload_is_damaged_or_incomplete_c5f981',
      ),
      'No hidden payload found.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.no_hidden_payload_found_673c74',
      ),
      'Hidden payload is damaged or incomplete.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_payload_is_damaged_or_incomplete_ad8e2a',
      ),
      'Unsupported payload version.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.unsupported_payload_version_787bf2',
      ),
      'Unsupported crypto version.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.unsupported_crypto_version_d47531',
      ),
      'Hidden payload is invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_payload_is_invalid_edfa3f',
      ),
      'Crypto envelope is invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.crypto_envelope_is_invalid_d06fb8',
      ),
      'Crypto envelope is too large.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.crypto_envelope_is_too_large_7e830a',
      ),
      'Crypto KDF parameters are invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.crypto_kdf_parameters_are_invalid_4b6aaf',
      ),
      'This payload requires a passphrase.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.this_payload_requires_a_passphrase_faaf89',
      ),
      'Passphrase mismatch or payload is damaged.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.passphrase_mismatch_or_payload_is_damaged_b73f8c',
      ),
      'Payload is damaged.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.payload_is_damaged_cb7dd6',
      ),
      'Payload checksum failed.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.payload_checksum_failed_7f5459',
      ),
      'Payload padding is invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.payload_padding_is_invalid_4d30d9',
      ),
      'Payload text is not valid UTF-8.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.payload_text_is_not_valid_utf_8_05aaa3',
      ),
      'Hidden payload header is invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_payload_header_is_invalid_60d5ac',
      ),
      'Hidden payload length is invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_payload_length_is_invalid_600382',
      ),
      'Hidden payload body is invalid.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_payload_body_is_invalid_43f76e',
      ),
      'Hidden payload tamper check failed.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.hidden_payload_tamper_check_failed_c1de3f',
      ),
      'Max error attempts must be between 0 and 255.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.max_error_attempts_must_be_between_0_and_255_3479c5',
      ),
      'Max successful reveals must be between 0 and 255.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.max_successful_reveals_must_be_between_0_and_255_5c0d55',
      ),
      'Carrier already contains hidden data. Use the original carrier, clear the hidden data, or embed the encrypted file as a new payload.' =>
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.carrier_already_contains_hidden_data_use_the_original_ca_ebd54f',
        ),
      'Dual-layer mode currently supports image carriers only.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.dual_layer_mode_currently_supports_image_carriers_only_c8fa28',
      ),
      'Dual-layer mode requires both passphrases.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.dual_layer_mode_requires_both_passphrases_d983b4',
      ),
      'Dual-layer passphrases must be different.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.dual_layer_passphrases_must_be_different_7af16f',
      ),
      'Payload is too large.' => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.payload_is_too_large_23c83a',
      ),
      'Input file is too large.' => _lifeI18nText(
        context,
        'inline.plan296.crypto.error.input_file_too_large_with_limit',
        params: <String, Object?>{
          'limit': _formatBytes(ToolboxCryptoService.maxPlainBytes),
        },
      ),
      'Source media is too large.' => _lifeI18nText(
        context,
        'inline.plan296.crypto.error.source_media_too_large_with_limit',
        params: <String, Object?>{
          'limit': _formatBytes(
            ToolboxSteganographyService.maxTailCarrierBytes,
          ),
        },
      ),
      'Image file is too large.' => _lifeI18nText(
        context,
        'inline.plan296.crypto.error.image_file_too_large_with_limit',
        params: <String, Object?>{
          'limit': _formatBytes(
            ToolboxSteganographyService.maxImageCarrierBytes,
          ),
        },
      ),
      'Image dimensions are too large.' => _lifeI18nText(
        context,
        'inline.plan296.crypto.error.image_dimensions_too_large_with_limit',
        params: <String, Object?>{
          'pixels': ToolboxSteganographyService.maxImagePixels,
        },
      ),
      _ when message.startsWith('Selected file is too large. Limit:') =>
        _lifeI18nText(
          context,
          'inline.plan296.crypto.error.selected_file_too_large',
          params: <String, Object?>{
            'detail': message.replaceFirst('Selected file is too large. ', ''),
          },
        ),
      _ when message.endsWith('is not available yet.') => _lifeI18nText(
        context,
        'inline.plan296.crypto.error.algorithm_unavailable',
      ),
      _ when message.startsWith('Secret payload is too large') => _lifeI18nText(
        context,
        'inline.plan296.crypto.error.secret_payload_too_large',
      ),
      _ => message,
    };
  }
}

class _KeyFileEntry {
  _KeyFileEntry({required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes) {
    final digest = sha256.convert(this.bytes);
    digestHex = digest.toString();
    digestBase64 = base64Encode(digest.bytes);
  }

  final String name;
  final Uint8List bytes;
  late final String digestHex;
  late final String digestBase64;
}

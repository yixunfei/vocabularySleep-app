part of '../toolbox_life_tools.dart';

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
    required this.encryption,
    required this.passphrase,
    required this.strength,
    required this.keyFileBytes,
    required this.sourceExtension,
    required this.cascade,
    required this.keyBits,
    required this.macAlgorithm,
    required this.signatureMode,
    required this.maxErrorAttempts,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final String text;
  final ToolboxCryptoAlgorithm encryption;
  final String passphrase;
  final ToolboxCryptoStrength strength;
  final Uint8List? keyFileBytes;
  final String? sourceExtension;
  final List<ToolboxCryptoCascadeCipher>? cascade;
  final ToolboxCryptoKeyBits keyBits;
  final ToolboxCryptoMacAlgorithm macAlgorithm;
  final ToolboxCryptoSignatureMode signatureMode;
  final int maxErrorAttempts;
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
    required this.fileName,
    required this.encryption,
    required this.passphrase,
    required this.strength,
    required this.keyFileBytes,
    required this.sourceExtension,
    required this.mediaType,
    required this.cascade,
    required this.keyBits,
    required this.macAlgorithm,
    required this.signatureMode,
    required this.maxErrorAttempts,
    required this.locatorAlgorithm,
    required this.locatorStrength,
  });

  final ToolboxSteganographyMediaKind mediaKind;
  final Uint8List carrierBytes;
  final Uint8List fileBytes;
  final String? fileName;
  final ToolboxCryptoAlgorithm encryption;
  final String passphrase;
  final ToolboxCryptoStrength strength;
  final Uint8List? keyFileBytes;
  final String? sourceExtension;
  final String? mediaType;
  final List<ToolboxCryptoCascadeCipher>? cascade;
  final ToolboxCryptoKeyBits keyBits;
  final ToolboxCryptoMacAlgorithm macAlgorithm;
  final ToolboxCryptoSignatureMode signatureMode;
  final int maxErrorAttempts;
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

ToolboxSteganographyEmbedResult _runStegoEmbedText(
  _StegoEmbedTextRequest request,
) {
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

class _SteganographyToolPage extends StatefulWidget {
  const _SteganographyToolPage();

  @override
  State<_SteganographyToolPage> createState() => _SteganographyToolPageState();
}

class _SteganographyToolPageState extends State<_SteganographyToolPage> {
  final ToolboxSteganographyService _service = ToolboxSteganographyService();
  final ToolboxCryptoService _cryptoService = ToolboxCryptoService();
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _keyFileLengthController = TextEditingController(
    text: '256',
  );
  final TextEditingController _maxErrorAttemptsController =
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
  Uint8List? _fileOutputBytes;
  ToolboxSteganographyEmbedResult? _fileEmbedResult;
  ToolboxSteganographyFileRevealResult? _fileRevealResult;
  ToolboxCryptoHashResult? _hashResult;
  Uint8List? _outputBytes;
  ui.Image? _sourcePreview;
  ui.Image? _outputPreview;
  ToolboxSteganographyEmbedResult? _embedResult;
  ToolboxSteganographyRevealResult? _revealResult;
  bool _busy = false;
  String? _savedPath;
  String? _error;
  bool _maxErrorRiskPromptShown = false;
  Timer? _decodeUnlockTimer;

  static const Duration _decodeErrorWindow = Duration(minutes: 5);
  static const Duration _decodeLockDuration = Duration(minutes: 5);
  static const int _decodeErrorLimit = 10;
  static final Map<String, List<DateTime>> _decodeErrorTimesByCarrier =
      <String, List<DateTime>>{};
  static final Map<String, DateTime> _decodeLockedUntilByCarrier =
      <String, DateTime>{};
  static final Map<String, int> _protectedDecodeFailuresByCarrier =
      <String, int>{};

  @override
  void dispose() {
    _secretController.dispose();
    _passphraseController.dispose();
    _keyFileLengthController.dispose();
    _maxErrorAttemptsController.dispose();
    _decodeUnlockTimer?.cancel();
    _sourcePreview?.dispose();
    _outputPreview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '图片/音频/视频隐写', en: 'Media steganography'),
      subtitle: _lifeText(
        context,
        zh: '本地加密文本并写入媒体，也可独立加密文件或计算哈希。',
        en: 'Encrypt text into media, encrypt files, or calculate hashes locally.',
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
          if (_savedPath != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildMessagePanel(
              context,
              text: _lifeText(
                context,
                zh: '已保存: $_savedPath',
                en: 'Saved: $_savedPath',
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
        title: Text(_lifeText(context, zh: '高级加密参数', en: 'Advanced crypto')),
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
                label: _lifeText(context, zh: '密钥材料', en: 'Key bits'),
                value: _keyBits,
                options: const <_LifeOption<ToolboxCryptoKeyBits>>[
                  _LifeOption<ToolboxCryptoKeyBits>(
                    value: ToolboxCryptoKeyBits.bits256,
                    labelZh: '256-bit',
                    labelEn: '256-bit',
                  ),
                  _LifeOption<ToolboxCryptoKeyBits>(
                    value: ToolboxCryptoKeyBits.bits512,
                    labelZh: '512-bit',
                    labelEn: '512-bit',
                  ),
                  _LifeOption<ToolboxCryptoKeyBits>(
                    value: ToolboxCryptoKeyBits.bits1024,
                    labelZh: '1024-bit',
                    labelEn: '1024-bit',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _keyBits = value),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxCryptoMacAlgorithm>(
                label: _lifeText(context, zh: '校验哈希', en: 'MAC hash'),
                value: _macAlgorithm,
                options: const <_LifeOption<ToolboxCryptoMacAlgorithm>>[
                  _LifeOption<ToolboxCryptoMacAlgorithm>(
                    value: ToolboxCryptoMacAlgorithm.sha256,
                    labelZh: 'SHA-256',
                    labelEn: 'SHA-256',
                  ),
                  _LifeOption<ToolboxCryptoMacAlgorithm>(
                    value: ToolboxCryptoMacAlgorithm.whirlpool,
                    labelZh: 'Whirlpool',
                    labelEn: 'Whirlpool',
                  ),
                ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _macAlgorithm = value),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxCryptoSignatureMode>(
                label: _lifeText(context, zh: '签名层', en: 'Signature'),
                value: _signatureMode,
                options: const <_LifeOption<ToolboxCryptoSignatureMode>>[
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.none,
                    labelZh: '无',
                    labelEn: 'None',
                  ),
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.weakSha256,
                    labelZh: '弱签名版 快',
                    labelEn: 'Weak fast',
                  ),
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.rsaSha256,
                    labelZh: 'SHA-256/RSA',
                    labelEn: 'SHA-256/RSA',
                  ),
                  _LifeOption<ToolboxCryptoSignatureMode>(
                    value: ToolboxCryptoSignatureMode.ecdsaSha256,
                    labelZh: 'ECDSA',
                    labelEn: 'ECDSA',
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
              TextField(
                key: const ValueKey<String>('life_stego_max_error_attempts'),
                controller: _maxErrorAttemptsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security_update_warning_rounded),
                  labelText: _lifeText(
                    context,
                    zh: '最大错误尝试次数',
                    en: 'Max wrong attempts',
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
              _LifeSegmentedField<ToolboxSteganographyLocatorAlgorithm>(
                label: _lifeText(
                  context,
                  zh: '定位密钥算法',
                  en: 'Locator algorithm',
                ),
                value: _locatorAlgorithm,
                options:
                    const <_LifeOption<ToolboxSteganographyLocatorAlgorithm>>[
                      _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                        value: ToolboxSteganographyLocatorAlgorithm.sha256,
                        labelZh: 'SHA-256',
                        labelEn: 'SHA-256',
                      ),
                      _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                        value: ToolboxSteganographyLocatorAlgorithm.sha512,
                        labelZh: 'SHA-512',
                        labelEn: 'SHA-512',
                      ),
                    ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _locatorAlgorithm = value),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxSteganographyLocatorStrength>(
                label: _lifeText(context, zh: '定位密钥强度', en: 'Locator strength'),
                value: _locatorStrength,
                options:
                    const <_LifeOption<ToolboxSteganographyLocatorStrength>>[
                      _LifeOption<ToolboxSteganographyLocatorStrength>(
                        value: ToolboxSteganographyLocatorStrength.standard,
                        labelZh: '标准 4096',
                        labelEn: 'Standard 4096',
                      ),
                      _LifeOption<ToolboxSteganographyLocatorStrength>(
                        value: ToolboxSteganographyLocatorStrength.strong,
                        labelZh: '加强 12000',
                        labelEn: 'Strong 12000',
                      ),
                      _LifeOption<ToolboxSteganographyLocatorStrength>(
                        value: ToolboxSteganographyLocatorStrength.extreme,
                        labelZh: '极限 24000',
                        labelEn: 'Extreme 24000',
                      ),
                    ],
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() => _locatorStrength = value),
              ),
              if (_encryption ==
                  ToolboxCryptoAlgorithm.customCascade) ...<Widget>[
                const SizedBox(height: 12),
                _buildInlineNotice(
                  context,
                  icon: Icons.account_tree_rounded,
                  text: _lifeText(
                    context,
                    zh: '自由级联会按下方顺序逐层加密，每层独立派生所选长度的密钥材料。',
                    en: 'Custom cascade encrypts in the order below, deriving independent key material for every stage.',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ToolboxCryptoCascadeCipher.values
                      .where(
                        (cipher) =>
                            cipher != ToolboxCryptoCascadeCipher.sha256Stream,
                      )
                      .map((cipher) => _buildCascadeChip(context, cipher))
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ],
      ),
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
                  _lifeText(context, zh: '定位设置', en: 'Locator'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSegmentedField<ToolboxSteganographyLocatorAlgorithm>(
            label: _lifeText(context, zh: '定位密钥算法', en: 'Locator algorithm'),
            value: _locatorAlgorithm,
            options: const <_LifeOption<ToolboxSteganographyLocatorAlgorithm>>[
              _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                value: ToolboxSteganographyLocatorAlgorithm.sha256,
                labelZh: 'SHA-256',
                labelEn: 'SHA-256',
              ),
              _LifeOption<ToolboxSteganographyLocatorAlgorithm>(
                value: ToolboxSteganographyLocatorAlgorithm.sha512,
                labelZh: 'SHA-512',
                labelEn: 'SHA-512',
              ),
            ],
            onChanged: _busy
                ? (_) {}
                : (value) => setState(() => _locatorAlgorithm = value),
          ),
          const SizedBox(height: 12),
          _LifeSegmentedField<ToolboxSteganographyLocatorStrength>(
            label: _lifeText(context, zh: '定位密钥强度', en: 'Locator strength'),
            value: _locatorStrength,
            options: const <_LifeOption<ToolboxSteganographyLocatorStrength>>[
              _LifeOption<ToolboxSteganographyLocatorStrength>(
                value: ToolboxSteganographyLocatorStrength.standard,
                labelZh: '标准 4096',
                labelEn: 'Standard 4096',
              ),
              _LifeOption<ToolboxSteganographyLocatorStrength>(
                value: ToolboxSteganographyLocatorStrength.strong,
                labelZh: '加强 12000',
                labelEn: 'Strong 12000',
              ),
              _LifeOption<ToolboxSteganographyLocatorStrength>(
                value: ToolboxSteganographyLocatorStrength.extreme,
                labelZh: '极限 24000',
                labelEn: 'Extreme 24000',
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
            ? _lifeText(context, zh: '写入密文', en: 'Embed secret')
            : _lifeText(context, zh: '还原信息', en: 'Reveal message'),
      _CryptoWorkspace.file =>
        _fileMode == _FileCryptoMode.encrypt
            ? _lifeText(context, zh: '文件写入', en: 'Embed file')
            : _lifeText(context, zh: '文件还原', en: 'Reveal file'),
      _CryptoWorkspace.hash => _lifeText(
        context,
        zh: '哈希校验',
        en: 'Hash digest',
      ),
    };
    final workspaceLabel = _workspaceLabel(context, _workspace);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '加密工作台', en: 'Crypto stage'),
      subtitle: _lifeText(
        context,
        zh: '当前: $workspaceLabel / $modeLabel / $mediaLabel。密钥文件可与口令叠加使用。',
        en: 'Current: $workspaceLabel / $modeLabel / $mediaLabel. A key file can be combined with the passphrase.',
      ),
      children: <Widget>[
        _LifeSegmentedField<_CryptoWorkspace>(
          label: _lifeText(context, zh: '功能', en: 'Function'),
          value: _workspace,
          options: const <_LifeOption<_CryptoWorkspace>>[
            _LifeOption<_CryptoWorkspace>(
              value: _CryptoWorkspace.steganography,
              labelZh: '隐写',
              labelEn: 'Stego',
            ),
            _LifeOption<_CryptoWorkspace>(
              value: _CryptoWorkspace.file,
              labelZh: '文件',
              labelEn: 'File',
            ),
            _LifeOption<_CryptoWorkspace>(
              value: _CryptoWorkspace.hash,
              labelZh: '哈希',
              labelEn: 'Hash',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _workspace = value;
                    _savedPath = null;
                    _error = null;
                  });
                },
        ),
        const SizedBox(height: 12),
        if (_workspace == _CryptoWorkspace.hash) ...<Widget>[
          _LifeSegmentedField<ToolboxCryptoHashAlgorithm>(
            label: _lifeText(context, zh: '哈希算法', en: 'Hash algorithm'),
            value: _hashAlgorithm,
            options: const <_LifeOption<ToolboxCryptoHashAlgorithm>>[
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.sha256,
                labelZh: 'SHA-256',
                labelEn: 'SHA-256',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.sha512,
                labelZh: 'SHA-512',
                labelEn: 'SHA-512',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.sha3_256,
                labelZh: 'SHA3-256',
                labelEn: 'SHA3-256',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.blake2b256,
                labelZh: 'BLAKE2b',
                labelEn: 'BLAKE2b',
              ),
              _LifeOption<ToolboxCryptoHashAlgorithm>(
                value: ToolboxCryptoHashAlgorithm.whirlpool,
                labelZh: 'Whirlpool',
                labelEn: 'Whirlpool',
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
                  label: _lifeText(context, zh: '写入', en: 'Embed'),
                ),
                _buildModeChip(
                  context,
                  mode: _StegoMode.reveal,
                  icon: Icons.lock_open_rounded,
                  label: _lifeText(context, zh: '还原', en: 'Reveal'),
                ),
              ] else ...<Widget>[
                _buildFileModeChip(
                  context,
                  mode: _FileCryptoMode.encrypt,
                  icon: Icons.lock_rounded,
                  label: _lifeText(context, zh: '加密', en: 'Encrypt'),
                ),
                _buildFileModeChip(
                  context,
                  mode: _FileCryptoMode.decrypt,
                  icon: Icons.lock_open_rounded,
                  label: _lifeText(context, zh: '解密', en: 'Decrypt'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_workspace == _CryptoWorkspace.steganography) ...<Widget>[
            _LifeSegmentedField<ToolboxSteganographyMediaKind>(
              label: _lifeText(context, zh: '媒体类型', en: 'Media type'),
              value: _mediaKind,
              options: const <_LifeOption<ToolboxSteganographyMediaKind>>[
                _LifeOption<ToolboxSteganographyMediaKind>(
                  value: ToolboxSteganographyMediaKind.image,
                  labelZh: '图片',
                  labelEn: 'Image',
                ),
                _LifeOption<ToolboxSteganographyMediaKind>(
                  value: ToolboxSteganographyMediaKind.audio,
                  labelZh: '音频',
                  labelEn: 'Audio',
                ),
                _LifeOption<ToolboxSteganographyMediaKind>(
                  value: ToolboxSteganographyMediaKind.video,
                  labelZh: '视频',
                  labelEn: 'Video',
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
            if (_isUnsupportedMediaWrite) ...<Widget>[
              _buildInlineNotice(
                context,
                icon: Icons.info_outline_rounded,
                text: _lifeText(
                  context,
                  zh: '音频写入需要频域后端，视频写入需要帧内或运动矢量后端；当前仅保留旧载荷还原。',
                  en: 'Audio writes require a frequency-domain backend and video writes require frame-level or motion-vector support. Legacy reveal stays available.',
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (!_isRevealMode) ...<Widget>[
            _LifeSegmentedField<ToolboxCryptoAlgorithm>(
              label: _lifeText(context, zh: '加密算法', en: 'Encryption'),
              value: _encryption,
              options: const <_LifeOption<ToolboxCryptoAlgorithm>>[
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesGcm,
                  labelZh: 'AES 强',
                  labelEn: 'AES strong',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.chacha20Poly1305,
                  labelZh: 'ChaCha20',
                  labelEn: 'ChaCha20',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.twofishGcm,
                  labelZh: 'Twofish 强',
                  labelEn: 'Twofish strong',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.camelliaGcm,
                  labelZh: 'Camellia 强',
                  labelEn: 'Camellia strong',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesTwofishGcm,
                  labelZh: 'AES+Twofish 强+',
                  labelEn: 'AES+Twofish strong+',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesCamelliaGcm,
                  labelZh: 'AES+Camellia 强+',
                  labelEn: 'AES+Camellia strong+',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm,
                  labelZh: '三重 强+',
                  labelEn: 'Triple strong+',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.customCascade,
                  labelZh: '自由级联 强',
                  labelEn: 'Custom strong',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.sha256RsaSignature,
                  labelZh: 'RSA 签名 强',
                  labelEn: 'RSA signed',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.ecdsaSignature,
                  labelZh: 'ECDSA 签名 强',
                  labelEn: 'ECDSA signed',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.whirlpoolDigest,
                  labelZh: 'Whirlpool 校验 强',
                  labelEn: 'Whirlpool strong',
                ),
                _LifeOption<ToolboxCryptoAlgorithm>(
                  value: ToolboxCryptoAlgorithm.none,
                  labelZh: '不加密 明文',
                  labelEn: 'No encryption plain',
                ),
              ],
              onChanged: _busy
                  ? (_) {}
                  : (value) => setState(() => _encryption = value),
            ),
            const SizedBox(height: 12),
            _buildAlgorithmSafetyNotice(context),
            const SizedBox(height: 12),
            _LifeSegmentedField<ToolboxCryptoStrength>(
              label: _lifeText(context, zh: '强度', en: 'Strength'),
              value: _strength,
              options: const <_LifeOption<ToolboxCryptoStrength>>[
                _LifeOption<ToolboxCryptoStrength>(
                  value: ToolboxCryptoStrength.standard,
                  labelZh: '标准 2^16',
                  labelEn: 'Standard 2^16',
                ),
                _LifeOption<ToolboxCryptoStrength>(
                  value: ToolboxCryptoStrength.strong,
                  labelZh: '加强 2^17',
                  labelEn: 'Strong 2^17',
                ),
                _LifeOption<ToolboxCryptoStrength>(
                  value: ToolboxCryptoStrength.extreme,
                  labelZh: '极限 2^18',
                  labelEn: 'Extreme 2^18',
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
        ? '${_sourceName ?? _lifeText(context, zh: '未命名媒体', en: 'Unnamed media')} · ${_formatBytes(_sourceBytes!.length)}'
        : _lifeText(context, zh: '尚未选择媒体。', en: 'No media selected yet.');
    return _LifeSettingsPanel(
      title: _mode == _StegoMode.embed
          ? _lifeText(context, zh: '载体与文本', en: 'Carrier and text')
          : _lifeText(context, zh: '待还原媒体', en: 'Media to reveal'),
      subtitle: _mode == _StegoMode.embed
          ? _lifeText(
              context,
              zh: '选择一个媒体文件，并输入需要隐藏的文本。',
              en: 'Pick a media file and enter the text to hide.',
            )
          : _lifeText(
              context,
              zh: '选择之前生成的隐写媒体，并输入对应口令。',
              en: 'Pick a generated stego media file and enter its passphrase.',
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
                label: Text(_lifeText(context, zh: '选择媒体', en: 'Pick media')),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
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
              labelText: _lifeText(context, zh: '隐藏文本', en: 'Secret text'),
            ),
          ),
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
            labelText: _lifeText(context, zh: '口令', en: 'Passphrase'),
            helperText: _mode == _StegoMode.reveal
                ? _lifeText(
                    context,
                    zh: '请输入写入时使用的口令和密钥文件。',
                    en: 'Use the passphrase and key file from embedding.',
                  )
                : _encryption.requiresSecret
                ? _lifeText(
                    context,
                    zh: '口令或密钥文件至少提供一个，还原时必须一致。',
                    en: 'Use a passphrase or key file; the same inputs are required when revealing.',
                  )
                : _lifeText(
                    context,
                    zh: '不加密模式可留空。',
                    en: 'Can be empty for no encryption.',
                  ),
          ),
        ),
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
                      ? _lifeText(context, zh: '处理中...', en: 'Working...')
                      : _mode == _StegoMode.embed
                      ? _lifeText(context, zh: '生成隐写媒体', en: 'Generate stego')
                      : _lifeText(context, zh: '还原文本', en: 'Reveal text'),
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
                label: Text(_lifeText(context, zh: '导出结果', en: 'Export')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilePanel(BuildContext context) {
    final hasSource = _sourceBytes != null;
    final sourceText = hasSource
        ? '${_sourceName ?? _lifeText(context, zh: '未命名媒体', en: 'Unnamed media')} · ${_formatBytes(_sourceBytes!.length)}'
        : _lifeText(
            context,
            zh: '尚未选择载体媒体。',
            en: 'No carrier media selected yet.',
          );
    final hasFile = _fileBytes != null;
    final fileText = hasFile
        ? '${_fileName ?? _lifeText(context, zh: '未命名文件', en: 'Unnamed file')} · ${_formatBytes(_fileBytes!.length)}'
        : _lifeText(context, zh: '尚未选择文件。', en: 'No file selected yet.');
    return _LifeSettingsPanel(
      title: _fileMode == _FileCryptoMode.encrypt
          ? _lifeText(context, zh: '文件写入媒体', en: 'File into media')
          : _lifeText(context, zh: '从媒体还原文件', en: 'Restore file from media'),
      subtitle: _fileMode == _FileCryptoMode.encrypt
          ? _lifeText(
              context,
              zh: '选择载体和要隐藏的文件，加密后的文件数据会写入图片、音频或视频。',
              en: 'Pick a carrier and a file; encrypted file bytes are embedded into image, audio, or video.',
            )
          : _lifeText(
              context,
              zh: '选择之前生成的隐写媒体，使用相同口令和密钥文件还原文件。',
              en: 'Pick generated stego media and reveal the file with the same passphrase and key file.',
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
                label: Text(_lifeText(context, zh: '选择载体', en: 'Pick carrier')),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
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
                  label: Text(_lifeText(context, zh: '选择文件', en: 'Pick file')),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _lifeText(context, zh: '清空文件', en: 'Clear file'),
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
            labelText: _lifeText(context, zh: '口令', en: 'Passphrase'),
            helperText: _lifeText(
              context,
              zh: '口令可与密钥文件叠加使用，解密时必须一致。',
              en: 'Can be combined with a key file and must match for decryption.',
            ),
          ),
        ),
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
                            _fileBytes == null)
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
                      ? _lifeText(context, zh: '处理中...', en: 'Working...')
                      : _fileMode == _FileCryptoMode.encrypt
                      ? _lifeText(context, zh: '写入文件', en: 'Embed file')
                      : _lifeText(context, zh: '还原文件', en: 'Reveal file'),
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
                label: Text(_lifeText(context, zh: '导出文件', en: 'Export')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHashPanel(BuildContext context) {
    final source = _fileBytes ?? _sourceBytes;
    final name = _fileName ?? _sourceName;
    final sourceText = source == null
        ? _lifeText(context, zh: '尚未选择文件。', en: 'No file selected yet.')
        : '${name ?? _lifeText(context, zh: '未命名文件', en: 'Unnamed file')} · ${_formatBytes(source.length)}';
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '哈希校验', en: 'Hash digest'),
      subtitle: _lifeText(
        context,
        zh: '选择任意文件并计算摘要，用于校验文件完整性或记录指纹。',
        en: 'Pick any file and calculate a digest for integrity checks.',
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
                label: Text(_lifeText(context, zh: '选择文件', en: 'Pick file')),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
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
                  ? _lifeText(context, zh: '处理中...', en: 'Working...')
                  : _lifeText(context, zh: '计算哈希', en: 'Calculate hash'),
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
      return _LifeSettingsPanel(
        title: _lifeText(context, zh: '结果', en: 'Result'),
        subtitle: _lifeText(
          context,
          zh: '执行写入或还原后，这里会显示载荷信息和文本结果。',
          en: 'After embedding or revealing, payload metrics and text appear here.',
        ),
        children: <Widget>[
          Text(_lifeText(context, zh: '暂无结果。', en: 'No result yet.')),
        ],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '结果', en: 'Result'),
      subtitle: _mode == _StegoMode.embed
          ? _lifeText(
              context,
              zh: '已生成可导出的隐写媒体。',
              en: 'A stego media file is ready to export.',
            )
          : _lifeText(
              context,
              zh: '已从媒体中还原文本。',
              en: 'Text has been revealed from the media.',
            ),
      children: <Widget>[
        if (embed != null) ...<Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeText(context, zh: '原文件', en: 'Source'),
                value: _formatBytes(embed.sourceBytes),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '结果文件', en: 'Output'),
                value: _formatBytes(embed.outputBytes),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '载荷', en: 'Payload'),
                value: _formatBytes(embed.payloadBytes),
              ),
              if (embed.capacityBytes != null)
                ToolboxMetricCard(
                  label: _lifeText(context, zh: '容量', en: 'Capacity'),
                  value: _formatBytes(embed.capacityBytes!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            _lifeText(
              context,
              zh: '密文预览: ${embed.cipherPreview}',
              en: 'Cipher preview: ${embed.cipherPreview}',
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
                label: _lifeText(context, zh: '载荷', en: 'Payload'),
                value: _formatBytes(reveal.payloadBytes),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '算法', en: 'Algorithm'),
                value: _encryptionLabel(context, reveal.encryption),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '强度', en: 'Strength'),
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
      return _LifeSettingsPanel(
        title: _lifeText(context, zh: '文件结果', en: 'File result'),
        subtitle: _lifeText(
          context,
          zh: '执行写入或还原后，这里会显示载荷、算法和导出状态。',
          en: 'After embedding or revealing, payload metrics and algorithm details appear here.',
        ),
        children: <Widget>[
          Text(_lifeText(context, zh: '暂无结果。', en: 'No result yet.')),
        ],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '文件结果', en: 'File result'),
      subtitle: _fileMode == _FileCryptoMode.encrypt
          ? _lifeText(
              context,
              zh: '已生成可导出的隐写媒体。',
              en: 'A stego media file is ready to export.',
            )
          : _lifeText(
              context,
              zh: '已从媒体还原文件内容，可导出保存。',
              en: 'The hidden file has been revealed and can be exported.',
            ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '载体', en: 'Carrier'),
              value: _formatBytes(_sourceBytes?.length ?? 0),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '输出', en: 'Output'),
              value: _formatBytes(_fileOutputBytes?.length ?? 0),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '算法', en: 'Algorithm'),
              value: _encryptionLabel(
                context,
                reveal?.encryption ?? _encryption,
              ),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '强度', en: 'Strength'),
              value: _strengthLabel(context, reveal?.strength ?? _strength),
            ),
            if (embed?.capacityBytes != null)
              ToolboxMetricCard(
                label: _lifeText(context, zh: '容量', en: 'Capacity'),
                value: _formatBytes(embed!.capacityBytes!),
              ),
          ],
        ),
        if (embed != null) ...<Widget>[
          const SizedBox(height: 12),
          SelectableText(
            _lifeText(
              context,
              zh: '密文预览: ${embed.cipherPreview}',
              en: 'Cipher preview: ${embed.cipherPreview}',
            ),
          ),
        ],
        if (reveal != null && reveal.fileName != null) ...<Widget>[
          const SizedBox(height: 12),
          SelectableText(
            _lifeText(
              context,
              zh: '文件名: ${reveal.fileName}',
              en: 'File name: ${reveal.fileName}',
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
        title: _lifeText(context, zh: '哈希结果', en: 'Hash result'),
        subtitle: _lifeText(
          context,
          zh: '计算后会显示十六进制和 Base64 摘要。',
          en: 'Hex and Base64 digests appear after calculation.',
        ),
        children: <Widget>[
          Text(_lifeText(context, zh: '暂无结果。', en: 'No result yet.')),
        ],
      );
    }
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '哈希结果', en: 'Hash result'),
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
        title: _lifeText(context, zh: '媒体预览', en: 'Media preview'),
        subtitle: _lifeText(
          context,
          zh: '音频和视频当前显示文件状态，导出后可用系统播放器打开。',
          en: 'Audio and video show file state here; exported files can be opened in system players.',
        ),
        children: <Widget>[
          _LifePreviewFrame(
            child: Text(
              _outputBytes == null
                  ? _lifeText(
                      context,
                      zh: '等待生成或还原。',
                      en: 'Waiting for generate or reveal.',
                    )
                  : _lifeText(
                      context,
                      zh: '结果媒体大小: ${_formatBytes(_outputBytes!.length)}',
                      en: 'Output media size: ${_formatBytes(_outputBytes!.length)}',
                    ),
            ),
          ),
        ],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '图片预览', en: 'Image preview'),
      subtitle: _lifeText(
        context,
        zh: '左侧原图，右侧隐写 PNG。',
        en: 'Source image on the left, stego PNG on the right.',
      ),
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final tiles = <Widget>[
              Expanded(
                child: _imageTile(
                  context: context,
                  titleZh: '原图',
                  titleEn: 'Source',
                  image: _sourcePreview,
                ),
              ),
              Expanded(
                child: _imageTile(
                  context: context,
                  titleZh: '隐写后',
                  titleEn: 'Stego',
                  image: _outputPreview,
                ),
              ),
            ];
            if (compact) {
              return Column(
                children: <Widget>[
                  _imageTile(
                    context: context,
                    titleZh: '原图',
                    titleEn: 'Source',
                    image: _sourcePreview,
                  ),
                  const SizedBox(height: 10),
                  _imageTile(
                    context: context,
                    titleZh: '隐写后',
                    titleEn: 'Stego',
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
      title: _lifeText(context, zh: '边界说明', en: 'Boundaries'),
      subtitle: _lifeText(
        context,
        zh: '本工具只在本地处理文件，不上传媒体。',
        en: 'This tool processes files locally and does not upload media.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '图片隐写采用密钥派生头和随机像素顺序的无损 PNG LSB；请不要再转存为 JPEG。音频/视频新写入等待频域、帧内或运动矢量后端，旧尾部载荷仅保留还原兼容。',
            en: 'Image stego uses lossless PNG LSB with a key-derived header and randomized pixel order; do not re-save as JPEG. New audio/video writes wait for frequency-domain, frame-level, or motion-vector backends. Legacy tail payloads are reveal-only.',
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
                _mode = mode;
                _clearResults();
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
                _fileMode = mode;
                _clearFileResults();
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
        : _lifeText(context, zh: '尚未选择密钥文件。', en: 'No key files selected.');
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
                      _lifeText(context, zh: '使用密钥文件', en: 'Use key files'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      _lifeText(
                        context,
                        zh: '开启后，所选文件会按稳定规则排序后参与派生。',
                        en: 'When enabled, selected files are sorted and mixed into key derivation.',
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
                    _lifeText(context, zh: '导入', en: 'Import'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: _compactGreenButtonStyle(context),
                ),
                TextButton.icon(
                  key: const ValueKey<String>('life_crypto_generate_key_file'),
                  onPressed: _busy ? null : _showKeyFileDialog,
                  icon: const Icon(Icons.casino_rounded, size: 18),
                  label: Text(_lifeText(context, zh: '生成', en: 'Generate')),
                  style: _compactButtonStyle(),
                ),
                FilledButton.icon(
                  key: const ValueKey<String>('life_crypto_export_key_file'),
                  onPressed: _busy || _keyFileBytes == null
                      ? null
                      : _saveKeyFile,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: Text(_lifeText(context, zh: '导出', en: 'Export')),
                  style: _compactGreenButtonStyle(context),
                ),
                IconButton.outlined(
                  tooltip: _lifeText(
                    context,
                    zh: '清空密钥文件',
                    en: 'Clear key files',
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
    return _lifeText(
      context,
      zh: '$count 个密钥文件 · ${_formatBytes(bytes)} · $names$suffix',
      en: '$count key file(s) · ${_formatBytes(bytes)} · $names$suffix',
    );
  }

  Widget _imageTile({
    required BuildContext context,
    required String titleZh,
    required String titleEn,
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
            _lifeText(context, zh: titleZh, en: titleEn),
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
                      _lifeText(context, zh: '暂无预览', en: 'No preview'),
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
        withData: true,
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      final bytes = file?.bytes;
      if (file == null || bytes == null || bytes.isEmpty) {
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
        _sourceBytes = Uint8List.fromList(bytes);
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
        _error = _lifeText(
          context,
          zh: '选择媒体失败: $error',
          en: 'Failed to pick media: $error',
        );
      });
    }
  }

  Future<void> _pickKeyFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      final files = picked?.files ?? const <PlatformFile>[];
      final entries = files
          .where((file) => file.bytes != null && file.bytes!.isNotEmpty)
          .map(
            (file) => _KeyFileEntry(
              name: file.name,
              bytes: Uint8List.fromList(file.bytes!),
            ),
          )
          .toList(growable: false);
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
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '选择密钥文件失败: $error',
          en: 'Failed to pick key file: $error',
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
            _lifeText(context, zh: '生成密钥文件', en: 'Generate key file'),
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
                  labelText: _lifeText(context, zh: '字节长度', en: 'Bytes'),
                  helperText: _lifeText(
                    context,
                    zh: '建议至少 256 字节，可输入 32 到 1048576。',
                    en: 'Recommended: at least 256 bytes. Range: 32 to 1048576.',
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_lifeText(context, zh: '取消', en: 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _generateKeyFile();
              },
              icon: const Icon(Icons.casino_rounded),
              label: Text(_lifeText(context, zh: '生成', en: 'Generate')),
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
        _error = _lifeText(
          context,
          zh: '密钥文件长度必须是数字。',
          en: 'Key file length must be a number.',
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
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = _lifeText(
          context,
          zh: '生成密钥文件失败: ${_friendlyError(context, error)}',
          en: 'Key file generation failed: ${_friendlyError(context, error)}',
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
      _error = null;
    });
    try {
      final fileName = _keyFileName ?? 'vocabulary_sleep_keyfile.bin';
      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeText(context, zh: '保存密钥文件', en: 'Save key file'),
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: <String>['bin'],
          bytes: bytes,
        );
      } on UnimplementedError {
        savedPath = null;
      }
      if (!mounted) {
        return;
      }
      if (savedPath == null || savedPath.trim().isEmpty) {
        if (kIsWeb) {
          setState(() {
            _savedPath = _lifeText(
              context,
              zh: '浏览器下载已触发，请查看下载列表。',
              en: 'Browser download started. Check your downloads.',
            );
          });
          return;
        }
        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'keys'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final fallback = File(path.join(exportDir.path, fileName));
        await fallback.writeAsBytes(bytes, flush: true);
        if (!mounted) {
          return;
        }
        setState(() => _savedPath = fallback.path);
        return;
      }
      setState(() => _savedPath = savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '保存密钥文件失败: $error',
          en: 'Save key file failed: $error',
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
      onPicked: (file, bytes) {
        _fileName = file.name;
        _fileExtension = file.extension;
        _fileBytes = Uint8List.fromList(bytes);
        _clearFileResults();
      },
      errorZh: '选择文件失败',
      errorEn: 'Failed to pick file',
    );
  }

  Future<void> _pickHashFile() async {
    await _pickAnyFile(
      onPicked: (file, bytes) {
        _fileName = file.name;
        _fileExtension = file.extension;
        _fileBytes = Uint8List.fromList(bytes);
        _hashResult = null;
        _savedPath = null;
        _error = null;
      },
      errorZh: '选择文件失败',
      errorEn: 'Failed to pick file',
    );
  }

  Future<void> _pickAnyFile({
    required void Function(PlatformFile file, Uint8List bytes) onPicked,
    required String errorZh,
    required String errorEn,
  }) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true,
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      final bytes = file?.bytes;
      if (file == null || bytes == null || bytes.isEmpty) {
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
        _error = _lifeText(
          context,
          zh: '$errorZh: $error',
          en: '$errorEn: $error',
        );
      });
    }
  }

  Future<bool> _confirmPlaintextIfNeeded() async {
    if (_encryption != ToolboxCryptoAlgorithm.none) {
      return true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_lifeText(context, zh: '确认不加密', en: 'Confirm plaintext')),
          content: Text(
            _lifeText(
              context,
              zh: '当前选择“不加密”，payload 只会经过封装和隐写，不会被加密。空密码会让还原门槛更低，请确认仍要生成。',
              en: 'No encryption is selected. The payload will be packaged and hidden, but not encrypted. An empty passphrase lowers the recovery barrier; confirm before generating.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_lifeText(context, zh: '取消', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                _lifeText(context, zh: '继续生成', en: 'Generate anyway'),
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
                  _lifeText(
                    context,
                    zh: '密码错误会销毁隐藏内容',
                    en: 'Wrong passwords can wipe hidden data',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _lifeText(
              context,
              zh: '已设置最大错误次数 $attempts。文件还原/解密时，如果密码错误累计达到该次数，将尝试销毁当前文件中的隐藏内容。',
              en: 'Max wrong attempts is set to $attempts. During file reveal/decryption, reaching this many wrong passwords will try to destroy hidden data in the current file.',
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_lifeText(context, zh: '知道了', en: 'OK')),
            ),
          ],
        );
      },
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
    if (!await _confirmPlaintextIfNeeded()) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
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
          encryption: _encryption,
          passphrase: _passphraseController.text,
          strength: _strength,
          keyFileBytes: _activeKeyFileBytes,
          sourceExtension: _sourceExtension,
          cascade: _selectedCascade,
          keyBits: _keyBits,
          macAlgorithm: _macAlgorithm,
          signatureMode: _signatureMode,
          maxErrorAttempts: maxErrorAttempts,
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
      });
      oldPreview?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '生成失败: ${_friendlyError(context, error)}',
          en: 'Generate failed: ${_friendlyError(context, error)}',
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
      });
      _registerDecodeSuccess(source);
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
        _error = _lifeText(
          context,
          zh: '还原失败: ${_friendlyError(context, error)}$extra',
          en: 'Reveal failed: ${_friendlyError(context, error)}$extra',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _encryptFile() async {
    final carrier = _sourceBytes;
    final file = _fileBytes;
    if (carrier == null || file == null) {
      return;
    }
    final maxErrorAttempts = _readMaxErrorAttemptsSetting();
    if (maxErrorAttempts == null) {
      return;
    }
    if (!await _confirmPlaintextIfNeeded()) {
      return;
    }
    setState(() {
      _busy = true;
      _savedPath = null;
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
          encryption: _encryption,
          passphrase: _passphraseController.text,
          strength: _strength,
          keyFileBytes: _activeKeyFileBytes,
          sourceExtension: _sourceExtension,
          fileName: _fileName,
          mediaType: _fileExtension,
          cascade: _selectedCascade,
          keyBits: _keyBits,
          macAlgorithm: _macAlgorithm,
          signatureMode: _signatureMode,
          maxErrorAttempts: maxErrorAttempts,
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
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '文件加密失败: ${_friendlyError(context, error)}',
          en: 'File encryption failed: ${_friendlyError(context, error)}',
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
        if (result.fileName != null && result.fileName!.trim().isNotEmpty) {
          _fileName = result.fileName;
          _fileExtension = path
              .extension(result.fileName!)
              .replaceFirst('.', '')
              .trim();
        }
      });
      _registerDecodeSuccess(carrier);
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
        _error = _lifeText(
          context,
          zh: '文件解密失败: ${_friendlyError(context, error)}$extra',
          en: 'File decryption failed: ${_friendlyError(context, error)}$extra',
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
        _error = _lifeText(
          context,
          zh: '哈希计算失败: ${_friendlyError(context, error)}',
          en: 'Hash failed: ${_friendlyError(context, error)}',
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
      _error = null;
    });
    try {
      final sourceName = _sourceName ?? 'media';
      final baseName = path.basenameWithoutExtension(sourceName);
      final fileName = '${baseName}_stego.${embed.outputExtension}';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeText(context, zh: '保存隐写媒体', en: 'Save stego media'),
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: <String>[embed.outputExtension],
          bytes: result,
        );
      } on UnimplementedError {
        savedPath = null;
      }

      if (!mounted) {
        return;
      }

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (kIsWeb) {
          setState(() {
            _savedPath = _lifeText(
              context,
              zh: '浏览器下载已触发，请查看下载列表。',
              en: 'Browser download started. Check your downloads.',
            );
          });
          return;
        }
        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'steganography'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallback = File(
          path.join(
            exportDir.path,
            '${baseName}_$timestamp.${embed.outputExtension}',
          ),
        );
        await fallback.writeAsBytes(result, flush: true);
        if (!mounted) {
          return;
        }
        setState(() {
          _savedPath = fallback.path;
        });
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
        _error = _lifeText(
          context,
          zh: '保存失败: $error',
          en: 'Save failed: $error',
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
      _error = null;
    });
    try {
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

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeText(context, zh: '保存文件结果', en: 'Save file result'),
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: <String>[outputExtension],
          bytes: result,
        );
      } on UnimplementedError {
        savedPath = null;
      }

      if (!mounted) {
        return;
      }
      if (savedPath == null || savedPath.trim().isEmpty) {
        if (kIsWeb) {
          setState(() {
            _savedPath = _lifeText(
              context,
              zh: '浏览器下载已触发，请查看下载列表。',
              en: 'Browser download started. Check your downloads.',
            );
          });
          return;
        }
        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'steganography'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallback = File(
          path.join(exportDir.path, '${baseName}_$timestamp.$outputExtension'),
        );
        await fallback.writeAsBytes(result, flush: true);
        if (!mounted) {
          return;
        }
        setState(() => _savedPath = fallback.path);
        return;
      }
      setState(() => _savedPath = savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '保存失败: $error',
          en: 'Save failed: $error',
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
    _error = null;
    oldOutput?.dispose();
  }

  void _clearFileResults() {
    _fileOutputBytes = null;
    _fileEmbedResult = null;
    _fileRevealResult = null;
    _savedPath = null;
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
      _hashResult = null;
      _savedPath = null;
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

  void _resetAll() {
    setState(() {
      _clearSourceAndResult();
      _useKeyFiles = false;
      _keyFileName = null;
      _keyFileBytes = null;
      _keyFileEntries = const <_KeyFileEntry>[];
      _secretController.clear();
    });
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
    if (_mediaKind == ToolboxSteganographyMediaKind.image) {
      return false;
    }
    return switch (_workspace) {
      _CryptoWorkspace.steganography => _mode == _StegoMode.embed,
      _CryptoWorkspace.file => _fileMode == _FileCryptoMode.encrypt,
      _CryptoWorkspace.hash => false,
    };
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
        _error = _lifeText(
          context,
          zh: '最大错误尝试次数必须是 0 到 255 之间的整数，已重置为 0（无限）。',
          en: 'Max wrong attempts must be an integer from 0 to 255. It has been reset to 0 (unlimited).',
        );
      });
      return null;
    }
    return parsed;
  }

  String _maxErrorAttemptsRiskText(BuildContext context) {
    final raw = _maxErrorAttemptsController.text.trim();
    final parsed = raw.isEmpty ? 0 : int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      return _lifeText(
        context,
        zh: '输入无效。必须为 0 到 255；确认生成时会重置为 0（无限）。',
        en: 'Invalid input. Use 0-255; it will reset to 0 (unlimited) before generation.',
      );
    }
    final current = parsed == 0
        ? _lifeText(context, zh: '无限', en: 'unlimited')
        : _lifeText(context, zh: '$parsed 次', en: '$parsed attempt(s)');
    return _lifeText(
      context,
      zh: '当前为 $current，最大 255 次。解密密码错误达到设置次数会销毁当前文件隐藏内容。',
      en: 'Current: $current, maximum 255. Reaching the limit with wrong decryption passwords destroys hidden data in the current file.',
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
    return _lifeText(
      context,
      zh: '当前文件错误次数 ${status.windowCount}。',
      en: 'Current file error count: ${status.windowCount}.',
    );
  }

  String _decodeLockText(BuildContext context, Duration remaining) {
    final minutes = math.max(1, remaining.inMinutes + 1);
    return _lifeText(
      context,
      zh: '当前文件还原已锁定，约 $minutes 分钟后可重试。',
      en: 'Reveal for the current file is locked. Try again in about $minutes minute(s).',
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
      ui.Image? preview;
      if (_mediaKind == ToolboxSteganographyMediaKind.image) {
        preview = await _decodePreview(stripped.bytes);
      }
      if (!mounted) {
        preview?.dispose();
        return null;
      }
      final oldSource = _sourcePreview;
      final oldOutput = _outputPreview;
      setState(() {
        _sourceBytes = stripped.bytes;
        _sourcePreview = preview;
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
          ? _lifeText(
              context,
              zh: '已复写源文件。',
              en: 'Source file was overwritten.',
            )
          : _lifeText(
              context,
              zh: '已清理当前内存载体；当前平台未提供可复写路径。',
              en: 'Current in-memory carrier was cleaned; this platform did not provide a writable source path.',
            );
      return _lifeText(
        context,
        zh: '$zhReason $target',
        en: '$enReason $target',
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
      ToolboxSteganographyMediaKind.image => _lifeText(
        context,
        zh: '图片',
        en: 'Image',
      ),
      ToolboxSteganographyMediaKind.audio => _lifeText(
        context,
        zh: '音频',
        en: 'Audio',
      ),
      ToolboxSteganographyMediaKind.video => _lifeText(
        context,
        zh: '视频',
        en: 'Video',
      ),
    };
  }

  String _workspaceLabel(BuildContext context, _CryptoWorkspace workspace) {
    return switch (workspace) {
      _CryptoWorkspace.steganography => _lifeText(
        context,
        zh: '隐写',
        en: 'Stego',
      ),
      _CryptoWorkspace.file => _lifeText(
        context,
        zh: '文件加密',
        en: 'File crypto',
      ),
      _CryptoWorkspace.hash => _lifeText(context, zh: '哈希', en: 'Hash'),
    };
  }

  String _algorithmSafetyText(
    BuildContext context,
    ToolboxCryptoAlgorithm encryption,
  ) {
    return switch (encryption) {
      ToolboxCryptoAlgorithm.none => _lifeText(
        context,
        zh: '安全性: 明文。不会加密 payload，生成前会再次确认；任何拿到载体的人都可能还原内容。',
        en: 'Safety: plaintext. Payloads are not encrypted and generation asks for confirmation; anyone with the carrier may recover the content.',
      ),
      ToolboxCryptoAlgorithm.sha256Stream => _lifeText(
        context,
        zh: '安全性: 弱，仅用于旧载荷还原；新加密已移除。',
        en: 'Safety: weak, reveal-only for legacy payloads. New encryption has been removed.',
      ),
      ToolboxCryptoAlgorithm.rc4Legacy => _lifeText(
        context,
        zh: '安全性: 弱，仅用于 RC4 旧载荷还原；新加密已移除。',
        en: 'Safety: weak, reveal-only for legacy RC4 payloads. New encryption has been removed.',
      ),
      ToolboxCryptoAlgorithm.aesTwofishGcm ||
      ToolboxCryptoAlgorithm.aesCamelliaGcm ||
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm ||
      ToolboxCryptoAlgorithm.customCascade => _lifeText(
        context,
        zh: '安全性: 强+。使用 scrypt 2^16 起步、随机填充、独立派生密钥材料和认证校验。',
        en: 'Safety: strong+. Uses scrypt from 2^16, random padding, independent key material, and authentication.',
      ),
      _ => _lifeText(
        context,
        zh: '安全性: 强。默认 256-bit 以上密钥材料，使用随机盐、随机填充和认证校验。',
        en: 'Safety: strong. Uses at least 256-bit key material, random salt, random padding, and authentication.',
      ),
    };
  }

  String _signaturePerformanceText(BuildContext context) {
    return switch (_effectiveSignatureMode) {
      ToolboxCryptoSignatureMode.weakSha256 => _lifeText(
        context,
        zh: '弱签名是快速轻量标签，不生成公私钥，不提供第三方来源证明。',
        en: 'Weak signature is a fast lightweight tag. It does not generate public/private keys or prove third-party origin.',
      ),
      ToolboxCryptoSignatureMode.rsaSha256 ||
      ToolboxCryptoSignatureMode.ecdsaSha256 => _lifeText(
        context,
        zh: '强签名会生成密钥对并签名，移动设备可能等待较久。',
        en: 'Strong signatures generate a key pair and sign the envelope; slower mobile devices may need more time.',
      ),
      ToolboxCryptoSignatureMode.none => '',
    };
  }

  String _encryptionLabel(
    BuildContext context,
    ToolboxCryptoAlgorithm encryption,
  ) {
    return switch (encryption) {
      ToolboxCryptoAlgorithm.aesGcm => _lifeText(
        context,
        zh: 'AES-GCM',
        en: 'AES-GCM',
      ),
      ToolboxCryptoAlgorithm.chacha20Poly1305 => _lifeText(
        context,
        zh: 'ChaCha20-Poly1305',
        en: 'ChaCha20-Poly1305',
      ),
      ToolboxCryptoAlgorithm.twofishGcm => _lifeText(
        context,
        zh: 'Twofish-GCM',
        en: 'Twofish-GCM',
      ),
      ToolboxCryptoAlgorithm.camelliaGcm => _lifeText(
        context,
        zh: 'Camellia-GCM',
        en: 'Camellia-GCM',
      ),
      ToolboxCryptoAlgorithm.aesTwofishGcm => _lifeText(
        context,
        zh: 'AES + Twofish',
        en: 'AES + Twofish',
      ),
      ToolboxCryptoAlgorithm.aesCamelliaGcm => _lifeText(
        context,
        zh: 'AES + Camellia',
        en: 'AES + Camellia',
      ),
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm => _lifeText(
        context,
        zh: 'AES + Twofish + Camellia',
        en: 'AES + Twofish + Camellia',
      ),
      ToolboxCryptoAlgorithm.customCascade => _lifeText(
        context,
        zh: '自由级联',
        en: 'Custom cascade',
      ),
      ToolboxCryptoAlgorithm.sha256RsaSignature => _lifeText(
        context,
        zh: 'SHA-256/RSA 签名',
        en: 'SHA-256/RSA signature',
      ),
      ToolboxCryptoAlgorithm.ecdsaSignature => _lifeText(
        context,
        zh: 'ECDSA 签名',
        en: 'ECDSA signature',
      ),
      ToolboxCryptoAlgorithm.whirlpoolDigest => _lifeText(
        context,
        zh: 'Whirlpool 校验',
        en: 'Whirlpool MAC',
      ),
      ToolboxCryptoAlgorithm.sha256Stream => _lifeText(
        context,
        zh: 'SHA256 流',
        en: 'SHA256 stream',
      ),
      ToolboxCryptoAlgorithm.rc4Legacy => _lifeText(
        context,
        zh: 'RC4 兼容',
        en: 'RC4 legacy',
      ),
      ToolboxCryptoAlgorithm.none => _lifeText(
        context,
        zh: '不加密',
        en: 'No encryption',
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
      ToolboxCryptoCascadeCipher.sha256Stream => _lifeText(
        context,
        zh: 'SHA256 流',
        en: 'SHA256 stream',
      ),
    };
  }

  String _strengthLabel(BuildContext context, ToolboxCryptoStrength strength) {
    return switch (strength) {
      ToolboxCryptoStrength.standard => _lifeText(
        context,
        zh: '标准',
        en: 'Standard',
      ),
      ToolboxCryptoStrength.strong => _lifeText(
        context,
        zh: '加强',
        en: 'Strong',
      ),
      ToolboxCryptoStrength.extreme => _lifeText(
        context,
        zh: '极限',
        en: 'Extreme',
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
      'Source media is empty.' => _lifeText(
        context,
        zh: '媒体文件为空。',
        en: message,
      ),
      'Input bytes are empty.' => _lifeText(
        context,
        zh: '输入文件为空。',
        en: message,
      ),
      'Secret text is empty.' => _lifeText(context, zh: '隐藏文本为空。', en: message),
      'This encryption mode requires a passphrase or key file.' => _lifeText(
        context,
        zh: '当前加密模式需要口令或密钥文件。',
        en: message,
      ),
      'This encryption mode requires a passphrase.' => _lifeText(
        context,
        zh: '当前加密模式需要填写口令。',
        en: message,
      ),
      'Passphrase or key file is required.' => _lifeText(
        context,
        zh: '请填写口令或选择密钥文件。',
        en: message,
      ),
      'Key file mismatch or missing key file.' => _lifeText(
        context,
        zh: '密钥文件不匹配，或缺少密钥文件。',
        en: message,
      ),
      'Legacy or weak algorithms can only decrypt existing payloads.' =>
        _lifeText(
          context,
          zh: 'RC4 和 SHA256 流仅保留旧载荷解密兼容，不能用于新加密。',
          en: message,
        ),
      'SHA256 stream can only decrypt existing legacy payloads.' => _lifeText(
        context,
        zh: 'SHA256 流仅保留旧载荷解密兼容，不能加入新的自由级联。',
        en: message,
      ),
      'Audio steganography requires a frequency-domain backend before new payloads can be generated.' =>
        _lifeText(
          context,
          zh: '音频新写入需要 DCT/DWT/回声隐藏等频域后端；当前仅支持旧载荷还原。',
          en: message,
        ),
      'Video steganography requires a frame-level or motion-vector backend before new payloads can be generated.' =>
        _lifeText(context, zh: '视频新写入需要帧内或运动矢量级后端；当前仅支持旧载荷还原。', en: message),
      'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.' =>
        _lifeText(
          context,
          zh: '不支持该图片格式，请选择 PNG/JPG/WebP/GIF 等常见图片。',
          en: message,
        ),
      'Unsupported image format or no hidden payload found.' => _lifeText(
        context,
        zh: '不支持该图片格式，或未发现隐写载荷。',
        en: message,
      ),
      'Image is too small.' => _lifeText(context, zh: '图片尺寸太小。', en: message),
      'No hidden image payload found.' => _lifeText(
        context,
        zh: '未在图片中发现隐写载荷。',
        en: message,
      ),
      'Hidden image payload is damaged or incomplete.' => _lifeText(
        context,
        zh: '图片中的隐写载荷损坏或不完整。',
        en: message,
      ),
      'No hidden payload found.' => _lifeText(
        context,
        zh: '未发现隐写载荷。',
        en: message,
      ),
      'Hidden payload is damaged or incomplete.' => _lifeText(
        context,
        zh: '隐写载荷损坏或不完整。',
        en: message,
      ),
      'Unsupported payload version.' => _lifeText(
        context,
        zh: '不支持该载荷版本。',
        en: message,
      ),
      'Unsupported crypto version.' => _lifeText(
        context,
        zh: '不支持该加密文件版本。',
        en: message,
      ),
      'Hidden payload is invalid.' => _lifeText(
        context,
        zh: '隐写载荷格式无效。',
        en: message,
      ),
      'Crypto envelope is invalid.' => _lifeText(
        context,
        zh: '加密文件格式无效。',
        en: message,
      ),
      'This payload requires a passphrase.' => _lifeText(
        context,
        zh: '该载荷需要口令。',
        en: message,
      ),
      'Passphrase mismatch or payload is damaged.' => _lifeText(
        context,
        zh: '口令不匹配，或载荷已损坏。',
        en: message,
      ),
      'Payload is damaged.' => _lifeText(context, zh: '载荷已损坏。', en: message),
      'Payload checksum failed.' => _lifeText(
        context,
        zh: '载荷校验失败。',
        en: message,
      ),
      'Payload padding is invalid.' => _lifeText(
        context,
        zh: '载荷随机填充无效，文件可能已损坏。',
        en: message,
      ),
      'Payload text is not valid UTF-8.' => _lifeText(
        context,
        zh: '载荷文本不是有效 UTF-8。',
        en: message,
      ),
      'Hidden payload header is invalid.' => _lifeText(
        context,
        zh: '隐写载荷头无效。',
        en: message,
      ),
      'Hidden payload length is invalid.' => _lifeText(
        context,
        zh: '隐写载荷长度无效。',
        en: message,
      ),
      'Hidden payload body is invalid.' => _lifeText(
        context,
        zh: '隐写载荷内容无效。',
        en: message,
      ),
      'Hidden payload tamper check failed.' => _lifeText(
        context,
        zh: '隐写数据防篡改校验失败。',
        en: message,
      ),
      'Max error attempts must be between 0 and 255.' => _lifeText(
        context,
        zh: '最大错误尝试次数必须在 0 到 255 之间。',
        en: message,
      ),
      'Payload is too large.' => _lifeText(context, zh: '载荷过大。', en: message),
      _ when message.endsWith('is not available yet.') => _lifeText(
        context,
        zh: '该算法暂未接入可靠加密后端。',
        en: message,
      ),
      _ when message.startsWith('Secret payload is too large') => _lifeText(
        context,
        zh: '隐藏文本超过当前图片容量。',
        en: message,
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

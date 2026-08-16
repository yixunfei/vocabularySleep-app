part of '../toolbox_crypto_security.dart';

enum _StandaloneFileCryptoMode { encrypt, decrypt }

class _FileCryptoToolPage extends StatefulWidget {
  const _FileCryptoToolPage();

  @override
  State<_FileCryptoToolPage> createState() => _FileCryptoToolPageState();
}

class _FileCryptoToolPageState extends State<_FileCryptoToolPage> {
  final ToolboxCryptoService _service = ToolboxCryptoService();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _maxErrorsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _maxDecryptsController = TextEditingController(
    text: '0',
  );

  _StandaloneFileCryptoMode _mode = _StandaloneFileCryptoMode.encrypt;
  ToolboxCryptoAlgorithm _algorithm = ToolboxCryptoAlgorithm.aesGcm;
  ToolboxCryptoStrength _strength = ToolboxCryptoStrength.standard;
  ToolboxCryptoKeyBits _keyBits = ToolboxCryptoKeyBits.bits256;
  ToolboxCryptoMacAlgorithm _macAlgorithm = ToolboxCryptoMacAlgorithm.sha256;
  ToolboxCryptoSignatureMode _signatureMode =
      ToolboxCryptoSignatureMode.ecdsaSha256;
  List<ToolboxCryptoCascadeCipher> _cascade =
      const <ToolboxCryptoCascadeCipher>[
        ToolboxCryptoCascadeCipher.aes,
        ToolboxCryptoCascadeCipher.twofish,
        ToolboxCryptoCascadeCipher.serpent,
      ];

  String? _sourceName;
  String? _sourcePath;
  Uint8List? _sourceBytes;
  Uint8List? _outputBytes;
  String? _outputName;
  String? _savedPath;
  ToolboxCryptoCombinedKeyFileResult? _combinedKeyFile;
  String? _statusMessage;
  String? _error;
  bool _busy = false;
  bool _configExpanded = false;
  bool _overwriteSourceOnThreshold = false;
  int _failedAttempts = 0;
  int _successfulDecrypts = 0;

  bool get _isEncrypt => _mode == _StandaloneFileCryptoMode.encrypt;

  @override
  void dispose() {
    _passphraseController.dispose();
    _maxErrorsController.dispose();
    _maxDecryptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.file.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.file.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildModePanel(context),
          if (_isEncrypt) ...<Widget>[
            const SizedBox(height: 14),
            _buildEncryptionPanel(context),
          ],
          const SizedBox(height: 14),
          _buildSourcePanel(context),
          const SizedBox(height: 14),
          _buildCredentialPanel(context),
          const SizedBox(height: 14),
          _buildActionPanel(context),
          const SizedBox(height: 14),
          _buildResultPanel(context),
        ],
      ),
    );
  }

  Widget _buildStageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accent = Color(0xFF286F7D);
    final sourceLabel = _sourceBytes == null
        ? _lifeI18nText(context, 'toolbox.crypto.file.no_source')
        : _lifeI18nText(
            context,
            'toolbox.crypto.file.selected_source',
            params: <String, Object?>{
              'name':
                  _sourceName ??
                  _lifeI18nText(context, 'toolbox.crypto.common.unnamed_file'),
              'size': _formatCryptoBytes(_sourceBytes!.length),
            },
          );
    return ToolboxSurfaceCard(
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: colorScheme.surfaceContainerLowest,
      borderColor: accent.withValues(alpha: 0.22),
      shadowColor: accent,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.lock_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(context, 'toolbox.crypto.file.stage_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sourceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  _isEncrypt
                      ? 'toolbox.crypto.file.mode_encrypt'
                      : 'toolbox.crypto.file.mode_decrypt',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, 'toolbox.crypto.file.chip_aead'),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.file.chip_auto_decrypt',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
            ],
          ),
          if (_statusMessage != null || _error != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildStatusBlock(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBlock(BuildContext context) {
    final theme = Theme.of(context);
    final isError = _error != null;
    final color = isError ? theme.colorScheme.error : const Color(0xFF286F7D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        _error ?? _statusMessage ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildModePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.file.mode_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.file.mode_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_StandaloneFileCryptoMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.file.mode_label'),
          value: _mode,
          options: const <_LifeOption<_StandaloneFileCryptoMode>>[
            _LifeOption<_StandaloneFileCryptoMode>(
              value: _StandaloneFileCryptoMode.encrypt,
              labelKey: 'toolbox.crypto.file.mode_encrypt',
            ),
            _LifeOption<_StandaloneFileCryptoMode>(
              value: _StandaloneFileCryptoMode.decrypt,
              labelKey: 'toolbox.crypto.file.mode_decrypt',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _mode = value;
                    _clearOutputOnly();
                    _error = null;
                    _statusMessage = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildSourcePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.file.source_section'),
      subtitle: _lifeI18nText(
        context,
        _isEncrypt
            ? 'toolbox.crypto.file.source_encrypt_subtitle'
            : 'toolbox.crypto.file.source_decrypt_subtitle',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _pickSource,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    _isEncrypt
                        ? 'toolbox.crypto.file.pick_plain'
                        : 'toolbox.crypto.file.pick_envelope',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
              onPressed: _busy ? null : _clearSource,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: Text(
            _sourceBytes == null
                ? _lifeI18nText(context, 'toolbox.crypto.file.no_source')
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.file.selected_source',
                    params: <String, Object?>{
                      'name':
                          _sourceName ??
                          _lifeI18nText(
                            context,
                            'toolbox.crypto.common.unnamed_file',
                          ),
                      'size': _formatCryptoBytes(_sourceBytes!.length),
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialPanel(BuildContext context) {
    final entries =
        _combinedKeyFile?.entries ?? const <ToolboxCryptoKeyFileEntryInfo>[];
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.file.credential_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.file.credential_subtitle',
      ),
      children: <Widget>[
        TextField(
          controller: _passphraseController,
          obscureText: true,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.file.passphrase_label',
            ),
            hintText: _lifeI18nText(
              context,
              'toolbox.crypto.file.passphrase_hint',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _pickKeyFiles,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.crypto.file.import_key_files'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildKeyFileActionRow(context),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: entries.isEmpty
              ? Text(_lifeI18nText(context, 'toolbox.crypto.file.no_key_files'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.file.key_files_selected',
                        params: <String, Object?>{
                          'count': entries.length,
                          'size': _formatCryptoBytes(_combinedKeyFile!.length),
                          'hash': _combinedKeyFile!.sha256.substring(0, 16),
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entries.map(
                      (entry) => _CryptoMetricRow(
                        label: entry.name,
                        value: _lifeI18nText(
                          context,
                          'toolbox.crypto.common.key_file_entry',
                          params: <String, Object?>{
                            'size': _formatCryptoBytes(entry.length),
                            'hash': entry.sha256.substring(0, 12),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildKeyFileActionRow(BuildContext context) {
    final generateButton = OutlinedButton.icon(
      onPressed: _busy ? null : _generateKeyFileForCurrentSelection,
      icon: const Icon(Icons.casino_rounded),
      label: Text(
        _lifeI18nText(context, 'toolbox.crypto.file.generate_key_file'),
      ),
    );
    final exportButton = OutlinedButton.icon(
      onPressed: _busy || _combinedKeyFile == null
          ? null
          : _exportCurrentKeyFile,
      icon: const Icon(Icons.ios_share_rounded),
      label: Text(
        _lifeI18nText(context, 'toolbox.crypto.file.export_key_file'),
      ),
    );
    final clearButton = IconButton.filledTonal(
      tooltip: _lifeI18nText(context, 'toolbox.crypto.file.clear_key_files'),
      onPressed: _busy || _combinedKeyFile == null ? null : _clearKeyFiles,
      icon: const Icon(Icons.key_off_rounded),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              generateButton,
              const SizedBox(height: 10),
              exportButton,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: clearButton),
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: generateButton),
            const SizedBox(width: 10),
            Expanded(child: exportButton),
            const SizedBox(width: 10),
            clearButton,
          ],
        );
      },
    );
  }

  Widget _buildEncryptionPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _busy
                ? null
                : () => setState(() => _configExpanded = !_configExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _lifeI18nText(
                            context,
                            'toolbox.crypto.file.config_section',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lifeI18nText(
                            context,
                            'toolbox.crypto.file.config_subtitle',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _configExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: _lifeI18nText(context, _algorithmKey(_algorithm)),
                accent: const Color(0xFF286F7D),
                backgroundColor: const Color(
                  0xFF286F7D,
                ).withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, _strengthKey(_strength)),
                accent: const Color(0xFF286F7D),
                backgroundColor: const Color(
                  0xFF286F7D,
                ).withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, _keyBitsKey(_keyBits)),
                accent: const Color(0xFF286F7D),
                backgroundColor: const Color(
                  0xFF286F7D,
                ).withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            child: _buildConfigHint(context),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildEncryptionControls(context),
              ),
            ),
            crossFadeState: _configExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEncryptionControls(BuildContext context) {
    return <Widget>[
      _LifeSegmentedField<ToolboxCryptoAlgorithm>(
        label: _lifeI18nText(context, 'toolbox.crypto.file.algorithm_label'),
        value: _algorithm,
        options: const <_LifeOption<ToolboxCryptoAlgorithm>>[
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.aesGcm,
            labelKey: 'toolbox.crypto.algorithm.aes_gcm',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.chacha20Poly1305,
            labelKey: 'toolbox.crypto.algorithm.chacha20_poly1305',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.twofishGcm,
            labelKey: 'toolbox.crypto.algorithm.twofish_gcm',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.camelliaGcm,
            labelKey: 'toolbox.crypto.algorithm.camellia_gcm',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.serpentGcm,
            labelKey: 'toolbox.crypto.algorithm.serpent_gcm',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.kuznyechikGcm,
            labelKey: 'toolbox.crypto.algorithm.kuznyechik_gcm',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm,
            labelKey: 'toolbox.crypto.algorithm.aes_serpent_kuznyechik',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value:
                ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm,
            labelKey: 'toolbox.crypto.algorithm.full_five_cascade',
          ),
          _LifeOption<ToolboxCryptoAlgorithm>(
            value: ToolboxCryptoAlgorithm.customCascade,
            labelKey: 'toolbox.crypto.algorithm.custom_cascade',
          ),
        ],
        onChanged: _busy
            ? (_) {}
            : (value) => setState(() => _algorithm = value),
      ),
      if (_algorithm == ToolboxCryptoAlgorithm.customCascade) ...<Widget>[
        const SizedBox(height: 12),
        _buildCascadePicker(context),
      ],
      const SizedBox(height: 12),
      _LifeSegmentedField<ToolboxCryptoStrength>(
        label: _lifeI18nText(context, 'toolbox.crypto.file.strength_label'),
        value: _strength,
        options: const <_LifeOption<ToolboxCryptoStrength>>[
          _LifeOption<ToolboxCryptoStrength>(
            value: ToolboxCryptoStrength.standard,
            labelKey: 'toolbox.crypto.strength.standard',
          ),
          _LifeOption<ToolboxCryptoStrength>(
            value: ToolboxCryptoStrength.strong,
            labelKey: 'toolbox.crypto.strength.strong',
          ),
          _LifeOption<ToolboxCryptoStrength>(
            value: ToolboxCryptoStrength.extreme,
            labelKey: 'toolbox.crypto.strength.extreme',
          ),
        ],
        onChanged: _busy
            ? (_) {}
            : (value) => setState(() => _strength = value),
      ),
      const SizedBox(height: 12),
      _LifeSegmentedField<ToolboxCryptoKeyBits>(
        label: _lifeI18nText(context, 'toolbox.crypto.file.key_bits_label'),
        value: _keyBits,
        options: const <_LifeOption<ToolboxCryptoKeyBits>>[
          _LifeOption<ToolboxCryptoKeyBits>(
            value: ToolboxCryptoKeyBits.bits256,
            labelKey: 'toolbox.crypto.key_bits.256',
          ),
          _LifeOption<ToolboxCryptoKeyBits>(
            value: ToolboxCryptoKeyBits.bits512,
            labelKey: 'toolbox.crypto.key_bits.512',
          ),
          _LifeOption<ToolboxCryptoKeyBits>(
            value: ToolboxCryptoKeyBits.bits1024,
            labelKey: 'toolbox.crypto.key_bits.1024',
          ),
          _LifeOption<ToolboxCryptoKeyBits>(
            value: ToolboxCryptoKeyBits.bits2048,
            labelKey: 'toolbox.crypto.key_bits.2048',
          ),
          _LifeOption<ToolboxCryptoKeyBits>(
            value: ToolboxCryptoKeyBits.bits4096,
            labelKey: 'toolbox.crypto.key_bits.4096',
          ),
        ],
        onChanged: _busy ? (_) {} : (value) => setState(() => _keyBits = value),
      ),
      const SizedBox(height: 12),
      _LifeSegmentedField<ToolboxCryptoMacAlgorithm>(
        label: _lifeI18nText(context, 'toolbox.crypto.file.mac_label'),
        value: _macAlgorithm,
        options: const <_LifeOption<ToolboxCryptoMacAlgorithm>>[
          _LifeOption<ToolboxCryptoMacAlgorithm>(
            value: ToolboxCryptoMacAlgorithm.sha256,
            labelKey: 'toolbox.crypto.mac.sha256',
          ),
          _LifeOption<ToolboxCryptoMacAlgorithm>(
            value: ToolboxCryptoMacAlgorithm.whirlpool,
            labelKey: 'toolbox.crypto.mac.whirlpool',
          ),
        ],
        onChanged: _busy
            ? (_) {}
            : (value) => setState(() => _macAlgorithm = value),
      ),
      const SizedBox(height: 12),
      _LifeSegmentedField<ToolboxCryptoSignatureMode>(
        label: _lifeI18nText(context, 'toolbox.crypto.file.signature_label'),
        value: _signatureMode,
        options: const <_LifeOption<ToolboxCryptoSignatureMode>>[
          _LifeOption<ToolboxCryptoSignatureMode>(
            value: ToolboxCryptoSignatureMode.none,
            labelKey: 'toolbox.crypto.signature.none',
          ),
          _LifeOption<ToolboxCryptoSignatureMode>(
            value: ToolboxCryptoSignatureMode.rsaSha256,
            labelKey: 'toolbox.crypto.signature.rsa',
          ),
          _LifeOption<ToolboxCryptoSignatureMode>(
            value: ToolboxCryptoSignatureMode.ecdsaSha256,
            labelKey: 'toolbox.crypto.signature.ecdsa',
          ),
        ],
        onChanged: _busy
            ? (_) {}
            : (value) => setState(() => _signatureMode = value),
      ),
      const SizedBox(height: 16),
      _buildLimitControls(context),
    ];
  }

  Widget _buildConfigHint(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: ValueKey<bool>(_configExpanded),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _configExpanded
                ? Icons.unfold_less_rounded
                : Icons.touch_app_rounded,
            size: 18,
            color: const Color(0xFF286F7D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lifeI18nText(
                context,
                _configExpanded
                    ? 'toolbox.crypto.file.config_collapse_hint'
                    : 'toolbox.crypto.file.config_expand_hint',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _lifeI18nText(context, 'toolbox.crypto.file.cascade_label'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              const <ToolboxCryptoCascadeCipher>[
                    ToolboxCryptoCascadeCipher.aes,
                    ToolboxCryptoCascadeCipher.chacha20,
                    ToolboxCryptoCascadeCipher.twofish,
                    ToolboxCryptoCascadeCipher.camellia,
                    ToolboxCryptoCascadeCipher.serpent,
                    ToolboxCryptoCascadeCipher.kuznyechik,
                  ]
                  .map((cipher) {
                    final selected = _cascade.contains(cipher);
                    return FilterChip(
                      selected: selected,
                      label: Text(_lifeI18nText(context, _cascadeKey(cipher))),
                      onSelected: _busy
                          ? null
                          : (value) {
                              setState(() {
                                final next = _cascade.toList();
                                if (value) {
                                  if (!next.contains(cipher) &&
                                      next.length < 6) {
                                    next.add(cipher);
                                  }
                                } else if (next.length > 1) {
                                  next.remove(cipher);
                                }
                                _cascade = next;
                              });
                            },
                    );
                  })
                  .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildLimitControls(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _lifeI18nText(context, 'toolbox.crypto.file.limit_section'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          _lifeI18nText(context, 'toolbox.crypto.file.limit_subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: warningColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: warningColor.withValues(alpha: 0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 18, color: warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.file.limit_encrypt_warning',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: warningColor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _maxErrorsController,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.file.max_errors_label',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    'toolbox.crypto.file.max_errors_helper',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxDecryptsController,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.file.max_decrypts_label',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    'toolbox.crypto.file.max_decrypts_helper',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _overwriteSourceOnThreshold,
            onChanged: _busy
                ? null
                : (value) =>
                      setState(() => _overwriteSourceOnThreshold = value),
            title: Text(
              _lifeI18nText(context, 'toolbox.crypto.file.overwrite_toggle'),
            ),
            subtitle: Text(
              _lifeI18nText(context, 'toolbox.crypto.file.overwrite_note'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : (_isEncrypt ? _encryptSource : _decryptSource),
            icon: Icon(
              _isEncrypt ? Icons.lock_rounded : Icons.lock_open_rounded,
            ),
            label: Text(
              _busy
                  ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                  : _lifeI18nText(
                      context,
                      _isEncrypt
                          ? 'toolbox.crypto.file.encrypt_button'
                          : 'toolbox.crypto.file.decrypt_button',
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
          onPressed: _busy ? null : _clearAll,
          icon: const Icon(Icons.delete_sweep_rounded),
        ),
      ],
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.file.result_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.file.result_subtitle'),
      children: <Widget>[
        if (_outputBytes == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.file.no_result'),
            ),
          )
        else ...<Widget>[
          _LifePreviewFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.common.file_name',
                  ),
                  value:
                      _outputName ??
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.common.unnamed_file',
                      ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.common.size'),
                  value: _formatCryptoBytes(_outputBytes!.length),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.common.sha256'),
                  value: _cryptoSha256Short(_outputBytes!),
                ),
                if (_savedPath != null)
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.common.saved_path',
                    ),
                    value: _savedPath!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _exportOutput,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.crypto.file.export_button'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickSource() async {
    try {
      final picked = await _pickCryptoFile(
        maxBytes: _isEncrypt
            ? ToolboxCryptoService.maxPlainBytes
            : ToolboxCryptoService.maxEnvelopeBytes,
        allowedExtensions: _isEncrypt ? null : const <String>['vsc', 'json'],
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        _sourceName = picked.name;
        _sourcePath = picked.path;
        _sourceBytes = picked.bytes;
        _clearOutputOnly();
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.source_ready',
          params: <String, Object?>{'name': picked.name},
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.pick_failed', error);
    }
  }

  Future<void> _pickKeyFiles() async {
    try {
      final entries = await _pickCryptoKeyFileInputs();
      if (entries.isEmpty || !mounted) {
        return;
      }
      final combined = _service.combineKeyFiles(entries);
      setState(() {
        _wipeCombinedKeyFile();
        _combinedKeyFile = combined;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.key_files_ready',
          params: <String, Object?>{
            'count': combined.entries.length,
            'hash': combined.sha256.substring(0, 16),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.key_files_failed', error);
    }
  }

  Future<void> _generateKeyFileForCurrentSelection() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.generating',
        );
      });
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = _service.generateKeyFile(
        length: 4096,
        fileName: 'vocabulary_sleep_file_crypto_key_$timestamp.bin',
      );
      final combined = _service.combineKeyFiles(<ToolboxCryptoKeyFileInput>[
        ToolboxCryptoKeyFileInput(name: result.fileName, bytes: result.bytes),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _wipeCombinedKeyFile();
        _combinedKeyFile = combined;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.key_file_generated',
          params: <String, Object?>{
            'size': _formatCryptoBytes(combined.length),
            'hash': combined.sha256.substring(0, 16),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.keyfile.generate_failed', error);
    }
  }

  Future<void> _exportCurrentKeyFile() async {
    final keyFile = _combinedKeyFile;
    if (keyFile == null) {
      return;
    }
    try {
      final fileName = _sanitizeCryptoFallbackFileName(keyFile.fileName);
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.save_dialog',
        ),
        fileName: fileName,
        extension: _extensionForFileName(fileName),
        bytes: keyFile.bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: keyFile.bytes,
        fallbackSegments: const <String>[
          'toolbox_crypto_security',
          'key_files',
        ],
        fallbackFileName: fileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.export_success',
          params: <String, Object?>{
            'path':
                savedPath ??
                _lifeI18nText(
                  context,
                  'toolbox.crypto.common.browser_download',
                ),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.keyfile.export_failed', error);
    }
  }

  Future<void> _encryptSource() async {
    final source = _sourceBytes;
    if (source == null) {
      _setPlainError('toolbox.crypto.file.error_need_source');
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.encrypting',
        );
      });
      final result = _service.encryptBytes(
        plainBytes: source,
        algorithm: _algorithm,
        strength: _strength,
        passphrase: _passphraseController.text,
        keyFileBytes: _combinedKeyFile?.bytes,
        fileName: _sourceName,
        cascade: _algorithm == ToolboxCryptoAlgorithm.customCascade
            ? _cascade
            : null,
        keyBits: _keyBits,
        macAlgorithm: _macAlgorithm,
        signatureMode: _signatureMode,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _outputBytes = result.envelopeBytes;
        _outputName = _encryptedOutputName();
        _savedPath = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.encrypt_success',
          params: <String, Object?>{
            'size': _formatCryptoBytes(result.envelopeBytes.length),
          },
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      _setError('toolbox.crypto.file.encrypt_failed', error);
    }
  }

  Future<void> _decryptSource() async {
    final source = _sourceBytes;
    if (source == null) {
      _setPlainError('toolbox.crypto.file.error_need_source');
      return;
    }
    final maxDecrypts = _maxDecryptCount;
    if (maxDecrypts > 0 && _successfulDecrypts >= maxDecrypts) {
      await _triggerThresholdClear('toolbox.crypto.file.decrypt_limit_cleared');
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.decrypting',
        );
      });
      final result = _service.decryptBytes(
        envelopeBytes: source,
        passphrase: _passphraseController.text,
        keyFileBytes: _combinedKeyFile?.bytes,
      );
      if (!mounted) {
        return;
      }
      _successfulDecrypts += 1;
      setState(() {
        _busy = false;
        _failedAttempts = 0;
        _outputBytes = result.plainBytes;
        _outputName = result.fileName ?? _decryptedOutputName();
        _savedPath = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.decrypt_success',
          params: <String, Object?>{
            'size': _formatCryptoBytes(result.plainBytes.length),
          },
        );
      });
      if (maxDecrypts > 0 && _successfulDecrypts >= maxDecrypts) {
        await _triggerThresholdClear(
          'toolbox.crypto.file.decrypt_limit_cleared',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _failedAttempts += 1;
      setState(() => _busy = false);
      final maxErrors = _maxErrorCount;
      if (maxErrors > 0 && _failedAttempts >= maxErrors) {
        await _triggerThresholdClear('toolbox.crypto.file.error_limit_cleared');
      } else {
        _setError('toolbox.crypto.file.decrypt_failed_with_count', error);
      }
    }
  }

  Future<void> _exportOutput() async {
    final bytes = _outputBytes;
    final fileName = _outputName;
    if (bytes == null || fileName == null) {
      return;
    }
    try {
      final safeFileName = _sanitizeCryptoFallbackFileName(fileName);
      final extension = _extensionForFileName(safeFileName);
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: _lifeI18nText(context, 'toolbox.crypto.file.save_dialog'),
        fileName: safeFileName,
        extension: extension,
        bytes: bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: bytes,
        fallbackSegments: const <String>['toolbox_crypto_security', 'files'],
        fallbackFileName: safeFileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _savedPath = savedPath;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.export_success',
          params: <String, Object?>{
            'path':
                savedPath ??
                _lifeI18nText(
                  context,
                  'toolbox.crypto.common.browser_download',
                ),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.export_failed', error);
    }
  }

  Future<void> _triggerThresholdClear(String messageKey) async {
    final sourcePath = _sourcePath;
    final didOverwrite = _overwriteSourceOnThreshold
        ? await _bestEffortOverwriteAndDeleteFile(sourcePath)
        : false;
    if (!mounted) {
      return;
    }
    setState(() {
      _wipeAndClearSensitiveState();
      _busy = false;
      _error = null;
      _statusMessage = didOverwrite
          ? _lifeI18nText(
              context,
              'toolbox.crypto.file.threshold_cleared_deleted',
            )
          : _lifeI18nText(context, messageKey);
    });
  }

  void _setError(String key, Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = _lifeI18nText(
        context,
        key,
        params: <String, Object?>{'error': _friendlyCryptoError(error)},
      );
      _statusMessage = null;
    });
  }

  void _setPlainError(String key) {
    setState(() {
      _error = _lifeI18nText(context, key);
      _statusMessage = null;
    });
  }

  void _clearSource() {
    setState(() {
      _wipeBytes(_sourceBytes);
      _sourceName = null;
      _sourcePath = null;
      _sourceBytes = null;
      _clearOutputOnly();
      _error = null;
      _statusMessage = null;
      _failedAttempts = 0;
      _successfulDecrypts = 0;
    });
  }

  void _clearKeyFiles() {
    setState(() {
      _wipeCombinedKeyFile();
      _combinedKeyFile = null;
      _error = null;
      _statusMessage = null;
    });
  }

  void _clearOutputOnly() {
    _wipeBytes(_outputBytes);
    _outputBytes = null;
    _outputName = null;
    _savedPath = null;
  }

  void _clearAll() {
    setState(() {
      _wipeAndClearSensitiveState();
      _error = null;
      _statusMessage = null;
    });
  }

  void _wipeAndClearSensitiveState() {
    _wipeBytes(_sourceBytes);
    _wipeBytes(_outputBytes);
    _sourceName = null;
    _sourcePath = null;
    _sourceBytes = null;
    _outputBytes = null;
    _outputName = null;
    _savedPath = null;
    _wipeCombinedKeyFile();
    _combinedKeyFile = null;
    _passphraseController.clear();
    _failedAttempts = 0;
    _successfulDecrypts = 0;
  }

  void _wipeCombinedKeyFile() {
    _wipeBytes(_combinedKeyFile?.bytes);
  }

  void _wipeBytes(Uint8List? bytes) {
    if (bytes == null) {
      return;
    }
    for (var index = 0; index < bytes.length; index += 1) {
      bytes[index] = 0;
    }
  }

  int get _maxErrorCount {
    final parsed = int.tryParse(_maxErrorsController.text.trim()) ?? 0;
    return parsed.clamp(0, 99);
  }

  int get _maxDecryptCount {
    final parsed = int.tryParse(_maxDecryptsController.text.trim()) ?? 0;
    return parsed.clamp(0, 999);
  }

  String _encryptedOutputName() {
    final source = _sourceName?.trim();
    if (source == null || source.isEmpty) {
      return 'vocabulary_sleep_encrypted.vsc';
    }
    final safeSource = _sanitizeCryptoFallbackFileName(source);
    final base = path.basenameWithoutExtension(safeSource).trim();
    final outputName =
        '${base.isEmpty ? 'vocabulary_sleep_encrypted' : base}.vsc';
    return _sanitizeCryptoFallbackFileName(outputName);
  }

  String _decryptedOutputName() {
    final source = _sourceName?.trim();
    if (source == null || source.isEmpty) {
      return 'vocabulary_sleep_decrypted.bin';
    }
    final safeSource = _sanitizeCryptoFallbackFileName(source);
    final base = path.basenameWithoutExtension(safeSource).trim();
    final outputName =
        '${base.isEmpty ? 'vocabulary_sleep_decrypted' : base}.bin';
    return _sanitizeCryptoFallbackFileName(outputName);
  }

  String _extensionForFileName(String fileName) {
    return _cryptoExtensionForUntrustedFileName(fileName);
  }

  String _friendlyCryptoError(Object error) {
    final text = error is ToolboxCryptoException
        ? error.message
        : error.toString();
    return text.replaceFirst('Exception: ', '');
  }

  String _algorithmKey(ToolboxCryptoAlgorithm algorithm) {
    return switch (algorithm) {
      ToolboxCryptoAlgorithm.aesGcm => 'toolbox.crypto.algorithm.aes_gcm',
      ToolboxCryptoAlgorithm.chacha20Poly1305 =>
        'toolbox.crypto.algorithm.chacha20_poly1305',
      ToolboxCryptoAlgorithm.twofishGcm =>
        'toolbox.crypto.algorithm.twofish_gcm',
      ToolboxCryptoAlgorithm.camelliaGcm =>
        'toolbox.crypto.algorithm.camellia_gcm',
      ToolboxCryptoAlgorithm.serpentGcm =>
        'toolbox.crypto.algorithm.serpent_gcm',
      ToolboxCryptoAlgorithm.kuznyechikGcm =>
        'toolbox.crypto.algorithm.kuznyechik_gcm',
      ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm =>
        'toolbox.crypto.algorithm.aes_serpent_kuznyechik',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm =>
        'toolbox.crypto.algorithm.full_five_cascade',
      ToolboxCryptoAlgorithm.customCascade =>
        'toolbox.crypto.algorithm.custom_cascade',
      _ => 'toolbox.crypto.algorithm.aes_gcm',
    };
  }

  String _strengthKey(ToolboxCryptoStrength strength) {
    return switch (strength) {
      ToolboxCryptoStrength.standard => 'toolbox.crypto.strength.standard',
      ToolboxCryptoStrength.strong => 'toolbox.crypto.strength.strong',
      ToolboxCryptoStrength.extreme => 'toolbox.crypto.strength.extreme',
    };
  }

  String _keyBitsKey(ToolboxCryptoKeyBits keyBits) {
    return switch (keyBits) {
      ToolboxCryptoKeyBits.bits256 => 'toolbox.crypto.key_bits.256',
      ToolboxCryptoKeyBits.bits512 => 'toolbox.crypto.key_bits.512',
      ToolboxCryptoKeyBits.bits1024 => 'toolbox.crypto.key_bits.1024',
      ToolboxCryptoKeyBits.bits2048 => 'toolbox.crypto.key_bits.2048',
      ToolboxCryptoKeyBits.bits4096 => 'toolbox.crypto.key_bits.4096',
    };
  }

  String _cascadeKey(ToolboxCryptoCascadeCipher cipher) {
    return switch (cipher) {
      ToolboxCryptoCascadeCipher.aes => 'toolbox.crypto.algorithm.aes_gcm',
      ToolboxCryptoCascadeCipher.chacha20 =>
        'toolbox.crypto.algorithm.chacha20_poly1305',
      ToolboxCryptoCascadeCipher.twofish =>
        'toolbox.crypto.algorithm.twofish_gcm',
      ToolboxCryptoCascadeCipher.camellia =>
        'toolbox.crypto.algorithm.camellia_gcm',
      ToolboxCryptoCascadeCipher.serpent =>
        'toolbox.crypto.algorithm.serpent_gcm',
      ToolboxCryptoCascadeCipher.kuznyechik =>
        'toolbox.crypto.algorithm.kuznyechik_gcm',
      ToolboxCryptoCascadeCipher.sha256Stream =>
        'toolbox.crypto.algorithm.sha256_stream',
    };
  }
}

class _CryptoMetricRow extends StatelessWidget {
  const _CryptoMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

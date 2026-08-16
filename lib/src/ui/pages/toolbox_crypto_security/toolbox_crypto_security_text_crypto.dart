part of '../toolbox_crypto_security.dart';

enum _TextCryptoMode { encrypt, decrypt }

class _TextCryptoToolPage extends StatefulWidget {
  const _TextCryptoToolPage();

  @override
  State<_TextCryptoToolPage> createState() => _TextCryptoToolPageState();
}

class _TextCryptoToolPageState extends State<_TextCryptoToolPage> {
  final ToolboxCryptoService _service = ToolboxCryptoService();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();

  _TextCryptoMode _mode = _TextCryptoMode.encrypt;
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

  ToolboxCryptoCombinedKeyFileResult? _combinedKeyFile;
  String? _outputText;
  String? _statusMessage;
  String? _error;
  bool _busy = false;
  bool _configExpanded = false;

  bool get _isEncrypt => _mode == _TextCryptoMode.encrypt;

  @override
  void dispose() {
    _inputController.dispose();
    _passphraseController.dispose();
    _wipeKeyFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.text.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.text.subtitle'),
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
          _buildInputPanel(context),
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
    final inputBytes = utf8.encode(_inputController.text).length;
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
                child: const Icon(Icons.text_fields_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(context, 'toolbox.crypto.text.stage_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inputBytes == 0
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.text.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.text.stage_ready',
                              params: <String, Object?>{
                                'size': _formatCryptoBytes(inputBytes),
                              },
                            ),
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
                      ? 'toolbox.crypto.text.mode_encrypt'
                      : 'toolbox.crypto.text.mode_decrypt',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.text.chip_v5_envelope',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, 'toolbox.crypto.text.chip_base64'),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
            ],
          ),
          if (_statusMessage != null || _error != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildStatusBlock(context, accent),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBlock(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final isError = _error != null;
    final color = isError ? theme.colorScheme.error : accent;
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
      title: _lifeI18nText(context, 'toolbox.crypto.text.mode_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.text.mode_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_TextCryptoMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.text.mode_label'),
          value: _mode,
          options: const <_LifeOption<_TextCryptoMode>>[
            _LifeOption<_TextCryptoMode>(
              value: _TextCryptoMode.encrypt,
              labelKey: 'toolbox.crypto.text.mode_encrypt',
            ),
            _LifeOption<_TextCryptoMode>(
              value: _TextCryptoMode.decrypt,
              labelKey: 'toolbox.crypto.text.mode_decrypt',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _mode = value;
                    _outputText = null;
                    _statusMessage = null;
                    _error = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.text.input_section'),
      subtitle: _lifeI18nText(
        context,
        _isEncrypt
            ? 'toolbox.crypto.text.input_encrypt_subtitle'
            : 'toolbox.crypto.text.input_decrypt_subtitle',
      ),
      children: <Widget>[
        TextField(
          controller: _inputController,
          enabled: !_busy,
          minLines: 6,
          maxLines: 10,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              _isEncrypt
                  ? 'toolbox.crypto.text.plain_label'
                  : 'toolbox.crypto.text.cipher_label',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton.filledTonal(
            tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
            onPressed: _busy ? null : _clearInput,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionPanel(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF286F7D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.text.config_section',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.text.config_subtitle',
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: _lifeI18nText(context, _cryptoAlgorithmKey(_algorithm)),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, _cryptoStrengthKey(_strength)),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, _cryptoKeyBitsKey(_keyBits)),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
            ],
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
            labelKey: 'toolbox.crypto.signature.rsa_sha256',
          ),
          _LifeOption<ToolboxCryptoSignatureMode>(
            value: ToolboxCryptoSignatureMode.ecdsaSha256,
            labelKey: 'toolbox.crypto.signature.ecdsa_sha256',
          ),
        ],
        onChanged: _busy
            ? (_) {}
            : (value) => setState(() => _signatureMode = value),
      ),
    ];
  }

  Widget _buildCascadePicker(BuildContext context) {
    final ciphers = const <ToolboxCryptoCascadeCipher>[
      ToolboxCryptoCascadeCipher.aes,
      ToolboxCryptoCascadeCipher.chacha20,
      ToolboxCryptoCascadeCipher.twofish,
      ToolboxCryptoCascadeCipher.camellia,
      ToolboxCryptoCascadeCipher.serpent,
      ToolboxCryptoCascadeCipher.kuznyechik,
    ];
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
          children: ciphers
              .map((cipher) {
                final selected = _cascade.contains(cipher);
                return FilterChip(
                  selected: selected,
                  label: Text(
                    _lifeI18nText(context, _cryptoCascadeKey(cipher)),
                  ),
                  onSelected: _busy
                      ? null
                      : (value) {
                          setState(() {
                            final next = _cascade.toList(growable: true);
                            if (value) {
                              next.add(cipher);
                            } else {
                              next.remove(cipher);
                            }
                            _cascade = next.isEmpty
                                ? const <ToolboxCryptoCascadeCipher>[
                                    ToolboxCryptoCascadeCipher.aes,
                                  ]
                                : next.take(6).toList(growable: false);
                          });
                        },
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildCredentialPanel(BuildContext context) {
    final keyFile = _combinedKeyFile;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.file.credential_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.text.credential_subtitle',
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
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickKeyFiles,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  _lifeI18nText(context, 'toolbox.crypto.file.pick_key_files'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'toolbox.crypto.file.clear_key_files',
              ),
              onPressed: _busy || keyFile == null ? null : _clearKeyFiles,
              icon: const Icon(Icons.key_off_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: keyFile == null
              ? Text(_lifeI18nText(context, 'toolbox.crypto.file.no_key_files'))
              : _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.common.sha256'),
                  value: keyFile.sha256,
                ),
        ),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy ? null : (_isEncrypt ? _encryptText : _decryptText),
        icon: Icon(_isEncrypt ? Icons.lock_rounded : Icons.lock_open_rounded),
        label: Text(
          _busy
              ? _lifeI18nText(context, 'toolbox.crypto.common.working')
              : _lifeI18nText(
                  context,
                  _isEncrypt
                      ? 'toolbox.crypto.text.encrypt_button'
                      : 'toolbox.crypto.text.decrypt_button',
                ),
        ),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final output = _outputText;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.text.result_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.text.result_subtitle'),
      children: <Widget>[
        if (output == null || output.isEmpty)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.text.no_result'),
            ),
          )
        else ...<Widget>[
          _LifePreviewFrame(child: SelectableText(output)),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _copyText(output),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    _lifeI18nText(context, 'toolbox.crypto.text.copy_result'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
                onPressed: _busy ? null : _clearResult,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickKeyFiles() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.text.key_files_loading',
        );
      });
      final entries = await _pickCryptoKeyFileInputs();
      if (!mounted) {
        return;
      }
      if (entries.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final combined = _service.combineKeyFiles(entries);
      setState(() {
        _wipeKeyFile();
        _combinedKeyFile = combined;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.key_files_ready',
          params: <String, Object?>{
            'count': combined.entries.length,
            'size': _formatCryptoBytes(combined.length),
            'hash': combined.sha256.substring(0, 16),
          },
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.file.key_files_failed', error);
    }
  }

  Future<void> _encryptText() async {
    try {
      final plainText = _inputController.text;
      if (plainText.isEmpty) {
        throw const ToolboxCryptoException('Input bytes are empty.');
      }
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.text.encrypting',
        );
      });
      final result = _service.encryptBytes(
        plainBytes: Uint8List.fromList(utf8.encode(plainText)),
        algorithm: _algorithm,
        strength: _strength,
        passphrase: _passphraseController.text,
        keyFileBytes: _combinedKeyFile?.bytes,
        fileName: 'text_message.txt',
        mediaType: 'text/plain;charset=utf-8',
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
        _outputText = base64Encode(result.envelopeBytes);
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.text.encrypt_success',
          params: <String, Object?>{
            'size': _formatCryptoBytes(result.envelopeBytes.length),
          },
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.text.encrypt_failed', error);
    }
  }

  Future<void> _decryptText() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.text.decrypting',
        );
      });
      final envelopeBytes = Uint8List.fromList(
        base64Decode(_inputController.text.trim()),
      );
      final result = _service.decryptBytes(
        envelopeBytes: envelopeBytes,
        passphrase: _passphraseController.text,
        keyFileBytes: _combinedKeyFile?.bytes,
      );
      final plainText = utf8.decode(result.plainBytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _outputText = plainText;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.text.decrypt_success',
          params: <String, Object?>{
            'size': _formatCryptoBytes(result.plainBytes.length),
          },
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.text.decrypt_failed', error);
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lifeI18nText(context, 'toolbox.crypto.text.copied')),
      ),
    );
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
      _busy = false;
    });
  }

  void _clearInput() {
    setState(() {
      _inputController.clear();
      _outputText = null;
      _statusMessage = null;
      _error = null;
    });
  }

  void _clearResult() {
    setState(() {
      _outputText = null;
      _statusMessage = null;
      _error = null;
    });
  }

  void _clearKeyFiles() {
    setState(() {
      _wipeKeyFile();
      _combinedKeyFile = null;
      _statusMessage = null;
      _error = null;
    });
  }

  void _wipeKeyFile() {
    final bytes = _combinedKeyFile?.bytes;
    if (bytes == null) {
      return;
    }
    for (var index = 0; index < bytes.length; index += 1) {
      bytes[index] = 0;
    }
  }

  String _friendlyCryptoError(Object error) {
    final text = error is ToolboxCryptoException
        ? error.message
        : error.toString();
    return text.replaceFirst('Exception: ', '');
  }
}

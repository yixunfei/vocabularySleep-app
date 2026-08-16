part of '../toolbox_crypto_security.dart';

enum _KeyFileMode { random, passphrase, combine }

class _KeyFileManagerPage extends StatefulWidget {
  const _KeyFileManagerPage();

  @override
  State<_KeyFileManagerPage> createState() => _KeyFileManagerPageState();
}

class _KeyFileManagerPageState extends State<_KeyFileManagerPage> {
  final ToolboxCryptoService _service = ToolboxCryptoService();
  final TextEditingController _lengthController = TextEditingController(
    text: '4096',
  );
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _saltController = TextEditingController(
    text: 'vocabulary_sleep_keyfile_derived_v1',
  );

  _KeyFileMode _mode = _KeyFileMode.random;
  ToolboxCryptoStrength _strength = ToolboxCryptoStrength.standard;
  Uint8List? _keyBytes;
  String? _fileName;
  String? _sha256;
  String? _savedPath;
  List<ToolboxCryptoKeyFileEntryInfo> _entries =
      const <ToolboxCryptoKeyFileEntryInfo>[];
  bool _busy = false;
  String? _statusMessage;
  String? _error;

  @override
  void dispose() {
    _lengthController.dispose();
    _passphraseController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.keyfile.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.keyfile.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildModePanel(context),
          const SizedBox(height: 14),
          _buildModeBody(context),
          const SizedBox(height: 14),
          _buildResultPanel(context),
        ],
      ),
    );
  }

  Widget _buildStageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accent = Color(0xFF6D5E9C);
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
                child: const Icon(Icons.vpn_key_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.keyfile.stage_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _keyBytes == null
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.keyfile.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.keyfile.stage_ready',
                              params: <String, Object?>{
                                'size': _formatCryptoBytes(_keyBytes!.length),
                                'hash': (_sha256 ?? '').substring(0, 16),
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
                  'toolbox.crypto.keyfile.chip_random',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.keyfile.chip_orderless',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.keyfile.chip_export',
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
    final color = isError ? theme.colorScheme.error : const Color(0xFF6D5E9C);
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
      title: _lifeI18nText(context, 'toolbox.crypto.keyfile.mode_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.keyfile.mode_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_KeyFileMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.keyfile.mode_label'),
          value: _mode,
          options: const <_LifeOption<_KeyFileMode>>[
            _LifeOption<_KeyFileMode>(
              value: _KeyFileMode.random,
              labelKey: 'toolbox.crypto.keyfile.mode_random',
            ),
            _LifeOption<_KeyFileMode>(
              value: _KeyFileMode.passphrase,
              labelKey: 'toolbox.crypto.keyfile.mode_passphrase',
            ),
            _LifeOption<_KeyFileMode>(
              value: _KeyFileMode.combine,
              labelKey: 'toolbox.crypto.keyfile.mode_combine',
            ),
          ],
          onChanged: _busy ? (_) {} : (value) => setState(() => _mode = value),
        ),
      ],
    );
  }

  Widget _buildModeBody(BuildContext context) {
    return switch (_mode) {
      _KeyFileMode.random => _buildRandomPanel(context),
      _KeyFileMode.passphrase => _buildPassphrasePanel(context),
      _KeyFileMode.combine => _buildCombinePanel(context),
    };
  }

  Widget _buildRandomPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.keyfile.random_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.keyfile.random_subtitle',
      ),
      children: <Widget>[
        _buildLengthField(context),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _generateRandom,
            icon: const Icon(Icons.casino_rounded),
            label: Text(
              _busy
                  ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                  : _lifeI18nText(
                      context,
                      'toolbox.crypto.keyfile.generate_random',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassphrasePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.keyfile.derive_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.keyfile.derive_subtitle',
      ),
      children: <Widget>[
        _buildLengthField(context),
        const SizedBox(height: 12),
        TextField(
          controller: _passphraseController,
          obscureText: true,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.keyfile.passphrase_label',
            ),
            hintText: _lifeI18nText(
              context,
              'toolbox.crypto.keyfile.passphrase_hint',
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _saltController,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.keyfile.salt_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.keyfile.salt_helper',
            ),
          ),
        ),
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
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _deriveFromPassphrase,
            icon: const Icon(Icons.password_rounded),
            label: Text(
              _busy
                  ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                  : _lifeI18nText(
                      context,
                      'toolbox.crypto.keyfile.derive_button',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCombinePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.keyfile.combine_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.keyfile.combine_subtitle',
      ),
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _combineImported,
            icon: const Icon(Icons.merge_type_rounded),
            label: Text(
              _busy
                  ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                  : _lifeI18nText(
                      context,
                      'toolbox.crypto.keyfile.pick_and_combine',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLengthField(BuildContext context) {
    return TextField(
      controller: _lengthController,
      enabled: !_busy,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.length_label',
        ),
        helperText: _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.length_helper',
        ),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final bytes = _keyBytes;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.keyfile.result_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.keyfile.result_subtitle',
      ),
      children: <Widget>[
        if (bytes == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.keyfile.no_result'),
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
                      _fileName ??
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.common.unnamed_file',
                      ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.common.size'),
                  value: _formatCryptoBytes(bytes.length),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.common.sha256'),
                  value: _sha256 ?? _cryptoSha256Short(bytes),
                ),
                if (_entries.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  ..._entries.map(
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
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _exportCurrent,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.keyfile.export_button',
                    ),
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

  Future<void> _generateRandom() async {
    try {
      final length = _requestedLength;
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.generating',
        );
      });
      final result = _service.generateKeyFile(
        length: length,
        fileName: 'vocabulary_sleep_random_keyfile.bin',
      );
      if (!mounted) {
        return;
      }
      _setKeyResult(
        bytes: result.bytes,
        fileName: result.fileName,
        sha256: result.sha256,
        entries: const <ToolboxCryptoKeyFileEntryInfo>[],
        messageKey: 'toolbox.crypto.keyfile.random_success',
      );
    } catch (error) {
      _setError('toolbox.crypto.keyfile.generate_failed', error);
    }
  }

  Future<void> _deriveFromPassphrase() async {
    try {
      final length = _requestedLength;
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.deriving',
        );
      });
      final result = _service.deriveKeyFileFromPassphrase(
        passphrase: _passphraseController.text,
        length: length,
        strength: _strength,
        saltText: _saltController.text,
        fileName: 'vocabulary_sleep_derived_keyfile.bin',
      );
      if (!mounted) {
        return;
      }
      _setKeyResult(
        bytes: result.bytes,
        fileName: result.fileName,
        sha256: result.sha256,
        entries: const <ToolboxCryptoKeyFileEntryInfo>[],
        messageKey: 'toolbox.crypto.keyfile.derive_success',
      );
    } catch (error) {
      _setError('toolbox.crypto.keyfile.derive_failed', error);
    }
  }

  Future<void> _combineImported() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.combining',
        );
      });
      final entries = await _pickCryptoKeyFileInputs();
      if (entries.isEmpty || !mounted) {
        setState(() => _busy = false);
        return;
      }
      final result = _service.combineKeyFiles(entries);
      if (!mounted) {
        return;
      }
      _setKeyResult(
        bytes: result.bytes,
        fileName: result.fileName,
        sha256: result.sha256,
        entries: result.entries,
        messageKey: 'toolbox.crypto.keyfile.combine_success',
      );
    } catch (error) {
      _setError('toolbox.crypto.keyfile.combine_failed', error);
    }
  }

  Future<void> _exportCurrent() async {
    final bytes = _keyBytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) {
      return;
    }
    try {
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.save_dialog',
        ),
        fileName: fileName,
        extension: 'bin',
        bytes: bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: bytes,
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
        _savedPath = savedPath;
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

  void _setKeyResult({
    required Uint8List bytes,
    required String fileName,
    required String sha256,
    required List<ToolboxCryptoKeyFileEntryInfo> entries,
    required String messageKey,
  }) {
    setState(() {
      _busy = false;
      _keyBytes = bytes;
      _fileName = fileName;
      _sha256 = sha256;
      _entries = entries;
      _savedPath = null;
      _error = null;
      _statusMessage = _lifeI18nText(
        context,
        messageKey,
        params: <String, Object?>{
          'size': _formatCryptoBytes(bytes.length),
          'hash': sha256.substring(0, 16),
        },
      );
    });
  }

  void _clearResult() {
    setState(() {
      _wipeBytes(_keyBytes);
      _keyBytes = null;
      _fileName = null;
      _sha256 = null;
      _savedPath = null;
      _entries = const <ToolboxCryptoKeyFileEntryInfo>[];
      _statusMessage = null;
      _error = null;
    });
  }

  void _wipeBytes(Uint8List? bytes) {
    if (bytes == null) {
      return;
    }
    for (var index = 0; index < bytes.length; index += 1) {
      bytes[index] = 0;
    }
  }

  void _setError(String key, Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = _lifeI18nText(
        context,
        key,
        params: <String, Object?>{'error': _friendlyCryptoError(error)},
      );
      _statusMessage = null;
    });
  }

  int get _requestedLength {
    final parsed = int.tryParse(_lengthController.text.trim()) ?? 4096;
    return parsed.clamp(32, ToolboxCryptoService.maxKeyFileBytes);
  }

  String _friendlyCryptoError(Object error) {
    final text = error is ToolboxCryptoException
        ? error.message
        : error.toString();
    return text.replaceFirst('Exception: ', '');
  }
}

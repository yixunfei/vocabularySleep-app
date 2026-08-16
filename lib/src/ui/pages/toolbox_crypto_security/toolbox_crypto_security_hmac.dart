part of '../toolbox_crypto_security.dart';

enum _HmacInputMode { text, file }

class _HmacToolPage extends StatefulWidget {
  const _HmacToolPage();

  @override
  State<_HmacToolPage> createState() => _HmacToolPageState();
}

class _HmacToolPageState extends State<_HmacToolPage> {
  static const Color _accent = Color(0xFF8A5A2B);

  final ToolboxCryptoExtraService _service = ToolboxCryptoExtraService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _expectedController = TextEditingController();

  _HmacInputMode _mode = _HmacInputMode.text;
  ToolboxCryptoHmacAlgorithm _algorithm = ToolboxCryptoHmacAlgorithm.sha256;
  _CryptoPickedFile? _pickedFile;
  ToolboxCryptoHmacResult? _result;
  String? _statusMessage;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _textController.dispose();
    _secretController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.hmac.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hmac.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildInputPanel(context),
          const SizedBox(height: 14),
          _buildSecretPanel(context),
          const SizedBox(height: 14),
          _buildAlgorithmPanel(context),
          const SizedBox(height: 14),
          _buildComparePanel(context),
          const SizedBox(height: 14),
          _buildActionButton(context),
          const SizedBox(height: 14),
          _buildResultPanel(context),
        ],
      ),
    );
  }

  Widget _buildStageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = _mode == _HmacInputMode.text
        ? utf8.encode(_textController.text).length
        : _pickedFile?.bytes.length ?? 0;
    return ToolboxSurfaceCard(
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: colorScheme.surfaceContainerLowest,
      borderColor: _accent.withValues(alpha: 0.22),
      shadowColor: _accent,
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
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.verified_user_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(context, 'toolbox.crypto.hmac.stage_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      size == 0
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.hmac.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.hmac.stage_ready',
                              params: <String, Object?>{
                                'size': _formatCryptoBytes(size),
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
                  _mode == _HmacInputMode.text
                      ? 'toolbox.crypto.hmac.mode_text'
                      : 'toolbox.crypto.hmac.mode_file',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  _cryptoHmacAlgorithmKey(_algorithm),
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(context, 'toolbox.crypto.hmac.chip_auth'),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
            ],
          ),
          if (_statusMessage != null || _error != null) ...<Widget>[
            const SizedBox(height: 12),
            _CryptoStatusBlock(
              message: _error ?? _statusMessage ?? '',
              accent: _accent,
              isError: _error != null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hmac.input_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hmac.input_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_HmacInputMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.hmac.mode_label'),
          value: _mode,
          options: const <_LifeOption<_HmacInputMode>>[
            _LifeOption<_HmacInputMode>(
              value: _HmacInputMode.text,
              labelKey: 'toolbox.crypto.hmac.mode_text',
            ),
            _LifeOption<_HmacInputMode>(
              value: _HmacInputMode.file,
              labelKey: 'toolbox.crypto.hmac.mode_file',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _mode = value;
                    _result = null;
                    _statusMessage = null;
                    _error = null;
                  });
                },
        ),
        const SizedBox(height: 12),
        if (_mode == _HmacInputMode.text)
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 8,
            enabled: !_busy,
            onChanged: (_) => setState(() => _result = null),
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.hmac.text_label',
              ),
            ),
          )
        else
          _buildFilePicker(context),
      ],
    );
  }

  Widget _buildFilePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _lifeI18nText(context, 'toolbox.crypto.hmac.pick_file'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
              onPressed: _busy || _pickedFile == null ? null : _clearFile,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: Text(
            _pickedFile == null
                ? _lifeI18nText(context, 'toolbox.crypto.hmac.no_file')
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.hmac.file_ready',
                    params: <String, Object?>{
                      'name': _pickedFile!.name,
                      'size': _formatCryptoBytes(_pickedFile!.bytes.length),
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecretPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hmac.secret_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hmac.secret_subtitle'),
      children: <Widget>[
        TextField(
          controller: _secretController,
          enabled: !_busy,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.hmac.secret_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.hmac.secret_helper',
            ),
          ),
          onChanged: (_) => setState(() => _result = null),
        ),
      ],
    );
  }

  Widget _buildAlgorithmPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hmac.algorithm_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.hmac.algorithm_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<ToolboxCryptoHmacAlgorithm>(
          label: _lifeI18nText(context, 'toolbox.crypto.hash.algorithm_label'),
          value: _algorithm,
          options: const <_LifeOption<ToolboxCryptoHmacAlgorithm>>[
            _LifeOption<ToolboxCryptoHmacAlgorithm>(
              value: ToolboxCryptoHmacAlgorithm.sha1,
              labelKey: 'toolbox.crypto.hash.algorithm.sha1',
            ),
            _LifeOption<ToolboxCryptoHmacAlgorithm>(
              value: ToolboxCryptoHmacAlgorithm.sha256,
              labelKey: 'toolbox.crypto.hash.algorithm.sha256',
            ),
            _LifeOption<ToolboxCryptoHmacAlgorithm>(
              value: ToolboxCryptoHmacAlgorithm.sha512,
              labelKey: 'toolbox.crypto.hash.algorithm.sha512',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _algorithm = value;
                    _result = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildComparePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hmac.compare_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hmac.compare_subtitle'),
      children: <Widget>[
        TextField(
          controller: _expectedController,
          enabled: !_busy,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.hmac.expected_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.hmac.expected_helper',
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy ? null : _calculate,
        icon: const Icon(Icons.verified_rounded),
        label: Text(
          _busy
              ? _lifeI18nText(context, 'toolbox.crypto.common.working')
              : _lifeI18nText(context, 'toolbox.crypto.hmac.calculate_button'),
        ),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final result = _result;
    final matched = result == null
        ? null
        : _service.hmacDigestMatches(
            expected: _expectedController.text,
            result: result,
          );
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hmac.result_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hmac.result_subtitle'),
      children: <Widget>[
        if (result == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.hmac.no_result'),
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
                    'toolbox.crypto.hash.algorithm_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    _cryptoHmacAlgorithmKey(result.algorithm),
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.common.size'),
                  value: _formatCryptoBytes(result.inputBytes),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.hmac.hex_label',
                  ),
                  value: result.hex,
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.hash.base64_label',
                  ),
                  value: result.base64,
                ),
                if (matched != null)
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.hmac.compare_status',
                    ),
                    value: _lifeI18nText(
                      context,
                      matched
                          ? 'toolbox.crypto.hmac.compare_match'
                          : 'toolbox.crypto.hmac.compare_mismatch',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _copyText(result.hex),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    _lifeI18nText(context, 'toolbox.crypto.hmac.copy_hex'),
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

  Future<void> _pickFile() async {
    try {
      final file = await _pickCryptoFile(
        maxBytes: ToolboxCryptoExtraService.maxHmacInputBytes,
      );
      if (file == null || !mounted) {
        return;
      }
      setState(() {
        _pickedFile = file;
        _result = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.hmac.file_selected',
          params: <String, Object?>{
            'name': file.name,
            'size': _formatCryptoBytes(file.bytes.length),
          },
        );
        _error = null;
      });
    } catch (error) {
      _setError('toolbox.crypto.hmac.pick_failed', error);
    }
  }

  Future<void> _calculate() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.hmac.calculating',
        );
      });
      final bytes = _mode == _HmacInputMode.text
          ? Uint8List.fromList(utf8.encode(_textController.text))
          : _pickedFile?.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const ToolboxCryptoExtraException('Input bytes are empty.');
      }
      final result = _service.calculateHmac(
        inputBytes: bytes,
        secret: _secretController.text,
        algorithm: _algorithm,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.hmac.calculate_success',
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.hmac.calculate_failed', error);
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lifeI18nText(context, 'toolbox.crypto.hmac.copied')),
      ),
    );
  }

  void _clearFile() {
    setState(() {
      _pickedFile = null;
      _result = null;
      _statusMessage = null;
      _error = null;
    });
  }

  void _clearResult() {
    setState(() {
      _result = null;
      _statusMessage = null;
      _error = null;
    });
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
        params: <String, Object?>{'error': _friendlyCryptoExtraError(error)},
      );
      _statusMessage = null;
    });
  }
}

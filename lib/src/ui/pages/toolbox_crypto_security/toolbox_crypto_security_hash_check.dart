part of '../toolbox_crypto_security.dart';

enum _HashInputMode { text, file }

final RegExp _cryptoHashHexDigestPattern = RegExp(r'^[0-9a-fA-F]+$');
final RegExp _cryptoHashBase64DigestPattern = RegExp(
  r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$',
);

@visibleForTesting
bool? toolboxCryptoHashDigestMatchesForTesting({
  required String expected,
  required ToolboxCryptoHashResult result,
}) {
  final normalizedExpected = _compactCryptoHashDigest(expected);
  if (normalizedExpected.isEmpty) {
    return null;
  }

  final resultHex = _compactCryptoHashDigest(result.hex);
  final digestBytes = _cryptoHashDigestByteLength(resultHex);
  if (digestBytes == null) {
    return false;
  }

  if (_isCryptoHashHexDigest(normalizedExpected, digestBytes)) {
    return normalizedExpected.toLowerCase() == resultHex.toLowerCase();
  }

  if (_isCryptoHashBase64Digest(normalizedExpected, digestBytes)) {
    final resultBase64 = _compactCryptoHashDigest(result.base64);
    return _isCryptoHashBase64Digest(resultBase64, digestBytes) &&
        normalizedExpected == resultBase64;
  }

  return false;
}

String _compactCryptoHashDigest(String value) {
  return value.replaceAll(RegExp(r'\s+'), '');
}

int? _cryptoHashDigestByteLength(String hex) {
  if (hex.isEmpty || hex.length.isOdd) {
    return null;
  }
  if (!_cryptoHashHexDigestPattern.hasMatch(hex)) {
    return null;
  }
  return hex.length ~/ 2;
}

bool _isCryptoHashHexDigest(String value, int digestBytes) {
  return digestBytes > 0 &&
      value.length == digestBytes * 2 &&
      _cryptoHashHexDigestPattern.hasMatch(value);
}

bool _isCryptoHashBase64Digest(String value, int digestBytes) {
  if (digestBytes <= 0 ||
      value.length != _cryptoHashBase64Length(digestBytes) ||
      !_cryptoHashBase64DigestPattern.hasMatch(value)) {
    return false;
  }
  try {
    return base64Decode(value).length == digestBytes;
  } on FormatException {
    return false;
  }
}

int _cryptoHashBase64Length(int byteLength) {
  return ((byteLength + 2) ~/ 3) * 4;
}

class _HashCheckToolPage extends StatefulWidget {
  const _HashCheckToolPage();

  @override
  State<_HashCheckToolPage> createState() => _HashCheckToolPageState();
}

class _HashCheckToolPageState extends State<_HashCheckToolPage> {
  final ToolboxCryptoService _service = ToolboxCryptoService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _expectedController = TextEditingController();

  _HashInputMode _mode = _HashInputMode.text;
  ToolboxCryptoHashAlgorithm _algorithm = ToolboxCryptoHashAlgorithm.sha256;
  _CryptoPickedFile? _pickedFile;
  ToolboxCryptoHashResult? _result;
  String? _statusMessage;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _textController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.hash.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hash.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildInputPanel(context),
          const SizedBox(height: 14),
          _buildAlgorithmPanel(context),
          const SizedBox(height: 14),
          _buildComparePanel(context),
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
    const accent = Color(0xFF4B7A4F);
    final size = _mode == _HashInputMode.text
        ? utf8.encode(_textController.text).length
        : _pickedFile?.bytes.length ?? 0;
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
                child: const Icon(Icons.tag_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(context, 'toolbox.crypto.hash.stage_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      size == 0
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.hash.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.hash.stage_ready',
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
                  _mode == _HashInputMode.text
                      ? 'toolbox.crypto.hash.mode_text'
                      : 'toolbox.crypto.hash.mode_file',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  _cryptoHashAlgorithmKey(_algorithm),
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.hash.chip_compare',
                ),
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

  Widget _buildInputPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hash.input_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hash.input_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_HashInputMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.hash.mode_label'),
          value: _mode,
          options: const <_LifeOption<_HashInputMode>>[
            _LifeOption<_HashInputMode>(
              value: _HashInputMode.text,
              labelKey: 'toolbox.crypto.hash.mode_text',
            ),
            _LifeOption<_HashInputMode>(
              value: _HashInputMode.file,
              labelKey: 'toolbox.crypto.hash.mode_file',
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
        if (_mode == _HashInputMode.text)
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 8,
            enabled: !_busy,
            onChanged: (_) => setState(() => _result = null),
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.hash.text_label',
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
                  _lifeI18nText(context, 'toolbox.crypto.hash.pick_file'),
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
                ? _lifeI18nText(context, 'toolbox.crypto.hash.no_file')
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.hash.file_ready',
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

  Widget _buildAlgorithmPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hash.algorithm_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.hash.algorithm_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<ToolboxCryptoHashAlgorithm>(
          label: _lifeI18nText(context, 'toolbox.crypto.hash.algorithm_label'),
          value: _algorithm,
          options: const <_LifeOption<ToolboxCryptoHashAlgorithm>>[
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.md5,
              labelKey: 'toolbox.crypto.hash.algorithm.md5',
            ),
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.sha1,
              labelKey: 'toolbox.crypto.hash.algorithm.sha1',
            ),
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.sha256,
              labelKey: 'toolbox.crypto.hash.algorithm.sha256',
            ),
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.sha512,
              labelKey: 'toolbox.crypto.hash.algorithm.sha512',
            ),
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.sha3_256,
              labelKey: 'toolbox.crypto.hash.algorithm.sha3_256',
            ),
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.blake2b256,
              labelKey: 'toolbox.crypto.hash.algorithm.blake2b_256',
            ),
            _LifeOption<ToolboxCryptoHashAlgorithm>(
              value: ToolboxCryptoHashAlgorithm.whirlpool,
              labelKey: 'toolbox.crypto.hash.algorithm.whirlpool',
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
      title: _lifeI18nText(context, 'toolbox.crypto.hash.compare_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hash.compare_subtitle'),
      children: <Widget>[
        TextField(
          controller: _expectedController,
          enabled: !_busy,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.hash.expected_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.hash.expected_helper',
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy ? null : _calculateHash,
        icon: const Icon(Icons.functions_rounded),
        label: Text(
          _busy
              ? _lifeI18nText(context, 'toolbox.crypto.common.working')
              : _lifeI18nText(context, 'toolbox.crypto.hash.calculate_button'),
        ),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final result = _result;
    final matched = result == null ? null : _compareResult(result);
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.hash.result_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.hash.result_subtitle'),
      children: <Widget>[
        if (result == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.hash.no_result'),
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
                    _cryptoHashAlgorithmKey(result.algorithm),
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.hash.hex_label',
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
                      'toolbox.crypto.hash.compare_status',
                    ),
                    value: _lifeI18nText(
                      context,
                      matched
                          ? 'toolbox.crypto.hash.compare_match'
                          : 'toolbox.crypto.hash.compare_mismatch',
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
                    _lifeI18nText(context, 'toolbox.crypto.hash.copy_hex'),
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
        maxBytes: ToolboxCryptoService.maxPlainBytes,
      );
      if (file == null || !mounted) {
        return;
      }
      setState(() {
        _pickedFile = file;
        _result = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.hash.file_selected',
          params: <String, Object?>{
            'name': file.name,
            'size': _formatCryptoBytes(file.bytes.length),
          },
        );
        _error = null;
      });
    } catch (error) {
      _setError('toolbox.crypto.hash.pick_failed', error);
    }
  }

  Future<void> _calculateHash() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.hash.calculating',
        );
      });
      final bytes = _mode == _HashInputMode.text
          ? Uint8List.fromList(utf8.encode(_textController.text))
          : _pickedFile?.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const ToolboxCryptoException('Input bytes are empty.');
      }
      final result = _service.hashBytes(bytes: bytes, algorithm: _algorithm);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.hash.calculate_success',
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.hash.calculate_failed', error);
    }
  }

  bool? _compareResult(ToolboxCryptoHashResult result) {
    return toolboxCryptoHashDigestMatchesForTesting(
      expected: _expectedController.text,
      result: result,
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lifeI18nText(context, 'toolbox.crypto.hash.copied')),
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

  String _friendlyCryptoError(Object error) {
    final text = error is ToolboxCryptoException
        ? error.message
        : error.toString();
    return text.replaceFirst('Exception: ', '');
  }
}

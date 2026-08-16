part of '../toolbox_crypto_security.dart';

enum _ShamirMode { split, recover }

enum _ShamirSplitSource { text, saltedPassword }

class _ShamirToolPage extends StatefulWidget {
  const _ShamirToolPage();

  @override
  State<_ShamirToolPage> createState() => _ShamirToolPageState();
}

class _ShamirToolPageState extends State<_ShamirToolPage> {
  static const Color _accent = Color(0xFF7A4E86);

  final ToolboxCryptoExtraService _service = ToolboxCryptoExtraService();
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _saltedPasswordController =
      TextEditingController();
  final TextEditingController _saltController = TextEditingController(
    text: ToolboxCryptoExtraService.generateSaltText(),
  );
  final TextEditingController _thresholdController = TextEditingController(
    text: '3',
  );
  final TextEditingController _shareCountController = TextEditingController(
    text: '5',
  );
  final TextEditingController _sharesController = TextEditingController();

  _ShamirMode _mode = _ShamirMode.split;
  _ShamirSplitSource _splitSource = _ShamirSplitSource.text;
  ToolboxCryptoShamirSplitResult? _splitResult;
  ToolboxCryptoShamirRecoverResult? _recoverResult;
  ToolboxCryptoSaltedPasswordDefinition? _saltedDefinition;
  String? _statusMessage;
  String? _error;

  @override
  void dispose() {
    _secretController.dispose();
    _saltedPasswordController.dispose();
    _saltController.dispose();
    _thresholdController.dispose();
    _shareCountController.dispose();
    _sharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.shamir.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.shamir.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildModePanel(context),
          const SizedBox(height: 14),
          _mode == _ShamirMode.split
              ? _buildSplitPanel(context)
              : _buildRecoverPanel(context),
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
                child: const Icon(Icons.call_split_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.shamir.stage_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stageSubtitle(context),
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
                  _mode == _ShamirMode.split
                      ? 'toolbox.crypto.shamir.mode_split'
                      : 'toolbox.crypto.shamir.mode_recover',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.chip_threshold',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.chip_local',
                ),
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

  String _stageSubtitle(BuildContext context) {
    if (_splitResult != null) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.shamir.stage_split_ready',
        params: <String, Object?>{
          'threshold': _splitResult!.threshold.toString(),
          'shares': _splitResult!.shareCount.toString(),
        },
      );
    }
    if (_recoverResult != null) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.shamir.stage_recover_ready',
        params: <String, Object?>{
          'size': _formatCryptoBytes(_recoverResult!.secretBytes.length),
        },
      );
    }
    return _lifeI18nText(context, 'toolbox.crypto.shamir.stage_empty');
  }

  Widget _buildModePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.shamir.mode_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.shamir.mode_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_ShamirMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.file.mode_label'),
          value: _mode,
          options: const <_LifeOption<_ShamirMode>>[
            _LifeOption<_ShamirMode>(
              value: _ShamirMode.split,
              labelKey: 'toolbox.crypto.shamir.mode_split',
            ),
            _LifeOption<_ShamirMode>(
              value: _ShamirMode.recover,
              labelKey: 'toolbox.crypto.shamir.mode_recover',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _mode = value;
              _splitResult = null;
              _recoverResult = null;
              _saltedDefinition = null;
              _statusMessage = null;
              _error = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSplitPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.shamir.split_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.shamir.split_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_ShamirSplitSource>(
          label: _lifeI18nText(context, 'toolbox.crypto.shamir.source_label'),
          value: _splitSource,
          options: const <_LifeOption<_ShamirSplitSource>>[
            _LifeOption<_ShamirSplitSource>(
              value: _ShamirSplitSource.text,
              labelKey: 'toolbox.crypto.shamir.source_text',
            ),
            _LifeOption<_ShamirSplitSource>(
              value: _ShamirSplitSource.saltedPassword,
              labelKey: 'toolbox.crypto.shamir.source_salted_password',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _splitSource = value;
              _resetSplitState();
            });
          },
        ),
        const SizedBox(height: 12),
        if (_splitSource == _ShamirSplitSource.text)
          TextField(
            controller: _secretController,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.shamir.secret_label',
              ),
              helperText: _lifeI18nText(
                context,
                'toolbox.crypto.shamir.secret_helper',
              ),
            ),
            onChanged: (_) => setState(_resetSplitState),
          )
        else ...<Widget>[
          TextField(
            controller: _saltedPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.shamir.salted_password_label',
              ),
              helperText: _lifeI18nText(
                context,
                'toolbox.crypto.shamir.salted_password_helper',
              ),
            ),
            onChanged: (_) => setState(_resetSplitState),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _saltController,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.shamir.salt_label',
              ),
              helperText: _lifeI18nText(
                context,
                'toolbox.crypto.shamir.salt_helper',
              ),
              suffixIcon: IconButton(
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.salt_refresh',
                ),
                onPressed: _refreshSalt,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            onChanged: (_) => setState(_resetSplitState),
          ),
          const SizedBox(height: 8),
          Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.shamir.salted_definition_note',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.threshold_label',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.threshold_helper',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _shareCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.share_count_label',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.share_count_helper',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecoverPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.shamir.recover_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.shamir.recover_subtitle',
      ),
      children: <Widget>[
        TextField(
          controller: _sharesController,
          minLines: 7,
          maxLines: 12,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.shamir.shares_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.shamir.shares_helper',
            ),
          ),
          onChanged: (_) => setState(() => _recoverResult = null),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _mode == _ShamirMode.split ? _split : _recover,
        icon: Icon(
          _mode == _ShamirMode.split
              ? Icons.call_split_rounded
              : Icons.merge_type_rounded,
        ),
        label: Text(
          _lifeI18nText(
            context,
            _mode == _ShamirMode.split
                ? 'toolbox.crypto.shamir.split_button'
                : 'toolbox.crypto.shamir.recover_button',
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.shamir.result_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.shamir.result_subtitle'),
      children: <Widget>[
        if (_splitResult == null && _recoverResult == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.shamir.no_result'),
            ),
          )
        else if (_splitResult != null)
          _buildSplitResult(context, _splitResult!)
        else
          _buildRecoverResult(context, _recoverResult!),
      ],
    );
  }

  Widget _buildSplitResult(
    BuildContext context,
    ToolboxCryptoShamirSplitResult result,
  ) {
    final definition = _saltedDefinition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifePreviewFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CryptoMetricRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.threshold_label',
                ),
                value: result.threshold.toString(),
              ),
              _CryptoMetricRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.share_count_label',
                ),
                value: result.shareCount.toString(),
              ),
              if (definition != null) ...<Widget>[
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.secret_source_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.salted_definition_value',
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.definition_fingerprint_label',
                  ),
                  value: definition.fingerprint,
                ),
              ],
              const SizedBox(height: 8),
              ...result.shares.map((share) => _buildShareItem(context, share)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                _copyText(result.shares.map((share) => share.text).join('\n')),
            icon: const Icon(Icons.copy_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.crypto.shamir.copy_all'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareItem(BuildContext context, ToolboxCryptoShamirShare share) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.shamir.share_item_label',
                    params: <String, Object?>{'index': share.index.toString()},
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.copy_share',
                ),
                onPressed: () => _copyText(share.text),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            share.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFeatures: const <ui.FontFeature>[
                ui.FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverResult(
    BuildContext context,
    ToolboxCryptoShamirRecoverResult result,
  ) {
    final text = result.utf8Text;
    final display = text ?? result.base64;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifePreviewFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CryptoMetricRow(
                label: _lifeI18nText(
                  context,
                  'toolbox.crypto.shamir.used_shares_label',
                ),
                value: result.usedShares.toString(),
              ),
              _CryptoMetricRow(
                label: _lifeI18nText(context, 'toolbox.crypto.common.size'),
                value: _formatCryptoBytes(result.secretBytes.length),
              ),
              const SizedBox(height: 8),
              SelectableText(display),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyText(display),
            icon: const Icon(Icons.copy_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.crypto.shamir.copy_recovered'),
            ),
          ),
        ),
      ],
    );
  }

  void _split() {
    try {
      final definition = _splitSource == _ShamirSplitSource.saltedPassword
          ? _service.defineSaltedPassword(
              password: _saltedPasswordController.text,
              salt: _saltController.text,
            )
          : null;
      final secretText = definition?.text ?? _secretController.text;
      final result = _service.splitShamirSecret(
        secretBytes: Uint8List.fromList(utf8.encode(secretText)),
        threshold: int.tryParse(_thresholdController.text.trim()) ?? 3,
        shareCount: int.tryParse(_shareCountController.text.trim()) ?? 5,
      );
      setState(() {
        _splitResult = result;
        _recoverResult = null;
        _saltedDefinition = definition;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.shamir.split_success',
        );
        _error = null;
      });
    } catch (error) {
      _setError('toolbox.crypto.shamir.split_failed', error);
    }
  }

  void _recover() {
    try {
      final result = _service.recoverShamirSecret(
        shareTexts: _sharesController.text.split(RegExp(r'\r?\n')),
      );
      setState(() {
        _recoverResult = result;
        _splitResult = null;
        _saltedDefinition = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.shamir.recover_success',
        );
        _error = null;
      });
    } catch (error) {
      _setError('toolbox.crypto.shamir.recover_failed', error);
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lifeI18nText(context, 'toolbox.crypto.shamir.copied')),
      ),
    );
  }

  void _setError(String key, Object error) {
    setState(() {
      _error = _lifeI18nText(
        context,
        key,
        params: <String, Object?>{'error': _friendlyCryptoExtraError(error)},
      );
      _statusMessage = null;
    });
  }

  void _refreshSalt() {
    setState(() {
      _saltController.text = ToolboxCryptoExtraService.generateSaltText();
      _resetSplitState();
    });
  }

  void _resetSplitState() {
    _splitResult = null;
    _saltedDefinition = null;
    _statusMessage = null;
    _error = null;
  }
}

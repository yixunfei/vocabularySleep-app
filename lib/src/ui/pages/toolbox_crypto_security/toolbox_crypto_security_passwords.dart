part of '../toolbox_crypto_security.dart';

class _PasswordGeneratorPage extends StatefulWidget {
  const _PasswordGeneratorPage();

  @override
  State<_PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<_PasswordGeneratorPage> {
  static const Color _accent = Color(0xFF5E6B2D);

  final ToolboxCryptoExtraService _service = ToolboxCryptoExtraService();
  final TextEditingController _lengthController = TextEditingController(
    text: '24',
  );
  final TextEditingController _batchCountController = TextEditingController(
    text: '5',
  );
  final TextEditingController _customCharsetController =
      TextEditingController();
  final TextEditingController _excludeCharactersController =
      TextEditingController(
        text: ToolboxCryptoExtraService.defaultPasswordExcludedCharacters,
      );
  final TextEditingController _wordCountController = TextEditingController(
    text: '5',
  );
  final TextEditingController _separatorController = TextEditingController(
    text: '-',
  );

  ToolboxCryptoPasswordMode _mode = ToolboxCryptoPasswordMode.password;
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeDigits = true;
  bool _includeSymbols = true;
  bool _capitalizeWords = false;
  bool _appendNumber = true;
  List<ToolboxCryptoPasswordResult> _results =
      const <ToolboxCryptoPasswordResult>[];
  String? _statusMessage;
  String? _error;

  @override
  void dispose() {
    _lengthController.dispose();
    _batchCountController.dispose();
    _customCharsetController.dispose();
    _excludeCharactersController.dispose();
    _wordCountController.dispose();
    _separatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.password.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.password.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildModePanel(context),
          const SizedBox(height: 14),
          _mode == ToolboxCryptoPasswordMode.password
              ? _buildPasswordOptionsPanel(context)
              : _buildPassphraseOptionsPanel(context),
          const SizedBox(height: 14),
          _buildActionButton(context),
          const SizedBox(height: 14),
          _buildResultPanel(context),
        ],
      ),
    );
  }

  Widget _buildStageCard(BuildContext context) {
    final firstResult = _results.isEmpty ? null : _results.first;
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
                child: const Icon(Icons.password_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password.stage_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstResult == null
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.password.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.password.stage_ready',
                              params: <String, Object?>{
                                'count': _results.length.toString(),
                                'entropy': firstResult.entropyBits
                                    .toStringAsFixed(1),
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
                  _mode == ToolboxCryptoPasswordMode.password
                      ? 'toolbox.crypto.password.mode_password'
                      : 'toolbox.crypto.password.mode_passphrase',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.password.chip_offline',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.password.chip_no_storage',
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

  Widget _buildModePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.password.mode_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.password.mode_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<ToolboxCryptoPasswordMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.file.mode_label'),
          value: _mode,
          options: const <_LifeOption<ToolboxCryptoPasswordMode>>[
            _LifeOption<ToolboxCryptoPasswordMode>(
              value: ToolboxCryptoPasswordMode.password,
              labelKey: 'toolbox.crypto.password.mode_password',
            ),
            _LifeOption<ToolboxCryptoPasswordMode>(
              value: ToolboxCryptoPasswordMode.passphrase,
              labelKey: 'toolbox.crypto.password.mode_passphrase',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _mode = value;
              _resetResultState();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPasswordOptionsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.password.options_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password.options_subtitle',
      ),
      children: <Widget>[
        TextField(
          controller: _lengthController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password.length_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password.length_helper',
            ),
          ),
          onChanged: (_) => setState(_resetResultState),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _batchCountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password.batch_count_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password.batch_count_helper',
            ),
          ),
          onChanged: (_) => setState(_resetResultState),
        ),
        const SizedBox(height: 10),
        _buildCheckbox(
          context,
          value: _includeLowercase,
          keyName: 'toolbox.crypto.password.include_lowercase',
          onChanged: (value) => setState(() {
            _includeLowercase = value;
            _resetResultState();
          }),
        ),
        _buildCheckbox(
          context,
          value: _includeUppercase,
          keyName: 'toolbox.crypto.password.include_uppercase',
          onChanged: (value) => setState(() {
            _includeUppercase = value;
            _resetResultState();
          }),
        ),
        _buildCheckbox(
          context,
          value: _includeDigits,
          keyName: 'toolbox.crypto.password.include_digits',
          onChanged: (value) => setState(() {
            _includeDigits = value;
            _resetResultState();
          }),
        ),
        _buildCheckbox(
          context,
          value: _includeSymbols,
          keyName: 'toolbox.crypto.password.include_symbols',
          onChanged: (value) => setState(() {
            _includeSymbols = value;
            _resetResultState();
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customCharsetController,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password.custom_charset_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password.custom_charset_helper',
            ),
          ),
          onChanged: (_) => setState(_resetResultState),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _excludeCharactersController,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password.exclude_charset_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password.exclude_charset_helper',
            ),
          ),
          onChanged: (_) => setState(_resetResultState),
        ),
      ],
    );
  }

  Widget _buildPassphraseOptionsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.password.passphrase_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password.passphrase_subtitle',
      ),
      children: <Widget>[
        TextField(
          controller: _wordCountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password.word_count_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password.word_count_helper',
            ),
          ),
          onChanged: (_) => setState(_resetResultState),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _separatorController,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password.separator_label',
            ),
          ),
          onChanged: (_) => setState(_resetResultState),
        ),
        const SizedBox(height: 10),
        _buildCheckbox(
          context,
          value: _capitalizeWords,
          keyName: 'toolbox.crypto.password.capitalize_words',
          onChanged: (value) => setState(() {
            _capitalizeWords = value;
            _resetResultState();
          }),
        ),
        _buildCheckbox(
          context,
          value: _appendNumber,
          keyName: 'toolbox.crypto.password.append_number',
          onChanged: (value) => setState(() {
            _appendNumber = value;
            _resetResultState();
          }),
        ),
      ],
    );
  }

  Widget _buildCheckbox(
    BuildContext context, {
    required bool value,
    required String keyName,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        title: Text(_lifeI18nText(context, keyName)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _generate,
        icon: const Icon(Icons.casino_rounded),
        label: Text(_lifeI18nText(context, 'toolbox.crypto.password.generate')),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final results = _results;
    final firstResult = results.isEmpty ? null : results.first;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.password.result_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password.result_subtitle',
      ),
      children: <Widget>[
        if (firstResult == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.password.no_result'),
            ),
          )
        else ...<Widget>[
          _LifePreviewFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var index = 0; index < results.length; index += 1) ...[
                  if (index > 0) const Divider(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _lifeI18nText(
                            context,
                            'toolbox.crypto.password.result_item_label',
                            params: <String, Object?>{
                              'index': (index + 1).toString(),
                            },
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: _accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: _lifeI18nText(
                          context,
                          'toolbox.crypto.password.copy_item',
                        ),
                        onPressed: () => _copyText(results[index].value),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    results[index].value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.password.generated_count_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    'toolbox.crypto.password.generated_count_value',
                    params: <String, Object?>{
                      'count': results.length.toString(),
                    },
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.password.entropy_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    'toolbox.crypto.password.entropy_value',
                    params: <String, Object?>{
                      'bits': firstResult.entropyBits.toStringAsFixed(1),
                    },
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.password.symbol_space_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    'toolbox.crypto.password.symbol_space_value',
                    params: <String, Object?>{
                      'count': firstResult.symbolSpace.toString(),
                    },
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
                  onPressed: () => _copyText(
                    results.map((result) => result.value).join('\n'),
                  ),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      results.length == 1
                          ? 'toolbox.crypto.password.copy'
                          : 'toolbox.crypto.password.copy_all',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
                onPressed: _clearResult,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _generate() {
    try {
      final results = _mode == ToolboxCryptoPasswordMode.password
          ? _service.generatePasswords(
              count: int.tryParse(_batchCountController.text.trim()) ?? 5,
              length: int.tryParse(_lengthController.text.trim()) ?? 24,
              includeLowercase: _includeLowercase,
              includeUppercase: _includeUppercase,
              includeDigits: _includeDigits,
              includeSymbols: _includeSymbols,
              customCharacterSet: _customCharsetController.text,
              excludedCharacters: _excludeCharactersController.text,
            )
          : <ToolboxCryptoPasswordResult>[
              _service.generatePassphrase(
                wordCount: int.tryParse(_wordCountController.text.trim()) ?? 5,
                separator: _separatorController.text.isEmpty
                    ? '-'
                    : _separatorController.text,
                capitalizeWords: _capitalizeWords,
                appendNumber: _appendNumber,
              ),
            ];
      setState(() {
        _results = results;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password.generate_success',
          params: <String, Object?>{'count': results.length.toString()},
        );
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.password.generate_failed',
          params: <String, Object?>{'error': _friendlyCryptoExtraError(error)},
        );
        _statusMessage = null;
      });
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lifeI18nText(context, 'toolbox.crypto.password.copied')),
      ),
    );
  }

  void _clearResult() {
    setState(_resetResultState);
  }

  void _resetResultState() {
    _results = const <ToolboxCryptoPasswordResult>[];
    _statusMessage = null;
    _error = null;
  }
}

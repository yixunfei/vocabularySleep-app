part of '../toolbox_crypto_security.dart';

enum _OtpMode { totp, hotp }

class _OtpToolPage extends StatefulWidget {
  const _OtpToolPage();

  @override
  State<_OtpToolPage> createState() => _OtpToolPageState();
}

class _OtpToolPageState extends State<_OtpToolPage> {
  static const Color _accent = Color(0xFF2F6F5E);

  final ToolboxCryptoExtraService _service = ToolboxCryptoExtraService();
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _counterController = TextEditingController(
    text: '0',
  );
  final TextEditingController _periodController = TextEditingController(
    text: '30',
  );

  _OtpMode _mode = _OtpMode.totp;
  ToolboxCryptoOtpAlgorithm _algorithm = ToolboxCryptoOtpAlgorithm.sha1;
  int _digits = 6;
  ToolboxCryptoOtpResult? _result;
  String? _statusMessage;
  String? _error;

  @override
  void dispose() {
    _secretController.dispose();
    _counterController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.otp.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.otp.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildSecretPanel(context),
          const SizedBox(height: 14),
          _buildModePanel(context),
          const SizedBox(height: 14),
          _buildAlgorithmPanel(context),
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
                child: const Icon(Icons.pin_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(context, 'toolbox.crypto.otp.stage_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result == null
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.otp.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.otp.stage_ready',
                              params: <String, Object?>{
                                'counter': _result!.counter.toString(),
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
                  _mode == _OtpMode.totp
                      ? 'toolbox.crypto.otp.mode_totp'
                      : 'toolbox.crypto.otp.mode_hotp',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  _cryptoOtpAlgorithmKey(_algorithm),
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.otp.chip_no_store',
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

  Widget _buildSecretPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.otp.secret_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.otp.secret_subtitle'),
      children: <Widget>[
        TextField(
          controller: _secretController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.otp.secret_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.otp.secret_helper',
            ),
          ),
          onChanged: (_) => setState(() => _result = null),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _generateSecret,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.crypto.otp.generate_secret'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.otp.mode_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.otp.mode_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<_OtpMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.file.mode_label'),
          value: _mode,
          options: const <_LifeOption<_OtpMode>>[
            _LifeOption<_OtpMode>(
              value: _OtpMode.totp,
              labelKey: 'toolbox.crypto.otp.mode_totp',
            ),
            _LifeOption<_OtpMode>(
              value: _OtpMode.hotp,
              labelKey: 'toolbox.crypto.otp.mode_hotp',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _mode = value;
              _result = null;
              _statusMessage = null;
              _error = null;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_mode == _OtpMode.totp)
          TextField(
            controller: _periodController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.otp.period_label',
              ),
              helperText: _lifeI18nText(
                context,
                'toolbox.crypto.otp.period_helper',
              ),
            ),
            onChanged: (_) => setState(() => _result = null),
          )
        else
          TextField(
            controller: _counterController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.otp.counter_label',
              ),
              helperText: _lifeI18nText(
                context,
                'toolbox.crypto.otp.counter_helper',
              ),
            ),
            onChanged: (_) => setState(() => _result = null),
          ),
        const SizedBox(height: 12),
        _LifeSegmentedField<int>(
          label: _lifeI18nText(context, 'toolbox.crypto.otp.digits_label'),
          value: _digits,
          options: const <_LifeOption<int>>[
            _LifeOption<int>(value: 6, labelKey: 'toolbox.crypto.otp.digits_6'),
            _LifeOption<int>(value: 7, labelKey: 'toolbox.crypto.otp.digits_7'),
            _LifeOption<int>(value: 8, labelKey: 'toolbox.crypto.otp.digits_8'),
          ],
          onChanged: (value) {
            setState(() {
              _digits = value;
              _result = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAlgorithmPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.otp.algorithm_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.otp.algorithm_subtitle'),
      children: <Widget>[
        _LifeSegmentedField<ToolboxCryptoOtpAlgorithm>(
          label: _lifeI18nText(context, 'toolbox.crypto.hash.algorithm_label'),
          value: _algorithm,
          options: const <_LifeOption<ToolboxCryptoOtpAlgorithm>>[
            _LifeOption<ToolboxCryptoOtpAlgorithm>(
              value: ToolboxCryptoOtpAlgorithm.sha1,
              labelKey: 'toolbox.crypto.hash.algorithm.sha1',
            ),
            _LifeOption<ToolboxCryptoOtpAlgorithm>(
              value: ToolboxCryptoOtpAlgorithm.sha256,
              labelKey: 'toolbox.crypto.hash.algorithm.sha256',
            ),
            _LifeOption<ToolboxCryptoOtpAlgorithm>(
              value: ToolboxCryptoOtpAlgorithm.sha512,
              labelKey: 'toolbox.crypto.hash.algorithm.sha512',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _algorithm = value;
              _result = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.play_circle_rounded),
        label: Text(_lifeI18nText(context, 'toolbox.crypto.otp.calculate')),
      ),
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final result = _result;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.otp.result_section'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.otp.result_subtitle'),
      children: <Widget>[
        if (result == null)
          _LifePreviewFrame(
            child: Text(_lifeI18nText(context, 'toolbox.crypto.otp.no_result')),
          )
        else ...<Widget>[
          _LifePreviewFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  result.code,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                _CryptoMetricRow(
                  label: _lifeI18nText(context, 'toolbox.crypto.otp.counter'),
                  value: result.counter.toString(),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.hash.algorithm_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    _cryptoOtpAlgorithmKey(result.algorithm),
                  ),
                ),
                if (result.secondsRemaining != null)
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.otp.remaining',
                    ),
                    value: _lifeI18nText(
                      context,
                      'toolbox.crypto.otp.remaining_value',
                      params: <String, Object?>{
                        'seconds': result.secondsRemaining.toString(),
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
                  onPressed: () => _copyText(result.code),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    _lifeI18nText(context, 'toolbox.crypto.otp.copy'),
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

  void _generateSecret() {
    setState(() {
      _secretController.text = _service.generateOtpSecret();
      _result = null;
      _error = null;
      _statusMessage = _lifeI18nText(
        context,
        'toolbox.crypto.otp.secret_generated',
      );
    });
  }

  void _calculate() {
    try {
      final result = _mode == _OtpMode.totp
          ? _service.totp(
              secret: _secretController.text,
              timestamp: DateTime.now().toUtc(),
              periodSeconds: int.tryParse(_periodController.text.trim()) ?? 30,
              digits: _digits,
              algorithm: _algorithm,
            )
          : _service.hotp(
              secret: _secretController.text,
              counter: int.tryParse(_counterController.text.trim()) ?? 0,
              digits: _digits,
              algorithm: _algorithm,
            );
      setState(() {
        _result = result;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.otp.calculate_success',
        );
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.otp.calculate_failed',
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
        content: Text(_lifeI18nText(context, 'toolbox.crypto.otp.copied')),
      ),
    );
  }

  void _clearResult() {
    setState(() {
      _result = null;
      _statusMessage = null;
      _error = null;
    });
  }
}

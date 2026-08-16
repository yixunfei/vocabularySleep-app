part of '../toolbox_crypto_security.dart';

enum _AsymmetricToolMode { generate, signVerify, rsaEncrypt }

class _AsymmetricCryptoToolPage extends StatefulWidget {
  const _AsymmetricCryptoToolPage();

  @override
  State<_AsymmetricCryptoToolPage> createState() =>
      _AsymmetricCryptoToolPageState();
}

class _AsymmetricCryptoToolPageState extends State<_AsymmetricCryptoToolPage> {
  final ToolboxCryptoService _service = ToolboxCryptoService();
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final TextEditingController _cipherController = TextEditingController();

  _AsymmetricToolMode _mode = _AsymmetricToolMode.generate;
  ToolboxCryptoAsymmetricAlgorithm _algorithm =
      ToolboxCryptoAsymmetricAlgorithm.rsa2048;
  ToolboxCryptoAsymmetricKeyPairResult? _keyPair;
  String? _plainOutput;
  String? _verifyStatusKey;
  String? _statusMessage;
  String? _error;
  bool _busy = false;
  bool _privateKeyVisible = false;

  @override
  void dispose() {
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    _messageController.dispose();
    _signatureController.dispose();
    _cipherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.asymmetric.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.asymmetric.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          _buildModePanel(context),
          const SizedBox(height: 14),
          switch (_mode) {
            _AsymmetricToolMode.generate => _buildGeneratePanel(context),
            _AsymmetricToolMode.signVerify => _buildSignVerifyPanel(context),
            _AsymmetricToolMode.rsaEncrypt => _buildRsaPanel(context),
          },
          const SizedBox(height: 14),
          _buildKeyTextPanel(context),
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
                child: const Icon(Icons.key_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.asymmetric.stage_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _keyPair == null
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.asymmetric.stage_empty',
                            )
                          : _lifeI18nText(
                              context,
                              'toolbox.crypto.asymmetric.stage_ready',
                              params: <String, Object?>{
                                'fingerprint': _keyPair!.publicKeyFingerprint
                                    .substring(0, 16),
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
                  _cryptoAsymmetricAlgorithmKey(_algorithm),
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.asymmetric.chip_local_keys',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.asymmetric.chip_ecc_sign_only',
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

  Widget _buildModePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.asymmetric.mode_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.mode_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<_AsymmetricToolMode>(
          label: _lifeI18nText(context, 'toolbox.crypto.asymmetric.mode_label'),
          value: _mode,
          options: const <_LifeOption<_AsymmetricToolMode>>[
            _LifeOption<_AsymmetricToolMode>(
              value: _AsymmetricToolMode.generate,
              labelKey: 'toolbox.crypto.asymmetric.mode_generate',
            ),
            _LifeOption<_AsymmetricToolMode>(
              value: _AsymmetricToolMode.signVerify,
              labelKey: 'toolbox.crypto.asymmetric.mode_sign_verify',
            ),
            _LifeOption<_AsymmetricToolMode>(
              value: _AsymmetricToolMode.rsaEncrypt,
              labelKey: 'toolbox.crypto.asymmetric.mode_rsa_encrypt',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _mode = value;
                    _statusMessage = null;
                    _error = null;
                    _verifyStatusKey = null;
                    _plainOutput = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildGeneratePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.generate_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.generate_subtitle',
      ),
      children: <Widget>[
        _buildAlgorithmPicker(context),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _generateKeys,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: Text(
              _busy
                  ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                  : _lifeI18nText(
                      context,
                      'toolbox.crypto.asymmetric.generate_button',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmPicker(BuildContext context) {
    return _LifeSegmentedField<ToolboxCryptoAsymmetricAlgorithm>(
      label: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.algorithm_label',
      ),
      value: _algorithm,
      options: const <_LifeOption<ToolboxCryptoAsymmetricAlgorithm>>[
        _LifeOption<ToolboxCryptoAsymmetricAlgorithm>(
          value: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
          labelKey: 'toolbox.crypto.asymmetric.algorithm.rsa_2048',
        ),
        _LifeOption<ToolboxCryptoAsymmetricAlgorithm>(
          value: ToolboxCryptoAsymmetricAlgorithm.ecP256,
          labelKey: 'toolbox.crypto.asymmetric.algorithm.ec_p256',
        ),
      ],
      onChanged: _busy ? (_) {} : (value) => setState(() => _algorithm = value),
    );
  }

  Widget _buildSignVerifyPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.asymmetric.sign_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.sign_subtitle',
      ),
      children: <Widget>[
        _buildLargeTextField(
          context,
          controller: _messageController,
          labelKey: 'toolbox.crypto.asymmetric.message_label',
        ),
        const SizedBox(height: 12),
        _buildLargeTextField(
          context,
          controller: _privateKeyController,
          labelKey: 'toolbox.crypto.asymmetric.private_key_label',
        ),
        const SizedBox(height: 12),
        _buildLargeTextField(
          context,
          controller: _publicKeyController,
          labelKey: 'toolbox.crypto.asymmetric.public_key_label',
        ),
        const SizedBox(height: 12),
        _buildLargeTextField(
          context,
          controller: _signatureController,
          labelKey: 'toolbox.crypto.asymmetric.signature_label',
        ),
        if (_verifyStatusKey != null) ...<Widget>[
          const SizedBox(height: 12),
          _LifePreviewFrame(
            child: Text(_lifeI18nText(context, _verifyStatusKey!)),
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final signButton = FilledButton.icon(
              onPressed: _busy ? null : _signMessage,
              icon: const Icon(Icons.draw_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.crypto.asymmetric.sign_button'),
              ),
            );
            final verifyButton = OutlinedButton.icon(
              onPressed: _busy ? null : _verifyMessage,
              icon: const Icon(Icons.verified_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.asymmetric.verify_button',
                ),
              ),
            );
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  signButton,
                  const SizedBox(height: 10),
                  verifyButton,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: signButton),
                const SizedBox(width: 10),
                Expanded(child: verifyButton),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRsaPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.asymmetric.rsa_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.rsa_subtitle',
      ),
      children: <Widget>[
        _buildLargeTextField(
          context,
          controller: _messageController,
          labelKey: 'toolbox.crypto.asymmetric.rsa_plain_label',
        ),
        const SizedBox(height: 12),
        _buildLargeTextField(
          context,
          controller: _publicKeyController,
          labelKey: 'toolbox.crypto.asymmetric.public_key_label',
        ),
        const SizedBox(height: 12),
        _buildLargeTextField(
          context,
          controller: _cipherController,
          labelKey: 'toolbox.crypto.asymmetric.cipher_label',
        ),
        const SizedBox(height: 12),
        _buildLargeTextField(
          context,
          controller: _privateKeyController,
          labelKey: 'toolbox.crypto.asymmetric.private_key_label',
        ),
        if (_plainOutput != null) ...<Widget>[
          const SizedBox(height: 12),
          _LifePreviewFrame(child: SelectableText(_plainOutput!)),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final encryptButton = FilledButton.icon(
              onPressed: _busy ? null : _encryptSmallText,
              icon: const Icon(Icons.lock_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.asymmetric.encrypt_button',
                ),
              ),
            );
            final decryptButton = OutlinedButton.icon(
              onPressed: _busy ? null : _decryptSmallText,
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.asymmetric.decrypt_button',
                ),
              ),
            );
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  encryptButton,
                  const SizedBox(height: 10),
                  decryptButton,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: encryptButton),
                const SizedBox(width: 10),
                Expanded(child: decryptButton),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyTextPanel(BuildContext context) {
    final keyPair = _keyPair;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.asymmetric.key_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.asymmetric.key_subtitle',
      ),
      children: <Widget>[
        if (keyPair == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.asymmetric.no_keypair'),
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
                    'toolbox.crypto.asymmetric.algorithm_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    _cryptoAsymmetricAlgorithmKey(keyPair.algorithm),
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.asymmetric.fingerprint_label',
                  ),
                  value: keyPair.publicKeyFingerprint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildKeyOutputBlock(
            context,
            labelKey: 'toolbox.crypto.asymmetric.public_key_label',
            text: keyPair.publicKeyText,
          ),
          const SizedBox(height: 12),
          _buildKeyOutputBlock(
            context,
            labelKey: 'toolbox.crypto.asymmetric.private_key_label',
            text: keyPair.privateKeyText,
            sensitive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildKeyOutputBlock(
    BuildContext context, {
    required String labelKey,
    required String text,
    bool sensitive = false,
  }) {
    final theme = Theme.of(context);
    if (sensitive && !_privateKeyVisible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(context, labelKey),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.asymmetric.private_key_hidden_note',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() => _privateKeyVisible = true),
              icon: const Icon(Icons.visibility_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.asymmetric.show_private_key',
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _lifeI18nText(context, labelKey),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        _LifePreviewFrame(child: SelectableText(text)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              if (sensitive)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _privateKeyVisible = false),
                  icon: const Icon(Icons.visibility_off_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.asymmetric.hide_private_key',
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _copyText(text),
                icon: const Icon(Icons.copy_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    sensitive
                        ? 'toolbox.crypto.asymmetric.copy_private_key'
                        : 'toolbox.crypto.asymmetric.copy_button',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (sensitive) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.asymmetric.private_key_clipboard_note',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLargeTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelKey,
  }) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      minLines: 3,
      maxLines: 7,
      decoration: InputDecoration(labelText: _lifeI18nText(context, labelKey)),
    );
  }

  Future<void> _generateKeys() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.generating',
        );
      });
      final result = _service.generateAsymmetricKeyPair(algorithm: _algorithm);
      if (!mounted) {
        return;
      }
      setState(() {
        _keyPair = result;
        _privateKeyVisible = false;
        _publicKeyController.text = result.publicKeyText;
        _privateKeyController.text = result.privateKeyText;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.generate_success',
          params: <String, Object?>{
            'fingerprint': result.publicKeyFingerprint.substring(0, 16),
          },
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.asymmetric.generate_failed', error);
    }
  }

  Future<void> _signMessage() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _verifyStatusKey = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.signing',
        );
      });
      final result = _service.signBytes(
        bytes: Uint8List.fromList(utf8.encode(_messageController.text)),
        privateKeyText: _privateKeyController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _signatureController.text = result.signatureText;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.sign_success',
          params: <String, Object?>{
            'fingerprint': result.publicKeyFingerprint.substring(0, 16),
          },
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.asymmetric.sign_failed', error);
    }
  }

  Future<void> _verifyMessage() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.verifying',
        );
      });
      final result = _service.verifyBytes(
        bytes: Uint8List.fromList(utf8.encode(_messageController.text)),
        publicKeyText: _publicKeyController.text,
        signatureText: _signatureController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _verifyStatusKey = result.isValid
            ? 'toolbox.crypto.asymmetric.verify_match'
            : 'toolbox.crypto.asymmetric.verify_mismatch';
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.verify_done',
          params: <String, Object?>{
            'fingerprint': result.publicKeyFingerprint.substring(0, 16),
          },
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.asymmetric.verify_failed', error);
    }
  }

  Future<void> _encryptSmallText() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _plainOutput = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.encrypting',
        );
      });
      final result = _service.encryptBytesWithPublicKey(
        plainBytes: Uint8List.fromList(utf8.encode(_messageController.text)),
        publicKeyText: _publicKeyController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cipherController.text = result.cipherText;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.encrypt_success',
          params: <String, Object?>{'size': result.cipherBytes},
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.asymmetric.encrypt_failed', error);
    }
  }

  Future<void> _decryptSmallText() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _plainOutput = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.decrypting',
        );
      });
      final bytes = _service.decryptBytesWithPrivateKey(
        cipherText: _cipherController.text,
        privateKeyText: _privateKeyController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _plainOutput = utf8.decode(bytes, allowMalformed: true);
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.asymmetric.decrypt_success',
        );
        _busy = false;
      });
    } catch (error) {
      _setError('toolbox.crypto.asymmetric.decrypt_failed', error);
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(context, 'toolbox.crypto.asymmetric.copied'),
        ),
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

  String _friendlyCryptoError(Object error) {
    final text = error is ToolboxCryptoException
        ? error.message
        : error.toString();
    return text.replaceFirst('Exception: ', '');
  }
}

part of '../toolbox_crypto_security.dart';

extension _ContentMediaConfigPanels on _ContentMediaToolPageState {
  Widget _buildEncryptionPanel(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF1F7A72);
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
                : () => applyState(() => _configExpanded = !_configExpanded),
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
                          'toolbox.crypto.content_media.config_subtitle',
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
            : (value) => applyState(() => _algorithm = value),
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
            : (value) => applyState(() => _strength = value),
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
        onChanged: _busy
            ? (_) {}
            : (value) => applyState(() => _keyBits = value),
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
            : (value) => applyState(() => _macAlgorithm = value),
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
            : (value) => applyState(() => _signatureMode = value),
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
                          applyState(() {
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
        'toolbox.crypto.content_media.credential_subtitle',
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
        const SizedBox(height: 10),
        _buildContentMediaKeyFileActionRow(context),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: keyFile == null
              ? Text(_lifeI18nText(context, 'toolbox.crypto.file.no_key_files'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.file.key_files_selected',
                        params: <String, Object?>{
                          'count': keyFile.entries.length,
                          'size': _formatCryptoBytes(keyFile.length),
                          'hash': keyFile.sha256.substring(0, 16),
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CryptoMetricRow(
                      label: _lifeI18nText(
                        context,
                        'toolbox.crypto.common.sha256',
                      ),
                      value: keyFile.sha256,
                    ),
                    _CryptoMetricRow(
                      label: _lifeI18nText(
                        context,
                        'toolbox.crypto.common.size',
                      ),
                      value: _formatCryptoBytes(keyFile.length),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _buildSessionLimitPanel(context),
      ],
    );
  }

  Widget _buildSessionLimitPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(context, 'toolbox.crypto.content_media.limit_title'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _lifeI18nText(context, 'toolbox.crypto.content_media.limit_note'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxErrorsField = TextField(
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
                  border: const OutlineInputBorder(),
                ),
              );
              final maxDecryptsField = TextField(
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
                  border: const OutlineInputBorder(),
                ),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  children: <Widget>[
                    maxErrorsField,
                    const SizedBox(height: 10),
                    maxDecryptsField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: maxErrorsField),
                  const SizedBox(width: 10),
                  Expanded(child: maxDecryptsField),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              value: _overwriteMediaOnThreshold,
              onChanged: _busy
                  ? null
                  : (value) =>
                        applyState(() => _overwriteMediaOnThreshold = value),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.content_media.overwrite_media_toggle',
                ),
              ),
              subtitle: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.content_media.overwrite_media_note',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentMediaKeyFileActionRow(BuildContext context) {
    final keyFile = _combinedKeyFile;
    final importButton = OutlinedButton.icon(
      onPressed: _busy ? null : _pickKeyFiles,
      icon: const Icon(Icons.upload_file_rounded),
      label: Text(
        _lifeI18nText(context, 'toolbox.crypto.file.import_key_files'),
      ),
    );
    final generateButton = OutlinedButton.icon(
      onPressed: _busy ? null : _showGenerateKeyFileDialog,
      icon: const Icon(Icons.casino_rounded),
      label: Text(
        _lifeI18nText(context, 'toolbox.crypto.file.generate_key_file'),
      ),
    );
    final exportButton = OutlinedButton.icon(
      onPressed: _busy || keyFile == null ? null : _exportCurrentKeyFile,
      icon: const Icon(Icons.ios_share_rounded),
      label: Text(
        _lifeI18nText(context, 'toolbox.crypto.file.export_key_file'),
      ),
    );
    final clearButton = IconButton.filledTonal(
      tooltip: _lifeI18nText(context, 'toolbox.crypto.file.clear_key_files'),
      onPressed: _busy || keyFile == null ? null : _clearKeyFiles,
      icon: const Icon(Icons.key_off_rounded),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              importButton,
              const SizedBox(height: 8),
              generateButton,
              const SizedBox(height: 8),
              exportButton,
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerRight, child: clearButton),
            ],
          );
        }
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: importButton),
                const SizedBox(width: 10),
                Expanded(child: generateButton),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: exportButton),
                const SizedBox(width: 10),
                clearButton,
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : (_isEncode ? _encodeContent : _decodeContent),
            icon: Icon(
              _isEncode ? Icons.auto_awesome_mosaic : Icons.lock_open_rounded,
            ),
            label: Text(
              _busy
                  ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                  : _lifeI18nText(
                      context,
                      _isEncode
                          ? 'toolbox.crypto.content_media.encode_button'
                          : 'toolbox.crypto.content_media.decode_button',
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
}

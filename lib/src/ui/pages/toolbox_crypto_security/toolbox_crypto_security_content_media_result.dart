part of '../toolbox_crypto_security.dart';

extension _ContentMediaResultPanel on _ContentMediaToolPageState {
  Widget _buildResultPanel(BuildContext context) {
    final encode = _encodeResult;
    final decode = _decodeResult;
    final restoredText = _restoredText;
    final share = _shareResult;
    final canSharePng =
        encode?.format == ToolboxContentMediaFormat.imagePng &&
        _outputBytes != null;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.result_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.result_subtitle',
      ),
      children: <Widget>[
        if (_outputBytes == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.content_media.no_result'),
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
                if (encode != null) ...<Widget>[
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.envelope_size',
                    ),
                    value: _formatCryptoBytes(encode.envelopeBytes.length),
                  ),
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.envelope_sha256',
                    ),
                    value: encode.envelopeSha256.substring(0, 24),
                  ),
                  if (encode.imageWidth != null && encode.imageHeight != null)
                    _CryptoMetricRow(
                      label: _lifeI18nText(
                        context,
                        'toolbox.crypto.content_media.image_dimensions',
                      ),
                      value: '${encode.imageWidth} x ${encode.imageHeight}',
                    ),
                  if (encode.duration != null)
                    _CryptoMetricRow(
                      label: _lifeI18nText(
                        context,
                        'toolbox.crypto.content_media.audio_duration',
                      ),
                      value: _formatDuration(encode.duration!),
                    ),
                ],
                if (decode != null) ...<Widget>[
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.restored_size',
                    ),
                    value: _formatCryptoBytes(decode.plainBytes.length),
                  ),
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.envelope_sha256',
                    ),
                    value: decode.envelopeSha256.substring(0, 24),
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
          if (encode != null) ...<Widget>[
            _buildCreatedMediaPreview(context, encode),
            const SizedBox(height: 12),
          ],
          if (restoredText != null) ...<Widget>[
            LayoutBuilder(
              builder: (context, constraints) {
                final viewButton = OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _showRestoredTextDialog(restoredText),
                  icon: const Icon(Icons.article_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.view_text',
                    ),
                  ),
                );
                final copyButton = FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => _copyRestoredText(restoredText),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.copy_text',
                    ),
                  ),
                );
                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      viewButton,
                      const SizedBox(height: 8),
                      copyButton,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: viewButton),
                    const SizedBox(width: 10),
                    Expanded(child: copyButton),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _exportOutput,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.crypto.content_media.export'),
              ),
            ),
          ),
          if (canSharePng) ...<Widget>[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final damageButton = OutlinedButton.icon(
                  onPressed: _busy || _uploading ? null : _simulatePngDamage,
                  icon: const Icon(Icons.broken_image_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.damage_button',
                    ),
                  ),
                );
                final uploadButton = FilledButton.tonalIcon(
                  onPressed: _busy || _uploading
                      ? null
                      : _uploadEncryptedPngToUguu,
                  icon: _uploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      _uploading
                          ? 'toolbox.crypto.content_media.share_uploading_short'
                          : 'toolbox.crypto.content_media.share_upload_button',
                    ),
                  ),
                );
                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      damageButton,
                      const SizedBox(height: 8),
                      uploadButton,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: damageButton),
                    const SizedBox(width: 10),
                    Expanded(child: uploadButton),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            _LifePreviewFrame(
              child: share == null
                  ? Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.content_media.share_waiting',
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SelectableText(share.url.toString()),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (share.name.isNotEmpty)
                              ToolboxInfoPill(
                                text: share.name,
                                accent: const Color(0xFF1F7A72),
                                backgroundColor: const Color(
                                  0xFF1F7A72,
                                ).withValues(alpha: 0.08),
                              ),
                            if (share.sizeBytes != null)
                              ToolboxInfoPill(
                                text: _formatCryptoBytes(share.sizeBytes!),
                                accent: const Color(0xFF1F7A72),
                                backgroundColor: const Color(
                                  0xFF1F7A72,
                                ).withValues(alpha: 0.08),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _copyShareLink,
                                icon: const Icon(Icons.link_rounded),
                                label: Text(
                                  _lifeI18nText(
                                    context,
                                    'toolbox.crypto.content_media.copy_link',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              tooltip: _lifeI18nText(
                                context,
                                'toolbox.crypto.content_media.open_link',
                              ),
                              onPressed: _busy ? null : _openShareLink,
                              icon: const Icon(Icons.open_in_new_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildCreatedMediaPreview(
    BuildContext context,
    ToolboxContentMediaEncodeResult encode,
  ) {
    final theme = Theme.of(context);
    final bytes = _outputBytes;
    if (bytes == null) {
      return const SizedBox.shrink();
    }
    return _LifePreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.content_media.preview_title',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (encode.format == ToolboxContentMediaFormat.imagePng)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 220,
                color: theme.colorScheme.surfaceContainerLowest,
                alignment: Alignment.center,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.content_media.preview_image_failed',
                    ),
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final label = Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.preview_audio_label',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
                final button = FilledButton.tonalIcon(
                  onPressed: _busy ? null : _toggleAudioPreview,
                  icon: Icon(
                    _previewPlaying
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _lifeI18nText(
                      context,
                      _previewPlaying
                          ? 'toolbox.crypto.content_media.preview_audio_stop'
                          : 'toolbox.crypto.content_media.preview_audio_play',
                    ),
                  ),
                );
                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      label,
                      const SizedBox(height: 8),
                      button,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: label),
                    const SizedBox(width: 10),
                    button,
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

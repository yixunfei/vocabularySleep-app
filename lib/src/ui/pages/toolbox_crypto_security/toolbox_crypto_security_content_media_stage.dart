part of '../toolbox_crypto_security.dart';

extension _ContentMediaStagePanels on _ContentMediaToolPageState {
  Widget _buildStageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accent = Color(0xFF1F7A72);
    const support = Color(0xFF586C91);
    final stageText = _isEncode
        ? _lifeI18nText(
            context,
            'toolbox.crypto.content_media.stage_encode',
            params: <String, Object?>{'size': _formatCryptoBytes(_plainSize)},
          )
        : _lifeI18nText(
            context,
            _mediaFile == null
                ? 'toolbox.crypto.content_media.stage_decode_empty'
                : 'toolbox.crypto.content_media.stage_decode',
            params: <String, Object?>{
              'name':
                  _mediaFile?.name ??
                  _lifeI18nText(context, 'toolbox.crypto.common.unnamed_file'),
              'size': _formatCryptoBytes(_mediaFile?.bytes.length ?? 0),
            },
          );
    return ToolboxSurfaceCard(
      radius: ToolboxUiTokens.sectionPanelRadius,
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colorScheme.surfaceContainerLowest,
          accent.withValues(alpha: 0.055),
          support.withValues(alpha: 0.04),
        ],
      ),
      borderColor: accent.withValues(alpha: 0.22),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.content_media.stage_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stageText,
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  _isEncode
                      ? 'toolbox.crypto.content_media.mode_encode'
                      : 'toolbox.crypto.content_media.mode_decode',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.content_media.chip_v5',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.content_media.chip_lossless',
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
      title: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.mode_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.mode_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<_ContentMediaMode>(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.content_media.mode_label',
          ),
          value: _mode,
          options: const <_LifeOption<_ContentMediaMode>>[
            _LifeOption<_ContentMediaMode>(
              value: _ContentMediaMode.encode,
              labelKey: 'toolbox.crypto.content_media.mode_encode',
            ),
            _LifeOption<_ContentMediaMode>(
              value: _ContentMediaMode.decode,
              labelKey: 'toolbox.crypto.content_media.mode_decode',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  applyState(() {
                    _mode = value;
                    _clearResultOnly();
                    _error = null;
                    _statusMessage = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.input_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.input_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<_ContentMediaInputKind>(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.content_media.input_kind_label',
          ),
          value: _inputKind,
          options: const <_LifeOption<_ContentMediaInputKind>>[
            _LifeOption<_ContentMediaInputKind>(
              value: _ContentMediaInputKind.text,
              labelKey: 'toolbox.crypto.content_media.input_text',
            ),
            _LifeOption<_ContentMediaInputKind>(
              value: _ContentMediaInputKind.file,
              labelKey: 'toolbox.crypto.content_media.input_file',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  applyState(() {
                    _inputKind = value;
                    _clearResultOnly();
                    _error = null;
                    _statusMessage = null;
                  });
                },
        ),
        const SizedBox(height: 12),
        if (_inputKind == _ContentMediaInputKind.text)
          TextField(
            controller: _textController,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => applyState(() {}),
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'toolbox.crypto.content_media.text_label',
              ),
            ),
          )
        else
          _buildPlainFilePicker(context),
      ],
    );
  }

  Widget _buildPlainFilePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _pickPlainFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.pick_plain_file',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
              onPressed: _busy ? null : _clearPlainFile,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: Text(
            _sourceFile == null
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.no_plain_file',
                  )
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.selected_file',
                    params: <String, Object?>{
                      'name': _sourceFile!.name,
                      'size': _formatCryptoBytes(_sourceFile!.bytes.length),
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPickPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.media_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.media_subtitle',
      ),
      children: <Widget>[
        TextField(
          controller: _mediaUrlController,
          enabled: !_busy,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.content_media.network_image_url_label',
            ),
            hintText: _lifeI18nText(
              context,
              'toolbox.crypto.content_media.network_image_url_hint',
            ),
            prefixIcon: const Icon(Icons.link_rounded),
          ),
          onSubmitted: (_) {
            if (!_busy) {
              _loadNetworkImage();
            }
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _busy ? null : _loadNetworkImage,
            icon: const Icon(Icons.cloud_download_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.content_media.load_network_image',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickEncodedMedia,
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.pick_local_media',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(context, 'toolbox.crypto.common.clear'),
              onPressed: _busy ? null : _clearEncodedMedia,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifePreviewFrame(
          child: Text(
            _mediaFile == null
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.no_media',
                  )
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.content_media.selected_file',
                    params: <String, Object?>{
                      'name': _mediaFile!.name,
                      'size': _formatCryptoBytes(_mediaFile!.bytes.length),
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.format_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.content_media.format_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<ToolboxContentMediaFormat>(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.content_media.format_label',
          ),
          value: _format,
          options: const <_LifeOption<ToolboxContentMediaFormat>>[
            _LifeOption<ToolboxContentMediaFormat>(
              value: ToolboxContentMediaFormat.imagePng,
              labelKey: 'toolbox.crypto.content_media.format_png',
            ),
            _LifeOption<ToolboxContentMediaFormat>(
              value: ToolboxContentMediaFormat.audioWav,
              labelKey: 'toolbox.crypto.content_media.format_wav',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) => applyState(() => _format = value),
        ),
        const SizedBox(height: 12),
        if (_format == ToolboxContentMediaFormat.imagePng) ...<Widget>[
          _buildPngImageOptions(context),
          const SizedBox(height: 12),
        ],
        _LifePreviewFrame(
          child: Text(
            _lifeI18nText(
              context,
              _format == ToolboxContentMediaFormat.imagePng
                  ? 'toolbox.crypto.content_media.format_png_note'
                  : 'toolbox.crypto.content_media.format_wav_note',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPngImageOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifeSegmentedField<_ContentMediaImageMinimum>(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.content_media.image_min_label',
          ),
          value: _imageMinimum,
          options: const <_LifeOption<_ContentMediaImageMinimum>>[
            _LifeOption<_ContentMediaImageMinimum>(
              value: _ContentMediaImageMinimum.auto,
              labelKey: 'toolbox.crypto.content_media.image_min_auto',
            ),
            _LifeOption<_ContentMediaImageMinimum>(
              value: _ContentMediaImageMinimum.square512,
              labelKey: 'toolbox.crypto.content_media.image_min_512',
            ),
            _LifeOption<_ContentMediaImageMinimum>(
              value: _ContentMediaImageMinimum.square1024,
              labelKey: 'toolbox.crypto.content_media.image_min_1024',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  applyState(() {
                    _imageMinimum = value;
                    _clearResultOnly();
                  });
                },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxContentMediaImageFillMode>(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.content_media.fill_mode_label',
          ),
          value: _imageFillMode,
          options: const <_LifeOption<ToolboxContentMediaImageFillMode>>[
            _LifeOption<ToolboxContentMediaImageFillMode>(
              value: ToolboxContentMediaImageFillMode.softGradient,
              labelKey: 'toolbox.crypto.content_media.fill_soft_gradient',
            ),
            _LifeOption<ToolboxContentMediaImageFillMode>(
              value: ToolboxContentMediaImageFillMode.paperGrain,
              labelKey: 'toolbox.crypto.content_media.fill_paper_grain',
            ),
            _LifeOption<ToolboxContentMediaImageFillMode>(
              value: ToolboxContentMediaImageFillMode.duskNoise,
              labelKey: 'toolbox.crypto.content_media.fill_dusk_noise',
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (value) {
                  applyState(() {
                    _imageFillMode = value;
                    _clearResultOnly();
                  });
                },
        ),
      ],
    );
  }
}

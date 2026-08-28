part of '../toolbox_life_tools.dart';

const List<_LifeColorOption> _idPhotoBackgroundOptions = <_LifeColorOption>[
  _LifeColorOption(
    color: Colors.white,
    labelKey: 'inline.plan295.life.white.ae2156d116df',
  ),
  _LifeColorOption(
    color: Color(0xFFE8F3FF),
    labelKey: 'inline.plan295.life.light_blue.81b2df2a904a',
  ),
  _LifeColorOption(
    color: Color(0xFF438BFF),
    labelKey: 'inline.plan295.life.blue.e74cca65888f',
  ),
  _LifeColorOption(
    color: Color(0xFFD94444),
    labelKey: 'inline.plan295.life.red.a80dab852185',
  ),
  _LifeColorOption(
    color: Color(0xFFF2F2F2),
    labelKey: 'inline.plan295.life.light_gray.df3b6c3322ea',
  ),
];

class _IdPhotoToolPage extends StatefulWidget {
  const _IdPhotoToolPage();

  @override
  State<_IdPhotoToolPage> createState() => _IdPhotoToolPageState();
}

class _IdPhotoToolPageState extends State<_IdPhotoToolPage> {
  static const ToolboxIdPhotoService _service = ToolboxIdPhotoService();
  static const ToolboxImageProcessingService _imageService =
      ToolboxImageProcessingService();

  String? _sourceName;
  Uint8List? _sourceBytes;
  ui.Image? _sourcePreview;
  int _sourceWidth = 0;
  int _sourceHeight = 0;
  int _sourceSize = 0;

  Uint8List? _resultBytes;
  ui.Image? _resultPreview;
  ToolboxIdPhotoRenderResult? _result;
  String? _savedPath;

  ToolboxIdPhotoPreset _preset = toolboxIdPhotoPresets.first;
  ToolboxIdPhotoOutputFormat _format = ToolboxIdPhotoOutputFormat.png;
  Color _backgroundColor = const Color(0xFF438BFF);
  double _dpi = 300;
  double _zoom = 1.18;
  double _offsetX = 0;
  double _offsetY = -0.06;
  double _backgroundTolerance = 0.44;
  double _replacementStrength = 0.82;
  double _jpegQuality = 92;
  bool _replaceBackground = true;
  bool _processing = false;
  bool _saving = false;
  String? _error;

  bool get _hasSource => _sourceBytes != null;
  bool get _hasResult => _resultBytes != null;

  @override
  void dispose() {
    _sourcePreview?.dispose();
    _resultPreview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.id_photo.0d7cf4d70985',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.offline_crop_plain_background_replac.e8312750b162',
      ),
      child: KeyedSubtree(
        key: const ValueKey<String>('life-id-photo-page'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildStagePanel(context),
            const SizedBox(height: 12),
            _buildConfigPanel(context),
            const SizedBox(height: 12),
            _buildActionRow(context),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              _buildErrorPanel(context),
            ],
            if (_savedPath != null) ...<Widget>[
              const SizedBox(height: 10),
              _buildSavedPanel(context),
            ],
            const SizedBox(height: 12),
            _buildResultPanel(context),
            const SizedBox(height: 12),
            _buildPreviewPanel(context),
            const SizedBox(height: 12),
            _buildNoticePanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStagePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.photo_stage.65adec1d66ad',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pick_a_portrait_first_then_adjust_pr.e34847c897b8',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.preset.cb8aaa69c5fa',
              ),
              value: _presetLabel(_preset, context),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.pixels.ccc640003b72',
              ),
              value: _preset.pixelPair(_dpi),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.background.5c33667dd504',
              ),
              value: _backgroundLabel(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_id_photo_pick_button'),
                onPressed: _processing || _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.pick_photo.8b755e2318a4',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan294.zen_sand.clear_ea17218b',
              ),
              onPressed: _processing || _saving ? null : _resetAll,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: _sourcePreview == null
              ? Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.no_photo_selected_yet.7d1bc1c83968',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sourceName ??
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.unnamed_photo.eef83605154c',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_sourceWidth}x$_sourceHeight · ${_formatBytes(_sourceSize)}',
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: RawImage(
                          image: _sourcePreview,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildConfigPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.generation_settings.d8fbf36e255b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.size_is_calculated_from_millimeters.38810f8f9302',
      ),
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('life_id_photo_preset_field'),
          child: _LifeSegmentedField<ToolboxIdPhotoPreset>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.photo_preset.69f15dc54716',
            ),
            value: _preset,
            options: toolboxIdPhotoPresets
                .map(
                  (preset) => _LifeOption<ToolboxIdPhotoPreset>(
                    value: preset,
                    labelText: _presetLabel(preset, context),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => setState(() {
              _preset = value;
              _clearResult();
            }),
          ),
        ),
        const SizedBox(height: 12),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_id_photo.dpi_9c8856',
          ),
          valueText: '${_dpi.round()} dpi · ${_preset.pixelPair(_dpi)}',
          value: _dpi,
          min: 150,
          max: 600,
          divisions: 45,
          onChanged: (value) => setState(() {
            _dpi = value;
            _clearResult();
          }),
        ),
        const SizedBox(height: 12),
        _LifeColorField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.background_color.5e5e51d81220',
          ),
          value: _backgroundColor,
          options: _idPhotoBackgroundOptions,
          onChanged: (value) => setState(() {
            _backgroundColor = value;
            _clearResult();
          }),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_id_photo_format_field'),
          child: _LifeSegmentedField<ToolboxIdPhotoOutputFormat>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.export_format.798da28c2095',
            ),
            value: _format,
            options: const <_LifeOption<ToolboxIdPhotoOutputFormat>>[
              _LifeOption<ToolboxIdPhotoOutputFormat>(
                value: ToolboxIdPhotoOutputFormat.png,
                labelKey: 'inline.plan295.life.png_clear.a09b2479f3cc',
              ),
              _LifeOption<ToolboxIdPhotoOutputFormat>(
                value: ToolboxIdPhotoOutputFormat.jpg,
                labelKey: 'inline.plan295.life.jpeg_smaller.590d2284a5b8',
              ),
            ],
            onChanged: (value) => setState(() {
              _format = value;
              _clearResult();
            }),
          ),
        ),
        if (_format == ToolboxIdPhotoOutputFormat.jpg) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.jpeg_quality.6f509fde325f',
            ),
            valueText: '${_jpegQuality.round()}',
            value: _jpegQuality,
            min: 60,
            max: 100,
            divisions: 40,
            onChanged: (value) => setState(() {
              _jpegQuality = value;
              _clearResult();
            }),
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          key: const ValueKey<String>(
            'life_id_photo_replace_background_switch',
          ),
          contentPadding: EdgeInsets.zero,
          value: _replaceBackground,
          onChanged: (value) => setState(() {
            _replaceBackground = value;
            _clearResult();
          }),
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.plain_background_replace.a29b13e8f31b',
            ),
          ),
          subtitle: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.samples_the_four_corners_and_replace.bf76bcf79eba',
            ),
          ),
        ),
        if (_replaceBackground) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.background_tolerance.cb43388ba7c9',
            ),
            valueText: '${(_backgroundTolerance * 100).round()}%',
            value: _backgroundTolerance,
            min: 0.05,
            max: 0.9,
            divisions: 34,
            onChanged: (value) => setState(() {
              _backgroundTolerance = value;
              _clearResult();
            }),
          ),
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.replace_strength.3a8863af64b7',
            ),
            valueText: '${(_replacementStrength * 100).round()}%',
            value: _replacementStrength,
            min: 0.35,
            max: 1,
            divisions: 26,
            onChanged: (value) => setState(() {
              _replacementStrength = value;
              _clearResult();
            }),
          ),
        ],
        const SizedBox(height: 12),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.crop_zoom.32dfd4a63e4d',
          ),
          valueText: '${_zoom.toStringAsFixed(2)}x',
          value: _zoom,
          min: 1,
          max: 2.4,
          divisions: 28,
          onChanged: (value) => setState(() {
            _zoom = value;
            _clearResult();
          }),
        ),
        const SizedBox(height: 12),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.horizontal_position.7e36369b6aa6',
          ),
          valueText: _signedPercent(_offsetX),
          value: _offsetX,
          min: -1,
          max: 1,
          divisions: 40,
          onChanged: (value) => setState(() {
            _offsetX = value;
            _clearResult();
          }),
        ),
        const SizedBox(height: 12),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.vertical_position.e809580ef58c',
          ),
          valueText: _signedPercent(_offsetY),
          value: _offsetY,
          min: -1,
          max: 1,
          divisions: 40,
          onChanged: (value) => setState(() {
            _offsetY = value;
            _clearResult();
          }),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey<String>('life_id_photo_generate_button'),
            onPressed: _hasSource && !_processing && !_saving
                ? _generate
                : null,
            icon: _processing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.badge_rounded),
            label: Text(
              _processing
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.life.generating.7a3fc9f68035',
                    )
                  : _lifeI18nText(
                      context,
                      'inline.plan295.life.generate.e140e9e0c26a',
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey<String>('life_id_photo_save_button'),
            onPressed: _hasResult && !_processing && !_saving
                ? _saveResult
                : null,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt_rounded),
            label: Text(
              _saving
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.life.saving.2c9b4d88c6ff',
                    )
                  : _lifeI18nText(
                      context,
                      'inline.plan295.crypto.export.f7657dd92440',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final result = _result;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.result_metrics.7fb4d460e8b5',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.after_generation_review_pixels_crop.07946a82a29e',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.target_pixels.1e894d59f63e',
              ),
              value: _preset.pixelPair(_dpi),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.output_size.bbdae54e8de3',
              ),
              value: _resultBytes == null
                  ? '--'
                  : _formatBytes(_resultBytes!.length),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.crop_box.44b6cfd294db',
              ),
              value: result == null
                  ? '--'
                  : '${result.cropWidth}x${result.cropHeight}',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.replaced_pixels.6c0659750231',
              ),
              value: result == null ? '--' : result.replacedPixels.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'inline.plan295.life.preview.5f7afb14e386'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.source_on_the_left_generated_id_phot.cf1e7df79351',
      ),
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            if (compact) {
              return Column(
                children: <Widget>[
                  _previewTile(
                    context: context,
                    titleKey: 'inline.plan295.life.source.bd1f1bbdfe8e',
                    image: _sourcePreview,
                  ),
                  const SizedBox(height: 10),
                  _previewTile(
                    context: context,
                    titleKey: 'inline.plan295.life.id_photo.3756c1731762',
                    image: _resultPreview,
                    backgroundColor: _backgroundColor,
                    aspectRatio:
                        _preset.pixelWidth(_dpi) / _preset.pixelHeight(_dpi),
                  ),
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(
                  child: _previewTile(
                    context: context,
                    titleKey: 'inline.plan295.life.source.bd1f1bbdfe8e',
                    image: _sourcePreview,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _previewTile(
                    context: context,
                    titleKey: 'inline.plan295.life.id_photo.3756c1731762',
                    image: _resultPreview,
                    backgroundColor: _backgroundColor,
                    aspectRatio:
                        _preset.pixelWidth(_dpi) / _preset.pixelHeight(_dpi),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _previewTile({
    required BuildContext context,
    required String titleKey,
    required ui.Image? image,
    Color? backgroundColor,
    double aspectRatio = 0.72,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(context, titleKey),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: image == null
                  ? Center(
                      child: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan295.crypto.no_preview.b2c10e9d539d',
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RawImage(image: image, fit: BoxFit.contain),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.usage_limits.3d3d70e341b3',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.this_tool_processes_images_locally_f.d276c0ffca54',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.plain_background_replacement_samples.5faa5306dc0a',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildErrorPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _buildSavedPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.saved.7b5e2b53bc',
          params: <String, Object?>{'_savedPath': _savedPath},
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      if (file == null) {
        return;
      }
      final bytes = await _readLifePickedImageBytes(file);
      final prepared = await _imageService.prepareSource(bytes);
      final preview = await _decodePreview(prepared.previewBytes);
      if (!mounted) {
        preview.dispose();
        return;
      }

      final oldSource = _sourcePreview;
      final oldResult = _resultPreview;
      setState(() {
        _sourceName = file.name;
        _sourceBytes = bytes;
        _sourcePreview = preview;
        _sourceWidth = prepared.width;
        _sourceHeight = prepared.height;
        _sourceSize = bytes.length;
        _resultBytes = null;
        _resultPreview = null;
        _result = null;
        _savedPath = null;
        _error = null;
      });
      oldSource?.dispose();
      oldResult?.dispose();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _logLifeImageError('id_photo.pick', error, stackTrace);
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.id.photo.failed_to_pick_photo.bf6cfec218',
          params: <String, Object?>{
            'error': _lifeImageProcessingErrorText(context, error),
          },
        );
      });
    }
  }

  Future<void> _generate() async {
    final source = _sourceBytes;
    if (source == null) {
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
      _savedPath = null;
    });

    try {
      final result = await _service.render(
        ToolboxIdPhotoRenderInput(
          sourceBytes: source,
          preset: _preset,
          dpi: _dpi,
          backgroundColor: _backgroundColor.toARGB32() & 0x00ffffff,
          outputFormat: _format,
          jpegQuality: _jpegQuality.round(),
          zoom: _zoom,
          offsetX: _offsetX,
          offsetY: _offsetY,
          replaceBackground: _replaceBackground,
          backgroundTolerance: _backgroundTolerance,
          replacementStrength: _replacementStrength,
        ),
      );
      final preview = await _decodePreview(result.bytes);
      if (!mounted) {
        preview.dispose();
        return;
      }
      final oldResult = _resultPreview;
      setState(() {
        _result = result;
        _resultBytes = result.bytes;
        _resultPreview = preview;
      });
      oldResult?.dispose();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _logLifeImageError('id_photo.run', error, stackTrace);
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.id.photo.generation_failed.9cae90229b',
          params: <String, Object?>{
            'error': _lifeImageProcessingErrorText(context, error),
          },
        );
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _saveResult() async {
    final result = _resultBytes;
    if (result == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _savedPath = null;
    });

    try {
      final sourceName = _sourceName ?? 'portrait';
      final baseName = path.basenameWithoutExtension(sourceName);
      final ext = _formatExtension(_format);
      final fileName = '${baseName}_${_preset.id}_${_dpi.round()}dpi.$ext';

      final savedPath = await _saveLifeBytes(
        context: context,
        bytes: result,
        fileName: fileName,
        fallbackFileName: '$baseName.$ext',
        subdirectory: 'id_photo',
        dialogTitleKey: 'inline.plan295.life.save_id_photo.7db851db140c',
        allowedExtensions: <String>[ext],
      );
      if (!mounted) {
        return;
      }
      setState(() => _savedPath = savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.save_failed.733e2f2246',
          params: <String, Object?>{'error': error},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<ui.Image> _decodePreview(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _presetLabel(ToolboxIdPhotoPreset preset, BuildContext context) {
    return _lifeI18nText(context, preset.labelKey);
  }

  String _backgroundLabel(BuildContext context) {
    for (final option in _idPhotoBackgroundOptions) {
      if (option.color.toARGB32() == _backgroundColor.toARGB32()) {
        return option.label(context);
      }
    }
    return '#${(_backgroundColor.toARGB32() & 0x00ffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _signedPercent(double value) {
    final percent = (value * 100).round();
    return percent > 0 ? '+$percent%' : '$percent%';
  }

  String _formatExtension(ToolboxIdPhotoOutputFormat format) {
    switch (format) {
      case ToolboxIdPhotoOutputFormat.png:
        return 'png';
      case ToolboxIdPhotoOutputFormat.jpg:
        return 'jpg';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  void _clearResult() {
    final oldResult = _resultPreview;
    _resultBytes = null;
    _resultPreview = null;
    _result = null;
    _savedPath = null;
    oldResult?.dispose();
  }

  void _resetAll() {
    final oldSource = _sourcePreview;
    final oldResult = _resultPreview;
    setState(() {
      _sourceName = null;
      _sourceBytes = null;
      _sourcePreview = null;
      _sourceWidth = 0;
      _sourceHeight = 0;
      _sourceSize = 0;
      _resultBytes = null;
      _resultPreview = null;
      _result = null;
      _savedPath = null;
      _preset = toolboxIdPhotoPresets.first;
      _format = ToolboxIdPhotoOutputFormat.png;
      _backgroundColor = const Color(0xFF438BFF);
      _dpi = 300;
      _zoom = 1.18;
      _offsetX = 0;
      _offsetY = -0.06;
      _backgroundTolerance = 0.44;
      _replacementStrength = 0.82;
      _jpegQuality = 92;
      _replaceBackground = true;
      _error = null;
    });
    oldSource?.dispose();
    oldResult?.dispose();
  }
}

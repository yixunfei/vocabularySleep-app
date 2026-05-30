part of '../toolbox_life_tools.dart';

enum _ImageCompressMode { ratio, width }

enum _ImageCompressAlgorithm {
  jpegBalanced,
  jpegAggressive,
  pngLossless,
  gifIndexed,
  autoBest,
}

enum _ImageCompressColorMode { original, grayscale, monochrome }

enum _ImageCompressDpiMode { keep, pngMetadata }

enum _ImageCompressFormat { jpg, png, gif }

class _ImageCompressCandidate {
  const _ImageCompressCandidate({
    required this.bytes,
    required this.algorithm,
    required this.format,
    required this.detail,
  });

  final Uint8List bytes;
  final _ImageCompressAlgorithm algorithm;
  final _ImageCompressFormat format;
  final String detail;
}

class _ImageCompressPage extends StatefulWidget {
  const _ImageCompressPage({this.embedded = false});

  final bool embedded;

  @override
  State<_ImageCompressPage> createState() => _ImageCompressPageState();
}

class _ImageCompressPageState extends State<_ImageCompressPage> {
  String? _sourceName;
  Uint8List? _sourceBytes;
  ui.Image? _sourcePreview;
  int _sourceWidth = 0;
  int _sourceHeight = 0;
  int _sourceSize = 0;

  Uint8List? _resultBytes;
  ui.Image? _resultPreview;
  int _resultWidth = 0;
  int _resultHeight = 0;
  int _resultSize = 0;
  String? _savedPath;

  _ImageCompressMode _mode = _ImageCompressMode.ratio;
  _ImageCompressAlgorithm _algorithm = _ImageCompressAlgorithm.autoBest;
  _ImageCompressColorMode _colorMode = _ImageCompressColorMode.original;
  _ImageCompressDpiMode _dpiMode = _ImageCompressDpiMode.keep;
  double _ratio = 0.8;
  double _jpegQuality = 75;
  double _bwThreshold = 0.5;
  double _dpi = 144;
  double _targetWidth = 1280;
  _ImageCompressAlgorithm? _resultAlgorithm;
  _ImageCompressFormat _resultFormat = _ImageCompressFormat.jpg;
  String? _resultAlgorithmDetail;

  bool _compressing = false;
  bool _saving = false;
  String? _error;

  bool get _hasSource => _sourceBytes != null;
  bool get _hasResult => _resultBytes != null;
  bool get _usesJpegQuality =>
      _algorithm == _ImageCompressAlgorithm.autoBest ||
      _algorithm == _ImageCompressAlgorithm.jpegBalanced ||
      _algorithm == _ImageCompressAlgorithm.jpegAggressive;
  bool get _usesMonochromeThreshold =>
      _colorMode == _ImageCompressColorMode.monochrome;
  bool get _usesDpiValue => _dpiMode == _ImageCompressDpiMode.pngMetadata;

  @override
  void dispose() {
    _sourcePreview?.dispose();
    _resultPreview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSourcePanel(context),
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
          _buildMetricsPanel(context),
          const SizedBox(height: 12),
          _buildPreviewPanel(context),
        ],
      );
    }
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_compression.836f865a3636',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.offline_local_compression_with_ratio.1a2a2947ef22',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSourcePanel(context),
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
          _buildMetricsPanel(context),
          const SizedBox(height: 12),
          _buildPreviewPanel(context),
        ],
      ),
    );
  }

  Widget _buildSourcePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.source_image.be0c3ad9c64b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pick_a_local_image_then_compress_by.0d77a9a57a2f',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_image_compress_pick_button'),
                onPressed: _compressing || _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.pick_image.9ce43eb388b3',
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
              onPressed: _compressing || _saving ? null : _resetAll,
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
                    'inline.plan295.life.no_image_selected_yet.1d4a4b1c698c',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sourceName ??
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.unnamed_image.e89ca462aeab',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.x.ef519271df',
                        params: <String, Object?>{
                          '_sourceWidth': _sourceWidth,
                          '_sourceHeight': _sourceHeight,
                          'p2': _formatBytes(_sourceSize),
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
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
    final maxWidth = _sourceWidth > 0 ? _sourceWidth.toDouble() : 4096;
    final double sliderMaxWidth = math.max(64.0, maxWidth).toDouble();
    final clampedTargetWidth = _targetWidth
        .clamp(64, sliderMaxWidth)
        .toDouble();
    final widthDivisions = ((sliderMaxWidth - 64) / 8)
        .floor()
        .clamp(1, 600)
        .toInt();
    final targetSizeText = _sourceWidth == 0 || _sourceHeight == 0
        ? _lifeI18nText(
            context,
            'inline.plan295.life.waiting_for_image.99646e865bc7',
          )
        : _mode == _ImageCompressMode.ratio
        ? '${(_sourceWidth * _ratio).round()}x${(_sourceHeight * _ratio).round()}'
        : '${clampedTargetWidth.round()}x${_scaledHeight(clampedTargetWidth.round())}';

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.compression_settings.f9cc25b98492',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.multiple_compression_algorithms_with.88612fe22f8d',
      ),
      children: <Widget>[
        _LifeSegmentedField<_ImageCompressMode>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.mode.5a854fd8b48d',
          ),
          value: _mode,
          options: <_LifeOption<_ImageCompressMode>>[
            const _LifeOption<_ImageCompressMode>(
              value: _ImageCompressMode.ratio,
              labelKey: 'inline.plan295.life.by_ratio.277739a0a091',
            ),
            const _LifeOption<_ImageCompressMode>(
              value: _ImageCompressMode.width,
              labelKey: 'inline.plan295.life.by_width.c0450e2c56f9',
            ),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<_ImageCompressAlgorithm>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.algorithm.1f86c487e91d',
          ),
          value: _algorithm,
          options: <_LifeOption<_ImageCompressAlgorithm>>[
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.autoBest,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.auto_best_43fd8b',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.jpegBalanced,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.jpeg_balanced_489128',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.jpegAggressive,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.jpeg_aggressive_22a8de',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.pngLossless,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.png_lossless_2d47ce',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.gifIndexed,
              labelKey:
                  'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.gif_indexed_aa8150',
            ),
          ],
          onChanged: (value) => setState(() => _algorithm = value),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_compress_color_mode_field'),
          child: _LifeSegmentedField<_ImageCompressColorMode>(
            label: _lifeI18nText(
              context,
              'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.lossy_preprocess_8c458c',
            ),
            value: _colorMode,
            options: <_LifeOption<_ImageCompressColorMode>>[
              const _LifeOption<_ImageCompressColorMode>(
                value: _ImageCompressColorMode.original,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.original_color_567f1a',
              ),
              const _LifeOption<_ImageCompressColorMode>(
                value: _ImageCompressColorMode.grayscale,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.grayscale_0c177d',
              ),
              const _LifeOption<_ImageCompressColorMode>(
                value: _ImageCompressColorMode.monochrome,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.black_white_36588b',
              ),
            ],
            onChanged: (value) => setState(() => _colorMode = value),
          ),
        ),
        if (_usesMonochromeThreshold) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.bw_threshold_0228f7',
            ),
            valueText: _bwThreshold.toStringAsFixed(2),
            value: _bwThreshold,
            min: 0.35,
            max: 0.75,
            divisions: 40,
            onChanged: (value) => setState(() => _bwThreshold = value),
          ),
        ],
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_compress_dpi_mode_field'),
          child: _LifeSegmentedField<_ImageCompressDpiMode>(
            label: _lifeI18nText(
              context,
              'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.dpi_option_6201da',
            ),
            value: _dpiMode,
            options: <_LifeOption<_ImageCompressDpiMode>>[
              const _LifeOption<_ImageCompressDpiMode>(
                value: _ImageCompressDpiMode.keep,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.no_custom_dpi_501946',
              ),
              const _LifeOption<_ImageCompressDpiMode>(
                value: _ImageCompressDpiMode.pngMetadata,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.write_png_dpi_0210f5',
              ),
            ],
            onChanged: (value) => setState(() => _dpiMode = value),
          ),
        ),
        if (_usesDpiValue) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.png_dpi_metadata_19b6d8',
            ),
            valueText: '${_dpi.round()} dpi',
            value: _dpi,
            min: 72,
            max: 300,
            divisions: 228,
            onChanged: (value) => setState(() => _dpi = value),
          ),
        ],
        const SizedBox(height: 12),
        if (_mode == _ImageCompressMode.ratio)
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.scale_ratio.73c7742c8a80',
            ),
            valueText: '${(_ratio * 100).round()}%',
            value: _ratio,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            onChanged: _hasSource
                ? (value) => setState(() => _ratio = value)
                : (_) {},
          )
        else
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.target_width.28e0428cadba',
            ),
            valueText: '${clampedTargetWidth.round()} px',
            value: clampedTargetWidth,
            min: 64,
            max: sliderMaxWidth.toDouble(),
            divisions: widthDivisions,
            onChanged: _hasSource
                ? (value) => setState(() => _targetWidth = value)
                : (_) {},
          ),
        if (_usesJpegQuality) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_id_photo.jpeg_quality_d81539',
            ),
            valueText: '${_jpegQuality.round()}',
            value: _jpegQuality,
            min: 20,
            max: 100,
            divisions: 80,
            onChanged: (value) => setState(() => _jpegQuality = value),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _lifeI18nText(
            context,
            'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.dpi_metadata_applies_only_to_png_output_jpeg_gif_ignore_179e15',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.expected_output_size.d89f044c2f',
            params: <String, Object?>{'targetSizeText': targetSizeText},
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey<String>('life_image_compress_run_button'),
            onPressed: _hasSource && !_compressing && !_saving
                ? _compress
                : null,
            icon: _compressing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.compress_rounded),
            label: Text(
              _compressing
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.life.compressing.106856574f74',
                    )
                  : _lifeI18nText(
                      context,
                      'inline.plan295.life.compress.73d7ee9a40ec',
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey<String>('life_image_compress_save_button'),
            onPressed: _hasResult && !_compressing && !_saving
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

  Widget _buildMetricsPanel(BuildContext context) {
    if (!_hasSource) {
      return _LifeSettingsPanel(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.compression_result.38590e7ddf99',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.life.pick_an_image_and_run_compression_to.fdaeccc398ac',
        ),
        children: const <Widget>[],
      );
    }

    final ratioText = _hasResult && _sourceSize > 0
        ? '${((_resultSize / _sourceSize) * 100).toStringAsFixed(1)}%'
        : '--';
    final shrinkText = _hasResult && _sourceSize > 0
        ? '${(100 - (_resultSize / _sourceSize * 100)).toStringAsFixed(1)}%'
        : '--';
    final dimensionText = _hasResult
        ? '${_resultWidth}x$_resultHeight'
        : _lifeI18nText(
            context,
            'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.not_compressed_c3e8a5',
          );
    final algorithmText = _hasResult
        ? _algorithmLabel(_resultAlgorithm ?? _algorithm, context)
        : '--';
    final detailText = _hasResult ? (_resultAlgorithmDetail ?? '--') : '--';

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.compression_result.38590e7ddf99',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.shows_output_size_ratio_and_dimensio.2ada3d60a69f',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.source_size.b47053a82484',
              ),
              value: _formatBytes(_sourceSize),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.output_size.bbdae54e8de3',
              ),
              value: _hasResult ? _formatBytes(_resultSize) : '--',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.size_ratio.c388cbbbf0d9',
              ),
              value: ratioText,
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.reduction.465277dac456',
              ),
              value: shrinkText,
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.output_dimensions.50d1fb163588',
              ),
              value: dimensionText,
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'literal.ui.pages.toolbox_crypto_security.toolbox_crypto_security_steganography.algorithm_70b858',
              ),
              value: algorithmText,
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.encoding_detail_3b8a5b',
              ),
              value: detailText,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'inline.plan295.life.preview.541b9f56bac7'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.source_on_the_left_and_compressed_re.5614b2c2e9d6',
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
                    titleKey: 'inline.plan295.life.compressed.e1f20d2e9acb',
                    image: _resultPreview,
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
                    titleKey: 'inline.plan295.life.compressed.e1f20d2e9acb',
                    image: _resultPreview,
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
            aspectRatio: 1,
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
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: true,
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      final bytes = file?.bytes;
      if (file == null || bytes == null || bytes.isEmpty) {
        return;
      }

      final preview = await _decodePreview(bytes);
      if (!mounted) {
        preview.dispose();
        return;
      }

      final oldSource = _sourcePreview;
      final oldResult = _resultPreview;
      setState(() {
        _sourceName = file.name;
        _sourceBytes = Uint8List.fromList(bytes);
        _sourcePreview = preview;
        _sourceWidth = preview.width;
        _sourceHeight = preview.height;
        _sourceSize = bytes.length;
        _targetWidth = preview.width.toDouble();
        _resultBytes = null;
        _resultPreview = null;
        _resultWidth = 0;
        _resultHeight = 0;
        _resultSize = 0;
        _resultAlgorithm = null;
        _resultAlgorithmDetail = null;
        _resultFormat = _ImageCompressFormat.jpg;
        _savedPath = null;
        _error = null;
      });
      oldSource?.dispose();
      oldResult?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.failed_to_pick_image.6e0bad236d',
          params: <String, Object?>{'error': error},
        );
      });
    }
  }

  Future<void> _compress() async {
    final source = _sourceBytes;
    if (source == null) {
      return;
    }
    setState(() {
      _compressing = true;
      _savedPath = null;
      _error = null;
    });
    try {
      final decoded = img.decodeImage(source);
      if (decoded == null) {
        throw StateError('Unsupported image format');
      }
      final oriented = img.bakeOrientation(decoded);
      final targetWidth = _mode == _ImageCompressMode.ratio
          ? math.max(1, (oriented.width * _ratio).round())
          : math.max(1, _targetWidth.round());
      final resized = targetWidth >= oriented.width
          ? oriented
          : img.copyResize(
              oriented,
              width: targetWidth,
              interpolation: img.Interpolation.average,
            );
      final preprocessed = _applyPreprocess(resized);
      final candidate = _encodeCandidate(preprocessed, _algorithm);
      final resultBytes = candidate.bytes;
      final preview = await _decodePreview(resultBytes);

      if (!mounted) {
        preview.dispose();
        return;
      }

      final oldResult = _resultPreview;
      setState(() {
        _resultBytes = resultBytes;
        _resultPreview = preview;
        _resultWidth = preview.width;
        _resultHeight = preview.height;
        _resultSize = resultBytes.length;
        _resultAlgorithm = candidate.algorithm;
        _resultAlgorithmDetail = candidate.detail;
        _resultFormat = candidate.format;
      });
      oldResult?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.compression_failed.e559f85464',
          params: <String, Object?>{'error': error},
        );
      });
    } finally {
      if (mounted) {
        setState(() => _compressing = false);
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
      final sourceName = _sourceName ?? 'image';
      final baseName = path.basenameWithoutExtension(sourceName);
      final ext = _formatExtension(_resultFormat);
      final fileName = '${baseName}_compressed.$ext';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeI18nText(
            context,
            'inline.plan295.life.save_compressed_image.071ebb6716f7',
          ),
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: <String>[ext],
          bytes: result,
        );
      } on UnimplementedError {
        savedPath = null;
      }

      if (!mounted) {
        return;
      }

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (kIsWeb) {
          setState(() {
            _savedPath = _lifeI18nText(
              context,
              'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
            );
          });
          return;
        }

        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'image_compress'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallback = File(
          path.join(exportDir.path, '${baseName}_$timestamp.$ext'),
        );
        await fallback.writeAsBytes(result, flush: true);
        if (!mounted) {
          return;
        }
        setState(() {
          _savedPath = fallback.path;
        });
        return;
      }

      setState(() {
        _savedPath = savedPath;
      });
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

  _ImageCompressCandidate _encodeCandidate(
    img.Image image,
    _ImageCompressAlgorithm algorithm,
  ) {
    final preprocessDetail = _preprocessDetailToken();
    final dpiDetail = _dpiDetailToken();
    String detailWithOptions(String detail) {
      final parts = <String>[
        detail,
        preprocessDetail,
        if (dpiDetail.isNotEmpty) dpiDetail,
      ];
      return parts.where((part) => part.isNotEmpty).join(' | ');
    }

    switch (algorithm) {
      case _ImageCompressAlgorithm.jpegBalanced:
        final bytes = Uint8List.fromList(
          img.encodeJpg(
            image,
            quality: _jpegQuality.round().clamp(20, 100),
            chroma: img.JpegChroma.yuv444,
          ),
        );
        return _ImageCompressCandidate(
          bytes: bytes,
          algorithm: algorithm,
          format: _ImageCompressFormat.jpg,
          detail: detailWithOptions('q${_jpegQuality.round()} yuv444'),
        );
      case _ImageCompressAlgorithm.jpegAggressive:
        final safeQuality = math
            .max(20, _jpegQuality.round() - 20)
            .clamp(20, 90);
        final bytes = Uint8List.fromList(
          img.encodeJpg(
            image,
            quality: safeQuality,
            chroma: img.JpegChroma.yuv420,
          ),
        );
        return _ImageCompressCandidate(
          bytes: bytes,
          algorithm: algorithm,
          format: _ImageCompressFormat.jpg,
          detail: detailWithOptions('q$safeQuality yuv420'),
        );
      case _ImageCompressAlgorithm.pngLossless:
        final pngDpi = _pngDpiMetadata();
        final encoder = img.PngEncoder(
          filter: img.PngFilter.paeth,
          level: 9,
          pixelDimensions: pngDpi,
        );
        final bytes = Uint8List.fromList(
          encoder.encode(image, singleFrame: true),
        );
        return _ImageCompressCandidate(
          bytes: bytes,
          algorithm: algorithm,
          format: _ImageCompressFormat.png,
          detail: detailWithOptions(
            pngDpi == null ? 'level9 paeth' : 'level9 paeth dpi${_dpi.round()}',
          ),
        );
      case _ImageCompressAlgorithm.gifIndexed:
        final bytes = Uint8List.fromList(
          img.encodeGif(
            image,
            samplingFactor: 32,
            dither: img.DitherKernel.none,
            ditherSerpentine: false,
          ),
        );
        return _ImageCompressCandidate(
          bytes: bytes,
          algorithm: algorithm,
          format: _ImageCompressFormat.gif,
          detail: detailWithOptions('indexed256 no-dither'),
        );
      case _ImageCompressAlgorithm.autoBest:
        final candidates = <_ImageCompressCandidate>[
          _encodeCandidate(image, _ImageCompressAlgorithm.jpegBalanced),
          _encodeCandidate(image, _ImageCompressAlgorithm.jpegAggressive),
          _encodeCandidate(image, _ImageCompressAlgorithm.pngLossless),
          _encodeCandidate(image, _ImageCompressAlgorithm.gifIndexed),
        ];
        candidates.sort((a, b) => a.bytes.length.compareTo(b.bytes.length));
        final winner = candidates.first;
        return _ImageCompressCandidate(
          bytes: winner.bytes,
          algorithm: winner.algorithm,
          format: winner.format,
          detail: 'auto -> ${winner.detail}',
        );
    }
  }

  String _algorithmLabel(
    _ImageCompressAlgorithm algorithm,
    BuildContext context,
  ) {
    switch (algorithm) {
      case _ImageCompressAlgorithm.autoBest:
        return _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.auto_best_43fd8b',
        );
      case _ImageCompressAlgorithm.jpegBalanced:
        return _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.jpeg_balanced_489128',
        );
      case _ImageCompressAlgorithm.jpegAggressive:
        return _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.jpeg_aggressive_22a8de',
        );
      case _ImageCompressAlgorithm.pngLossless:
        return _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.png_lossless_2d47ce',
        );
      case _ImageCompressAlgorithm.gifIndexed:
        return _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_compress.gif_indexed_aa8150',
        );
    }
  }

  String _formatExtension(_ImageCompressFormat format) {
    switch (format) {
      case _ImageCompressFormat.jpg:
        return 'jpg';
      case _ImageCompressFormat.png:
        return 'png';
      case _ImageCompressFormat.gif:
        return 'gif';
    }
  }

  img.Image _applyPreprocess(img.Image source) {
    final image = img.Image.from(source);
    switch (_colorMode) {
      case _ImageCompressColorMode.original:
        return image;
      case _ImageCompressColorMode.grayscale:
        return img.grayscale(image);
      case _ImageCompressColorMode.monochrome:
        return img.luminanceThreshold(
          image,
          threshold: _bwThreshold.clamp(0.0, 1.0),
        );
    }
  }

  String _preprocessDetailToken() {
    switch (_colorMode) {
      case _ImageCompressColorMode.original:
        return 'color';
      case _ImageCompressColorMode.grayscale:
        return 'gray';
      case _ImageCompressColorMode.monochrome:
        return 'bw@${_bwThreshold.toStringAsFixed(2)}';
    }
  }

  img.PngPhysicalPixelDimensions? _pngDpiMetadata() {
    if (_dpiMode != _ImageCompressDpiMode.pngMetadata) {
      return null;
    }
    return img.PngPhysicalPixelDimensions.dpi(_dpi.round());
  }

  String _dpiDetailToken() {
    if (_dpiMode != _ImageCompressDpiMode.pngMetadata) {
      return '';
    }
    return 'dpi${_dpi.round()}(png-only)';
  }

  int _scaledHeight(int width) {
    if (_sourceWidth <= 0 || _sourceHeight <= 0) {
      return 0;
    }
    return math.max(1, (_sourceHeight * width / _sourceWidth).round());
  }

  Future<ui.Image> _decodePreview(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
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
      _resultWidth = 0;
      _resultHeight = 0;
      _resultSize = 0;
      _resultAlgorithm = null;
      _resultAlgorithmDetail = null;
      _resultFormat = _ImageCompressFormat.jpg;
      _savedPath = null;
      _error = null;
      _ratio = 0.8;
      _jpegQuality = 75;
      _colorMode = _ImageCompressColorMode.original;
      _dpiMode = _ImageCompressDpiMode.keep;
      _bwThreshold = 0.5;
      _dpi = 144;
      _targetWidth = 1280;
      _mode = _ImageCompressMode.ratio;
    });
    oldSource?.dispose();
    oldResult?.dispose();
  }
}

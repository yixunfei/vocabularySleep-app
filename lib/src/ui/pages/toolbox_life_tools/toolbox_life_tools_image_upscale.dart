part of '../toolbox_life_tools.dart';

enum _ImageUpscaleMode { ratio, size, canvas }

typedef _ImageUpscaleAlgorithm = ToolboxImageUpscaleAlgorithm;

enum _ImageUpscaleFormat { png, jpg }

typedef _ImageUpscaleCanvasMode = ToolboxImageCanvasMode;

class _ImageUpscalePage extends StatefulWidget {
  const _ImageUpscalePage({this.embedded = false});

  final bool embedded;

  @override
  State<_ImageUpscalePage> createState() => _ImageUpscalePageState();
}

class _ImageUpscalePageState extends State<_ImageUpscalePage> {
  static const ToolboxImageProcessingService _imageService =
      ToolboxImageProcessingService();

  final TextEditingController _customScaleController = TextEditingController(
    text: '2.0',
  );

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

  _ImageUpscaleMode _mode = _ImageUpscaleMode.ratio;
  _ImageUpscaleAlgorithm _algorithm = _ImageUpscaleAlgorithm.duplicate;
  _ImageUpscaleFormat _format = _ImageUpscaleFormat.png;
  _ImageUpscaleCanvasMode _canvasMode = _ImageUpscaleCanvasMode.edge;
  double _scale = 2.0;
  final double _maxScale = 16.0;
  double _targetWidth = 2048;
  double _targetHeight = 2048;
  double _jpegQuality = 92;
  Color _canvasColor = const Color(0xFFF4F0E8);

  bool _processing = false;
  bool _saving = false;
  String? _error;
  String? _resultDetail;

  bool get _hasSource => _sourceBytes != null;
  bool get _hasResult => _resultBytes != null;
  bool get _usesCanvasMode => _mode == _ImageUpscaleMode.canvas;
  bool get _usesJpegQuality => _format == _ImageUpscaleFormat.jpg;

  @override
  void dispose() {
    _customScaleController.dispose();
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
          _buildMetricsPanel(context),
          const SizedBox(height: 12),
          _buildPreviewPanel(context),
        ],
      );
    }
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_upscale.36aed877fe01',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.local_interpolation_upscale_and_canv.9fb961eecdb8',
      ),
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
          _buildMetricsPanel(context),
          const SizedBox(height: 12),
          _buildPreviewPanel(context),
        ],
      ),
    );
  }

  Widget _buildStagePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.stage_overview.47aaca2aabf1',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pick_an_image_then_choose_interpolat.a2f69addfd85',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.current_mode.30bf20a5acbd',
              ),
              value: _modeLabel(_mode, context),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.crypto.algorithm.8435288f5f2f',
              ),
              value: _algorithmLabel(_algorithm, context),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.export_format.375fc1be842b',
              ),
              value: _formatLabel(_format, context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_image_upscale_pick_button'),
                onPressed: _processing || _saving ? null : _pickImage,
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
                      '${_sourceWidth}x$_sourceHeight · ${_lifeFormatBytes(_sourceSize)}',
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
    final sourceWidth = _sourceWidth > 0 ? _sourceWidth : 512;
    final sourceHeight = _sourceHeight > 0 ? _sourceHeight : 512;
    final maxWidth = math.max(sourceWidth.toDouble() * _maxScale, 512.0);
    final maxHeight = math.max(sourceHeight.toDouble() * _maxScale, 512.0);
    final clampedWidth = _targetWidth.clamp(32, maxWidth).toDouble();
    final clampedHeight = _targetHeight.clamp(32, maxHeight).toDouble();

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.upscale_settings.6ef8ad1fe903',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.use_common_interpolation_algorithms.4688ec98af92',
      ),
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('life_image_upscale_mode_field'),
          child: _LifeSegmentedField<_ImageUpscaleMode>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.upscale_mode.693d7c5c6529',
            ),
            value: _mode,
            options: const <_LifeOption<_ImageUpscaleMode>>[
              _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.ratio,
                labelKey: 'inline.plan295.life.by_scale.ea8b02907910',
              ),
              _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.size,
                labelKey: 'inline.plan295.life.target_size.f5281cce0aac',
              ),
              _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.canvas,
                labelKey: 'inline.plan295.life.canvas_expand.0d27fe89de89',
              ),
            ],
            onChanged: (value) => setState(() => _mode = value),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_upscale_algorithm_field'),
          child: _LifeSegmentedField<_ImageUpscaleAlgorithm>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.interpolation.8b6ac3aa65a1',
            ),
            value: _algorithm,
            options: const <_LifeOption<_ImageUpscaleAlgorithm>>[
              _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.duplicate,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.fast_duplicate_19fe43',
              ),
              _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.nearest,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.nearest_27b4ad',
              ),
              _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.linear,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.linear_0dcc7e',
              ),
              _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.cubic,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.cubic_175f76',
              ),
              _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.average,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.average_9c484a',
              ),
            ],
            onChanged: (value) => setState(() => _algorithm = value),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_upscale_format_field'),
          child: _LifeSegmentedField<_ImageUpscaleFormat>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.export_format.798da28c2095',
            ),
            value: _format,
            options: const <_LifeOption<_ImageUpscaleFormat>>[
              _LifeOption<_ImageUpscaleFormat>(
                value: _ImageUpscaleFormat.png,
                labelKey: 'inline.plan295.life.png_lossless.de21e3ccbc6d',
              ),
              _LifeOption<_ImageUpscaleFormat>(
                value: _ImageUpscaleFormat.jpg,
                labelKey: 'inline.plan295.life.jpeg_smaller.590d2284a5b8',
              ),
            ],
            onChanged: (value) => setState(() => _format = value),
          ),
        ),
        const SizedBox(height: 12),
        if (_mode == _ImageUpscaleMode.ratio)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.scale_factor.dab68efca3e3',
                ),
                valueText: '${_scale.toStringAsFixed(2)}x',
                value: _scale.clamp(1.0, _maxScale).toDouble(),
                min: 1.0,
                max: _maxScale,
                divisions: ((_maxScale - 1) * 4).round(),
                onChanged: _hasSource
                    ? (value) => setState(() {
                        _scale = value;
                        _customScaleController.text = value.toStringAsFixed(2);
                      })
                    : (_) {},
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>(
                  'life_image_upscale_custom_scale_field',
                ),
                controller: _customScaleController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: _hasSource && !_processing && !_saving,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.custom_scale.405d379ffb69',
                  ),
                  hintText: _lifeI18nText(
                    context,
                    'inline.plan295.life.for_example_2_3_5_12.8a2e1c4ebee8',
                  ),
                  suffixText: 'x',
                ),
                onSubmitted: (_) => _syncCustomScaleFromInput(),
                onChanged: (_) => _syncCustomScaleFromInput(live: true),
              ),
            ],
          )
        else ...<Widget>[
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.target_width.28e0428cadba',
            ),
            valueText: '${clampedWidth.round()} px',
            value: clampedWidth,
            min: 32,
            max: maxWidth,
            divisions: math.max(1, ((maxWidth - 32) / 8).floor()),
            onChanged: _hasSource
                ? (value) => setState(() => _targetWidth = value)
                : (_) {},
          ),
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.target_height.ac54c80c0ee8',
            ),
            valueText: '${clampedHeight.round()} px',
            value: clampedHeight,
            min: 32,
            max: maxHeight,
            divisions: math.max(1, ((maxHeight - 32) / 8).floor()),
            onChanged: _hasSource
                ? (value) => setState(() => _targetHeight = value)
                : (_) {},
          ),
        ],
        if (_usesCanvasMode) ...<Widget>[
          const SizedBox(height: 12),
          KeyedSubtree(
            key: const ValueKey<String>('life_image_upscale_canvas_mode_field'),
            child: _LifeSegmentedField<_ImageUpscaleCanvasMode>(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.canvas_fill.b63ff848a9bc',
              ),
              value: _canvasMode,
              options: const <_LifeOption<_ImageUpscaleCanvasMode>>[
                _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.edge,
                  labelKey: 'inline.plan295.life.edge_extend.efde37c9108d',
                ),
                _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.mirror,
                  labelKey: 'inline.plan295.life.mirror_fill.9281515b28ed',
                ),
                _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.solid,
                  labelKey: 'inline.plan295.life.solid_color.eb1e35ce00b9',
                ),
                _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.transparent,
                  labelKey: 'inline.plan295.life.transparent.fd7f50f5a927',
                ),
              ],
              onChanged: (value) => setState(() => _canvasMode = value),
            ),
          ),
          if (_canvasMode == _ImageUpscaleCanvasMode.solid) ...<Widget>[
            const SizedBox(height: 12),
            _LifeColorField(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.canvas_color.3ca332bf78d6',
              ),
              value: _canvasColor,
              options: const <_LifeColorOption>[
                _LifeColorOption(
                  color: Color(0xFFF4F0E8),
                  labelKey: 'inline.plan295.life.warm_ivory.638874eeb403',
                ),
                _LifeColorOption(
                  color: Color(0xFF111827),
                  labelKey: 'inline.plan295.life.ink_dark.29252d08994a',
                ),
                _LifeColorOption(
                  color: Color(0xFF2563EB),
                  labelKey: 'inline.plan295.life.blue.e74cca65888f',
                ),
                _LifeColorOption(
                  color: Color(0xFF16A34A),
                  labelKey: 'inline.plan295.life.green.c52c94d8b79e',
                ),
                _LifeColorOption(
                  color: Color(0xFFF97316),
                  labelKey: 'inline.plan295.life.orange.314513e06d79',
                ),
              ],
              onChanged: (value) => setState(() => _canvasColor = value),
            ),
          ],
        ],
        if (_usesJpegQuality) ...<Widget>[
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
            onChanged: (value) => setState(() => _jpegQuality = value),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.note_this_is_local_interpolation_and.f3fdedfff2f6',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.upscale.expected_output_x.ae4ed3378c',
            params: <String, Object?>{
              'p0': _expectedWidth(),
              'p1': _expectedHeight(),
            },
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
            key: const ValueKey<String>('life_image_upscale_run_button'),
            onPressed: _hasSource && !_processing && !_saving
                ? _runUpscale
                : null,
            icon: _processing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: Text(
              _processing
                  ? _lifeI18nText(context, 'processing')
                  : _lifeI18nText(
                      context,
                      'inline.plan295.life.upscale.f3c3c4008080',
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey<String>('life_image_upscale_save_button'),
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
          'inline.plan295.life.result_metrics.7fb4d460e8b5',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.life.pick_an_image_and_run_upscale_to_ins.cd06fd468d45',
        ),
        children: const <Widget>[],
      );
    }

    final sizeRatio = _hasResult && _sourceSize > 0
        ? (_resultSize / _sourceSize).toStringAsFixed(2)
        : '--';
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.result_metrics.7fb4d460e8b5',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.review_output_pixels_file_size_and_a.e702d35d94d5',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.source_pixels.39158dd7994b',
              ),
              value: '${_sourceWidth}x$_sourceHeight',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.output_pixels.7d68371a55a4',
              ),
              value: _hasResult ? '${_resultWidth}x$_resultHeight' : '--',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.source_size.b47053a82484',
              ),
              value: _lifeFormatBytes(_sourceSize),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.output_size.bbdae54e8de3',
              ),
              value: _hasResult ? _lifeFormatBytes(_resultSize) : '--',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.byte_ratio.076b1dfef3d2',
              ),
              value: _hasResult ? '${sizeRatio}x' : '--',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.processing_detail.e7253e93fc50',
              ),
              value: _hasResult ? (_resultDetail ?? '--') : '--',
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
        'inline.plan295.life.source_on_the_left_and_upscale_resul.66fc2d7f3bf5',
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
                    titleKey: 'inline.plan295.life.upscaled.0580d6bc1ed7',
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
                    titleKey: 'inline.plan295.life.upscaled.0580d6bc1ed7',
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
      final preview = await _decodeLifeUiImage(prepared.previewBytes);
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
        _targetWidth = math.max(64, prepared.width * 2).toDouble();
        _targetHeight = math.max(64, prepared.height * 2).toDouble();
        _customScaleController.text = _scale.toStringAsFixed(2);
        _resultBytes = null;
        _resultPreview = null;
        _resultWidth = 0;
        _resultHeight = 0;
        _resultSize = 0;
        _savedPath = null;
        _error = null;
        _resultDetail = null;
      });
      oldSource?.dispose();
      oldResult?.dispose();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _logLifeImageError('upscale.pick', error, stackTrace);
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.failed_to_pick_image.6e0bad236d',
          params: <String, Object?>{
            'error': _lifeImageProcessingErrorText(context, error),
          },
        );
      });
    }
  }

  Future<void> _runUpscale() async {
    final source = _sourceBytes;
    if (source == null) {
      return;
    }
    setState(() {
      _processing = true;
      _savedPath = null;
      _error = null;
    });

    try {
      final targetWidth = _expectedWidth();
      final targetHeight = _expectedHeight();
      final result = await _imageService.upscale(
        ToolboxImageUpscaleInput(
          sourceBytes: source,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          algorithm: _algorithm,
          outputFormat: ToolboxImageOutputFormat.values.byName(_format.name),
          expandCanvas: _mode == _ImageUpscaleMode.canvas,
          canvasMode: _canvasMode,
          canvasColor: _canvasColor.toARGB32() & 0x00ffffff,
          jpegQuality: _jpegQuality.round(),
        ),
      );
      final preview = await _decodeLifeUiImage(result.previewBytes);
      if (!mounted) {
        preview.dispose();
        return;
      }

      final oldResult = _resultPreview;
      setState(() {
        _resultBytes = result.bytes;
        _resultPreview = preview;
        _resultWidth = result.width;
        _resultHeight = result.height;
        _resultSize = result.bytes.length;
        _resultDetail = _buildResultDetail();
      });
      oldResult?.dispose();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _logLifeImageError('upscale.run', error, stackTrace);
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.upscale.upscale_failed.78f8fb476d',
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
      final sourceName = _sourceName ?? 'image';
      final baseName = path.basenameWithoutExtension(sourceName);
      final ext = ToolboxImageOutputFormat.values
          .byName(_format.name)
          .fileExtension;
      final fileName = '${baseName}_upscaled.$ext';

      final savedPath = await _saveLifeBytes(
        context: context,
        bytes: result,
        fileName: fileName,
        fallbackFileName: '$baseName.$ext',
        subdirectory: 'image_upscale',
        dialogTitleKey: 'inline.plan295.life.save_upscaled_image.03390afabac6',
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

  void _syncCustomScaleFromInput({bool live = false}) {
    final parsed = double.tryParse(_customScaleController.text.trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return;
    }
    final normalized = parsed.clamp(1.0, _maxScale).toDouble();
    if ((normalized - _scale).abs() < 0.001) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _scale = normalized;
    });
    if (!live) {
      _customScaleController.text = normalized.toStringAsFixed(2);
      _customScaleController.selection = TextSelection.fromPosition(
        TextPosition(offset: _customScaleController.text.length),
      );
    }
  }

  String _modeLabel(_ImageUpscaleMode mode, BuildContext context) {
    switch (mode) {
      case _ImageUpscaleMode.ratio:
        return _lifeI18nText(
          context,
          'inline.plan295.life.by_scale.ea8b02907910',
        );
      case _ImageUpscaleMode.size:
        return _lifeI18nText(
          context,
          'inline.plan295.life.target_size.f5281cce0aac',
        );
      case _ImageUpscaleMode.canvas:
        return _lifeI18nText(
          context,
          'inline.plan295.life.canvas_expand.0d27fe89de89',
        );
    }
  }

  String _algorithmLabel(
    _ImageUpscaleAlgorithm algorithm,
    BuildContext context,
  ) {
    switch (algorithm) {
      case _ImageUpscaleAlgorithm.duplicate:
        return _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.fast_duplicate_19fe43',
        );
      case _ImageUpscaleAlgorithm.nearest:
        return 'Nearest';
      case _ImageUpscaleAlgorithm.linear:
        return 'Linear';
      case _ImageUpscaleAlgorithm.cubic:
        return 'Cubic';
      case _ImageUpscaleAlgorithm.average:
        return 'Average';
    }
  }

  String _formatLabel(_ImageUpscaleFormat format, BuildContext context) {
    switch (format) {
      case _ImageUpscaleFormat.png:
        return _lifeI18nText(
          context,
          'inline.plan295.life.png_lossless.de21e3ccbc6d',
        );
      case _ImageUpscaleFormat.jpg:
        return _lifeI18nText(
          context,
          'inline.plan295.life.jpeg_smaller.590d2284a5b8',
        );
    }
  }

  String _buildResultDetail() {
    final parts = <String>[
      _modeLabel(_mode, context),
      _algorithmLabel(_algorithm, context),
      _formatLabel(_format, context),
    ];
    if (_mode == _ImageUpscaleMode.canvas) {
      parts.add(switch (_canvasMode) {
        _ImageUpscaleCanvasMode.transparent => 'transparent',
        _ImageUpscaleCanvasMode.edge => 'edge',
        _ImageUpscaleCanvasMode.mirror => 'mirror',
        _ImageUpscaleCanvasMode.solid => 'solid',
      });
    } else if (_mode == _ImageUpscaleMode.ratio) {
      parts.add('${_scale.toStringAsFixed(1)}x');
    } else {
      parts.add('${_expectedWidth()}x${_expectedHeight()}');
    }
    if (_format == _ImageUpscaleFormat.jpg) {
      parts.add('q${_jpegQuality.round()}');
    }
    return parts.join(' | ');
  }

  int _expectedWidth() {
    if (_sourceWidth <= 0) {
      return _mode == _ImageUpscaleMode.ratio ? 0 : _targetWidth.round();
    }
    return switch (_mode) {
      _ImageUpscaleMode.ratio => math.max(1, (_sourceWidth * _scale).round()),
      _ImageUpscaleMode.size ||
      _ImageUpscaleMode.canvas => math.max(_sourceWidth, _targetWidth.round()),
    };
  }

  int _expectedHeight() {
    if (_sourceHeight <= 0) {
      return _mode == _ImageUpscaleMode.ratio ? 0 : _targetHeight.round();
    }
    return switch (_mode) {
      _ImageUpscaleMode.ratio => math.max(1, (_sourceHeight * _scale).round()),
      _ImageUpscaleMode.size || _ImageUpscaleMode.canvas => math.max(
        _sourceHeight,
        _targetHeight.round(),
      ),
    };
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
      _savedPath = null;
      _error = null;
      _resultDetail = null;
      _mode = _ImageUpscaleMode.ratio;
      _algorithm = _ImageUpscaleAlgorithm.duplicate;
      _format = _ImageUpscaleFormat.png;
      _canvasMode = _ImageUpscaleCanvasMode.edge;
      _scale = 2.0;
      _customScaleController.text = '2.00';
      _targetWidth = 2048;
      _targetHeight = 2048;
      _jpegQuality = 92;
      _canvasColor = const Color(0xFFF4F0E8);
    });
    oldSource?.dispose();
    oldResult?.dispose();
  }
}

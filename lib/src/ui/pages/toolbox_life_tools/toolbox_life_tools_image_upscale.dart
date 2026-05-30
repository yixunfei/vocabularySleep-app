part of '../toolbox_life_tools.dart';

enum _ImageUpscaleMode { ratio, size, canvas }

enum _ImageUpscaleAlgorithm { duplicate, nearest, linear, cubic, average }

enum _ImageUpscaleFormat { png, jpg }

enum _ImageUpscaleCanvasMode { transparent, edge, mirror, solid }

class _ImageUpscalePage extends StatefulWidget {
  const _ImageUpscalePage({this.embedded = false});

  final bool embedded;

  @override
  State<_ImageUpscalePage> createState() => _ImageUpscalePageState();
}

class _ImageUpscalePageState extends State<_ImageUpscalePage> {
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
  double _maxScale = 16.0;
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
                      '${_sourceWidth}x$_sourceHeight · ${_formatBytes(_sourceSize)}',
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
              const _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.ratio,
                labelKey: 'inline.plan295.life.by_scale.ea8b02907910',
              ),
              const _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.size,
                labelKey: 'inline.plan295.life.target_size.f5281cce0aac',
              ),
              const _LifeOption<_ImageUpscaleMode>(
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
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.duplicate,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.fast_duplicate_19fe43',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.nearest,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.nearest_27b4ad',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.linear,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.linear_0dcc7e',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.cubic,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_image_upscale.cubic_175f76',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
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
              const _LifeOption<_ImageUpscaleFormat>(
                value: _ImageUpscaleFormat.png,
                labelKey: 'inline.plan295.life.png_lossless.de21e3ccbc6d',
              ),
              const _LifeOption<_ImageUpscaleFormat>(
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
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.edge,
                  labelKey: 'inline.plan295.life.edge_extend.efde37c9108d',
                ),
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.mirror,
                  labelKey: 'inline.plan295.life.mirror_fill.9281515b28ed',
                ),
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.solid,
                  labelKey: 'inline.plan295.life.solid_color.eb1e35ce00b9',
                ),
                const _LifeOption<_ImageUpscaleCanvasMode>(
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
        _targetWidth = math.max(64, preview.width * 2).toDouble();
        _targetHeight = math.max(64, preview.height * 2).toDouble();
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
      final decoded = img.decodeImage(source);
      if (decoded == null) {
        throw StateError('Unsupported image format');
      }
      final oriented = img.bakeOrientation(decoded);
      final targetWidth = _expectedWidth();
      final targetHeight = _expectedHeight();
      final output = _mode == _ImageUpscaleMode.canvas
          ? _expandCanvas(
              oriented,
              targetWidth: targetWidth,
              targetHeight: targetHeight,
            )
          : _resizeImage(
              oriented,
              targetWidth: targetWidth,
              targetHeight: targetHeight,
            );

      final resultBytes = _encodeResult(output);
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
        _resultDetail = _buildResultDetail();
      });
      oldResult?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.upscale.upscale_failed.78f8fb476d',
          params: <String, Object?>{'error': error},
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
      final ext = _formatExtension(_format);
      final fileName = '${baseName}_upscaled.$ext';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeI18nText(
            context,
            'inline.plan295.life.save_upscaled_image.03390afabac6',
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
          path.join(appDir.path, 'life_tools', 'image_upscale'),
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

  img.Image _expandCanvas(
    img.Image source, {
    required int targetWidth,
    required int targetHeight,
  }) {
    final resized = source.width == targetWidth && source.height == targetHeight
        ? img.Image.from(source)
        : _resizeImage(
            source,
            targetWidth: math.min(source.width, targetWidth),
            targetHeight: math.min(source.height, targetHeight),
          );

    if (_canvasMode == _ImageUpscaleCanvasMode.transparent) {
      return img.copyExpandCanvas(
        resized,
        newWidth: targetWidth,
        newHeight: targetHeight,
      );
    }
    if (_canvasMode == _ImageUpscaleCanvasMode.solid) {
      return img.copyExpandCanvas(
        resized,
        newWidth: targetWidth,
        newHeight: targetHeight,
        backgroundColor: img.ColorRgb8(
          (_canvasColor.r * 255.0).round().clamp(0, 255),
          (_canvasColor.g * 255.0).round().clamp(0, 255),
          (_canvasColor.b * 255.0).round().clamp(0, 255),
        ),
      );
    }

    final canvas = img.Image(
      width: targetWidth,
      height: targetHeight,
      numChannels: resized.numChannels,
    );
    final offsetX = (targetWidth - resized.width) ~/ 2;
    final offsetY = (targetHeight - resized.height) ~/ 2;
    _fillCanvasBySampling(
      canvas: canvas,
      source: resized,
      offsetX: offsetX,
      offsetY: offsetY,
      mirror: _canvasMode == _ImageUpscaleCanvasMode.mirror,
    );
    return canvas;
  }

  img.Image _resizeImage(
    img.Image source, {
    required int targetWidth,
    required int targetHeight,
  }) {
    final safeWidth = math.max(1, targetWidth);
    final safeHeight = math.max(1, targetHeight);
    if (_algorithm == _ImageUpscaleAlgorithm.duplicate) {
      return img.copyResize(
        source,
        width: safeWidth,
        height: safeHeight,
        interpolation: img.Interpolation.nearest,
      );
    }
    return img.copyResize(
      source,
      width: safeWidth,
      height: safeHeight,
      interpolation: _interpolationFor(_algorithm),
    );
  }

  void _fillCanvasBySampling({
    required img.Image canvas,
    required img.Image source,
    required int offsetX,
    required int offsetY,
    required bool mirror,
  }) {
    for (var y = 0; y < canvas.height; y += 1) {
      for (var x = 0; x < canvas.width; x += 1) {
        final inside =
            x >= offsetX &&
            x < offsetX + source.width &&
            y >= offsetY &&
            y < offsetY + source.height;
        if (inside) {
          canvas.setPixel(x, y, source.getPixel(x - offsetX, y - offsetY));
          continue;
        }

        final sampleX = mirror
            ? _mirrorSample(x - offsetX, source.width)
            : _clampSample(x - offsetX, source.width);
        final sampleY = mirror
            ? _mirrorSample(y - offsetY, source.height)
            : _clampSample(y - offsetY, source.height);
        canvas.setPixel(x, y, source.getPixel(sampleX, sampleY));
      }
    }
  }

  int _clampSample(int value, int length) {
    if (length <= 1) {
      return 0;
    }
    return value.clamp(0, length - 1);
  }

  int _mirrorSample(int value, int length) {
    if (length <= 1) {
      return 0;
    }
    var sample = value;
    final period = (length - 1) * 2;
    sample %= period;
    if (sample < 0) {
      sample += period;
    }
    if (sample >= length) {
      sample = period - sample;
    }
    return sample.clamp(0, length - 1);
  }

  Uint8List _encodeResult(img.Image image) {
    switch (_format) {
      case _ImageUpscaleFormat.png:
        return Uint8List.fromList(
          img.encodePng(image, level: 6, filter: img.PngFilter.paeth),
        );
      case _ImageUpscaleFormat.jpg:
        return Uint8List.fromList(
          img.encodeJpg(
            image,
            quality: _jpegQuality.round().clamp(60, 100),
            chroma: img.JpegChroma.yuv444,
          ),
        );
    }
  }

  img.Interpolation _interpolationFor(_ImageUpscaleAlgorithm algorithm) {
    switch (algorithm) {
      case _ImageUpscaleAlgorithm.duplicate:
        return img.Interpolation.nearest;
      case _ImageUpscaleAlgorithm.nearest:
        return img.Interpolation.nearest;
      case _ImageUpscaleAlgorithm.linear:
        return img.Interpolation.linear;
      case _ImageUpscaleAlgorithm.cubic:
        return img.Interpolation.cubic;
      case _ImageUpscaleAlgorithm.average:
        return img.Interpolation.average;
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

  String _formatExtension(_ImageUpscaleFormat format) {
    switch (format) {
      case _ImageUpscaleFormat.png:
        return 'png';
      case _ImageUpscaleFormat.jpg:
        return 'jpg';
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

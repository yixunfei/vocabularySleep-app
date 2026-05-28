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
      title: _lifeText(context, zh: '图片压缩', en: 'Image compression'),
      subtitle: _lifeText(
        context,
        zh: '本地离线压缩，支持比例、宽度和质量控制。',
        en: 'Offline local compression with ratio, width, and quality controls.',
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
      title: _lifeText(context, zh: '原图输入', en: 'Source image'),
      subtitle: _lifeText(
        context,
        zh: '选择本地图片后可按比例或宽度进行压缩。',
        en: 'Pick a local image, then compress by ratio or target width.',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_image_compress_pick_button'),
                onPressed: _compressing || _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_lifeText(context, zh: '选择图片', en: 'Pick image')),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
              onPressed: _compressing || _saving ? null : _resetAll,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: _sourcePreview == null
              ? Text(
                  _lifeText(
                    context,
                    zh: '尚未选择图片。',
                    en: 'No image selected yet.',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sourceName ??
                          _lifeText(context, zh: '未命名图片', en: 'Unnamed image'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lifeText(
                        context,
                        zh: '${_sourceWidth}x${_sourceHeight} · ${_formatBytes(_sourceSize)}',
                        en: '${_sourceWidth}x${_sourceHeight} · ${_formatBytes(_sourceSize)}',
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
        ? _lifeText(context, zh: '等待选择图片', en: 'Waiting for image')
        : _mode == _ImageCompressMode.ratio
        ? '${(_sourceWidth * _ratio).round()}x${(_sourceHeight * _ratio).round()}'
        : '${clampedTargetWidth.round()}x${_scaledHeight(clampedTargetWidth.round())}';

    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '压缩参数', en: 'Compression settings'),
      subtitle: _lifeText(
        context,
        zh: '默认输出 JPEG，可显著减小体积。',
        en: 'Multiple compression algorithms with optional auto-best selection.',
      ),
      children: <Widget>[
        _LifeSegmentedField<_ImageCompressMode>(
          label: _lifeText(context, zh: '压缩模式', en: 'Mode'),
          value: _mode,
          options: <_LifeOption<_ImageCompressMode>>[
            const _LifeOption<_ImageCompressMode>(
              value: _ImageCompressMode.ratio,
              labelZh: '按比例',
              labelEn: 'By ratio',
            ),
            const _LifeOption<_ImageCompressMode>(
              value: _ImageCompressMode.width,
              labelZh: '按宽度',
              labelEn: 'By width',
            ),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<_ImageCompressAlgorithm>(
          label: _lifeText(
            context,
            zh: 'Compression algorithm',
            en: 'Algorithm',
          ),
          value: _algorithm,
          options: <_LifeOption<_ImageCompressAlgorithm>>[
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.autoBest,
              labelZh: 'Auto best',
              labelEn: 'Auto best',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.jpegBalanced,
              labelZh: 'JPEG balanced',
              labelEn: 'JPEG balanced',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.jpegAggressive,
              labelZh: 'JPEG aggressive',
              labelEn: 'JPEG aggressive',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.pngLossless,
              labelZh: 'PNG lossless',
              labelEn: 'PNG lossless',
            ),
            const _LifeOption<_ImageCompressAlgorithm>(
              value: _ImageCompressAlgorithm.gifIndexed,
              labelZh: 'GIF indexed',
              labelEn: 'GIF indexed',
            ),
          ],
          onChanged: (value) => setState(() => _algorithm = value),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_compress_color_mode_field'),
          child: _LifeSegmentedField<_ImageCompressColorMode>(
            label: _lifeText(
              context,
              zh: 'Lossy preprocess',
              en: 'Lossy preprocess',
            ),
            value: _colorMode,
            options: <_LifeOption<_ImageCompressColorMode>>[
              const _LifeOption<_ImageCompressColorMode>(
                value: _ImageCompressColorMode.original,
                labelZh: 'Original color',
                labelEn: 'Original color',
              ),
              const _LifeOption<_ImageCompressColorMode>(
                value: _ImageCompressColorMode.grayscale,
                labelZh: 'Grayscale',
                labelEn: 'Grayscale',
              ),
              const _LifeOption<_ImageCompressColorMode>(
                value: _ImageCompressColorMode.monochrome,
                labelZh: 'Black/white',
                labelEn: 'Black/white',
              ),
            ],
            onChanged: (value) => setState(() => _colorMode = value),
          ),
        ),
        if (_usesMonochromeThreshold) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: 'BW threshold', en: 'BW threshold'),
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
            label: _lifeText(context, zh: 'DPI option', en: 'DPI option'),
            value: _dpiMode,
            options: <_LifeOption<_ImageCompressDpiMode>>[
              const _LifeOption<_ImageCompressDpiMode>(
                value: _ImageCompressDpiMode.keep,
                labelZh: 'No custom DPI',
                labelEn: 'No custom DPI',
              ),
              const _LifeOption<_ImageCompressDpiMode>(
                value: _ImageCompressDpiMode.pngMetadata,
                labelZh: 'Write PNG DPI',
                labelEn: 'Write PNG DPI',
              ),
            ],
            onChanged: (value) => setState(() => _dpiMode = value),
          ),
        ),
        if (_usesDpiValue) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(
              context,
              zh: 'PNG DPI metadata',
              en: 'PNG DPI metadata',
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
            label: _lifeText(context, zh: '缩放比例', en: 'Scale ratio'),
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
            label: _lifeText(context, zh: '目标宽度', en: 'Target width'),
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
            label: _lifeText(context, zh: 'JPEG quality', en: 'JPEG quality'),
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
          _lifeText(
            context,
            zh: 'DPI metadata applies only to PNG output. JPEG/GIF ignore custom DPI metadata.',
            en: 'DPI metadata applies only to PNG output. JPEG/GIF ignore custom DPI metadata.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _lifeText(
            context,
            zh: '预期输出尺寸: $targetSizeText',
            en: 'Expected output size: $targetSizeText',
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
                  ? _lifeText(context, zh: '压缩中...', en: 'Compressing...')
                  : _lifeText(context, zh: '开始压缩', en: 'Compress'),
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
                  ? _lifeText(context, zh: '保存中...', en: 'Saving...')
                  : _lifeText(context, zh: '导出结果', en: 'Export'),
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
        _lifeText(context, zh: '已保存: $_savedPath', en: 'Saved: $_savedPath'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildMetricsPanel(BuildContext context) {
    if (!_hasSource) {
      return _LifeSettingsPanel(
        title: _lifeText(context, zh: '压缩结果', en: 'Compression result'),
        subtitle: _lifeText(
          context,
          zh: '选择图片并执行压缩后展示结果。',
          en: 'Pick an image and run compression to view results.',
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
        : _lifeText(context, zh: 'Not compressed', en: 'Not compressed');
    final algorithmText = _hasResult
        ? _algorithmLabel(_resultAlgorithm ?? _algorithm, context)
        : '--';
    final detailText = _hasResult ? (_resultAlgorithmDetail ?? '--') : '--';

    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '压缩结果', en: 'Compression result'),
      subtitle: _lifeText(
        context,
        zh: '展示压缩后体积、比例和尺寸变化。',
        en: 'Shows output size, ratio, and dimensions.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '原图体积', en: 'Source size'),
              value: _formatBytes(_sourceSize),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '结果体积', en: 'Output size'),
              value: _hasResult ? _formatBytes(_resultSize) : '--',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '体积占比', en: 'Size ratio'),
              value: ratioText,
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '压缩幅度', en: 'Reduction'),
              value: shrinkText,
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '输出尺寸', en: 'Output dimensions'),
              value: dimensionText,
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: 'Algorithm', en: 'Algorithm'),
              value: algorithmText,
            ),
            ToolboxMetricCard(
              label: _lifeText(
                context,
                zh: 'Encoding detail',
                en: 'Encoding detail',
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
      title: _lifeText(context, zh: '效果预览', en: 'Preview'),
      subtitle: _lifeText(
        context,
        zh: '左侧原图，右侧压缩结果。',
        en: 'Source on the left and compressed result on the right.',
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
                    titleZh: '原图',
                    titleEn: 'Source',
                    image: _sourcePreview,
                  ),
                  const SizedBox(height: 10),
                  _previewTile(
                    context: context,
                    titleZh: '压缩后',
                    titleEn: 'Compressed',
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
                    titleZh: '原图',
                    titleEn: 'Source',
                    image: _sourcePreview,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _previewTile(
                    context: context,
                    titleZh: '压缩后',
                    titleEn: 'Compressed',
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
    required String titleZh,
    required String titleEn,
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
            _lifeText(context, zh: titleZh, en: titleEn),
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
                      _lifeText(context, zh: '暂无预览', en: 'No preview'),
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
        _error = _lifeText(
          context,
          zh: '选择图片失败: $error',
          en: 'Failed to pick image: $error',
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
        _error = _lifeText(
          context,
          zh: '压缩失败: $error',
          en: 'Compression failed: $error',
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
          dialogTitle: _lifeText(
            context,
            zh: '保存压缩图片',
            en: 'Save compressed image',
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
            _savedPath = _lifeText(
              context,
              zh: '浏览器下载已触发，请查看下载列表。',
              en: 'Browser download started. Check your downloads.',
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
        _error = _lifeText(
          context,
          zh: '保存失败: $error',
          en: 'Save failed: $error',
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
        return _lifeText(context, zh: 'Auto best', en: 'Auto best');
      case _ImageCompressAlgorithm.jpegBalanced:
        return _lifeText(context, zh: 'JPEG balanced', en: 'JPEG balanced');
      case _ImageCompressAlgorithm.jpegAggressive:
        return _lifeText(context, zh: 'JPEG aggressive', en: 'JPEG aggressive');
      case _ImageCompressAlgorithm.pngLossless:
        return _lifeText(context, zh: 'PNG lossless', en: 'PNG lossless');
      case _ImageCompressAlgorithm.gifIndexed:
        return _lifeText(context, zh: 'GIF indexed', en: 'GIF indexed');
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

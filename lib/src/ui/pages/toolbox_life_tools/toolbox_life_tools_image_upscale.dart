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
      title: _lifeText(context, zh: '图片扩大', en: 'Image upscale'),
      subtitle: _lifeText(
        context,
        zh: '本地插值放大与补像素扩展，用于把小图转成指定更大分辨率。',
        en: 'Local interpolation upscale and canvas expansion for larger target resolutions.',
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
      title: _lifeText(context, zh: '主舞台信息', en: 'Stage overview'),
      subtitle: _lifeText(
        context,
        zh: '先选图，再决定是插值放大还是仅扩展画布。结果可导出为 PNG 或 JPEG。',
        en: 'Pick an image, then choose interpolation upscale or canvas-only expansion. Export as PNG or JPEG.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '当前模式', en: 'Current mode'),
              value: _modeLabel(_mode, context),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '算法', en: 'Algorithm'),
              value: _algorithmLabel(_algorithm, context),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '输出格式', en: 'Export format'),
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
                label: Text(_lifeText(context, zh: '选择图片', en: 'Pick image')),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
              onPressed: _processing || _saving ? null : _resetAll,
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
      title: _lifeText(context, zh: '扩大参数', en: 'Upscale settings'),
      subtitle: _lifeText(
        context,
        zh: '支持常见插值算法、指定宽高和仅补像素扩边，适合先把图做大再进入其他图像流程。',
        en: 'Use common interpolation algorithms, exact target size, or pixel-expansion canvas modes before other image workflows.',
      ),
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('life_image_upscale_mode_field'),
          child: _LifeSegmentedField<_ImageUpscaleMode>(
            label: _lifeText(context, zh: '扩大模式', en: 'Upscale mode'),
            value: _mode,
            options: const <_LifeOption<_ImageUpscaleMode>>[
              const _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.ratio,
                labelZh: '按倍率放大',
                labelEn: 'By scale',
              ),
              const _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.size,
                labelZh: '指定宽高',
                labelEn: 'Target size',
              ),
              const _LifeOption<_ImageUpscaleMode>(
                value: _ImageUpscaleMode.canvas,
                labelZh: '补像素扩展',
                labelEn: 'Canvas expand',
              ),
            ],
            onChanged: (value) => setState(() => _mode = value),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_upscale_algorithm_field'),
          child: _LifeSegmentedField<_ImageUpscaleAlgorithm>(
            label: _lifeText(context, zh: '插值算法', en: 'Interpolation'),
            value: _algorithm,
            options: const <_LifeOption<_ImageUpscaleAlgorithm>>[
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.duplicate,
                labelZh: 'Fast duplicate',
                labelEn: 'Fast duplicate',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.nearest,
                labelZh: 'Nearest',
                labelEn: 'Nearest',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.linear,
                labelZh: 'Linear',
                labelEn: 'Linear',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.cubic,
                labelZh: 'Cubic',
                labelEn: 'Cubic',
              ),
              const _LifeOption<_ImageUpscaleAlgorithm>(
                value: _ImageUpscaleAlgorithm.average,
                labelZh: 'Average',
                labelEn: 'Average',
              ),
            ],
            onChanged: (value) => setState(() => _algorithm = value),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('life_image_upscale_format_field'),
          child: _LifeSegmentedField<_ImageUpscaleFormat>(
            label: _lifeText(context, zh: '导出格式', en: 'Export format'),
            value: _format,
            options: const <_LifeOption<_ImageUpscaleFormat>>[
              const _LifeOption<_ImageUpscaleFormat>(
                value: _ImageUpscaleFormat.png,
                labelZh: 'PNG 无损',
                labelEn: 'PNG lossless',
              ),
              const _LifeOption<_ImageUpscaleFormat>(
                value: _ImageUpscaleFormat.jpg,
                labelZh: 'JPEG 较小',
                labelEn: 'JPEG smaller',
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
                label: _lifeText(context, zh: '放大倍率', en: 'Scale factor'),
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
                  labelText: _lifeText(
                    context,
                    zh: '自定义倍率',
                    en: 'Custom scale',
                  ),
                  hintText: _lifeText(
                    context,
                    zh: '例如 2 / 3.5 / 12',
                    en: 'For example 2 / 3.5 / 12',
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
            label: _lifeText(context, zh: '目标宽度', en: 'Target width'),
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
            label: _lifeText(context, zh: '目标高度', en: 'Target height'),
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
              label: _lifeText(context, zh: '补像素策略', en: 'Canvas fill'),
              value: _canvasMode,
              options: const <_LifeOption<_ImageUpscaleCanvasMode>>[
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.edge,
                  labelZh: '边缘拉伸',
                  labelEn: 'Edge extend',
                ),
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.mirror,
                  labelZh: '镜像补边',
                  labelEn: 'Mirror fill',
                ),
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.solid,
                  labelZh: '纯色填充',
                  labelEn: 'Solid color',
                ),
                const _LifeOption<_ImageUpscaleCanvasMode>(
                  value: _ImageUpscaleCanvasMode.transparent,
                  labelZh: '透明留白',
                  labelEn: 'Transparent',
                ),
              ],
              onChanged: (value) => setState(() => _canvasMode = value),
            ),
          ),
          if (_canvasMode == _ImageUpscaleCanvasMode.solid) ...<Widget>[
            const SizedBox(height: 12),
            _LifeColorField(
              label: _lifeText(context, zh: '扩展背景色', en: 'Canvas color'),
              value: _canvasColor,
              options: const <_LifeColorOption>[
                _LifeColorOption(
                  color: Color(0xFFF4F0E8),
                  labelZh: '米白',
                  labelEn: 'Warm ivory',
                ),
                _LifeColorOption(
                  color: Color(0xFF111827),
                  labelZh: '深墨',
                  labelEn: 'Ink dark',
                ),
                _LifeColorOption(
                  color: Color(0xFF2563EB),
                  labelZh: '蓝底',
                  labelEn: 'Blue',
                ),
                _LifeColorOption(
                  color: Color(0xFF16A34A),
                  labelZh: '绿底',
                  labelEn: 'Green',
                ),
                _LifeColorOption(
                  color: Color(0xFFF97316),
                  labelZh: '橙底',
                  labelEn: 'Orange',
                ),
              ],
              onChanged: (value) => setState(() => _canvasColor = value),
            ),
          ],
        ],
        if (_usesJpegQuality) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: 'JPEG 质量', en: 'JPEG quality'),
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
          _lifeText(
            context,
            zh: '说明：当前为本地插值放大与画布扩展，不是生成式 AI 超分辨率，无法凭空恢复真实细节。',
            en: 'Note: this is local interpolation and canvas expansion, not generative AI super-resolution, so it cannot recreate true missing details.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          _lifeText(
            context,
            zh: '预期输出: ${_expectedWidth()}x${_expectedHeight()}',
            en: 'Expected output: ${_expectedWidth()}x${_expectedHeight()}',
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
                  ? _lifeText(context, zh: '处理中...', en: 'Processing...')
                  : _lifeText(context, zh: '开始扩大', en: 'Upscale'),
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
        title: _lifeText(context, zh: '结果信息', en: 'Result metrics'),
        subtitle: _lifeText(
          context,
          zh: '选图并执行扩大后显示输出尺寸、体积和算法信息。',
          en: 'Pick an image and run upscale to inspect size, bytes, and algorithm info.',
        ),
        children: const <Widget>[],
      );
    }

    final sizeRatio = _hasResult && _sourceSize > 0
        ? (_resultSize / _sourceSize).toStringAsFixed(2)
        : '--';
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '结果信息', en: 'Result metrics'),
      subtitle: _lifeText(
        context,
        zh: '查看放大后的像素、体积和当前处理方式。',
        en: 'Review output pixels, file size, and active processing path.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '原图尺寸', en: 'Source pixels'),
              value: '${_sourceWidth}x$_sourceHeight',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '输出尺寸', en: 'Output pixels'),
              value: _hasResult ? '${_resultWidth}x$_resultHeight' : '--',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '原图体积', en: 'Source size'),
              value: _formatBytes(_sourceSize),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '结果体积', en: 'Output size'),
              value: _hasResult ? _formatBytes(_resultSize) : '--',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '体积倍率', en: 'Byte ratio'),
              value: _hasResult ? '${sizeRatio}x' : '--',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '处理详情', en: 'Processing detail'),
              value: _hasResult ? (_resultDetail ?? '--') : '--',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '预览对比', en: 'Preview'),
      subtitle: _lifeText(
        context,
        zh: '左侧原图，右侧扩大结果。窄屏下自动改为上下排列。',
        en: 'Source on the left and upscale result on the right. On narrow screens this stacks vertically.',
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
                    titleZh: '扩大后',
                    titleEn: 'Upscaled',
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
                    titleZh: '扩大后',
                    titleEn: 'Upscaled',
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
        _error = _lifeText(
          context,
          zh: '选择图片失败: $error',
          en: 'Failed to pick image: $error',
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
        _error = _lifeText(
          context,
          zh: '扩大失败: $error',
          en: 'Upscale failed: $error',
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
          dialogTitle: _lifeText(
            context,
            zh: '保存扩大结果',
            en: 'Save upscaled image',
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
        return _lifeText(context, zh: '按倍率放大', en: 'By scale');
      case _ImageUpscaleMode.size:
        return _lifeText(context, zh: '指定宽高', en: 'Target size');
      case _ImageUpscaleMode.canvas:
        return _lifeText(context, zh: '补像素扩展', en: 'Canvas expand');
    }
  }

  String _algorithmLabel(
    _ImageUpscaleAlgorithm algorithm,
    BuildContext context,
  ) {
    switch (algorithm) {
      case _ImageUpscaleAlgorithm.duplicate:
        return _lifeText(context, zh: 'Fast duplicate', en: 'Fast duplicate');
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
        return _lifeText(context, zh: 'PNG 无损', en: 'PNG lossless');
      case _ImageUpscaleFormat.jpg:
        return _lifeText(context, zh: 'JPEG 较小', en: 'JPEG smaller');
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

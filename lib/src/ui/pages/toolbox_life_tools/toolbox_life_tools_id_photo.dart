part of '../toolbox_life_tools.dart';

const List<_LifeColorOption> _idPhotoBackgroundOptions = <_LifeColorOption>[
  _LifeColorOption(color: Colors.white, labelZh: '白底', labelEn: 'White'),
  _LifeColorOption(
    color: Color(0xFFE8F3FF),
    labelZh: '浅蓝',
    labelEn: 'Light blue',
  ),
  _LifeColorOption(color: Color(0xFF438BFF), labelZh: '蓝底', labelEn: 'Blue'),
  _LifeColorOption(color: Color(0xFFD94444), labelZh: '红底', labelEn: 'Red'),
  _LifeColorOption(
    color: Color(0xFFF2F2F2),
    labelZh: '浅灰',
    labelEn: 'Light gray',
  ),
];

class _IdPhotoToolPage extends StatefulWidget {
  const _IdPhotoToolPage();

  @override
  State<_IdPhotoToolPage> createState() => _IdPhotoToolPageState();
}

class _IdPhotoToolPageState extends State<_IdPhotoToolPage> {
  static const ToolboxIdPhotoService _service = ToolboxIdPhotoService();

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
      title: _lifeText(context, zh: '证件照生成', en: 'ID photo'),
      subtitle: _lifeText(
        context,
        zh: '离线裁切照片、替换纯色背景，并按常见证件照规格导出。',
        en: 'Offline crop, plain background replacement, and common ID photo export.',
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
      title: _lifeText(context, zh: '照片舞台', en: 'Photo stage'),
      subtitle: _lifeText(
        context,
        zh: '先选择头像照片，再按用途调整规格、裁切位置和底色。',
        en: 'Pick a portrait first, then adjust preset, crop position, and background.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '当前规格', en: 'Preset'),
              value: _presetLabel(_preset, context),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '输出像素', en: 'Pixels'),
              value: _preset.pixelPair(_dpi),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '底色', en: 'Background'),
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
                label: Text(_lifeText(context, zh: '选择照片', en: 'Pick photo')),
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
                    zh: '尚未选择照片。',
                    en: 'No photo selected yet.',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sourceName ??
                          _lifeText(context, zh: '未命名照片', en: 'Unnamed photo'),
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
      title: _lifeText(context, zh: '生成参数', en: 'Generation settings'),
      subtitle: _lifeText(
        context,
        zh: '尺寸按毫米和 DPI 换算，背景替换适合纯色或接近纯色背景的照片。',
        en: 'Size is calculated from millimeters and DPI. Background replacement works best on plain backdrops.',
      ),
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('life_id_photo_preset_field'),
          child: _LifeSegmentedField<ToolboxIdPhotoPreset>(
            label: _lifeText(context, zh: '证件照规格', en: 'Photo preset'),
            value: _preset,
            options: toolboxIdPhotoPresets
                .map(
                  (preset) => _LifeOption<ToolboxIdPhotoPreset>(
                    value: preset,
                    labelZh: preset.labelZh,
                    labelEn: preset.labelEn,
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
          label: _lifeText(context, zh: 'DPI', en: 'DPI'),
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
          label: _lifeText(context, zh: '证件照底色', en: 'Background color'),
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
            label: _lifeText(context, zh: '导出格式', en: 'Export format'),
            value: _format,
            options: const <_LifeOption<ToolboxIdPhotoOutputFormat>>[
              _LifeOption<ToolboxIdPhotoOutputFormat>(
                value: ToolboxIdPhotoOutputFormat.png,
                labelZh: 'PNG 清晰',
                labelEn: 'PNG clear',
              ),
              _LifeOption<ToolboxIdPhotoOutputFormat>(
                value: ToolboxIdPhotoOutputFormat.jpg,
                labelZh: 'JPEG 较小',
                labelEn: 'JPEG smaller',
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
            label: _lifeText(context, zh: 'JPEG 质量', en: 'JPEG quality'),
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
            _lifeText(context, zh: '简易换底色', en: 'Plain background replace'),
          ),
          subtitle: Text(
            _lifeText(
              context,
              zh: '按照片四角取样替换相近背景，不会上传照片。',
              en: 'Samples the four corners and replaces similar backdrop pixels without uploading.',
            ),
          ),
        ),
        if (_replaceBackground) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: '背景容差', en: 'Background tolerance'),
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
            label: _lifeText(context, zh: '替换强度', en: 'Replace strength'),
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
          label: _lifeText(context, zh: '裁切缩放', en: 'Crop zoom'),
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
          label: _lifeText(context, zh: '左右位置', en: 'Horizontal position'),
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
          label: _lifeText(context, zh: '上下位置', en: 'Vertical position'),
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
                  ? _lifeText(context, zh: '生成中...', en: 'Generating...')
                  : _lifeText(context, zh: '生成证件照', en: 'Generate'),
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
                  ? _lifeText(context, zh: '保存中...', en: 'Saving...')
                  : _lifeText(context, zh: '导出结果', en: 'Export'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPanel(BuildContext context) {
    final result = _result;
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '结果信息', en: 'Result metrics'),
      subtitle: _lifeText(
        context,
        zh: '生成后检查输出像素、裁切区域和换底色影响范围。',
        en: 'After generation, review pixels, crop box, and replaced backdrop coverage.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '目标像素', en: 'Target pixels'),
              value: _preset.pixelPair(_dpi),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '结果体积', en: 'Output size'),
              value: _resultBytes == null
                  ? '--'
                  : _formatBytes(_resultBytes!.length),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '裁切区域', en: 'Crop box'),
              value: result == null
                  ? '--'
                  : '${result.cropWidth}x${result.cropHeight}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '换底像素', en: 'Replaced pixels'),
              value: result == null ? '--' : result.replacedPixels.toString(),
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
        zh: '左侧原图，右侧生成结果；窄屏下自动上下排列。',
        en: 'Source on the left, generated ID photo on the right. Narrow screens stack vertically.',
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
                    titleZh: '证件照',
                    titleEn: 'ID photo',
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
                    titleZh: '原图',
                    titleEn: 'Source',
                    image: _sourcePreview,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _previewTile(
                    context: context,
                    titleZh: '证件照',
                    titleEn: 'ID photo',
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
    required String titleZh,
    required String titleEn,
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
            _lifeText(context, zh: titleZh, en: titleEn),
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
                        _lifeText(context, zh: '暂无预览', en: 'No preview'),
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
      title: _lifeText(context, zh: '使用边界', en: 'Usage limits'),
      subtitle: _lifeText(
        context,
        zh: '本工具在本地处理图片，适合日常报名、资料整理和尺寸核对。',
        en: 'This tool processes images locally for everyday forms, profile prep, and size checks.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '简易换底色依赖照片四角取样，复杂背景、头发边缘和阴影可能需要先在专业修图工具中抠图；证件照规格请以具体办事机构要求为准。',
            en: 'Plain background replacement samples the four corners, so complex scenes, hair edges, and shadows may need a dedicated editor first. Always follow the target authority requirements.',
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
        _lifeText(context, zh: '已保存: $_savedPath', en: 'Saved: $_savedPath'),
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
        _resultBytes = null;
        _resultPreview = null;
        _result = null;
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
          zh: '选择照片失败: $error',
          en: 'Failed to pick photo: $error',
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
      final result = _service.render(
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '生成失败: $error',
          en: 'Generation failed: $error',
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

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeText(context, zh: '保存证件照', en: 'Save ID photo'),
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
          path.join(appDir.path, 'life_tools', 'id_photo'),
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

  Future<ui.Image> _decodePreview(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _presetLabel(ToolboxIdPhotoPreset preset, BuildContext context) {
    return _lifeText(context, zh: preset.labelZh, en: preset.labelEn);
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

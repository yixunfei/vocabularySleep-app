part of '../toolbox_life_tools.dart';

class _MemeMakerToolPage extends StatefulWidget {
  const _MemeMakerToolPage();

  @override
  State<_MemeMakerToolPage> createState() => _MemeMakerToolPageState();
}

class _MemeMakerToolPageState extends State<_MemeMakerToolPage> {
  final TextEditingController _topController = TextEditingController();
  final TextEditingController _bottomController = TextEditingController();
  final TextEditingController _stickerController = TextEditingController(
    text: 'Sticker',
  );

  ui.Image? _sourceImage;
  String? _sourceName;
  late List<ToolboxMemeTextLayer> _layers;
  String _selectedLayerId = 'top';
  double _stageZoom = 1;
  Offset _stageOffset = Offset.zero;
  bool _exporting = false;
  String? _savedPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _layers = ToolboxMemeService.buildDefaultLayers();
    _topController.addListener(() => _setLayerText('top', _topController.text));
    _bottomController.addListener(
      () => _setLayerText('bottom', _bottomController.text),
    );
    _stickerController.addListener(
      () => _setLayerText('sticker', _stickerController.text),
    );
  }

  @override
  void dispose() {
    _sourceImage?.dispose();
    _topController.dispose();
    _bottomController.dispose();
    _stickerController.dispose();
    super.dispose();
  }

  ToolboxMemeTextLayer get _selectedLayer =>
      _layers.firstWhere((layer) => layer.id == _selectedLayerId);

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

      final old = _sourceImage;
      setState(() {
        _sourceImage = preview;
        _sourceName = file.name;
        _stageZoom = 1;
        _stageOffset = Offset.zero;
        _savedPath = null;
        _error = null;
      });
      old?.dispose();
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

  Future<ui.Image> _decodePreview(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  ToolboxMemeRenderRequest? _buildRequest() {
    final image = _sourceImage;
    if (image == null) {
      return null;
    }
    return ToolboxMemeRenderRequest(sourceImage: image, layers: _layers);
  }

  Future<void> _exportMeme() async {
    final request = _buildRequest();
    if (request == null) {
      return;
    }
    setState(() {
      _exporting = true;
      _savedPath = null;
      _error = null;
    });
    try {
      final saveDialogTitle = _lifeText(
        context,
        zh: '保存表情包',
        en: 'Save meme image',
      );
      final browserDownloadText = _lifeText(
        context,
        zh: '浏览器下载已触发，请查看下载列表。',
        en: 'Browser download started. Check your downloads.',
      );
      final bytes = await ToolboxMemeService.renderPng(request);
      final sourceName = _sourceName ?? 'meme';
      final baseName = path.basenameWithoutExtension(sourceName);
      final fileName = '${baseName}_meme.png';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: saveDialogTitle,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const <String>['png'],
          bytes: bytes,
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
            _savedPath = browserDownloadText;
          });
          return;
        }

        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'meme_maker'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallback = File(
          path.join(exportDir.path, '${baseName}_$timestamp.png'),
        );
        await fallback.writeAsBytes(bytes, flush: true);
        if (!mounted) {
          return;
        }
        setState(() => _savedPath = fallback.path);
        return;
      }

      setState(() => _savedPath = savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '导出失败: $error',
          en: 'Export failed: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _setLayerText(String id, String text) {
    final index = _layers.indexWhere((layer) => layer.id == id);
    if (index < 0 || _layers[index].text == text) {
      return;
    }
    setState(() {
      _layers = _layers
          .map((layer) => layer.id == id ? layer.copyWith(text: text) : layer)
          .toList(growable: false);
    });
  }

  void _updateSelectedLayer(ToolboxMemeTextLayer nextLayer) {
    setState(() {
      _layers = _layers
          .map((layer) => layer.id == nextLayer.id ? nextLayer : layer)
          .toList(growable: false);
    });
  }

  void _moveLayerOrder(int delta) {
    final sorted = <ToolboxMemeTextLayer>[..._layers]
      ..sort((left, right) => left.zIndex.compareTo(right.zIndex));
    final currentIndex = sorted.indexWhere(
      (layer) => layer.id == _selectedLayerId,
    );
    final nextIndex = (currentIndex + delta).clamp(0, sorted.length - 1);
    if (currentIndex < 0 || nextIndex == currentIndex) {
      return;
    }
    final moved = sorted.removeAt(currentIndex);
    sorted.insert(nextIndex, moved);
    setState(() {
      _layers = sorted
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(zIndex: entry.key))
          .toList(growable: false);
    });
  }

  String _layerLabel(String id) {
    return switch (id) {
      'top' => _lifeText(context, zh: '顶部文案', en: 'Top caption'),
      'bottom' => _lifeText(context, zh: '底部文案', en: 'Bottom caption'),
      'sticker' => _lifeText(context, zh: '贴纸文案', en: 'Sticker'),
      _ => id,
    };
  }

  String _fontFamilyLabel(ToolboxMemeFontFamily family) {
    return switch (family) {
      ToolboxMemeFontFamily.sans => _lifeText(context, zh: '无衬线', en: 'Sans'),
      ToolboxMemeFontFamily.serif => _lifeText(context, zh: '衬线', en: 'Serif'),
      ToolboxMemeFontFamily.monospace => _lifeText(
        context,
        zh: '等宽',
        en: 'Mono',
      ),
    };
  }

  String _bubbleStyleLabel(ToolboxMemeBubbleStyle style) {
    return switch (style) {
      ToolboxMemeBubbleStyle.classic => _lifeText(
        context,
        zh: '经典描边',
        en: 'Classic outline',
      ),
      ToolboxMemeBubbleStyle.panel => _lifeText(
        context,
        zh: '字幕卡片',
        en: 'Panel caption',
      ),
      ToolboxMemeBubbleStyle.sticker => _lifeText(
        context,
        zh: '贴纸气泡',
        en: 'Sticker bubble',
      ),
    };
  }

  String _alignLabel(ToolboxMemeTextAlignMode align) {
    return switch (align) {
      ToolboxMemeTextAlignMode.left => _lifeText(
        context,
        zh: '左对齐',
        en: 'Left',
      ),
      ToolboxMemeTextAlignMode.center => _lifeText(
        context,
        zh: '居中',
        en: 'Center',
      ),
      ToolboxMemeTextAlignMode.right => _lifeText(
        context,
        zh: '右对齐',
        en: 'Right',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final image = _sourceImage;
    final aspectRatio = image == null ? 1.0 : image.width / image.height;
    final request = _buildRequest();
    final selected = _selectedLayer;

    return ToolboxToolPage(
      title: _lifeText(context, zh: '表情包制作', en: 'Meme maker'),
      subtitle: _lifeText(
        context,
        zh: '导入本地图片，在预览区直接拖动和缩放文字图层，再按同一套参数导出真实 PNG。',
        en: 'Import a local image, drag and scale text layers directly in preview, then export a real PNG driven by the same layer model.',
      ),
      child: Column(
        key: const ValueKey<String>('life-meme-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '素材与导出', en: 'Source and export'),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    key: const ValueKey<String>('life-meme-pick-button'),
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_search_rounded),
                    label: Text(
                      _lifeText(context, zh: '导入图片', en: 'Pick image'),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey<String>('life-meme-export-button'),
                    onPressed: request == null || _exporting
                        ? null
                        : _exportMeme,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      _exporting
                          ? _lifeText(context, zh: '导出中...', en: 'Exporting...')
                          : _lifeText(context, zh: '导出 PNG', en: 'Export PNG'),
                    ),
                  ),
                ],
              ),
              if (_sourceName != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _lifeText(context, zh: '当前素材: ', en: 'Current image: ') +
                      _sourceName!,
                ),
              ],
              if (_savedPath != null) ...<Widget>[
                const SizedBox(height: 8),
                SelectableText(
                  _lifeText(context, zh: '导出位置: ', en: 'Saved to: ') +
                      _savedPath!,
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '画面预览', en: 'Preview'),
            subtitle: _lifeText(
              context,
              zh: '点选图层后可直接拖动位置、双指缩放，蓝色边框表示当前正在编辑的图层。',
              en: 'Tap a layer to edit it, drag to move, and pinch to scale. The blue frame marks the active layer.',
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _LifeSliderField(
                      label: _lifeText(context, zh: '预览缩放', en: 'Preview zoom'),
                      valueText: '${(_stageZoom * 100).round()}%',
                      value: _stageZoom,
                      min: 1,
                      max: 3,
                      onChanged: (value) {
                        setState(() => _stageZoom = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() {
                        _stageZoom = 1;
                        _stageOffset = Offset.zero;
                      });
                    },
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: Text(
                      _lifeText(context, zh: '重置视图', en: 'Reset view'),
                    ),
                  ),
                ],
              ),
              _LifePreviewFrame(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: image == null
                      ? Center(
                          child: Text(
                            _lifeText(
                              context,
                              zh: '先导入一张本地图片再开始做表情包。',
                              en: 'Pick a local image to start making a meme.',
                            ),
                            key: const ValueKey<String>('life-meme-empty'),
                          ),
                        )
                      : _MemePreviewStage(
                          key: const ValueKey<String>('life-meme-preview'),
                          image: image,
                          layers: _layers,
                          selectedLayerId: _selectedLayerId,
                          stageZoom: _stageZoom,
                          stageOffset: _stageOffset,
                          onSelectLayer: (id) {
                            setState(() => _selectedLayerId = id);
                          },
                          onTransformLayer: (id, centerX, centerY, scale) {
                            final target = _layers.firstWhere(
                              (layer) => layer.id == id,
                            );
                            _updateSelectedLayer(
                              target.copyWith(
                                centerX: centerX,
                                centerY: centerY,
                                scale: scale,
                              ),
                            );
                          },
                          onViewportChanged: (zoom, offset) {
                            setState(() {
                              _stageZoom = zoom;
                              _stageOffset = offset;
                            });
                          },
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '文案输入', en: 'Layer text'),
            subtitle: _lifeText(
              context,
              zh: '顶部、底部和贴纸文案分别对应三个独立图层，后续样式和层级会作用到当前选中的图层。',
              en: 'Top, bottom, and sticker captions map to three independent layers. Style and order controls apply to the currently selected layer.',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-meme-top-text'),
                controller: _topController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(context, zh: '顶部文案', en: 'Top caption'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-meme-bottom-text'),
                controller: _bottomController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(
                    context,
                    zh: '底部文案',
                    en: 'Bottom caption',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-meme-sticker-text'),
                controller: _stickerController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(context, zh: '贴纸文案', en: 'Sticker text'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '图层样式', en: 'Layer style'),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _layers
                    .map((layer) {
                      return ChoiceChip(
                        selected: layer.id == _selectedLayerId,
                        label: Text(_layerLabel(layer.id)),
                        onSelected: (_) =>
                            setState(() => _selectedLayerId = layer.id),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => _moveLayerOrder(-1),
                    icon: const Icon(Icons.vertical_align_top_rounded),
                    label: Text(
                      _lifeText(context, zh: '上移层级', en: 'Bring forward'),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _moveLayerOrder(1),
                    icon: const Icon(Icons.vertical_align_bottom_rounded),
                    label: Text(
                      _lifeText(context, zh: '下移层级', en: 'Send backward'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxMemeBubbleStyle>(
                label: _lifeText(context, zh: '图层风格', en: 'Bubble style'),
                value: selected.bubbleStyle,
                options: ToolboxMemeBubbleStyle.values
                    .map(
                      (style) => _LifeOption<ToolboxMemeBubbleStyle>(
                        value: style,
                        labelZh: switch (style) {
                          ToolboxMemeBubbleStyle.classic => '经典描边',
                          ToolboxMemeBubbleStyle.panel => '字幕卡片',
                          ToolboxMemeBubbleStyle.sticker => '贴纸气泡',
                        },
                        labelEn: _bubbleStyleLabel(style),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(bubbleStyle: value));
                },
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxMemeFontFamily>(
                label: _lifeText(context, zh: '字体家族', en: 'Font family'),
                value: selected.fontFamily,
                options: ToolboxMemeFontFamily.values
                    .map(
                      (family) => _LifeOption<ToolboxMemeFontFamily>(
                        value: family,
                        labelZh: switch (family) {
                          ToolboxMemeFontFamily.sans => '无衬线',
                          ToolboxMemeFontFamily.serif => '衬线',
                          ToolboxMemeFontFamily.monospace => '等宽',
                        },
                        labelEn: _fontFamilyLabel(family),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(fontFamily: value));
                },
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxMemeTextAlignMode>(
                label: _lifeText(context, zh: '对齐方式', en: 'Text align'),
                value: selected.align,
                options: ToolboxMemeTextAlignMode.values
                    .map(
                      (align) => _LifeOption<ToolboxMemeTextAlignMode>(
                        value: align,
                        labelZh: switch (align) {
                          ToolboxMemeTextAlignMode.left => '左对齐',
                          ToolboxMemeTextAlignMode.center => '居中',
                          ToolboxMemeTextAlignMode.right => '右对齐',
                        },
                        labelEn: _alignLabel(align),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(align: value));
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.bold,
                title: Text(_lifeText(context, zh: '粗体', en: 'Bold')),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(bold: value));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.italic,
                title: Text(_lifeText(context, zh: '斜体', en: 'Italic')),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(italic: value));
                },
              ),
              const SizedBox(height: 4),
              _LifeSliderField(
                label: _lifeText(context, zh: '基础字号', en: 'Base text size'),
                valueText: selected.fontScale.toStringAsFixed(2),
                value: selected.fontScale,
                min: 0.05,
                max: 0.16,
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(fontScale: value));
                },
              ),
              _LifeSliderField(
                label: _lifeText(context, zh: '图层缩放', en: 'Layer scale'),
                valueText: selected.scale.toStringAsFixed(2),
                value: selected.scale,
                min: 0.45,
                max: 2.2,
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(scale: value));
                },
              ),
              _LifeSliderField(
                label: _lifeText(context, zh: '文字边距', en: 'Text padding'),
                valueText: selected.paddingScale.toStringAsFixed(2),
                value: selected.paddingScale,
                min: 0.02,
                max: 0.12,
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(paddingScale: value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemePreviewStage extends StatefulWidget {
  const _MemePreviewStage({
    super.key,
    required this.image,
    required this.layers,
    required this.selectedLayerId,
    required this.stageZoom,
    required this.stageOffset,
    required this.onSelectLayer,
    required this.onTransformLayer,
    required this.onViewportChanged,
  });

  final ui.Image image;
  final List<ToolboxMemeTextLayer> layers;
  final String selectedLayerId;
  final double stageZoom;
  final Offset stageOffset;
  final ValueChanged<String> onSelectLayer;
  final void Function(String id, double centerX, double centerY, double scale)
  onTransformLayer;
  final void Function(double zoom, Offset offset) onViewportChanged;

  @override
  State<_MemePreviewStage> createState() => _MemePreviewStageState();
}

class _MemePreviewStageState extends State<_MemePreviewStage> {
  String? _activeLayerId;
  Offset? _gestureStartLocalPoint;
  Offset _startStageOffset = Offset.zero;
  double _startStageZoom = 1;
  double _startCenterX = 0.5;
  double _startCenterY = 0.5;
  double _startScale = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageSize = Size(constraints.maxWidth, constraints.maxHeight);
        final request = ToolboxMemeRenderRequest(
          sourceImage: widget.image,
          layers: widget.layers,
        );
        final resolvedLayers = ToolboxMemeService.resolveLayers(
          widget.layers,
          stageSize,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final layer = _hitTestLayer(
              _toCanvasPoint(details.localPosition, stageSize),
              resolvedLayers,
            );
            if (layer != null) {
              widget.onSelectLayer(layer.id);
            }
          },
          onScaleStart: (details) {
            _gestureStartLocalPoint = details.localFocalPoint;
            _startStageOffset = widget.stageOffset;
            _startStageZoom = widget.stageZoom;
            final hit = _hitTestLayer(
              _toCanvasPoint(details.localFocalPoint, stageSize),
              resolvedLayers,
            );
            _activeLayerId = hit?.id;
            if (hit != null) {
              _startCenterX = hit.centerX;
              _startCenterY = hit.centerY;
              _startScale = hit.scale;
              widget.onSelectLayer(hit.id);
            }
          },
          onScaleUpdate: (details) {
            final startPoint = _gestureStartLocalPoint;
            if (startPoint == null) {
              return;
            }
            if (_activeLayerId != null) {
              final activeLayer = widget.layers.firstWhere(
                (layer) => layer.id == _activeLayerId,
              );
              final startCanvasPoint = _toCanvasPoint(startPoint, stageSize);
              final currentCanvasPoint = _toCanvasPoint(
                details.localFocalPoint,
                stageSize,
              );
              final delta = currentCanvasPoint - startCanvasPoint;
              final nextCenterX =
                  (_startCenterX + delta.dx / stageSize.width)
                      .clamp(0.08, 0.92)
                      .toDouble();
              final nextCenterY =
                  (_startCenterY + delta.dy / stageSize.height)
                      .clamp(0.08, 0.92)
                      .toDouble();
              final nextScale = (_startScale * details.scale)
                  .clamp(0.45, 2.2)
                  .toDouble();
              widget.onTransformLayer(
                activeLayer.id,
                nextCenterX,
                nextCenterY,
                nextScale,
              );
              return;
            }

            final nextZoom = (_startStageZoom * details.scale)
                .clamp(1.0, 3.0)
                .toDouble();
            final nextOffset =
                _clampViewportOffset(
                  _startStageOffset +
                      (details.localFocalPoint - startPoint),
                  stageSize,
                  nextZoom,
                );
            widget.onViewportChanged(nextZoom, nextOffset);
          },
          onScaleEnd: (_) {
            _activeLayerId = null;
            _gestureStartLocalPoint = null;
          },
          child: ClipRect(
            child: Transform(
              alignment: Alignment.center,
              transform: _buildViewportTransform(stageSize),
              child: CustomPaint(
                size: stageSize,
                painter: _MemePreviewPainter(
                  request: request,
                  selectedLayerId: widget.selectedLayerId,
                  selectionColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ToolboxMemeTextLayer? _hitTestLayer(
    Offset canvasPoint,
    List<ToolboxMemeResolvedLayer> resolvedLayers,
  ) {
    for (final resolved in resolvedLayers.reversed) {
      if (resolved.bounds.inflate(10).contains(canvasPoint)) {
        return resolved.layer;
      }
    }
    return null;
  }

  Matrix4 _buildViewportTransform(Size stageSize) {
    return Matrix4.identity()
      ..translateByDouble(widget.stageOffset.dx, widget.stageOffset.dy, 0, 1)
      ..translateByDouble(stageSize.width / 2, stageSize.height / 2, 0, 1)
      ..scaleByDouble(widget.stageZoom, widget.stageZoom, 1, 1)
      ..translateByDouble(-stageSize.width / 2, -stageSize.height / 2, 0, 1);
  }

  Offset _toCanvasPoint(Offset localPoint, Size stageSize) {
    final inverse = Matrix4.inverted(_buildViewportTransform(stageSize));
    final transformed = MatrixUtils.transformPoint(inverse, localPoint);
    return Offset(
      transformed.dx.clamp(0.0, stageSize.width).toDouble(),
      transformed.dy.clamp(0.0, stageSize.height).toDouble(),
    );
  }

  Offset _clampViewportOffset(Offset candidate, Size stageSize, double zoom) {
    final maxDx = stageSize.width * (zoom - 1) / 2;
    final maxDy = stageSize.height * (zoom - 1) / 2;
    return Offset(
      candidate.dx.clamp(-maxDx, maxDx).toDouble(),
      candidate.dy.clamp(-maxDy, maxDy).toDouble(),
    );
  }
}

class _MemePreviewPainter extends CustomPainter {
  const _MemePreviewPainter({
    required this.request,
    required this.selectedLayerId,
    required this.selectionColor,
  });

  final ToolboxMemeRenderRequest request;
  final String selectedLayerId;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    ToolboxMemeService.paint(
      canvas,
      request,
      canvasSize: size,
      selectedLayerId: selectedLayerId,
      selectionColor: selectionColor,
      drawSelection: true,
    );
  }

  @override
  bool shouldRepaint(covariant _MemePreviewPainter oldDelegate) {
    return oldDelegate.request.sourceImage != request.sourceImage ||
        oldDelegate.selectedLayerId != selectedLayerId ||
        oldDelegate.selectionColor != selectionColor ||
        !listEquals(oldDelegate.request.layers, request.layers);
  }
}

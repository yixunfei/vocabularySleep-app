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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.failed_to_pick_image.6e0bad236d',
          params: <String, Object?>{'error': error},
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
      final saveDialogTitle = _lifeI18nText(
        context,
        'inline.plan295.life.save_meme_image.9a273f3ddb7e',
      );
      final browserDownloadText = _lifeI18nText(
        context,
        'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
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
        _error = _lifeI18nText(
          context,
          'errorExportFailed',
          params: <String, Object?>{'error': error},
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
      'top' => _lifeI18nText(
        context,
        'inline.plan295.life.top_caption.9d1a5a7d70eb',
      ),
      'bottom' => _lifeI18nText(
        context,
        'inline.plan295.life.bottom_caption.6456c37bf6a7',
      ),
      'sticker' => _lifeI18nText(
        context,
        'inline.plan295.life.sticker.8768a9a94403',
      ),
      _ => id,
    };
  }

  String _fontFamilyLabel(ToolboxMemeFontFamily family) {
    return switch (family) {
      ToolboxMemeFontFamily.sans => _lifeI18nText(
        context,
        'inline.plan295.life.sans.95a53d0ea1a0',
      ),
      ToolboxMemeFontFamily.serif => _lifeI18nText(
        context,
        'inline.plan295.life.serif.5664f9e7718a',
      ),
      ToolboxMemeFontFamily.monospace => _lifeI18nText(
        context,
        'inline.plan295.life.mono.6193ef478e21',
      ),
    };
  }

  String _bubbleStyleLabel(ToolboxMemeBubbleStyle style) {
    return switch (style) {
      ToolboxMemeBubbleStyle.classic => _lifeI18nText(
        context,
        'inline.plan295.life.classic_outline.f47319870fd0',
      ),
      ToolboxMemeBubbleStyle.panel => _lifeI18nText(
        context,
        'inline.plan295.life.panel_caption.f2a7e0627328',
      ),
      ToolboxMemeBubbleStyle.sticker => _lifeI18nText(
        context,
        'inline.plan295.life.sticker_bubble.c5d36ea5534c',
      ),
    };
  }

  String _alignLabel(ToolboxMemeTextAlignMode align) {
    return switch (align) {
      ToolboxMemeTextAlignMode.left => _lifeI18nText(
        context,
        'inline.plan295.life.left.ff9407b2b65a',
      ),
      ToolboxMemeTextAlignMode.center => _lifeI18nText(
        context,
        'inline.plan295.life.center.78ebf5f3d988',
      ),
      ToolboxMemeTextAlignMode.right => _lifeI18nText(
        context,
        'inline.plan295.life.right.280d5954b34e',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.meme_maker.b757bab40693',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.import_a_local_image_drag_and_scale.f0d2529aec26',
      ),
      child: Column(
        key: const ValueKey<String>('life-meme-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.source_and_export.19dc44788194',
            ),
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.pick_image.21467c886080',
                      ),
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
                          ? _lifeI18nText(
                              context,
                              'inline.plan295.life.exporting.4a7bae70c078',
                            )
                          : _lifeI18nText(
                              context,
                              'inline.plan295.life.export_png.ed4ae20882a0',
                            ),
                    ),
                  ),
                ],
              ),
              if (_sourceName != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _lifeI18nText(
                        context,
                        'inline.plan295.life.current_image.a93514ea0751',
                      ) +
                      _sourceName!,
                ),
              ],
              if (_savedPath != null) ...<Widget>[
                const SizedBox(height: 8),
                SelectableText(
                  _lifeI18nText(
                        context,
                        'inline.plan295.life.saved_to.6546039c21f2',
                      ) +
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
            title: _lifeI18nText(
              context,
              'inline.plan295.life.preview.1cee2fa795cb',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.tap_a_layer_to_edit_it_drag_to_move.b4bbae8649d8',
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _LifeSliderField(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.preview_zoom.9a8a7c278d2d',
                      ),
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.reset_view.4eac02008da8',
                      ),
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
                            _lifeI18nText(
                              context,
                              'inline.plan295.life.pick_a_local_image_to_start_making_a.2a876f36abda',
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
            title: _lifeI18nText(
              context,
              'inline.plan295.life.layer_text.5882a9c00c4b',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.top_bottom_and_sticker_captions_map.3d376c103f6a',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-meme-top-text'),
                controller: _topController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.top_caption.9d1a5a7d70eb',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-meme-bottom-text'),
                controller: _bottomController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.bottom_caption.6456c37bf6a7',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-meme-sticker-text'),
                controller: _stickerController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.sticker_text.616ed3c4ac34',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.layer_style.474f1caa2da3',
            ),
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.bring_forward.44ed806ee4a5',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _moveLayerOrder(1),
                    icon: const Icon(Icons.vertical_align_bottom_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.send_backward.6a8f6647e20d',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxMemeBubbleStyle>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.bubble_style.502d09b36860',
                ),
                value: selected.bubbleStyle,
                options: ToolboxMemeBubbleStyle.values
                    .map(
                      (style) => _LifeOption<ToolboxMemeBubbleStyle>(
                        value: style,
                        labelText: _bubbleStyleLabel(style),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(bubbleStyle: value));
                },
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxMemeFontFamily>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.font_family.b093e5173612',
                ),
                value: selected.fontFamily,
                options: ToolboxMemeFontFamily.values
                    .map(
                      (family) => _LifeOption<ToolboxMemeFontFamily>(
                        value: family,
                        labelText: _fontFamilyLabel(family),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(fontFamily: value));
                },
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxMemeTextAlignMode>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.text_align.204141d7e7ae',
                ),
                value: selected.align,
                options: ToolboxMemeTextAlignMode.values
                    .map(
                      (align) => _LifeOption<ToolboxMemeTextAlignMode>(
                        value: align,
                        labelText: _alignLabel(align),
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
                title: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.bold.77e6053e8fa0',
                  ),
                ),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(bold: value));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.italic,
                title: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.italic.665a2ebe74b8',
                  ),
                ),
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(italic: value));
                },
              ),
              const SizedBox(height: 4),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.base_text_size.361d4f79046d',
                ),
                valueText: selected.fontScale.toStringAsFixed(2),
                value: selected.fontScale,
                min: 0.05,
                max: 0.16,
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(fontScale: value));
                },
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.layer_scale.1bda7016395d',
                ),
                valueText: selected.scale.toStringAsFixed(2),
                value: selected.scale,
                min: 0.45,
                max: 2.2,
                onChanged: (value) {
                  _updateSelectedLayer(selected.copyWith(scale: value));
                },
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.text_padding.a28b5c556eba',
                ),
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
              final nextCenterX = (_startCenterX + delta.dx / stageSize.width)
                  .clamp(0.08, 0.92)
                  .toDouble();
              final nextCenterY = (_startCenterY + delta.dy / stageSize.height)
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
            final nextOffset = _clampViewportOffset(
              _startStageOffset + (details.localFocalPoint - startPoint),
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

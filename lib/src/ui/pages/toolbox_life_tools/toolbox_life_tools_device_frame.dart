part of '../toolbox_life_tools.dart';

const int _deviceFrameMaxSourceBytes = 32 * 1024 * 1024;

class _DeviceFrameToolPage extends StatefulWidget {
  const _DeviceFrameToolPage();

  @override
  State<_DeviceFrameToolPage> createState() => _DeviceFrameToolPageState();
}

class _DeviceFrameToolPageState extends State<_DeviceFrameToolPage> {
  final GlobalKey _previewKey = GlobalKey();
  final TextEditingController _statusTimeController = TextEditingController(
    text: '9:41',
  );

  ui.Image? _sourceImage;
  String? _sourceName;
  _DeviceFramePreset _preset = _DeviceFramePreset.titanium;
  _DeviceFrameBackground _background = _DeviceFrameBackground.studio;
  _DeviceFrameStatusTone _statusTone = _DeviceFrameStatusTone.light;
  _DeviceFrameScreenFit _screenFit = _DeviceFrameScreenFit.cover;
  bool _showStatusBar = false;
  bool _showGlare = true;
  double _canvasPadding = 28;
  double _batteryPercent = 86;
  bool _showBatteryPercent = true;
  bool _charging = false;
  double _signalLevel = 4;
  bool _showWifi = true;
  double _wifiStrength = 3;
  _DeviceFrameNetworkType _networkType = _DeviceFrameNetworkType.fiveG;
  bool _exporting = false;
  String? _savedPath;
  String? _error;

  @override
  void dispose() {
    _statusTimeController.dispose();
    _sourceImage?.dispose();
    super.dispose();
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
      if (!mounted) {
        return;
      }
      if (file == null) {
        return;
      }
      final oversizedMessage = _lifeText(
        context,
        zh: '图片超过 32MB，请先压缩后再导入。',
        en: 'The image is larger than 32 MB. Compress it before importing.',
      );
      if (file.size > _deviceFrameMaxSourceBytes) {
        throw StateError(oversizedMessage);
      }

      final bytes = await _readPickedBytes(file, oversizedMessage);
      if (bytes == null || bytes.isEmpty) {
        return;
      }

      final image = await _decodePreview(bytes);
      if (!mounted) {
        image.dispose();
        return;
      }

      final oldImage = _sourceImage;
      setState(() {
        _sourceImage = image;
        _sourceName = file.name;
        _savedPath = null;
        _error = null;
      });
      oldImage?.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '选择截图失败: $error',
          en: 'Failed to pick screenshot: $error',
        );
      });
    }
  }

  Future<Uint8List?> _readPickedBytes(
    PlatformFile file,
    String oversizedMessage,
  ) async {
    final bytes = file.bytes;
    if (bytes != null) {
      return bytes;
    }

    final stream = file.readStream;
    if (stream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in stream) {
        builder.add(chunk);
        if (builder.length > _deviceFrameMaxSourceBytes) {
          throw StateError(oversizedMessage);
        }
      }
      return builder.takeBytes();
    }

    final filePath = file.path;
    if (filePath == null || filePath.trim().isEmpty) {
      return null;
    }
    return File(filePath).readAsBytes();
  }

  Future<ui.Image> _decodePreview(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  Future<void> _exportFrame() async {
    final image = _sourceImage;
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (image == null || boundary == null) {
      return;
    }

    setState(() {
      _exporting = true;
      _savedPath = null;
      _error = null;
    });

    final saveDialogTitle = _lifeText(
      context,
      zh: '保存带壳截图',
      en: 'Save framed screenshot',
    );
    final browserDownloadText = _lifeText(
      context,
      zh: '浏览器下载已触发，请查看下载列表。',
      en: 'Browser download started. Check your downloads.',
    );
    final exportCanceledText = _lifeText(
      context,
      zh: '已取消保存。',
      en: 'Save canceled.',
    );
    final displayRatio = View.of(context).devicePixelRatio;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final renderBox =
          _previewKey.currentContext?.findRenderObject() as RenderBox?;
      final logicalWidth = renderBox?.size.width ?? 360;
      final sourceRatio = image.width / logicalWidth;
      final pixelRatio = math.max(displayRatio, sourceRatio).clamp(2.0, 4.8);
      final rendered = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      if (data == null) {
        throw StateError('Failed to encode PNG bytes.');
      }

      final bytes = data.buffer.asUint8List();
      final sourceName = _sourceName ?? 'device_frame';
      final baseName = path.basenameWithoutExtension(sourceName);
      final fileName = '${baseName}_mockup.png';

      String? savedPath;
      var saveDialogUnavailable = false;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: saveDialogTitle,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const <String>['png'],
          bytes: bytes,
        );
      } on UnimplementedError {
        saveDialogUnavailable = true;
      }

      if (!mounted) {
        return;
      }

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (kIsWeb) {
          setState(() => _savedPath = browserDownloadText);
          return;
        }
        if (!saveDialogUnavailable) {
          setState(() => _savedPath = exportCanceledText);
          return;
        }

        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'device_frame'),
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

  _DeviceFrameStatusSettings get _statusSettings => _DeviceFrameStatusSettings(
    timeText: _statusTimeController.text.trim().isEmpty
        ? '9:41'
        : _statusTimeController.text.trim(),
    batteryPercent: _batteryPercent.round().clamp(1, 100),
    showBatteryPercent: _showBatteryPercent,
    charging: _charging,
    signalLevel: _signalLevel.round().clamp(0, 4),
    showWifi: _showWifi,
    wifiStrength: _wifiStrength.round().clamp(0, 3),
    networkType: _networkType,
  );

  String _sizeLabel(ui.Image image) => '${image.width} x ${image.height}';

  String _aspectRatioLabel(ui.Image image) {
    final ratio = image.width / image.height;
    return '${ratio.toStringAsFixed(2)}:1';
  }

  String? _aspectWarning(BuildContext context, ui.Image image) {
    if (_preset == _DeviceFramePreset.clean) {
      return null;
    }
    final sourceAspect = image.width / image.height;
    final targetAspect = _specForPreset(_preset).screenAspect;
    if ((sourceAspect - targetAspect).abs() <= 0.08) {
      return null;
    }
    return _lifeText(
      context,
      zh: '原图比例与机模屏幕不完全一致；若主体被裁切，可把截图适配切换为“完整显示”。',
      en: 'The source aspect differs from this screen. Switch screenshot fit to "Fit whole image" if important content is cropped.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _sourceImage;

    return ToolboxToolPage(
      title: _lifeText(context, zh: '带壳截图', en: 'Device frame shot'),
      subtitle: _lifeText(
        context,
        zh: '导入本地截图，合成到原创前视机模，按需调整背景、裁切、状态栏并导出 PNG。',
        en: 'Import a local screenshot, place it in an original front-view mockup, then tune backdrop, fit, status bar, and PNG export.',
      ),
      child: Column(
        key: const ValueKey<String>('life-device-frame-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DeviceFrameStagePanel(
            previewKey: _previewKey,
            image: image,
            sourceName: _sourceName,
            savedPath: _savedPath,
            error: _error,
            exporting: _exporting,
            preset: _preset,
            background: _background,
            statusTone: _statusTone,
            statusSettings: _statusSettings,
            showStatusBar: _showStatusBar,
            showGlare: _showGlare,
            canvasPadding: _canvasPadding,
            screenFit: _screenFit,
            aspectWarning: image == null
                ? null
                : _aspectWarning(context, image),
            onPickImage: _pickImage,
            onExportFrame: image == null || _exporting ? null : _exportFrame,
            sourceSizeLabel: image == null ? null : _sizeLabel(image),
            sourceAspectLabel: image == null ? null : _aspectRatioLabel(image),
          ),
          const SizedBox(height: 12),
          _DeviceFrameStylePanel(
            preset: _preset,
            background: _background,
            screenFit: _screenFit,
            canvasPadding: _canvasPadding,
            showGlare: _showGlare,
            onPresetChanged: (value) => setState(() => _preset = value),
            onBackgroundChanged: (value) => setState(() => _background = value),
            onScreenFitChanged: (value) => setState(() => _screenFit = value),
            onCanvasPaddingChanged: (value) =>
                setState(() => _canvasPadding = value),
            onShowGlareChanged: _preset == _DeviceFramePreset.clean
                ? null
                : (value) => setState(() => _showGlare = value),
          ),
          const SizedBox(height: 12),
          _DeviceFrameStatusPanel(
            showStatusBar: _showStatusBar,
            statusTone: _statusTone,
            statusTimeController: _statusTimeController,
            batteryPercent: _batteryPercent,
            showBatteryPercent: _showBatteryPercent,
            charging: _charging,
            signalLevel: _signalLevel,
            showWifi: _showWifi,
            wifiStrength: _wifiStrength,
            networkType: _networkType,
            statusSettings: _statusSettings,
            onShowStatusBarChanged: (value) =>
                setState(() => _showStatusBar = value),
            onStatusToneChanged: (value) => setState(() => _statusTone = value),
            onTimeChanged: (_) => setState(() {}),
            onBatteryPercentChanged: (value) =>
                setState(() => _batteryPercent = value),
            onShowBatteryPercentChanged: (value) =>
                setState(() => _showBatteryPercent = value),
            onChargingChanged: (value) => setState(() => _charging = value),
            onSignalLevelChanged: (value) =>
                setState(() => _signalLevel = value),
            onShowWifiChanged: (value) => setState(() => _showWifi = value),
            onWifiStrengthChanged: (value) =>
                setState(() => _wifiStrength = value),
            onNetworkTypeChanged: (value) =>
                setState(() => _networkType = value),
          ),
          const SizedBox(height: 12),
          const _DeviceFrameNotesPanel(),
        ],
      ),
    );
  }
}

class _DeviceFrameStagePanel extends StatelessWidget {
  const _DeviceFrameStagePanel({
    required this.previewKey,
    required this.image,
    required this.sourceName,
    required this.savedPath,
    required this.error,
    required this.exporting,
    required this.preset,
    required this.background,
    required this.statusTone,
    required this.statusSettings,
    required this.showStatusBar,
    required this.showGlare,
    required this.canvasPadding,
    required this.screenFit,
    required this.aspectWarning,
    required this.onPickImage,
    required this.onExportFrame,
    required this.sourceSizeLabel,
    required this.sourceAspectLabel,
  });

  final GlobalKey previewKey;
  final ui.Image? image;
  final String? sourceName;
  final String? savedPath;
  final String? error;
  final bool exporting;
  final _DeviceFramePreset preset;
  final _DeviceFrameBackground background;
  final _DeviceFrameStatusTone statusTone;
  final _DeviceFrameStatusSettings statusSettings;
  final bool showStatusBar;
  final bool showGlare;
  final double canvasPadding;
  final _DeviceFrameScreenFit screenFit;
  final String? aspectWarning;
  final VoidCallback onPickImage;
  final VoidCallback? onExportFrame;
  final String? sourceSizeLabel;
  final String? sourceAspectLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = image != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeText(context, zh: '截图舞台', en: 'Screenshot stage'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasImage
                ? _lifeText(
                    context,
                    zh: '正在预览当前合成效果，可继续调整机模、背景或直接导出。',
                    en: 'Previewing the current composite. Tune the mockup or export it now.',
                  )
                : _lifeText(
                    context,
                    zh: '下一步：导入一张截图，页面会立刻生成带壳预览。',
                    en: 'Next: pick a screenshot and the mockup preview appears here.',
                  ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                key: const ValueKey<String>('life-device-frame-pick-button'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onPickImage,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(
                  hasImage
                      ? _lifeText(context, zh: '更换截图', en: 'Replace image')
                      : _lifeText(context, zh: '导入截图', en: 'Pick screenshot'),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('life-device-frame-export-button'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onExportFrame,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  exporting
                      ? _lifeText(context, zh: '导出中...', en: 'Exporting...')
                      : _lifeText(context, zh: '导出 PNG', en: 'Export PNG'),
                ),
              ),
            ],
          ),
          if (sourceName != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _lifeText(context, zh: '当前截图: ', en: 'Current screenshot: ') +
                  sourceName!,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (hasImage) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _lifeText(context, zh: '原图尺寸', en: 'Source size'),
                  value: sourceSizeLabel!,
                ),
                ToolboxMetricCard(
                  label: _lifeText(context, zh: '比例', en: 'Aspect'),
                  value: sourceAspectLabel!,
                ),
                ToolboxMetricCard(
                  label: _lifeText(context, zh: '机模', en: 'Mockup'),
                  value: _deviceFramePresetLabel(context, preset),
                ),
                ToolboxMetricCard(
                  label: _lifeText(context, zh: '适配', en: 'Fit'),
                  value: _deviceFrameScreenFitLabel(context, screenFit),
                ),
              ],
            ),
          ],
          if (aspectWarning != null) ...<Widget>[
            const SizedBox(height: 10),
            _DeviceFrameInfoBanner(
              icon: Icons.crop_rounded,
              text: aspectWarning!,
            ),
          ],
          if (savedPath != null) ...<Widget>[
            const SizedBox(height: 10),
            _DeviceFrameInfoBanner(
              icon: Icons.check_circle_rounded,
              text:
                  _lifeText(context, zh: '导出位置: ', en: 'Saved to: ') +
                  savedPath!,
              selectable: true,
            ),
          ],
          if (error != null) ...<Widget>[
            const SizedBox(height: 10),
            _DeviceFrameInfoBanner(
              icon: Icons.error_outline_rounded,
              text: error!,
              isError: true,
            ),
          ],
          const SizedBox(height: 14),
          RepaintBoundary(
            key: previewKey,
            child: _DeviceFramePreviewStage(
              image: image,
              preset: preset,
              background: background,
              statusTone: statusTone,
              statusSettings: statusSettings,
              showStatusBar: showStatusBar,
              showGlare: showGlare,
              canvasPadding: canvasPadding,
              screenFit: screenFit,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceFrameInfoBanner extends StatelessWidget {
  const _DeviceFrameInfoBanner({
    required this.icon,
    required this.text,
    this.isError = false,
    this.selectable = false,
  });

  final IconData icon;
  final String text;
  final bool isError;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final textStyle = theme.textTheme.bodySmall?.copyWith(color: color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: selectable
                ? SelectableText(text, style: textStyle)
                : Text(text, style: textStyle),
          ),
        ],
      ),
    );
  }
}

class _DeviceFrameStylePanel extends StatelessWidget {
  const _DeviceFrameStylePanel({
    required this.preset,
    required this.background,
    required this.screenFit,
    required this.canvasPadding,
    required this.showGlare,
    required this.onPresetChanged,
    required this.onBackgroundChanged,
    required this.onScreenFitChanged,
    required this.onCanvasPaddingChanged,
    required this.onShowGlareChanged,
  });

  final _DeviceFramePreset preset;
  final _DeviceFrameBackground background;
  final _DeviceFrameScreenFit screenFit;
  final double canvasPadding;
  final bool showGlare;
  final ValueChanged<_DeviceFramePreset> onPresetChanged;
  final ValueChanged<_DeviceFrameBackground> onBackgroundChanged;
  final ValueChanged<_DeviceFrameScreenFit> onScreenFitChanged;
  final ValueChanged<double> onCanvasPaddingChanged;
  final ValueChanged<bool>? onShowGlareChanged;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '构图设置', en: 'Composition'),
      subtitle: _lifeText(
        context,
        zh: '先选机模与背景，再决定截图是填满屏幕还是完整显示。',
        en: 'Choose the mockup and backdrop, then decide whether the screenshot fills or fits the screen.',
      ),
      children: <Widget>[
        _LifeSegmentedField<_DeviceFramePreset>(
          label: _lifeText(context, zh: '机模风格', en: 'Mockup preset'),
          value: preset,
          options: const <_LifeOption<_DeviceFramePreset>>[
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.titanium,
              labelZh: '钛金灵动岛',
              labelEn: 'Titanium island',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.obsidian,
              labelZh: '曜石灵动岛',
              labelEn: 'Obsidian island',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.graphite,
              labelZh: '石墨挖孔屏',
              labelEn: 'Graphite hole-punch',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.frost,
              labelZh: '冰霜银挖孔屏',
              labelEn: 'Frost hole-punch',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.clean,
              labelZh: '无壳海报',
              labelEn: 'Clean poster',
            ),
          ],
          onChanged: onPresetChanged,
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_DeviceFrameBackground>(
          label: _lifeText(context, zh: '背景氛围', en: 'Backdrop'),
          value: background,
          options: const <_LifeOption<_DeviceFrameBackground>>[
            _LifeOption<_DeviceFrameBackground>(
              value: _DeviceFrameBackground.studio,
              labelZh: '柔光棚拍',
              labelEn: 'Studio',
            ),
            _LifeOption<_DeviceFrameBackground>(
              value: _DeviceFrameBackground.aurora,
              labelZh: '薄荷渐变',
              labelEn: 'Aurora',
            ),
            _LifeOption<_DeviceFrameBackground>(
              value: _DeviceFrameBackground.midnight,
              labelZh: '午夜深色',
              labelEn: 'Midnight',
            ),
          ],
          onChanged: onBackgroundChanged,
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_DeviceFrameScreenFit>(
          label: _lifeText(context, zh: '截图适配', en: 'Screenshot fit'),
          value: screenFit,
          options: const <_LifeOption<_DeviceFrameScreenFit>>[
            _LifeOption<_DeviceFrameScreenFit>(
              value: _DeviceFrameScreenFit.cover,
              labelZh: '裁切填满',
              labelEn: 'Fill screen',
            ),
            _LifeOption<_DeviceFrameScreenFit>(
              value: _DeviceFrameScreenFit.contain,
              labelZh: '完整显示',
              labelEn: 'Fit whole image',
            ),
          ],
          onChanged: onScreenFitChanged,
        ),
        const SizedBox(height: 8),
        _LifeSliderField(
          label: _lifeText(context, zh: '画布留白', en: 'Canvas padding'),
          valueText: '${canvasPadding.toStringAsFixed(0)} px',
          value: canvasPadding,
          min: 12,
          max: 46,
          divisions: 17,
          onChanged: onCanvasPaddingChanged,
        ),
        if (onShowGlareChanged != null) ...<Widget>[
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: showGlare,
            onChanged: onShowGlareChanged,
            title: Text(_lifeText(context, zh: '显示炫光', en: 'Show glare')),
            subtitle: Text(
              _lifeText(
                context,
                zh: '给屏幕玻璃和边框补一点棚拍反光，让成图更像真实展示图。',
                en: 'Add a subtle studio reflection so the result feels closer to a real product shot.',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DeviceFrameStatusPanel extends StatelessWidget {
  const _DeviceFrameStatusPanel({
    required this.showStatusBar,
    required this.statusTone,
    required this.statusTimeController,
    required this.batteryPercent,
    required this.showBatteryPercent,
    required this.charging,
    required this.signalLevel,
    required this.showWifi,
    required this.wifiStrength,
    required this.networkType,
    required this.statusSettings,
    required this.onShowStatusBarChanged,
    required this.onStatusToneChanged,
    required this.onTimeChanged,
    required this.onBatteryPercentChanged,
    required this.onShowBatteryPercentChanged,
    required this.onChargingChanged,
    required this.onSignalLevelChanged,
    required this.onShowWifiChanged,
    required this.onWifiStrengthChanged,
    required this.onNetworkTypeChanged,
  });

  final bool showStatusBar;
  final _DeviceFrameStatusTone statusTone;
  final TextEditingController statusTimeController;
  final double batteryPercent;
  final bool showBatteryPercent;
  final bool charging;
  final double signalLevel;
  final bool showWifi;
  final double wifiStrength;
  final _DeviceFrameNetworkType networkType;
  final _DeviceFrameStatusSettings statusSettings;
  final ValueChanged<bool> onShowStatusBarChanged;
  final ValueChanged<_DeviceFrameStatusTone> onStatusToneChanged;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<double> onBatteryPercentChanged;
  final ValueChanged<bool> onShowBatteryPercentChanged;
  final ValueChanged<bool> onChargingChanged;
  final ValueChanged<double> onSignalLevelChanged;
  final ValueChanged<bool> onShowWifiChanged;
  final ValueChanged<double> onWifiStrengthChanged;
  final ValueChanged<_DeviceFrameNetworkType> onNetworkTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '状态栏设置', en: 'Status bar'),
      subtitle: _lifeText(
        context,
        zh: '原图顶部被裁掉，或需要统一展示时间、电量和网络状态时再开启。',
        en: 'Enable this when the source top is cropped or when you need consistent time, battery, and network state.',
      ),
      children: <Widget>[
        SwitchListTile.adaptive(
          key: const ValueKey<String>('life-device-frame-status-switch'),
          contentPadding: EdgeInsets.zero,
          value: showStatusBar,
          onChanged: onShowStatusBarChanged,
          title: Text(_lifeText(context, zh: '补状态栏', en: 'Add status bar')),
          subtitle: Text(
            _lifeText(
              context,
              zh: '开启后可单独控制时间、电量、信号、Wi-Fi 和网络制式。',
              en: 'When enabled, control time, battery, signal, Wi-Fi, and network label independently.',
            ),
          ),
        ),
        if (showStatusBar) ...<Widget>[
          const SizedBox(height: 8),
          _LifeSegmentedField<_DeviceFrameStatusTone>(
            label: _lifeText(context, zh: '状态栏配色', en: 'Status style'),
            value: statusTone,
            options: const <_LifeOption<_DeviceFrameStatusTone>>[
              _LifeOption<_DeviceFrameStatusTone>(
                value: _DeviceFrameStatusTone.light,
                labelZh: '浅色字',
                labelEn: 'Light text',
              ),
              _LifeOption<_DeviceFrameStatusTone>(
                value: _DeviceFrameStatusTone.dark,
                labelZh: '深色字',
                labelEn: 'Dark text',
              ),
            ],
            onChanged: onStatusToneChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('life-device-frame-time-field'),
            controller: statusTimeController,
            onChanged: onTimeChanged,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '时间文案', en: 'Time text'),
              hintText: '9:41',
            ),
          ),
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: '电量百分比', en: 'Battery level'),
            valueText: '${batteryPercent.round()}%',
            value: batteryPercent,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: onBatteryPercentChanged,
          ),
          const SizedBox(height: 8),
          _LifeSegmentedField<bool>(
            label: _lifeText(context, zh: '电池状态', en: 'Battery state'),
            value: charging,
            options: const <_LifeOption<bool>>[
              _LifeOption<bool>(value: false, labelZh: '普通', labelEn: 'Normal'),
              _LifeOption<bool>(
                value: true,
                labelZh: '充电中',
                labelEn: 'Charging',
              ),
            ],
            onChanged: onChargingChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: showBatteryPercent,
            onChanged: onShowBatteryPercentChanged,
            title: Text(
              _lifeText(context, zh: '显示电量数字', en: 'Show battery percent'),
            ),
          ),
          const SizedBox(height: 6),
          _LifeSliderField(
            label: _lifeText(context, zh: '蜂窝信号强度', en: 'Cellular signal'),
            valueText: '${signalLevel.round()} / 4',
            value: signalLevel,
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: onSignalLevelChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: showWifi,
            onChanged: onShowWifiChanged,
            title: Text(_lifeText(context, zh: '显示 Wi-Fi', en: 'Show Wi-Fi')),
          ),
          if (showWifi)
            _LifeSliderField(
              label: _lifeText(context, zh: 'Wi-Fi 强度', en: 'Wi-Fi strength'),
              valueText: '${wifiStrength.round()} / 3',
              value: wifiStrength,
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: onWifiStrengthChanged,
            ),
          const SizedBox(height: 10),
          _LifeSegmentedField<_DeviceFrameNetworkType>(
            label: _lifeText(context, zh: '网络制式', en: 'Network label'),
            value: networkType,
            options: const <_LifeOption<_DeviceFrameNetworkType>>[
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.none,
                labelZh: '无字样',
                labelEn: 'No text',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.edge,
                labelZh: 'E',
                labelEn: 'E',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.fourG,
                labelZh: '4G',
                labelEn: '4G',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.fiveG,
                labelZh: '5G',
                labelEn: '5G',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.lte,
                labelZh: 'LTE',
                labelEn: 'LTE',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.wifiOnly,
                labelZh: '仅 Wi-Fi',
                labelEn: 'Wi-Fi only',
              ),
            ],
            onChanged: onNetworkTypeChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeText(context, zh: '时间', en: 'Time'),
                value: statusSettings.timeText,
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '电量', en: 'Battery'),
                value:
                    '${statusSettings.batteryPercent}% · ${_deviceFrameBatteryStatusLabel(context, statusSettings)}',
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '网络', en: 'Network'),
                value: _deviceFrameNetworkTypeLabel(context, networkType),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DeviceFrameNotesPanel extends StatelessWidget {
  const _DeviceFrameNotesPanel();

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '使用边界', en: 'Notes'),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '当前机模均为仓库内原创前视展示图层，参考主流真机的正面观感、边框节奏和 cutout 布局，但不对应任何厂商官方营销素材或精确 OEM 尺寸。',
            en: 'These mockups are original front-view showcase assets inspired by mainstream device proportions, frame rhythm, and cutout placement, not official OEM marketing materials or exact physical dimensions.',
          ),
        ),
      ],
    );
  }
}

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
      final oversizedMessage = _lifeI18nText(
        context,
        'inline.plan295.life.the_image_is_larger_than_32_mb_compr.a64eb8a5d824',
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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.device.frame.failed_to_pick_screenshot.70461507aa',
          params: <String, Object?>{'error': error},
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

    final saveDialogTitle = _lifeI18nText(
      context,
      'inline.plan295.life.save_framed_screenshot.77dee7782207',
    );
    final browserDownloadText = _lifeI18nText(
      context,
      'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
    );
    final exportCanceledText = _lifeI18nText(
      context,
      'inline.plan295.life.save_canceled.50d0c10cdace',
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
    return _lifeI18nText(
      context,
      'inline.plan295.life.the_source_aspect_differs_from_this.6483689570ac',
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _sourceImage;

    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.device_frame_shot.e3a794041162',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.import_a_local_screenshot_place_it_i.9cf5b3415183',
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
            _lifeI18nText(
              context,
              'inline.plan295.life.screenshot_stage.56b863221d84',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasImage
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.previewing_the_current_composite_tun.4b848fbf7597',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.life.next_pick_a_screenshot_and_the_mocku.6566084b4a4b',
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
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.replace_image.08c794454d62',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.life.pick_screenshot.6bd979625881',
                        ),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('life-device-frame-export-button'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onExportFrame,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  exporting
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
          if (sourceName != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _lifeI18nText(
                    context,
                    'inline.plan295.life.current_screenshot.89d8d0e730c0',
                  ) +
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
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.source_size.bcee8f1e482c',
                  ),
                  value: sourceSizeLabel!,
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.aspect.cf4a9d39d48b',
                  ),
                  value: sourceAspectLabel!,
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.mockup.87069b67283d',
                  ),
                  value: _deviceFramePresetLabel(context, preset),
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.fit.8044bd1bbe38',
                  ),
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
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.saved_to.6546039c21f2',
                  ) +
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.composition.e061eff04394',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.choose_the_mockup_and_backdrop_then.51ab84fe1b4c',
      ),
      children: <Widget>[
        _LifeSegmentedField<_DeviceFramePreset>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.mockup_preset.592212454ffb',
          ),
          value: preset,
          options: const <_LifeOption<_DeviceFramePreset>>[
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.titanium,
              labelKey: 'inline.plan295.life.titanium_island.cc96da6b5d71',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.obsidian,
              labelKey: 'inline.plan295.life.obsidian_island.d979f2c453f2',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.graphite,
              labelKey: 'inline.plan295.life.graphite_hole_punch.6a404cab7936',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.frost,
              labelKey: 'inline.plan295.life.frost_hole_punch.767828eb59af',
            ),
            _LifeOption<_DeviceFramePreset>(
              value: _DeviceFramePreset.clean,
              labelKey: 'inline.plan295.life.clean_poster.7d0c9009a20f',
            ),
          ],
          onChanged: onPresetChanged,
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_DeviceFrameBackground>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.backdrop.0551932c2eba',
          ),
          value: background,
          options: const <_LifeOption<_DeviceFrameBackground>>[
            _LifeOption<_DeviceFrameBackground>(
              value: _DeviceFrameBackground.studio,
              labelKey: 'inline.plan295.life.studio.0ec59319705f',
            ),
            _LifeOption<_DeviceFrameBackground>(
              value: _DeviceFrameBackground.aurora,
              labelKey: 'inline.plan295.life.aurora.509cc7d060d3',
            ),
            _LifeOption<_DeviceFrameBackground>(
              value: _DeviceFrameBackground.midnight,
              labelKey: 'inline.plan295.life.midnight.7125c74faa32',
            ),
          ],
          onChanged: onBackgroundChanged,
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<_DeviceFrameScreenFit>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.screenshot_fit.0c7c11ef8a96',
          ),
          value: screenFit,
          options: const <_LifeOption<_DeviceFrameScreenFit>>[
            _LifeOption<_DeviceFrameScreenFit>(
              value: _DeviceFrameScreenFit.cover,
              labelKey: 'inline.plan295.life.fill_screen.c130d99e73b9',
            ),
            _LifeOption<_DeviceFrameScreenFit>(
              value: _DeviceFrameScreenFit.contain,
              labelKey: 'inline.plan295.life.fit_whole_image.889f3cf4dea8',
            ),
          ],
          onChanged: onScreenFitChanged,
        ),
        const SizedBox(height: 8),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.canvas_padding.b8563d740a03',
          ),
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
            title: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.show_glare.86b3cbb4ba98',
              ),
            ),
            subtitle: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.add_a_subtle_studio_reflection_so_th.c0accbe4e6b9',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.status_bar.aefffa2429cf',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.enable_this_when_the_source_top_is_c.5fdde1f95d3c',
      ),
      children: <Widget>[
        SwitchListTile.adaptive(
          key: const ValueKey<String>('life-device-frame-status-switch'),
          contentPadding: EdgeInsets.zero,
          value: showStatusBar,
          onChanged: onShowStatusBarChanged,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.add_status_bar.6193c7899043',
            ),
          ),
          subtitle: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.when_enabled_control_time_battery_si.aa7039f7d362',
            ),
          ),
        ),
        if (showStatusBar) ...<Widget>[
          const SizedBox(height: 8),
          _LifeSegmentedField<_DeviceFrameStatusTone>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.status_style.e495ee959789',
            ),
            value: statusTone,
            options: const <_LifeOption<_DeviceFrameStatusTone>>[
              _LifeOption<_DeviceFrameStatusTone>(
                value: _DeviceFrameStatusTone.light,
                labelKey: 'inline.plan295.life.light_text.69e7cd253340',
              ),
              _LifeOption<_DeviceFrameStatusTone>(
                value: _DeviceFrameStatusTone.dark,
                labelKey: 'inline.plan295.life.dark_text.20e890f3e407',
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
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.time_text.e7495b76c18a',
              ),
              hintText: '9:41',
            ),
          ),
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.battery_level.508b1ef46552',
            ),
            valueText: '${batteryPercent.round()}%',
            value: batteryPercent,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: onBatteryPercentChanged,
          ),
          const SizedBox(height: 8),
          _LifeSegmentedField<bool>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.battery_state.df01beb12a1d',
            ),
            value: charging,
            options: const <_LifeOption<bool>>[
              _LifeOption<bool>(
                value: false,
                labelKey: 'inline.plan295.life.normal.52e6667a59a6',
              ),
              _LifeOption<bool>(
                value: true,
                labelKey: 'inline.plan295.life.charging.5f9c2df896d8',
              ),
            ],
            onChanged: onChargingChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: showBatteryPercent,
            onChanged: onShowBatteryPercentChanged,
            title: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.show_battery_percent.60745b3afd72',
              ),
            ),
          ),
          const SizedBox(height: 6),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.cellular_signal.4a8a3d469bd0',
            ),
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
            title: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.show_wi_fi.651d4bfa2e76',
              ),
            ),
          ),
          if (showWifi)
            _LifeSliderField(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.wi_fi_strength.b8d4ec5af587',
              ),
              valueText: '${wifiStrength.round()} / 3',
              value: wifiStrength,
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: onWifiStrengthChanged,
            ),
          const SizedBox(height: 10),
          _LifeSegmentedField<_DeviceFrameNetworkType>(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.network_label.e438b42a2b0a',
            ),
            value: networkType,
            options: const <_LifeOption<_DeviceFrameNetworkType>>[
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.none,
                labelKey: 'inline.plan295.life.no_text.34d3947413e5',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.edge,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_compass.e_569c50',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.fourG,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_device_frame_labels.4g_8b353d',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.fiveG,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_device_frame_labels.5g_c19123',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.lte,
                labelKey:
                    'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_device_frame_labels.lte_276f23',
              ),
              _LifeOption<_DeviceFrameNetworkType>(
                value: _DeviceFrameNetworkType.wifiOnly,
                labelKey: 'inline.plan295.life.wi_fi_only.0991304ffff5',
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
                label: _lifeI18nText(
                  context,
                  'inline.ui.pages.toolbox_human_tests_typing.time_b4685a',
                ),
                value: statusSettings.timeText,
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.battery.4cfb5f06293f',
                ),
                value:
                    '${statusSettings.batteryPercent}% · ${_deviceFrameBatteryStatusLabel(context, statusSettings)}',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.network.a842366fbdeb',
                ),
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
      title: _lifeI18nText(context, 'inline.plan295.life.notes.34bde0fb12d6'),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.these_mockups_are_original_front_vie.01b12ba6eda0',
          ),
        ),
      ],
    );
  }
}

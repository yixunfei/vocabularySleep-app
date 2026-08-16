part of '../toolbox_life_tools.dart';

class _MagnifierToolPage extends StatefulWidget {
  const _MagnifierToolPage();

  @override
  State<_MagnifierToolPage> createState() => _MagnifierToolPageState();
}

class _MagnifierToolPageState extends State<_MagnifierToolPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  ui.Image? _frozenImage;
  bool _initializing = true;
  bool _torchOn = false;
  bool _frozen = false;
  int _cameraIndex = 0;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _frozenImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.magnifier.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.magnifier.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.magnifier.stage'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.magnifier.stage_subtitle',
            ),
            children: <Widget>[
              AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                    child: _buildPreview(context),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _LifeSliderField(
                label: _lifeI18nText(context, 'toolbox.life.magnifier.zoom'),
                valueText: '${_zoom.toStringAsFixed(1)}x',
                value: _zoom.clamp(_minZoom, _maxZoom),
                min: _minZoom,
                max: math.max(_minZoom, _maxZoom),
                divisions: math.max(1, ((_maxZoom - _minZoom) * 10).round()),
                onChanged: _setZoom,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _controller == null ? null : _toggleFreeze,
                    icon: Icon(
                      _frozen ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    ),
                    label: Text(
                      _lifeI18nText(
                        context,
                        _frozen
                            ? 'toolbox.life.magnifier.resume'
                            : 'toolbox.life.magnifier.freeze',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _controller == null ? null : _toggleTorch,
                    icon: Icon(
                      _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                    ),
                    label: Text(
                      _lifeI18nText(context, 'toolbox.life.magnifier.torch'),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _cameras.length < 2 ? null : _switchCamera,
                    icon: const Icon(Icons.cameraswitch_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.magnifier.switch_camera',
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorKey != null) ...<Widget>[
                const SizedBox(height: 12),
                _LifeInlineNotice(
                  icon: Icons.no_photography_rounded,
                  text: _lifeI18nText(context, _errorKey!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_frozen && _frozenImage != null) {
      return RawImage(image: _frozenImage, fit: BoxFit.cover);
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          _lifeI18nText(context, 'toolbox.life.magnifier.no_camera'),
          textAlign: TextAlign.center,
        ),
      );
    }
    return CameraPreview(controller);
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _errorKey = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameras = cameras;
          _controller = null;
          _errorKey = 'toolbox.life.magnifier.error_no_camera';
        });
        return;
      }
      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = backIndex >= 0 ? backIndex : 0;
      await _openCamera(_cameraIndex);
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.magnifier.error_camera');
      }
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  Future<void> _openCamera(int index) async {
    final old = _controller;
    _controller = null;
    await old?.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    final minZoom = await controller.getMinZoomLevel();
    final maxZoom = await controller.getMaxZoomLevel();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _minZoom = minZoom;
      _maxZoom = math.max(minZoom, maxZoom);
      _zoom = _zoom.clamp(_minZoom, _maxZoom);
      _torchOn = false;
      _frozen = false;
    });
    await _setZoom(_zoom);
  }

  Future<void> _setZoom(double value) async {
    final controller = _controller;
    final next = value.clamp(_minZoom, _maxZoom);
    setState(() => _zoom = next);
    try {
      await controller?.setZoomLevel(next);
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.magnifier.error_zoom');
      }
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      setState(() {
        _torchOn = !_torchOn;
        _errorKey = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.magnifier.error_torch');
      }
    }
  }

  Future<void> _toggleFreeze() async {
    final controller = _controller;
    if (_frozen) {
      setState(() => _frozen = false);
      return;
    }
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final image = await _decodeLifeUiImage(bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _frozenImage;
      setState(() {
        _frozenImage = image;
        _frozen = true;
        _errorKey = null;
      });
      old?.dispose();
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.magnifier.error_freeze');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      return;
    }
    setState(() => _initializing = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _openCamera(_cameraIndex);
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.magnifier.error_camera');
      }
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }
}

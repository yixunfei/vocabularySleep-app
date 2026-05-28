part of '../toolbox_life_tools.dart';

const int _qrImageSourceReadMaxBytes = 32 * 1024 * 1024;
const int _qrImagePayloadTargetBytes = 2200;
const int _qrArtImageMaxSide = 720;
const int _qrArtImageJpegQuality = 78;
const int _qrArtImageTargetBytes = 720 * 1024;

enum _QrVisualImageMode { none, artBlend, transparentArt }

enum _QrCorrectionOption { low, medium, quartile, high }

extension _QrCorrectionOptionInfo on _QrCorrectionOption {
  int get qrValue {
    return switch (this) {
      _QrCorrectionOption.low => QrErrorCorrectLevel.L,
      _QrCorrectionOption.medium => QrErrorCorrectLevel.M,
      _QrCorrectionOption.quartile => QrErrorCorrectLevel.Q,
      _QrCorrectionOption.high => QrErrorCorrectLevel.H,
    };
  }

  String get label {
    return switch (this) {
      _QrCorrectionOption.low => 'L 7%',
      _QrCorrectionOption.medium => 'M 15%',
      _QrCorrectionOption.quartile => 'Q 25%',
      _QrCorrectionOption.high => 'H 30%',
    };
  }
}

class _QrStyleSpec {
  const _QrStyleSpec({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.foreground,
    required this.background,
    required this.eyeShape,
    required this.moduleShape,
    this.panelColor,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final Color foreground;
  final Color background;
  final QrEyeShape eyeShape;
  final QrDataModuleShape moduleShape;
  final Color? panelColor;

  String label(BuildContext context) {
    return _lifeText(context, zh: labelZh, en: labelEn);
  }
}

const List<_QrStyleSpec> _qrStyleSpecs = <_QrStyleSpec>[
  _QrStyleSpec(
    id: 'classic',
    labelZh: '经典黑白',
    labelEn: 'Classic',
    foreground: Color(0xFF111827),
    background: Colors.white,
    eyeShape: QrEyeShape.square,
    moduleShape: QrDataModuleShape.square,
  ),
  _QrStyleSpec(
    id: 'rounded',
    labelZh: '圆点柔和',
    labelEn: 'Rounded',
    foreground: Color(0xFF0F766E),
    background: Color(0xFFF0FDFA),
    eyeShape: QrEyeShape.circle,
    moduleShape: QrDataModuleShape.circle,
    panelColor: Color(0xFFE6FFFB),
  ),
  _QrStyleSpec(
    id: 'midnight',
    labelZh: '夜色高对比',
    labelEn: 'Midnight',
    foreground: Color(0xFFF8FAFC),
    background: Color(0xFF111827),
    eyeShape: QrEyeShape.square,
    moduleShape: QrDataModuleShape.square,
    panelColor: Color(0xFF1F2937),
  ),
  _QrStyleSpec(
    id: 'blueprint',
    labelZh: '蓝图',
    labelEn: 'Blueprint',
    foreground: Color(0xFF1D4ED8),
    background: Color(0xFFEFF6FF),
    eyeShape: QrEyeShape.square,
    moduleShape: QrDataModuleShape.circle,
    panelColor: Color(0xFFDBEAFE),
  ),
  _QrStyleSpec(
    id: 'rose',
    labelZh: '柔玫瑰',
    labelEn: 'Rose',
    foreground: Color(0xFF9F1239),
    background: Color(0xFFFFF1F2),
    eyeShape: QrEyeShape.circle,
    moduleShape: QrDataModuleShape.square,
    panelColor: Color(0xFFFFE4E6),
  ),
];

class _QrVersionOption {
  const _QrVersionOption({required this.value, required this.label});

  final int value;
  final String label;
}

final List<_QrVersionOption> _qrVersionOptions = <_QrVersionOption>[
  const _QrVersionOption(value: QrVersions.auto, label: 'Auto'),
  ...List<_QrVersionOption>.generate(
    40,
    (index) => _QrVersionOption(value: index + 1, label: 'V${index + 1}'),
  ),
];

class _QrPage extends StatefulWidget {
  const _QrPage();

  @override
  State<_QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<_QrPage> {
  final GlobalKey _previewKey = GlobalKey();
  final TextEditingController _textController = TextEditingController(
    text: 'Sleep words: focus, rest, review.',
  );
  final TextEditingController _urlController = TextEditingController(
    text: 'https://example.com',
  );
  final TextEditingController _wifiSsidController = TextEditingController(
    text: 'Home WiFi',
  );
  final TextEditingController _wifiPasswordController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController(
    text: 'Alex Chen',
  );
  final TextEditingController _contactPhoneController = TextEditingController(
    text: '+86 138 0000 0000',
  );
  final TextEditingController _contactEmailController = TextEditingController(
    text: 'alex@example.com',
  );
  final TextEditingController _contactOrgController = TextEditingController(
    text: 'Vocabulary Sleep',
  );
  final TextEditingController _emailToController = TextEditingController(
    text: 'hello@example.com',
  );
  final TextEditingController _emailSubjectController = TextEditingController(
    text: 'Hello',
  );
  final TextEditingController _emailBodyController = TextEditingController(
    text: 'Sent from QR code.',
  );
  final TextEditingController _smsPhoneController = TextEditingController(
    text: '+86 138 0000 0000',
  );
  final TextEditingController _smsBodyController = TextEditingController(
    text: 'I will arrive soon.',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+86 138 0000 0000',
  );
  final TextEditingController _latitudeController = TextEditingController(
    text: '31.230416',
  );
  final TextEditingController _longitudeController = TextEditingController(
    text: '121.473701',
  );
  final TextEditingController _geoLabelController = TextEditingController(
    text: 'Shanghai',
  );
  final TextEditingController _eventTitleController = TextEditingController(
    text: 'Review session',
  );
  final TextEditingController _eventLocationController = TextEditingController(
    text: 'Study room',
  );

  ToolboxQrPayloadType _payloadType = ToolboxQrPayloadType.url;
  ToolboxQrEncodingStandard _standard = ToolboxQrEncodingStandard.qrCode;
  ToolboxQrWifiEncryption _wifiEncryption = ToolboxQrWifiEncryption.wpa;
  bool _wifiHidden = false;
  _QrCorrectionOption _correction = _QrCorrectionOption.quartile;
  int _version = QrVersions.auto;
  bool _gapless = true;
  _QrStyleSpec _style = _qrStyleSpecs.first;
  bool _useCenterImage = false;
  double _logoSize = 54;
  Uint8List? _logoBytes;
  String? _logoName;
  _QrVisualImageMode _visualImageMode = _QrVisualImageMode.none;
  Uint8List? _visualImageBytes;
  String? _visualImageName;
  ToolboxQrArtImageResult? _visualImageResult;
  double _visualImageVeil = 0.46;
  double _artDarkness = 0.84;
  double _artModuleScale = 0.86;

  Uint8List? _imageSourceBytes;
  String? _imageSourceName;
  ToolboxQrImageDataResult? _imageDataResult;
  ToolboxQrImageCodec _imageCodec = ToolboxQrImageCodec.jpeg;
  double _imageMaxSide = 72;
  double _imageJpegQuality = 56;
  bool _processingImage = false;
  bool _processingVisualImage = false;

  DateTime _eventStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _eventEnd = DateTime.now().add(const Duration(hours: 2));
  bool _exporting = false;
  String? _savedPath;
  String? _error;

  List<TextEditingController> get _controllers => <TextEditingController>[
    _textController,
    _urlController,
    _wifiSsidController,
    _wifiPasswordController,
    _contactNameController,
    _contactPhoneController,
    _contactEmailController,
    _contactOrgController,
    _emailToController,
    _emailSubjectController,
    _emailBodyController,
    _smsPhoneController,
    _smsBodyController,
    _phoneController,
    _latitudeController,
    _longitudeController,
    _geoLabelController,
    _eventTitleController,
    _eventLocationController,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _savedPath = null;
        _error = null;
      });
    }
  }

  ToolboxQrPayloadInput _buildPayloadInput() {
    return ToolboxQrPayloadInput(
      type: _payloadType,
      text: _textController.text,
      url: _urlController.text,
      wifiSsid: _wifiSsidController.text,
      wifiPassword: _wifiPasswordController.text,
      wifiEncryption: _wifiEncryption,
      wifiHidden: _wifiHidden,
      contactName: _contactNameController.text,
      contactPhone: _contactPhoneController.text,
      contactEmail: _contactEmailController.text,
      contactOrg: _contactOrgController.text,
      emailTo: _emailToController.text,
      emailSubject: _emailSubjectController.text,
      emailBody: _emailBodyController.text,
      smsPhone: _smsPhoneController.text,
      smsBody: _smsBodyController.text,
      phoneNumber: _phoneController.text,
      latitude: _latitudeController.text,
      longitude: _longitudeController.text,
      geoLabel: _geoLabelController.text,
      eventTitle: _eventTitleController.text,
      eventLocation: _eventLocationController.text,
      eventStart: _eventStart,
      eventEnd: _eventEnd,
      imageDataUrl:
          _imageDataResult?.dataUrl ?? 'Select and compress an image first.',
    );
  }

  ToolboxQrPayloadResult get _payloadResult {
    return ToolboxQrService.buildPayload(_buildPayloadInput());
  }

  Future<void> _pickLogoImage() async {
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
      final bytes = await _readPickedBytes(file);
      if (bytes == null || bytes.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _logoBytes = bytes;
        _logoName = file.name;
        _useCenterImage = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '导入中心图片失败: $error',
          en: 'Failed to import center image: $error',
        );
      });
    }
  }

  Future<void> _pickVisualImage() async {
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
      final bytes = await _readPickedBytes(file);
      if (bytes == null || bytes.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _processingVisualImage = true;
        _error = null;
      });
      final result = await _prepareVisualArtImage(bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _visualImageBytes = result.bytes;
        _visualImageName = file.name;
        _visualImageResult = result;
        if (_visualImageMode == _QrVisualImageMode.none) {
          _visualImageMode = _QrVisualImageMode.artBlend;
        }
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '导入艺术图片失败: $error',
          en: 'Failed to import visual image: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _processingVisualImage = false);
      }
    }
  }

  Future<void> _pickQrImagePayload() async {
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
      final bytes = await _readPickedBytes(file);
      if (bytes == null || bytes.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _imageSourceBytes = bytes;
        _imageSourceName = file.name;
        _payloadType = ToolboxQrPayloadType.imageDataUrl;
        _standard = ToolboxQrEncodingStandard.qrCode;
        _correction = _QrCorrectionOption.high;
        _error = null;
      });
      await _compressImagePayload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '导入图片二维码内容失败: $error',
          en: 'Failed to import image payload: $error',
        );
      });
    }
  }

  Future<Uint8List?> _readPickedBytes(PlatformFile file) async {
    final tooLargeMessage = _lifeText(
      context,
      zh: '图片超过 32MB，二维码化会占用过多内存，请先裁切或用图片压缩页压小后再导入。',
      en: 'The image is larger than 32 MB. Crop it or compress it first to avoid high memory use.',
    );
    if (file.size > _qrImageSourceReadMaxBytes) {
      throw StateError(tooLargeMessage);
    }
    final bytes = file.bytes;
    if (bytes != null) {
      return bytes;
    }
    final stream = file.readStream;
    if (stream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in stream) {
        builder.add(chunk);
        if (builder.length > _qrImageSourceReadMaxBytes) {
          throw StateError(tooLargeMessage);
        }
      }
      return builder.takeBytes();
    }
    final filePath = file.path;
    if (filePath == null || filePath.trim().isEmpty) {
      return null;
    }
    final diskFile = File(filePath);
    final diskSize = await diskFile.length();
    if (diskSize > _qrImageSourceReadMaxBytes) {
      throw StateError(tooLargeMessage);
    }
    return diskFile.readAsBytes();
  }

  Future<void> _compressImagePayload() async {
    final source = _imageSourceBytes;
    if (source == null) {
      return;
    }
    setState(() {
      _processingImage = true;
      _error = null;
    });
    try {
      var result = await _encodeImagePayloadWithTarget(
        source,
        _qrImagePayloadTargetBytes,
      );
      if (!_imagePayloadFitsCurrentQr(result.dataUrl)) {
        for (final target in const <int>[1600, 1200, 900, 650]) {
          final candidate = await _encodeImagePayloadWithTarget(source, target);
          if (candidate.dataUrlBytes < result.dataUrlBytes) {
            result = candidate;
          }
          if (_imagePayloadFitsCurrentQr(candidate.dataUrl)) {
            result = candidate;
            break;
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _imageDataResult = result;
        _payloadType = ToolboxQrPayloadType.imageDataUrl;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '图片二维码化失败: $error',
          en: 'Failed to QR-encode image: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _processingImage = false);
      }
    }
  }

  Future<ToolboxQrImageDataResult> _encodeImagePayloadWithTarget(
    Uint8List source,
    int targetDataUrlBytes,
  ) {
    return compute(
      _encodeQrImageDataUrl,
      _QrImageEncodeRequest(
        source,
        _imageMaxSide.round(),
        _imageJpegQuality.round(),
        _imageCodec,
        targetDataUrlBytes,
      ),
    );
  }

  Future<ToolboxQrArtImageResult> _prepareVisualArtImage(Uint8List source) {
    return compute(
      _prepareQrArtImage,
      _QrArtImageEncodeRequest(
        source,
        _qrArtImageMaxSide,
        _qrArtImageJpegQuality,
        _qrArtImageTargetBytes,
      ),
    );
  }

  void _applyArtScanPreset() {
    setState(() {
      _standard = ToolboxQrEncodingStandard.qrCode;
      _correction = _QrCorrectionOption.low;
      _version = 25;
      _gapless = true;
      _useCenterImage = false;
      _visualImageMode = _visualImageBytes == null
          ? _QrVisualImageMode.none
          : _QrVisualImageMode.artBlend;
      _visualImageVeil = 0.70;
      _artDarkness = 0.90;
      _artModuleScale = 0.72;
      _error = null;
    });
  }

  bool _imagePayloadFitsCurrentQr(String dataUrl) {
    final validation = QrValidator.validate(
      data: dataUrl,
      version: _version,
      errorCorrectionLevel: _correction.qrValue,
    );
    if (!validation.isValid || validation.qrCode == null) {
      return false;
    }
    try {
      QrPainter.withQr(qr: validation.qrCode!);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickEventDateTime({required bool start}) async {
    final current = start ? _eventStart : _eventEnd;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted || time == null) {
      return;
    }
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _eventStart = next;
        if (!_eventEnd.isAfter(_eventStart)) {
          _eventEnd = _eventStart.add(const Duration(hours: 1));
        }
      } else {
        _eventEnd = next.isAfter(_eventStart)
            ? next
            : _eventStart.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _copyPayload() async {
    final payload = _payloadResult.payload;
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lifeText(context, zh: '内容已复制', en: 'Payload copied')),
      ),
    );
  }

  Future<void> _exportPng() async {
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }
    setState(() {
      _exporting = true;
      _savedPath = null;
      _error = null;
    });
    final saveDialogTitle = _lifeText(
      context,
      zh: '保存二维码',
      en: 'Save code image',
    );
    final browserDownloadText = _lifeText(
      context,
      zh: '浏览器下载已触发，请查看下载列表。',
      en: 'Browser download started. Check your downloads.',
    );
    try {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final rendered = await boundary.toImage(pixelRatio: 4);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      if (data == null) {
        throw StateError('Failed to encode PNG bytes.');
      }
      final bytes = data.buffer.asUint8List();
      final name = _payloadType == ToolboxQrPayloadType.imageDataUrl
          ? path.basenameWithoutExtension(_imageSourceName ?? 'image_qr')
          : _payloadType.id;
      final fileName = '${name}_${_standard.id}.png';
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
        final exportDir = Directory(path.join(appDir.path, 'life_tools', 'qr'));
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallback = File(
          path.join(exportDir.path, '${name}_$timestamp.png'),
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

  @override
  Widget build(BuildContext context) {
    final payload = _payloadResult;
    final qrValidation = _safeQrValidation(payload);
    return ToolboxToolPage(
      title: _lifeText(context, zh: '二维码生成', en: 'QR generator'),
      subtitle: _lifeText(
        context,
        zh: '本地生成 QR / Data Matrix / Aztec / PDF417，支持模板、样式、中心图和图片二维码化。',
        en: 'Generate QR, Data Matrix, Aztec, and PDF417 locally with templates, styles, center images, and image Data URL payloads.',
      ),
      child: Column(
        key: const ValueKey<String>('life-qr-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPayloadPanel(context),
          const SizedBox(height: 12),
          _buildStylePanel(context),
          const SizedBox(height: 12),
          _buildPreviewPanel(context, payload, qrValidation),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildQrMessage(context, _error!, isError: true),
          ],
          if (_savedPath != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildQrMessage(
              context,
              _lifeText(
                context,
                zh: '已保存: $_savedPath',
                en: 'Saved: $_savedPath',
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildBoundaryPanel(context),
        ],
      ),
    );
  }

  Widget _buildPayloadPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '内容模板', en: 'Content template'),
      subtitle: _lifeText(
        context,
        zh: '选择内容类型后只显示相关输入，减少移动端滚动负担。',
        en: 'Only relevant fields are shown for the selected payload type.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ToolboxQrPayloadType.values
              .map((type) {
                return ChoiceChip(
                  selected: _payloadType == type,
                  label: Text(_payloadLabel(type)),
                  onSelected: (_) => setState(() => _payloadType = type),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey<ToolboxQrPayloadType>(_payloadType),
            child: _buildPayloadFields(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPayloadFields(BuildContext context) {
    return switch (_payloadType) {
      ToolboxQrPayloadType.text => TextField(
        key: const ValueKey<String>('life-qr-text-field'),
        controller: _textController,
        minLines: 4,
        maxLines: 8,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: _lifeText(context, zh: '文本内容', en: 'Text content'),
        ),
      ),
      ToolboxQrPayloadType.url => TextField(
        key: const ValueKey<String>('life-qr-url-field'),
        controller: _urlController,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.link_rounded),
          labelText: _lifeText(context, zh: '网址', en: 'URL'),
        ),
      ),
      ToolboxQrPayloadType.wifi => _buildWifiFields(context),
      ToolboxQrPayloadType.contact => _buildContactFields(context),
      ToolboxQrPayloadType.email => _buildEmailFields(context),
      ToolboxQrPayloadType.sms => _buildSmsFields(context),
      ToolboxQrPayloadType.phone => TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.phone_rounded),
          labelText: _lifeText(context, zh: '电话号码', en: 'Phone number'),
        ),
      ),
      ToolboxQrPayloadType.geo => _buildGeoFields(context),
      ToolboxQrPayloadType.calendar => _buildCalendarFields(context),
      ToolboxQrPayloadType.imageDataUrl => _buildImagePayloadFields(context),
    };
  }

  Widget _buildWifiFields(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: _wifiSsidController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: 'Wi-Fi 名称', en: 'Wi-Fi SSID'),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _wifiPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '密码', en: 'Password'),
          ),
        ),
        const SizedBox(height: 10),
        _LifeSegmentedField<ToolboxQrWifiEncryption>(
          label: _lifeText(context, zh: '加密方式', en: 'Encryption'),
          value: _wifiEncryption,
          options: ToolboxQrWifiEncryption.values
              .map(
                (item) => _LifeOption<ToolboxQrWifiEncryption>(
                  value: item,
                  labelZh: item.label,
                  labelEn: item.label,
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _wifiEncryption = value),
        ),
        SwitchListTile(
          value: _wifiHidden,
          contentPadding: EdgeInsets.zero,
          title: Text(_lifeText(context, zh: '隐藏网络', en: 'Hidden network')),
          onChanged: (value) => setState(() => _wifiHidden = value),
        ),
      ],
    );
  }

  Widget _buildContactFields(BuildContext context) {
    return Column(
      children: <Widget>[
        _textInput(
          _contactNameController,
          _lifeText(context, zh: '姓名', en: 'Name'),
        ),
        const SizedBox(height: 10),
        _textInput(
          _contactPhoneController,
          _lifeText(context, zh: '电话', en: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _textInput(
          _contactEmailController,
          _lifeText(context, zh: '邮箱', en: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _textInput(
          _contactOrgController,
          _lifeText(context, zh: '组织', en: 'Org'),
        ),
      ],
    );
  }

  Widget _buildEmailFields(BuildContext context) {
    return Column(
      children: <Widget>[
        _textInput(
          _emailToController,
          _lifeText(context, zh: '收件人', en: 'To'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _textInput(
          _emailSubjectController,
          _lifeText(context, zh: '主题', en: 'Subject'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailBodyController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '正文', en: 'Body'),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsFields(BuildContext context) {
    return Column(
      children: <Widget>[
        _textInput(
          _smsPhoneController,
          _lifeText(context, zh: '手机号', en: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _smsBodyController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '短信内容', en: 'Message'),
          ),
        ),
      ],
    );
  }

  Widget _buildGeoFields(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _textInput(
                _latitudeController,
                _lifeText(context, zh: '纬度', en: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _textInput(
                _longitudeController,
                _lifeText(context, zh: '经度', en: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _textInput(
          _geoLabelController,
          _lifeText(context, zh: '地点名', en: 'Label'),
        ),
      ],
    );
  }

  Widget _buildCalendarFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _textInput(
          _eventTitleController,
          _lifeText(context, zh: '事件标题', en: 'Title'),
        ),
        const SizedBox(height: 10),
        _textInput(
          _eventLocationController,
          _lifeText(context, zh: '地点', en: 'Location'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () => _pickEventDateTime(start: true),
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _lifeText(
                  context,
                  zh: '开始 ${_formatShortDateTime(_eventStart)}',
                  en: 'Start ${_formatShortDateTime(_eventStart)}',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickEventDateTime(start: false),
              icon: const Icon(Icons.event_available_rounded),
              label: Text(
                _lifeText(
                  context,
                  zh: '结束 ${_formatShortDateTime(_eventEnd)}',
                  en: 'End ${_formatShortDateTime(_eventEnd)}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePayloadFields(BuildContext context) {
    final imageData = _imageDataResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('life-qr-image-pick-button'),
                onPressed: _processingImage ? null : _pickQrImagePayload,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(_lifeText(context, zh: '导入图片', en: 'Import image')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _imageSourceBytes == null || _processingImage
                    ? null
                    : _compressImagePayload,
                icon: _processingImage
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  _processingImage
                      ? _lifeText(context, zh: '处理中...', en: 'Working...')
                      : _lifeText(context, zh: '二维码化', en: 'Encode'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxQrImageCodec>(
          label: _lifeText(context, zh: '压缩格式', en: 'Payload image format'),
          value: _imageCodec,
          options: const <_LifeOption<ToolboxQrImageCodec>>[
            _LifeOption<ToolboxQrImageCodec>(
              value: ToolboxQrImageCodec.jpeg,
              labelZh: 'JPEG 小体积',
              labelEn: 'JPEG small',
            ),
            _LifeOption<ToolboxQrImageCodec>(
              value: ToolboxQrImageCodec.png,
              labelZh: 'PNG 透明',
              labelEn: 'PNG transparent',
            ),
          ],
          onChanged: (value) => setState(() => _imageCodec = value),
        ),
        const SizedBox(height: 12),
        _LifeSliderField(
          label: _lifeText(context, zh: '图片最长边', en: 'Image max side'),
          valueText: '${_imageMaxSide.round()} px',
          value: _imageMaxSide,
          min: 24,
          max: 144,
          divisions: 120,
          onChanged: (value) => setState(() => _imageMaxSide = value),
        ),
        if (_imageCodec == ToolboxQrImageCodec.jpeg)
          _LifeSliderField(
            label: _lifeText(context, zh: 'JPEG 质量', en: 'JPEG quality'),
            valueText: _imageJpegQuality.round().toString(),
            value: _imageJpegQuality,
            min: 24,
            max: 82,
            divisions: 58,
            onChanged: (value) => setState(() => _imageJpegQuality = value),
          ),
        const SizedBox(height: 8),
        Text(
          _lifeText(
            context,
            zh: '图片二维码化会把缩略图压成 Data URL 写入码内，只适合很小的头像、图标或签名图。',
            en: 'Image QR payload embeds a compressed thumbnail as a Data URL. Use it only for tiny avatars, icons, or signatures.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(
          _lifeText(
            context,
            zh: '导入后会自动压缩到约 ${_formatBytes(_qrImagePayloadTargetBytes)} 的二维码友好体积；超过 ${_formatBytes(_qrImageSourceReadMaxBytes)} 的超大源图仍需先裁切或压缩。',
            en: 'Imported images are auto-compressed toward a QR-friendly ${_formatBytes(_qrImagePayloadTargetBytes)} payload. Sources above ${_formatBytes(_qrImageSourceReadMaxBytes)} still need cropping or compression first.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (imageData != null) ...<Widget>[
          const SizedBox(height: 10),
          _buildQrMessage(
            context,
            _lifeText(
              context,
              zh: '${_imageSourceName ?? 'image'}：源图 ${imageData.sourceWidth}x${imageData.sourceHeight} / ${_formatBytes(imageData.sourceBytesLength)}，已压缩为 ${imageData.width}x${imageData.height} / ${_formatBytes(imageData.bytes.length)}，Data URL ${_formatBytes(imageData.dataUrlBytes)}，${imageData.compressionNote}，SHA ${imageData.sha256Short}',
              en: '${_imageSourceName ?? 'image'}: source ${imageData.sourceWidth}x${imageData.sourceHeight} / ${_formatBytes(imageData.sourceBytesLength)}, compressed to ${imageData.width}x${imageData.height} / ${_formatBytes(imageData.bytes.length)}, Data URL ${_formatBytes(imageData.dataUrlBytes)}, ${imageData.compressionNote}, SHA ${imageData.sha256Short}',
            ),
          ),
          if (imageData.dataUrlBytes > _qrImagePayloadTargetBytes) ...<Widget>[
            const SizedBox(height: 8),
            _buildQrMessage(
              context,
              _lifeText(
                context,
                zh: '已使用最小候选压缩，但仍超过建议体积。若扫码不稳定，请改用中心图模式或继续降低最长边。',
                en: 'The smallest candidate still exceeds the target payload. If scanning is unstable, use center-image mode or lower the max side.',
              ),
              isWarning: true,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStylePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '编码与样式', en: 'Encoding and style'),
      subtitle: _lifeText(
        context,
        zh: 'QR Code 支持完整样式、容错和中心图；其他二维标准保留高对比预览。',
        en: 'QR Code supports full style, error correction, and center images; other 2D standards use high-contrast previews.',
      ),
      children: <Widget>[
        _LifeSegmentedField<ToolboxQrEncodingStandard>(
          label: _lifeText(context, zh: '二维码编码标准', en: '2D code standard'),
          value: _standard,
          options: ToolboxQrEncodingStandard.values
              .map(
                (standard) => _LifeOption<ToolboxQrEncodingStandard>(
                  value: standard,
                  labelZh: standard.label,
                  labelEn: standard.label,
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _standard = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<_QrCorrectionOption>(
          label: _lifeText(context, zh: 'QR 容错等级', en: 'QR error correction'),
          value: _correction,
          options: _QrCorrectionOption.values
              .map(
                (option) => _LifeOption<_QrCorrectionOption>(
                  value: option,
                  labelZh: option.label,
                  labelEn: option.label,
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _correction = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<int>(
          label: _lifeText(context, zh: 'QR 版本快捷档', en: 'QR version quick'),
          value: _version,
          options: const <_LifeOption<int>>[
            _LifeOption<int>(
              value: QrVersions.auto,
              labelZh: '自动',
              labelEn: 'Auto',
            ),
            _LifeOption<int>(value: 10, labelZh: 'V10', labelEn: 'V10'),
            _LifeOption<int>(value: 20, labelZh: 'V20', labelEn: 'V20'),
            _LifeOption<int>(value: 25, labelZh: 'V25', labelEn: 'V25'),
            _LifeOption<int>(value: 30, labelZh: 'V30', labelEn: 'V30'),
            _LifeOption<int>(value: 40, labelZh: 'V40', labelEn: 'V40'),
          ],
          onChanged: (value) => setState(() => _version = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey<String>('life-qr-version-dropdown-$_version'),
          initialValue: _version,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(
              context,
              zh: '精确 QR 版本',
              en: 'Exact QR version',
            ),
          ),
          items: _qrVersionOptions
              .map(
                (option) => DropdownMenuItem<int>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              setState(() => _version = value);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildArtPresetPanel(context),
        const SizedBox(height: 12),
        _buildStyleChooser(context),
        SwitchListTile(
          value: _gapless,
          contentPadding: EdgeInsets.zero,
          title: Text(_lifeText(context, zh: '无缝模块', en: 'Gapless modules')),
          subtitle: Text(
            _lifeText(
              context,
              zh: '关闭后模块之间有轻微间隔，更柔和但可能降低小尺寸可扫性。',
              en: 'Disable for softer gaps between modules; small codes may scan less reliably.',
            ),
          ),
          onChanged: (value) => setState(() => _gapless = value),
        ),
        SwitchListTile(
          value: _useCenterImage,
          contentPadding: EdgeInsets.zero,
          title: Text(_lifeText(context, zh: '使用中心图', en: 'Use center image')),
          subtitle: Text(
            _logoName == null
                ? _lifeText(
                    context,
                    zh: '适合 Logo/头像叠加，不会把图片内容写入二维码。',
                    en: 'Best for logos or avatars; the image content is not encoded.',
                  )
                : _logoName!,
          ),
          onChanged: _standard == ToolboxQrEncodingStandard.qrCode
              ? (value) => setState(() => _useCenterImage = value)
              : null,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _standard == ToolboxQrEncodingStandard.qrCode
                    ? _pickLogoImage
                    : null,
                icon: const Icon(Icons.image_rounded),
                label: Text(_lifeText(context, zh: '导入中心图', en: 'Import logo')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickQrImagePayload,
                icon: const Icon(Icons.image_search_rounded),
                label: Text(
                  _lifeText(context, zh: '图片二维码化', en: 'Image to QR'),
                ),
              ),
            ),
          ],
        ),
        if (_useCenterImage && _logoBytes != null) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: '中心图尺寸', en: 'Logo size'),
            valueText: '${_logoSize.round()} px',
            value: _logoSize,
            min: 32,
            max: 88,
            divisions: 56,
            onChanged: (value) => setState(() => _logoSize = value),
          ),
        ],
        const SizedBox(height: 14),
        _buildVisualImageControls(context),
      ],
    );
  }

  Widget _buildArtPresetPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeText(context, zh: '艺术二维码预设', en: 'Art QR preset'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            _lifeText(
              context,
              zh: '弱纠错 + 大版本 + 强定位保护会给半调画像更多模块密度；抗污损能力更弱，发布前务必实机扫码。',
              en: 'Low correction + a larger version + stronger finder protection gives halftone art more module density; scan-test before publishing.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey<String>('life-qr-art-scan-preset'),
            onPressed: _applyArtScanPreset,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: Text(
              _lifeText(
                context,
                zh: '应用弱纠错定位码 V25',
                en: 'Apply low-correction V25',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualImageControls(BuildContext context) {
    final artImage = _visualImageResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('life-qr-visual-image-mode'),
          child: _LifeSegmentedField<_QrVisualImageMode>(
            label: _lifeText(context, zh: 'QArt 艺术化', en: 'QArt style'),
            value: _visualImageMode,
            options: const <_LifeOption<_QrVisualImageMode>>[
              _LifeOption<_QrVisualImageMode>(
                value: _QrVisualImageMode.none,
                labelZh: '关闭',
                labelEn: 'Off',
              ),
              _LifeOption<_QrVisualImageMode>(
                value: _QrVisualImageMode.artBlend,
                labelZh: '半调画像',
                labelEn: 'Halftone art',
              ),
              _LifeOption<_QrVisualImageMode>(
                value: _QrVisualImageMode.transparentArt,
                labelZh: '透图融合',
                labelEn: 'Transparent art',
              ),
            ],
            onChanged: (value) => setState(() => _visualImageMode = value),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _visualImageName == null
              ? _lifeText(
                  context,
                  zh: '导入图片后会自动压缩为渲染友好的艺术图，再按图片明暗重绘半调轮廓；定位角、时序线和校验信息保持高对比。',
                  en: 'Imported images are auto-compressed for rendering, then redrawn as halftone QR contours while finder patterns, timing lines, and format areas stay high contrast.',
                )
              : _visualImageName!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey<String>('life-qr-visual-image-button'),
                onPressed: _processingVisualImage ? null : _pickVisualImage,
                icon: _processingVisualImage
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _processingVisualImage
                      ? _lifeText(context, zh: '压缩中...', en: 'Compressing...')
                      : _lifeText(context, zh: '导入艺术图', en: 'Import art image'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _visualImageBytes == null
                    ? null
                    : () => setState(() {
                        _visualImageBytes = null;
                        _visualImageName = null;
                        _visualImageResult = null;
                        _visualImageMode = _QrVisualImageMode.none;
                      }),
                icon: const Icon(Icons.clear_rounded),
                label: Text(_lifeText(context, zh: '清除图片', en: 'Clear image')),
              ),
            ),
          ],
        ),
        if (artImage != null) ...<Widget>[
          const SizedBox(height: 10),
          _buildQrMessage(
            context,
            _lifeText(
              context,
              zh: '${_visualImageName ?? 'art'}：源图 ${artImage.sourceWidth}x${artImage.sourceHeight} / ${_formatBytes(artImage.sourceBytesLength)}，艺术图 ${artImage.width}x${artImage.height} / ${_formatBytes(artImage.bytes.length)}，${artImage.compressionNote}，SHA ${artImage.sha256Short}',
              en: '${_visualImageName ?? 'art'}: source ${artImage.sourceWidth}x${artImage.sourceHeight} / ${_formatBytes(artImage.sourceBytesLength)}, art image ${artImage.width}x${artImage.height} / ${_formatBytes(artImage.bytes.length)}, ${artImage.compressionNote}, SHA ${artImage.sha256Short}',
            ),
          ),
          if (artImage.bytes.length > _qrArtImageTargetBytes) ...<Widget>[
            const SizedBox(height: 8),
            _buildQrMessage(
              context,
              _lifeText(
                context,
                zh: '已自动压缩艺术图，但仍超过建议渲染体积；若预览卡顿，请先裁切源图或换更简单的图片。',
                en: 'The art image was compressed but still exceeds the rendering target; crop it or use a simpler image if preview feels slow.',
              ),
              isWarning: true,
            ),
          ],
        ],
        if (_visualImageBytes != null &&
            _visualImageMode != _QrVisualImageMode.none) ...<Widget>[
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: '可扫性保护层', en: 'Scan protection'),
            valueText: '${(_visualImageVeil * 100).round()}%',
            value: _visualImageVeil,
            min: 0.18,
            max: 0.82,
            divisions: 56,
            onChanged: (value) => setState(() => _visualImageVeil = value),
          ),
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: '图像对比强度', en: 'Image contrast'),
            valueText: '${(_artDarkness * 100).round()}%',
            value: _artDarkness,
            min: 0.30,
            max: 0.96,
            divisions: 66,
            onChanged: (value) => setState(() => _artDarkness = value),
          ),
          const SizedBox(height: 12),
          _LifeSliderField(
            label: _lifeText(context, zh: '模块留白', en: 'Module spacing'),
            valueText: '${((1 - _artModuleScale) * 100).round()}%',
            value: _artModuleScale,
            min: 0.58,
            max: 1.0,
            divisions: 42,
            onChanged: (value) => setState(() => _artModuleScale = value),
          ),
        ],
      ],
    );
  }

  Widget _buildStyleChooser(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _lifeText(context, zh: '视觉样式', en: 'Visual style'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _qrStyleSpecs
              .map((style) {
                final selected = style.id == _style.id;
                return ChoiceChip(
                  selected: selected,
                  avatar: CircleAvatar(
                    backgroundColor: style.background,
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 16,
                      color: style.foreground,
                    ),
                  ),
                  label: Text(style.label(context)),
                  onSelected: (_) => setState(() => _style = style),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(
    BuildContext context,
    ToolboxQrPayloadResult payload,
    QrValidationResult? qrValidation,
  ) {
    final theme = Theme.of(context);
    final valid = qrValidation?.isValid ?? true;
    final statusText = qrValidation == null
        ? _lifeText(
            context,
            zh: '${_standard.label} · ${_formatBytes(payload.byteLength)}',
            en: '${_standard.label} · ${_formatBytes(payload.byteLength)}',
          )
        : valid
        ? _lifeText(
            context,
            zh: 'QR V${qrValidation.qrCode?.typeNumber ?? '-'} · ${_correction.label} · ${_formatBytes(payload.byteLength)}',
            en: 'QR V${qrValidation.qrCode?.typeNumber ?? '-'} · ${_correction.label} · ${_formatBytes(payload.byteLength)}',
          )
        : _lifeText(
            context,
            zh: '当前内容超过所选版本/容错可承载范围。',
            en: 'Payload is too large for the selected version/correction.',
          );
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '预览与导出', en: 'Preview and export'),
      subtitle: statusText,
      children: <Widget>[
        Center(
          child: RepaintBoundary(
            key: _previewKey,
            child: Container(
              width: 292,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _style.panelColor ?? _style.background,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: _buildPreviewCanvas(
                  context,
                  payload.payload,
                  qrValidation,
                  valid,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              key: const ValueKey<String>('life-qr-export-button'),
              onPressed: _exporting || !valid ? null : _exportPng,
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_rounded),
              label: Text(
                _exporting
                    ? _lifeText(context, zh: '导出中...', en: 'Exporting...')
                    : _lifeText(context, zh: '导出 PNG', en: 'Export PNG'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _copyPayload,
              icon: const Icon(Icons.copy_rounded),
              label: Text(_lifeText(context, zh: '复制内容', en: 'Copy payload')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          payload.displaySummary,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (payload.warning.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _buildQrMessage(context, payload.warning, isWarning: true),
        ],
        if (!valid && qrValidation?.error != null) ...<Widget>[
          const SizedBox(height: 10),
          _buildQrMessage(context, '${qrValidation!.error}', isError: true),
        ],
      ],
    );
  }

  Widget _buildPreviewCanvas(
    BuildContext context,
    String payload,
    QrValidationResult? qrValidation,
    bool valid,
  ) {
    if (!valid) {
      return _buildCodeError(
        context,
        '${qrValidation?.error ?? 'Input too long'}',
      );
    }
    final visualBytes = _visualImageBytes;
    if (visualBytes == null || _visualImageMode == _QrVisualImageMode.none) {
      return _buildCodePreview(context, payload, qrValidation);
    }
    return _buildArtQrPreview(context, visualBytes, qrValidation);
  }

  QrValidationResult? _safeQrValidation(ToolboxQrPayloadResult payload) {
    if (_standard != ToolboxQrEncodingStandard.qrCode) {
      return null;
    }
    final result = QrValidator.validate(
      data: payload.payload,
      version: _version,
      errorCorrectionLevel: _correction.qrValue,
    );
    if (!result.isValid) {
      return result;
    }
    final qrCode = result.qrCode;
    if (qrCode == null) {
      return QrValidationResult(
        status: QrValidationStatus.error,
        error: Exception('QR validation did not return a code.'),
      );
    }
    try {
      // Force qr_flutter's lazy painter setup before the widget reaches layout.
      QrPainter.withQr(qr: qrCode);
      return result;
    } catch (error) {
      return QrValidationResult(
        status: QrValidationStatus.contentTooLong,
        error: error is Exception ? error : Exception('$error'),
      );
    }
  }

  Widget _buildArtQrPreview(
    BuildContext context,
    Uint8List visualBytes,
    QrValidationResult? qrValidation,
  ) {
    final qrCode = qrValidation?.qrCode;
    if (_standard != ToolboxQrEncodingStandard.qrCode || qrCode == null) {
      return _buildCodePreview(context, '', qrValidation);
    }
    return SizedBox.square(
      dimension: 244,
      child: CustomPaint(
        painter: _ArtQrPainter(
          qrCode: qrCode,
          imageBytes: visualBytes,
          style: _style,
          mode: _visualImageMode,
          protection: _visualImageVeil,
          tintStrength: _artDarkness,
          moduleScale: _artModuleScale,
          gapless: _gapless,
        ),
      ),
    );
  }

  Widget _buildCodePreview(
    BuildContext context,
    String payload,
    QrValidationResult? qrValidation,
  ) {
    if (_standard == ToolboxQrEncodingStandard.qrCode) {
      final qrCode = qrValidation?.qrCode;
      if (qrCode == null) {
        return _buildCodeError(context, 'QR payload is not ready.');
      }
      return QrImageView.withQr(
        qr: qrCode,
        size: 244,
        padding: const EdgeInsets.all(14),
        backgroundColor: _style.background,
        version: _version,
        errorCorrectionLevel: _correction.qrValue,
        gapless: _gapless,
        eyeStyle: QrEyeStyle(
          eyeShape: _style.eyeShape,
          color: _style.foreground,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: _style.moduleShape,
          color: _style.foreground,
        ),
        embeddedImage: _useCenterImage && _logoBytes != null
            ? MemoryImage(_logoBytes!)
            : null,
        embeddedImageStyle: QrEmbeddedImageStyle(size: Size.square(_logoSize)),
        errorStateBuilder: (context, error) =>
            _buildCodeError(context, '$error'),
      );
    }
    final height = _standard == ToolboxQrEncodingStandard.pdf417
        ? 132.0
        : 230.0;
    return Container(
      width: 244,
      height: height,
      padding: const EdgeInsets.all(12),
      color: _style.background,
      child: BarcodeWidget(
        data: payload,
        barcode: _barcodeFor(_standard),
        width: 220,
        height: height - 24,
        color: _style.foreground,
        backgroundColor: _style.background,
        drawText: false,
        errorBuilder: (context, error) => _buildCodeError(context, error),
      ),
    );
  }

  Widget _buildCodeError(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Container(
      width: 244,
      height: 180,
      padding: const EdgeInsets.all(14),
      alignment: Alignment.center,
      color: theme.colorScheme.errorContainer,
      child: Text(
        _lifeText(context, zh: '无法生成: $error', en: 'Cannot render: $error'),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Barcode _barcodeFor(ToolboxQrEncodingStandard standard) {
    return switch (standard) {
      ToolboxQrEncodingStandard.qrCode => Barcode.qrCode(),
      ToolboxQrEncodingStandard.dataMatrix => Barcode.dataMatrix(),
      ToolboxQrEncodingStandard.aztec => Barcode.aztec(),
      ToolboxQrEncodingStandard.pdf417 => Barcode.pdf417(),
    };
  }

  Widget _buildBoundaryPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '扫码兼容提示', en: 'Scan compatibility'),
      subtitle: _lifeText(
        context,
        zh: '不同扫码器对 Wi-Fi、日历、联系人和非 QR 标准支持不同。',
        en: 'Scanner support varies for Wi-Fi, calendar, contact, and non-QR standards.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '图片二维码化并不适合大图传输。若只是想带品牌头像，请用中心图；若要把图片内容写入码内，请控制在小尺寸并实测可扫性。',
            en: 'Image Data URL QR is not for large image transfer. Use center image for branding; if you embed image content, keep it tiny and test scanning.',
          ),
        ),
      ],
    );
  }

  Widget _buildQrMessage(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    final color = isError
        ? theme.colorScheme.error
        : isWarning
        ? Colors.orange
        : theme.colorScheme.tertiary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(message, style: theme.textTheme.bodySmall),
    );
  }

  Widget _textInput(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    );
  }

  String _payloadLabel(ToolboxQrPayloadType type) {
    return switch (type) {
      ToolboxQrPayloadType.text => _lifeText(context, zh: '文本', en: 'Text'),
      ToolboxQrPayloadType.url => 'URL',
      ToolboxQrPayloadType.wifi => 'Wi-Fi',
      ToolboxQrPayloadType.contact => _lifeText(
        context,
        zh: '联系人',
        en: 'Contact',
      ),
      ToolboxQrPayloadType.email => _lifeText(context, zh: '邮件', en: 'Email'),
      ToolboxQrPayloadType.sms => _lifeText(context, zh: '短信', en: 'SMS'),
      ToolboxQrPayloadType.phone => _lifeText(context, zh: '电话', en: 'Phone'),
      ToolboxQrPayloadType.geo => _lifeText(context, zh: '地理位置', en: 'Geo'),
      ToolboxQrPayloadType.calendar => _lifeText(
        context,
        zh: '日历',
        en: 'Calendar',
      ),
      ToolboxQrPayloadType.imageDataUrl => _lifeText(
        context,
        zh: '图片内容',
        en: 'Image payload',
      ),
    };
  }

  String _formatShortDateTime(DateTime value) {
    String two(int raw) => raw.toString().padLeft(2, '0');
    return '${value.month}/${value.day} ${two(value.hour)}:${two(value.minute)}';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

@immutable
class _QrImageEncodeRequest {
  const _QrImageEncodeRequest(
    this.sourceBytes,
    this.maxSide,
    this.jpegQuality,
    this.codec,
    this.targetDataUrlBytes,
  );

  final Uint8List sourceBytes;
  final int maxSide;
  final int jpegQuality;
  final ToolboxQrImageCodec codec;
  final int targetDataUrlBytes;
}

ToolboxQrImageDataResult _encodeQrImageDataUrl(_QrImageEncodeRequest request) {
  return ToolboxQrService.encodeImageToDataUrl(
    request.sourceBytes,
    maxSide: request.maxSide,
    jpegQuality: request.jpegQuality,
    codec: request.codec,
    targetDataUrlBytes: request.targetDataUrlBytes,
  );
}

@immutable
class _QrArtImageEncodeRequest {
  const _QrArtImageEncodeRequest(
    this.sourceBytes,
    this.maxSide,
    this.jpegQuality,
    this.targetBytes,
  );

  final Uint8List sourceBytes;
  final int maxSide;
  final int jpegQuality;
  final int targetBytes;
}

ToolboxQrArtImageResult _prepareQrArtImage(_QrArtImageEncodeRequest request) {
  return ToolboxQrService.prepareArtImage(
    request.sourceBytes,
    maxSide: request.maxSide,
    jpegQuality: request.jpegQuality,
    targetBytes: request.targetBytes,
  );
}

const List<List<int>> _qrAlignmentPatternPositions = <List<int>>[
  <int>[],
  <int>[6, 18],
  <int>[6, 22],
  <int>[6, 26],
  <int>[6, 30],
  <int>[6, 34],
  <int>[6, 22, 38],
  <int>[6, 24, 42],
  <int>[6, 26, 46],
  <int>[6, 28, 50],
  <int>[6, 30, 54],
  <int>[6, 32, 58],
  <int>[6, 34, 62],
  <int>[6, 26, 46, 66],
  <int>[6, 26, 48, 70],
  <int>[6, 26, 50, 74],
  <int>[6, 30, 54, 78],
  <int>[6, 30, 56, 82],
  <int>[6, 30, 58, 86],
  <int>[6, 34, 62, 90],
  <int>[6, 28, 50, 72, 94],
  <int>[6, 26, 50, 74, 98],
  <int>[6, 30, 54, 78, 102],
  <int>[6, 28, 54, 80, 106],
  <int>[6, 32, 58, 84, 110],
  <int>[6, 30, 58, 86, 114],
  <int>[6, 34, 62, 90, 118],
  <int>[6, 26, 50, 74, 98, 122],
  <int>[6, 30, 54, 78, 102, 126],
  <int>[6, 26, 52, 78, 104, 130],
  <int>[6, 30, 56, 82, 108, 134],
  <int>[6, 34, 60, 86, 112, 138],
  <int>[6, 30, 58, 86, 114, 142],
  <int>[6, 34, 62, 90, 118, 146],
  <int>[6, 30, 54, 78, 102, 126, 150],
  <int>[6, 24, 50, 76, 102, 128, 154],
  <int>[6, 28, 54, 80, 106, 132, 158],
  <int>[6, 32, 58, 84, 110, 136, 162],
  <int>[6, 26, 54, 82, 110, 138, 166],
  <int>[6, 30, 58, 86, 114, 142, 170],
];

const List<List<double>> _qrArtBayer4 = <List<double>>[
  <double>[0, 8, 2, 10],
  <double>[12, 4, 14, 6],
  <double>[3, 11, 1, 9],
  <double>[15, 7, 13, 5],
];

class _ArtQrPainter extends CustomPainter {
  _ArtQrPainter({
    required this.qrCode,
    required this.imageBytes,
    required this.style,
    required this.mode,
    required this.protection,
    required this.tintStrength,
    required this.moduleScale,
    required this.gapless,
  }) : _image = QrImage(qrCode),
       _source = _decodeSource(imageBytes);

  final QrCode qrCode;
  final Uint8List imageBytes;
  final _QrStyleSpec style;
  final _QrVisualImageMode mode;
  final double protection;
  final double tintStrength;
  final double moduleScale;
  final bool gapless;
  final QrImage _image;
  final img.Image? _source;

  static img.Image? _decodeSource(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    return decoded == null ? null : img.bakeOrientation(decoded);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final source = _source;
    final backgroundPaint = Paint()..color = style.background;
    canvas.drawRect(Offset.zero & size, backgroundPaint);
    final moduleCount = qrCode.moduleCount;
    final quiet = 4.0;
    final cell = size.shortestSide / (moduleCount + quiet * 2);
    final inset = cell * quiet;
    final artRect = Rect.fromLTWH(
      inset,
      inset,
      cell * moduleCount,
      cell * moduleCount,
    );
    if (source != null) {
      _paintHalftoneBackdrop(canvas, artRect, source);
    }
    _paintArtModules(canvas, artRect, source);
  }

  void _paintHalftoneBackdrop(Canvas canvas, Rect rect, img.Image source) {
    final moduleCount = qrCode.moduleCount;
    final cell = rect.width / moduleCount;
    final imageWeight = mode == _QrVisualImageMode.transparentArt ? 0.70 : 0.52;
    final protectionWeight = protection.clamp(0.0, 1.0) * 0.34;
    final paint = Paint();
    for (var row = 0; row < moduleCount; row += 1) {
      for (var col = 0; col < moduleCount; col += 1) {
        final centerX = (col + 0.5) / moduleCount;
        final centerY = (row + 0.5) / moduleCount;
        final sampled = _sampleColor(source, centerX, centerY);
        final tone = _luminance(sampled);
        final edge = _edgeStrength(source, centerX, centerY);
        final ink = _imageInk(tone, edge, col, row);
        final backdrop = _backdropColor(sampled, ink);
        paint.color =
            Color.lerp(
              style.background,
              backdrop,
              (imageWeight - protectionWeight).clamp(0.14, 0.76),
            ) ??
            backdrop;
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + col * cell,
            rect.top + row * cell,
            cell + 0.35,
            cell + 0.35,
          ),
          paint,
        );
      }
    }
  }

  void _paintArtModules(Canvas canvas, Rect rect, img.Image? source) {
    final moduleCount = qrCode.moduleCount;
    final cell = rect.width / moduleCount;
    for (var row = 0; row < moduleCount; row += 1) {
      for (var col = 0; col < moduleCount; col += 1) {
        final dark = _image.isDark(row, col);
        final moduleRect = Rect.fromLTWH(
          rect.left + col * cell,
          rect.top + row * cell,
          cell + (gapless ? 0.35 : 0),
          cell + (gapless ? 0.35 : 0),
        );
        if (_isFunctionModule(col, row, moduleCount)) {
          _paintFunctionModule(canvas, moduleRect, dark);
          continue;
        }

        final centerX = (col + 0.5) / moduleCount;
        final centerY = (row + 0.5) / moduleCount;
        final sampled = source == null
            ? style.foreground
            : _sampleColor(source, centerX, centerY);
        final tone = _luminance(sampled);
        final edge = source == null
            ? 0.0
            : _edgeStrength(source, centerX, centerY);
        final ink = _imageInk(tone, edge, col, row);
        if (dark) {
          final paint = Paint()..color = _moduleInkColor(sampled, ink);
          final scale = _darkModuleScale(ink);
          _drawDataModule(
            canvas,
            _centeredRect(moduleRect, scale),
            paint,
            cell,
          );
        } else {
          _paintLightArtDetail(canvas, moduleRect, sampled, ink, cell);
        }
      }
    }
  }

  void _paintFunctionModule(Canvas canvas, Rect rect, bool dark) {
    final paint = Paint()..color = dark ? style.foreground : style.background;
    canvas.drawRect(rect.inflate(0.2), paint);
  }

  void _paintLightArtDetail(
    Canvas canvas,
    Rect moduleRect,
    Color sampled,
    double ink,
    double cell,
  ) {
    final threshold = mode == _QrVisualImageMode.transparentArt ? 0.72 : 0.58;
    final ditherAllowance =
        _orderedDither(
          (moduleRect.left / cell).floor(),
          (moduleRect.top / cell).floor(),
        ) *
        0.18;
    if (ink < threshold + ditherAllowance || protection > 0.78) {
      return;
    }
    final alphaBase = mode == _QrVisualImageMode.transparentArt ? 0.13 : 0.20;
    final alpha =
        alphaBase *
        (1.0 - protection.clamp(0.0, 1.0) * 0.54) *
        tintStrength.clamp(0.0, 1.0);
    if (alpha <= 0.025) {
      return;
    }
    final scale =
        ui.lerpDouble(0.16, 0.44, ink.clamp(0.0, 1.0))! *
        (1.0 - protection.clamp(0.0, 1.0) * 0.26);
    final paint = Paint()
      ..color = _darkened(sampled, 1).withValues(alpha: alpha);
    _drawDataModule(canvas, _centeredRect(moduleRect, scale), paint, cell);
  }

  void _drawDataModule(Canvas canvas, Rect rect, Paint paint, double cell) {
    if (style.moduleShape == QrDataModuleShape.circle) {
      canvas.drawOval(rect, paint);
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16)),
      paint,
    );
  }

  Rect _centeredRect(Rect rect, double scale) {
    final clamped = scale.clamp(0.08, 1.08);
    final side = math.min(rect.width, rect.height) * clamped;
    return Rect.fromCenter(center: rect.center, width: side, height: side);
  }

  double _darkModuleScale(double ink) {
    final safeFloor = ui.lerpDouble(0.50, 0.72, protection.clamp(0.0, 1.0))!;
    final visualCeil = ui.lerpDouble(
      moduleScale.clamp(0.58, 1.0) * 0.92,
      gapless ? 1.04 : 0.94,
      ink.clamp(0.0, 1.0),
    )!;
    final contrastBoost = (tintStrength.clamp(0.0, 1.0) - 0.5) * 0.08;
    return math.max(safeFloor, visualCeil + contrastBoost).clamp(0.44, 1.06);
  }

  Color _backdropColor(Color color, double ink) {
    final backgroundLight = _luminance(style.background);
    final hsl = HSLColor.fromColor(color);
    if (backgroundLight < 0.5) {
      final lightness = ui.lerpDouble(0.12, 0.34, ink.clamp(0.0, 1.0))!;
      return hsl
          .withLightness(lightness.clamp(0.08, 0.42))
          .withSaturation((hsl.saturation * 0.72).clamp(0.0, 0.72))
          .toColor();
    }
    final lightness = ui.lerpDouble(0.94, 0.42, ink.clamp(0.0, 1.0))!;
    return hsl
        .withLightness(lightness.clamp(0.36, 0.96))
        .withSaturation((hsl.saturation * 0.58).clamp(0.0, 0.68))
        .toColor();
  }

  Color _moduleInkColor(Color sampled, double ink) {
    final sampledInk = _darkened(sampled, tintStrength);
    final mix = ui.lerpDouble(0.40, 0.72, ink.clamp(0.0, 1.0))!;
    return Color.lerp(style.foreground, sampledInk, mix) ?? sampledInk;
  }

  Color _sampleColor(img.Image source, double dx, double dy) {
    final point = _coverPoint(source, dx, dy);
    final x = point.dx.round().clamp(0, source.width - 1);
    final y = point.dy.round().clamp(0, source.height - 1);
    final pixel = source.getPixel(x, y);
    return Color.fromARGB(
      pixel.a.toInt(),
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  Offset _coverPoint(img.Image source, double dx, double dy) {
    final targetAspect = 1.0;
    final sourceAspect = source.width / source.height;
    var left = 0.0;
    var top = 0.0;
    var width = source.width.toDouble();
    var height = source.height.toDouble();
    if (sourceAspect > targetAspect) {
      width = source.height * targetAspect;
      left = (source.width - width) / 2;
    } else if (sourceAspect < targetAspect) {
      height = source.width / targetAspect;
      top = (source.height - height) / 2;
    }
    return Offset(
      left + dx.clamp(0.0, 1.0) * (width - 1),
      top + dy.clamp(0.0, 1.0) * (height - 1),
    );
  }

  double _edgeStrength(img.Image source, double dx, double dy) {
    final step = (1 / qrCode.moduleCount) * 0.72;
    final left = _luminance(_sampleColor(source, dx - step, dy));
    final right = _luminance(_sampleColor(source, dx + step, dy));
    final top = _luminance(_sampleColor(source, dx, dy - step));
    final bottom = _luminance(_sampleColor(source, dx, dy + step));
    return ((left - right).abs() + (top - bottom).abs()).clamp(0.0, 1.0);
  }

  double _imageInk(double tone, double edge, int x, int y) {
    final contrast = tintStrength.clamp(0.0, 1.0);
    final darkMass = math.pow(1 - tone.clamp(0.0, 1.0), 0.78).toDouble();
    final thresholdNoise = (0.5 - _orderedDither(x, y)) * 0.18;
    final fineNoise = (_hashNoise(x, y) - 0.5) * 0.08;
    return (darkMass * (0.70 + contrast * 0.28) +
            edge * (0.22 + contrast * 0.20) +
            thresholdNoise +
            fineNoise)
        .clamp(0.0, 1.0);
  }

  double _orderedDither(int x, int y) {
    return (_qrArtBayer4[y & 3][x & 3] + 0.5) / 16.0;
  }

  double _hashNoise(int x, int y) {
    final raw =
        (x * 374761393) ^ (y * 668265263) ^ (qrCode.typeNumber * 1442695041);
    final mixed = (raw ^ (raw >> 13) ^ (raw >> 17)) & 0x3ff;
    return mixed / 1023.0;
  }

  double _luminance(Color color) {
    final raw = color.toARGB32();
    final r = ((raw >> 16) & 0xff) / 255.0;
    final g = ((raw >> 8) & 0xff) / 255.0;
    final b = (raw & 0xff) / 255.0;
    return (0.2126 * r + 0.7152 * g + 0.0722 * b).clamp(0.0, 1.0);
  }

  Color _darkened(Color color, double strength) {
    final hsl = HSLColor.fromColor(color);
    final foregroundLight = _luminance(style.foreground);
    final backgroundLight = _luminance(style.background);
    final foregroundIsLight = foregroundLight > backgroundLight;
    final targetLightness = foregroundIsLight
        ? (mode == _QrVisualImageMode.transparentArt ? 0.86 : 0.78)
        : (mode == _QrVisualImageMode.transparentArt ? 0.18 : 0.10);
    final lightness =
        ui.lerpDouble(
          hsl.lightness,
          targetLightness,
          strength.clamp(0.0, 1.0),
        ) ??
        targetLightness;
    final saturation = math.min(1.0, hsl.saturation + 0.22);
    return hsl
        .withLightness(
          foregroundIsLight
              ? lightness.clamp(0.62, 0.96)
              : lightness.clamp(0.04, 0.34),
        )
        .withSaturation(saturation)
        .toColor();
  }

  bool _isFunctionModule(int x, int y, int moduleCount) {
    return _isFinderGuard(x, y, moduleCount) ||
        _isTimingPattern(x, y, moduleCount) ||
        _isAlignmentPattern(x, y, moduleCount) ||
        _isFormatInfo(x, y, moduleCount) ||
        _isVersionInfo(x, y, moduleCount);
  }

  bool _isFinderGuard(int x, int y, int moduleCount) {
    final inTopLeft = x <= 8 && y <= 8;
    final inTopRight = x >= moduleCount - 8 && y <= 8;
    final inBottomLeft = x <= 8 && y >= moduleCount - 8;
    return inTopLeft || inTopRight || inBottomLeft;
  }

  bool _isTimingPattern(int x, int y, int moduleCount) {
    return (x == 6 && y >= 8 && y < moduleCount - 8) ||
        (y == 6 && x >= 8 && x < moduleCount - 8);
  }

  bool _isFormatInfo(int x, int y, int moduleCount) {
    return (y == 8 && (x <= 8 || x >= moduleCount - 8)) ||
        (x == 8 && (y <= 8 || y >= moduleCount - 7)) ||
        (x == 8 && y == moduleCount - 8);
  }

  bool _isVersionInfo(int x, int y, int moduleCount) {
    if (qrCode.typeNumber < 7) {
      return false;
    }
    final topRight = y < 6 && x >= moduleCount - 11 && x <= moduleCount - 9;
    final bottomLeft = x < 6 && y >= moduleCount - 11 && y <= moduleCount - 9;
    return topRight || bottomLeft;
  }

  bool _isAlignmentPattern(int x, int y, int moduleCount) {
    final version = qrCode.typeNumber;
    if (version < 2 || version > _qrAlignmentPatternPositions.length) {
      return false;
    }
    final positions = _qrAlignmentPatternPositions[version - 1];
    for (final centerY in positions) {
      for (final centerX in positions) {
        if (_isFinderGuard(centerX, centerY, moduleCount)) {
          continue;
        }
        if ((x - centerX).abs() <= 2 && (y - centerY).abs() <= 2) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _ArtQrPainter oldDelegate) {
    return oldDelegate.qrCode != qrCode ||
        oldDelegate.imageBytes != imageBytes ||
        oldDelegate.style != style ||
        oldDelegate.mode != mode ||
        oldDelegate.protection != protection ||
        oldDelegate.tintStrength != tintStrength ||
        oldDelegate.moduleScale != moduleScale ||
        oldDelegate.gapless != gapless;
  }
}

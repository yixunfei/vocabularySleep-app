part of '../toolbox_life_tools.dart';

class _ImageToWebToolPage extends StatefulWidget {
  const _ImageToWebToolPage();

  @override
  State<_ImageToWebToolPage> createState() => _ImageToWebToolPageState();
}

class _ImageToWebToolPageState extends State<_ImageToWebToolPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _altController = TextEditingController();

  String? _sourceName;
  Uint8List? _sourceBytes;
  ui.Image? _preview;
  String? _html;
  String? _savedPath;
  ToolboxImageToWebUploadResult? _uploadResult;
  ToolboxImageToWebFit _fit = ToolboxImageToWebFit.contain;
  ToolboxImageToWebBackground _background = ToolboxImageToWebBackground.light;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _preview?.dispose();
    _titleController.dispose();
    _altController.dispose();
    super.dispose();
  }

  bool get _hasSource => _sourceBytes != null && _preview != null;
  bool get _hasHtml => _html != null && _html!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '图片转网页', en: 'Image to webpage'),
      subtitle: _lifeText(
        context,
        zh: '把本地图片封装成单文件 HTML 预览页，也可上传原图到 Uguu 获取 3 小时临时分享链接。',
        en: 'Wrap a local image into a single-file HTML page, or upload the image to Uguu for a temporary 3-hour share link.',
      ),
      child: Column(
        key: const ValueKey<String>('life-image-to-web-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStagePanel(context),
          const SizedBox(height: 12),
          _buildConfigPanel(context),
          const SizedBox(height: 12),
          _buildLocalExportPanel(context),
          const SizedBox(height: 12),
          _buildUploadPanel(context),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildErrorPanel(context),
          ],
          const SizedBox(height: 12),
          _buildBoundaryPanel(context),
        ],
      ),
    );
  }

  Widget _buildStagePanel(BuildContext context) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '图片舞台', en: 'Image stage'),
      subtitle: _lifeText(
        context,
        zh: '先选择图片，再生成可离线打开的单文件网页。',
        en: 'Pick an image first, then generate an offline single-file page.',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_image_to_web_pick_button'),
                onPressed: _uploading || _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_lifeText(context, zh: '选择图片', en: 'Pick image')),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
              onPressed: _uploading || _saving ? null : _reset,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: !_hasSource
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _ImageToWebMetricChip(
                          label: _lifeText(context, zh: '原图尺寸', en: 'Image'),
                          value: '${_preview!.width}x${_preview!.height}',
                        ),
                        _ImageToWebMetricChip(
                          label: _lifeText(context, zh: '文件大小', en: 'Size'),
                          value: _formatBytes(_sourceBytes!.length),
                        ),
                        _ImageToWebMetricChip(
                          label: _lifeText(context, zh: 'HTML 体积', en: 'HTML'),
                          value: _hasHtml
                              ? _formatBytes(utf8.encode(_html!).length)
                              : '--',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 260),
                        color: _stagePreviewColor(theme),
                        child: RawImage(image: _preview, fit: BoxFit.contain),
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
      title: _lifeText(context, zh: '网页配置', en: 'Page settings'),
      subtitle: _lifeText(
        context,
        zh: '标题和替代文本会写入生成的 HTML，适合分享给浏览器直接打开。',
        en: 'Title and alt text are written into the generated HTML for browser viewing.',
      ),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('life_image_to_web_title_field'),
          controller: _titleController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '网页标题', en: 'Page title'),
          ),
          onChanged: (_) => _regenerateHtml(),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey<String>('life_image_to_web_alt_field'),
          controller: _altController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '图片替代文本', en: 'Image alt text'),
          ),
          onChanged: (_) => _regenerateHtml(),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxImageToWebFit>(
          label: _lifeText(context, zh: '图片适配', en: 'Image fit'),
          value: _fit,
          options: const <_LifeOption<ToolboxImageToWebFit>>[
            _LifeOption<ToolboxImageToWebFit>(
              value: ToolboxImageToWebFit.contain,
              labelZh: '完整显示',
              labelEn: 'Contain',
            ),
            _LifeOption<ToolboxImageToWebFit>(
              value: ToolboxImageToWebFit.cover,
              labelZh: '封面裁切',
              labelEn: 'Cover',
            ),
            _LifeOption<ToolboxImageToWebFit>(
              value: ToolboxImageToWebFit.natural,
              labelZh: '自然尺寸',
              labelEn: 'Natural',
            ),
          ],
          onChanged: (value) {
            setState(() => _fit = value);
            _regenerateHtml();
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxImageToWebBackground>(
          label: _lifeText(context, zh: '背景', en: 'Background'),
          value: _background,
          options: const <_LifeOption<ToolboxImageToWebBackground>>[
            _LifeOption<ToolboxImageToWebBackground>(
              value: ToolboxImageToWebBackground.light,
              labelZh: '浅色',
              labelEn: 'Light',
            ),
            _LifeOption<ToolboxImageToWebBackground>(
              value: ToolboxImageToWebBackground.dark,
              labelZh: '深色',
              labelEn: 'Dark',
            ),
            _LifeOption<ToolboxImageToWebBackground>(
              value: ToolboxImageToWebBackground.checker,
              labelZh: '棋盘格',
              labelEn: 'Checker',
            ),
          ],
          onChanged: (value) {
            setState(() => _background = value);
            _regenerateHtml();
          },
        ),
      ],
    );
  }

  Widget _buildLocalExportPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '本地网页', en: 'Local webpage'),
      subtitle: _lifeText(
        context,
        zh: 'HTML 内嵌 Base64 图片，不依赖网络；大图会让 HTML 体积明显变大。',
        en: 'The HTML embeds the image as Base64 and works offline; large images make the HTML much bigger.',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>(
                  'life_image_to_web_save_html_button',
                ),
                onPressed: _hasHtml && !_saving && !_uploading
                    ? _saveHtml
                    : null,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_alt_rounded),
                label: Text(
                  _saving
                      ? _lifeText(context, zh: '保存中...', en: 'Saving...')
                      : _lifeText(context, zh: '保存 HTML', en: 'Save HTML'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              key: const ValueKey<String>('life_image_to_web_copy_html_button'),
              tooltip: _lifeText(context, zh: '复制 HTML', en: 'Copy HTML'),
              onPressed: _hasHtml ? () => _copyText(_html!, 'HTML') : null,
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
        if (_savedPath != null) ...<Widget>[
          const SizedBox(height: 10),
          SelectableText(
            _lifeText(
              context,
              zh: '保存位置: $_savedPath',
              en: 'Saved to: $_savedPath',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadPanel(BuildContext context) {
    final result = _uploadResult;
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '临时图片分享', en: 'Temporary image share'),
      subtitle: _lifeText(
        context,
        zh: '上传原图到 Uguu，生成公开临时链接。请不要上传证件、隐私或敏感图片。',
        en: 'Upload the original image to Uguu for a public temporary link. Do not upload ID, private, or sensitive images.',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_image_to_web_upload_button'),
                onPressed: _hasSource && !_saving && !_uploading
                    ? _uploadToUguu
                    : null,
                icon: _uploading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _uploading
                      ? _lifeText(context, zh: '上传中...', en: 'Uploading...')
                      : _lifeText(
                          context,
                          zh: '上传到 Uguu',
                          en: 'Upload to Uguu',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              key: const ValueKey<String>('life_image_to_web_copy_url_button'),
              tooltip: _lifeText(context, zh: '复制链接', en: 'Copy link'),
              onPressed: result == null
                  ? null
                  : () => _copyText(result.url.toString(), 'URL'),
              icon: const Icon(Icons.link_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '打开链接', en: 'Open link'),
              onPressed: result == null
                  ? null
                  : () => _openExternal(context, result.url.toString()),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: result == null
              ? Text(
                  _lifeText(
                    context,
                    zh: '上传后会在这里显示临时链接。',
                    en: 'The temporary link will appear here after upload.',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SelectableText(result.url.toString()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (result.name.isNotEmpty)
                          _ImageToWebMetricChip(
                            label: _lifeText(context, zh: '文件名', en: 'Name'),
                            value: result.name,
                          ),
                        if (result.sizeBytes != null)
                          _ImageToWebMetricChip(
                            label: _lifeText(context, zh: '上传大小', en: 'Size'),
                            value: _formatBytes(result.sizeBytes!),
                          ),
                        _ImageToWebMetricChip(
                          label: _lifeText(context, zh: '有效期', en: 'TTL'),
                          value: _lifeText(context, zh: '约 3 小时', en: '~3h'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildErrorPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _error ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _buildBoundaryPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '使用边界', en: 'Boundary'),
      subtitle: _lifeText(
        context,
        zh: '本地 HTML 不会上传图片；Uguu 分享是第三方公开临时链接，公开站 FAQ 当前声明约 3 小时后删除，并会保留活动文件数据库记录到过期。',
        en: 'Local HTML generation does not upload the image. Uguu sharing is a third-party public temporary link; its FAQ currently states deletion after about 3 hours and active-file database records until expiry.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '若需要长期托管网页，请使用正式对象存储或静态站点服务；本工具更适合临时预览、转发和轻量展示。',
            en: 'For long-term hosting, use real object storage or a static-site service. This tool is meant for temporary preview, forwarding, and lightweight display.',
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: true,
      );
      final file = picked?.files.isNotEmpty == true
          ? picked!.files.first
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
      final oldPreview = _preview;
      setState(() {
        _sourceName = file.name;
        _sourceBytes = Uint8List.fromList(bytes);
        _preview = preview;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = path.basenameWithoutExtension(file.name);
        }
        if (_altController.text.trim().isEmpty) {
          _altController.text = file.name;
        }
        _savedPath = null;
        _uploadResult = null;
        _error = null;
      });
      oldPreview?.dispose();
      _regenerateHtml();
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

  Future<ui.Image> _decodePreview(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _regenerateHtml() {
    final bytes = _sourceBytes;
    final preview = _preview;
    if (bytes == null || preview == null) {
      return;
    }
    final html = ToolboxImageToWebService.buildHtml(
      ToolboxImageToWebRequest(
        imageBytes: bytes,
        fileName: _sourceName ?? 'image.png',
        width: preview.width,
        height: preview.height,
        title: _titleController.text,
        altText: _altController.text,
        fit: _fit,
        background: _background,
      ),
    );
    if (mounted) {
      setState(() => _html = html);
    }
  }

  Future<void> _saveHtml() async {
    final html = _html;
    if (html == null) {
      return;
    }
    setState(() {
      _saving = true;
      _savedPath = null;
      _error = null;
    });
    try {
      final bytes = Uint8List.fromList(utf8.encode(html));
      final fileName = ToolboxImageToWebService.suggestedHtmlFileName(
        _sourceName ?? 'image',
      );
      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: _lifeText(
            context,
            zh: '保存图片网页',
            en: 'Save image webpage',
          ),
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const <String>['html'],
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
          path.join(appDir.path, 'life_tools', 'image_to_web'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fallback = File(
          path.join(
            exportDir.path,
            '${path.basenameWithoutExtension(fileName)}_$timestamp.html',
          ),
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
          zh: '保存 HTML 失败: $error',
          en: 'Failed to save HTML: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _uploadToUguu() async {
    final bytes = _sourceBytes;
    if (bytes == null) {
      return;
    }
    setState(() {
      _uploading = true;
      _uploadResult = null;
      _error = null;
    });
    try {
      final result = await ToolboxImageToWebService.uploadToUguu(
        imageBytes: bytes,
        fileName: _sourceName ?? 'image.png',
      );
      if (!mounted) {
        return;
      }
      setState(() => _uploadResult = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '上传失败: $error',
          en: 'Upload failed: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeText(context, zh: '已复制 $label', en: '$label copied'),
        ),
      ),
    );
  }

  void _reset() {
    final oldPreview = _preview;
    setState(() {
      _sourceName = null;
      _sourceBytes = null;
      _preview = null;
      _html = null;
      _savedPath = null;
      _uploadResult = null;
      _error = null;
      _titleController.clear();
      _altController.clear();
    });
    oldPreview?.dispose();
  }

  Color _stagePreviewColor(ThemeData theme) {
    return switch (_background) {
      ToolboxImageToWebBackground.light => theme.colorScheme.surface,
      ToolboxImageToWebBackground.dark => const Color(0xFF151923),
      ToolboxImageToWebBackground.checker =>
        theme.colorScheme.surfaceContainerHighest,
    };
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
}

class _ImageToWebMetricChip extends StatelessWidget {
  const _ImageToWebMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

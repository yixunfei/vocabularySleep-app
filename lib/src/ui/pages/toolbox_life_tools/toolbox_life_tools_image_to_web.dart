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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_to_webpage.1ddd6465ce87',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.wrap_a_local_image_into_a_single_fil.41c4df832745',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_stage.77dcc9325097',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pick_an_image_first_then_generate_an.582435b25277',
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_image_to_web_pick_button'),
                onPressed: _uploading || _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.pick_image.9ce43eb388b3',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan294.zen_sand.clear_ea17218b',
              ),
              onPressed: _uploading || _saving ? null : _reset,
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifePreviewFrame(
          child: !_hasSource
              ? Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.no_image_selected_yet.1d4a4b1c698c',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sourceName ??
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.unnamed_image.e89ca462aeab',
                          ),
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
                          label: _lifeI18nText(
                            context,
                            'inline.plan295.life.image.81cbdc5d8b60',
                          ),
                          value: '${_preview!.width}x${_preview!.height}',
                        ),
                        _ImageToWebMetricChip(
                          label: _lifeI18nText(
                            context,
                            'inline.plan295.life.size.5d3d989d937b',
                          ),
                          value: _formatBytes(_sourceBytes!.length),
                        ),
                        _ImageToWebMetricChip(
                          label: _lifeI18nText(
                            context,
                            'inline.plan295.life.html.f7a0fb516649',
                          ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.page_settings.12acbc180e4d',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.title_and_alt_text_are_written_into.026104732106',
      ),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('life_image_to_web_title_field'),
          controller: _titleController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.page_title.febb78bb6738',
            ),
          ),
          onChanged: (_) => _regenerateHtml(),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey<String>('life_image_to_web_alt_field'),
          controller: _altController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.image_alt_text.dd0c788e0911',
            ),
          ),
          onChanged: (_) => _regenerateHtml(),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxImageToWebFit>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.image_fit.c7dc99a73afc',
          ),
          value: _fit,
          options: const <_LifeOption<ToolboxImageToWebFit>>[
            _LifeOption<ToolboxImageToWebFit>(
              value: ToolboxImageToWebFit.contain,
              labelKey: 'inline.plan295.life.contain.2824f148c19d',
            ),
            _LifeOption<ToolboxImageToWebFit>(
              value: ToolboxImageToWebFit.cover,
              labelKey: 'inline.plan295.life.cover.5a87ca6b52d1',
            ),
            _LifeOption<ToolboxImageToWebFit>(
              value: ToolboxImageToWebFit.natural,
              labelKey: 'inline.plan295.life.natural.aea6b49dc498',
            ),
          ],
          onChanged: (value) {
            setState(() => _fit = value);
            _regenerateHtml();
          },
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxImageToWebBackground>(
          label: _lifeI18nText(context, 'appearanceBackgroundTitle'),
          value: _background,
          options: const <_LifeOption<ToolboxImageToWebBackground>>[
            _LifeOption<ToolboxImageToWebBackground>(
              value: ToolboxImageToWebBackground.light,
              labelKey: 'inline.plan295.life.light.91610509632d',
            ),
            _LifeOption<ToolboxImageToWebBackground>(
              value: ToolboxImageToWebBackground.dark,
              labelKey: 'ref.themeDark',
            ),
            _LifeOption<ToolboxImageToWebBackground>(
              value: ToolboxImageToWebBackground.checker,
              labelKey: 'inline.plan295.life.checker.b9325f7ccf0f',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.local_webpage.8d183d9c6bcc',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.the_html_embeds_the_image_as_base64.b630a7869b05',
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
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.saving.2c9b4d88c6ff',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.life.save_html.879e0d010a21',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              key: const ValueKey<String>('life_image_to_web_copy_html_button'),
              tooltip: _lifeI18nText(
                context,
                'inline.plan295.life.copy_html.a04d80ff229f',
              ),
              onPressed: _hasHtml ? () => _copyText(_html!, 'HTML') : null,
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
        if (_savedPath != null) ...<Widget>[
          const SizedBox(height: 10),
          SelectableText(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.to.web.saved_to.a70708f829',
              params: <String, Object?>{'_savedPath': _savedPath},
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadPanel(BuildContext context) {
    final result = _uploadResult;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.temporary_image_share.b03d76d0fb35',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.upload_the_original_image_to_uguu_fo.919ddfc0a29f',
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
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.uploading.b78f7ab33897',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.life.upload_to_uguu.553b40a7c339',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              key: const ValueKey<String>('life_image_to_web_copy_url_button'),
              tooltip: _lifeI18nText(
                context,
                'inline.plan295.life.copy_link.6782e0d873b9',
              ),
              onPressed: result == null
                  ? null
                  : () => _copyText(result.url.toString(), 'URL'),
              icon: const Icon(Icons.link_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan295.life.open_link.94c87d5b803d',
              ),
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
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.the_temporary_link_will_appear_here.a2dbbb207867',
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
                            label: _lifeI18nText(
                              context,
                              'inline.plan295.life.name.160a4094139f',
                            ),
                            value: result.name,
                          ),
                        if (result.sizeBytes != null)
                          _ImageToWebMetricChip(
                            label: _lifeI18nText(
                              context,
                              'inline.plan295.life.size.7850a09793a0',
                            ),
                            value: _formatBytes(result.sizeBytes!),
                          ),
                        _ImageToWebMetricChip(
                          label: _lifeI18nText(
                            context,
                            'inline.plan295.life.ttl.a0399b1384a9',
                          ),
                          value: _lifeI18nText(
                            context,
                            'inline.plan295.life.3h.7df2ebc1dfa7',
                          ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.boundary.b72c98dd2a1f',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.local_html_generation_does_not_uploa.5399cbc040ee',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.for_long_term_hosting_use_real_objec.de9c865b1bd9',
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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.compress.failed_to_pick_image.6e0bad236d',
          params: <String, Object?>{'error': error},
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
          dialogTitle: _lifeI18nText(
            context,
            'inline.plan295.life.save_image_webpage.bfb018d381f9',
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
            _savedPath = _lifeI18nText(
              context,
              'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.to.web.failed_to_save_html.b0261ecb82',
          params: <String, Object?>{'error': error},
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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.to.web.upload_failed.97b5ae72f7',
          params: <String, Object?>{'error': error},
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
          _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.image.to.web.copied.e89207e2d2',
            params: <String, Object?>{'label': label},
          ),
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

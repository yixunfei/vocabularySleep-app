part of '../toolbox_life_tools.dart';

class _ArchiveToolPage extends StatefulWidget {
  const _ArchiveToolPage();

  @override
  State<_ArchiveToolPage> createState() => _ArchiveToolPageState();
}

class _ArchiveToolPageState extends State<_ArchiveToolPage> {
  final TextEditingController _zipPasswordController = TextEditingController();
  final TextEditingController _extractPasswordController =
      TextEditingController();
  final List<_LifeArchiveInput> _archiveInputs = <_LifeArchiveInput>[];
  Archive? _loadedArchive;
  String? _loadedName;
  String? _loadedPath;
  _LifeArchiveFormat? _loadedFormat;
  Uint8List? _selectedArchiveBytes;
  Uint8List? _archiveBytes;
  _LifeArchiveCreateFormat _createFormat = _LifeArchiveCreateFormat.zip;
  _LifeArchiveCompressionLevel _compressionLevel =
      _LifeArchiveCompressionLevel.balanced;
  _LifeArchiveZipAlgorithm _zipAlgorithm = _LifeArchiveZipAlgorithm.deflate;
  final ValueNotifier<_LifeArchiveProgressInfo?> _progressInfo =
      ValueNotifier<_LifeArchiveProgressInfo?>(null);
  String? _savedPath;
  String? _extractedPath;
  String? _errorKey;
  int _folderInputCount = 0;
  int _failedInputCount = 0;
  bool _busy = false;
  bool _webExtractDownload = false;
  bool _progressDialogOpen = false;

  @override
  void dispose() {
    _zipPasswordController.dispose();
    _extractPasswordController.dispose();
    _progressInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _loadedArchive?.files ?? const <ArchiveFile>[];
    final canExtract = _canExtractArchive(entries);
    final effectiveCreateFormat = _effectiveCreateFormat;
    final wrapsStreamFormat = effectiveCreateFormat != _createFormat;
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.archive_tool.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.archive_tool.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.archive_tool.compress'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.archive_tool.compress_subtitle',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickFiles,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.pick_files',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _pickFolder,
                    icon: const Icon(Icons.create_new_folder_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.pick_folder',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _archiveInputs.isEmpty || _busy
                        ? null
                        : _buildArchive,
                    icon: const Icon(Icons.folder_zip_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.create_archive',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _archiveBytes == null || _busy
                        ? null
                        : _saveArchive,
                    icon: const Icon(Icons.save_alt_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.save_archive',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<_LifeArchiveCreateFormat>(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.archive_tool.format',
                ),
                value: _createFormat,
                options: _lifeArchiveCreateFormatOptions,
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() {
                        _createFormat = value;
                        _archiveBytes = null;
                        _savedPath = null;
                        if (!_createFormat.isZip) {
                          _zipAlgorithm = _LifeArchiveZipAlgorithm.deflate;
                        }
                      }),
              ),
              if (wrapsStreamFormat) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.stream_format_auto_tar_hint',
                    params: <String, Object?>{
                      'format': _lifeI18nText(
                        context,
                        effectiveCreateFormat.labelKey,
                      ),
                    },
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _LifeSegmentedField<_LifeArchiveCompressionLevel>(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.archive_tool.level',
                ),
                value: _compressionLevel,
                options: _lifeArchiveCompressionLevelOptions,
                onChanged: _busy
                    ? (_) {}
                    : (value) => setState(() {
                        _compressionLevel = value;
                        _archiveBytes = null;
                        _savedPath = null;
                      }),
              ),
              const SizedBox(height: 12),
              if (_createFormat.isZip) ...<Widget>[
                _LifeSegmentedField<_LifeArchiveZipAlgorithm>(
                  label: _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.algorithm',
                  ),
                  value: _zipAlgorithm,
                  options: _lifeArchiveZipAlgorithmOptions,
                  onChanged: _busy
                      ? (_) {}
                      : (value) => setState(() {
                          _zipAlgorithm = value;
                          _archiveBytes = null;
                          _savedPath = null;
                        }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _zipPasswordController,
                  enabled: !_busy,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.zip_password',
                    ),
                    helperText: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.password_optional',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {
                    _archiveBytes = null;
                    _savedPath = null;
                  }),
                ),
              ] else
                _LifeInlineNotice(
                  icon: Icons.lock_outline_rounded,
                  text: _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.password_zip_only_notice',
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.metric_files',
                    ),
                    value: _archiveInputs.length.toString(),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.metric_folders',
                    ),
                    value: _folderInputCount.toString(),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.metric_archive_size',
                    ),
                    value: _archiveBytes == null
                        ? '--'
                        : _lifeFormatBytes(_archiveBytes!.length),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.output_format',
                    ),
                    value: _lifeI18nText(
                      context,
                      effectiveCreateFormat.labelKey,
                    ),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.metric_failed_files',
                    ),
                    value: _failedInputCount.toString(),
                  ),
                ],
              ),
              if (_archiveInputs.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.selected_items',
                  ),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                ..._archiveInputs.take(6).map((input) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      input.fromFolder
                          ? Icons.folder_copy_rounded
                          : Icons.insert_drive_file_rounded,
                    ),
                    title: Text(input.relativePath),
                    subtitle: Text(_lifeFormatBytes(input.size)),
                  );
                }),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(context, 'toolbox.life.archive_tool.extract'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.archive_tool.extract_subtitle',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _pickArchive,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.pick_zip',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _selectedArchiveBytes == null || _busy
                        ? null
                        : _readSelectedArchive,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.read_archive',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: !canExtract || _busy ? null : _extractArchive,
                    icon: const Icon(Icons.unarchive_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.archive_tool.extract_all',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _extractPasswordController,
                enabled:
                    _loadedFormat == null ||
                    _loadedFormat == _LifeArchiveFormat.zip,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.extract_password',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    _loadedFormat == null ||
                            _loadedFormat == _LifeArchiveFormat.zip
                        ? 'toolbox.life.archive_tool.password_optional'
                        : 'toolbox.life.archive_tool.password_not_available',
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_loadedFormat != _LifeArchiveFormat.zip ||
                      _selectedArchiveBytes == null) {
                    return;
                  }
                  setState(() {
                    _loadedArchive = null;
                    _extractedPath = null;
                    _errorKey = null;
                  });
                },
                onSubmitted: (_) {
                  if (_selectedArchiveBytes != null && !_busy) {
                    _readSelectedArchive();
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.metric_archive',
                    ),
                    value: _loadedArchiveLabel(),
                  ),
                  ToolboxMetricCard(
                    label: _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.metric_entries',
                    ),
                    value: entries.length.toString(),
                  ),
                ],
              ),
              if (entries.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                ...entries.take(8).map((entry) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      entry.isFile
                          ? Icons.insert_drive_file_rounded
                          : Icons.folder_rounded,
                    ),
                    title: Text(entry.name),
                    subtitle: Text(
                      entry.isFile ? _lifeFormatBytes(entry.size) : '--',
                    ),
                  );
                }),
              ],
              if (_savedPath != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.common.saved_to',
                    params: <String, Object?>{'path': _savedPath},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_extractedPath != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _lifeI18nText(
                    context,
                    _webExtractDownload
                        ? 'toolbox.life.archive_tool.web_extracted_to'
                        : 'toolbox.life.archive_tool.extracted_to',
                    params: <String, Object?>{'path': _extractedPath},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_errorKey != null) ...<Widget>[
                const SizedBox(height: 12),
                _LifeInlineNotice(
                  icon: Icons.folder_zip_rounded,
                  text: _lifeI18nText(context, _errorKey!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
      _archiveBytes = null;
      _savedPath = null;
      _webExtractDownload = false;
      _failedInputCount = 0;
    });
    final inputs = <_LifeArchiveInput>[];
    var failed = 0;
    var readBytes = 0;
    await _withArchiveProgress<void>(
      _LifeArchiveProgressInfo(
        titleKey: 'toolbox.life.archive_tool.progress_title_read_inputs',
        phaseKey: 'toolbox.life.archive_tool.progress_phase_collect',
        processedCount: 0,
        totalCount: picked.files.length,
      ),
      () async {
        for (var index = 0; index < picked.files.length; index += 1) {
          final input = await _inputFromPlatformFile(picked.files[index]);
          if (input == null) {
            failed += 1;
          } else {
            inputs.add(input);
            readBytes += input.size;
          }
          _setArchiveProgress(
            _LifeArchiveProgressInfo(
              titleKey: 'toolbox.life.archive_tool.progress_title_read_inputs',
              phaseKey: 'toolbox.life.archive_tool.progress_phase_collect',
              processedCount: index + 1,
              totalCount: picked.files.length,
              inputBytes: readBytes,
              failedCount: failed,
            ),
          );
        }
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _archiveInputs
        ..clear()
        ..addAll(_deduplicateArchiveInputs(inputs));
      _folderInputCount = 0;
      _failedInputCount = failed;
      _busy = false;
      _errorKey = _archiveInputs.isEmpty
          ? 'toolbox.life.archive_tool.error_no_bytes'
          : null;
    });
  }

  Future<void> _pickFolder() async {
    if (kIsWeb) {
      setState(() {
        _errorKey = 'toolbox.life.archive_tool.error_folder_unsupported';
      });
      return;
    }
    final folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath == null || folderPath.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
      _archiveBytes = null;
      _savedPath = null;
      _webExtractDownload = false;
      _failedInputCount = 0;
    });
    final root = Directory(folderPath);
    final inputs = <_LifeArchiveInput>[];
    var failed = 0;
    var processed = 0;
    var readBytes = 0;
    try {
      await _withArchiveProgress<void>(
        _LifeArchiveProgressInfo(
          titleKey: 'toolbox.life.archive_tool.progress_title_read_inputs',
          phaseKey: 'toolbox.life.archive_tool.progress_phase_collect',
          archiveName: path.basename(root.path),
          processedCount: 0,
        ),
        () async {
          await for (final entity in root.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is! File) {
              continue;
            }
            final type = await FileSystemEntity.type(
              entity.path,
              followLinks: false,
            );
            if (type != FileSystemEntityType.file) {
              continue;
            }
            try {
              final relative = path.relative(entity.path, from: root.path);
              final archivePath = _safeArchiveRelativePath(relative);
              if (archivePath.isEmpty) {
                failed += 1;
                continue;
              }
              final bytes = await entity.readAsBytes();
              inputs.add(
                _LifeArchiveInput(
                  relativePath: archivePath,
                  size: bytes.length,
                  bytes: bytes,
                  fromFolder: true,
                ),
              );
              readBytes += bytes.length;
            } catch (_) {
              failed += 1;
            }
            processed += 1;
            if (processed == 1 || processed % 10 == 0) {
              _setArchiveProgress(
                _LifeArchiveProgressInfo(
                  titleKey:
                      'toolbox.life.archive_tool.progress_title_read_inputs',
                  phaseKey: 'toolbox.life.archive_tool.progress_phase_collect',
                  archiveName: path.basename(root.path),
                  processedCount: processed,
                  inputBytes: readBytes,
                  failedCount: failed,
                ),
              );
            }
          }
          _setArchiveProgress(
            _LifeArchiveProgressInfo(
              titleKey: 'toolbox.life.archive_tool.progress_title_read_inputs',
              phaseKey: 'toolbox.life.archive_tool.progress_phase_collect',
              archiveName: path.basename(root.path),
              processedCount: processed,
              inputBytes: readBytes,
              failedCount: failed,
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failedInputCount = failed;
          _errorKey = 'toolbox.life.archive_tool.error_no_bytes';
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _archiveInputs
        ..clear()
        ..addAll(_deduplicateArchiveInputs(inputs));
      _folderInputCount = 1;
      _failedInputCount = failed;
      _busy = false;
      _errorKey = _archiveInputs.isEmpty
          ? 'toolbox.life.archive_tool.error_no_bytes'
          : null;
    });
  }

  Future<void> _buildArchive() async {
    final createFormat = _effectiveCreateFormat;
    setState(() {
      _busy = true;
      _errorKey = null;
      _savedPath = null;
    });
    try {
      final bytes = await _withArchiveProgress<List<int>>(
        _LifeArchiveProgressInfo(
          titleKey: 'toolbox.life.archive_tool.progress_title_create',
          phaseKey: 'toolbox.life.archive_tool.progress_phase_encode',
          phaseParams: <String, Object?>{
            'format': _lifeI18nText(context, createFormat.labelKey),
          },
          formatLabel: _lifeI18nText(context, createFormat.labelKey),
          processedCount: _archiveInputs.length,
          totalCount: _archiveInputs.length,
          inputBytes: _archiveInputBytes,
          failedCount: _failedInputCount,
        ),
        _encodeArchive,
      );
      if (mounted) {
        setState(() => _archiveBytes = Uint8List.fromList(bytes));
      }
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeArchiveTool',
        'archive creation failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'requestedFormat': _createFormat.name,
          'effectiveFormat': _effectiveCreateFormat.name,
          'fileCount': _archiveInputs.length,
        },
      );
      if (mounted) {
        setState(
          () => _errorKey = error is _LifeArchiveUserError
              ? error.key
              : 'toolbox.life.archive_tool.error_archive',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveArchive() async {
    final bytes = _archiveBytes;
    if (bytes == null) {
      return;
    }
    final createFormat = _effectiveCreateFormat;
    final saved = await _saveLifeBytes(
      context: context,
      bytes: bytes,
      fileName: 'life_archive.${createFormat.fileExtension}',
      subdirectory: 'archive_tool',
      dialogTitleKey: 'toolbox.life.archive_tool.save_dialog',
      allowedExtensions: <String>[createFormat.fileExtension],
    );
    if (mounted) {
      setState(() => _savedPath = saved);
    }
  }

  Future<void> _pickArchive() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: _lifeArchiveAllowedExtensions,
    );
    final file = (picked != null && picked.files.isNotEmpty)
        ? picked.files.first
        : null;
    if (file == null) {
      return;
    }
    final filePath = file.path;
    setState(() {
      _busy = true;
      _loadedArchive = null;
      _loadedName = null;
      _loadedPath = null;
      _loadedFormat = null;
      _selectedArchiveBytes = null;
      _errorKey = null;
      _extractedPath = null;
      _webExtractDownload = false;
    });
    try {
      await _withArchiveProgress<void>(
        _LifeArchiveProgressInfo(
          titleKey: 'toolbox.life.archive_tool.progress_title_read_archive',
          phaseKey: 'toolbox.life.archive_tool.progress_phase_decode',
          archiveName: file.name,
          inputBytes: file.size,
        ),
        () async {
          final bytes =
              file.bytes ??
              (filePath == null || filePath.isEmpty
                  ? null
                  : await File(filePath).readAsBytes());
          if (bytes == null || bytes.isEmpty) {
            throw const _LifeArchiveUserError(
              'toolbox.life.archive_tool.error_no_bytes',
            );
          }
          final format = _detectLifeArchiveFormat(file.name, bytes);
          _selectedArchiveBytes = Uint8List.fromList(bytes);
          _loadedName = file.name;
          _loadedPath = filePath;
          _loadedFormat = format;
          _decodeSelectedArchive();
        },
      );
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeArchiveTool',
        'archive read failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'name': file.name},
      );
      if (mounted) {
        setState(
          () => _errorKey = error is _LifeArchiveUserError
              ? error.key
              : _loadedFormat == _LifeArchiveFormat.zip
              ? 'toolbox.life.archive_tool.error_bad_password_or_encryption'
              : 'toolbox.life.archive_tool.error_read',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _readSelectedArchive() async {
    if (_selectedArchiveBytes == null || _loadedName == null) {
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
      _extractedPath = null;
      _webExtractDownload = false;
    });
    try {
      await _withArchiveProgress<void>(
        _LifeArchiveProgressInfo(
          titleKey: 'toolbox.life.archive_tool.progress_title_read_archive',
          phaseKey: 'toolbox.life.archive_tool.progress_phase_decode',
          phaseParams: <String, Object?>{
            'format': _loadedFormat?.label ?? '--',
          },
          archiveName: _loadedName,
          formatLabel: _loadedFormat?.label,
          inputBytes: _selectedArchiveBytes?.length,
        ),
        () async {
          _decodeSelectedArchive();
        },
      );
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeArchiveTool',
        'archive read failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'name': _loadedName,
          'format': _loadedFormat?.name,
          'passwordProvided': _zipExtractPassword != null,
        },
      );
      if (mounted) {
        setState(
          () => _errorKey = error is _LifeArchiveUserError
              ? error.key
              : _loadedFormat == _LifeArchiveFormat.zip
              ? 'toolbox.life.archive_tool.error_bad_password_or_encryption'
              : 'toolbox.life.archive_tool.error_read',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _decodeSelectedArchive() {
    final bytes = _selectedArchiveBytes;
    final name = _loadedName;
    final format = _loadedFormat;
    if (bytes == null || name == null || bytes.isEmpty || format == null) {
      throw const _LifeArchiveUserError(
        'toolbox.life.archive_tool.error_no_bytes',
      );
    }
    final unsupportedErrorKey = _archiveUnsupportedErrorKey(format);
    if (unsupportedErrorKey != null) {
      throw _LifeArchiveUserError(unsupportedErrorKey);
    }
    final archive = _decodeLifeArchive(
      name,
      bytes,
      format,
      password: _zipExtractPassword,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedArchive = archive;
      _extractedPath = null;
      _webExtractDownload = false;
      _errorKey = null;
    });
  }

  Future<void> _extractArchive() async {
    final archive = _loadedArchive;
    if (archive == null) {
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
      _extractedPath = null;
      _webExtractDownload = false;
    });
    try {
      await _withArchiveProgress<void>(
        _LifeArchiveProgressInfo(
          titleKey: 'toolbox.life.archive_tool.progress_title_extract',
          phaseKey: 'toolbox.life.archive_tool.progress_phase_extract',
          archiveName: _loadedName,
          formatLabel: _loadedFormat?.label,
          processedCount: 0,
          totalCount: _fileEntryCount(archive),
        ),
        () async {
          if (kIsWeb) {
            final bytes = _encodeExtractedEntriesAsZip(archive);
            final saved = await _saveLifeBytes(
              context: context,
              bytes: Uint8List.fromList(bytes),
              fileName: _webExtractArchiveName(),
              subdirectory: 'archive_tool',
              dialogTitleKey: 'toolbox.life.archive_tool.save_dialog',
              allowedExtensions: const <String>['zip'],
            );
            if (mounted) {
              setState(() {
                _extractedPath = saved;
                _webExtractDownload = true;
              });
            }
            return;
          }
          final appDir = await getApplicationDocumentsDirectory();
          final root = Directory(
            path.join(
              appDir.path,
              'life_tools',
              'archive_tool',
              'extract_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
          await root.create(recursive: true);
          final totalEntries = _fileEntryCount(archive);
          var processed = 0;
          var writtenBytes = 0;
          for (final entry in archive) {
            if (!entry.isFile) {
              continue;
            }
            final relative = _safeArchiveRelativePath(entry.name);
            if (relative.isEmpty) {
              continue;
            }
            final target = File(path.join(root.path, relative));
            final parent = target.parent;
            if (!await parent.exists()) {
              await parent.create(recursive: true);
            }
            await target.writeAsBytes(entry.content, flush: true);
            processed += 1;
            writtenBytes += entry.size;
            if (processed == 1 ||
                processed == totalEntries ||
                processed % 10 == 0) {
              _setArchiveProgress(
                _LifeArchiveProgressInfo(
                  titleKey: 'toolbox.life.archive_tool.progress_title_extract',
                  phaseKey: 'toolbox.life.archive_tool.progress_phase_extract',
                  archiveName: _loadedName,
                  formatLabel: _loadedFormat?.label,
                  processedCount: processed,
                  totalCount: totalEntries,
                  outputBytes: writtenBytes,
                ),
              );
            }
          }
          if (mounted) {
            setState(() {
              _extractedPath = root.path;
              _webExtractDownload = false;
            });
          }
        },
      );
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeArchiveTool',
        'archive extract failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.archive_tool.error_extract');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<T> _withArchiveProgress<T>(
    _LifeArchiveProgressInfo info,
    FutureOr<T> Function() action,
  ) async {
    if (!mounted) {
      return Future<T>.sync(action);
    }
    _setArchiveProgress(info);
    unawaited(_openArchiveProgressDialog());
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return await Future<T>.sync(action);
    } finally {
      _progressInfo.value = null;
      if (mounted && _progressDialogOpen) {
        _progressDialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _openArchiveProgressDialog() async {
    if (_progressDialogOpen || !mounted) {
      return;
    }
    _progressDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return _LifeArchiveProgressDialog(progress: _progressInfo);
        },
      );
    } finally {
      _progressDialogOpen = false;
    }
  }

  void _setArchiveProgress(_LifeArchiveProgressInfo info) {
    _progressInfo.value = info;
  }

  int get _archiveInputBytes {
    return _archiveInputs.fold<int>(0, (total, input) => total + input.size);
  }

  int _fileEntryCount(Archive archive) {
    return archive.files.where((entry) => entry.isFile).length;
  }

  bool _canExtractArchive(List<ArchiveFile> entries) {
    return entries.where((entry) => entry.isFile).isNotEmpty;
  }

  String _loadedArchiveLabel() {
    final name = _loadedName;
    if (name == null) {
      return '--';
    }
    final format = _loadedFormat;
    if (format == null) {
      return name;
    }
    return '$name · ${format.label}';
  }

  List<int> _encodeArchive() {
    if (_archiveInputs.isEmpty) {
      throw const _LifeArchiveUserError(
        'toolbox.life.archive_tool.error_no_bytes',
      );
    }
    final createFormat = _effectiveCreateFormat;
    final archive = Archive();
    for (final input in _archiveInputs) {
      final entry = ArchiveFile.bytes(input.relativePath, input.bytes);
      if (createFormat.isZip) {
        entry.compression = _zipAlgorithm.compressionType;
        if (_zipAlgorithm == _LifeArchiveZipAlgorithm.deflate) {
          entry.compressionLevel = _compressionLevel.deflateLevel;
        }
      }
      archive.addFile(entry);
    }
    return switch (createFormat) {
      _LifeArchiveCreateFormat.zip => ZipEncoder(
        password: _zipCreatePassword,
      ).encodeBytes(archive, level: _compressionLevel.deflateLevel),
      _LifeArchiveCreateFormat.tar => TarEncoder().encodeBytes(archive),
      _LifeArchiveCreateFormat.tarGzip => GZipEncoder().encodeBytes(
        TarEncoder().encodeBytes(archive),
        level: _compressionLevel.deflateLevel,
      ),
      _LifeArchiveCreateFormat.tarBzip2 => BZip2Encoder().encodeBytes(
        TarEncoder().encodeBytes(archive),
      ),
      _LifeArchiveCreateFormat.tarXz => XZEncoder().encodeBytes(
        TarEncoder().encodeBytes(archive),
      ),
      _LifeArchiveCreateFormat.gzip => GZipEncoder().encodeBytes(
        _archiveInputs.single.bytes,
        level: _compressionLevel.deflateLevel,
      ),
      _LifeArchiveCreateFormat.bzip2 => BZip2Encoder().encodeBytes(
        _archiveInputs.single.bytes,
      ),
      _LifeArchiveCreateFormat.xz => XZEncoder().encodeBytes(
        _archiveInputs.single.bytes,
      ),
    };
  }

  List<int> _encodeExtractedEntriesAsZip(Archive archive) {
    final extracted = Archive();
    for (final entry in archive.files) {
      if (!entry.isFile) {
        continue;
      }
      final relative = _safeArchiveRelativePath(entry.name);
      if (relative.isEmpty) {
        continue;
      }
      final output = ArchiveFile.bytes(relative, entry.content);
      output.compression = CompressionType.deflate;
      output.compressionLevel = _compressionLevel.deflateLevel;
      extracted.addFile(output);
    }
    if (extracted.files.isEmpty) {
      throw const _LifeArchiveUserError(
        'toolbox.life.archive_tool.error_no_bytes',
      );
    }
    return ZipEncoder().encodeBytes(
      extracted,
      level: _compressionLevel.deflateLevel,
    );
  }

  Future<_LifeArchiveInput?> _inputFromPlatformFile(PlatformFile file) async {
    try {
      final bytes =
          file.bytes ??
          (file.path == null || file.path!.isEmpty
              ? null
              : await File(file.path!).readAsBytes());
      if (bytes == null) {
        return null;
      }
      return _LifeArchiveInput(
        relativePath: _safeArchiveRelativePath(file.name),
        size: bytes.length,
        bytes: bytes,
        fromFolder: false,
      );
    } catch (_) {
      return null;
    }
  }

  List<_LifeArchiveInput> _deduplicateArchiveInputs(
    List<_LifeArchiveInput> inputs,
  ) {
    final usedNames = <String>{};
    return inputs
        .map((input) {
          final name = input.relativePath.isEmpty
              ? 'entry'
              : input.relativePath;
          return input.copyWith(
            relativePath: _uniqueArchiveName(name, usedNames),
          );
        })
        .toList(growable: false);
  }

  String _uniqueArchiveName(String name, Set<String> usedNames) {
    var candidate = name;
    var index = 2;
    while (usedNames.contains(candidate)) {
      final dir = path.posix.dirname(name);
      final fileName = path.posix.basename(name);
      final ext = _lifeCompoundExtension(fileName);
      final base = ext.isEmpty
          ? fileName
          : fileName.substring(0, fileName.length - ext.length);
      final nextName = '${base}_$index$ext';
      candidate = dir == '.' ? nextName : path.posix.join(dir, nextName);
      index += 1;
    }
    usedNames.add(candidate);
    return candidate;
  }

  String? get _zipCreatePassword {
    final value = _zipPasswordController.text.trim();
    return value.isEmpty || !_createFormat.isZip ? null : value;
  }

  String? get _zipExtractPassword {
    final value = _extractPasswordController.text;
    return value.isEmpty ? null : value;
  }

  _LifeArchiveCreateFormat get _effectiveCreateFormat {
    return _resolveLifeArchiveCreateFormat(
      _createFormat,
      _archiveInputs.length,
    );
  }

  String _webExtractArchiveName() {
    final source = _loadedName == null || _loadedName!.trim().isEmpty
        ? 'extracted'
        : _lifeArchiveBaseNameWithoutCompoundExtension(_loadedName!);
    return '${_lifeSafeFileName(source, fallback: 'extracted')}_extracted.zip';
  }

  String _safeArchiveRelativePath(String raw) {
    final parts = raw
        .split(RegExp(r'[\\/]+'))
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .map((part) => _lifeSafeFileName(part, fallback: 'entry'))
        .toList(growable: false);
    if (parts.isEmpty) {
      return '';
    }
    return path.posix.joinAll(parts);
  }
}

class _LifeArchiveProgressInfo {
  const _LifeArchiveProgressInfo({
    required this.titleKey,
    required this.phaseKey,
    this.phaseParams = const <String, Object?>{},
    this.archiveName,
    this.formatLabel,
    this.processedCount,
    this.totalCount,
    this.inputBytes,
    this.outputBytes,
    this.failedCount,
  });

  final String titleKey;
  final String phaseKey;
  final Map<String, Object?> phaseParams;
  final String? archiveName;
  final String? formatLabel;
  final int? processedCount;
  final int? totalCount;
  final int? inputBytes;
  final int? outputBytes;
  final int? failedCount;
}

class _LifeArchiveProgressDialog extends StatelessWidget {
  const _LifeArchiveProgressDialog({required this.progress});

  final ValueListenable<_LifeArchiveProgressInfo?> progress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_LifeArchiveProgressInfo?>(
      valueListenable: progress,
      builder: (context, info, _) {
        final current =
            info ??
            const _LifeArchiveProgressInfo(
              titleKey: 'toolbox.life.archive_tool.progress_title_create',
              phaseKey: 'toolbox.life.archive_tool.progress_phase_encode',
            );
        final processed = current.processedCount;
        final total = current.totalCount;
        final progressValue = processed != null && total != null && total > 0
            ? (processed / total).clamp(0.0, 1.0)
            : null;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            icon: const Icon(Icons.folder_zip_rounded),
            title: Text(_lifeI18nText(context, current.titleKey)),
            content: SizedBox(
              width: math.min(MediaQuery.sizeOf(context).width - 96, 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LinearProgressIndicator(value: progressValue),
                  const SizedBox(height: 12),
                  Text(
                    _lifeI18nText(
                      context,
                      current.phaseKey,
                      params: current.phaseParams,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _progressMetrics(current),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.archive_tool.progress_keep_open',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _progressMetrics(_LifeArchiveProgressInfo info) {
    final metrics = <Widget>[];
    void add(String labelKey, String value) {
      metrics.add(_LifeArchiveProgressMetric(labelKey: labelKey, value: value));
    }

    final archiveName = info.archiveName;
    if (archiveName != null && archiveName.isNotEmpty) {
      add('toolbox.life.archive_tool.metric_archive', archiveName);
    }
    final formatLabel = info.formatLabel;
    if (formatLabel != null && formatLabel.isNotEmpty) {
      add('toolbox.life.archive_tool.output_format', formatLabel);
    }
    final processed = info.processedCount;
    if (processed != null) {
      final total = info.totalCount;
      add(
        'toolbox.life.archive_tool.metric_files',
        total == null ? processed.toString() : '$processed/$total',
      );
    }
    final inputBytes = info.inputBytes;
    if (inputBytes != null && inputBytes > 0) {
      add(
        'toolbox.life.archive_tool.progress_input_size',
        _lifeFormatBytes(inputBytes),
      );
    }
    final outputBytes = info.outputBytes;
    if (outputBytes != null && outputBytes > 0) {
      add(
        'toolbox.life.archive_tool.progress_output_size',
        _lifeFormatBytes(outputBytes),
      );
    }
    final failed = info.failedCount;
    if (failed != null && failed > 0) {
      add('toolbox.life.archive_tool.metric_failed_files', failed.toString());
    }
    return metrics;
  }
}

class _LifeArchiveProgressMetric extends StatelessWidget {
  const _LifeArchiveProgressMetric({
    required this.labelKey,
    required this.value,
  });

  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(context, labelKey),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeArchiveInput {
  const _LifeArchiveInput({
    required this.relativePath,
    required this.size,
    required this.bytes,
    required this.fromFolder,
  });

  final String relativePath;
  final int size;
  final Uint8List bytes;
  final bool fromFolder;

  _LifeArchiveInput copyWith({String? relativePath}) {
    return _LifeArchiveInput(
      relativePath: relativePath ?? this.relativePath,
      size: size,
      bytes: bytes,
      fromFolder: fromFolder,
    );
  }
}

class _LifeArchiveUserError implements Exception {
  const _LifeArchiveUserError(this.key);

  final String key;
}

enum _LifeArchiveCreateFormat {
  zip(labelKey: 'toolbox.life.archive_tool.format_zip', fileExtension: 'zip'),
  tar(labelKey: 'toolbox.life.archive_tool.format_tar', fileExtension: 'tar'),
  tarGzip(
    labelKey: 'toolbox.life.archive_tool.format_tar_gzip',
    fileExtension: 'tar.gz',
  ),
  tarBzip2(
    labelKey: 'toolbox.life.archive_tool.format_tar_bzip2',
    fileExtension: 'tar.bz2',
  ),
  tarXz(
    labelKey: 'toolbox.life.archive_tool.format_tar_xz',
    fileExtension: 'tar.xz',
  ),
  gzip(
    labelKey: 'toolbox.life.archive_tool.format_gzip',
    fileExtension: 'gz',
    singleFileOnly: true,
  ),
  bzip2(
    labelKey: 'toolbox.life.archive_tool.format_bzip2',
    fileExtension: 'bz2',
    singleFileOnly: true,
  ),
  xz(
    labelKey: 'toolbox.life.archive_tool.format_xz',
    fileExtension: 'xz',
    singleFileOnly: true,
  );

  const _LifeArchiveCreateFormat({
    required this.labelKey,
    required this.fileExtension,
    this.singleFileOnly = false,
  });

  final String labelKey;
  final String fileExtension;
  final bool singleFileOnly;

  bool get isZip => this == _LifeArchiveCreateFormat.zip;
}

_LifeArchiveCreateFormat _resolveLifeArchiveCreateFormat(
  _LifeArchiveCreateFormat requested,
  int inputCount,
) {
  if (inputCount <= 1 || !requested.singleFileOnly) {
    return requested;
  }
  return switch (requested) {
    _LifeArchiveCreateFormat.gzip => _LifeArchiveCreateFormat.tarGzip,
    _LifeArchiveCreateFormat.bzip2 => _LifeArchiveCreateFormat.tarBzip2,
    _LifeArchiveCreateFormat.xz => _LifeArchiveCreateFormat.tarXz,
    _ => requested,
  };
}

const List<_LifeOption<_LifeArchiveCreateFormat>>
_lifeArchiveCreateFormatOptions = <_LifeOption<_LifeArchiveCreateFormat>>[
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.zip,
    labelKey: 'toolbox.life.archive_tool.format_zip',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.tar,
    labelKey: 'toolbox.life.archive_tool.format_tar',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.tarGzip,
    labelKey: 'toolbox.life.archive_tool.format_tar_gzip',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.tarBzip2,
    labelKey: 'toolbox.life.archive_tool.format_tar_bzip2',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.tarXz,
    labelKey: 'toolbox.life.archive_tool.format_tar_xz',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.gzip,
    labelKey: 'toolbox.life.archive_tool.format_gzip',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.bzip2,
    labelKey: 'toolbox.life.archive_tool.format_bzip2',
  ),
  _LifeOption<_LifeArchiveCreateFormat>(
    value: _LifeArchiveCreateFormat.xz,
    labelKey: 'toolbox.life.archive_tool.format_xz',
  ),
];

enum _LifeArchiveCompressionLevel {
  store(labelKey: 'toolbox.life.archive_tool.level_store', deflateLevel: 0),
  fast(labelKey: 'toolbox.life.archive_tool.level_fast', deflateLevel: 1),
  balanced(
    labelKey: 'toolbox.life.archive_tool.level_balanced',
    deflateLevel: 6,
  ),
  bestSize(
    labelKey: 'toolbox.life.archive_tool.level_best_size',
    deflateLevel: 9,
  );

  const _LifeArchiveCompressionLevel({
    required this.labelKey,
    required this.deflateLevel,
  });

  final String labelKey;
  final int deflateLevel;
}

const List<_LifeOption<_LifeArchiveCompressionLevel>>
_lifeArchiveCompressionLevelOptions =
    <_LifeOption<_LifeArchiveCompressionLevel>>[
      _LifeOption<_LifeArchiveCompressionLevel>(
        value: _LifeArchiveCompressionLevel.store,
        labelKey: 'toolbox.life.archive_tool.level_store',
      ),
      _LifeOption<_LifeArchiveCompressionLevel>(
        value: _LifeArchiveCompressionLevel.fast,
        labelKey: 'toolbox.life.archive_tool.level_fast',
      ),
      _LifeOption<_LifeArchiveCompressionLevel>(
        value: _LifeArchiveCompressionLevel.balanced,
        labelKey: 'toolbox.life.archive_tool.level_balanced',
      ),
      _LifeOption<_LifeArchiveCompressionLevel>(
        value: _LifeArchiveCompressionLevel.bestSize,
        labelKey: 'toolbox.life.archive_tool.level_best_size',
      ),
    ];

enum _LifeArchiveZipAlgorithm {
  store(
    labelKey: 'toolbox.life.archive_tool.algorithm_store',
    compressionType: CompressionType.none,
  ),
  deflate(
    labelKey: 'toolbox.life.archive_tool.algorithm_deflate',
    compressionType: CompressionType.deflate,
  ),
  bzip2(
    labelKey: 'toolbox.life.archive_tool.algorithm_bzip2',
    compressionType: CompressionType.bzip2,
  );

  const _LifeArchiveZipAlgorithm({
    required this.labelKey,
    required this.compressionType,
  });

  final String labelKey;
  final CompressionType compressionType;
}

const List<_LifeOption<_LifeArchiveZipAlgorithm>>
_lifeArchiveZipAlgorithmOptions = <_LifeOption<_LifeArchiveZipAlgorithm>>[
  _LifeOption<_LifeArchiveZipAlgorithm>(
    value: _LifeArchiveZipAlgorithm.store,
    labelKey: 'toolbox.life.archive_tool.algorithm_store',
  ),
  _LifeOption<_LifeArchiveZipAlgorithm>(
    value: _LifeArchiveZipAlgorithm.deflate,
    labelKey: 'toolbox.life.archive_tool.algorithm_deflate',
  ),
  _LifeOption<_LifeArchiveZipAlgorithm>(
    value: _LifeArchiveZipAlgorithm.bzip2,
    labelKey: 'toolbox.life.archive_tool.algorithm_bzip2',
  ),
];

enum _LifeArchiveFormat {
  zip('ZIP'),
  tar('TAR'),
  tarGzip('TAR.GZ'),
  gzip('GZip'),
  tarBzip2('TAR.BZ2'),
  bzip2('BZip2'),
  tarXz('TAR.XZ'),
  xz('XZ'),
  rar('RAR'),
  sevenZip('7z');

  const _LifeArchiveFormat(this.label);

  final String label;
}

const List<String> _lifeArchiveAllowedExtensions = <String>[
  'zip',
  'tar',
  'gz',
  'gzip',
  'tgz',
  'bz2',
  'tbz',
  'tbz2',
  'xz',
  'txz',
  'rar',
  '7z',
];

_LifeArchiveFormat _detectLifeArchiveFormat(String fileName, List<int> bytes) {
  final lowerName = fileName.toLowerCase();
  if (_hasPrefix(bytes, const <int>[0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c]) ||
      lowerName.endsWith('.7z')) {
    return _LifeArchiveFormat.sevenZip;
  }
  if (_hasPrefix(bytes, const <int>[0x52, 0x61, 0x72, 0x21, 0x1a, 0x07]) ||
      lowerName.endsWith('.rar')) {
    return _LifeArchiveFormat.rar;
  }
  if (lowerName.endsWith('.tar.gz') || lowerName.endsWith('.tgz')) {
    return _LifeArchiveFormat.tarGzip;
  }
  if (lowerName.endsWith('.tar.bz2') ||
      lowerName.endsWith('.tbz') ||
      lowerName.endsWith('.tbz2')) {
    return _LifeArchiveFormat.tarBzip2;
  }
  if (lowerName.endsWith('.tar.xz') || lowerName.endsWith('.txz')) {
    return _LifeArchiveFormat.tarXz;
  }
  if (_hasPrefix(bytes, const <int>[0x50, 0x4b]) ||
      lowerName.endsWith('.zip')) {
    return _LifeArchiveFormat.zip;
  }
  if (_hasPrefix(bytes, const <int>[0x1f, 0x8b]) ||
      lowerName.endsWith('.gz') ||
      lowerName.endsWith('.gzip')) {
    return _LifeArchiveFormat.gzip;
  }
  if (_hasPrefix(bytes, const <int>[0x42, 0x5a, 0x68]) ||
      lowerName.endsWith('.bz2')) {
    return _LifeArchiveFormat.bzip2;
  }
  if (_hasPrefix(bytes, const <int>[0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00]) ||
      lowerName.endsWith('.xz')) {
    return _LifeArchiveFormat.xz;
  }
  if (_looksLikeTar(bytes) || lowerName.endsWith('.tar')) {
    return _LifeArchiveFormat.tar;
  }
  return _LifeArchiveFormat.zip;
}

String? _archiveUnsupportedErrorKey(_LifeArchiveFormat format) {
  return switch (format) {
    _LifeArchiveFormat.rar => 'toolbox.life.archive_tool.error_rar_unsupported',
    _LifeArchiveFormat.sevenZip =>
      'toolbox.life.archive_tool.error_7z_unsupported',
    _ => null,
  };
}

Archive _decodeLifeArchive(
  String fileName,
  List<int> bytes,
  _LifeArchiveFormat format, {
  String? password,
}) {
  switch (format) {
    case _LifeArchiveFormat.zip:
      return ZipDecoder().decodeBytes(bytes, password: password);
    case _LifeArchiveFormat.tar:
      return TarDecoder().decodeBytes(bytes);
    case _LifeArchiveFormat.tarGzip:
      return TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    case _LifeArchiveFormat.gzip:
      return _singleFileArchive(
        _stripArchiveCompressionExtension(fileName, '.gz', '.gzip'),
        GZipDecoder().decodeBytes(bytes),
      );
    case _LifeArchiveFormat.tarBzip2:
      return TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes));
    case _LifeArchiveFormat.bzip2:
      return _singleFileArchive(
        _stripArchiveCompressionExtension(fileName, '.bz2'),
        BZip2Decoder().decodeBytes(bytes),
      );
    case _LifeArchiveFormat.tarXz:
      return TarDecoder().decodeBytes(XZDecoder().decodeBytes(bytes));
    case _LifeArchiveFormat.xz:
      return _singleFileArchive(
        _stripArchiveCompressionExtension(fileName, '.xz'),
        XZDecoder().decodeBytes(bytes),
      );
    case _LifeArchiveFormat.rar:
    case _LifeArchiveFormat.sevenZip:
      throw StateError('Unsupported archive decoder');
  }
}

Archive _singleFileArchive(String fileName, List<int> bytes) {
  final archive = Archive();
  archive.addFile(ArchiveFile.bytes(_lifeSafeFileName(fileName), bytes));
  return archive;
}

String _lifeArchiveBaseNameWithoutCompoundExtension(String fileName) {
  final baseName = path.basename(fileName);
  final extension = _lifeCompoundExtension(baseName);
  if (extension.isEmpty) {
    return baseName;
  }
  return baseName.substring(0, baseName.length - extension.length);
}

String _stripArchiveCompressionExtension(
  String fileName,
  String extension, [
  String? alternativeExtension,
]) {
  final lowerName = fileName.toLowerCase();
  if (lowerName.endsWith(extension)) {
    return fileName.substring(0, fileName.length - extension.length);
  }
  if (alternativeExtension != null &&
      lowerName.endsWith(alternativeExtension)) {
    return fileName.substring(0, fileName.length - alternativeExtension.length);
  }
  return '$fileName.out';
}

bool _hasPrefix(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }
  for (var i = 0; i < prefix.length; i += 1) {
    if (bytes[i] != prefix[i]) {
      return false;
    }
  }
  return true;
}

bool _looksLikeTar(List<int> bytes) {
  if (bytes.length < 262) {
    return false;
  }
  return bytes[257] == 0x75 &&
      bytes[258] == 0x73 &&
      bytes[259] == 0x74 &&
      bytes[260] == 0x61 &&
      bytes[261] == 0x72;
}

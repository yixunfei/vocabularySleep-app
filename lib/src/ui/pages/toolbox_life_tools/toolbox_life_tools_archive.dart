part of '../toolbox_life_tools.dart';

class _ArchiveToolPage extends StatefulWidget {
  const _ArchiveToolPage();

  @override
  State<_ArchiveToolPage> createState() => _ArchiveToolPageState();
}

class _ArchiveToolPageState extends State<_ArchiveToolPage> {
  static const ToolboxArchiveProcessingService _archiveService =
      ToolboxArchiveProcessingService();

  final TextEditingController _zipPasswordController = TextEditingController();
  final TextEditingController _extractPasswordController =
      TextEditingController();
  final List<ToolboxArchiveInput> _archiveInputs = <ToolboxArchiveInput>[];
  ToolboxArchiveDecodeResult? _loadedArchive;
  String? _loadedName;
  ToolboxArchiveFormat? _loadedFormat;
  Uint8List? _selectedArchiveBytes;
  Uint8List? _archiveBytes;
  ToolboxArchiveCreateFormat _createFormat = ToolboxArchiveCreateFormat.zip;
  ToolboxArchiveCompressionLevel _compressionLevel =
      ToolboxArchiveCompressionLevel.balanced;
  ToolboxArchiveZipAlgorithm _zipAlgorithm = ToolboxArchiveZipAlgorithm.deflate;
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
  Widget build(BuildContext context) => buildArchiveView(context);

  void _updateArchiveState(VoidCallback update) => setState(update);

  Future<void> _pickFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
      withReadStream: !kIsWeb,
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
    final inputs = <ToolboxArchiveInput>[];
    var failed = 0;
    var readBytes = 0;
    try {
      ToolboxArchiveResourcePolicy.validateEntryCount(picked.files.length);
      await _withArchiveProgress<void>(
        _LifeArchiveProgressInfo(
          titleKey: 'toolbox.life.archive_tool.progress_title_read_inputs',
          phaseKey: 'toolbox.life.archive_tool.progress_phase_collect',
          processedCount: 0,
          totalCount: picked.files.length,
        ),
        () async {
          for (var index = 0; index < picked.files.length; index += 1) {
            final input = await _inputFromPlatformFile(
              picked.files[index],
              currentTotalBytes: readBytes,
            );
            if (input == null) {
              failed += 1;
            } else {
              inputs.add(input);
              readBytes += input.size;
            }
            _setArchiveProgress(
              _LifeArchiveProgressInfo(
                titleKey:
                    'toolbox.life.archive_tool.progress_title_read_inputs',
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
      final normalized =
          ToolboxArchiveProcessingService.normalizeSelectedInputs(inputs);
      if (!mounted) {
        return;
      }
      setState(() {
        _archiveInputs
          ..clear()
          ..addAll(normalized);
        _folderInputCount = 0;
        _failedInputCount = failed;
        _errorKey = _archiveInputs.isEmpty
            ? 'toolbox.life.archive_tool.error_no_bytes'
            : null;
      });
    } catch (error, stackTrace) {
      _logArchiveFailure('input file collection failed', error, stackTrace);
      if (mounted) {
        setState(() {
          _failedInputCount = failed;
          _errorKey = _archiveErrorKey(
            error,
            fallbackKey: 'toolbox.life.archive_tool.error_no_bytes',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
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
    final inputs = <ToolboxArchiveInput>[];
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
              ToolboxArchiveResourcePolicy.validateEntryCount(
                inputs.length + 1,
              );
              final fileLength = await entity.length();
              ToolboxArchiveResourcePolicy.validateEntryBytes(
                fileLength,
                entryPath: entity.path,
              );
              ToolboxArchiveResourcePolicy.validateTotalContentBytes(
                readBytes + fileLength,
              );
              final relative = path.relative(entity.path, from: root.path);
              final archivePath =
                  ToolboxArchivePathPolicy.normalizeSafeRelativePath(relative);
              final bytes = await _readArchiveFile(
                entity,
                currentTotalBytes: readBytes,
              );
              inputs.add(
                ToolboxArchiveInput(
                  relativePath: archivePath,
                  bytes: bytes,
                  fromFolder: true,
                ),
              );
              readBytes += bytes.length;
            } on ToolboxArchiveProcessingException {
              rethrow;
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
      final normalized =
          ToolboxArchiveProcessingService.normalizeSelectedInputs(inputs);
      if (!mounted) {
        return;
      }
      setState(() {
        _archiveInputs
          ..clear()
          ..addAll(normalized);
        _folderInputCount = 1;
        _failedInputCount = failed;
        _errorKey = _archiveInputs.isEmpty
            ? 'toolbox.life.archive_tool.error_no_bytes'
            : null;
      });
    } catch (error, stackTrace) {
      _logArchiveFailure('folder collection failed', error, stackTrace);
      if (mounted) {
        setState(() {
          _failedInputCount = failed;
          _errorKey = _archiveErrorKey(
            error,
            fallbackKey: 'toolbox.life.archive_tool.error_no_bytes',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _buildArchive() async {
    final createFormat = _effectiveCreateFormat;
    setState(() {
      _busy = true;
      _errorKey = null;
      _savedPath = null;
    });
    try {
      final bytes = await _withArchiveProgress<Uint8List>(
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
        () => _archiveService.encode(
          ToolboxArchiveEncodeRequest(
            entries: List<ToolboxArchiveInput>.unmodifiable(_archiveInputs),
            format: createFormat,
            compressionLevel: _compressionLevel,
            zipAlgorithm: _zipAlgorithm,
            password: _zipCreatePassword,
          ),
        ),
      );
      if (mounted) {
        setState(() => _archiveBytes = bytes);
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
        setState(() {
          _errorKey = _archiveErrorKey(
            error,
            fallbackKey: 'toolbox.life.archive_tool.error_archive',
          );
        });
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
      withData: kIsWeb,
      withReadStream: !kIsWeb,
      type: FileType.custom,
      allowedExtensions: _lifeArchiveAllowedExtensions,
    );
    final file = (picked != null && picked.files.isNotEmpty)
        ? picked.files.first
        : null;
    if (file == null) {
      return;
    }
    setState(() {
      _busy = true;
      _loadedArchive = null;
      _loadedName = null;
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
          final bytes = await _readPickedArchiveBytes(file);
          final format = ToolboxArchiveProcessingService.detectFormat(
            file.name,
            bytes,
          );
          _selectedArchiveBytes = bytes;
          _loadedName = file.name;
          _loadedFormat = format;
          await _decodeSelectedArchive();
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
        setState(() {
          _errorKey = _archiveErrorKey(
            error,
            fallbackKey: _loadedFormat == ToolboxArchiveFormat.zip
                ? 'toolbox.life.archive_tool.error_bad_password_or_encryption'
                : 'toolbox.life.archive_tool.error_read',
          );
        });
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
          await _decodeSelectedArchive();
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
        setState(() {
          _errorKey = _archiveErrorKey(
            error,
            fallbackKey: _loadedFormat == ToolboxArchiveFormat.zip
                ? 'toolbox.life.archive_tool.error_bad_password_or_encryption'
                : 'toolbox.life.archive_tool.error_read',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _decodeSelectedArchive() async {
    final bytes = _selectedArchiveBytes;
    final name = _loadedName;
    final format = _loadedFormat;
    if (bytes == null || name == null || bytes.isEmpty || format == null) {
      throw const ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.emptyInput,
      );
    }
    final archive = await _archiveService.decode(
      fileName: name,
      bytes: bytes,
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
    Directory? extractionRoot;
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
          totalCount: archive.fileCount,
        ),
        () async {
          archive.validateForExtraction();
          if (kIsWeb) {
            final bytes = await _archiveService.encodeDecodedEntriesAsZip(
              archive,
              compressionLevel: _compressionLevel,
            );
            if (!mounted) {
              return;
            }
            final saved = await _saveLifeBytes(
              context: context,
              bytes: bytes,
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
          extractionRoot = root;
          await root.create(recursive: true);
          final normalizedRoot = path.normalize(path.absolute(root.path));
          final totalEntries = archive.fileCount;
          var processed = 0;
          var writtenBytes = 0;
          for (final entry in archive.entries) {
            if (!entry.isFile) {
              continue;
            }
            final relative = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
              entry.relativePath,
            );
            final targetPath = path.normalize(
              path.joinAll(<String>[normalizedRoot, ...relative.split('/')]),
            );
            if (!path.isWithin(normalizedRoot, targetPath)) {
              throw ToolboxArchiveProcessingException(
                ToolboxArchiveErrorCode.unsafePath,
                entryPath: entry.relativePath,
              );
            }
            final target = File(targetPath);
            final parent = target.parent;
            if (!await parent.exists()) {
              await parent.create(recursive: true);
            }
            final entryBytes = entry.bytes!;
            ToolboxArchiveResourcePolicy.validateEntryBytes(
              entryBytes.length,
              entryPath: relative,
            );
            ToolboxArchiveResourcePolicy.validateTotalContentBytes(
              writtenBytes + entryBytes.length,
            );
            await target.writeAsBytes(entryBytes, flush: true);
            processed += 1;
            writtenBytes += entryBytes.length;
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
      final root = extractionRoot;
      if (root != null && await root.exists()) {
        try {
          await root.delete(recursive: true);
        } catch (cleanupError, cleanupStackTrace) {
          _logArchiveFailure(
            'partial extraction cleanup failed',
            cleanupError,
            cleanupStackTrace,
          );
        }
      }
      if (mounted) {
        setState(() {
          _errorKey = _archiveErrorKey(
            error,
            fallbackKey: 'toolbox.life.archive_tool.error_extract',
          );
        });
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

  bool _canExtractArchive(List<ToolboxArchiveDecodedEntry> entries) {
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

  Future<ToolboxArchiveInput?> _inputFromPlatformFile(
    PlatformFile file, {
    required int currentTotalBytes,
  }) async {
    try {
      if (file.size > 0) {
        ToolboxArchiveResourcePolicy.validateEntryBytes(
          file.size,
          entryPath: file.name,
        );
        ToolboxArchiveResourcePolicy.validateTotalContentBytes(
          currentTotalBytes + file.size,
        );
      }
      final directBytes = file.bytes;
      final stream =
          file.readStream ??
          (file.path == null || file.path!.isEmpty
              ? null
              : File(file.path!).openRead());
      final bytes =
          directBytes ??
          (stream == null
              ? null
              : await _readLimitedArchiveBytes(
                  stream,
                  maxBytes: ToolboxArchiveResourcePolicy.maxEntryBytes,
                  currentTotalBytes: currentTotalBytes,
                  overflowCode: ToolboxArchiveErrorCode.entryTooLarge,
                  entryPath: file.name,
                ));
      if (bytes == null) {
        return null;
      }
      ToolboxArchiveResourcePolicy.validateEntryBytes(
        bytes.length,
        entryPath: file.name,
      );
      ToolboxArchiveResourcePolicy.validateTotalContentBytes(
        currentTotalBytes + bytes.length,
      );
      return ToolboxArchiveInput(
        relativePath: ToolboxArchivePathPolicy.normalizeSafeRelativePath(
          file.name,
        ),
        bytes: bytes,
        fromFolder: false,
      );
    } on ToolboxArchiveProcessingException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _readArchiveFile(
    File file, {
    required int currentTotalBytes,
  }) {
    return _readLimitedArchiveBytes(
      file.openRead(),
      maxBytes: ToolboxArchiveResourcePolicy.maxEntryBytes,
      currentTotalBytes: currentTotalBytes,
      overflowCode: ToolboxArchiveErrorCode.entryTooLarge,
      entryPath: file.path,
    );
  }

  Future<Uint8List> _readPickedArchiveBytes(PlatformFile file) async {
    if (file.size > 0) {
      ToolboxArchiveResourcePolicy.validateArchiveBytes(file.size);
    }
    final directBytes = file.bytes;
    if (directBytes != null) {
      ToolboxArchiveResourcePolicy.validateArchiveBytes(directBytes.length);
      return directBytes;
    }
    final stream =
        file.readStream ??
        (file.path == null || file.path!.isEmpty
            ? null
            : File(file.path!).openRead());
    if (stream == null) {
      throw const ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.emptyInput,
      );
    }
    final bytes = await _readLimitedArchiveBytes(
      stream,
      maxBytes: ToolboxArchiveResourcePolicy.maxArchiveBytes,
      overflowCode: ToolboxArchiveErrorCode.archiveTooLarge,
      entryPath: file.name,
    );
    ToolboxArchiveResourcePolicy.validateArchiveBytes(bytes.length);
    return bytes;
  }

  Future<Uint8List> _readLimitedArchiveBytes(
    Stream<List<int>> stream, {
    required int maxBytes,
    required ToolboxArchiveErrorCode overflowCode,
    int currentTotalBytes = 0,
    String? entryPath,
  }) async {
    final builder = BytesBuilder(copy: false);
    var byteLength = 0;
    await for (final chunk in stream) {
      byteLength += chunk.length;
      if (byteLength > maxBytes) {
        throw ToolboxArchiveProcessingException(
          overflowCode,
          actualValue: byteLength,
          limitValue: maxBytes,
          entryPath: entryPath,
        );
      }
      ToolboxArchiveResourcePolicy.validateTotalContentBytes(
        currentTotalBytes + byteLength,
      );
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  String _archiveErrorKey(Object error, {required String fallbackKey}) {
    if (error is! ToolboxArchiveProcessingException) {
      return fallbackKey;
    }
    return switch (error.code) {
      ToolboxArchiveErrorCode.emptyInput =>
        'toolbox.life.archive_tool.error_no_bytes',
      ToolboxArchiveErrorCode.archiveTooLarge =>
        'toolbox.life.archive_tool.error_archive_too_large',
      ToolboxArchiveErrorCode.tooManyEntries =>
        'toolbox.life.archive_tool.error_too_many_entries',
      ToolboxArchiveErrorCode.entryTooLarge =>
        'toolbox.life.archive_tool.error_entry_too_large',
      ToolboxArchiveErrorCode.totalContentTooLarge =>
        'toolbox.life.archive_tool.error_total_content_too_large',
      ToolboxArchiveErrorCode.compressionRatioTooHigh =>
        'toolbox.life.archive_tool.error_compression_ratio_too_high',
      ToolboxArchiveErrorCode.unsafePath ||
      ToolboxArchiveErrorCode.duplicatePath ||
      ToolboxArchiveErrorCode.symbolicLink =>
        'toolbox.life.archive_tool.error_unsafe_path',
      ToolboxArchiveErrorCode.unsupportedFormat =>
        _loadedFormat == ToolboxArchiveFormat.rar
            ? 'toolbox.life.archive_tool.error_rar_unsupported'
            : _loadedFormat == ToolboxArchiveFormat.sevenZip
            ? 'toolbox.life.archive_tool.error_7z_unsupported'
            : fallbackKey,
      ToolboxArchiveErrorCode.invalidArchive ||
      ToolboxArchiveErrorCode.processingFailed => fallbackKey,
    };
  }

  void _logArchiveFailure(String message, Object error, StackTrace stackTrace) {
    AppLogService.instance.e(
      'LifeArchiveTool',
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  String? get _zipCreatePassword {
    final value = _zipPasswordController.text.trim();
    return value.isEmpty || !_createFormat.isZip ? null : value;
  }

  String? get _zipExtractPassword {
    final value = _extractPasswordController.text;
    return value.isEmpty ? null : value;
  }

  ToolboxArchiveCreateFormat get _effectiveCreateFormat {
    return ToolboxArchiveProcessingService.resolveCreateFormat(
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
}

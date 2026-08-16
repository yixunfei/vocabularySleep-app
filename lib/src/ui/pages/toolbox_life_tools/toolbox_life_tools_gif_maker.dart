part of '../toolbox_life_tools.dart';

class _GifMakerToolPage extends StatefulWidget {
  const _GifMakerToolPage();

  @override
  State<_GifMakerToolPage> createState() => _GifMakerToolPageState();
}

class _GifMakerToolPageState extends State<_GifMakerToolPage> {
  Trimmer _trimmer = Trimmer();

  File? _videoFile;
  String? _videoName;
  double _startValue = 0;
  double _endValue = 0;
  double _videoDurationMs = 0;
  double _maxClipSeconds = 6;
  double _fps = 10;
  double _targetWidth = 480;
  double _quality = 55;
  bool _loading = false;
  bool _exporting = false;
  bool _isPlaying = false;
  String? _exportedPath;
  int? _exportedBytes;
  String? _errorKey;
  _LifeVideoProbe? _videoProbe;

  bool get _hasVideo => _videoFile != null && _videoDurationMs > 0;

  bool get _canExport =>
      _supportsNativeGifMakerPlatform &&
      _hasVideo &&
      !_loading &&
      !_exporting &&
      _endValue > _startValue &&
      (_trimmer.videoPlayerController?.value.isInitialized ?? false);

  int get _estimatedFrameCount =>
      math.max(0, (_selectedDurationMs / 1000 * _fps).ceil());

  @override
  void dispose() {
    _disposeTrimmer(_trimmer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.gif_maker.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.gif_maker.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildImportStage(context),
          const SizedBox(height: 12),
          _buildTrimStage(context),
          const SizedBox(height: 12),
          _buildExportStage(context),
        ],
      ),
    );
  }

  Widget _buildImportStage(BuildContext context) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.gif_maker.import_stage'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.gif_maker.import_subtitle',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _loading || _exporting ? null : _pickVideo,
              icon: const Icon(Icons.video_file_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.life.gif_maker.pick'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _videoFile == null || _exporting ? null : _clearVideo,
              icon: const Icon(Icons.clear_all_rounded),
              label: Text(_lifeI18nText(context, 'toolbox.life.common.clear')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_videoFile == null)
          Text(
            _lifeI18nText(context, 'toolbox.life.gif_maker.empty'),
            style: theme.textTheme.bodySmall,
          )
        else if (_hasVideo)
          _LifeInlineNotice(
            icon: Icons.movie_filter_rounded,
            text: _lifeI18nText(
              context,
              'toolbox.life.gif_maker.video_loaded',
              params: <String, Object?>{
                'name': _videoName,
                'duration': _durationText(_videoDurationMs),
              },
            ),
          )
        else
          _LifeInlineNotice(
            icon: Icons.movie_filter_rounded,
            text: _lifeI18nText(
              context,
              'toolbox.life.gif_maker.video_selected',
              params: <String, Object?>{
                'name': _videoName,
                'size': _lifeFormatBytes(_videoProbe?.bytes ?? 0),
                'container': _videoProbe?.containerLabel ?? '--',
              },
            ),
          ),
        const SizedBox(height: 10),
        _LifeInlineNotice(
          icon: Icons.info_outline_rounded,
          text: _lifeI18nText(
            context,
            'toolbox.life.gif_maker.compatibility_hint',
          ),
        ),
        if (_errorKey != null) ...<Widget>[
          const SizedBox(height: 10),
          _LifeInlineNotice(
            icon: Icons.info_outline_rounded,
            text: _lifeI18nText(context, _errorKey!),
          ),
        ],
      ],
    );
  }

  Widget _buildTrimStage(BuildContext context) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.gif_maker.trim_stage'),
      subtitle: _lifeI18nText(context, 'toolbox.life.gif_maker.trim_subtitle'),
      children: <Widget>[
        if (_videoFile == null)
          Text(
            _lifeI18nText(context, 'toolbox.life.gif_maker.trim_empty'),
            style: theme.textTheme.bodySmall,
          )
        else if (!_supportsNativeGifMakerPlatform)
          Text(
            _lifeI18nText(
              context,
              'toolbox.life.gif_maker.preview_unsupported_platform',
            ),
            style: theme.textTheme.bodySmall,
          )
        else ...<Widget>[
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 8),
          _buildVideoPreview(context),
          if (_hasVideo) ...<Widget>[
            const SizedBox(height: 10),
            _buildTrimRangeControls(context),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _hasVideo && !_exporting ? _togglePreview : null,
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _lifeI18nText(
                    context,
                    _isPlaying
                        ? 'toolbox.life.gif_maker.preview_pause'
                        : 'toolbox.life.gif_maker.preview_play',
                  ),
                ),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.gif_maker.metric_range',
                ),
                value: _rangeText(),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.gif_maker.metric_duration',
                ),
                value: _durationText(_selectedDurationMs),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.gif_maker.metric_frames',
                ),
                value: _estimatedFrameCount.toString(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExportStage(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.gif_maker.export'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.gif_maker.export_subtitle',
      ),
      children: <Widget>[
        _LifeSliderField(
          label: _lifeI18nText(context, 'toolbox.life.gif_maker.max_length'),
          valueText: _lifeI18nText(
            context,
            'toolbox.life.gif_maker.seconds',
            params: <String, Object?>{'seconds': _maxClipSeconds.round()},
          ),
          value: _maxClipSeconds,
          min: 2,
          max: 15,
          divisions: 13,
          onChanged: (value) {
            if (_videoFile == null || _exporting) {
              return;
            }
            setState(() {
              _maxClipSeconds = value;
              _endValue = math.min(_endValue, _startValue + value * 1000);
              _exportedPath = null;
              _exportedBytes = null;
            });
          },
        ),
        _LifeSliderField(
          label: _lifeI18nText(context, 'toolbox.life.gif_maker.fps'),
          valueText: _lifeI18nText(
            context,
            'toolbox.life.gif_maker.fps_value',
            params: <String, Object?>{'fps': _fps.round()},
          ),
          value: _fps,
          min: 4,
          max: 15,
          divisions: 11,
          onChanged: (value) {
            if (_exporting) {
              return;
            }
            setState(() {
              _fps = value;
              _exportedPath = null;
              _exportedBytes = null;
            });
          },
        ),
        _LifeSliderField(
          label: _lifeI18nText(context, 'toolbox.life.gif_maker.width'),
          valueText: _lifeI18nText(
            context,
            'toolbox.life.gif_maker.pixels',
            params: <String, Object?>{'px': _targetWidth.round()},
          ),
          value: _targetWidth,
          min: 240,
          max: 720,
          divisions: 24,
          onChanged: (value) {
            if (_exporting) {
              return;
            }
            setState(() {
              _targetWidth = value;
              _exportedPath = null;
              _exportedBytes = null;
            });
          },
        ),
        _LifeSliderField(
          label: _lifeI18nText(context, 'toolbox.life.gif_maker.quality'),
          valueText: _lifeI18nText(
            context,
            'toolbox.life.gif_maker.quality_value',
            params: <String, Object?>{'quality': _quality.round()},
          ),
          value: _quality,
          min: 30,
          max: 90,
          divisions: 12,
          onChanged: (value) {
            if (_exporting) {
              return;
            }
            setState(() {
              _quality = value;
              _exportedPath = null;
              _exportedBytes = null;
            });
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _canExport ? _exportGif : null,
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_creation_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.life.gif_maker.make'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _exportedPath == null || _exporting ? null : _saveGif,
              icon: const Icon(Icons.save_alt_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.life.gif_maker.save'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'toolbox.life.gif_maker.metric_fps',
              ),
              value: _fps.round().toString(),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'toolbox.life.gif_maker.metric_width',
              ),
              value: _lifeI18nText(
                context,
                'toolbox.life.gif_maker.pixels',
                params: <String, Object?>{'px': _targetWidth.round()},
              ),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'toolbox.life.gif_maker.metric_size',
              ),
              value: _exportedBytes == null
                  ? '--'
                  : _lifeFormatBytes(_exportedBytes!),
            ),
          ],
        ),
        if (_exportedPath != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _lifeI18nText(
              context,
              'toolbox.life.common.saved_to',
              params: <String, Object?>{'path': _exportedPath},
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_errorKey != null) ...<Widget>[
          const SizedBox(height: 12),
          _LifeInlineNotice(
            icon: Icons.gif_box_rounded,
            text: _lifeI18nText(context, _errorKey!),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _trimmer.videoPlayerController;
    final initialized = controller?.value.isInitialized ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 220,
        color: Colors.black,
        alignment: Alignment.center,
        child: _loading
            ? const CircularProgressIndicator()
            : !initialized
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _lifeI18nText(context, 'toolbox.life.gif_maker.trim_empty'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              )
            : AspectRatio(
                aspectRatio: controller!.value.aspectRatio <= 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
      ),
    );
  }

  Widget _buildTrimRangeControls(BuildContext context) {
    final theme = Theme.of(context);
    final max = math.max(_videoDurationMs, 1.0);
    final start = _startValue.clamp(0.0, max);
    final end = _endValue.clamp(start, max);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _rangeText(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _durationText(_selectedDurationMs),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const <ui.FontFeature>[
                    ui.FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(start, end),
            min: 0,
            max: max,
            divisions: math.max(1, (max / 250).round()),
            labels: RangeLabels(_durationText(start), _durationText(end)),
            onChanged: _exporting
                ? null
                : (values) {
                    final limitedEnd = math.min(
                      values.end,
                      values.start + _maxClipSeconds * 1000,
                    );
                    setState(() {
                      _startValue = values.start;
                      _endValue = math.max(values.start, limitedEnd);
                      _exportedPath = null;
                      _exportedBytes = null;
                    });
                  },
            onChangeEnd: (values) {
              _trimmer.videoPlayerController?.seekTo(
                Duration(milliseconds: values.start.round()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _lifeGifMakerVideoExtensions,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final filePath = picked.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      setState(() => _errorKey = 'toolbox.life.gif_maker.error_no_path');
      return;
    }
    final file = File(filePath);
    if (!await file.exists()) {
      setState(() => _errorKey = 'toolbox.life.gif_maker.error_no_path');
      return;
    }
    final displayName = picked.files.single.name;
    final oldTrimmer = _trimmer;
    final nextTrimmer = Trimmer();
    setState(() {
      _trimmer = nextTrimmer;
      _videoFile = file;
      _videoName = displayName;
      _videoProbe = null;
      _startValue = 0;
      _endValue = 0;
      _videoDurationMs = 0;
      _loading = true;
      _isPlaying = false;
      _exportedPath = null;
      _exportedBytes = null;
      _errorKey = null;
    });
    _disposeTrimmerAfterFrame(oldTrimmer);

    late final _LifeVideoProbe probe;
    try {
      probe = await _probeLifeGifMakerVideo(file, displayName);
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeGifMaker',
        'video container probe failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'platform': defaultTargetPlatform.name,
          'sourcePath': filePath,
          'sourceBytes': await file.length(),
          'extension': path.extension(filePath).toLowerCase(),
        },
      );
      if (mounted && identical(_trimmer, nextTrimmer)) {
        setState(() {
          _loading = false;
          _errorKey = 'toolbox.life.gif_maker.error_probe_failed';
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (!identical(_trimmer, nextTrimmer)) {
      _disposeTrimmer(nextTrimmer);
      return;
    }
    setState(() => _videoProbe = probe);

    if (!_supportsNativeGifMakerPlatform) {
      setState(() {
        _loading = false;
        _videoProbe = probe;
        _errorKey = 'toolbox.life.gif_maker.error_unsupported_platform';
      });
      return;
    }

    late final File importedFile;
    try {
      importedFile = await _copyVideoToImportCache(file, displayName);
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeGifMaker',
        'video import cache copy failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'platform': defaultTargetPlatform.name,
          'sourcePath': filePath,
          'sourceBytes': await file.length(),
        },
      );
      if (mounted && identical(_trimmer, nextTrimmer)) {
        setState(() {
          _loading = false;
          _videoProbe = probe;
          _errorKey = 'toolbox.life.gif_maker.error_no_path';
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (!identical(_trimmer, nextTrimmer)) {
      _disposeTrimmer(nextTrimmer);
      return;
    }
    setState(() {
      _videoFile = importedFile;
      _videoProbe = probe;
    });
    await Future<void>.delayed(Duration.zero);
    try {
      await nextTrimmer.loadVideo(videoFile: importedFile);
      final duration = nextTrimmer.videoPlayerController?.value.duration;
      if (!mounted) {
        return;
      }
      if (!identical(_trimmer, nextTrimmer)) {
        _disposeTrimmer(nextTrimmer);
        return;
      }
      final durationMs = duration?.inMilliseconds.toDouble() ?? 0;
      setState(() {
        _videoDurationMs = durationMs;
        _endValue = math.min(durationMs, _maxClipSeconds * 1000);
        _loading = false;
        _errorKey = durationMs <= 0
            ? 'toolbox.life.gif_maker.error_zero_duration'
            : null;
      });
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeGifMaker',
        'video load failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'platform': defaultTargetPlatform.name,
          'sourcePath': filePath,
          'importedPath': importedFile.path,
          'sourceBytes': await file.length(),
          'importedBytes': await importedFile.length(),
          'extension': path.extension(filePath).toLowerCase(),
          ...probe.toLogData(),
          'controllerError':
              nextTrimmer.videoPlayerController?.value.errorDescription,
        },
      );
      if (!mounted) {
        return;
      }
      if (!identical(_trimmer, nextTrimmer)) {
        _disposeTrimmer(nextTrimmer);
        return;
      }
      setState(() {
        _loading = false;
        _videoProbe = probe;
        _errorKey = 'toolbox.life.gif_maker.error_decode_failed';
      });
    }
  }

  void _clearVideo() {
    final oldTrimmer = _trimmer;
    setState(() {
      _trimmer = Trimmer();
      _videoFile = null;
      _videoName = null;
      _startValue = 0;
      _endValue = 0;
      _videoDurationMs = 0;
      _isPlaying = false;
      _exportedPath = null;
      _exportedBytes = null;
      _errorKey = null;
      _videoProbe = null;
    });
    _disposeTrimmerAfterFrame(oldTrimmer);
  }

  Future<void> _togglePreview() async {
    if (!_supportsNativeGifMakerPlatform || !_hasVideo) {
      return;
    }
    final playing = await _trimmer.videoPlaybackControl(
      startValue: _startValue,
      endValue: _endValue,
    );
    if (mounted) {
      setState(() => _isPlaying = playing);
    }
  }

  Future<void> _exportGif() async {
    if (!_supportsNativeGifMakerPlatform) {
      setState(
        () => _errorKey = 'toolbox.life.gif_maker.error_unsupported_platform',
      );
      return;
    }
    if (!_canExport) {
      return;
    }
    setState(() {
      _exporting = true;
      _isPlaying = false;
      _exportedPath = null;
      _exportedBytes = null;
      _errorKey = null;
    });
    try {
      await _trimmer.videoPlayerController?.pause();
      String? outputPath;
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        outputType: OutputType.gif,
        fpsGIF: _fps.round(),
        scaleGIF: _targetWidth.round(),
        qualityGIF: _quality.round(),
        storageDir: StorageDir.temporaryDirectory,
        videoFolderName: 'gif_maker',
        videoFileName:
            'life_video_gif_${DateTime.now().millisecondsSinceEpoch}',
        onSave: (path) => outputPath = path,
      );
      if (!mounted) {
        return;
      }
      final path = outputPath;
      final file = path == null ? null : File(path);
      final exists = file != null && await file.exists();
      if (!exists) {
        throw StateError('gif export failed');
      }
      setState(() {
        _exportedPath = path;
        _exportedBytes = file.lengthSync();
      });
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'LifeGifMaker',
        'gif export failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'platform': defaultTargetPlatform.name,
          'videoPath': _videoFile?.path,
          'startMs': _startValue.round(),
          'endMs': _endValue.round(),
          'fps': _fps.round(),
          'width': _targetWidth.round(),
          'quality': _quality.round(),
        },
      );
      if (mounted) {
        setState(
          () => _errorKey = 'toolbox.life.gif_maker.error_frame_extract_failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _saveGif() async {
    final exportPath = _exportedPath;
    if (exportPath == null) {
      return;
    }
    final file = File(exportPath);
    if (!await file.exists()) {
      if (mounted) {
        setState(() => _errorKey = 'toolbox.life.gif_maker.error_save');
      }
      return;
    }
    final saved = await _saveLifeBytes(
      context: context,
      bytes: await file.readAsBytes(),
      fileName: path.basename(exportPath),
      subdirectory: 'gif_maker',
      dialogTitleKey: 'toolbox.life.gif_maker.save_dialog',
      allowedExtensions: const <String>['gif'],
    );
    if (mounted) {
      setState(() => _exportedPath = saved);
    }
  }

  double get _selectedDurationMs => math.max(0, _endValue - _startValue);

  String _rangeText() {
    if (!_hasVideo) {
      return '--';
    }
    return '${_durationText(_startValue)} - ${_durationText(_endValue)}';
  }

  String _durationText(double milliseconds) {
    final totalSeconds = (milliseconds / 1000).clamp(0, double.infinity);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds - minutes * 60;
    return '$minutes:${seconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  Future<File> _copyVideoToImportCache(File source, String displayName) async {
    final tempDir = await getTemporaryDirectory();
    final importDir = Directory(
      path.join(tempDir.path, 'life_tools', 'gif_maker', 'imports'),
    );
    if (!await importDir.exists()) {
      await importDir.create(recursive: true);
    }
    final extension = _safeVideoExtension(displayName, source.path);
    final target = File(
      path.join(
        importDir.path,
        'video_import_${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );
    return source.copy(target.path);
  }
}

void _disposeTrimmerAfterFrame(Trimmer trimmer) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _disposeTrimmer(trimmer);
  });
}

void _disposeTrimmer(Trimmer trimmer) {
  final controller = trimmer.videoPlayerController;
  if (controller != null) {
    unawaited(controller.dispose());
  }
  trimmer.dispose();
}

class _LifeVideoProbe {
  const _LifeVideoProbe({
    required this.bytes,
    required this.extension,
    required this.isMp4Candidate,
    required this.isMp4Container,
    required this.topLevelBoxes,
    this.majorBrand,
    this.compatibleBrands = const <String>[],
    this.moovOffset,
    this.mdatOffset,
  });

  final int bytes;
  final String extension;
  final bool isMp4Candidate;
  final bool isMp4Container;
  final List<String> topLevelBoxes;
  final String? majorBrand;
  final List<String> compatibleBrands;
  final int? moovOffset;
  final int? mdatOffset;

  String get containerLabel {
    if (!isMp4Candidate) {
      return extension.isEmpty ? 'video' : extension.toUpperCase();
    }
    final brands = <String>[
      if (majorBrand != null) majorBrand!,
      ...compatibleBrands,
    ];
    final uniqueBrands = <String>[];
    for (final brand in brands) {
      if (brand.isNotEmpty && !uniqueBrands.contains(brand)) {
        uniqueBrands.add(brand);
      }
    }
    final suffix = uniqueBrands.take(3).join('/');
    return suffix.isEmpty ? 'MP4' : 'MP4 $suffix';
  }

  Map<String, Object?> toLogData() {
    return <String, Object?>{
      'probeBytes': bytes,
      'probeExtension': extension,
      'probeMp4Candidate': isMp4Candidate,
      'probeMp4Container': isMp4Container,
      'probeMajorBrand': majorBrand,
      'probeCompatibleBrands': compatibleBrands,
      'probeTopLevelBoxes': topLevelBoxes,
      'probeMoovOffset': moovOffset,
      'probeMdatOffset': mdatOffset,
    };
  }
}

Future<_LifeVideoProbe> _probeLifeGifMakerVideo(
  File file,
  String displayName,
) async {
  final bytes = await file.length();
  final extension = _normalizedVideoExtension(displayName, file.path);
  final isMp4Candidate = _lifeGifMakerMp4Extensions.contains(extension);
  if (!isMp4Candidate || bytes < 8) {
    return _LifeVideoProbe(
      bytes: bytes,
      extension: extension,
      isMp4Candidate: isMp4Candidate,
      isMp4Container: false,
      topLevelBoxes: const <String>[],
    );
  }

  final boxes = <String>[];
  String? majorBrand;
  final compatibleBrands = <String>[];
  int? moovOffset;
  int? mdatOffset;

  final reader = await file.open();
  try {
    var offset = 0;
    var boxCount = 0;
    while (offset + 8 <= bytes && boxCount < 256) {
      await reader.setPosition(offset);
      final header = await reader.read(8);
      if (header.length < 8) {
        break;
      }
      var boxSize = _readLifeGifMakerUint32(header, 0);
      final boxType = _lifeGifMakerFourCc(header, 4);
      var headerSize = 8;
      if (boxSize == 1) {
        final extended = await reader.read(8);
        if (extended.length < 8) {
          break;
        }
        boxSize = _readLifeGifMakerUint64(extended, 0);
        headerSize = 16;
      } else if (boxSize == 0) {
        boxSize = bytes - offset;
      }
      if (boxSize < headerSize || offset + boxSize > bytes) {
        break;
      }
      boxes.add(boxType);
      if (boxType == 'moov') {
        moovOffset ??= offset;
      } else if (boxType == 'mdat') {
        mdatOffset ??= offset;
      } else if (boxType == 'ftyp') {
        final payloadLength = math.min(boxSize - headerSize, 256);
        final payload = await reader.read(payloadLength);
        if (payload.length >= 8) {
          majorBrand = _lifeGifMakerFourCc(payload, 0);
          for (var index = 8; index + 4 <= payload.length; index += 4) {
            compatibleBrands.add(_lifeGifMakerFourCc(payload, index));
          }
        }
      }
      offset += boxSize;
      boxCount += 1;
    }
  } finally {
    await reader.close();
  }

  final isMp4Container = majorBrand != null || boxes.contains('moov');
  return _LifeVideoProbe(
    bytes: bytes,
    extension: extension,
    isMp4Candidate: isMp4Candidate,
    isMp4Container: isMp4Container,
    topLevelBoxes: boxes.take(12).toList(growable: false),
    majorBrand: majorBrand,
    compatibleBrands: compatibleBrands.take(8).toList(growable: false),
    moovOffset: moovOffset,
    mdatOffset: mdatOffset,
  );
}

const List<String> _lifeGifMakerVideoExtensions = <String>[
  'mp4',
  'm4v',
  'mov',
  'webm',
  '3gp',
  '3gpp',
  'avi',
  'mkv',
  'wmv',
  'mpeg',
  'mpg',
];

const Set<String> _lifeGifMakerMp4Extensions = <String>{
  'mp4',
  'm4v',
  'mov',
  '3gp',
  '3gpp',
};

bool get _supportsNativeGifMakerPlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

String _safeVideoExtension(String displayName, String filePath) {
  final normalized = _normalizedVideoExtension(displayName, filePath);
  if (_lifeGifMakerVideoExtensions.contains(normalized)) {
    return '.$normalized';
  }
  return '.mp4';
}

String _normalizedVideoExtension(String displayName, String filePath) {
  final displayExtension = path.extension(displayName).toLowerCase();
  final sourceExtension = path.extension(filePath).toLowerCase();
  final extension = displayExtension.isNotEmpty
      ? displayExtension
      : sourceExtension;
  return extension.startsWith('.') ? extension.substring(1) : extension;
}

int _readLifeGifMakerUint32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _readLifeGifMakerUint64(List<int> bytes, int offset) {
  var value = 0;
  for (var index = offset; index < offset + 8; index += 1) {
    value = (value << 8) | bytes[index];
  }
  return value;
}

String _lifeGifMakerFourCc(List<int> bytes, int offset) {
  final chars = <int>[];
  for (var index = offset; index < offset + 4; index += 1) {
    final byte = bytes[index];
    chars.add(byte >= 32 && byte <= 126 ? byte : 0x2e);
  }
  return String.fromCharCodes(chars);
}

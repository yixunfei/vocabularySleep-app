part of '../toolbox_life_tools.dart';

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

extension _ToolboxArchiveCreateFormatUi on ToolboxArchiveCreateFormat {
  String get labelKey => switch (this) {
    ToolboxArchiveCreateFormat.zip => 'toolbox.life.archive_tool.format_zip',
    ToolboxArchiveCreateFormat.tar => 'toolbox.life.archive_tool.format_tar',
    ToolboxArchiveCreateFormat.tarGzip =>
      'toolbox.life.archive_tool.format_tar_gzip',
    ToolboxArchiveCreateFormat.tarBzip2 =>
      'toolbox.life.archive_tool.format_tar_bzip2',
    ToolboxArchiveCreateFormat.tarXz =>
      'toolbox.life.archive_tool.format_tar_xz',
    ToolboxArchiveCreateFormat.gzip => 'toolbox.life.archive_tool.format_gzip',
    ToolboxArchiveCreateFormat.bzip2 =>
      'toolbox.life.archive_tool.format_bzip2',
    ToolboxArchiveCreateFormat.xz => 'toolbox.life.archive_tool.format_xz',
  };
}

const List<_LifeOption<ToolboxArchiveCreateFormat>>
_lifeArchiveCreateFormatOptions = <_LifeOption<ToolboxArchiveCreateFormat>>[
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.zip,
    labelKey: 'toolbox.life.archive_tool.format_zip',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.tar,
    labelKey: 'toolbox.life.archive_tool.format_tar',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.tarGzip,
    labelKey: 'toolbox.life.archive_tool.format_tar_gzip',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.tarBzip2,
    labelKey: 'toolbox.life.archive_tool.format_tar_bzip2',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.tarXz,
    labelKey: 'toolbox.life.archive_tool.format_tar_xz',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.gzip,
    labelKey: 'toolbox.life.archive_tool.format_gzip',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.bzip2,
    labelKey: 'toolbox.life.archive_tool.format_bzip2',
  ),
  _LifeOption<ToolboxArchiveCreateFormat>(
    value: ToolboxArchiveCreateFormat.xz,
    labelKey: 'toolbox.life.archive_tool.format_xz',
  ),
];

const List<_LifeOption<ToolboxArchiveCompressionLevel>>
_lifeArchiveCompressionLevelOptions =
    <_LifeOption<ToolboxArchiveCompressionLevel>>[
      _LifeOption<ToolboxArchiveCompressionLevel>(
        value: ToolboxArchiveCompressionLevel.store,
        labelKey: 'toolbox.life.archive_tool.level_store',
      ),
      _LifeOption<ToolboxArchiveCompressionLevel>(
        value: ToolboxArchiveCompressionLevel.fast,
        labelKey: 'toolbox.life.archive_tool.level_fast',
      ),
      _LifeOption<ToolboxArchiveCompressionLevel>(
        value: ToolboxArchiveCompressionLevel.balanced,
        labelKey: 'toolbox.life.archive_tool.level_balanced',
      ),
      _LifeOption<ToolboxArchiveCompressionLevel>(
        value: ToolboxArchiveCompressionLevel.bestSize,
        labelKey: 'toolbox.life.archive_tool.level_best_size',
      ),
    ];

const List<_LifeOption<ToolboxArchiveZipAlgorithm>>
_lifeArchiveZipAlgorithmOptions = <_LifeOption<ToolboxArchiveZipAlgorithm>>[
  _LifeOption<ToolboxArchiveZipAlgorithm>(
    value: ToolboxArchiveZipAlgorithm.store,
    labelKey: 'toolbox.life.archive_tool.algorithm_store',
  ),
  _LifeOption<ToolboxArchiveZipAlgorithm>(
    value: ToolboxArchiveZipAlgorithm.deflate,
    labelKey: 'toolbox.life.archive_tool.algorithm_deflate',
  ),
  _LifeOption<ToolboxArchiveZipAlgorithm>(
    value: ToolboxArchiveZipAlgorithm.bzip2,
    labelKey: 'toolbox.life.archive_tool.algorithm_bzip2',
  ),
];

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

String _lifeArchiveBaseNameWithoutCompoundExtension(String fileName) {
  final baseName = path.basename(fileName);
  final extension = _lifeCompoundExtension(baseName);
  if (extension.isEmpty) {
    return baseName;
  }
  return baseName.substring(0, baseName.length - extension.length);
}

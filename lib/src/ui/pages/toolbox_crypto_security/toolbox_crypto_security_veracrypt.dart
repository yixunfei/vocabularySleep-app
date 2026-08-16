part of '../toolbox_crypto_security.dart';

class _VeraCryptToolPage extends StatefulWidget {
  const _VeraCryptToolPage();

  @override
  State<_VeraCryptToolPage> createState() => _VeraCryptToolPageState();
}

class _VeraCryptCreateSource {
  const _VeraCryptCreateSource({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;
}

class _VeraCryptToolPageState extends State<_VeraCryptToolPage> {
  static const Color _accent = Color(0xFF315F92);

  final ToolboxVeraCryptService _service = ToolboxVeraCryptService();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _pimController = TextEditingController();

  ToolboxVeraCryptInspectionResult? _result;
  ToolboxVeraCryptKeyFileInspectionResult? _keyFileInspection;
  ToolboxVeraCryptHeaderUnlockResult? _unlockResult;
  ToolboxVeraCryptDataProbeResult? _dataProbeResult;
  // FS browse session state (PLAN_349).
  ToolboxVeraCryptUnlockedSession? _fsSession;
  ToolboxVeraCryptFat32Volume? _fsVolume;
  List<ToolboxVeraCryptFat32Entry> _fsCurrentEntries =
      const <ToolboxVeraCryptFat32Entry>[];
  final List<String> _fsPathSegments = <String>[];
  final List<int> _fsClusterStack = <int>[];
  ToolboxVeraCryptFat32Entry? _fsSelectedEntry;
  Uint8List? _fsSelectedFileBytes;
  String? _fsSelectedFileSha;
  bool _fsSelectedTruncated = false;
  bool _fsBusy = false;
  bool _fsExportBusy = false;
  String? _fsStatus;
  List<_VeraCryptCreateSource> _createSources =
      const <_VeraCryptCreateSource>[];
  bool _createBusy = false;
  String? _createStatus;
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _keyFileName;
  String? _error;
  bool _busy = false;
  bool _keyFileBusy = false;
  bool _unlockBusy = false;
  bool _dataProbeBusy = false;
  bool _showAdvancedUnlock = false;

  @override
  void initState() {
    super.initState();
    _passphraseController.addListener(_handleUnlockMaterialChanged);
    _pimController.addListener(_handleUnlockMaterialChanged);
  }

  @override
  void dispose() {
    _passphraseController.removeListener(_handleUnlockMaterialChanged);
    _pimController.removeListener(_handleUnlockMaterialChanged);
    _passphraseController.dispose();
    _pimController.dispose();
    // Best-effort synchronous close path; the session close itself is async and
    // zeroes the key material. We cannot await here, so trigger it unawaited.
    _fsSession?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.veracrypt.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.veracrypt.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 14),
          if (_error != null) ...<Widget>[
            ToolboxSurfaceCard(
              radius: ToolboxUiTokens.cardRadius,
              color: colorScheme.errorContainer.withValues(alpha: 0.62),
              borderColor: colorScheme.error.withValues(alpha: 0.26),
              shadowOpacity: 0,
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.container_section',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.container_section_subtitle',
            ),
            children: <Widget>[
              FilledButton.icon(
                key: const ValueKey<String>('crypto_veracrypt_pick_button'),
                onPressed: _busy ? null : _pickContainer,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.veracrypt.pick_container',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedFileName == null
                    ? _lifeI18nText(
                        context,
                        'toolbox.crypto.veracrypt.no_container',
                      )
                    : _lifeI18nText(
                        context,
                        'toolbox.crypto.veracrypt.selected_container',
                        params: <String, Object?>{'name': _selectedFileName},
                      ),
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_result != null) ...<Widget>[
            _buildResultPanel(context, _result!),
            const SizedBox(height: 14),
          ],
          _buildUnlockPanel(context),
          const SizedBox(height: 14),
          if (_unlockResult != null) ...<Widget>[
            _VeraCryptHeaderUnlockResultPanel(
              result: _unlockResult!,
              accent: _accent,
            ),
            const SizedBox(height: 14),
          ],
          if (_dataProbeResult != null) ...<Widget>[
            _VeraCryptDataProbeResultPanel(
              result: _dataProbeResult!,
              accent: _accent,
            ),
            const SizedBox(height: 14),
          ],
          _VeraCryptFsBrowsePanel(accent: _accent, state: this),
          const SizedBox(height: 14),
          _buildCreateContainerPanel(context),
          const SizedBox(height: 14),
          const _VeraCryptBoundaryPanel(),
        ],
      ),
    );
  }

  Widget _buildStageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = _unlockSummary;
    final readinessLabel = _result == null
        ? _lifeI18nText(context, 'toolbox.crypto.veracrypt.status_waiting')
        : _readinessText(context, _result!.readiness);
    final materialLabel = _materialStatusText(context, summary);
    final materialStatusColor = _materialStatusColor(context, summary);
    final nextAction = _nextActionText(context, summary);
    return ToolboxSurfaceCard(
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: colorScheme.surfaceContainerLowest,
      borderColor: _accent.withValues(alpha: 0.22),
      shadowColor: _accent,
      shadowOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.lock_open_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.veracrypt.stage_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.veracrypt.stage_subtitle',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: readinessLabel,
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              if (_result != null)
                ToolboxInfoPill(
                  text: _containerKindText(context, _result!.containerKind),
                  accent: _accent,
                  backgroundColor: _accent.withValues(alpha: 0.08),
                ),
              ToolboxInfoPill(
                text: materialLabel,
                accent: materialStatusColor,
                backgroundColor: materialStatusColor.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.mobile_first',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.read_only_roadmap',
                ),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.next_plan_rounded, color: _accent, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextAction,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockPanel(BuildContext context) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.veracrypt.unlock_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.unlock_section_subtitle',
      ),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('crypto_veracrypt_passphrase_field'),
          controller: _passphraseController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.passphrase',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            setState(() => _showAdvancedUnlock = !_showAdvancedUnlock);
          },
          icon: Icon(
            _showAdvancedUnlock
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
          ),
          label: Text(
            _lifeI18nText(context, 'toolbox.crypto.veracrypt.advanced_unlock'),
          ),
        ),
        if (_showAdvancedUnlock) ...<Widget>[
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('crypto_veracrypt_pim_field'),
            controller: _pimController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _lifeI18nText(context, 'toolbox.crypto.veracrypt.pim'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey<String>('crypto_veracrypt_keyfile_button'),
            onPressed: _keyFileBusy ? null : _pickKeyFile,
            icon: _keyFileBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.vpn_key_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.crypto.veracrypt.pick_keyfile'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _keyFileInspection == null ? null : _clearKeyFile,
            icon: const Icon(Icons.key_off_rounded),
            label: Text(
              _lifeI18nText(context, 'toolbox.crypto.veracrypt.clear_keyfile'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _keyFileName == null
                ? _lifeI18nText(context, 'toolbox.crypto.veracrypt.no_keyfile')
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.veracrypt.selected_keyfile',
                    params: <String, Object?>{'name': _keyFileName},
                  ),
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
        const SizedBox(height: 12),
        ..._buildUnlockActionChildren(context, _unlockSummary),
      ],
    );
  }

  Widget _buildCreateContainerPanel(BuildContext context) {
    final theme = Theme.of(context);
    final canCreate =
        !_createBusy &&
        _createSources.isNotEmpty &&
        _passphraseController.text.isNotEmpty;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.veracrypt.create.section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.create.section_subtitle',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              key: const ValueKey<String>(
                'crypto_veracrypt_create_pick_file_button',
              ),
              onPressed: _createBusy ? null : _pickCreateSourceFile,
              icon: const Icon(Icons.file_open_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.create.pick_file',
                ),
              ),
            ),
            FilledButton.icon(
              key: const ValueKey<String>(
                'crypto_veracrypt_create_container_button',
              ),
              onPressed: canCreate ? _createEncryptedContainer : null,
              icon: _createBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.enhanced_encryption_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  _createBusy
                      ? 'toolbox.crypto.veracrypt.create.creating'
                      : 'toolbox.crypto.veracrypt.create.button',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _createSources.isEmpty
              ? _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.create.no_source',
                )
              : _createSources.length == 1
              ? _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.create.selected_source',
                  params: <String, Object?>{'name': _createSources.single.name},
                )
              : _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.create.selected_sources',
                  params: <String, Object?>{
                    'count': _createSources.length,
                    'size': _formatBytes(
                      _createSources.fold<int>(
                        0,
                        (sum, source) => sum + source.size,
                      ),
                    ),
                  },
                ),
          style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        if (_createStatus != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _createStatus!,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildUnlockActionChildren(
    BuildContext context,
    ToolboxVeraCryptUnlockMaterialSummary summary,
  ) {
    final theme = Theme.of(context);
    final keyFile = summary.keyFile;
    final canAttempt = _canAttemptHeaderUnlock(summary);
    final statusColor = _materialStatusColor(context, summary);
    return <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          ToolboxInfoPill(
            text: _materialStatusText(context, summary),
            accent: statusColor,
            backgroundColor: statusColor.withValues(alpha: 0.08),
          ),
          ToolboxInfoPill(
            text: summary.hasPassphrase
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.veracrypt.passphrase_length',
                    params: <String, Object?>{
                      'count': summary.passphraseLength,
                    },
                  )
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.veracrypt.passphrase_not_set',
                  ),
            accent: _accent,
            backgroundColor: _accent.withValues(alpha: 0.08),
          ),
          ToolboxInfoPill(
            text: _pimStatusText(context, summary.pimStatus),
            accent: statusColor,
            backgroundColor: statusColor.withValues(alpha: 0.08),
          ),
          ToolboxInfoPill(
            text: _keyFileStatusText(context, summary),
            accent: _accent,
            backgroundColor: _accent.withValues(alpha: 0.08),
          ),
        ],
      ),
      if (keyFile != null) ...<Widget>[
        const SizedBox(height: 14),
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.keyfile_size',
          ),
          value: _formatBytes(keyFile.fileSize),
        ),
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.keyfile_sample',
          ),
          value: _lifeI18nText(
            context,
            keyFile.isTruncated
                ? 'toolbox.crypto.veracrypt.keyfile_sample_truncated'
                : 'toolbox.crypto.veracrypt.keyfile_sample_complete',
            params: <String, Object?>{
              'bytes': keyFile.bytesHashed,
              'limit': keyFile.maxBytesHashed,
            },
          ),
        ),
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.keyfile_fingerprint',
          ),
          value: keyFile.sha256Preview.isEmpty
              ? _lifeI18nText(context, 'toolbox.crypto.veracrypt.none')
              : keyFile.sha256Preview,
        ),
      ],
      const SizedBox(height: 12),
      Text(
        _lifeI18nText(context, 'toolbox.crypto.veracrypt.kdf_candidates'),
        style: theme.textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: summary.candidateKdfLabelKeys
            .map(
              (key) => ToolboxInfoPill(
                text: _lifeI18nText(context, key),
                accent: _accent,
                backgroundColor: _accent.withValues(alpha: 0.08),
              ),
            )
            .toList(growable: false),
      ),
      const SizedBox(height: 12),
      ...summary.notes.map(
        (key) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                key == 'toolbox.crypto.veracrypt.note.pim_invalid'
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: key == 'toolbox.crypto.veracrypt.note.pim_invalid'
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lifeI18nText(context, key),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        key: const ValueKey<String>('crypto_veracrypt_unlock_header_button'),
        onPressed: canAttempt ? _attemptHeaderUnlock : null,
        icon: _unlockBusy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_open_rounded),
        label: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.header_unlock_button',
          ),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const ValueKey<String>('crypto_veracrypt_data_probe_button'),
        onPressed: _canProbeDataArea(summary) ? _attemptDataProbe : null,
        icon: _dataProbeBusy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.storage_rounded),
        label: Text(
          _lifeI18nText(context, 'toolbox.crypto.veracrypt.data_probe_button'),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _lifeI18nText(
          context,
          _unlockResult?.success == true
              ? 'toolbox.crypto.veracrypt.data_probe_button_note'
              : 'toolbox.crypto.veracrypt.header_unlock_button_note',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    ];
  }

  Widget _buildResultPanel(
    BuildContext context,
    ToolboxVeraCryptInspectionResult result,
  ) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.veracrypt.result_section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.result_section_subtitle',
      ),
      children: <Widget>[
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.container_kind',
          ),
          value: _containerKindText(context, result.containerKind),
        ),
        _VeraCryptMetricRow(
          label: _lifeI18nText(context, 'toolbox.crypto.veracrypt.file_size'),
          value: _formatBytes(result.fileSize),
        ),
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.layout_floor',
          ),
          value: _formatBytes(result.minContainerBytes),
        ),
        const SizedBox(height: 8),
        Text(
          _lifeI18nText(context, 'toolbox.crypto.veracrypt.header_windows'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ...result.headerWindows.map(
          (window) => _VeraCryptMetricRow(
            label: _lifeI18nText(context, window.kind.labelKey),
            value: _headerWindowStatusText(context, window),
          ),
        ),
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.sha256_preview',
          ),
          value: result.sha256Preview.isEmpty
              ? _lifeI18nText(context, 'toolbox.crypto.veracrypt.none')
              : result.sha256Preview,
        ),
        const SizedBox(height: 12),
        Text(
          _lifeI18nText(context, 'toolbox.crypto.veracrypt.inspection_notes'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ...result.notes.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.info_outline_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lifeI18nText(context, key),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickContainer() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );
      final file = result?.files.single;
      if (file == null) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      final filePath = file.path;
      if (filePath == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.path_unavailable',
          );
          _busy = false;
        });
        return;
      }
      final inspection = await _service.inspectFile(
        file: File(filePath),
        fileName: file.name,
        fileSize: file.size > 0 ? file.size : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = inspection;
        _unlockResult = null;
        _dataProbeResult = null;
        _selectedFilePath = filePath;
        _selectedFileName = file.name;
        _resetFilesystemState();
        _busy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.pick_failed',
          params: <String, Object?>{'error': '$error'},
        );
        _busy = false;
      });
    }
  }

  Future<void> _pickCreateSourceFile() async {
    setState(() {
      _createBusy = true;
      _createStatus = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
        allowMultiple: true,
      );
      final files = result?.files;
      if (files == null || files.isEmpty) {
        if (mounted) {
          setState(() => _createBusy = false);
        }
        return;
      }
      final sources = <_VeraCryptCreateSource>[];
      for (final file in files) {
        final filePath = file.path;
        if (filePath == null || filePath.isEmpty) {
          continue;
        }
        sources.add(
          _VeraCryptCreateSource(
            path: filePath,
            name: file.name,
            size: file.size > 0 ? file.size : File(filePath).lengthSync(),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      if (sources.isEmpty) {
        setState(() {
          _createBusy = false;
          _createSources = const <_VeraCryptCreateSource>[];
          _createStatus = _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.create.source_path_unavailable',
          );
        });
        return;
      }
      setState(() {
        _createSources = sources;
        _createBusy = false;
        _createStatus = files.length == sources.length
            ? null
            : _lifeI18nText(
                context,
                'toolbox.crypto.veracrypt.create.source_path_unavailable',
              );
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _createBusy = false;
        _createStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.create.failed',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _createEncryptedContainer() async {
    final sources = List<_VeraCryptCreateSource>.of(_createSources);
    if (sources.isEmpty) {
      return;
    }
    if (_passphraseController.text.isEmpty) {
      setState(() {
        _createStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.create.need_passphrase',
        );
      });
      return;
    }
    final passphrase = _passphraseController.text;
    final pim = _pimController.text;
    final keyFile = _keyFileInspection;
    final saveDialogTitle = _lifeI18nText(
      context,
      'toolbox.crypto.veracrypt.create.save_dialog',
    );
    setState(() {
      _createBusy = true;
      _createStatus = null;
    });
    try {
      final createFiles = <ToolboxVeraCryptCreateFileInput>[];
      for (final source in sources) {
        final sourceBytes = await File(source.path).readAsBytes();
        createFiles.add(
          ToolboxVeraCryptCreateFileInput(
            name: source.name,
            bytes: sourceBytes,
          ),
        );
      }
      final created = _service.createContainerBytes(
        passphrase: passphrase,
        pim: pim,
        keyFile: keyFile,
        files: createFiles,
      );
      if (!mounted) {
        return;
      }
      final suggestedName = sources.length == 1
          ? '${path.basenameWithoutExtension(sources.single.name)}.hc'
          : 'veracrypt_container.hc';
      String? picked;
      try {
        picked = await FilePicker.platform.saveFile(
          dialogTitle: saveDialogTitle,
          fileName: suggestedName,
          type: FileType.custom,
          allowedExtensions: const <String>['hc'],
          bytes: kIsWeb ? created.containerBytes : null,
        );
      } on UnimplementedError {
        picked = null;
      }
      String savedPath;
      if (picked != null && picked.isNotEmpty) {
        await File(picked).writeAsBytes(created.containerBytes, flush: true);
        savedPath = picked;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final outDir = Directory(
          path.join(dir.path, 'crypto_security', 'veracrypt_create'),
        );
        if (!outDir.existsSync()) {
          outDir.createSync(recursive: true);
        }
        savedPath = path.join(outDir.path, suggestedName);
        await File(savedPath).writeAsBytes(created.containerBytes, flush: true);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _createBusy = false;
        _createStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.create.success',
          params: <String, Object?>{
            'path': savedPath,
            'size': _formatBytes(created.containerSize),
          },
        );
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _createBusy = false;
        _createStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.create.failed',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _pickKeyFile() async {
    setState(() {
      _keyFileBusy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );
      final file = result?.files.single;
      if (file == null) {
        if (mounted) {
          setState(() => _keyFileBusy = false);
        }
        return;
      }
      final filePath = file.path;
      if (filePath == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.keyfile_path_unavailable',
          );
          _keyFileBusy = false;
        });
        return;
      }
      final inspection = await _service.inspectKeyFile(
        file: File(filePath),
        fileName: file.name,
        fileSize: file.size > 0 ? file.size : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _keyFileName = file.name;
        _keyFileInspection = inspection;
        _unlockResult = null;
        _dataProbeResult = null;
        _keyFileBusy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.keyfile_pick_failed',
          params: <String, Object?>{'error': '$error'},
        );
        _keyFileBusy = false;
      });
    }
  }

  void _clearKeyFile() {
    setState(() {
      _keyFileName = null;
      _keyFileInspection = null;
      _unlockResult = null;
      _dataProbeResult = null;
      _resetFilesystemState();
    });
  }

  void _handleUnlockMaterialChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _unlockResult = null;
      _dataProbeResult = null;
      _resetFilesystemState();
    });
  }

  Future<void> _attemptHeaderUnlock() async {
    final filePath = _selectedFilePath;
    if (filePath == null) {
      return;
    }
    setState(() {
      _unlockBusy = true;
      _dataProbeResult = null;
      _resetFilesystemState();
      _error = null;
    });
    try {
      final result = await _service.attemptPrimaryHeaderUnlock(
        file: File(filePath),
        passphrase: _passphraseController.text,
        pim: _pimController.text,
        keyFile: _keyFileInspection,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _unlockResult = result;
        _unlockBusy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.header_unlock_error',
          params: <String, Object?>{'error': '$error'},
        );
        _unlockBusy = false;
      });
    }
  }

  Future<void> _attemptDataProbe() async {
    final filePath = _selectedFilePath;
    if (filePath == null) {
      return;
    }
    setState(() {
      _dataProbeBusy = true;
      _resetFilesystemState();
      _error = null;
    });
    try {
      final result = await _service.probePrimaryDataArea(
        file: File(filePath),
        passphrase: _passphraseController.text,
        pim: _pimController.text,
        keyFile: _keyFileInspection,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _dataProbeResult = result;
        _dataProbeBusy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.data_probe_error',
          params: <String, Object?>{'error': '$error'},
        );
        _dataProbeBusy = false;
      });
    }
  }

  // ============ FS browse/export (PLAN_349) ============

  void _resetFilesystemState({bool closeSession = true}) {
    if (closeSession) {
      _fsSession?.close();
    }
    _fsSession = null;
    _fsVolume = null;
    _fsCurrentEntries = const <ToolboxVeraCryptFat32Entry>[];
    _fsPathSegments.clear();
    _fsClusterStack.clear();
    _fsSelectedEntry = null;
    _fsSelectedFileBytes = null;
    _fsSelectedFileSha = null;
    _fsSelectedTruncated = false;
    _fsBusy = false;
    _fsExportBusy = false;
    _fsStatus = null;
  }

  Future<void> _openFilesystem() async {
    final filePath = _selectedFilePath;
    if (filePath == null || _unlockResult?.success != true) {
      return;
    }
    // Guard against re-entry leaking the previous session's file handle: if a
    // session is somehow still open (race, double-tap), close it before we
    // open a new one. _resetFilesystemState(closeSession:false) below only
    // clears references, so the explicit await here is what actually releases
    // the underlying RandomAccessFile promptly instead of waiting for GC.
    final previousSession = _fsSession;
    if (previousSession != null && !previousSession.isClosed) {
      await previousSession.close();
    }
    setState(() {
      _fsBusy = true;
      _fsStatus = _lifeI18nText(context, 'toolbox.crypto.veracrypt.fs.opening');
      _error = null;
    });
    _resetFilesystemState(closeSession: false);
    try {
      final open = await _service.openSession(
        file: File(filePath),
        passphrase: _passphraseController.text,
        pim: _pimController.text,
        keyFile: _keyFileInspection,
      );
      if (!mounted) {
        await open.session?.close();
        return;
      }
      if (!open.success) {
        setState(() {
          _fsBusy = false;
          _fsStatus = _lifeI18nText(context, open.status.labelKey);
        });
        return;
      }
      final session = open.session!;
      final volume = await session.openFat32Volume();
      final root = await volume.listDirectory(dirCluster: volume.rootCluster);
      if (!mounted) {
        await session.close();
        return;
      }
      setState(() {
        _fsSession = session;
        _fsVolume = volume;
        _fsCurrentEntries = root.entries;
        _fsPathSegments
          ..clear()
          ..add(
            _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.fs.breadcrumb_root',
            ),
          );
        _fsClusterStack
          ..clear()
          ..add(volume.rootCluster);
        _fsBusy = false;
        _fsStatus = null;
      });
    } on ToolboxVeraCryptFat32Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        final note = _lifeI18nText(context, error.noteKey);
        _fsStatus = error.message == null ? note : '$note\n${error.message}';
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        _fsStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.fs.note.io_failure',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _closeFilesystem() async {
    final session = _fsSession;
    if (session == null) {
      _resetFilesystemState();
      return;
    }
    setState(() {
      _fsBusy = true;
      _fsStatus = _lifeI18nText(context, 'toolbox.crypto.veracrypt.fs.closing');
    });
    await session.close();
    if (!mounted) {
      return;
    }
    setState(_resetFilesystemState);
  }

  Future<void> _enterDirectory(ToolboxVeraCryptFat32Entry entry) async {
    final volume = _fsVolume;
    if (volume == null || !entry.isDirectory) {
      return;
    }
    setState(() {
      _fsBusy = true;
      _fsStatus = null;
      _fsSelectedEntry = null;
      _fsSelectedFileBytes = null;
      _fsSelectedFileSha = null;
      _fsSelectedTruncated = false;
    });
    try {
      final result = await volume.listDirectory(dirCluster: entry.firstCluster);
      if (!mounted) {
        return;
      }
      setState(() {
        _fsCurrentEntries = result.entries;
        _fsPathSegments.add(entry.displayName);
        _fsClusterStack.add(entry.firstCluster);
        _fsBusy = false;
      });
    } on ToolboxVeraCryptFat32Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        final note = _lifeI18nText(context, error.noteKey);
        _fsStatus = error.message == null ? note : '$note\n${error.message}';
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        _fsStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.fs.note.io_failure',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _navigateToSegment(int segmentIndex) async {
    final volume = _fsVolume;
    if (volume == null || segmentIndex >= _fsClusterStack.length) {
      return;
    }
    if (segmentIndex == _fsClusterStack.length - 1) {
      // Already at this segment; nothing to do.
      return;
    }
    setState(() {
      _fsBusy = true;
      _fsStatus = null;
      _fsSelectedEntry = null;
      _fsSelectedFileBytes = null;
      _fsSelectedFileSha = null;
      _fsSelectedTruncated = false;
    });
    final targetCluster = _fsClusterStack[segmentIndex];
    try {
      final result = await volume.listDirectory(dirCluster: targetCluster);
      if (!mounted) {
        return;
      }
      setState(() {
        _fsCurrentEntries = result.entries;
        _fsPathSegments.removeRange(segmentIndex + 1, _fsPathSegments.length);
        _fsClusterStack.removeRange(segmentIndex + 1, _fsClusterStack.length);
        _fsBusy = false;
      });
    } on ToolboxVeraCryptFat32Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        final note = _lifeI18nText(context, error.noteKey);
        _fsStatus = error.message == null ? note : '$note\n${error.message}';
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        _fsStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.fs.note.io_failure',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _selectEntry(ToolboxVeraCryptFat32Entry entry) async {
    final volume = _fsVolume;
    if (volume == null || entry.isDirectory) {
      return;
    }
    setState(() {
      _fsBusy = true;
      _fsStatus = null;
      _fsSelectedEntry = entry;
      _fsSelectedFileBytes = null;
      _fsSelectedFileSha = null;
      _fsSelectedTruncated = false;
    });
    try {
      final result = await volume.readFile(entry: entry);
      if (!mounted) {
        return;
      }
      final sha = sha256.convert(result.bytes).toString();
      setState(() {
        _fsSelectedFileBytes = result.bytes;
        _fsSelectedFileSha = sha;
        _fsSelectedTruncated = result.truncated;
        _fsBusy = false;
      });
    } on ToolboxVeraCryptFat32Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        final note = _lifeI18nText(context, error.noteKey);
        _fsStatus = error.message == null ? note : '$note\n${error.message}';
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsBusy = false;
        _fsStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.fs.note.io_failure',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _exportSelected() async {
    final entry = _fsSelectedEntry;
    final bytes = _fsSelectedFileBytes;
    if (entry == null || bytes == null) {
      return;
    }
    setState(() {
      _fsExportBusy = true;
      _fsStatus = null;
    });
    try {
      final fileName = entry.displayName;
      final extension = _extensionOf(fileName);
      String? picked;
      try {
        picked = await FilePicker.platform.saveFile(
          dialogTitle: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.fs.export_button',
          ),
          fileName: fileName,
          type: extension == null ? FileType.any : FileType.custom,
          allowedExtensions: extension == null ? null : <String>[extension],
          bytes: kIsWeb ? bytes : null,
        );
      } on UnimplementedError {
        picked = null;
      }
      String? savedPath;
      if (picked != null && picked.isNotEmpty) {
        await File(picked).writeAsBytes(bytes, flush: true);
        savedPath = picked;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final outDir = Directory(
          path.join(dir.path, 'crypto_security', 'veracrypt_export'),
        );
        if (!outDir.existsSync()) {
          outDir.createSync(recursive: true);
        }
        final fallbackPath = path.join(outDir.path, fileName);
        await File(fallbackPath).writeAsBytes(bytes, flush: true);
        savedPath = fallbackPath;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _fsExportBusy = false;
        _fsStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.fs.export_success',
          params: <String, Object?>{'path': savedPath ?? fileName},
        );
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fsExportBusy = false;
        _fsStatus = _lifeI18nText(
          context,
          'toolbox.crypto.veracrypt.fs.export_failed',
          params: <String, Object?>{'error': '$error'},
        );
      });
    }
  }

  String? _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) {
      return null;
    }
    return fileName.substring(dot + 1).toLowerCase();
  }

  ToolboxVeraCryptUnlockMaterialSummary get _unlockSummary {
    return _service.summarizeUnlockMaterial(
      passphrase: _passphraseController.text,
      pim: _pimController.text,
      keyFile: _keyFileInspection,
    );
  }

  String _readinessText(
    BuildContext context,
    ToolboxVeraCryptReadiness readiness,
  ) {
    return switch (readiness) {
      ToolboxVeraCryptReadiness.noFile => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.status_waiting',
      ),
      ToolboxVeraCryptReadiness.tooSmall => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.status_too_small',
      ),
      ToolboxVeraCryptReadiness.inspectOnly => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.status_inspect_only',
      ),
      ToolboxVeraCryptReadiness.readyForHeaderUnlock => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.status_ready',
      ),
    };
  }

  String _containerKindText(
    BuildContext context,
    ToolboxVeraCryptContainerKind kind,
  ) {
    return _lifeI18nText(context, kind.labelKey);
  }

  String _materialStatusText(
    BuildContext context,
    ToolboxVeraCryptUnlockMaterialSummary summary,
  ) {
    if (summary.pimStatus == ToolboxVeraCryptPimStatus.invalid) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.material_invalid_pim',
      );
    }
    if (summary.canAttemptFutureHeaderUnlock) {
      return _lifeI18nText(context, 'toolbox.crypto.veracrypt.material_ready');
    }
    return _lifeI18nText(context, 'toolbox.crypto.veracrypt.material_needed');
  }

  Color _materialStatusColor(
    BuildContext context,
    ToolboxVeraCryptUnlockMaterialSummary summary,
  ) {
    if (summary.pimStatus == ToolboxVeraCryptPimStatus.invalid) {
      return Theme.of(context).colorScheme.error;
    }
    if (summary.canAttemptFutureHeaderUnlock) {
      return const Color(0xFF2F7A4B);
    }
    return const Color(0xFF6E5A11);
  }

  String _pimStatusText(
    BuildContext context,
    ToolboxVeraCryptPimStatus status,
  ) {
    return switch (status) {
      ToolboxVeraCryptPimStatus.none => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.pim_default',
      ),
      ToolboxVeraCryptPimStatus.valid => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.pim_valid',
      ),
      ToolboxVeraCryptPimStatus.invalid => _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.pim_invalid',
      ),
    };
  }

  String _keyFileStatusText(
    BuildContext context,
    ToolboxVeraCryptUnlockMaterialSummary summary,
  ) {
    if (summary.keyFile == null) {
      return _lifeI18nText(context, 'toolbox.crypto.veracrypt.keyfile_none');
    }
    if (summary.keyFile!.isEmpty) {
      return _lifeI18nText(context, 'toolbox.crypto.veracrypt.keyfile_empty');
    }
    return _lifeI18nText(context, 'toolbox.crypto.veracrypt.keyfile_ready');
  }

  String _headerWindowStatusText(
    BuildContext context,
    ToolboxVeraCryptHeaderWindow window,
  ) {
    if (!window.isReadable) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.header_unavailable',
      );
    }
    if (!window.hasSaltFingerprint) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.header_available_at',
        params: <String, Object?>{
          'offset': window.offset,
          'bytes': window.bytesAvailable,
        },
      );
    }
    return _lifeI18nText(
      context,
      'toolbox.crypto.veracrypt.header_available_with_salt',
      params: <String, Object?>{
        'offset': window.offset,
        'bytes': window.bytesAvailable,
        'fingerprint': window.saltFingerprint,
      },
    );
  }

  String _nextActionText(
    BuildContext context,
    ToolboxVeraCryptUnlockMaterialSummary summary,
  ) {
    if (_result == null) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_pick_container',
      );
    }
    if (_result!.readiness == ToolboxVeraCryptReadiness.tooSmall) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_choose_larger_container',
      );
    }
    if (_result!.readiness == ToolboxVeraCryptReadiness.inspectOnly) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_review_extension',
      );
    }
    if (!summary.canAttemptFutureHeaderUnlock) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_add_unlock_material',
      );
    }
    if (_fsSession != null && !_fsSession!.isClosed) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_filesystem_ready',
      );
    }
    if (_unlockResult?.success == true) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_open_filesystem',
      );
    }
    if (_dataProbeResult?.success == true) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.next_data_probe_done',
      );
    }
    return _lifeI18nText(
      context,
      'toolbox.crypto.veracrypt.next_attempt_header_unlock',
    );
  }

  bool _canAttemptHeaderUnlock(ToolboxVeraCryptUnlockMaterialSummary summary) {
    return !_unlockBusy &&
        _selectedFilePath != null &&
        _result?.readiness == ToolboxVeraCryptReadiness.readyForHeaderUnlock &&
        summary.canAttemptFutureHeaderUnlock;
  }

  bool _canProbeDataArea(ToolboxVeraCryptUnlockMaterialSummary summary) {
    return !_dataProbeBusy &&
        !_unlockBusy &&
        _selectedFilePath != null &&
        _result?.readiness == ToolboxVeraCryptReadiness.readyForHeaderUnlock &&
        _unlockResult?.success == true &&
        summary.canAttemptFutureHeaderUnlock;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final units = <String>['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} ${units[unitIndex]}';
  }
}

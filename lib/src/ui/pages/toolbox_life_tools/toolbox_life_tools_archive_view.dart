part of '../toolbox_life_tools.dart';

extension _ArchiveToolPageView on _ArchiveToolPageState {
  Widget buildArchiveView(BuildContext context) {
    final theme = Theme.of(context);
    final entries =
        _loadedArchive?.entries ?? const <ToolboxArchiveDecodedEntry>[];
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
              _LifeSegmentedField<ToolboxArchiveCreateFormat>(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.archive_tool.format',
                ),
                value: _createFormat,
                options: _lifeArchiveCreateFormatOptions,
                onChanged: _busy
                    ? (_) {}
                    : (value) => _updateArchiveState(() {
                        _createFormat = value;
                        _archiveBytes = null;
                        _savedPath = null;
                        if (!_createFormat.isZip) {
                          _zipAlgorithm = ToolboxArchiveZipAlgorithm.deflate;
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
              _LifeSegmentedField<ToolboxArchiveCompressionLevel>(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.archive_tool.level',
                ),
                value: _compressionLevel,
                options: _lifeArchiveCompressionLevelOptions,
                onChanged: _busy
                    ? (_) {}
                    : (value) => _updateArchiveState(() {
                        _compressionLevel = value;
                        _archiveBytes = null;
                        _savedPath = null;
                      }),
              ),
              const SizedBox(height: 12),
              if (_createFormat.isZip) ...<Widget>[
                _LifeSegmentedField<ToolboxArchiveZipAlgorithm>(
                  label: _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.algorithm',
                  ),
                  value: _zipAlgorithm,
                  options: _lifeArchiveZipAlgorithmOptions,
                  onChanged: _busy
                      ? (_) {}
                      : (value) => _updateArchiveState(() {
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
                  onChanged: (_) => _updateArchiveState(() {
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
                    _loadedFormat == ToolboxArchiveFormat.zip,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.life.archive_tool.extract_password',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    _loadedFormat == null ||
                            _loadedFormat == ToolboxArchiveFormat.zip
                        ? 'toolbox.life.archive_tool.password_optional'
                        : 'toolbox.life.archive_tool.password_not_available',
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_loadedFormat != ToolboxArchiveFormat.zip ||
                      _selectedArchiveBytes == null) {
                    return;
                  }
                  _updateArchiveState(() {
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
                    title: Text(entry.relativePath),
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
}

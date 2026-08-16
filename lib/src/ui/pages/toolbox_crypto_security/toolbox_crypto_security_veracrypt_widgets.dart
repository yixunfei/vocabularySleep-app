part of '../toolbox_crypto_security.dart';

class _VeraCryptMetricRow extends StatelessWidget {
  const _VeraCryptMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _VeraCryptHeaderUnlockResultPanel extends StatelessWidget {
  const _VeraCryptHeaderUnlockResultPanel({
    required this.result,
    required this.accent,
  });

  final ToolboxVeraCryptHeaderUnlockResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.success
        ? const Color(0xFF2F7A4B)
        : theme.colorScheme.error;
    final decoded = result.decodedHeader;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.header_unlock_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.header_unlock_section_subtitle',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxInfoPill(
              text: _lifeI18nText(context, result.status.labelKey),
              accent: color,
              backgroundColor: color.withValues(alpha: 0.08),
            ),
            if (decoded != null) ...<Widget>[
              ToolboxInfoPill(
                text: _lifeI18nText(context, decoded.kdf.labelKey),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
              ToolboxInfoPill(
                text: _lifeI18nText(
                  context,
                  'toolbox.crypto.veracrypt.header_unlock_aes_xts',
                ),
                accent: accent,
                backgroundColor: accent.withValues(alpha: 0.08),
              ),
            ],
          ],
        ),
        if (decoded != null) ...<Widget>[
          const SizedBox(height: 14),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_kdf',
            ),
            value: _lifeI18nText(context, decoded.kdf.labelKey),
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_iterations',
            ),
            value: '${decoded.iterations}',
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_version',
            ),
            value: '${decoded.headerVersion}',
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_required_version',
            ),
            value: _formatVeraCryptHexVersion(decoded.requiredProgramVersion),
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_volume_size',
            ),
            value: _formatVeraCryptBytes(decoded.volumeSize),
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_encrypted_area',
            ),
            value: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_area_value',
              params: <String, Object?>{
                'start': decoded.encryptedAreaStart,
                'length': _formatVeraCryptBytes(decoded.encryptedAreaLength),
              },
            ),
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_sector_size',
            ),
            value: '${decoded.sectorSize} B',
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.header_unlock_hidden_volume',
            ),
            value: decoded.hiddenVolume
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.veracrypt.header_unlock_hidden_yes',
                  )
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.veracrypt.note.hidden_header_area_present',
                  ),
          ),
        ],
        const SizedBox(height: 12),
        ...result.notes.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  result.success
                      ? Icons.verified_user_rounded
                      : Icons.info_outline_rounded,
                  color: result.success
                      ? const Color(0xFF2F7A4B)
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
      ],
    );
  }
}

class _VeraCryptDataProbeResultPanel extends StatelessWidget {
  const _VeraCryptDataProbeResultPanel({
    required this.result,
    required this.accent,
  });

  final ToolboxVeraCryptDataProbeResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = result.success
        ? const Color(0xFF2F7A4B)
        : theme.colorScheme.error;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.data_probe_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.data_probe_section_subtitle',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxInfoPill(
              text: _lifeI18nText(context, result.status.labelKey),
              accent: statusColor,
              backgroundColor: statusColor.withValues(alpha: 0.08),
            ),
            ToolboxInfoPill(
              text: _lifeI18nText(
                context,
                result.likelyFat32BootSector
                    ? 'toolbox.crypto.veracrypt.data_probe_fat32_yes'
                    : 'toolbox.crypto.veracrypt.data_probe_fat32_no',
              ),
              accent: result.likelyFat32BootSector
                  ? const Color(0xFF2F7A4B)
                  : accent,
              backgroundColor:
                  (result.likelyFat32BootSector
                          ? const Color(0xFF2F7A4B)
                          : accent)
                      .withValues(alpha: 0.08),
            ),
          ],
        ),
        if (result.success) ...<Widget>[
          const SizedBox(height: 14),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_offset',
            ),
            value: '${result.dataOffset ?? 0}',
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_bytes',
            ),
            value: _formatVeraCryptBytes(result.bytesRead),
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_units',
            ),
            value: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_units_value',
              params: <String, Object?>{
                'start': result.dataUnitStart,
                'count': result.dataUnitCount,
              },
            ),
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_sha256',
            ),
            value: result.decryptedSha256,
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_hex_preview',
            ),
            value: result.plaintextHexPreview,
          ),
          _VeraCryptMetricRow(
            label: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.data_probe_fat32',
            ),
            value: _lifeI18nText(
              context,
              result.likelyFat32BootSector
                  ? 'toolbox.crypto.veracrypt.data_probe_fat32_yes'
                  : 'toolbox.crypto.veracrypt.data_probe_fat32_no',
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...result.notes.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  result.success
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  color: result.success
                      ? const Color(0xFF2F7A4B)
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
      ],
    );
  }
}

class _VeraCryptBoundaryPanel extends StatelessWidget {
  const _VeraCryptBoundaryPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      radius: ToolboxUiTokens.cardRadius,
      color: theme.colorScheme.surfaceContainerLow,
      borderColor: theme.colorScheme.outlineVariant,
      shadowOpacity: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.mobile_friendly_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.veracrypt.mobile_boundary',
              ),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatVeraCryptBytes(int bytes) {
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

String _formatVeraCryptHexVersion(int version) {
  return '0x${version.toRadixString(16).padLeft(4, '0')}';
}

/// Read-only FAT32 browse/export panel for the VeraCrypt tool (PLAN_349).
///
/// Receives the owning page state so it can read the FS session fields and
/// invoke the FS action methods. It is display-only: all parsing and key
/// handling lives in the service layer.
class _VeraCryptFsBrowsePanel extends StatelessWidget {
  const _VeraCryptFsBrowsePanel({required this.accent, required this.state});

  final Color accent;
  final _VeraCryptToolPageState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionActive =
        state._fsSession != null && !state._fsSession!.isClosed;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.crypto.veracrypt.fs.section'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.fs.section_subtitle',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxInfoPill(
              text: _lifeI18nText(
                context,
                'toolbox.crypto.veracrypt.fs.browse_boundary',
              ),
              accent: accent,
              backgroundColor: accent.withValues(alpha: 0.08),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('crypto_veracrypt_fs_open_button'),
                onPressed: _mountEnabled ? _onMountPressed : null,
                icon: state._fsBusy && !sessionActive
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    sessionActive
                        ? 'toolbox.crypto.veracrypt.fs.close_button'
                        : 'toolbox.crypto.veracrypt.fs.open_button',
                  ),
                ),
              ),
            ),
          ],
        ),
        if (state._fsStatus != null) ...<Widget>[
          const SizedBox(height: 10),
          _fsStatusBox(context, colorScheme, theme),
        ],
        if (sessionActive) ...<Widget>[
          const SizedBox(height: 14),
          _buildBreadcrumb(context, theme),
          const SizedBox(height: 10),
          _buildEntryList(context, theme),
          if (state._fsSelectedEntry != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildFilePreview(context, theme),
          ],
        ],
      ],
    );
  }

  void _onMountPressed() {
    final sessionActive =
        state._fsSession != null && !state._fsSession!.isClosed;
    if (sessionActive) {
      state._closeFilesystem();
    } else {
      state._openFilesystem();
    }
  }

  bool get _mountEnabled {
    if (state._fsBusy) {
      return false;
    }
    final sessionActive =
        state._fsSession != null && !state._fsSession!.isClosed;
    if (sessionActive) {
      return true;
    }
    // Opening requires a chosen container whose primary header unlocked.
    return state._selectedFilePath != null &&
        state._unlockResult?.success == true;
  }

  Widget _fsStatusBox(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        state._fsStatus!,
        style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, ThemeData theme) {
    return Container(
      key: const ValueKey<String>('crypto_veracrypt_fs_breadcrumb'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (var i = 0; i < state._fsPathSegments.length; i++) ...<Widget>[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            InkWell(
              onTap: state._fsBusy ? null : () => state._navigateToSegment(i),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  state._fsPathSegments[i],
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: i == state._fsPathSegments.length - 1
                        ? accent
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: i == state._fsPathSegments.length - 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, ThemeData theme) {
    if (state._fsBusy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final entries = state._fsCurrentEntries;
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          _lifeI18nText(context, 'toolbox.crypto.veracrypt.fs.empty_directory'),
          style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
        ),
      );
    }
    return Container(
      key: const ValueKey<String>('crypto_veracrypt_fs_dir_list'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: entries.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final selected =
              state._fsSelectedEntry?.displayName == entry.displayName;
          return _fsEntryTile(context, theme, entry: entry, selected: selected);
        },
      ),
    );
  }

  Widget _fsEntryTile(
    BuildContext context,
    ThemeData theme, {
    required ToolboxVeraCryptFat32Entry entry,
    required bool selected,
  }) {
    return InkWell(
      onTap: state._fsBusy
          ? null
          : () {
              if (entry.isDirectory) {
                state._enterDirectory(entry);
              } else {
                state._selectEntry(entry);
              }
            },
      child: Container(
        color: selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(
              entry.isDirectory
                  ? Icons.folder_rounded
                  : Icons.insert_drive_file_outlined,
              size: 20,
              color: entry.isDirectory
                  ? accent
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_lifeI18nText(context, 'toolbox.crypto.veracrypt.fs.entry_cluster')}: ${entry.firstCluster}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!entry.isDirectory)
              Text(
                _formatVeraCryptBytes(entry.size),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, ThemeData theme) {
    final entry = state._fsSelectedEntry!;
    final bytes = state._fsSelectedFileBytes;
    final sha = state._fsSelectedFileSha ?? '';
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.crypto.veracrypt.fs.preview_section',
      ),
      subtitle: entry.displayName,
      children: <Widget>[
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.fs.entry_size',
          ),
          value: _formatVeraCryptBytes(entry.size),
        ),
        _VeraCryptMetricRow(
          label: _lifeI18nText(
            context,
            'toolbox.crypto.veracrypt.fs.entry_cluster',
          ),
          value: '${entry.firstCluster}',
        ),
        if (sha.isNotEmpty)
          _VeraCryptMetricRow(
            label: _lifeI18nText(context, 'toolbox.crypto.veracrypt.fs.sha256'),
            value: sha,
          ),
        if (state._fsSelectedTruncated)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.veracrypt.fs.note.file_truncated',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>(
                  'crypto_veracrypt_fs_export_button',
                ),
                onPressed: (bytes == null || state._fsExportBusy)
                    ? null
                    : state._exportSelected,
                icon: state._fsExportBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    state._fsExportBusy
                        ? 'toolbox.crypto.veracrypt.fs.exporting'
                        : 'toolbox.crypto.veracrypt.fs.export_button',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

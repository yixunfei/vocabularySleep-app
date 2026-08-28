part of '../toolbox_crypto_security.dart';

class _PasswordVaultPage extends StatefulWidget {
  const _PasswordVaultPage();

  @override
  State<_PasswordVaultPage> createState() => _PasswordVaultPageState();
}

class _PasswordVaultPageState extends State<_PasswordVaultPage>
    with WidgetsBindingObserver {
  static const Color _accent = Color(0xFF7A3F4D);
  static const Color _createAccent = Color(0xFF7A5C24);
  static const Color _unlockAccent = Color(0xFF28706F);
  static const Color _manageAccent = Color(0xFF4F639E);
  static const bool _passwordRevealCacheEnabled = false;
  static const Duration _credentialTtl = Duration(seconds: 60);
  static const Duration _passwordRevealTtl = Duration(seconds: 45);
  static const Duration _keyFileTtl = Duration(minutes: 5);
  static const Duration _biometricBackgroundLockDelay = Duration(seconds: 2);

  static Uint8List _randomClipboardMacKey() {
    final random = math.Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  static void _wipeBytes(Uint8List bytes) {
    bytes.fillRange(0, bytes.length, 0);
  }

  final ToolboxPasswordVaultService _service = ToolboxPasswordVaultService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Uint8List _clipboardMacKey = _randomClipboardMacKey();
  final TextEditingController _masterController = TextEditingController();
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createMasterController = TextEditingController();
  final TextEditingController _createMasterConfirmController =
      TextEditingController();
  final TextEditingController _createPasswordHintController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  ToolboxPasswordVaultStrength _newRecordStrength =
      ToolboxPasswordVaultStrength.enhanced;
  List<_LocalPasswordVaultInfo> _vaults = const <_LocalPasswordVaultInfo>[];
  List<ToolboxPasswordVaultEntryIndex> _indexes =
      const <ToolboxPasswordVaultEntryIndex>[];
  final Map<String, _PasswordVaultPasswordCacheEntry> _passwordCache =
      <String, _PasswordVaultPasswordCacheEntry>{};
  final Map<ToolboxPasswordVaultUnlockMode, _PasswordVaultCredentialCacheEntry>
  _credentialCache =
      <ToolboxPasswordVaultUnlockMode, _PasswordVaultCredentialCacheEntry>{};
  ToolboxPasswordVaultSnapshot? _snapshot;
  ToolboxPasswordVaultUnlockMode? _unlockMode;
  String? _selectedVaultId;
  bool _unlocked = false;
  bool _busy = false;
  bool _showMaster = false;
  bool _showCreateMaster = false;
  bool _showAll = false;
  bool _createDeleteRequiresPassword = true;
  bool _createAddEntryRequiresPassword = true;
  bool _createEditEntryRequiresPassword = true;
  bool _createDeleteEntryRequiresPassword = true;
  int _createClipboardClearSeconds =
      ToolboxPasswordVaultService.defaultClipboardClearSeconds;
  int _createAutoLockSeconds =
      ToolboxPasswordVaultService.defaultAutoLockSeconds;
  Uint8List? _activeKeyFileBytes;
  String? _activeKeyFileSha256;
  String? _statusMessage;
  String? _error;
  String? _localPath;
  String? _fileSha256;
  Timer? _credentialTtlTimer;
  Timer? _passwordCacheTimer;
  Timer? _clipboardClearTimer;
  Timer? _keyFileTtlTimer;
  Timer? _autoLockTimer;
  Timer? _biometricLifecycleLockTimer;
  int _clipboardClearToken = 0;
  String? _lastSecretClipboardMac;
  int _unlockFailureCount = 0;
  DateTime? _unlockBlockedUntil;
  bool _createNameDefaultApplied = false;
  bool _biometricInFlight = false;
  bool _biometricLifecycleLockPending = false;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshVaults());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_createNameDefaultApplied && _createNameController.text.isEmpty) {
      _createNameController.text = _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.title',
      );
      _createNameDefaultApplied = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearClipboardSecret();
    _clearSensitiveSessionState(clearKeyFile: true);
    _wipeBytes(_clipboardMacKey);
    _masterController.dispose();
    _createNameController.dispose();
    _createMasterController.dispose();
    _createMasterConfirmController.dispose();
    _createPasswordHintController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lastLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _biometricLifecycleLockPending = false;
      _biometricLifecycleLockTimer?.cancel();
      _biometricLifecycleLockTimer = null;
    }
    if (_biometricInFlight) {
      if (_isSensitiveBackgroundLifecycle(state)) {
        _biometricLifecycleLockPending = true;
        _clearClipboardSecret();
      }
      return;
    }
    if (_isSensitiveBackgroundLifecycle(state)) {
      _clearClipboardSecret();
      if (_unlocked) {
        _lockVault(clearKeyFile: true);
      } else {
        _clearSensitiveSessionState(clearKeyFile: true);
      }
    }
  }

  bool _isSensitiveBackgroundLifecycle(AppLifecycleState state) {
    return state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.password_vault.title'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.subtitle',
      ),
      floatingActionButton: _unlocked ? _buildQuickLockButton(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 10),
          if (!_unlocked) ...<Widget>[
            _buildCreatePanel(context),
            const SizedBox(height: 10),
            _buildUnlockPanel(context),
            const SizedBox(height: 10),
            _buildVaultSelectorPanel(context),
          ] else ...<Widget>[_buildVaultWorkspacePanel(context)],
        ],
      ),
    );
  }

  Widget _buildQuickLockButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      heroTag: 'password-vault-quick-lock',
      onPressed: _busy ? null : _lockVault,
      backgroundColor: _accent,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.lock_rounded),
      label: Text(
        _lifeI18nText(context, 'toolbox.crypto.password_vault.quick_lock'),
      ),
    );
  }

  Widget _buildVaultExpansionPanel({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
    String? subtitle,
    Color? color,
    Color? borderColor,
    double shadowOpacity = 0.035,
    bool initiallyExpanded = false,
  }) {
    final theme = Theme.of(context);
    return _PasswordVaultCollapsiblePanel(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: accent,
      color: color ?? theme.colorScheme.surfaceContainerLow,
      borderColor: borderColor ?? accent.withValues(alpha: 0.22),
      shadowOpacity: shadowOpacity,
      initiallyExpanded: initiallyExpanded,
      children: children,
    );
  }

  Widget _buildStageCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snapshot = _snapshot;
    final selectedVault = _selectedVaultId == null
        ? null
        : _vaults.where((vault) => vault.id == _selectedVaultId).firstOrNull;
    final title =
        snapshot?.settings.name ??
        selectedVault?.name ??
        _lifeI18nText(context, 'toolbox.crypto.password_vault.stage_title');
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withValues(alpha: 0.22)),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stageSubtitle(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.guide_tooltip',
                ),
                onPressed: _openPasswordVaultGuide,
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ],
          ),
          if (_unlocked) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxInfoPill(
                  text: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.chip_entry_cascade',
                  ),
                  accent: _accent,
                  backgroundColor: _accent.withValues(alpha: 0.08),
                ),
                ToolboxInfoPill(
                  text: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.chip_key_material',
                  ),
                  accent: _accent,
                  backgroundColor: _accent.withValues(alpha: 0.08),
                ),
                ToolboxInfoPill(
                  text: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.chip_raw_only',
                  ),
                  accent: _accent,
                  backgroundColor: _accent.withValues(alpha: 0.08),
                ),
              ],
            ),
            if (_fileSha256 != null ||
                _activeKeyFileSha256 != null) ...<Widget>[
              const SizedBox(height: 12),
              _LifePreviewFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_fileSha256 != null)
                      _CryptoMetricRow(
                        label: _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.file_hash_label',
                        ),
                        value: _fileSha256!,
                      ),
                    if (_activeKeyFileSha256 != null)
                      _CryptoMetricRow(
                        label: _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.key_file_hash_label',
                        ),
                        value: _activeKeyFileSha256!,
                      ),
                  ],
                ),
              ),
            ],
          ],
          if (!_unlocked &&
              selectedVault != null &&
              _activeKeyFileSha256 != null) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxInfoPill(
                  text: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.key_file_loaded_short',
                  ),
                  accent: _accent,
                  backgroundColor: _accent.withValues(alpha: 0.08),
                ),
              ],
            ),
          ],
          if (_statusMessage != null || _error != null) ...<Widget>[
            const SizedBox(height: 12),
            _CryptoStatusBlock(
              message: _error ?? _statusMessage ?? '',
              accent: _accent,
              isError: _error != null,
            ),
          ],
        ],
      ),
    );
  }

  String _stageSubtitle(BuildContext context) {
    if (!_unlocked) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.stage_locked_v2',
      );
    }
    return _lifeI18nText(
      context,
      'toolbox.crypto.password_vault.stage_unlocked',
      params: <String, Object?>{'count': _indexes.length.toString()},
    );
  }

  Widget _buildVaultSelectorPanel(BuildContext context) {
    final theme = Theme.of(context);
    final selectedVault = _selectedVaultId == null
        ? null
        : _vaults.where((vault) => vault.id == _selectedVaultId).firstOrNull;
    return _buildVaultExpansionPanel(
      context: context,
      title: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.vault_selector_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.vault_selector_subtitle_v3',
      ),
      icon: Icons.inventory_2_rounded,
      accent: _manageAccent,
      color: Color.alphaBlend(
        _manageAccent.withValues(alpha: 0.045),
        theme.colorScheme.surfaceContainerLow,
      ),
      borderColor: _manageAccent.withValues(alpha: 0.24),
      shadowOpacity: 0.035,
      children: <Widget>[
        if (_vaults.isEmpty)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.password_vault.no_vaults'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vaults
                .map(
                  (vault) => ChoiceChip(
                    selected: _selectedVaultId == vault.id,
                    label: Text(vault.name),
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                            _selectedVaultId = vault.id;
                            _localPath = vault.path;
                            _snapshot = null;
                            _fileSha256 = null;
                          }),
                  ),
                )
                .toList(growable: false),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _busy || selectedVault == null
                  ? null
                  : () => _openLocalVaultManagementSheet(selectedVault),
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.manage_vault',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _refreshVaults,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.crypto.common.reset'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importVault,
              icon: const Icon(Icons.file_upload_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.import_vault',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreatePanel(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: EdgeInsets.zero,
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: Color.alphaBlend(
        _createAccent.withValues(alpha: 0.05),
        theme.colorScheme.surfaceContainerLow,
      ),
      borderColor: _createAccent.withValues(alpha: 0.24),
      shadowColor: _createAccent,
      shadowOpacity: 0.035,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          leading: Icon(Icons.add_moderator_rounded, color: _createAccent),
          title: Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.create_section',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          children: <Widget>[
            TextField(
              controller: _createNameController,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.vault_name_label',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createMasterController,
              obscureText: !_showCreateMaster,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.master_label',
                ),
                suffixIcon: IconButton(
                  tooltip: _lifeI18nText(
                    context,
                    _showCreateMaster
                        ? 'toolbox.crypto.password_vault.hide_password'
                        : 'toolbox.crypto.password_vault.reveal_password',
                  ),
                  onPressed: () =>
                      setState(() => _showCreateMaster = !_showCreateMaster),
                  icon: Icon(
                    _showCreateMaster
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createMasterConfirmController,
              obscureText: !_showCreateMaster,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.master_confirm_label',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createPasswordHintController,
              enabled: !_busy,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.password_hint_label',
                ),
                helperText: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.password_hint_helper',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                value: _createDeleteRequiresPassword,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.delete_requires_password_label',
                  ),
                ),
                subtitle: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.delete_requires_password_helper',
                  ),
                ),
                onChanged: _busy
                    ? null
                    : (value) =>
                          setState(() => _createDeleteRequiresPassword = value),
              ),
            ),
            const SizedBox(height: 10),
            _buildCreateSafetyOptions(context),
            const SizedBox(height: 12),
            _buildKeyFileTools(context),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _createVault,
                icon: const Icon(Icons.add_moderator_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.create_vault',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSafetyOptions(BuildContext context) {
    return _LifePreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.create_safety_options_title',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _PasswordVaultSwitchRow(
            value: _createAddEntryRequiresPassword,
            titleKey:
                'toolbox.crypto.password_vault.add_entry_requires_password_label',
            subtitleKey:
                'toolbox.crypto.password_vault.add_entry_requires_password_helper',
            onChanged: _busy
                ? null
                : (value) =>
                      setState(() => _createAddEntryRequiresPassword = value),
          ),
          _PasswordVaultSwitchRow(
            value: _createEditEntryRequiresPassword,
            titleKey:
                'toolbox.crypto.password_vault.edit_entry_requires_password_label',
            subtitleKey:
                'toolbox.crypto.password_vault.edit_entry_requires_password_helper',
            onChanged: _busy
                ? null
                : (value) =>
                      setState(() => _createEditEntryRequiresPassword = value),
          ),
          _PasswordVaultSwitchRow(
            value: _createDeleteEntryRequiresPassword,
            titleKey:
                'toolbox.crypto.password_vault.delete_entry_requires_password_label',
            subtitleKey:
                'toolbox.crypto.password_vault.delete_entry_requires_password_helper',
            onChanged: _busy
                ? null
                : (value) => setState(
                    () => _createDeleteEntryRequiresPassword = value,
                  ),
          ),
          const SizedBox(height: 10),
          _PasswordVaultDurationChoiceField(
            labelKey:
                'toolbox.crypto.password_vault.clipboard_clear_seconds_label',
            value: _createClipboardClearSeconds,
            values: const <int>[10, 15, 30, 60],
            onChanged: _busy
                ? null
                : (value) =>
                      setState(() => _createClipboardClearSeconds = value),
          ),
          const SizedBox(height: 10),
          _PasswordVaultDurationChoiceField(
            labelKey: 'toolbox.crypto.password_vault.auto_lock_seconds_label',
            value: _createAutoLockSeconds,
            values: const <int>[60, 300, 900, 1800],
            onChanged: _busy
                ? null
                : (value) => setState(() => _createAutoLockSeconds = value),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockPanel(BuildContext context) {
    final theme = Theme.of(context);
    final selectedVault = _selectedVaultId == null
        ? null
        : _vaults.where((vault) => vault.id == _selectedVaultId).firstOrNull;
    final passwordHint = selectedVault?.passwordHint.trim();
    return _buildVaultExpansionPanel(
      context: context,
      title: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.unlock_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.unlock_subtitle_v3',
      ),
      icon: Icons.lock_open_rounded,
      accent: _unlockAccent,
      color: Color.alphaBlend(
        _unlockAccent.withValues(alpha: 0.045),
        theme.colorScheme.surfaceContainerLow,
      ),
      borderColor: _unlockAccent.withValues(alpha: 0.24),
      shadowOpacity: 0.035,
      children: <Widget>[
        TextField(
          controller: _masterController,
          obscureText: !_showMaster,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.master_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.master_helper_v2',
            ),
            suffixIcon: IconButton(
              tooltip: _lifeI18nText(
                context,
                _showMaster
                    ? 'toolbox.crypto.password_vault.hide_password'
                    : 'toolbox.crypto.password_vault.reveal_password',
              ),
              onPressed: () => setState(() => _showMaster = !_showMaster),
              icon: Icon(
                _showMaster
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
        ),
        if (passwordHint != null && passwordHint.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _LifePreviewFrame(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.lightbulb_outline_rounded, color: _unlockAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    passwordHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildKeyFileTools(context),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy || _selectedVaultId == null
                    ? null
                    : _unlockLocalVault,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(
                  _busy
                      ? _lifeI18nText(context, 'toolbox.crypto.common.working')
                      : _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.unlock',
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.export_vault',
              ),
              onPressed: _busy || _selectedVaultId == null
                  ? null
                  : _exportVault,
              icon: const Icon(Icons.file_download_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyFileTools(BuildContext context) {
    final hash = _activeKeyFileSha256;
    return _LifePreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.key_file_section',
            ),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hash == null
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.key_file_none',
                  )
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.key_file_loaded',
                    params: <String, Object?>{'hash': hash},
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _busy ? null : _importKeyFile,
                icon: const Icon(Icons.key_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.import_key_file',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _generateKeyFile,
                icon: const Icon(Icons.vpn_key_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.generate_key_file',
                  ),
                ),
              ),
              if (hash != null)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _clearActiveKeyFile();
                        }),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(
                    _lifeI18nText(context, 'toolbox.crypto.common.clear'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaultWorkspacePanel(BuildContext context) {
    final selectedVault = _selectedVaultId == null
        ? null
        : _vaults.where((vault) => vault.id == _selectedVaultId).firstOrNull;
    final readOnly = _unlockMode == ToolboxPasswordVaultUnlockMode.shadow;
    final theme = Theme.of(context);
    return _buildVaultExpansionPanel(
      context: context,
      title: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.workspace_section',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.workspace_subtitle',
      ),
      icon: Icons.account_tree_rounded,
      accent: _accent,
      color: Color.alphaBlend(
        _accent.withValues(alpha: 0.04),
        theme.colorScheme.surfaceContainerLow,
      ),
      borderColor: _accent.withValues(alpha: 0.24),
      initiallyExpanded: true,
      children: <Widget>[
        _LifePreviewFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _accent.withValues(alpha: 0.12),
                    foregroundColor: _accent,
                    child: const Icon(Icons.inventory_2_rounded, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          selectedVault?.name ??
                              _snapshot?.settings.name ??
                              _lifeI18nText(
                                context,
                                'toolbox.crypto.password_vault.stage_title',
                              ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lifeI18nText(
                            context,
                            'toolbox.crypto.password_vault.workspace_current_vault_helper',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ToolboxInfoPill(
                    text: _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.workspace_entries_count',
                      params: <String, Object?>{
                        'count': _indexes.length.toString(),
                      },
                    ),
                    accent: _accent,
                    backgroundColor: _accent.withValues(alpha: 0.08),
                  ),
                  ToolboxInfoPill(
                    text: _lifeI18nText(
                      context,
                      _unlockMode == ToolboxPasswordVaultUnlockMode.shadow
                          ? 'toolbox.crypto.password_vault.workspace_shadow_mode'
                          : 'toolbox.crypto.password_vault.workspace_primary_mode',
                    ),
                    accent: _accent,
                    backgroundColor: _accent.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.search_label',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.search_helper_v3',
            ),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: _lifeI18nText(
                      context,
                      'toolbox.crypto.common.clear',
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (!readOnly) ...<Widget>[
              FilledButton.icon(
                onPressed: _busy ? null : () => _openEntryEditor(),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.add_entry',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _openVaultSettingsSheet,
                icon: const Icon(Icons.settings_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.open_settings',
                  ),
                ),
              ),
            ],
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() => _showAll = !_showAll),
              icon: Icon(
                _showAll
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
              label: Text(
                _lifeI18nText(
                  context,
                  _showAll
                      ? 'toolbox.crypto.password_vault.hide_all'
                      : 'toolbox.crypto.password_vault.show_all',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportVault,
              icon: const Icon(Icons.file_download_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.export_vault',
                ),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: _busy || selectedVault == null
                  ? null
                  : () => _confirmDeleteVault(selectedVault),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.delete_vault',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _lockVault,
              icon: const Icon(Icons.lock_rounded),
              label: Text(
                _lifeI18nText(context, 'toolbox.crypto.password_vault.lock'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: _accent.withValues(alpha: 0.18), height: 1),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.entries_section',
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.entries_subtitle_v2',
                params: <String, Object?>{'count': _indexes.length.toString()},
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildEntryListItems(context),
      ],
    );
  }

  Future<void> _openVaultSettingsSheet() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    final action = await showModalBottomSheet<_PasswordVaultSettingsAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PasswordVaultSettingsSheet(
        accent: _accent,
        settings: snapshot.settings,
        shadowAvailable: _unlockMode == ToolboxPasswordVaultUnlockMode.primary,
        onBiometricGateToggle: _prepareBiometricGateChange,
      ),
    );
    if (action == null || !mounted) {
      return;
    }
    if (action.kind == _PasswordVaultSettingsActionKind.saveSettings) {
      await _saveVaultSettings(action.settings!);
    } else {
      await _changeMasterPassword(action.master!);
    }
  }

  List<Widget> _buildEntryListItems(BuildContext context) {
    final filtered = _filteredIndexes();
    final theme = Theme.of(context);
    final recordsById = _recordsById();
    if (filtered.isEmpty) {
      return <Widget>[
        _LifePreviewFrame(
          child: Text(
            _indexes.isEmpty
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.no_entries',
                  )
                : _searchController.text.trim().isEmpty && !_showAll
                ? _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.search_only_empty',
                  )
                : _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.no_search_results',
                  ),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ];
    }
    return <Widget>[
      for (final index in filtered) ...<Widget>[
        _PasswordVaultEntryCard(
          index: index,
          accent: _accent,
          password: _cachedPassword(index.id),
          record: recordsById[index.id]!,
          readOnly: _unlockMode == ToolboxPasswordVaultUnlockMode.shadow,
          onGetPassword: () => _loadPassword(index.id),
          onCopyAccount: () => _copyText(
            index.account,
            'toolbox.crypto.password_vault.copied_account',
          ),
          onCopyPassword: () => _copyPassword(index.id),
          onEdit: () => _openEntryEditor(index),
          onDelete: () => _confirmDelete(index),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<ToolboxPasswordVaultEntryIndex> _filteredIndexes() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty && !_showAll) {
      return const <ToolboxPasswordVaultEntryIndex>[];
    }
    final source = query.isEmpty
        ? _indexes
        : _indexes.where((entry) {
            return entry.channel.toLowerCase().contains(query) ||
                entry.account.toLowerCase().contains(query) ||
                entry.hint.toLowerCase().contains(query) ||
                entry.note.toLowerCase().contains(query);
          });
    return source.toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  ToolboxPasswordVaultEncryptedRecord _recordById(String id) {
    final snapshot = _snapshot;
    final source = _unlockMode == ToolboxPasswordVaultUnlockMode.shadow
        ? snapshot?.shadowRecords
        : snapshot?.records;
    return source!.firstWhere((record) => record.id == id);
  }

  Map<String, ToolboxPasswordVaultEncryptedRecord> _recordsById() {
    final snapshot = _snapshot;
    final source = _unlockMode == ToolboxPasswordVaultUnlockMode.shadow
        ? snapshot?.shadowRecords
        : snapshot?.records;
    return <String, ToolboxPasswordVaultEncryptedRecord>{
      for (final record
          in source ?? const <ToolboxPasswordVaultEncryptedRecord>[])
        record.id: record,
    };
  }

  Future<void> _refreshVaults() async {
    if (kIsWeb) {
      setState(() => _vaults = const <_LocalPasswordVaultInfo>[]);
      return;
    }
    final vaults = <_LocalPasswordVaultInfo>[];
    final seenPaths = <String>{};
    final dir = await _vaultDirectory(createDirectory: true);
    final legacyDir = await _legacyVaultDirectory(createDirectory: false);
    final legacyFile = await _legacyVaultFile(createDirectory: false);
    if (await legacyFile.exists()) {
      try {
        final bytes = Uint8List.fromList(await legacyFile.readAsBytes());
        final snapshot = _service.decodeVaultBytes(bytes);
        seenPaths.add(path.normalize(legacyFile.path));
        vaults.add(
          _LocalPasswordVaultInfo.fromSnapshot(snapshot, legacyFile.path),
        );
      } on Object {
        // Broken local files are surfaced when the user imports or unlocks.
      }
    }
    for (final scanDir in <Directory>[dir, legacyDir]) {
      if (!await scanDir.exists()) {
        continue;
      }
      await for (final entity in scanDir.list()) {
        if (entity is! File || path.extension(entity.path) != '.vspvault') {
          continue;
        }
        final normalizedPath = path.normalize(entity.path);
        if (!seenPaths.add(normalizedPath)) {
          continue;
        }
        try {
          final bytes = Uint8List.fromList(await entity.readAsBytes());
          final snapshot = _service.decodeVaultBytes(bytes);
          vaults.add(
            _LocalPasswordVaultInfo.fromSnapshot(snapshot, entity.path),
          );
        } on Object {
          // Ignore unreadable metadata in the selector.
        }
      }
    }
    vaults.sort((left, right) => left.name.compareTo(right.name));
    if (!mounted) {
      return;
    }
    setState(() {
      _vaults = vaults;
      if (_selectedVaultId != null &&
          !vaults.any((vault) => vault.id == _selectedVaultId)) {
        _selectedVaultId = null;
      }
      _selectedVaultId ??= vaults.firstOrNull?.id;
      _localPath = _selectedVaultId == null
          ? null
          : vaults
                .where((vault) => vault.id == _selectedVaultId)
                .firstOrNull
                ?.path;
    });
  }

  Future<void> _openPasswordVaultGuide() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PasswordVaultGuideSheet(accent: _accent),
    );
  }

  Future<void> _openLocalVaultManagementSheet(
    _LocalPasswordVaultInfo vault,
  ) async {
    final action = await showModalBottomSheet<_PasswordVaultLocalAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _PasswordVaultLocalManagementSheet(accent: _accent, vault: vault),
    );
    if (action == null || !mounted) {
      return;
    }
    switch (action.kind) {
      case _PasswordVaultLocalActionKind.rename:
        await _renameLocalVault(vault, action.name ?? vault.name);
      case _PasswordVaultLocalActionKind.delete:
        await _confirmDeleteVault(vault);
    }
  }

  Future<void> _renameLocalVault(
    _LocalPasswordVaultInfo vault,
    String name,
  ) async {
    final verificationPassword = await _requestLocalVaultPassword(
      vault,
      titleKey: 'toolbox.crypto.password_vault.rename_vault',
      messageKey: 'toolbox.crypto.password_vault.rename_vault_password_message',
      helperKey: 'toolbox.crypto.password_vault.rename_vault_password_helper',
    );
    if (verificationPassword == null) {
      return;
    }
    await _runBusy(() async {
      final nextName = name.trim();
      if (_normalizedVaultName(nextName).isEmpty) {
        throw const ToolboxPasswordVaultException('Vault name is invalid.');
      }
      if (_vaultNameExists(nextName, exceptVaultId: vault.id)) {
        throw const ToolboxPasswordVaultException('Vault name already exists.');
      }
      final file = File(vault.path);
      if (!await file.exists()) {
        throw const ToolboxPasswordVaultException('Vault file is invalid.');
      }
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final snapshot = _service.decodeVaultBytes(bytes);
      _service.verifyPrimaryVaultPasswordBytes(
        bytes: bytes,
        masterPassword: verificationPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
      final nextSnapshot = _service.updateSettings(
        snapshot: snapshot,
        name: nextName,
        strength: snapshot.settings.strength,
        visible: true,
        deleteRequiresPassword: snapshot.settings.deleteRequiresPassword,
        addEntryRequiresPassword: snapshot.settings.addEntryRequiresPassword,
        editEntryRequiresPassword: snapshot.settings.editEntryRequiresPassword,
        deleteEntryRequiresPassword:
            snapshot.settings.deleteEntryRequiresPassword,
        biometricGateEnabled: snapshot.settings.biometricGateEnabled,
        clipboardClearSeconds: snapshot.settings.clipboardClearSeconds,
        autoLockSeconds: snapshot.settings.autoLockSeconds,
        passwordHint: snapshot.settings.passwordHint,
        shadowMaxUnlocks: snapshot.settings.shadowMaxUnlocks,
      );
      final protectedSnapshot = _service.protectManifest(
        snapshot: nextSnapshot,
        primaryMasterPassword: verificationPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
      await file.writeAsBytes(
        _service.encodeVaultBytes(protectedSnapshot),
        flush: true,
      );
      if (_snapshot?.settings.id == vault.id) {
        _snapshot = protectedSnapshot;
      }
      await _refreshVaults();
      setState(() {
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.vault_renamed',
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.save_failed');
  }

  Future<void> _confirmDeleteVault(_LocalPasswordVaultInfo vault) async {
    final verificationPassword = vault.deleteRequiresPassword
        ? await _requestDeleteVaultPassword(vault)
        : null;
    if (vault.deleteRequiresPassword && verificationPassword == null) {
      return;
    }
    if (!vault.deleteRequiresPassword &&
        !await _requestDeleteVaultConfirmation(vault)) {
      return;
    }
    await _runBusy(() async {
      final file = File(vault.path);
      if (!await file.exists()) {
        throw const ToolboxPasswordVaultException('Vault file is invalid.');
      }
      final bytes = Uint8List.fromList(await file.readAsBytes());
      if (vault.deleteRequiresPassword) {
        _service.verifyPrimaryVaultPasswordBytes(
          bytes: bytes,
          masterPassword: verificationPassword!,
          keyFileBytes: _activeKeyFileBytes,
        );
      }
      await file.delete();
      await _refreshVaults();
      setState(() {
        if (_selectedVaultId == vault.id) {
          _selectedVaultId = _vaults.firstOrNull?.id;
          _localPath = _vaults.firstOrNull?.path;
        }
        if (_snapshot?.settings.id == vault.id) {
          _unlocked = false;
          _snapshot = null;
          _indexes = const <ToolboxPasswordVaultEntryIndex>[];
          _clearPasswordCache();
          _clearCredentialCache();
          _unlockMode = null;
          _masterController.clear();
          _searchController.clear();
          _showAll = false;
        }
        _fileSha256 = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.vault_deleted',
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.delete_vault_failed');
  }

  Future<bool> _requestDeleteVaultConfirmation(
    _LocalPasswordVaultInfo vault,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.delete_vault_title',
          ),
        ),
        content: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.delete_vault_message',
            params: <String, Object?>{'name': vault.name},
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.password_vault.cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.delete_vault_confirm',
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<String?> _requestDeleteVaultPassword(_LocalPasswordVaultInfo vault) {
    return _requestLocalVaultPassword(
      vault,
      titleKey: 'toolbox.crypto.password_vault.delete_vault_title',
      messageKey: 'toolbox.crypto.password_vault.delete_vault_message',
      helperKey: 'toolbox.crypto.password_vault.delete_vault_password_helper',
      confirmKey: 'toolbox.crypto.password_vault.delete_vault_confirm',
    );
  }

  Future<String?> _requestLocalVaultPassword(
    _LocalPasswordVaultInfo vault, {
    required String titleKey,
    required String helperKey,
    String messageKey = 'toolbox.crypto.password_vault.delete_vault_message',
    String confirmKey = 'toolbox.crypto.password_vault.save',
  }) async {
    final controller = TextEditingController();
    var showPassword = false;
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final canConfirm = controller.text.trim().isNotEmpty;
              return AlertDialog(
                title: Text(_lifeI18nText(context, titleKey)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        messageKey,
                        params: <String, Object?>{'name': vault.name},
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      obscureText: !showPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.delete_vault_password_label',
                        ),
                        helperText: _lifeI18nText(context, helperKey),
                        suffixIcon: IconButton(
                          tooltip: _lifeI18nText(
                            context,
                            showPassword
                                ? 'toolbox.crypto.password_vault.hide_password'
                                : 'toolbox.crypto.password_vault.reveal_password',
                          ),
                          onPressed: () => setDialogState(
                            () => showPassword = !showPassword,
                          ),
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          Navigator.of(context).pop(value);
                        }
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.cancel',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: canConfirm
                        ? () => Navigator.of(context).pop(controller.text)
                        : null,
                    child: Text(_lifeI18nText(context, confirmKey)),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.clear();
      controller.dispose();
    }
  }

  bool _vaultNameExists(String name, {String? exceptVaultId}) {
    final normalized = _normalizedVaultName(name);
    if (normalized.isEmpty) {
      return false;
    }
    return _vaults.any(
      (vault) =>
          vault.id != exceptVaultId &&
          _normalizedVaultName(vault.name) == normalized,
    );
  }

  String _normalizedVaultName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<Directory> _vaultDirectory({bool createDirectory = true}) async {
    final appDir = await getApplicationSupportDirectory();
    final vaultDir = Directory(
      path.join(appDir.path, 'toolbox_crypto', 'password_vaults'),
    );
    if (createDirectory && !await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  Future<Directory> _legacyVaultDirectory({
    bool createDirectory = false,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(
      path.join(appDir.path, 'toolbox_crypto', 'password_vaults'),
    );
    if (createDirectory && !await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  Future<File> _legacyVaultFile({bool createDirectory = true}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(path.join(appDir.path, 'toolbox_crypto'));
    if (createDirectory && !await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return File(path.join(vaultDir.path, 'password_vault.vspvault'));
  }

  Future<File> _localVaultFile(String vaultId) async {
    final known = _vaults.where((vault) => vault.id == vaultId).firstOrNull;
    if (known != null) {
      return File(known.path);
    }
    final dir = await _vaultDirectory();
    return File(path.join(dir.path, 'password_vault_$vaultId.vspvault'));
  }

  Future<Uint8List> _readSelectedVaultBytes() async {
    final selected = _selectedVaultId;
    if (selected == null) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    final file = await _localVaultFile(selected);
    if (!await file.exists()) {
      throw const ToolboxPasswordVaultException('Vault file is invalid.');
    }
    final length = await file.length();
    if (length <= 0 || length > ToolboxPasswordVaultService.maxVaultBytes) {
      throw const ToolboxPasswordVaultException('Vault file is too large.');
    }
    return Uint8List.fromList(await file.readAsBytes());
  }

  Future<void> _persistSnapshot(
    ToolboxPasswordVaultSnapshot snapshot, {
    bool syncShadow = true,
    String? primaryMasterPassword,
    String? shadowMasterPassword,
  }) async {
    var nextSnapshot = snapshot;
    if (syncShadow &&
        _unlockMode == ToolboxPasswordVaultUnlockMode.primary &&
        nextSnapshot.settings.shadowEnabled &&
        primaryMasterPassword != null &&
        shadowMasterPassword != null) {
      nextSnapshot = _service.syncShadowVault(
        snapshot: nextSnapshot,
        primaryMasterPassword: primaryMasterPassword,
        shadowMasterPassword: shadowMasterPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
    }
    if (primaryMasterPassword != null || shadowMasterPassword != null) {
      nextSnapshot = _service.protectManifest(
        snapshot: nextSnapshot,
        primaryMasterPassword: primaryMasterPassword,
        shadowMasterPassword: shadowMasterPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
    }
    final bytes = _service.encodeVaultBytes(nextSnapshot);
    if (!kIsWeb) {
      final file = await _localVaultFile(nextSnapshot.settings.id);
      await file.writeAsBytes(bytes, flush: true);
      _localPath = file.path;
    }
    _snapshot = nextSnapshot;
    _fileSha256 = sha256.convert(bytes).toString();
    _selectedVaultId = nextSnapshot.settings.id;
  }

  Future<void> _createVault() async {
    final masterPassword = _createMasterController.text;
    if (masterPassword != _createMasterConfirmController.text) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.error_master_mismatch',
        );
        _statusMessage = null;
      });
      return;
    }
    final weakPasswordAccepted = await _confirmWeakPasswordRiskIfNeeded(
      password: masterPassword,
      kindKey: 'toolbox.crypto.password_vault.weak_kind_master',
    );
    if (!weakPasswordAccepted) {
      return;
    }
    await _runBusy(() async {
      await _refreshVaults();
      if (_vaultNameExists(_createNameController.text)) {
        throw const ToolboxPasswordVaultException('Vault name already exists.');
      }
      final snapshot = _service.createVaultSnapshot(
        name: _createNameController.text,
        masterPassword: masterPassword,
        keyFileBytes: _activeKeyFileBytes,
        strength: _newRecordStrength,
        deleteRequiresPassword: _createDeleteRequiresPassword,
        addEntryRequiresPassword: _createAddEntryRequiresPassword,
        editEntryRequiresPassword: _createEditEntryRequiresPassword,
        deleteEntryRequiresPassword: _createDeleteEntryRequiresPassword,
        clipboardClearSeconds: _createClipboardClearSeconds,
        autoLockSeconds: _createAutoLockSeconds,
        passwordHint: _createPasswordHintController.text,
        allowWeakMasterPassword: true,
      );
      _unlockMode = ToolboxPasswordVaultUnlockMode.primary;
      await _persistSnapshot(
        snapshot,
        syncShadow: false,
        primaryMasterPassword: masterPassword,
      );
      _cacheCredential(ToolboxPasswordVaultUnlockMode.primary, masterPassword);
      _applySnapshotSettings(snapshot);
      setState(() {
        _unlocked = true;
        _indexes = const <ToolboxPasswordVaultEntryIndex>[];
        _clearPasswordCache();
        _createMasterController.clear();
        _createMasterConfirmController.clear();
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.create_success',
        );
        _error = null;
      });
      _scheduleAutoLock();
      await _refreshVaults();
    }, failureKey: 'toolbox.crypto.password_vault.save_failed');
  }

  Future<bool> _confirmWeakPasswordRiskIfNeeded({
    required String password,
    required String kindKey,
  }) async {
    if (password.trim().isEmpty) {
      return true;
    }
    final assessment = _service.assessMasterPassword(password);
    if (assessment.accepted) {
      return true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.weak_password_risk_title',
          ),
        ),
        content: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.weak_password_risk_body',
            params: <String, Object?>{
              'kind': _lifeI18nText(context, kindKey),
              'bits': assessment.entropyBits.toStringAsFixed(1),
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.password_vault.cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.weak_password_continue',
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _unlockLocalVault() async {
    final blockedFor = _unlockCooldownRemaining();
    if (blockedFor != null) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.error_unlock_cooldown',
          params: <String, Object?>{
            'seconds': blockedFor.inSeconds.clamp(1, 999).toString(),
          },
        );
        _statusMessage = null;
      });
      return;
    }
    await _runBusy(() async {
      final submittedPassword = _masterController.text;
      final bytes = await _readSelectedVaultBytes();
      late final ToolboxPasswordVaultUnlockResult result;
      try {
        result = _service.unlockVaultBytes(
          bytes: bytes,
          masterPassword: submittedPassword,
          keyFileBytes: _activeKeyFileBytes,
        );
      } on Object {
        _registerUnlockFailure();
        rethrow;
      }
      final biometricAccepted = await _ensureBiometricGateForSettings(
        result.snapshot.settings,
        reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
      );
      if (!biometricAccepted) {
        _masterController.clear();
        _clearSensitiveSessionState(clearKeyFile: false);
        return;
      }
      if (result.shadowStateChanged ||
          result.recordDerivationMigrated ||
          result.manifestAuthMigrated) {
        await _persistSnapshot(
          result.snapshot,
          syncShadow: false,
          primaryMasterPassword:
              result.mode == ToolboxPasswordVaultUnlockMode.primary
              ? submittedPassword
              : null,
          shadowMasterPassword:
              result.mode == ToolboxPasswordVaultUnlockMode.shadow
              ? submittedPassword
              : null,
        );
      } else {
        _snapshot = result.snapshot;
      }
      final effectiveFileSha256 =
          (result.shadowStateChanged ||
              result.recordDerivationMigrated ||
              result.manifestAuthMigrated)
          ? _fileSha256
          : result.fileSha256;
      _applySnapshotSettings(result.snapshot);
      _clearUnlockFailures();
      _cacheCredential(result.mode, submittedPassword);
      setState(() {
        _indexes = result.indexes;
        _unlocked = true;
        _unlockMode = result.mode;
        _clearPasswordCache();
        _showAll = false;
        _fileSha256 = effectiveFileSha256;
        _masterController.clear();
        _statusMessage = result.recordDerivationMigrated
            ? _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.legacy_metadata_migrated',
              )
            : _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.unlock_success',
                params: <String, Object?>{
                  'count': result.indexes.length.toString(),
                },
              );
        _error = null;
      });
      _scheduleAutoLock();
    }, failureKey: 'toolbox.crypto.password_vault.unlock_failed');
  }

  void _applySnapshotSettings(ToolboxPasswordVaultSnapshot snapshot) {
    _newRecordStrength = snapshot.settings.strength;
    if (snapshot.settings.addEntryRequiresPassword &&
        snapshot.settings.editEntryRequiresPassword &&
        snapshot.settings.deleteEntryRequiresPassword) {
      _clearCredentialCache();
    }
  }

  bool get _isMobileBiometricPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<bool> _prepareBiometricGateChange(bool enabled) async {
    if (!enabled) {
      return true;
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return false;
    }
    return _ensureBiometricGateForSettings(
      snapshot.settings,
      reasonKey: 'toolbox.crypto.password_vault.biometric_setup_reason',
      force: true,
    );
  }

  Future<bool> _ensureBiometricGate({required String reasonKey}) async {
    final settings = _snapshot?.settings;
    if (settings == null) {
      return true;
    }
    return _ensureBiometricGateForSettings(settings, reasonKey: reasonKey);
  }

  Future<bool> _ensureBiometricGateForSettings(
    ToolboxPasswordVaultSettings settings, {
    required String reasonKey,
    bool force = false,
  }) async {
    if (!force &&
        (!settings.biometricGateEnabled || !_isMobileBiometricPlatform)) {
      return true;
    }
    if (!_isMobileBiometricPlatform) {
      _reportBiometricGateIssue(
        'toolbox.crypto.password_vault.biometric_unavailable',
      );
      return false;
    }
    final available = await _hasBiometricCapability();
    if (!available || !mounted) {
      _reportBiometricGateIssue(
        'toolbox.crypto.password_vault.biometric_unavailable',
      );
      return false;
    }
    _biometricInFlight = true;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: _lifeI18nText(context, reasonKey),
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) {
        _clearCredentialCache();
        _clearPasswordCache();
        _reportBiometricGateIssue(
          'toolbox.crypto.password_vault.biometric_failed',
        );
      }
      return authenticated;
    } on LocalAuthException {
      _clearCredentialCache();
      _clearPasswordCache();
      _reportBiometricGateIssue(
        'toolbox.crypto.password_vault.biometric_failed',
      );
      return false;
    } on Object {
      _clearCredentialCache();
      _clearPasswordCache();
      _reportBiometricGateIssue(
        'toolbox.crypto.password_vault.biometric_failed',
      );
      return false;
    } finally {
      _biometricInFlight = false;
      _scheduleBiometricBackgroundLockIfNeeded();
    }
  }

  void _scheduleBiometricBackgroundLockIfNeeded() {
    if (!_biometricLifecycleLockPending ||
        !_isSensitiveBackgroundLifecycle(
          _lastLifecycleState ?? AppLifecycleState.resumed,
        )) {
      _biometricLifecycleLockPending = false;
      return;
    }
    _biometricLifecycleLockTimer?.cancel();
    _biometricLifecycleLockTimer = Timer(_biometricBackgroundLockDelay, () {
      if (!mounted ||
          !_isSensitiveBackgroundLifecycle(
            _lastLifecycleState ?? AppLifecycleState.resumed,
          )) {
        _biometricLifecycleLockPending = false;
        return;
      }
      _biometricLifecycleLockPending = false;
      if (_unlocked) {
        _lockVault(clearKeyFile: true);
      } else {
        _clearClipboardSecret();
        _clearSensitiveSessionState(clearKeyFile: true);
      }
    });
  }

  Future<bool> _hasBiometricCapability() async {
    if (!_isMobileBiometricPlatform) {
      return false;
    }
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!supported || !canCheck) {
        return false;
      }
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on Object {
      return false;
    }
  }

  void _reportBiometricGateIssue(String messageKey) {
    if (!mounted) {
      return;
    }
    final message = _lifeI18nText(context, messageKey);
    setState(() {
      _error = message;
      _statusMessage = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEntryEditor([ToolboxPasswordVaultEntryIndex? index]) async {
    final snapshot = _snapshot;
    if (!_unlocked ||
        snapshot == null ||
        _unlockMode != ToolboxPasswordVaultUnlockMode.primary) {
      return;
    }
    final authenticated = await _ensureBiometricGate(
      reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
    );
    if (!authenticated) {
      return;
    }
    String? primaryMaster;
    ToolboxPasswordVaultEntry? existing;
    ToolboxPasswordVaultEncryptedRecord? existingRecord;
    ToolboxPasswordVaultEntryIndex? existingIndex = index;
    if (index != null) {
      existingRecord = _recordById(index.id);
      if (existingRecord.isLegacyFullEntry) {
        primaryMaster = await _credentialFor(
          ToolboxPasswordVaultUnlockMode.primary,
          titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
          helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
        );
        if (primaryMaster == null) {
          return;
        }
        existing = await _decryptEntry(index.id, masterPassword: primaryMaster);
        if (existing == null) {
          return;
        }
        existingIndex = existing.toIndex();
      }
    }
    if (!mounted) {
      return;
    }
    final draft = await showModalBottomSheet<_PasswordVaultEntryDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PasswordVaultEntryEditorSheet(
        entry: existing,
        index: existingIndex,
        accent: _accent,
        defaultStrength: snapshot.settings.strength,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    if (draft.passwordChanged &&
        !await _confirmWeakPasswordRiskIfNeeded(
          password: draft.password,
          kindKey: 'toolbox.crypto.password_vault.weak_kind_entry',
        )) {
      return;
    }
    final creatingEntry = existingIndex == null;
    final operationRequiresPassword = creatingEntry
        ? snapshot.settings.addEntryRequiresPassword
        : snapshot.settings.editEntryRequiresPassword;
    primaryMaster ??= await _credentialFor(
      ToolboxPasswordVaultUnlockMode.primary,
      titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
      helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
      forcePrompt: operationRequiresPassword,
    );
    if (primaryMaster == null) {
      return;
    }
    final shadowMaster = snapshot.settings.shadowEnabled
        ? await _shadowCredentialForSync()
        : null;
    if (snapshot.settings.shadowEnabled && shadowMaster == null) {
      return;
    }
    await _runBusy(() async {
      final now = DateTime.now().toUtc();
      final passwordChanged = creatingEntry || draft.passwordChanged;
      late final ToolboxPasswordVaultEntryIndex nextIndex;
      late final ToolboxPasswordVaultEncryptedRecord nextRecord;
      var syncShadow = true;
      if (creatingEntry) {
        final nextEntry = _service.createEntry(
          channel: draft.channel,
          account: draft.account,
          password: draft.password,
          hint: draft.hint,
          note: draft.note,
          now: now,
        );
        nextIndex = nextEntry.toIndex();
        nextRecord = _service.encryptEntry(
          entry: nextEntry,
          masterPassword: primaryMaster!,
          settings: snapshot.settings,
          keyFileBytes: _activeKeyFileBytes,
          strength: draft.strength,
        );
      } else if (passwordChanged || existingRecord!.isLegacyFullEntry) {
        final baseIndex = existingIndex!;
        final existingPassword = passwordChanged
            ? draft.password
            : existing!.password;
        final nextEntry = ToolboxPasswordVaultEntry(
          id: baseIndex.id,
          channel: draft.channel.trim(),
          account: draft.account.trim(),
          password: existingPassword,
          hint: draft.hint.trim(),
          note: draft.note.trim(),
          createdAt: baseIndex.createdAt,
          updatedAt: now,
        );
        nextIndex = nextEntry.toIndex();
        nextRecord = _service.encryptEntry(
          entry: nextEntry,
          masterPassword: primaryMaster!,
          settings: snapshot.settings,
          keyFileBytes: _activeKeyFileBytes,
          strength: existingRecord!.strength,
        );
      } else {
        nextIndex = existingIndex!.copyWith(
          channel: draft.channel,
          account: draft.account,
          hint: draft.hint,
          note: draft.note,
          updatedAt: now,
        );
        nextRecord = _service.updateRecordIndex(
          record: existingRecord!,
          index: nextIndex,
          settings: snapshot.settings,
          masterPassword: primaryMaster!,
          keyFileBytes: _activeKeyFileBytes,
        );
        syncShadow = snapshot.settings.shadowEnabled;
      }
      final nextRecords =
          snapshot.records
              .where((record) => record.id != nextRecord.id)
              .toList(growable: true)
            ..add(nextRecord)
            ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      var nextSnapshot = snapshot.copyWith(records: nextRecords);
      if (!passwordChanged && !nextRecord.isLegacyFullEntry) {
        final shadowSnapshot = _tryUpdateShadowIndex(
          snapshot: snapshot,
          nextSnapshot: nextSnapshot,
          nextIndex: nextIndex,
          shadowMasterPassword: shadowMaster,
        );
        if (shadowSnapshot != null) {
          nextSnapshot = shadowSnapshot;
          syncShadow = false;
        }
      }
      await _persistSnapshot(
        nextSnapshot,
        syncShadow: syncShadow,
        primaryMasterPassword: primaryMaster,
        shadowMasterPassword: shadowMaster,
      );
      _cacheCredential(ToolboxPasswordVaultUnlockMode.primary, primaryMaster!);
      setState(() {
        _indexes =
            _indexes
                .where((item) => item.id != nextIndex.id)
                .toList(growable: true)
              ..add(nextIndex)
              ..sort(
                (left, right) => right.updatedAt.compareTo(left.updatedAt),
              );
        if (passwordChanged) {
          _removePasswordCache(nextIndex.id);
        }
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.save_success',
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.save_failed');
  }

  ToolboxPasswordVaultSnapshot? _tryUpdateShadowIndex({
    required ToolboxPasswordVaultSnapshot snapshot,
    required ToolboxPasswordVaultSnapshot nextSnapshot,
    required ToolboxPasswordVaultEntryIndex nextIndex,
    required String? shadowMasterPassword,
  }) {
    if (!snapshot.settings.shadowEnabled) {
      return nextSnapshot;
    }
    if (shadowMasterPassword == null) {
      return null;
    }
    final shadowIndex = snapshot.shadowRecords.indexWhere(
      (record) => record.id == nextIndex.id,
    );
    if (shadowIndex < 0) {
      return null;
    }
    final shadowRecord = snapshot.shadowRecords[shadowIndex];
    if (shadowRecord.isLegacyFullEntry) {
      return null;
    }
    final nextShadowRecord = _service.updateRecordIndex(
      record: shadowRecord,
      index: nextIndex.copyWith(shadow: true),
      settings: snapshot.settings,
      masterPassword: shadowMasterPassword,
      keyFileBytes: _activeKeyFileBytes,
    );
    final nextShadowRecords = snapshot.shadowRecords.toList(growable: true);
    nextShadowRecords[shadowIndex] = nextShadowRecord;
    nextShadowRecords.sort(
      (left, right) => right.updatedAt.compareTo(left.updatedAt),
    );
    return nextSnapshot.copyWith(shadowRecords: nextShadowRecords);
  }

  Future<void> _confirmDelete(ToolboxPasswordVaultEntryIndex index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _lifeI18nText(context, 'toolbox.crypto.password_vault.delete_title'),
        ),
        content: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.delete_message',
            params: <String, Object?>{'name': index.displayTitle},
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.password_vault.cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.delete_confirm',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final authenticated = await _ensureBiometricGate(
      reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
    );
    if (!authenticated) {
      return;
    }
    final snapshotBeforeDelete = _snapshot;
    if (snapshotBeforeDelete == null) {
      return;
    }
    final primaryMaster = await _credentialFor(
      ToolboxPasswordVaultUnlockMode.primary,
      titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
      helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
      forcePrompt: snapshotBeforeDelete.settings.deleteEntryRequiresPassword,
    );
    if (primaryMaster == null) {
      return;
    }
    final shadowMaster = snapshotBeforeDelete.settings.shadowEnabled
        ? await _shadowCredentialForSync()
        : null;
    if (snapshotBeforeDelete.settings.shadowEnabled && shadowMaster == null) {
      return;
    }
    await _runBusy(() async {
      final snapshot = _snapshot;
      if (snapshot == null) {
        return;
      }
      final nextRecords = snapshot.records
          .where((record) => record.id != index.id)
          .toList(growable: false);
      final nextShadowRecords = snapshot.shadowRecords
          .where((record) => record.id != index.id)
          .toList(growable: false);
      await _persistSnapshot(
        snapshot.copyWith(
          records: nextRecords,
          shadowRecords: nextShadowRecords,
        ),
        syncShadow: false,
        primaryMasterPassword: primaryMaster,
        shadowMasterPassword: shadowMaster,
      );
      setState(() {
        _indexes = _indexes
            .where((item) => item.id != index.id)
            .toList(growable: false);
        _removePasswordCache(index.id);
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.deleted',
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.save_failed');
  }

  Future<void> _saveVaultSettings(_PasswordVaultSettingsDraft draft) async {
    final authenticated = await _ensureBiometricGate(
      reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
    );
    if (!authenticated) {
      return;
    }
    final primaryMaster = await _credentialFor(
      ToolboxPasswordVaultUnlockMode.primary,
      titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
      helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
    );
    if (primaryMaster == null) {
      return;
    }
    final snapshotBeforeSave = _snapshot;
    final shadowMaster =
        snapshotBeforeSave != null && snapshotBeforeSave.settings.shadowEnabled
        ? await _shadowCredentialForSync()
        : null;
    if (snapshotBeforeSave != null &&
        snapshotBeforeSave.settings.shadowEnabled &&
        shadowMaster == null) {
      return;
    }
    final enablingShadow =
        snapshotBeforeSave != null &&
        draft.shadowEnabled &&
        !snapshotBeforeSave.settings.shadowEnabled;
    if (enablingShadow &&
        !await _confirmWeakPasswordRiskIfNeeded(
          password: draft.shadowPassword,
          kindKey: 'toolbox.crypto.password_vault.weak_kind_shadow',
        )) {
      return;
    }
    await _runBusy(() async {
      final snapshot = _snapshot;
      if (snapshot == null) {
        return;
      }
      if (_vaultNameExists(draft.name, exceptVaultId: snapshot.settings.id)) {
        throw const ToolboxPasswordVaultException('Vault name already exists.');
      }
      final biometricTurnedOn =
          draft.biometricGateEnabled && !snapshot.settings.biometricGateEnabled;
      var nextSnapshot = _service.updateSettings(
        snapshot: snapshot,
        name: draft.name,
        strength: draft.strength,
        visible: true,
        deleteRequiresPassword: draft.deleteRequiresPassword,
        addEntryRequiresPassword: draft.addEntryRequiresPassword,
        editEntryRequiresPassword: draft.editEntryRequiresPassword,
        deleteEntryRequiresPassword: draft.deleteEntryRequiresPassword,
        biometricGateEnabled: draft.biometricGateEnabled,
        clipboardClearSeconds: draft.clipboardClearSeconds,
        autoLockSeconds: draft.autoLockSeconds,
        passwordHint: draft.passwordHint,
        shadowMaxUnlocks: draft.shadowMaxUnlocks,
      );
      if (draft.shadowEnabled && !snapshot.settings.shadowEnabled) {
        nextSnapshot = _service.enableShadowVault(
          snapshot: nextSnapshot,
          primaryMasterPassword: primaryMaster,
          shadowMasterPassword: draft.shadowPassword,
          shadowMaxUnlocks: draft.shadowMaxUnlocks,
          keyFileBytes: _activeKeyFileBytes,
          allowWeakShadowMasterPassword: true,
        );
      } else if (!draft.shadowEnabled && snapshot.settings.shadowEnabled) {
        nextSnapshot = _service.disableShadowVault(snapshot: nextSnapshot);
      }
      await _persistSnapshot(
        nextSnapshot,
        syncShadow: false,
        primaryMasterPassword: primaryMaster,
        shadowMasterPassword: nextSnapshot.settings.shadowEnabled
            ? shadowMaster
            : null,
      );
      _applySnapshotSettings(nextSnapshot);
      _cacheCredential(ToolboxPasswordVaultUnlockMode.primary, primaryMaster);
      await _refreshVaults();
      setState(() {
        _statusMessage = _lifeI18nText(
          context,
          biometricTurnedOn
              ? 'toolbox.crypto.password_vault.biometric_enabled'
              : 'toolbox.crypto.password_vault.settings_saved',
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.save_failed');
  }

  Future<void> _changeMasterPassword(_PasswordVaultMasterDraft draft) async {
    final authenticated = await _ensureBiometricGate(
      reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
    );
    if (!authenticated) {
      return;
    }
    final currentMaster = await _credentialFor(
      ToolboxPasswordVaultUnlockMode.primary,
      titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
      helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
    );
    if (currentMaster == null) {
      return;
    }
    if (draft.newMasterPassword != draft.confirmMasterPassword) {
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.error_master_mismatch',
        );
        _statusMessage = null;
      });
      return;
    }
    if (!await _confirmWeakPasswordRiskIfNeeded(
      password: draft.newMasterPassword,
      kindKey: 'toolbox.crypto.password_vault.weak_kind_master',
    )) {
      return;
    }
    await _runBusy(() async {
      final snapshot = _snapshot;
      if (snapshot == null) {
        return;
      }
      final nextSnapshot = _service.changeMasterPassword(
        snapshot: snapshot,
        oldMasterPassword: currentMaster,
        newMasterPassword: draft.newMasterPassword,
        oldKeyFileBytes: _activeKeyFileBytes,
        newKeyFileBytes: _activeKeyFileBytes,
        allowWeakNewMasterPassword: true,
      );
      await _persistSnapshot(
        nextSnapshot,
        syncShadow: false,
        primaryMasterPassword: draft.newMasterPassword,
      );
      _cacheCredential(
        ToolboxPasswordVaultUnlockMode.primary,
        draft.newMasterPassword,
      );
      setState(() {
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.master_changed',
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.save_failed');
  }

  Future<void> _exportVault() async {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    if (_unlocked) {
      final authenticated = await _ensureBiometricGate(
        reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
      );
      if (!authenticated || !mounted) {
        return;
      }
    }
    await _runBusy(() async {
      final bytes = _unlocked && _snapshot != null
          ? _service.encodeVaultBytes(_snapshot!)
          : await _readSelectedVaultBytes();
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: i18n.t('toolbox.crypto.password_vault.export_dialog'),
        fileName:
            'vocabulary_sleep_password_vault_${DateTime.now().millisecondsSinceEpoch}.vspvault',
        extension: 'vspvault',
        bytes: bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: bytes,
        fallbackSegments: const <String>['toolbox_crypto', 'exports'],
        fallbackFileName: 'vocabulary_sleep_password_vault.vspvault',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = savedPath == null
            ? i18n.t('toolbox.crypto.common.browser_download')
            : i18n.t(
                'toolbox.crypto.password_vault.export_success',
                params: <String, Object?>{'path': savedPath},
              );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.export_failed');
  }

  Future<void> _importVault() async {
    await _runBusy(() async {
      final picked = await _pickCryptoFile(
        maxBytes: ToolboxPasswordVaultService.maxVaultBytes,
        allowedExtensions: const <String>['vspvault', 'json'],
      );
      if (picked == null) {
        return;
      }
      final submittedPassword = _masterController.text;
      final result = _service.unlockVaultBytes(
        bytes: picked.bytes,
        masterPassword: submittedPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
      if (_vaultNameExists(
        result.snapshot.settings.name,
        exceptVaultId: result.snapshot.settings.id,
      )) {
        throw const ToolboxPasswordVaultException('Vault name already exists.');
      }
      final biometricAccepted = await _ensureBiometricGateForSettings(
        result.snapshot.settings,
        reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
      );
      if (!biometricAccepted) {
        _masterController.clear();
        _clearSensitiveSessionState(clearKeyFile: false);
        return;
      }
      await _persistSnapshot(
        result.snapshot,
        syncShadow: false,
        primaryMasterPassword:
            result.mode == ToolboxPasswordVaultUnlockMode.primary
            ? submittedPassword
            : null,
        shadowMasterPassword:
            result.mode == ToolboxPasswordVaultUnlockMode.shadow
            ? submittedPassword
            : null,
      );
      final importedFileSha256 = _fileSha256;
      final importedPath = _localPath;
      await _refreshVaults();
      setState(() {
        _selectedVaultId = result.snapshot.settings.id;
        _snapshot = result.snapshot;
        _indexes = result.indexes;
        _unlocked = true;
        _unlockMode = result.mode;
        _fileSha256 = importedFileSha256;
        _localPath = importedPath;
        _masterController.clear();
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.import_success',
          params: <String, Object?>{'count': result.indexes.length.toString()},
        );
        _error = null;
      });
      _cacheCredential(result.mode, submittedPassword);
      _scheduleAutoLock();
    }, failureKey: 'toolbox.crypto.password_vault.import_failed');
  }

  Future<void> _importKeyFile() async {
    await _runBusy(() async {
      final picked = await _pickCryptoFile(
        maxBytes: ToolboxCryptoService.maxKeyFileBytes,
      );
      if (picked == null) {
        return;
      }
      final keyBytes = _service.normalizeImportedKeyFile(picked.bytes);
      final hash = _service.keyFileSha256(keyBytes);
      setState(() {
        _setActiveKeyFile(keyBytes);
        _activeKeyFileSha256 = hash;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.key_file_loaded',
          params: <String, Object?>{'hash': hash ?? ''},
        );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.import_failed');
  }

  Future<void> _generateKeyFile() async {
    await _runBusy(() async {
      final bytes = _service.createIndependentKeyFileBytes();
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'toolbox.crypto.password_vault.generate_key_file',
        ),
        fileName:
            'vocabulary_sleep_password_vault_key_${DateTime.now().millisecondsSinceEpoch}.vspkey',
        extension: 'vspkey',
        bytes: bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: bytes,
        fallbackSegments: const <String>['toolbox_crypto', 'keys'],
        fallbackFileName: 'vocabulary_sleep_password_vault_key.vspkey',
      );
      final normalized = _service.normalizeImportedKeyFile(bytes);
      setState(() {
        _setActiveKeyFile(normalized);
        _activeKeyFileSha256 = _service.keyFileSha256(normalized);
        _statusMessage = savedPath == null
            ? _lifeI18nText(context, 'toolbox.crypto.common.browser_download')
            : _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.export_success',
                params: <String, Object?>{'path': savedPath},
              );
        _error = null;
      });
    }, failureKey: 'toolbox.crypto.password_vault.export_failed');
  }

  Future<ToolboxPasswordVaultEntry?> _decryptEntry(
    String id, {
    required String masterPassword,
  }) async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return null;
    }
    try {
      return _service.decryptRecord(
        record: snapshot.records.firstWhere((record) => record.id == id),
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
    } on Object catch (error) {
      setState(() {
        _error = _friendlyPasswordVaultError(error);
        _statusMessage = null;
      });
      return null;
    }
  }

  Future<void> _loadPassword(String id) async {
    final snapshot = _snapshot;
    final mode = _unlockMode;
    if (snapshot == null || mode == null) {
      return;
    }
    final authenticated = await _ensureBiometricGate(
      reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
    );
    if (!authenticated) {
      return;
    }
    final masterPassword = await _credentialFor(
      mode,
      titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
      helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
    );
    if (masterPassword == null) {
      return;
    }
    await _runBusy(() async {
      final record = _recordById(id);
      var password = _service.decryptRecordPassword(
        record: record,
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
      try {
        _cacheCredential(mode, masterPassword);
        if (!mounted) {
          return;
        }
        await _showPasswordRevealDialog(password);
        if (!mounted) {
          return;
        }
        setState(() {
          _statusMessage = _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.password_loaded_once',
          );
          _error = null;
        });
      } finally {
        password = '';
      }
    }, failureKey: 'toolbox.crypto.password_vault.unlock_failed');
  }

  Future<void> _showPasswordRevealDialog(String password) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.password_label',
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SelectableText(
            password,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFeatures: const <ui.FontFeature>[
                ui.FontFeature.tabularFigures(),
              ],
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_lifeI18nText(context, 'close')),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPassword(String id) async {
    final authenticated = await _ensureBiometricGate(
      reasonKey: 'toolbox.crypto.password_vault.biometric_reason',
    );
    if (!authenticated) {
      return;
    }
    if (!await _confirmPasswordClipboardCopy()) {
      return;
    }
    final cachedPassword = _cachedPassword(id);
    if (cachedPassword != null) {
      await _copyText(
        cachedPassword,
        'toolbox.crypto.password_vault.copied_password_auto_clear',
        secret: true,
        successParams: <String, Object?>{
          'seconds': _effectiveClipboardClearSeconds.toString(),
        },
      );
      if (!mounted) {
        return;
      }
      setState(() => _removePasswordCache(id));
      return;
    }
    await _decryptAndCopyPassword(id);
  }

  Future<bool> _confirmPasswordClipboardCopy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.copy_password_risk_title',
          ),
        ),
        content: Text(
          _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.copy_password_risk_body',
            params: <String, Object?>{
              'seconds': _effectiveClipboardClearSeconds.toString(),
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _lifeI18nText(context, 'toolbox.crypto.password_vault.cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.copy_password',
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _lockVault({bool clearKeyFile = true}) {
    _clearClipboardSecret();
    _clearSensitiveSessionState(clearKeyFile: clearKeyFile);
    setState(() {
      _unlocked = false;
      _snapshot = null;
      _indexes = const <ToolboxPasswordVaultEntryIndex>[];
      _unlockMode = null;
      _masterController.clear();
      _searchController.clear();
      _showAll = false;
      _statusMessage = _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.locked',
      );
      _error = null;
    });
  }

  Future<void> _copyText(
    String text,
    String successKey, {
    bool secret = false,
    Map<String, Object?>? successParams,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (secret) {
      _scheduleClipboardClear(text);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(
            context,
            successKey,
            params: successParams ?? const <String, Object?>{},
          ),
        ),
      ),
    );
  }

  String? _cachedPassword(String id) {
    if (!_passwordRevealCacheEnabled) {
      return null;
    }
    _evictExpiredPasswordCache();
    return _passwordCache[id]?.password;
  }

  void _cachePassword(String id, String password) {
    if (!_passwordRevealCacheEnabled) {
      return;
    }
    _passwordCache[id] = _PasswordVaultPasswordCacheEntry(
      password: password,
      expiresAt: DateTime.now().add(_passwordRevealTtl),
    );
    _schedulePasswordCacheTimer();
  }

  void _removePasswordCache(String id) {
    _passwordCache.remove(id);
    _schedulePasswordCacheTimer();
  }

  void _clearPasswordCache() {
    _passwordCache.clear();
    _passwordCacheTimer?.cancel();
    _passwordCacheTimer = null;
  }

  void _evictExpiredPasswordCache() {
    final now = DateTime.now();
    _passwordCache.removeWhere((_, entry) => !entry.expiresAt.isAfter(now));
    if (_passwordCache.isEmpty) {
      _passwordCacheTimer?.cancel();
      _passwordCacheTimer = null;
    }
  }

  void _schedulePasswordCacheTimer() {
    _passwordCacheTimer?.cancel();
    if (_passwordCache.isEmpty) {
      _passwordCacheTimer = null;
      return;
    }
    final now = DateTime.now();
    final nextExpiry = _passwordCache.values
        .map((entry) => entry.expiresAt)
        .reduce((left, right) => left.isBefore(right) ? left : right);
    final delay = nextExpiry.difference(now);
    _passwordCacheTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) {
        return;
      }
      setState(_evictExpiredPasswordCache);
      _schedulePasswordCacheTimer();
    });
  }

  String? _cachedCredential(ToolboxPasswordVaultUnlockMode mode) {
    if (!_credentialCacheAllowed(mode)) {
      return null;
    }
    _evictExpiredCredentials();
    return _credentialCache[mode]?.password;
  }

  bool _credentialCacheAllowed(ToolboxPasswordVaultUnlockMode mode) {
    if (mode != ToolboxPasswordVaultUnlockMode.primary) {
      return false;
    }
    final settings = _snapshot?.settings;
    if (settings == null) {
      return false;
    }
    return !settings.addEntryRequiresPassword ||
        !settings.editEntryRequiresPassword ||
        !settings.deleteEntryRequiresPassword;
  }

  Future<String?> _credentialFor(
    ToolboxPasswordVaultUnlockMode mode, {
    required String titleKey,
    required String helperKey,
    bool forcePrompt = false,
  }) async {
    if (!forcePrompt) {
      final cached = _cachedCredential(mode);
      if (cached != null) {
        return cached;
      }
    }
    return _requestVaultCredential(titleKey: titleKey, helperKey: helperKey);
  }

  Future<String?> _shadowCredentialForSync() {
    return _credentialFor(
      ToolboxPasswordVaultUnlockMode.shadow,
      titleKey: 'toolbox.crypto.password_vault.shadow_credential_prompt_title',
      helperKey:
          'toolbox.crypto.password_vault.shadow_credential_prompt_helper',
    );
  }

  void _cacheCredential(ToolboxPasswordVaultUnlockMode mode, String password) {
    if (!_credentialCacheAllowed(mode)) {
      return;
    }
    _credentialCache[mode] = _PasswordVaultCredentialCacheEntry(
      password: password,
      expiresAt: DateTime.now().add(_credentialTtl),
    );
    _scheduleCredentialTimer();
  }

  void _clearCredentialCache() {
    _credentialCache.clear();
    _credentialTtlTimer?.cancel();
    _credentialTtlTimer = null;
  }

  void _evictExpiredCredentials() {
    final now = DateTime.now();
    _credentialCache.removeWhere((_, entry) => !entry.expiresAt.isAfter(now));
    if (_credentialCache.isEmpty) {
      _credentialTtlTimer?.cancel();
      _credentialTtlTimer = null;
    }
  }

  void _scheduleCredentialTimer() {
    _credentialTtlTimer?.cancel();
    if (_credentialCache.isEmpty) {
      _credentialTtlTimer = null;
      return;
    }
    final now = DateTime.now();
    final nextExpiry = _credentialCache.values
        .map((entry) => entry.expiresAt)
        .reduce((left, right) => left.isBefore(right) ? left : right);
    final delay = nextExpiry.difference(now);
    _credentialTtlTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) {
        return;
      }
      setState(_evictExpiredCredentials);
      _scheduleCredentialTimer();
    });
  }

  Future<String?> _requestVaultCredential({
    required String titleKey,
    required String helperKey,
  }) async {
    final controller = TextEditingController();
    var showPassword = false;
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final canConfirm = controller.text.isNotEmpty;
              return AlertDialog(
                title: Text(_lifeI18nText(context, titleKey)),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: !showPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.master_label',
                    ),
                    helperText: _lifeI18nText(context, helperKey),
                    suffixIcon: IconButton(
                      tooltip: _lifeI18nText(
                        context,
                        showPassword
                            ? 'toolbox.crypto.password_vault.hide_password'
                            : 'toolbox.crypto.password_vault.reveal_password',
                      ),
                      onPressed: () =>
                          setDialogState(() => showPassword = !showPassword),
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      Navigator.of(context).pop(value);
                    }
                  },
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.cancel',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: canConfirm
                        ? () => Navigator.of(context).pop(controller.text)
                        : null,
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.save',
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.clear();
      controller.dispose();
    }
  }

  Future<void> _decryptAndCopyPassword(String id) async {
    final snapshot = _snapshot;
    final mode = _unlockMode;
    if (snapshot == null || mode == null) {
      return;
    }
    final masterPassword = await _credentialFor(
      mode,
      titleKey: 'toolbox.crypto.password_vault.credential_prompt_title',
      helperKey: 'toolbox.crypto.password_vault.credential_prompt_helper',
    );
    if (masterPassword == null) {
      return;
    }
    await _runBusy(() async {
      var password = _service.decryptRecordPassword(
        record: _recordById(id),
        settings: snapshot.settings,
        masterPassword: masterPassword,
        keyFileBytes: _activeKeyFileBytes,
      );
      try {
        _cacheCredential(mode, masterPassword);
        await _copyText(
          password,
          'toolbox.crypto.password_vault.copied_password_auto_clear',
          secret: true,
          successParams: <String, Object?>{
            'seconds': _effectiveClipboardClearSeconds.toString(),
          },
        );
      } finally {
        password = '';
      }
    }, failureKey: 'toolbox.crypto.password_vault.unlock_failed');
  }

  void _scheduleClipboardClear(String text) {
    _clipboardClearToken += 1;
    final token = _clipboardClearToken;
    final mac = _clipboardSecretMac(text);
    _lastSecretClipboardMac = mac;
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(_effectiveClipboardTtl, () {
      unawaited(
        _clearClipboardIfMacUnchanged(
          mac,
          token,
          Uint8List.fromList(_clipboardMacKey),
        ),
      );
    });
  }

  void _clearClipboardSecret() {
    final mac = _lastSecretClipboardMac;
    if (mac == null) {
      return;
    }
    _clipboardClearToken += 1;
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = null;
    unawaited(
      _clearClipboardIfMacUnchanged(
        mac,
        _clipboardClearToken,
        Uint8List.fromList(_clipboardMacKey),
      ),
    );
  }

  String _clipboardSecretMac(String text, {Uint8List? macKey}) {
    return Hmac(
      sha256,
      macKey ?? _clipboardMacKey,
    ).convert(utf8.encode(text)).toString();
  }

  Future<void> _clearClipboardIfMacUnchanged(
    String expectedMac,
    int token,
    Uint8List macKey,
  ) async {
    try {
      ClipboardData? data;
      try {
        data = await Clipboard.getData('text/plain');
      } on Object {
        if (token == _clipboardClearToken) {
          await Clipboard.setData(const ClipboardData(text: ''));
          if (_lastSecretClipboardMac == expectedMac) {
            _lastSecretClipboardMac = null;
          }
        }
        return;
      }
      if (token != _clipboardClearToken) {
        return;
      }
      final clipboardText = data?.text;
      if (clipboardText != null &&
          _clipboardSecretMac(clipboardText, macKey: macKey) == expectedMac) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
      if (_lastSecretClipboardMac == expectedMac) {
        _lastSecretClipboardMac = null;
      }
    } on Object {
      // Best-effort clipboard cleanup; some platforms deny clipboard reads.
    } finally {
      _wipeBytes(macKey);
    }
  }

  void _setActiveKeyFile(Uint8List? bytes) {
    _clearActiveKeyFile();
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    _activeKeyFileBytes = Uint8List.fromList(bytes);
    _activeKeyFileSha256 = _service.keyFileSha256(_activeKeyFileBytes);
    _scheduleKeyFileClear();
  }

  void _clearActiveKeyFile() {
    final bytes = _activeKeyFileBytes;
    if (bytes != null) {
      bytes.fillRange(0, bytes.length, 0);
    }
    _activeKeyFileBytes = null;
    _activeKeyFileSha256 = null;
    _keyFileTtlTimer?.cancel();
    _keyFileTtlTimer = null;
  }

  void _scheduleKeyFileClear() {
    _keyFileTtlTimer?.cancel();
    _keyFileTtlTimer = Timer(_keyFileTtl, () {
      if (!mounted) {
        return;
      }
      if (_unlocked) {
        _lockVault(clearKeyFile: true);
      } else {
        setState(_clearActiveKeyFile);
      }
    });
  }

  void _clearSensitiveSessionState({required bool clearKeyFile}) {
    _clearPasswordCache();
    _clearCredentialCache();
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    _biometricLifecycleLockTimer?.cancel();
    _biometricLifecycleLockTimer = null;
    _biometricLifecycleLockPending = false;
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = null;
    _lastSecretClipboardMac = null;
    if (clearKeyFile) {
      _clearActiveKeyFile();
    }
    _masterController.clear();
    _createMasterController.clear();
    _createMasterConfirmController.clear();
  }

  void _scheduleAutoLock() {
    _autoLockTimer?.cancel();
    if (!_unlocked) {
      _autoLockTimer = null;
      return;
    }
    _autoLockTimer = Timer(_effectiveAutoLockTtl, () {
      if (!mounted || !_unlocked) {
        return;
      }
      _lockVault(clearKeyFile: true);
    });
  }

  int get _effectiveClipboardClearSeconds =>
      _snapshot?.settings.clipboardClearSeconds ??
      ToolboxPasswordVaultService.defaultClipboardClearSeconds;

  Duration get _effectiveClipboardTtl =>
      Duration(seconds: _effectiveClipboardClearSeconds);

  Duration get _effectiveAutoLockTtl {
    final seconds =
        _snapshot?.settings.autoLockSeconds ??
        ToolboxPasswordVaultService.defaultAutoLockSeconds;
    return Duration(seconds: seconds);
  }

  Duration? _unlockCooldownRemaining() {
    final blockedUntil = _unlockBlockedUntil;
    if (blockedUntil == null) {
      return null;
    }
    final remaining = blockedUntil.difference(DateTime.now());
    if (remaining.inMicroseconds <= 0) {
      _unlockBlockedUntil = null;
      return null;
    }
    return remaining;
  }

  void _registerUnlockFailure() {
    _unlockFailureCount += 1;
    if (_unlockFailureCount < 3) {
      return;
    }
    final seconds = math.min(
      60,
      5 * math.pow(2, _unlockFailureCount - 3).toInt(),
    );
    _unlockBlockedUntil = DateTime.now().add(Duration(seconds: seconds));
  }

  void _clearUnlockFailures() {
    _unlockFailureCount = 0;
    _unlockBlockedUntil = null;
  }

  Future<void> _runBusy(
    Future<void> Function() action, {
    required String failureKey,
  }) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted && _unlocked) {
        _scheduleAutoLock();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          failureKey,
          params: <String, Object?>{
            'error': _friendlyPasswordVaultError(error),
          },
        );
        _statusMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _friendlyPasswordVaultError(Object error) {
    final text = error is ToolboxPasswordVaultException
        ? error.message
        : error is ToolboxCryptoException
        ? error.message
        : error.toString();
    final normalized = text.replaceFirst('Exception: ', '');
    final key = switch (normalized) {
      'Master password is required.' =>
        'toolbox.crypto.password_vault.error_master_required',
      'Master password confirmation does not match.' =>
        'toolbox.crypto.password_vault.error_master_mismatch',
      'Master password does not meet local strength requirements.' =>
        'toolbox.crypto.password_vault.error_master_strength',
      'Substitution rule must map the same number of characters.' =>
        'toolbox.crypto.password_vault.error_substitution_rule',
      'Website/channel or account is required.' =>
        'toolbox.crypto.password_vault.error_entry_required',
      'Password is required.' =>
        'toolbox.crypto.password_vault.error_password_required',
      'Vault entry text is too long.' =>
        'toolbox.crypto.password_vault.error_text_too_long',
      'Vault entry is too large.' =>
        'toolbox.crypto.password_vault.error_entry_too_large',
      'Vault file is too large.' || 'Vault has too many records.' =>
        'toolbox.crypto.password_vault.error_file_too_large',
      'Vault name is invalid.' =>
        'toolbox.crypto.password_vault.error_vault_name',
      'Vault name already exists.' =>
        'toolbox.crypto.password_vault.error_vault_name_conflict',
      'Vault safety setting is invalid.' =>
        'toolbox.crypto.password_vault.error_safety_setting',
      'Key file is invalid.' ||
      'Key file is required or does not match this vault.' =>
        'toolbox.crypto.password_vault.error_key_file',
      'Shadow unlock limit is invalid.' =>
        'toolbox.crypto.password_vault.error_shadow_limit',
      'Vault file is invalid.' ||
      'Vault record is invalid.' ||
      'Vault entry is invalid.' =>
        'toolbox.crypto.password_vault.error_file_invalid',
      'Vault file is unsupported.' =>
        'toolbox.crypto.password_vault.error_file_unsupported',
      'Vault record cannot be decrypted.' =>
        'toolbox.crypto.password_vault.error_record_decrypt',
      'Vault unlock failed. Check the master password, key file, or file integrity.' =>
        'toolbox.crypto.password_vault.error_unlock_failed_v2',
      'Primary vault password verification failed. Check the primary master password, key file, or file integrity.' =>
        'toolbox.crypto.password_vault.error_primary_verification_failed',
      _ => 'toolbox.crypto.password_vault.error_unknown',
    };
    return _lifeI18nText(context, key);
  }
}

class _PasswordVaultPasswordCacheEntry {
  const _PasswordVaultPasswordCacheEntry({
    required this.password,
    required this.expiresAt,
  });

  final String password;
  final DateTime expiresAt;
}

class _PasswordVaultCredentialCacheEntry {
  const _PasswordVaultCredentialCacheEntry({
    required this.password,
    required this.expiresAt,
  });

  final String password;
  final DateTime expiresAt;
}

class _LocalPasswordVaultInfo {
  const _LocalPasswordVaultInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.shadowEnabled,
    required this.deleteRequiresPassword,
    required this.passwordHint,
  });

  final String id;
  final String name;
  final String path;
  final bool shadowEnabled;
  final bool deleteRequiresPassword;
  final String passwordHint;

  factory _LocalPasswordVaultInfo.fromSnapshot(
    ToolboxPasswordVaultSnapshot snapshot,
    String path,
  ) {
    return _LocalPasswordVaultInfo(
      id: snapshot.settings.id,
      name: snapshot.settings.name,
      path: path,
      shadowEnabled: snapshot.settings.shadowEnabled,
      deleteRequiresPassword: true,
      passwordHint: snapshot.settings.passwordHint,
    );
  }
}

class _PasswordVaultCollapsiblePanel extends StatelessWidget {
  const _PasswordVaultCollapsiblePanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
    this.subtitle,
    this.color,
    this.borderColor,
    this.shadowOpacity = 0.035,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Color? color;
  final Color? borderColor;
  final double shadowOpacity;
  final bool initiallyExpanded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.surfaceContainerLow;
    final effectiveBorder = borderColor ?? accent.withValues(alpha: 0.22);
    return ToolboxSurfaceCard(
      padding: EdgeInsets.zero,
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: effectiveColor,
      borderColor: effectiveBorder,
      shadowColor: accent,
      shadowOpacity: shadowOpacity,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
          children: children,
        ),
      ),
    );
  }
}

class _PasswordVaultGuideSheet extends StatelessWidget {
  const _PasswordVaultGuideSheet({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.12),
                    foregroundColor: accent,
                    child: const Icon(Icons.help_outline_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.guide_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PasswordVaultGuideItem(
                icon: Icons.lock_open_rounded,
                accent: accent,
                textKey: 'toolbox.crypto.password_vault.guide_unlock_flow',
              ),
              _PasswordVaultGuideItem(
                icon: Icons.flip_to_back_rounded,
                accent: accent,
                textKey: 'toolbox.crypto.password_vault.guide_shadow_flow',
              ),
              _PasswordVaultGuideItem(
                icon: Icons.key_rounded,
                accent: accent,
                textKey: 'toolbox.crypto.password_vault.guide_key_file_flow',
              ),
              _PasswordVaultGuideItem(
                icon: Icons.file_download_rounded,
                accent: accent,
                textKey: 'toolbox.crypto.password_vault.guide_migration_flow',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_lifeI18nText(context, 'close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordVaultGuideItem extends StatelessWidget {
  const _PasswordVaultGuideItem({
    required this.icon,
    required this.accent,
    required this.textKey,
  });

  final IconData icon;
  final Color accent;
  final String textKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lifeI18nText(context, textKey),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PasswordVaultLocalActionKind { rename, delete }

class _PasswordVaultLocalAction {
  const _PasswordVaultLocalAction._({required this.kind, this.name});

  const _PasswordVaultLocalAction.rename(String name)
    : this._(kind: _PasswordVaultLocalActionKind.rename, name: name);

  const _PasswordVaultLocalAction.delete()
    : this._(kind: _PasswordVaultLocalActionKind.delete);

  final _PasswordVaultLocalActionKind kind;
  final String? name;
}

class _PasswordVaultLocalManagementSheet extends StatefulWidget {
  const _PasswordVaultLocalManagementSheet({
    required this.accent,
    required this.vault,
  });

  final Color accent;
  final _LocalPasswordVaultInfo vault;

  @override
  State<_PasswordVaultLocalManagementSheet> createState() =>
      _PasswordVaultLocalManagementSheetState();
}

class _PasswordVaultLocalManagementSheetState
    extends State<_PasswordVaultLocalManagementSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.vault.name,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: widget.accent.withValues(alpha: 0.12),
                    foregroundColor: widget.accent,
                    child: const Icon(Icons.tune_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.manage_vault_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.vault_name_label',
                  ),
                  prefixIcon: const Icon(
                    Icons.drive_file_rename_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      _PasswordVaultLocalAction.rename(_nameController.text),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.rename_vault',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _PasswordVaultLocalAction.delete()),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.delete_vault',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordVaultSwitchRow extends StatelessWidget {
  const _PasswordVaultSwitchRow({
    required this.value,
    required this.titleKey,
    required this.subtitleKey,
    required this.onChanged,
  });

  final bool value;
  final String titleKey;
  final String subtitleKey;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        value: value,
        contentPadding: EdgeInsets.zero,
        title: Text(_lifeI18nText(context, titleKey)),
        subtitle: Text(_lifeI18nText(context, subtitleKey)),
        onChanged: onChanged,
      ),
    );
  }
}

class _PasswordVaultDurationChoiceField extends StatelessWidget {
  const _PasswordVaultDurationChoiceField({
    required this.labelKey,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String labelKey;
  final int value;
  final List<int> values;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label(context), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (seconds) => ChoiceChip(
                  selected: value == seconds,
                  label: Text(_durationLabel(context, seconds)),
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged?.call(seconds),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }

  String _durationLabel(BuildContext context, int seconds) {
    if (seconds < 60) {
      return _lifeI18nText(
        context,
        'toolbox.crypto.password_vault.duration_seconds',
        params: <String, Object?>{'seconds': seconds.toString()},
      );
    }
    return _lifeI18nText(
      context,
      'toolbox.crypto.password_vault.duration_minutes',
      params: <String, Object?>{'minutes': (seconds ~/ 60).toString()},
    );
  }
}

enum _PasswordVaultSettingsActionKind { saveSettings, changeMaster }

class _PasswordVaultSettingsAction {
  const _PasswordVaultSettingsAction._({
    required this.kind,
    this.settings,
    this.master,
  });

  factory _PasswordVaultSettingsAction.saveSettings(
    _PasswordVaultSettingsDraft settings,
  ) {
    return _PasswordVaultSettingsAction._(
      kind: _PasswordVaultSettingsActionKind.saveSettings,
      settings: settings,
    );
  }

  factory _PasswordVaultSettingsAction.changeMaster(
    _PasswordVaultMasterDraft master,
  ) {
    return _PasswordVaultSettingsAction._(
      kind: _PasswordVaultSettingsActionKind.changeMaster,
      master: master,
    );
  }

  final _PasswordVaultSettingsActionKind kind;
  final _PasswordVaultSettingsDraft? settings;
  final _PasswordVaultMasterDraft? master;
}

class _PasswordVaultSettingsDraft {
  const _PasswordVaultSettingsDraft({
    required this.name,
    required this.strength,
    required this.deleteRequiresPassword,
    required this.addEntryRequiresPassword,
    required this.editEntryRequiresPassword,
    required this.deleteEntryRequiresPassword,
    required this.biometricGateEnabled,
    required this.clipboardClearSeconds,
    required this.autoLockSeconds,
    required this.passwordHint,
    required this.shadowEnabled,
    required this.shadowPassword,
    required this.shadowMaxUnlocks,
  });

  final String name;
  final ToolboxPasswordVaultStrength strength;
  final bool deleteRequiresPassword;
  final bool addEntryRequiresPassword;
  final bool editEntryRequiresPassword;
  final bool deleteEntryRequiresPassword;
  final bool biometricGateEnabled;
  final int clipboardClearSeconds;
  final int autoLockSeconds;
  final String passwordHint;
  final bool shadowEnabled;
  final String shadowPassword;
  final int shadowMaxUnlocks;
}

class _PasswordVaultMasterDraft {
  const _PasswordVaultMasterDraft({
    required this.newMasterPassword,
    required this.confirmMasterPassword,
  });

  final String newMasterPassword;
  final String confirmMasterPassword;
}

class _PasswordVaultSettingsSheet extends StatefulWidget {
  const _PasswordVaultSettingsSheet({
    required this.accent,
    required this.settings,
    required this.shadowAvailable,
    required this.onBiometricGateToggle,
  });

  final Color accent;
  final ToolboxPasswordVaultSettings settings;
  final bool shadowAvailable;
  final Future<bool> Function(bool enabled) onBiometricGateToggle;

  @override
  State<_PasswordVaultSettingsSheet> createState() =>
      _PasswordVaultSettingsSheetState();
}

class _PasswordVaultSettingsSheetState
    extends State<_PasswordVaultSettingsSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.settings.name,
  );
  late final TextEditingController _passwordHintController =
      TextEditingController(text: widget.settings.passwordHint);
  late final TextEditingController _shadowPasswordController =
      TextEditingController();
  late final TextEditingController _shadowMaxUnlocksController =
      TextEditingController(text: widget.settings.shadowMaxUnlocks.toString());
  late final TextEditingController _newMasterController =
      TextEditingController();
  late final TextEditingController _newMasterConfirmController =
      TextEditingController();
  late ToolboxPasswordVaultStrength _strength = widget.settings.strength;
  late bool _deleteRequiresPassword = widget.settings.deleteRequiresPassword;
  late bool _addEntryRequiresPassword =
      widget.settings.addEntryRequiresPassword;
  late bool _editEntryRequiresPassword =
      widget.settings.editEntryRequiresPassword;
  late bool _deleteEntryRequiresPassword =
      widget.settings.deleteEntryRequiresPassword;
  late bool _biometricGateEnabled = widget.settings.biometricGateEnabled;
  late int _clipboardClearSeconds = widget.settings.clipboardClearSeconds;
  late int _autoLockSeconds = widget.settings.autoLockSeconds;
  late bool _shadowEnabled = widget.settings.shadowEnabled;
  bool _biometricGateBusy = false;
  bool _showNewMaster = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordHintController.dispose();
    _shadowPasswordController.dispose();
    _shadowMaxUnlocksController.dispose();
    _newMasterController.dispose();
    _newMasterConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final enabled = widget.shadowAvailable;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: widget.accent.withValues(alpha: 0.12),
                    foregroundColor: widget.accent,
                    child: const Icon(Icons.settings_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.settings_sheet_title',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.settings_sheet_subtitle',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (!enabled) ...<Widget>[
                const SizedBox(height: 12),
                _CryptoStatusBlock(
                  message: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.settings_disabled_shadow',
                  ),
                  accent: Colors.orange.shade700,
                ),
              ],
              const SizedBox(height: 16),
              _PasswordVaultCollapsiblePanel(
                title: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.settings_section',
                ),
                subtitle: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.settings_subtitle_v2',
                ),
                icon: Icons.tune_rounded,
                accent: widget.accent,
                color: Color.alphaBlend(
                  widget.accent.withValues(alpha: 0.04),
                  Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                borderColor: widget.accent.withValues(alpha: 0.22),
                children: <Widget>[
                  TextField(
                    controller: _nameController,
                    enabled: enabled,
                    decoration: InputDecoration(
                      labelText: _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.vault_name_label',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LifeSegmentedField<ToolboxPasswordVaultStrength>(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.strength_label',
                    ),
                    value: _strength,
                    options: const <_LifeOption<ToolboxPasswordVaultStrength>>[
                      _LifeOption<ToolboxPasswordVaultStrength>(
                        value: ToolboxPasswordVaultStrength.enhanced,
                        labelKey:
                            'toolbox.crypto.password_vault.strength_enhanced',
                      ),
                      _LifeOption<ToolboxPasswordVaultStrength>(
                        value: ToolboxPasswordVaultStrength.extreme,
                        labelKey:
                            'toolbox.crypto.password_vault.strength_extreme',
                      ),
                    ],
                    onChanged: enabled
                        ? (value) => setState(() => _strength = value)
                        : (_) {},
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordHintController,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.password_hint_label',
                      ),
                      helperText: _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.password_hint_helper',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _deleteRequiresPassword,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.delete_requires_password_label',
                        ),
                      ),
                      subtitle: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.delete_requires_password_helper',
                        ),
                      ),
                      onChanged: enabled
                          ? (value) =>
                                setState(() => _deleteRequiresPassword = value)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PasswordVaultSwitchRow(
                    value: _addEntryRequiresPassword,
                    titleKey:
                        'toolbox.crypto.password_vault.add_entry_requires_password_label',
                    subtitleKey:
                        'toolbox.crypto.password_vault.add_entry_requires_password_helper',
                    onChanged: enabled
                        ? (value) =>
                              setState(() => _addEntryRequiresPassword = value)
                        : null,
                  ),
                  _PasswordVaultSwitchRow(
                    value: _editEntryRequiresPassword,
                    titleKey:
                        'toolbox.crypto.password_vault.edit_entry_requires_password_label',
                    subtitleKey:
                        'toolbox.crypto.password_vault.edit_entry_requires_password_helper',
                    onChanged: enabled
                        ? (value) =>
                              setState(() => _editEntryRequiresPassword = value)
                        : null,
                  ),
                  _PasswordVaultSwitchRow(
                    value: _deleteEntryRequiresPassword,
                    titleKey:
                        'toolbox.crypto.password_vault.delete_entry_requires_password_label',
                    subtitleKey:
                        'toolbox.crypto.password_vault.delete_entry_requires_password_helper',
                    onChanged: enabled
                        ? (value) => setState(
                            () => _deleteEntryRequiresPassword = value,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _PasswordVaultDurationChoiceField(
                    labelKey:
                        'toolbox.crypto.password_vault.clipboard_clear_seconds_label',
                    value: _clipboardClearSeconds,
                    values: const <int>[10, 15, 30, 60],
                    onChanged: enabled
                        ? (value) =>
                              setState(() => _clipboardClearSeconds = value)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _PasswordVaultDurationChoiceField(
                    labelKey:
                        'toolbox.crypto.password_vault.auto_lock_seconds_label',
                    value: _autoLockSeconds,
                    values: const <int>[60, 300, 900, 1800],
                    onChanged: enabled
                        ? (value) => setState(() => _autoLockSeconds = value)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _biometricGateEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.biometric_gate_label',
                        ),
                      ),
                      subtitle: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.biometric_gate_helper',
                        ),
                      ),
                      onChanged: enabled && !_biometricGateBusy
                          ? _toggleBiometricGate
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _shadowEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.shadow_label',
                        ),
                      ),
                      subtitle: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.shadow_helper',
                        ),
                      ),
                      onChanged: enabled
                          ? (value) => setState(() => _shadowEnabled = value)
                          : null,
                    ),
                  ),
                  if (_shadowEnabled) ...<Widget>[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shadowPasswordController,
                      enabled: enabled && !widget.settings.shadowEnabled,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.shadow_password_label',
                        ),
                        helperText: _lifeI18nText(
                          context,
                          widget.settings.shadowEnabled
                              ? 'toolbox.crypto.password_vault.shadow_password_unchanged'
                              : 'toolbox.crypto.password_vault.shadow_password_helper',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _shadowMaxUnlocksController,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.shadow_max_unlocks_label',
                        ),
                        helperText: _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.shadow_max_unlocks_helper',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: enabled ? _saveSettings : null,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.save_settings',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PasswordVaultCollapsiblePanel(
                title: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.change_master_section',
                ),
                subtitle: _lifeI18nText(
                  context,
                  'toolbox.crypto.password_vault.change_master_subtitle',
                ),
                icon: Icons.password_rounded,
                accent: widget.accent,
                color: Color.alphaBlend(
                  widget.accent.withValues(alpha: 0.025),
                  Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                borderColor: widget.accent.withValues(alpha: 0.18),
                children: <Widget>[
                  TextField(
                    controller: _newMasterController,
                    obscureText: !_showNewMaster,
                    enabled: enabled,
                    decoration: InputDecoration(
                      labelText: _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.new_master_label',
                      ),
                      suffixIcon: IconButton(
                        tooltip: _lifeI18nText(
                          context,
                          _showNewMaster
                              ? 'toolbox.crypto.password_vault.hide_password'
                              : 'toolbox.crypto.password_vault.reveal_password',
                        ),
                        onPressed: () =>
                            setState(() => _showNewMaster = !_showNewMaster),
                        icon: Icon(
                          _showNewMaster
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newMasterConfirmController,
                    obscureText: !_showNewMaster,
                    enabled: enabled,
                    decoration: InputDecoration(
                      labelText: _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.new_master_confirm_label',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: enabled ? _changeMaster : null,
                    icon: const Icon(Icons.password_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.change_master',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBiometricGate(bool value) async {
    setState(() => _biometricGateBusy = true);
    final allowed = await widget.onBiometricGateToggle(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricGateBusy = false;
      if (allowed) {
        _biometricGateEnabled = value;
      }
    });
  }

  void _saveSettings() {
    final rawMaxUnlocks = _shadowMaxUnlocksController.text.trim();
    Navigator.of(context).pop(
      _PasswordVaultSettingsAction.saveSettings(
        _PasswordVaultSettingsDraft(
          name: _nameController.text,
          strength: _strength,
          deleteRequiresPassword: _deleteRequiresPassword,
          addEntryRequiresPassword: _addEntryRequiresPassword,
          editEntryRequiresPassword: _editEntryRequiresPassword,
          deleteEntryRequiresPassword: _deleteEntryRequiresPassword,
          biometricGateEnabled: _biometricGateEnabled,
          clipboardClearSeconds: _clipboardClearSeconds,
          autoLockSeconds: _autoLockSeconds,
          passwordHint: _passwordHintController.text,
          shadowEnabled: _shadowEnabled,
          shadowPassword: _shadowPasswordController.text,
          shadowMaxUnlocks: rawMaxUnlocks.isEmpty
              ? 0
              : int.tryParse(rawMaxUnlocks) ?? -1,
        ),
      ),
    );
  }

  void _changeMaster() {
    Navigator.of(context).pop(
      _PasswordVaultSettingsAction.changeMaster(
        _PasswordVaultMasterDraft(
          newMasterPassword: _newMasterController.text,
          confirmMasterPassword: _newMasterConfirmController.text,
        ),
      ),
    );
  }
}

class _PasswordVaultEntryCard extends StatefulWidget {
  const _PasswordVaultEntryCard({
    required this.index,
    required this.record,
    required this.accent,
    required this.password,
    required this.readOnly,
    required this.onGetPassword,
    required this.onCopyAccount,
    required this.onCopyPassword,
    required this.onEdit,
    required this.onDelete,
  });

  final ToolboxPasswordVaultEntryIndex index;
  final ToolboxPasswordVaultEncryptedRecord record;
  final Color accent;
  final String? password;
  final bool readOnly;
  final VoidCallback onGetPassword;
  final VoidCallback onCopyAccount;
  final VoidCallback onCopyPassword;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_PasswordVaultEntryCard> createState() =>
      _PasswordVaultEntryCardState();
}

class _PasswordVaultEntryCardState extends State<_PasswordVaultEntryCard> {
  bool _showPassword = false;

  @override
  void didUpdateWidget(covariant _PasswordVaultEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index.id != widget.index.id ||
        oldWidget.password != widget.password) {
      _showPassword = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final password = widget.password;
    final passwordLoaded = password != null;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      radius: ToolboxUiTokens.cardRadius,
      color: colorScheme.surfaceContainerLowest,
      borderColor: widget.accent.withValues(alpha: 0.2),
      shadowColor: widget.accent,
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: widget.accent.withValues(alpha: 0.12),
                foregroundColor: widget.accent,
                child: const Icon(Icons.password_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.index.displayTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.index.account.isEmpty
                          ? _lifeI18nText(
                              context,
                              'toolbox.crypto.password_vault.account_empty',
                            )
                          : widget.index.account,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.readOnly)
                IconButton(
                  tooltip: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.edit_entry',
                  ),
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
              if (!widget.readOnly)
                IconButton(
                  tooltip: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.delete_entry',
                  ),
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _LifePreviewFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PasswordVaultMaskedPasswordRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.password_label',
                  ),
                  value: passwordLoaded
                      ? (_showPassword ? password : _maskedPassword(password))
                      : _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.password_not_loaded',
                        ),
                  passwordLoaded: passwordLoaded,
                  showPassword: _showPassword,
                  onToggle: passwordLoaded
                      ? () => setState(() => _showPassword = !_showPassword)
                      : null,
                ),
                if (widget.index.hint.isNotEmpty)
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.hint_label',
                    ),
                    value: widget.index.hint,
                  ),
                if (widget.index.note.isNotEmpty)
                  _CryptoMetricRow(
                    label: _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.note_label',
                    ),
                    value: widget.index.note,
                  ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.record_security_label',
                  ),
                  value: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.record_security_value',
                    params: <String, Object?>{
                      'stages': widget.record.stageCount.toString(),
                      'cipherBits': '256',
                      'materialBits': widget.record.materialBits.bits
                          .toString(),
                    },
                  ),
                ),
                _CryptoMetricRow(
                  label: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.updated_label',
                  ),
                  value: MaterialLocalizations.of(
                    context,
                  ).formatFullDate(widget.index.updatedAt.toLocal()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (passwordLoaded)
                FilledButton.tonalIcon(
                  onPressed: widget.onCopyPassword,
                  icon: const Icon(Icons.password_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.copy_password',
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: widget.onGetPassword,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.get_password',
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: widget.index.account.isEmpty
                    ? null
                    : widget.onCopyAccount,
                icon: const Icon(Icons.copy_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.copy_account',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskedPassword(String password) {
    final length = password.runes.length.clamp(8, 32);
    return List<String>.filled(length, '*').join();
  }
}

class _PasswordVaultMaskedPasswordRow extends StatelessWidget {
  const _PasswordVaultMaskedPasswordRow({
    required this.label,
    required this.value,
    required this.passwordLoaded,
    required this.showPassword,
    required this.onToggle,
  });

  final String label;
  final String value;
  final bool passwordLoaded;
  final bool showPassword;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: showPassword ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const <ui.FontFeature>[
                  ui.FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          if (passwordLoaded)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _lifeI18nText(
                context,
                showPassword
                    ? 'toolbox.crypto.password_vault.hide_password'
                    : 'toolbox.crypto.password_vault.reveal_password',
              ),
              onPressed: onToggle,
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _PasswordVaultEntryDraft {
  const _PasswordVaultEntryDraft({
    required this.channel,
    required this.account,
    required this.password,
    required this.passwordChanged,
    required this.hint,
    required this.note,
    required this.strength,
  });

  final String channel;
  final String account;
  final String password;
  final bool passwordChanged;
  final String hint;
  final String note;
  final ToolboxPasswordVaultStrength strength;
}

class _PasswordVaultEntryEditorSheet extends StatefulWidget {
  const _PasswordVaultEntryEditorSheet({
    required this.accent,
    required this.defaultStrength,
    this.entry,
    this.index,
  });

  final Color accent;
  final ToolboxPasswordVaultStrength defaultStrength;
  final ToolboxPasswordVaultEntry? entry;
  final ToolboxPasswordVaultEntryIndex? index;

  @override
  State<_PasswordVaultEntryEditorSheet> createState() =>
      _PasswordVaultEntryEditorSheetState();
}

class _PasswordVaultEntryEditorSheetState
    extends State<_PasswordVaultEntryEditorSheet> {
  final ToolboxCryptoExtraService _passwordGenerator =
      ToolboxCryptoExtraService();
  late final TextEditingController _channelController = TextEditingController(
    text: widget.entry?.channel ?? widget.index?.channel ?? '',
  );
  late final TextEditingController _accountController = TextEditingController(
    text: widget.entry?.account ?? widget.index?.account ?? '',
  );
  late final TextEditingController _passwordController = TextEditingController(
    text: '',
  );
  late final TextEditingController _hintController = TextEditingController(
    text: widget.entry?.hint ?? widget.index?.hint ?? '',
  );
  late final TextEditingController _noteController = TextEditingController(
    text: widget.entry?.note ?? widget.index?.note ?? '',
  );
  late ToolboxPasswordVaultStrength _strength = widget.defaultStrength;
  bool _showPassword = false;
  bool _changePassword = false;

  @override
  void dispose() {
    _channelController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _hintController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editingExisting = widget.entry != null || widget.index != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: widget.accent.withValues(alpha: 0.12),
                    foregroundColor: widget.accent,
                    child: const Icon(Icons.password_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lifeI18nText(
                        context,
                        editingExisting
                            ? 'toolbox.crypto.password_vault.editor_edit_title'
                            : 'toolbox.crypto.password_vault.editor_new_title',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _channelController,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.field_channel',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.field_account',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (editingExisting) ...<Widget>[
                _LifePreviewFrame(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _lifeI18nText(
                                context,
                                'toolbox.crypto.password_vault.change_entry_password',
                              ),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lifeI18nText(
                                context,
                                'toolbox.crypto.password_vault.change_entry_password_helper',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _changePassword,
                        onChanged: (value) =>
                            setState(() => _changePassword = value),
                      ),
                    ],
                  ),
                ),
                if (_changePassword) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: _lifeI18nText(
                        context,
                        'toolbox.crypto.password_vault.field_new_password',
                      ),
                      suffixIcon: _buildPasswordFieldActions(context),
                    ),
                  ),
                ],
              ] else
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: _lifeI18nText(
                      context,
                      'toolbox.crypto.password_vault.field_password',
                    ),
                    suffixIcon: _buildPasswordFieldActions(context),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _hintController,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.field_hint',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.field_note',
                  ),
                ),
              ),
              if (!editingExisting) ...<Widget>[
                const SizedBox(height: 12),
                _buildRecordConfigExpansion(context),
                const SizedBox(height: 12),
                _buildClipboardSecurityNotice(context),
              ],
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.cancel',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.crypto.password_vault.save',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordConfigExpansion(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: EdgeInsets.zero,
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: theme.colorScheme.surfaceContainerLow,
      borderColor: theme.colorScheme.outlineVariant,
      shadowColor: widget.accent,
      shadowOpacity: 0.04,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.tune_rounded, color: widget.accent),
          title: Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.record_config_section',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.record_config_subtitle_v2',
            ),
            style: theme.textTheme.bodySmall,
          ),
          children: <Widget>[
            _LifeSegmentedField<ToolboxPasswordVaultStrength>(
              label: _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.strength_label',
              ),
              value: _strength,
              options: const <_LifeOption<ToolboxPasswordVaultStrength>>[
                _LifeOption<ToolboxPasswordVaultStrength>(
                  value: ToolboxPasswordVaultStrength.enhanced,
                  labelKey: 'toolbox.crypto.password_vault.strength_enhanced',
                ),
                _LifeOption<ToolboxPasswordVaultStrength>(
                  value: ToolboxPasswordVaultStrength.extreme,
                  labelKey: 'toolbox.crypto.password_vault.strength_extreme',
                ),
              ],
              onChanged: (value) => setState(() => _strength = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordFieldActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'toolbox.crypto.password_vault.generate_entry_password',
          ),
          onPressed: _generatePassword,
          icon: const Icon(Icons.auto_fix_high_rounded),
        ),
        IconButton(
          tooltip: _lifeI18nText(
            context,
            _showPassword
                ? 'toolbox.crypto.password_vault.hide_password'
                : 'toolbox.crypto.password_vault.reveal_password',
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
          icon: Icon(
            _showPassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ),
      ],
    );
  }

  void _generatePassword() {
    final result = _passwordGenerator.generatePassword(
      length: 24,
      includeLowercase: true,
      includeUppercase: true,
      includeDigits: true,
      includeSymbols: true,
      avoidAmbiguous: true,
    );
    setState(() {
      _passwordController.text = result.value;
      _showPassword = true;
      _changePassword = true;
    });
  }

  Widget _buildClipboardSecurityNotice(BuildContext context) {
    final theme = Theme.of(context);
    return _LifePreviewFrame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: widget.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.clipboard_security_notice_title',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lifeI18nText(
                    context,
                    'toolbox.crypto.password_vault.clipboard_security_notice_body',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final editingExisting = widget.entry != null || widget.index != null;
    Navigator.of(context).pop(
      _PasswordVaultEntryDraft(
        channel: _channelController.text,
        account: _accountController.text,
        password: _passwordController.text,
        passwordChanged: !editingExisting || _changePassword,
        hint: _hintController.text,
        note: _noteController.text,
        strength: _strength,
      ),
    );
  }
}

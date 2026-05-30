part of '../toolbox_crypto_security.dart';

class CryptoSecurityHubPage extends StatelessWidget {
  const CryptoSecurityHubPage({super.key});

  static const Color _accent = Color(0xFF286F7D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.ui.module.module_access.crypto_security_edbc46',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.crypto.a_security_hub_for_steganography_enc.96312ff54543',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ToolboxSurfaceCard(
            radius: ToolboxUiTokens.sectionPanelRadius,
            color: colorScheme.surfaceContainerLowest,
            borderColor: _accent.withValues(alpha: 0.22),
            shadowColor: _accent,
            shadowOpacity: 0.06,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.enhanced_encryption_rounded,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _lifeI18nText(
                              context,
                              'inline.plan295.crypto.security_workspace.75c2c69f6097',
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _lifeI18nText(
                              context,
                              'inline.plan295.crypto.submodules_open_from_standalone_card.b8f6715362dd',
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
                      text: _lifeI18nText(
                        context,
                        'inline.plan295.crypto.local_first.112fb08c91e5',
                      ),
                      accent: _accent,
                      backgroundColor: _accent.withValues(alpha: 0.08),
                    ),
                    ToolboxInfoPill(
                      text: _lifeI18nText(
                        context,
                        'inline.plan295.crypto.standalone_modules.bb91f39ee6b9',
                      ),
                      accent: _accent,
                      backgroundColor: _accent.withValues(alpha: 0.08),
                    ),
                    ToolboxInfoPill(
                      text: _lifeI18nText(
                        context,
                        'inline.plan295.crypto.expansion_ready.dd905eb8f2d1',
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
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.crypto.available_modules.f92f97f00fd0',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _CryptoSecurityModuleCard(
            icon: Icons.hide_image_rounded,
            accent: _accent,
            title: _lifeI18nText(
              context,
              'inline.plan295.crypto.media_steganography.ae000f7887ea',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.crypto.hide_encrypted_text_or_files_in_medi.7167c242d3c8',
            ),
            chips: <String>[
              _lifeI18nText(
                context,
                'inline.plan295.crypto.image.baebdc30e7e4',
              ),
              _lifeI18nText(
                context,
                'inline.plan295.crypto.audio.253158c06f3c',
              ),
              _lifeI18nText(
                context,
                'inline.plan295.crypto.video.2074eae3b2ea',
              ),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _SteganographyToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ToolboxSurfaceCard(
            radius: ToolboxUiTokens.cardRadius,
            color: colorScheme.surfaceContainerLow,
            borderColor: colorScheme.outlineVariant,
            shadowOpacity: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.add_road_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.crypto.future_encryption_decryption_key_cer.dfb97acfd04e',
                    ),
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
}

class _CryptoSecurityModuleCard extends StatelessWidget {
  const _CryptoSecurityModuleCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final List<String> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ToolboxUiTokens.cardRadius),
        onTap: onTap,
        child: ToolboxSurfaceCard(
          padding: const EdgeInsets.all(14),
          radius: ToolboxUiTokens.cardRadius,
          color: theme.colorScheme.surfaceContainerLowest,
          borderColor: accent.withValues(alpha: 0.22),
          shadowColor: accent,
          shadowOpacity: 0.05,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.14),
                foregroundColor: accent,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: chips
                          .map(
                            (chip) => ToolboxInfoPill(
                              text: chip,
                              accent: accent,
                              backgroundColor: accent.withValues(alpha: 0.08),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

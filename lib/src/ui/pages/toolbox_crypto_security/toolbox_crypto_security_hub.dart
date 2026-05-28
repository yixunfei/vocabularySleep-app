part of '../toolbox_crypto_security.dart';

class CryptoSecurityHubPage extends StatelessWidget {
  const CryptoSecurityHubPage({super.key});

  static const Color _accent = Color(0xFF286F7D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxToolPage(
      title: _lifeText(context, zh: '加密安全', en: 'Crypto security'),
      subtitle: _lifeText(
        context,
        zh: '面向隐写、加密、解密、密钥与校验的安全工具中心；当前先迁入媒体隐写子模块。',
        en: 'A security hub for steganography, encryption, decryption, keys, and verification; media steganography is the first migrated module.',
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
                            _lifeText(
                              context,
                              zh: '安全工具工作台',
                              en: 'Security workspace',
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _lifeText(
                              context,
                              zh: '子模块以独立卡片进入，便于后续扩展大量加密解密工具。',
                              en: 'Submodules open from standalone cards, leaving room for many future crypto tools.',
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
                      text: _lifeText(context, zh: '本地处理', en: 'Local-first'),
                      accent: _accent,
                      backgroundColor: _accent.withValues(alpha: 0.08),
                    ),
                    ToolboxInfoPill(
                      text: _lifeText(
                        context,
                        zh: '独立子模块',
                        en: 'Standalone modules',
                      ),
                      accent: _accent,
                      backgroundColor: _accent.withValues(alpha: 0.08),
                    ),
                    ToolboxInfoPill(
                      text: _lifeText(
                        context,
                        zh: '预留扩展',
                        en: 'Expansion-ready',
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
            _lifeText(context, zh: '已接入子模块', en: 'Available modules'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _CryptoSecurityModuleCard(
            icon: Icons.hide_image_rounded,
            accent: _accent,
            title: _lifeText(
              context,
              zh: '图片/音频/视频隐写',
              en: 'Media steganography',
            ),
            subtitle: _lifeText(
              context,
              zh: '将加密文本或文件写入媒体载体，并支持还原、文件加密与哈希校验。',
              en: 'Hide encrypted text or files in media carriers, with reveal, file crypto, and hash verification.',
            ),
            chips: <String>[
              _lifeText(context, zh: '图片', en: 'Image'),
              _lifeText(context, zh: '音频', en: 'Audio'),
              _lifeText(context, zh: '视频', en: 'Video'),
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
                    _lifeText(
                      context,
                      zh: '后续加密、解密、密钥、证书、校验、签名等能力会继续以独立子模块接入这里。',
                      en: 'Future encryption, decryption, key, certificate, verification, and signature tools will join this hub as separate modules.',
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

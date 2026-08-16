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
            icon: Icons.admin_panel_settings_rounded,
            accent: const Color(0xFF7A3F4D),
            title: _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.title',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.password_vault.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.hub_chip_crud',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.hub_chip_cascade',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.password_vault.hub_chip_export',
              ),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _PasswordVaultPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.password_rounded,
            accent: const Color(0xFF5E6B2D),
            title: _lifeI18nText(context, 'toolbox.crypto.password.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.password.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.password.hub_chip_random'),
              _lifeI18nText(context, 'toolbox.crypto.password.hub_chip_phrase'),
              _lifeI18nText(
                context,
                'toolbox.crypto.password.hub_chip_entropy',
              ),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _PasswordGeneratorPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.hide_image_rounded,
            accent: _accent,
            title: _lifeI18nText(
              context,
              'inline.plan295.crypto.media_steganography.ae000f7887ea',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.stego.hub_subtitle_experimental',
            ),
            chips: <String>[
              _lifeI18nText(
                context,
                'toolbox.crypto.stego.hub_chip_image_write',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.stego.hub_chip_av_reveal_only',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.stego.hub_chip_low_visibility',
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
          _CryptoSecurityModuleCard(
            icon: Icons.lock_rounded,
            accent: _accent,
            title: _lifeI18nText(context, 'toolbox.crypto.file.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.file.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.file.hub_chip_algorithms'),
              _lifeI18nText(context, 'toolbox.crypto.file.hub_chip_key_files'),
              _lifeI18nText(context, 'toolbox.crypto.file.hub_chip_auto'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _FileCryptoToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.text_fields_rounded,
            accent: _accent,
            title: _lifeI18nText(context, 'toolbox.crypto.text.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.text.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.text.hub_chip_v5'),
              _lifeI18nText(context, 'toolbox.crypto.text.hub_chip_base64'),
              _lifeI18nText(context, 'toolbox.crypto.text.hub_chip_keyfile'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _TextCryptoToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.graphic_eq_rounded,
            accent: const Color(0xFF286F7D),
            title: _lifeI18nText(context, 'toolbox.crypto.content_media.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.content_media.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(
                context,
                'toolbox.crypto.content_media.hub_chip_png',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.content_media.hub_chip_wav',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.content_media.hub_chip_v5',
              ),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ContentMediaToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.pin_rounded,
            accent: const Color(0xFF2F6F5E),
            title: _lifeI18nText(context, 'toolbox.crypto.otp.title'),
            subtitle: _lifeI18nText(context, 'toolbox.crypto.otp.hub_subtitle'),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.otp.hub_chip_totp'),
              _lifeI18nText(context, 'toolbox.crypto.otp.hub_chip_hotp'),
              _lifeI18nText(context, 'toolbox.crypto.otp.hub_chip_no_store'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _OtpToolPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.tag_rounded,
            accent: const Color(0xFF4B7A4F),
            title: _lifeI18nText(context, 'toolbox.crypto.hash.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.hash.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.hash.hub_chip_text'),
              _lifeI18nText(context, 'toolbox.crypto.hash.hub_chip_file'),
              _lifeI18nText(context, 'toolbox.crypto.hash.hub_chip_compare'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _HashCheckToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.verified_user_rounded,
            accent: const Color(0xFF8A5A2B),
            title: _lifeI18nText(context, 'toolbox.crypto.hmac.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.hmac.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.hmac.hub_chip_text_file'),
              _lifeI18nText(context, 'toolbox.crypto.hmac.hub_chip_verify'),
              _lifeI18nText(context, 'toolbox.crypto.hmac.hub_chip_keyed'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _HmacToolPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.vpn_key_rounded,
            accent: const Color(0xFF6D5E9C),
            title: _lifeI18nText(context, 'toolbox.crypto.keyfile.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.keyfile.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.keyfile.hub_chip_random'),
              _lifeI18nText(context, 'toolbox.crypto.keyfile.hub_chip_derive'),
              _lifeI18nText(context, 'toolbox.crypto.keyfile.hub_chip_combine'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _KeyFileManagerPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.call_split_rounded,
            accent: const Color(0xFF7A4E86),
            title: _lifeI18nText(context, 'toolbox.crypto.shamir.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.shamir.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.shamir.hub_chip_split'),
              _lifeI18nText(context, 'toolbox.crypto.shamir.hub_chip_recover'),
              _lifeI18nText(context, 'toolbox.crypto.shamir.hub_chip_local'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ShamirToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.key_rounded,
            accent: const Color(0xFF6D5E9C),
            title: _lifeI18nText(context, 'toolbox.crypto.asymmetric.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.asymmetric.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(context, 'toolbox.crypto.asymmetric.hub_chip_rsa'),
              _lifeI18nText(context, 'toolbox.crypto.asymmetric.hub_chip_ecc'),
              _lifeI18nText(context, 'toolbox.crypto.asymmetric.hub_chip_sign'),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _AsymmetricCryptoToolPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CryptoSecurityModuleCard(
            icon: Icons.enhanced_encryption_rounded,
            accent: const Color(0xFF315F92),
            title: _lifeI18nText(context, 'toolbox.crypto.veracrypt.title'),
            subtitle: _lifeI18nText(
              context,
              'toolbox.crypto.veracrypt.hub_subtitle',
            ),
            chips: <String>[
              _lifeI18nText(
                context,
                'toolbox.crypto.veracrypt.hub_chip_mobile',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.veracrypt.hub_chip_inspector',
              ),
              _lifeI18nText(
                context,
                'toolbox.crypto.veracrypt.hub_chip_no_mount',
              ),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _VeraCryptToolPage(),
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
                    _lifeI18nText(context, 'toolbox.crypto.hub.boundary_note'),
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

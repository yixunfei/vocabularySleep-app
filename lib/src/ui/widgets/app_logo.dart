import 'package:flutter/material.dart';

import '../../app/app_identity.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: AppIdentity.displayName,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            AppIdentity.logoAssetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

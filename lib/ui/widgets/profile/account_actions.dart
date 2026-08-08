import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// Bottom-of-profile action group: change-password (warning, outlined) and
/// sign-out (critical, filled). Icons give each button a recognisable
/// affordance before the label is read, and the taller vertical padding
/// gives the buttons enough weight to feel like committed actions.
class AccountActions extends StatelessWidget {
  const AccountActions({
    required this.onChangePassword,
    required this.onSignOut,
    super.key,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color warning = isDark ? AppColors.warningDark : AppColors.warning;
    final Color critical = isDark ? AppColors.criticalDark : AppColors.critical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline, size: 20),
          label: const Text('Cambiar contraseña'),
          onPressed: onChangePassword,
          style: OutlinedButton.styleFrom(
            foregroundColor: warning,
            side: BorderSide(color: warning, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            textStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('Cerrar sesión'),
          onPressed: onSignOut,
          style: FilledButton.styleFrom(
            backgroundColor: critical,
            foregroundColor: AppColors.paper,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            textStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

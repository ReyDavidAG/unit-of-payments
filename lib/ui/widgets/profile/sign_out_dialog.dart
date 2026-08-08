import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/letter_palette.dart';

/// Asks the user to confirm a destructive action. A custom [Dialog] (not
/// Material's AlertDialog) so the avatar circle, title and two equal-width
/// buttons can all breathe — AlertDialog clamps everything to its
/// left-aligned narrow column.
Future<bool> showSignOutDialog(
  BuildContext context, {
  required String email,
}) async {
  final ThemeData theme = Theme.of(context);
  final bool isDark = theme.brightness == Brightness.dark;
  final Color critical = isDark ? AppColors.criticalDark : AppColors.critical;
  final String letter = email.isEmpty
      ? '?'
      : email.substring(0, 1).toUpperCase();
  final Color borderColor = letterPaletteColor(letter);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                  border: Border.all(color: borderColor, width: 2.5),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¿Cerrar sesión?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Vas a salir de tu cuenta en este dispositivo. '
              'Tus datos quedan guardados.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: critical,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

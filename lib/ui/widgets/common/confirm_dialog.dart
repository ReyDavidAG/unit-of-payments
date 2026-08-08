import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';

/// Asks before something the user cannot take back with one tap. Returns false
/// on dismiss, so a stray tap outside never counts as a yes.
///
/// [destructive] paints the confirm button in the danger hue. Reversible
/// actions leave it false and keep the default primary voice — an app where
/// every dialog is red teaches the user to ignore red.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Mejor no',
  bool destructive = false,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final bool isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.dangerDark
                        : AppColors.danger,
                    // Paired per mode, not a single light cream: cream on
                    // dangerDark measures 3.81:1, under the floor.
                    foregroundColor: isDark
                        ? AppColors.paperDark
                        : AppColors.paper,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// Single bottom sheet with two voices:
///   - paso 1: "Hay una nueva versión" → "Actualizar ahora" / "Después"
///   - paso 3: "Listo para instalar"   → "Instalar ahora" (sin "Después")
///
/// The shape, the colors and the rhythm are identical; only [title], [body],
/// [actionLabel], [onDismiss] and [isDismissible] change.
class UpdateBottomSheet extends StatelessWidget {
  const UpdateBottomSheet({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.onDismiss,
    this.isDismissible = true,
    super.key,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
    VoidCallback? onDismiss,
    bool isDismissible = true,
  }) => showModalBottomSheet<void>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => UpdateBottomSheet(
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
      isDismissible: isDismissible,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle. Hidden when not dismissible: paso 3 has no exit
            // and a grabbable handle implies the wrong affordance.
            if (isDismissible)
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
            Icon(
              Icons.system_update,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(actionLabel),
            ),
            if (onDismiss != null) ...[
              const SizedBox(height: AppSpacing.xs2),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Después'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

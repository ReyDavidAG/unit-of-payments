import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';

/// Decorative drag handle at the top of the bottom sheet. Material's built-in
/// `showDragHandle: true` ships its own drag widget that, combined with the
/// inner SingleChildScrollView, swallows the drag-to-dismiss gesture on some
/// Flutter builds; drawing the handle inline keeps the visual without the
/// dismiss-eating side effect.
class SheetDragHandleWidget extends StatelessWidget {
  const SheetDragHandleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color tint = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

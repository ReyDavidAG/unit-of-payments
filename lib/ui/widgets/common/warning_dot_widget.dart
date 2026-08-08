import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';

/// Filled circle with a glyph inside, in the semantic warning hue. Small enough
/// to sit inline next to a title, loud enough to be found while scanning.
///
/// The glyph is not decoration: colour alone cannot carry a warning for a
/// colour-blind user, and the badge is often the only thing on the row that
/// has changed.
class WarningDotWidget extends StatelessWidget {
  const WarningDotWidget({required this.tooltip, this.size = 16, super.key});

  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color fill = isDark ? AppColors.warningDark : AppColors.warning;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            // The amber measures 1.79:1 on the light paper — the fill alone
            // has no silhouette there. The ink ring is what makes it a shape.
            border: Border.all(color: AppColors.ink),
          ),
          // Both warning hues are light, so the glyph is always the dark ink.
          child: Icon(
            Icons.priority_high,
            size: size * 0.72,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

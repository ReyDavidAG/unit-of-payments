import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// The eight curated swatches from DESIGN.md and nothing else. A free colour
/// picker is the fastest way to destroy the palette.
class CardSwatchPickerWidget extends StatelessWidget {
  const CardSwatchPickerWidget({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final Color swatch in AppColors.cardSwatches.values)
          _Swatch(
            color: swatch,
            selected: AppColors.hexOf(swatch) == selected.toUpperCase(),
            outline: theme.colorScheme.onSurface,
            onTap: () => onSelected(AppColors.hexOf(swatch)),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.outline,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final Color outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        // Not animated: eight swatches animating at once would blow the
        // two-moving-things-per-screen budget for a state that reads instantly.
        child: Container(
          width: AppSpacing.xl,
          height: AppSpacing.xl,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // Selection is a ring, not a checkmark: the colour has to stay
            // fully visible to be judged against the others.
            border: Border.all(
              color: selected ? outline : Colors.transparent,
              width: selected ? AppSpacing.xs3 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

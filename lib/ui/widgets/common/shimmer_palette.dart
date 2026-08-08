import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';

/// Single source for shimmer colors. Honours the warm-grey palette in both
/// modes: the sweep reads against the surrounding `paper` instead of fighting
/// it.
class ShimmerPalette {
  const ShimmerPalette({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  static ShimmerPalette of(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const ShimmerPalette(
            base: AppColors.surfaceDark,
            highlight: AppColors.surface2Dark,
          )
        : const ShimmerPalette(
            base: AppColors.surface2,
            highlight: AppColors.surface,
          );
  }
}

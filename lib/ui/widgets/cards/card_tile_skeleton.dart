import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/theme/app_spacing.dart';
import '../common/shimmer_palette.dart';

/// Skeleton for [CardTileWidget]. Mirrors the swatch square, alias, meta line
/// and archive icon, so the layout doesn't jump when the data arrives.
class CardTileSkeleton extends StatelessWidget {
  const CardTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ShimmerPalette palette = ShimmerPalette.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Shimmer.fromColors(
          baseColor: palette.base,
          highlightColor: palette.highlight,
          child: Row(
            children: [
              Container(
                width: AppSpacing.md,
                height: AppSpacing.md,
                decoration: BoxDecoration(
                  color: palette.base,
                  borderRadius: BorderRadius.circular(AppSpacing.xs2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(width: 140, height: 14, color: palette.base),
                    const SizedBox(height: AppSpacing.xs3),
                    _Bar(width: 96, height: 12, color: palette.base),
                  ],
                ),
              ),
              Container(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                decoration: BoxDecoration(
                  color: palette.base,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.xs2),
    ),
  );
}

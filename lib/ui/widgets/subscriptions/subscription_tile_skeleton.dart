import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/theme/app_spacing.dart';
import '../common/shimmer_palette.dart';

/// Skeleton for [SubscriptionTileWidget]. Mirrors the 3 px colour bar, name,
/// meta line, amount and charge label.
class SubscriptionTileSkeleton extends StatelessWidget {
  const SubscriptionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ShimmerPalette palette = ShimmerPalette.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: AppSpacing.swatchBar, color: palette.base),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Shimmer.fromColors(
                  baseColor: palette.base,
                  highlightColor: palette.highlight,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bar(width: 180, height: 14, color: palette.base),
                            const SizedBox(height: AppSpacing.xs3),
                            _Bar(width: 120, height: 12, color: palette.base),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Bar(width: 72, height: 14, color: palette.base),
                          const SizedBox(height: AppSpacing.xs3),
                          _Bar(width: 48, height: 12, color: palette.base),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/theme/app_spacing.dart';
import '../common/shimmer_palette.dart';

/// Skeleton for [NotificationEntryWidget]. Mirrors the icon, title, meta line
/// and amount.
class NotificationEntrySkeleton extends StatelessWidget {
  const NotificationEntrySkeleton({super.key});

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
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(width: 160, height: 14, color: palette.base),
                    const SizedBox(height: AppSpacing.xs3),
                    _Bar(width: 220, height: 12, color: palette.base),
                  ],
                ),
              ),
              _Bar(width: 64, height: 14, color: palette.base),
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

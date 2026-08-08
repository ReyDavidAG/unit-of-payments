import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/theme/app_spacing.dart';
import '../common/shimmer_palette.dart';

/// Skeleton for the dashboard body. Mirrors the monthly total, spend-split
/// bar, per-card breakdown and upcoming-charges card.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ShimmerPalette palette = ShimmerPalette.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _MonthlyTotalSkeleton(palette: palette),
        const SizedBox(height: AppSpacing.lg),
        Shimmer.fromColors(
          baseColor: palette.base,
          highlightColor: palette.highlight,
          child: Container(
            height: AppSpacing.md,
            decoration: BoxDecoration(
              color: palette.base,
              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabelSkeleton(),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < 3; i++) ...[
          _CardTotalSkeleton(palette: palette),
          const SizedBox(height: AppSpacing.listGap),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        const _SectionLabelSkeleton(),
        const SizedBox(height: AppSpacing.sm),
        _UpcomingCardSkeleton(palette: palette),
      ],
    );
  }
}

class _MonthlyTotalSkeleton extends StatelessWidget {
  const _MonthlyTotalSkeleton({required this.palette});

  final ShimmerPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(width: 48, height: 11, color: palette.base),
          const SizedBox(height: AppSpacing.xs2),
          Shimmer.fromColors(
            baseColor: palette.base,
            highlightColor: palette.highlight,
            child: _Bar(width: 220, height: 40, color: palette.base),
          ),
        ],
      ),
    );
  }
}

class _CardTotalSkeleton extends StatelessWidget {
  const _CardTotalSkeleton({required this.palette});

  final ShimmerPalette palette;

  @override
  Widget build(BuildContext context) {
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
                    _Bar(width: 120, height: 16, color: palette.base),
                    const SizedBox(height: AppSpacing.xs3),
                    _Bar(width: 180, height: 12, color: palette.base),
                  ],
                ),
              ),
              _Bar(width: 88, height: 18, color: palette.base),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingCardSkeleton extends StatelessWidget {
  const _UpcomingCardSkeleton({required this.palette});

  final ShimmerPalette palette;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Shimmer.fromColors(
          baseColor: palette.base,
          highlightColor: palette.highlight,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Row(
                  children: [
                    Container(
                      width: AppSpacing.xs,
                      height: AppSpacing.xs,
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
                          _Bar(width: 100, height: 12, color: palette.base),
                        ],
                      ),
                    ),
                    _Bar(width: 64, height: 14, color: palette.base),
                  ],
                ),
                if (i < 2) const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: palette.base),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Bar(width: 48, height: 12, color: palette.base),
                  _Bar(width: 80, height: 14, color: palette.base),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabelSkeleton extends StatelessWidget {
  const _SectionLabelSkeleton();

  @override
  Widget build(BuildContext context) {
    final ShimmerPalette palette = ShimmerPalette.of(context);
    return Shimmer.fromColors(
      baseColor: palette.base,
      highlightColor: palette.highlight,
      child: _Bar(width: 96, height: 11, color: palette.base),
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

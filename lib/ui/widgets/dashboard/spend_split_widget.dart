import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_total_model.dart';

/// Proportion bar: where the monthly total goes, one segment per card.
///
/// It is never the only carrier of identity — the per-card list underneath
/// names and totals every segment, which is what lets three of the swatches
/// sit below 3:1 against the surface.
class SpendSplitWidget extends StatelessWidget {
  const SpendSplitWidget({required this.totals, super.key});

  final List<CardTotalModel> totals;

  /// Beyond five the segments get too thin to read and colours start
  /// repeating, so the tail folds into one neutral bucket.
  static const int _maxSegments = 5;
  static const double _barHeight = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double total = totals.fold(0, (sum, item) => sum + item.monthlyTotal);
    // One segment is not a proportion; two is the smallest split worth drawing.
    if (totals.length < 2 || total <= 0) {
      return const SizedBox.shrink();
    }

    final List<_Segment> segments = _segments(theme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs2),
      child: SizedBox(
        height: _barHeight,
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              // A 2px gap of surface between fills, so adjacent segments read
              // as separate even when their colours are close.
              if (i > 0) const SizedBox(width: AppSpacing.xs3),
              Expanded(
                flex: (segments[i].value / total * 10000).round().clamp(
                  1,
                  10000,
                ),
                child: ColoredBox(color: segments[i].color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_Segment> _segments(ThemeData theme) {
    final List<CardTotalModel> sorted = [...totals]
      ..sort((a, b) => b.monthlyTotal.compareTo(a.monthlyTotal));
    final List<_Segment> segments = [
      for (final CardTotalModel item in sorted.take(_maxSegments))
        _Segment(
          item.color.isEmpty
              ? theme.colorScheme.outline
              : AppColors.swatchFromHex(item.color),
          item.monthlyTotal,
        ),
    ];
    if (sorted.length > _maxSegments) {
      segments.add(
        _Segment(
          theme.colorScheme.outline,
          sorted
              .skip(_maxSegments)
              .fold(0, (sum, item) => sum + item.monthlyTotal),
        ),
      );
    }
    return segments;
  }
}

class _Segment {
  const _Segment(this.color, this.value);

  final Color color;
  final double value;
}

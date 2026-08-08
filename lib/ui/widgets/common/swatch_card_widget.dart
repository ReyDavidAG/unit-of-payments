import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';

/// A card with its owner's colour running down the left edge. Every row that
/// belongs to a payment card is built from this — the list, the totals, the
/// statement — so the bar is the same width in all of them and "which card is
/// this" is answered by colour before a word is read.
///
/// The bar is a hard edge against the card fill, never a filled tile: the
/// swatches are saturated and a filled row would compete with the amount.
class SwatchCardWidget extends StatelessWidget {
  const SwatchCardWidget({
    required this.swatch,
    required this.child,
    this.onTap,
    super.key,
  });

  final Color swatch;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight so the bar runs the full height of whatever the row
    // turns out to be, rather than a guessed fixed height.
    final Widget body = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: AppSpacing.swatchBar, color: swatch),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: child,
            ),
          ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

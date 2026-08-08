import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_assets.dart';
import '../../../data/models/cards/card_model.dart';

/// Brand picker for the card form. Each option shows the brand's bundled
/// WebP as a small card thumbnail, the brand label below, and a selection
/// ring. The thumbnail is exactly 1.6:1 to match the WebP source — any
/// mismatch crops the card and hides the chip or wordmark.
class CardBrandPickerWidget extends StatelessWidget {
  const CardBrandPickerWidget({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CardBrand selected;
  final ValueChanged<CardBrand> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final CardBrand brand in CardBrand.values)
          _BrandTile(
            brand: brand,
            selected: brand == selected,
            outline: theme.colorScheme.onSurface,
            onTap: () => onSelected(brand),
          ),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({
    required this.brand,
    required this.selected,
    required this.outline,
    required this.onTap,
  });

  final CardBrand brand;
  final bool selected;
  final Color outline;
  final VoidCallback onTap;

  // Width and height match the bundled WebP exactly (640×400 source =
  // 1.6:1). Sized down to ~50% so four tiles fit comfortably in a row on
  // phone-width sheets without wrapping.
  static const double _width = 60;
  static const double _height = 38;

  // Concentric corners: the ring sits `xs2` away from the artwork, so its
  // radius has to be the artwork's radius plus that gap or the curves fight.
  static const double _gap = AppSpacing.xs2;
  static const double _artRadius = AppSpacing.xs2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: brand.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_artRadius + _gap),
        child: Container(
          padding: const EdgeInsets.all(_gap),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_artRadius + _gap),
            // Always drawn, only ever tinted: a border that appears on
            // selection would resize the tile and shove the row sideways.
            border: Border.all(
              color: selected ? outline : Colors.transparent,
              width: AppSpacing.xs3,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_artRadius),
                child: Image.asset(
                  CardAssets.webp(brand),
                  width: _width,
                  height: _height,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xs2),
              SizedBox(
                width: _width,
                child: Text(
                  brand.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

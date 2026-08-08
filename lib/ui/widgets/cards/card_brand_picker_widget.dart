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
  // 1.6:1). Earlier this was 96×60 with an extra inset, which cropped the
  // WebP and left only the middle band visible.
  static const double _width = 120;
  static const double _height = 75;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: brand.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        child: Container(
          width: _width,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            border: Border.all(
              color: selected ? outline : Colors.transparent,
              width: selected ? AppSpacing.xs3 : 0,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.xs2),
                child: Image.asset(
                  CardAssets.webp(brand),
                  width: _width,
                  height: _height,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xs2),
              Text(brand.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

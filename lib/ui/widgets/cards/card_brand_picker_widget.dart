import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_assets.dart';
import '../../../data/models/cards/card_model.dart';

/// Brand picker for the card form. Each option shows the brand's bundled
/// WebP as a small card thumbnail, the brand label below, and a selection
/// ring. Replaces the old six-swatch colour picker — the brand is the
/// identity now, not a user-picked colour.
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

  static const double _width = 96;
  static const double _height = 60;

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
                  width: _width - AppSpacing.md,
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

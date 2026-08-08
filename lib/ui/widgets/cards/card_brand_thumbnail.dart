import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_assets.dart';
import '../../../data/models/cards/card_model.dart';

/// The brand art, ringed in the card's own swatch.
///
/// The ring is what makes the colour legible at thumbnail scale: the WebP
/// fills its frame, so without it the swatch would only exist on the far edge
/// of the row. Brand and swatch answer two different questions — which network
/// processes it, and which of *your* cards this is — and both are on screen.
class CardBrandThumbnail extends StatelessWidget {
  const CardBrandThumbnail({
    required this.brand,
    required this.swatch,
    super.key,
  });

  final CardBrand brand;
  final Color swatch;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      border: Border.all(color: swatch, width: AppSpacing.xs3),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs2),
      child: Image.asset(
        CardAssets.webp(brand),
        width: AppSpacing.xl2,
        height: AppSpacing.xl,
        fit: BoxFit.cover,
      ),
    ),
  );
}

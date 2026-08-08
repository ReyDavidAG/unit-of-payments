import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../data/models/cards/card_model.dart';
import '../common/swatch_card_widget.dart';
import 'card_brand_thumbnail.dart';

/// Alias in title weight, brand WebP as a small card thumbnail beside it,
/// last4 in mono. The swatch runs down the edge and rings the art — the same
/// bar every charge on this card draws, so the link is learned once.
class CardTileWidget extends StatelessWidget {
  const CardTileWidget({
    required this.card,
    required this.onTap,
    required this.onArchive,
    super.key,
  });

  final CardModel card;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final Color swatch = AppColors.swatchFromHex(card.color);

    return SwatchCardWidget(
      swatch: swatch,
      onTap: onTap,
      child: Row(
        children: [
          CardBrandThumbnail(brand: card.brand, swatch: swatch),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _Details(card: card)),
          IconButton(
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archivar',
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.textTheme.bodySmall?.color ?? theme.hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.alias,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs3),
        if (card.last4 == null)
          Text(card.brand.label, style: theme.textTheme.bodySmall)
        else
          Row(
            children: [
              // The brand is the one that gives: its artwork is already on the
              // thumbnail, while the last4 is the only thing here that tells
              // two cards of the same brand apart.
              Flexible(
                child: Text(
                  card.brand.label,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('•••• ${card.last4}', style: AppTypography.figure(muted)),
            ],
          ),
      ],
    );
  }
}

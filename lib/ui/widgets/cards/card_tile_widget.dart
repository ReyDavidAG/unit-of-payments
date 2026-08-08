import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../data/models/cards/card_model.dart';

/// Alias in title weight, swatch as a small square beside it, last4 in mono.
/// The swatch never becomes the tile background.
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
    final ThemeData theme = Theme.of(context);
    final Color swatch = AppColors.swatchFromHex(card.color);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              Container(
                width: AppSpacing.md,
                height: AppSpacing.md,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(AppSpacing.xs2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.alias, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs3),
                    _Meta(card: card),
                  ],
                ),
              ),
              IconButton(
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archivar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.textTheme.bodySmall?.color ?? theme.hintColor;

    if (card.last4 == null) {
      return Text(card.brand.label, style: theme.textTheme.bodySmall);
    }
    return Row(
      children: [
        Text(card.brand.label, style: theme.textTheme.bodySmall),
        const SizedBox(width: AppSpacing.xs),
        Text('•••• ${card.last4}', style: AppTypography.figure(muted)),
      ],
    );
  }
}

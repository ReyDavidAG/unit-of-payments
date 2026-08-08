import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_total_model.dart';
import '../cards/card_brand_thumbnail.dart';
import '../common/swatch_card_widget.dart';

/// One card alias and what it costs per month. Same bar and same ring as the
/// row on Tarjetas: the summary is a view of those cards, so it identifies
/// them the same way rather than inventing a second visual language.
class CardTotalWidget extends StatelessWidget {
  const CardTotalWidget({required this.total, required this.today, super.key});

  final CardTotalModel total;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = total.subscriptionCount;
    final Color swatch = AppColors.swatchFromHex(total.color);

    return SwatchCardWidget(
      swatch: swatch,
      child: Row(
        children: [
          CardBrandThumbnail(brand: total.brand, swatch: swatch),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total.alias,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs3),
                Text(_subtitle(count), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            MoneyHelper.amount(total.monthlyTotal),
            style: AppTypography.amount(theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  String _subtitle(int count) {
    final String plural = count == 1 ? 'suscripción' : 'suscripciones';
    if (total.nextChargeDate == null) {
      return '$count $plural';
    }
    final int days = DateTime(
      total.nextChargeDate!.year,
      total.nextChargeDate!.month,
      total.nextChargeDate!.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    return '$count $plural · '
        '${MoneyHelper.chargeLabel(total.nextChargeDate!, days)}';
  }
}

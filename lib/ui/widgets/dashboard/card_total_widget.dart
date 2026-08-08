import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_assets.dart';
import '../../../data/models/cards/card_total_model.dart';

/// One card alias and what it costs per month. The swatch is a small square
/// beside the alias, never the tile background.
class CardTotalWidget extends StatelessWidget {
  const CardTotalWidget({required this.total, required this.today, super.key});

  final CardTotalModel total;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = total.subscriptionCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs2),
              child: Image.asset(
                CardAssets.webp(total.brand),
                width: AppSpacing.xl2,
                height: AppSpacing.xl,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(total.alias, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs3),
                  Text(_subtitle(count), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              MoneyHelper.amount(total.monthlyTotal),
              style: AppTypography.amount(theme.colorScheme.onSurface),
            ),
          ],
        ),
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

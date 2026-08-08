import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_assets.dart';
import '../../../data/models/subscriptions/subscription_model.dart';

/// Name on the left, amount right-aligned in mono so decimals line up down the
/// list. The card colour is a bar on the edge, never a filled tile.
class SubscriptionTileWidget extends StatelessWidget {
  const SubscriptionTileWidget({
    required this.subscription,
    required this.onTap,
    required this.today,
    super.key,
  });

  final SubscriptionModel subscription;
  final VoidCallback onTap;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int? days = subscription.daysUntilCharge(today);
    final bool imminent = days != null && days <= 3;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: AppSpacing.swatchBar,
                color:
                    subscription.cardId == null ||
                        subscription.cardBrand == null
                    ? theme.dividerColor
                    : CardAssets.accent(subscription.cardBrand!),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Row(
                    children: [
                      Expanded(child: _Details(subscription: subscription)),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            MoneyHelper.amount(subscription.amount),
                            style: AppTypography.amount(
                              theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs3),
                          if (subscription.nextChargeDate != null)
                            Text(
                              MoneyHelper.chargeLabel(
                                subscription.nextChargeDate!,
                                days ?? 0,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                // The accent is the attention colour, and this
                                // is the only thing on the row that wants it.
                                color: imminent
                                    ? theme.colorScheme.secondary
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String meta = [
      subscription.cycle.label,
      if (subscription.cardAlias != null) subscription.cardAlias!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subscription.name,
          style: theme.textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs3),
        Text(meta, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_assets.dart';
import '../../../data/models/subscriptions/subscription_model.dart';

/// A charge due soon. Denser than the subscriptions list on purpose: this is a
/// glance, not a place to edit.
class UpcomingChargeWidget extends StatelessWidget {
  const UpcomingChargeWidget({
    required this.subscription,
    required this.today,
    super.key,
  });

  final SubscriptionModel subscription;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int days = subscription.daysUntilCharge(today) ?? 0;
    final bool imminent = days <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              // Brand accent on the dot: the row's tiny identifier. Falls
              // back to outline when the subscription has no card attached.
              color: subscription.cardBrand == null
                  ? theme.colorScheme.outline
                  : CardAssets.accent(subscription.cardBrand!),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              subscription.name,
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            MoneyHelper.chargeLabel(subscription.nextChargeDate!, days),
            style: theme.textTheme.bodySmall?.copyWith(
              // The accent marks urgency and nothing else on this screen.
              color: imminent ? theme.colorScheme.secondary : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            MoneyHelper.amount(subscription.amount),
            style: AppTypography.amount(theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

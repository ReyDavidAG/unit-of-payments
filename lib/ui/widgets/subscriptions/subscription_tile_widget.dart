import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
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
    final bool isDark = theme.brightness == Brightness.dark;

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
                                // Semantic palette: critical when imminent,
                                // warning when soon, success when there's
                                // runway, default muted otherwise.
                                color: AppColors.urgency(
                                  days ?? 0,
                                  isDark: isDark,
                                ),
                                fontWeight:
                                    AppColors.urgency(
                                          days ?? 0,
                                          isDark: isDark,
                                        ) ==
                                        null
                                    ? null
                                    : FontWeight.w500,
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
    // An installment plan reports progress where an open-ended charge reports
    // its cycle: "Mensual" is true of both and useful on neither.
    final String meta = [
      if (subscription.isInstallment && subscription.installmentsPaid != null)
        '${subscription.kind.shortLabel} '
            '${subscription.installmentsPaid} de '
            '${subscription.installmentsTotal}'
      else
        subscription.cycle.label,
      if (subscription.cardAlias != null) subscription.cardAlias!,
      if (subscription.owedBy != null) '${subscription.owedBy} te paga',
    ].join(' · ');
    // Meta line carries the brand tint at 80% opacity — a hint of the card's
    // colour without filling the row. Reads as muted when no card is set.
    final Color? brandTint = subscription.cardBrand == null
        ? null
        : CardAssets.accent(subscription.cardBrand!).withValues(alpha: 0.8);

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
        Text(
          meta,
          style: theme.textTheme.bodySmall?.copyWith(color: brandTint),
        ),
      ],
    );
  }
}

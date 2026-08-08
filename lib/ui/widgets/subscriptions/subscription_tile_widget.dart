import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../widgets/common/swatch_card_widget.dart';
import '../../widgets/common/warning_dot_widget.dart';

/// Name on the left, amount right-aligned in mono so decimals line up down the
/// list. The bar on the edge carries the card's own swatch — the same colour
/// that identifies the card on the Tarjetas tab, so the link is learned once.
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
    final bool paused = subscription.isPaused;

    return SwatchCardWidget(
      // A paused charge drops its colour along with its urgency: the row is
      // still there, it just stops claiming attention.
      swatch: subscription.cardId == null || paused
          ? theme.dividerColor
          : AppColors.swatchFromHex(subscription.cardColor),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _Details(subscription: subscription)),
          const SizedBox(width: AppSpacing.sm),
          _Amount(subscription: subscription, days: days, isDark: isDark),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.subscription,
    required this.days,
    required this.isDark,
  });

  final SubscriptionModel subscription;
  final int? days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool paused = subscription.isPaused;
    // Paused reads as muted rather than urgent: it has no next charge to be
    // urgent about, and an amber "en 4 días" on a stopped charge is a lie.
    final Color? tint = paused
        ? null
        : AppColors.urgency(days ?? 0, isDark: isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          MoneyHelper.amount(subscription.amount),
          style: AppTypography.amount(
            paused
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs3),
        if (paused)
          Text('En pausa', style: theme.textTheme.bodySmall)
        else if (subscription.nextChargeDate != null)
          Text(
            MoneyHelper.chargeLabel(subscription.nextChargeDate!, days ?? 0),
            style: theme.textTheme.bodySmall?.copyWith(
              // Semantic palette: critical when imminent, warning when soon,
              // success when there's runway, default muted otherwise.
              color: tint,
              fontWeight: tint == null ? null : FontWeight.w500,
            ),
          ),
      ],
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
      subscription.progressLabel,
      if (subscription.cardAlias != null) subscription.cardAlias!,
      if (subscription.owedBy != null) '${subscription.owedBy} te paga',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (subscription.cardArchived) ...[
              const WarningDotWidget(tooltip: 'La tarjeta está archivada'),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                subscription.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: subscription.isPaused
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs3),
        // Plain muted, never the card's brand colour: a Visa navy or a
        // Mastercard red on this line measured under 2:1 in dark mode.
        // Card identity is the bar's job, and the bar is unreadable-proof.
        Text(meta, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

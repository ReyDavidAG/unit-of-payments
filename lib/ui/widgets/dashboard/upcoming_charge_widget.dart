import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/subscriptions/subscription_model.dart';

/// A charge due soon. Denser than the subscriptions list on purpose: this is a
/// glance, not a place to edit. The charge-label colour follows the
/// semantic palette: critical when imminent, warning when soon, success
/// when there's plenty of runway.
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
    final bool isDark = theme.brightness == Brightness.dark;
    final Color? urgencyColor = _urgencyColor(days, isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // The dot is this list's version of the swatch bar — same width, same
          // colour, same question answered. It used to carry the brand accent,
          // which made every Visa the same navy dot no matter which card it was.
          Container(
            width: AppSpacing.swatchBar,
            height: AppSpacing.swatchBar,
            decoration: BoxDecoration(
              color: subscription.cardId == null
                  ? theme.colorScheme.outline
                  : AppColors.swatchFromHex(subscription.cardColor),
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
              // The semantic palette carries the time-to-charge signal:
              // pink when it's now, amber when it's close, green when
              // there's breathing room.
              color: urgencyColor,
              fontWeight: urgencyColor == null ? null : FontWeight.w500,
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

  /// Map days-until-charge to a semantic colour. Null means "no tint"
  /// — the default muted copy. Critical / warning / success escalate
  /// with proximity.
  static Color? _urgencyColor(int days, bool isDark) {
    if (days <= 3) return isDark ? AppColors.criticalDark : AppColors.critical;
    if (days <= 6) return isDark ? AppColors.warningDark : AppColors.warning;
    if (days <= 13) return isDark ? AppColors.successDark : AppColors.success;
    return null;
  }
}

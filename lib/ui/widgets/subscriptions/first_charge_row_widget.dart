import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../core/helpers/money_helper.dart';

/// First-charge row with the absolute date and its relative phrasing on the
/// same tile, so the user sees "when" once instead of having to read two
/// separate labels.
class FirstChargeRowWidget extends StatelessWidget {
  const FirstChargeRowWidget({
    required this.isInstallment,
    required this.date,
    required this.daysUntil,
    required this.onTap,
    super.key,
  });

  final bool isInstallment;
  final DateTime date;
  final int daysUntil;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isInstallment ? 'Primer pago' : 'Primer cobro',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs3),
                  Text(
                    '${MoneyHelper.longDate(date)} · ${MoneyHelper.chargeLabel(date, daysUntil)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

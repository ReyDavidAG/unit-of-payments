import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/notifications/notification_log_model.dart';

/// One row of the reminder history.
class NotificationEntryWidget extends StatelessWidget {
  const NotificationEntryWidget({required this.entry, super.key});

  final NotificationLogModel entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool sent = entry.deliveredAt != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            // Icon plus text, never colour alone: a state carried only by a
            // dot is a state a colourblind reader cannot read.
            Icon(
              sent ? Icons.check_circle_outline : Icons.schedule,
              size: AppSpacing.md,
              color: sent
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xs3),
                  Text(
                    '${sent ? 'Avisado' : 'Programado'} · '
                    'cobro el ${MoneyHelper.shortDate(entry.chargeDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              MoneyHelper.amount(entry.amount),
              style: AppTypography.amount(theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

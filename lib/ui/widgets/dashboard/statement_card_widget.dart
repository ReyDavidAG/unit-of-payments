import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_statement_model.dart';
import '../common/swatch_card_widget.dart';

/// One card's open statement: what closes, when it has to be paid, and how much
/// of it someone else is repaying.
class StatementCardWidget extends StatelessWidget {
  const StatementCardWidget({
    required this.statement,
    required this.today,
    super.key,
  });

  final CardStatementModel statement;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final int? days = statement.daysUntilDue(today);
    final Color? urgency = days == null
        ? null
        : AppColors.urgency(days, isDark: isDark);

    return SwatchCardWidget(
      swatch: AppColors.swatchFromHex(statement.color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statement.alias,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs3),
                Text(
                  _deadline(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: urgency,
                    fontWeight: urgency == null ? null : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyHelper.amount(statement.totalDue),
                style: AppTypography.amount(theme.colorScheme.onSurface),
              ),
              if (statement.isShared) ...[
                const SizedBox(height: AppSpacing.xs3),
                Text(
                  'Tuyo ${MoneyHelper.amount(statement.yours)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Without a due day there is a total but no deadline, so the card says what
  /// it can and points at the missing field rather than inventing a date.
  String _deadline() {
    final int? days = statement.daysUntilDue(today);
    if (statement.dueOn == null || days == null) {
      return 'Cierra el ${MoneyHelper.shortDate(statement.closesOn)} · '
          'agrega el día límite';
    }
    return '${MoneyHelper.dueLabel(statement.dueOn!, days)} · '
        'cierra el ${MoneyHelper.shortDate(statement.closesOn)}';
  }
}

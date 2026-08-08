import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/subscriptions/debtor_model.dart';
import '../../../data/providers/dashboard/dashboard_provider.dart';
import '../../widgets/common/section_label_widget.dart';

/// Who repays charges on the user's cards. Hidden entirely until someone does:
/// most people never lend a card.
class DebtorsView extends ConsumerWidget {
  const DebtorsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DebtorModel> debtors =
        ref.watch(debtorsProvider).value ?? const [];
    if (debtors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionLabelWidget('TE REEMBOLSAN'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              children: [
                for (final DebtorModel debtor in debtors)
                  _DebtorRow(debtor: debtor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DebtorRow extends StatelessWidget {
  const _DebtorRow({required this.debtor});

  final DebtorModel debtor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Outstanding is the number that matters when there is an end date; an
    // open-ended split has none, so that row reports the monthly figure.
    final bool showOutstanding = debtor.hasEnd;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtor.name,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs3),
                Text(
                  showOutstanding
                      ? '${MoneyHelper.amount(debtor.monthlyAmount)} al mes'
                      : '${debtor.planCount} cargo'
                            '${debtor.planCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            MoneyHelper.amount(
              showOutstanding ? debtor.outstanding : debtor.monthlyAmount,
            ),
            style: AppTypography.amount(theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

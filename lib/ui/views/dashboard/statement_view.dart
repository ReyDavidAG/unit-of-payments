import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_statement_model.dart';
import '../../../data/providers/dashboard/dashboard_provider.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/section_label_widget.dart';
import '../../widgets/dashboard/statement_card_widget.dart';

/// What has to be paid on each card's current statement. Renders nothing at all
/// until a card has a cutoff day — an empty state here would just be nagging
/// about a field most cards never need.
class StatementView extends ConsumerWidget {
  const StatementView({required this.today, super.key});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CardStatementModel> statements =
        (ref.watch(cardStatementsProvider).value ?? const [])
            .where((statement) => statement.hasCharges)
            .toList();
    if (statements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionLabelWidget('ESTE CORTE'),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < statements.length; i++) ...[
          AnimatedListItem(
            index: i,
            child: StatementCardWidget(statement: statements[i], today: today),
          ),
          const SizedBox(height: AppSpacing.listGap),
        ],
      ],
    );
  }
}

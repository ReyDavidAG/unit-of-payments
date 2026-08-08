import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_total_model.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../../data/providers/dashboard/dashboard_provider.dart';
import '../../../data/providers/subscriptions/subscriptions_provider.dart';
import '../../views/dashboard/debtors_view.dart';
import '../../views/dashboard/statement_view.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/profile_action_button.dart';
import '../../widgets/common/section_label_widget.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../../widgets/dashboard/card_total_widget.dart';
import '../../widgets/dashboard/dashboard_skeleton.dart';
import '../../widgets/dashboard/spend_split_widget.dart';
import '../../widgets/dashboard/upcoming_charge_widget.dart';

/// The one screen that answers "what am I paying, and on what".
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const String routeName = 'dashboard';
  static const String routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CardTotalModel>> totals = ref.watch(
      cardTotalsProvider,
    );
    final AsyncValue<List<SubscriptionModel>> upcoming = ref.watch(
      upcomingProvider,
    );
    final CardTotalModel? uncarded = ref.watch(uncardedTotalProvider);
    final DateTime today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: const [ThemeToggleButton(), ProfileActionButton()],
      ),
      body: totals.when(
        loading: () => const DashboardSkeleton(),
        error: (error, _) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(subscriptionsProvider)
              ..invalidate(cardTotalsProvider)
              ..invalidate(upcomingProvider);
            await ref.read(cardTotalsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [_Message(SupabaseService.describeError(error))],
          ),
        ),
        data: (_) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(subscriptionsProvider)
              ..invalidate(cardTotalsProvider)
              ..invalidate(upcomingProvider)
              ..invalidate(cardStatementsProvider)
              ..invalidate(debtorsProvider);
            await ref.read(cardTotalsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const AnimatedHero(child: _MonthlyTotal()),
              ..._breakdown(totals.value ?? const [], uncarded, today),
              StatementView(today: today),
              ..._upcoming(upcoming.value ?? const [], today),
              const DebtorsView(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _breakdown(
    List<CardTotalModel> totals,
    CardTotalModel? uncarded,
    DateTime today,
  ) {
    // A card with nothing charged to it is noise on this screen; it still
    // exists on the Tarjetas tab.
    final List<CardTotalModel> rows = [
      ...totals.where((total) => total.subscriptionCount > 0),
      ?uncarded,
    ];
    if (rows.isEmpty) {
      return const [
        _Message(
          'Cuando registres suscripciones, aquí ves cuánto pagas por cada '
          'tarjeta.',
        ),
      ];
    }
    return [
      SpendSplitWidget(totals: rows),
      if (rows.length >= 2) const SizedBox(height: AppSpacing.lg),
      const SectionLabelWidget('POR TARJETA'),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < rows.length; i++) ...[
        AnimatedListItem(
          index: i,
          child: CardTotalWidget(total: rows[i], today: today),
        ),
        const SizedBox(height: AppSpacing.listGap),
      ],
    ];
  }

  List<Widget> _upcoming(List<SubscriptionModel> items, DateTime today) {
    final List<SubscriptionModel> dated = items
        .where((item) => item.nextChargeDate != null)
        .toList();
    if (dated.isEmpty) {
      return const [];
    }
    final double sum = dated.fold(0, (total, item) => total + item.amount);
    return [
      const SizedBox(height: AppSpacing.sectionGap),
      const SectionLabelWidget('PRÓXIMOS 30 DÍAS'),
      const SizedBox(height: AppSpacing.sm),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            children: [
              for (var i = 0; i < dated.length; i++)
                AnimatedListItem(
                  index: i,
                  child: UpcomingChargeWidget(
                    subscription: dated[i],
                    today: today,
                  ),
                ),
              const Divider(height: AppSpacing.lg),
              _Total(sum),
            ],
          ),
        ),
      ),
    ];
  }
}

class _Total extends StatelessWidget {
  const _Total(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total', style: theme.textTheme.labelLarge),
        Text(
          MoneyHelper.amount(value),
          style: AppTypography.amount(theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _MonthlyTotal extends ConsumerWidget {
  const _MonthlyTotal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final double total = ref.watch(monthlyTotalProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AL MES', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs2),
          Text(
            MoneyHelper.amount(total),
            style: AppTypography.displayAmount(theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyLarge);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_total_model.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../../data/providers/dashboard/dashboard_provider.dart';
import '../../../data/providers/subscriptions/subscriptions_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/dashboard/card_total_widget.dart';
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
        actions: [
          IconButton(
            onPressed: SupabaseService.signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(subscriptionsProvider)
            ..invalidate(cardTotalsProvider)
            ..invalidate(upcomingProvider);
          await ref.read(cardTotalsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const _MonthlyTotal(),
            ...switch (totals) {
              AsyncError(:final error) => [
                _Message(SupabaseService.describeError(error)),
              ],
              AsyncLoading() => const [
                Center(child: CircularProgressIndicator()),
              ],
              _ => _breakdown(totals.value ?? const [], uncarded, today),
            },
            ..._upcoming(upcoming.value ?? const [], today),
          ],
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
      const _SectionLabel('POR TARJETA'),
      const SizedBox(height: AppSpacing.sm),
      for (final CardTotalModel total in rows) ...[
        CardTotalWidget(total: total, today: today),
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
      const _SectionLabel('PRÓXIMOS 30 DÍAS'),
      const SizedBox(height: AppSpacing.sm),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            children: [
              for (final SubscriptionModel item in dated)
                UpcomingChargeWidget(subscription: item, today: today),
              const Divider(height: AppSpacing.lg),
              _Total(sum),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Uppercase micro-label. Reads from labelSmall so the tracking stays in one
/// place rather than being retyped per section.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelSmall);
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

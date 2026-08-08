import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_total_model.dart';
import '../../../data/providers/dashboard/dashboard_provider.dart';
import '../../../data/providers/subscriptions/subscriptions_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/dashboard/card_total_widget.dart';

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
            ..invalidate(cardTotalsProvider);
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
              _ => _breakdown(
                totals.value ?? const [],
                uncarded,
                today,
                Theme.of(context).textTheme.labelSmall,
              ),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _breakdown(
    List<CardTotalModel> totals,
    CardTotalModel? uncarded,
    DateTime today,
    TextStyle? labelStyle,
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
      Text('POR TARJETA', style: labelStyle),
      const SizedBox(height: AppSpacing.sm),
      for (final CardTotalModel total in rows) ...[
        CardTotalWidget(total: total, today: today),
        const SizedBox(height: AppSpacing.listGap),
      ],
    ];
  }
}

class _MonthlyTotal extends ConsumerWidget {
  const _MonthlyTotal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final double total = ref.watch(monthlyTotalProvider);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.sectionGap,
      ),
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

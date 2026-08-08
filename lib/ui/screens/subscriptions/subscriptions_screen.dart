import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_model.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../../data/providers/cards/cards_provider.dart';
import '../../../data/providers/subscriptions/subscriptions_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../views/subscriptions/subscription_form_view.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/subscriptions/subscription_tile_widget.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  static const String routeName = 'subscriptions';
  static const String routePath = '/';

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<CardModel> cards = ref.read(cardsProvider).value ?? const [];
    final SubscriptionModel? item = await SubscriptionFormView.show(
      context,
      cards: cards,
    );
    if (item == null) {
      return;
    }
    await _run(
      messenger,
      () => ref.read(subscriptionsProvider.notifier).add(item),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel existing,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<CardModel> cards = ref.read(cardsProvider).value ?? const [];
    final SubscriptionModel? item = await SubscriptionFormView.show(
      context,
      cards: cards,
      initial: existing,
    );
    if (item == null) {
      return;
    }
    await _run(
      messenger,
      () => ref.read(subscriptionsProvider.notifier).edit(item),
    );
  }

  static Future<bool> _run(
    ScaffoldMessengerState messenger,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return true;
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(SupabaseService.describeError(error))),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SubscriptionModel>> subscriptions = ref.watch(
      subscriptionsProvider,
    );
    final DateTime today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripciones'),
        actions: [
          IconButton(
            onPressed: SupabaseService.signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      floatingActionButton: subscriptions.value?.isEmpty ?? true
          ? null
          : FloatingActionButton(
              onPressed: () => _create(context, ref),
              tooltip: 'Agregar suscripción',
              child: const Icon(Icons.add),
            ),
      body: subscriptions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyStateWidget(
          message: SupabaseService.describeError(error),
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(subscriptionsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyStateWidget(
                message:
                    'Todavía no registras suscripciones. Agrega la primera y '
                    'te aviso antes de cada cobro.',
                actionLabel: 'Agregar suscripción',
                onAction: () => _create(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.listGap),
                itemBuilder: (_, index) => index == 0
                    ? const _MonthlyTotal()
                    : SubscriptionTileWidget(
                        subscription: items[index - 1],
                        today: today,
                        onTap: () => _edit(context, ref, items[index - 1]),
                      ),
              ),
      ),
    );
  }
}

/// The one number the app exists to show.
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

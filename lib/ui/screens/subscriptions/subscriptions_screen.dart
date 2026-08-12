import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_model.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../../data/providers/cards/cards_provider.dart';
import '../../../data/providers/subscriptions/subscriptions_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../views/subscriptions/subscription_form_view.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/profile_action_button.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../../widgets/subscriptions/subscription_tile_skeleton.dart';
import '../../widgets/subscriptions/subscription_tile_widget.dart';
import '../charge_history/charge_history_screen.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  static const String routeName = 'subscriptions';
  static const String routePath = '/subscriptions';

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
      onStatus: (status) => _changeStatus(messenger, ref, existing, status),
    );
    if (item == null) {
      return;
    }
    await _run(
      messenger,
      () => ref.read(subscriptionsProvider.notifier).edit(item),
    );
  }

  /// Cancelling is confirmed inside the sheet and is not undoable from here.
  /// Pausing is one tap either way, so it offers the undo instead of a dialog.
  Future<void> _changeStatus(
    ScaffoldMessengerState messenger,
    WidgetRef ref,
    SubscriptionModel item,
    SubscriptionStatus status,
  ) async {
    final SubscriptionsNotifier notifier = ref.read(
      subscriptionsProvider.notifier,
    );
    final bool cancelling = status == SubscriptionStatus.cancelled;
    final bool ok = await _run(
      messenger,
      () =>
          cancelling ? notifier.cancel(item) : notifier.setStatus(item, status),
    );
    if (!ok) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (status) {
          SubscriptionStatus.paused => '${item.name} en pausa',
          SubscriptionStatus.active => '${item.name} reanudada',
          SubscriptionStatus.cancelled => '${item.name} cancelada',
        }),
        action: cancelling
            ? null
            : SnackBarAction(
                label: 'Deshacer',
                // Through _run: the snackbar outlives this screen, so an undo
                // that fails must surface rather than throw into the void.
                onPressed: () => _run(
                  messenger,
                  () => notifier.setStatus(item, item.status),
                ),
              ),
      ),
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
            tooltip: 'Historial de cobros',
            icon: const Icon(Icons.history),
            onPressed: () => context.pushNamed(ChargeHistoryScreen.routeName),
          ),
          const ThemeToggleButton(),
          const ProfileActionButton(),
        ],
      ),
      floatingActionButton: subscriptions.value?.isEmpty ?? true
          ? null
          : FloatingActionButton(
              // See CardsScreen: every tab stays mounted, so the default
              // shared hero tag collides.
              heroTag: null,
              onPressed: () => _create(context, ref),
              tooltip: 'Agregar suscripción',
              // The FAB borrows the active tab's hue (success) so the action
              // and the section read as one — the tab already trained the eye
              // to expect that colour on this screen.
              backgroundColor: Theme.of(context).success.withAlpha(200),
              foregroundColor: AppColors.paper,
              child: const Icon(Icons.note_add_outlined),
            ),
      body: subscriptions.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: 6,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.listGap),
          itemBuilder: (_, _) => const SubscriptionTileSkeleton(),
        ),
        error: (error, _) => ErrorRetryWidget(
          error: error,
          onRetry: () => ref.invalidate(subscriptionsProvider),
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
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.listGap),
                itemBuilder: (_, index) => AnimatedListItem(
                  index: index,
                  child: SubscriptionTileWidget(
                    subscription: items[index],
                    today: today,
                    onTap: () => _edit(context, ref, items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

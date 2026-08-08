import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_model.dart';
import '../../../data/providers/cards/cards_provider.dart';
import '../../../data/providers/subscriptions/subscriptions_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../views/cards/card_form_view.dart';
import '../../widgets/cards/card_tile_skeleton.dart';
import '../../widgets/cards/card_tile_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/profile_action_button.dart';
import '../../widgets/common/theme_toggle_button.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  static const String routeName = 'cards';
  static const String routePath = '/cards';

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    // Captured before the await: the sheet closing is an async gap and the
    // context may be gone by the time the write finishes.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CardModel? card = await CardFormView.show(context);
    if (card == null) {
      return;
    }
    await _run(messenger, () => ref.read(cardsProvider.notifier).add(card));
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    CardModel existing,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CardModel? card = await CardFormView.show(context, initial: existing);
    if (card == null) {
      return;
    }
    await _run(messenger, () => ref.read(cardsProvider.notifier).edit(card));
  }

  /// Archiving is reversible, but it is not local: every charge on this card
  /// keeps pointing at it and starts flying a warning. That consequence is
  /// invisible from here, so it gets said out loud before it happens.
  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    CardModel card,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CardsNotifier notifier = ref.read(cardsProvider.notifier);
    // Null-safe on purpose: an unloaded list must soften the message, never
    // take the dialog down with it.
    final int charges = (ref.read(subscriptionsProvider).value ?? const [])
        .where((item) => item.cardId == card.id)
        .length;
    final bool confirmed = await showConfirmDialog(
      context,
      title: '¿Archivar ${card.alias}?',
      message: charges == 0
          ? 'Sale de tus listas y de los totales. La puedes recuperar cuando '
                'quieras.'
          : 'Sale de tus listas y de los totales. '
                '${charges == 1 ? 'Hay 1 cargo' : 'Hay $charges cargos'} '
                'en esta tarjeta: se quedan, marcados con una advertencia '
                'hasta que les asignes otra.',
      confirmLabel: 'Archivar',
    );
    if (!confirmed) {
      return;
    }
    final bool ok = await _run(messenger, () => notifier.archive(card));
    if (!ok) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('${card.alias} archivada'),
        action: SnackBarAction(
          label: 'Deshacer',
          // Through _run, not fire-and-forget: undo can fail like any other
          // write, and the snackbar outlives this screen.
          onPressed: () => _run(messenger, () => notifier.restore(card)),
        ),
      ),
    );
  }

  /// Surfaces the failure instead of leaving the screen silently unchanged.
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
    final AsyncValue<List<CardModel>> cards = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjetas'),
        actions: const [ThemeToggleButton(), ProfileActionButton()],
      ),
      floatingActionButton: cards.value?.isEmpty ?? true
          ? null
          : FloatingActionButton(
              // The shell keeps every tab mounted, so two FABs share the tree.
              // A null tag opts out of the hero entirely: they never fly
              // between routes, and a shared default tag crashes the
              // transition.
              heroTag: null,
              onPressed: () => _create(context, ref),
              tooltip: 'Agregar tarjeta',
              // Same trick as Suscripciones: lift the active tab's hue
              // (tabPurple) so the action reads as belonging to this section.
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.tabPurpleDark
                  : AppColors.tabPurple,
              foregroundColor: AppColors.paper,
              child: const Icon(Icons.add_card_outlined),
            ),
      body: cards.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: 5,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.listGap),
          itemBuilder: (_, _) => const CardTileSkeleton(),
        ),
        error: (error, _) => ErrorRetryWidget(
          error: error,
          onRetry: () => ref.invalidate(cardsProvider),
        ),
        data: (items) => items.isEmpty
            ? EmptyStateWidget(
                message:
                    'Todavía no tienes tarjetas. Agrega una para agrupar tus '
                    'suscripciones por dónde se cobran.',
                actionLabel: 'Agregar tarjeta',
                onAction: () => _create(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.listGap),
                itemBuilder: (_, index) => AnimatedListItem(
                  index: index,
                  child: CardTileWidget(
                    card: items[index],
                    onTap: () => _edit(context, ref, items[index]),
                    onArchive: () => _archive(context, ref, items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

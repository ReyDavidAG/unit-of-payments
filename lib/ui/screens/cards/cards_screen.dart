import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_model.dart';
import '../../../data/providers/cards/cards_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../views/cards/card_form_view.dart';
import '../../widgets/cards/card_tile_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

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

  /// Archive is reversible, so it confirms with an undo rather than a dialog.
  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    CardModel card,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CardsNotifier notifier = ref.read(cardsProvider.notifier);
    final bool ok = await _run(messenger, () => notifier.archive(card));
    if (!ok) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('${card.alias} archivada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => notifier.restore(card),
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
      appBar: AppBar(title: const Text('Tarjetas')),
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
              child: const Icon(Icons.add),
            ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyStateWidget(
          message: SupabaseService.describeError(error),
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(cardsProvider),
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
                itemBuilder: (_, index) => CardTileWidget(
                  card: items[index],
                  onTap: () => _edit(context, ref, items[index]),
                  onArchive: () => _archive(context, ref, items[index]),
                ),
              ),
      ),
    );
  }
}

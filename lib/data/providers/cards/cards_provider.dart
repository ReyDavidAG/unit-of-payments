import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cards/card_model.dart';
import '../../services/cards/card_service.dart';
import '../auth/auth_provider.dart';
import '../subscriptions/subscriptions_provider.dart';

final AsyncNotifierProvider<CardsNotifier, List<CardModel>> cardsProvider =
    AsyncNotifierProvider<CardsNotifier, List<CardModel>>(CardsNotifier.new);

class CardsNotifier extends AsyncNotifier<List<CardModel>> {
  @override
  Future<List<CardModel>> build() async {
    // Re-fetches on sign-out and on sign-in, so one account never shows
    // another's cards from a stale cache.
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return CardService.fetchActive();
  }

  Future<void> add(CardModel card) async {
    final CardModel created = await CardService.create(card);
    state = AsyncData([...?state.value, created]..sort(_byAlias));
  }

  Future<void> edit(CardModel card) async {
    final CardModel updated = await CardService.update(card);
    state = AsyncData(
      [
        for (final CardModel item in state.value ?? const <CardModel>[])
          if (item.id == updated.id) updated else item,
      ]..sort(_byAlias),
    );
  }

  /// Removes from the list first so the row disappears immediately. If the
  /// write fails the list is restored and the caller sees the error.
  Future<void> archive(CardModel card) async {
    final List<CardModel> previous = state.value ?? const [];
    state = AsyncData([
      for (final CardModel item in previous)
        if (item.id != card.id) item,
    ]);
    try {
      await CardService.setArchived(card.id, archived: true);
      _refreshCharges();
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> restore(CardModel card) async {
    await CardService.setArchived(card.id, archived: false);
    state = AsyncData([...?state.value, card]..sort(_byAlias));
    _refreshCharges();
  }

  /// `card_archived` is computed by the view, so every charge has to be re-read
  /// for its warning to appear — and to disappear again on undo.
  ///
  /// It lives here and not in the screen because it is a consequence of the
  /// write, not of the tap. A `WidgetRef` captured in an undo callback is dead
  /// the moment its widget is: this `ref` belongs to the provider and outlives
  /// any screen that triggered it.
  void _refreshCharges() => ref.invalidate(subscriptionsProvider);

  static int _byAlias(CardModel a, CardModel b) =>
      a.alias.toLowerCase().compareTo(b.alias.toLowerCase());
}

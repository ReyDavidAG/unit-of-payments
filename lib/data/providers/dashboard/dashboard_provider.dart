import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cards/card_model.dart';
import '../../models/cards/card_total_model.dart';
import '../../models/subscriptions/subscription_model.dart';
import '../../services/cards/card_service.dart';
import '../../services/subscriptions/subscription_service.dart';
import '../auth/auth_provider.dart';
import '../cards/cards_provider.dart';
import '../subscriptions/subscriptions_provider.dart';

/// Totals per card, straight from `v_card_totals`. Watches the two writable
/// providers so any edit upstream re-reads the view instead of leaving a stale
/// number on screen.
final FutureProvider<List<CardTotalModel>> cardTotalsProvider =
    FutureProvider<List<CardTotalModel>>((ref) async {
      ref.watch(subscriptionsProvider);
      ref.watch(cardsProvider);
      if (ref.watch(currentUserIdProvider) == null) {
        return const [];
      }
      return CardService.fetchTotals();
    });

/// `v_card_totals` starts from cards, so a subscription with no card never
/// appears in it. This is that leftover, summed on the client because there is
/// no card row to hang it off.
final Provider<CardTotalModel?> uncardedTotalProvider =
    Provider<CardTotalModel?>((ref) {
      final List<SubscriptionModel> orphans =
          (ref.watch(subscriptionsProvider).value ?? const [])
              .where((item) => item.cardId == null)
              .toList();
      if (orphans.isEmpty) {
        return null;
      }
      return CardTotalModel(
        alias: 'Sin tarjeta',
        color: '',
        brand: CardBrand.other,
        subscriptionCount: orphans.length,
        monthlyTotal: orphans.fold(
          0,
          (sum, item) => sum + (item.monthlyAmount ?? 0),
        ),
        nextChargeDate: orphans
            .map((item) => item.nextChargeDate)
            .nonNulls
            .fold<DateTime?>(
              null,
              (earliest, date) =>
                  earliest == null || date.isBefore(earliest) ? date : earliest,
            ),
      );
    });

/// Charges due in the next 30 days. `v_upcoming` already filters and orders
/// them, so this is a read, not a client-side scan of every subscription.
final FutureProvider<List<SubscriptionModel>> upcomingProvider =
    FutureProvider<List<SubscriptionModel>>((ref) async {
      ref.watch(subscriptionsProvider);
      if (ref.watch(currentUserIdProvider) == null) {
        return const [];
      }
      return SubscriptionService.fetchUpcoming();
    });

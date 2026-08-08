import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/subscriptions/subscription_model.dart';
import '../../services/subscriptions/subscription_service.dart';
import '../auth/auth_provider.dart';

final AsyncNotifierProvider<SubscriptionsNotifier, List<SubscriptionModel>>
subscriptionsProvider =
    AsyncNotifierProvider<SubscriptionsNotifier, List<SubscriptionModel>>(
      SubscriptionsNotifier.new,
    );

class SubscriptionsNotifier extends AsyncNotifier<List<SubscriptionModel>> {
  @override
  Future<List<SubscriptionModel>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return SubscriptionService.fetchActive();
  }

  Future<void> add(SubscriptionModel item) async {
    final SubscriptionModel created = await SubscriptionService.create(item);
    state = AsyncData([...?state.value, created]..sort(_byNextCharge));
  }

  Future<void> edit(SubscriptionModel item) async {
    final SubscriptionModel updated = await SubscriptionService.update(item);
    state = AsyncData(
      [
        for (final SubscriptionModel current
            in state.value ?? const <SubscriptionModel>[])
          if (current.id == updated.id) updated else current,
      ]..sort(_byNextCharge),
    );
  }

  Future<void> deactivate(SubscriptionModel item) async {
    final List<SubscriptionModel> previous = state.value ?? const [];
    state = AsyncData([
      for (final SubscriptionModel current in previous)
        if (current.id != item.id) current,
    ]);
    try {
      await SubscriptionService.setActive(item.id, active: false);
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> restore(SubscriptionModel item) async {
    await SubscriptionService.setActive(item.id, active: true);
    state = AsyncData([...?state.value, item]..sort(_byNextCharge));
  }

  /// Nulls last: a subscription without a computed next charge is one whose
  /// cycle the database could not resolve, and it belongs at the bottom.
  static int _byNextCharge(SubscriptionModel a, SubscriptionModel b) {
    if (a.nextChargeDate == null) {
      return b.nextChargeDate == null ? 0 : 1;
    }
    if (b.nextChargeDate == null) {
      return -1;
    }
    return a.nextChargeDate!.compareTo(b.nextChargeDate!);
  }
}

/// What the user pays per month, everything normalized by the database.
final Provider<double> monthlyTotalProvider = Provider<double>((ref) {
  final List<SubscriptionModel> items =
      ref.watch(subscriptionsProvider).value ?? const [];
  return items.fold(0, (sum, item) => sum + (item.monthlyAmount ?? 0));
});

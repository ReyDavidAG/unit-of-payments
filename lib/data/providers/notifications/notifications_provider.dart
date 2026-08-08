import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notifications/notification_log_model.dart';
import '../../models/subscriptions/subscription_model.dart';
import '../../services/notifications/local_notification_service.dart';
import '../../services/notifications/notification_log_service.dart';
import '../../services/notifications/notification_scheduler.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../profile/profile_provider.dart';

/// Reschedules whenever the upcoming set changes. Watching the provider rather
/// than calling the scheduler from each edit means no write path can forget to.
final FutureProvider<int> notificationSyncProvider = FutureProvider<int>((
  ref,
) async {
  if (ref.watch(currentUserIdProvider) == null) {
    await LocalNotificationService.cancelAll();
    return 0;
  }
  // Awaited before scheduling, not merely watched: the profile is what sets
  // the timezone, and a reminder scheduled against the wrong one fires at the
  // wrong hour.
  await ref.watch(profileProvider.future);
  final List<SubscriptionModel> upcoming = await ref.watch(
    upcomingProvider.future,
  );
  return NotificationScheduler.sync(upcoming);
});

final AsyncNotifierProvider<NotificationLogNotifier, List<NotificationLogModel>>
notificationLogProvider =
    AsyncNotifierProvider<NotificationLogNotifier, List<NotificationLogModel>>(
      NotificationLogNotifier.new,
    );

class NotificationLogNotifier
    extends AsyncNotifier<List<NotificationLogModel>> {
  @override
  Future<List<NotificationLogModel>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    // Depends on the sync so the history reflects what was just scheduled, but
    // does not depend on it succeeding: scheduling is a side effect, reading
    // the log is the job of this screen. The watch stays outside the try so
    // the dependency is still registered when it throws.
    final Future<int> sync = ref.watch(notificationSyncProvider.future);
    try {
      await sync;
    } on Object catch (error) {
      debugPrint('notification sync failed, showing history anyway: $error');
    }
    final List<NotificationLogModel> entries =
        await NotificationLogService.fetchRecent();
    return _settleDelivered(entries);
  }

  /// A local notification fires with the app closed, so nothing can report
  /// delivery at the time. Anything whose moment has passed is marked on the
  /// next launch instead.
  Future<List<NotificationLogModel>> _settleDelivered(
    List<NotificationLogModel> entries,
  ) async {
    final List<String> due = [
      for (final NotificationLogModel entry in entries)
        if (entry.isDue && entry.id != null) entry.id!,
    ];
    if (due.isEmpty) {
      return entries;
    }
    // Cosmetic bookkeeping. If it fails the entries are still correct, just
    // one launch behind on their delivered flag.
    try {
      await NotificationLogService.markDelivered(due);
    } on Object catch (error) {
      debugPrint('could not mark notices delivered: $error');
      return entries;
    }
    return NotificationLogService.fetchRecent();
  }
}

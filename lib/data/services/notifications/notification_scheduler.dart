import 'package:flutter/foundation.dart';

import '../../../core/helpers/money_helper.dart';
import '../../models/notifications/notification_log_model.dart';
import '../../models/subscriptions/subscription_model.dart';
import 'local_notification_service.dart';
import 'notification_log_service.dart';

/// Rebuilds the whole pending set from `v_upcoming` on every run.
///
/// Cancel-all then reschedule is cheaper and far less bug-prone than diffing
/// what is already pending against what should be — and the database's unique
/// constraint means the log does not double up either.
class NotificationScheduler {
  const NotificationScheduler._();

  static Future<int> sync(List<SubscriptionModel> upcoming) async {
    // Nothing is written when the platform side is unavailable: a history row
    // saying "programado" for a reminder that can never fire is a lie.
    if (!await LocalNotificationService.initialize()) {
      return 0;
    }

    final DateTime now = DateTime.now();
    final List<PlannedReminder> planned = plan(upcoming, now);

    await LocalNotificationService.cancelAll();
    for (final PlannedReminder item in planned) {
      await LocalNotificationService.schedule(
        id: item.id,
        title: item.title,
        body: item.body,
        when: item.fireAt,
      );
    }

    await NotificationLogService.record([
      for (final PlannedReminder item in planned)
        NotificationLogModel(
          subscriptionId: item.subscriptionId,
          chargeDate: item.chargeDate,
          scheduledFor: item.fireAt,
          amount: item.amount,
          title: item.title,
        ),
    ]);
    return planned.length;
  }

  /// Which reminders should exist right now. Pure, so the window, the trim
  /// and the skip-the-past rule are testable without a device.
  @visibleForTesting
  static List<PlannedReminder> plan(
    List<SubscriptionModel> upcoming,
    DateTime now,
  ) {
    final List<PlannedReminder> planned = [];
    for (final SubscriptionModel item in upcoming) {
      final DateTime? charge = item.nextChargeDate;
      if (charge == null) {
        continue;
      }
      final DateTime fireAt = DateTime(
        charge.year,
        charge.month,
        charge.day,
        LocalNotificationService.hourOfDay,
      ).subtract(Duration(days: item.reminderDaysBefore));

      // A reminder whose moment already passed cannot be scheduled. It still
      // gets logged below, so the history shows the charge came and went.
      if (!fireAt.isAfter(now)) {
        continue;
      }
      planned.add(
        PlannedReminder(
          id: _idFor(item.id, charge),
          subscriptionId: item.id,
          chargeDate: charge,
          fireAt: fireAt,
          amount: item.amount,
          title: item.name,
          body: _body(item),
        ),
      );
    }

    // iOS drops everything past 64 pending notifications, so the nearest ones
    // win. The next launch picks up whatever got trimmed.
    planned.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return planned.take(LocalNotificationService.maxPending).toList();
  }

  static String _body(SubscriptionModel item) {
    final String amount = MoneyHelper.amount(item.amount);
    return item.cardAlias == null
        ? 'Se cobra $amount'
        : 'Se cobra $amount a ${item.cardAlias}';
  }

  /// Android and iOS want a 32-bit int, and the ids here are uuids. Hashing
  /// the pair keeps it stable across launches so a reschedule replaces rather
  /// than duplicates.
  static int _idFor(String subscriptionId, DateTime chargeDate) =>
      Object.hash(subscriptionId, chargeDate.toIso8601String()) & 0x7FFFFFFF;
}

@visibleForTesting
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.subscriptionId,
    required this.chargeDate,
    required this.fireAt,
    required this.amount,
    required this.title,
    required this.body,
  });

  final int id;
  final String subscriptionId;
  final DateTime chargeDate;
  final DateTime fireAt;
  final double amount;
  final String title;
  final String body;
}

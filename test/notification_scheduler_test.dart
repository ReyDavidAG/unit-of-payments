import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unit_of_payments/data/models/notifications/notification_log_model.dart';
import 'package:unit_of_payments/data/models/subscriptions/subscription_model.dart';
import 'package:unit_of_payments/data/services/notifications/local_notification_service.dart';
import 'package:unit_of_payments/data/services/notifications/notification_scheduler.dart';

SubscriptionModel _sub({
  required String id,
  required DateTime next,
  int reminder = 1,
}) => SubscriptionModel(
  id: id,
  name: 'Netflix $id',
  amount: 219,
  cycle: BillingCycle.monthly,
  firstChargeDate: DateTime(2026, 1, 15),
  reminderDaysBefore: reminder,
  nextChargeDate: next,
);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  final DateTime now = DateTime(2026, 9, 1, 12);

  test('the reminder lands reminderDaysBefore the charge, mid-morning', () {
    final List<PlannedReminder> planned = NotificationScheduler.plan([
      _sub(id: 'a', next: DateTime(2026, 9, 12), reminder: 3),
    ], now);

    expect(planned.single.fireAt, DateTime(2026, 9, 9, 9));
  });

  test('a reminder whose moment already passed is not scheduled', () {
    // Charge tomorrow with a 3-day warning: the moment to warn is behind us.
    // Scheduling it would fire the notification instantly.
    final List<PlannedReminder> planned = NotificationScheduler.plan([
      _sub(id: 'a', next: DateTime(2026, 9, 2), reminder: 3),
    ], now);

    expect(planned, isEmpty);
  });

  test('same-day reminders are still scheduled if 09:00 has not passed', () {
    final List<PlannedReminder> planned = NotificationScheduler.plan([
      _sub(id: 'a', next: DateTime(2026, 9, 3), reminder: 0),
    ], DateTime(2026, 9, 3, 6));

    expect(planned.single.fireAt, DateTime(2026, 9, 3, 9));
  });

  test('the nearest reminders win when iOS runs out of slots', () {
    // iOS drops everything past 64 pending, so the trim has to keep the
    // soonest ones. The next launch picks up whatever was cut.
    final List<PlannedReminder> planned = NotificationScheduler.plan([
      for (int day = 1; day <= 80; day++)
        _sub(
          id: 'sub-$day',
          next: DateTime(2026, 9, 2).add(Duration(days: day)),
        ),
    ], now);

    expect(planned.length, LocalNotificationService.maxPending);
    expect(planned.first.fireAt.isBefore(planned.last.fireAt), isTrue);
    expect(planned.first.chargeDate, DateTime(2026, 9, 3));
  });

  test('the notification id is stable across runs', () {
    // An unstable id would duplicate the notification on every reschedule
    // instead of replacing it.
    final List<SubscriptionModel> input = [
      _sub(id: 'a', next: DateTime(2026, 9, 12)),
    ];
    expect(
      NotificationScheduler.plan(input, now).single.id,
      NotificationScheduler.plan(input, now).single.id,
    );
    expect(NotificationScheduler.plan(input, now).single.id, greaterThan(0));
  });

  test('a subscription with no computed charge date is skipped', () {
    final List<PlannedReminder> planned = NotificationScheduler.plan([
      SubscriptionModel(
        id: 'a',
        name: 'x',
        amount: 1,
        cycle: BillingCycle.custom,
        firstChargeDate: DateTime(2026),
      ),
    ], now);

    expect(planned, isEmpty);
  });

  group('log', () {
    test('the same charge always writes the same conflict key', () {
      final NotificationLogModel entry = NotificationLogModel(
        subscriptionId: 'sub-1',
        chargeDate: DateTime(2026, 9, 12),
        scheduledFor: DateTime(2026, 9, 11, 9),
        amount: 219,
        title: 'Netflix',
      );
      // notif_once is (subscription_id, charge_date); a timestamp here would
      // never collide and the history would grow a row per launch.
      expect(entry.toInsert()['charge_date'], '2026-09-12');
    });

    test('delivery is inferred on the next launch, not at fire time', () {
      final NotificationLogModel past = NotificationLogModel(
        subscriptionId: 'sub-1',
        chargeDate: DateTime(2020),
        scheduledFor: DateTime(2020),
        amount: 1,
        title: 'x',
      );
      expect(past.isDue, isTrue);

      final NotificationLogModel marked = NotificationLogModel(
        subscriptionId: 'sub-1',
        chargeDate: DateTime(2020),
        scheduledFor: DateTime(2020),
        amount: 1,
        title: 'x',
        deliveredAt: DateTime(2020, 1, 2),
      );
      expect(marked.isDue, isFalse);
    });

    test('numeric comes back from the log as a string too', () {
      final NotificationLogModel entry = NotificationLogModel.fromJson({
        'id': 'uuid',
        'subscription_id': 'sub-1',
        'charge_date': '2026-09-12',
        'scheduled_for': '2026-09-11T15:00:00Z',
        'amount': '219.00',
        'title': 'Netflix',
        'delivered_at': null,
        'opened_at': null,
      });
      expect(entry.amount, 219.0);
      expect(entry.deliveredAt, isNull);
    });
  });
}

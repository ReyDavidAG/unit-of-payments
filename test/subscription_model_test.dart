import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unit_of_payments/core/helpers/money_helper.dart';
import 'package:unit_of_payments/data/models/subscriptions/subscription_model.dart';

SubscriptionModel _build({
  required BillingCycle cycle,
  int? customDays,
  DateTime? nextCharge,
}) => SubscriptionModel(
  id: 'id',
  name: 'Netflix',
  amount: 219,
  cycle: cycle,
  customDays: customDays,
  firstChargeDate: DateTime(2026, 1, 31),
  nextChargeDate: nextCharge,
);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  test('numeric arrives from Postgres as a string, not a double', () {
    // PostgREST serializes numeric as a string so precision is not lost in
    // JSON. Reading it as num would make every amount zero.
    final SubscriptionModel item = SubscriptionModel.fromJson({
      'id': 'id',
      'name': 'Spotify',
      'amount': '129.00',
      'cycle': 'monthly',
      'first_charge_date': '2026-03-15',
      'monthly_amount': '129.00',
      'next_charge_date': '2026-08-15',
    });
    expect(item.amount, 129.0);
    expect(item.monthlyAmount, 129.0);
    expect(item.nextChargeDate, DateTime(2026, 8, 15));
  });

  test('custom_days is only sent for the custom cycle', () {
    // subs_custom_days rejects the row otherwise, so leaving a stale value
    // behind after switching cycles would fail the write.
    expect(
      _build(
        cycle: BillingCycle.monthly,
        customDays: 45,
      ).toWrite()['custom_days'],
      isNull,
    );
    expect(
      _build(
        cycle: BillingCycle.custom,
        customDays: 45,
      ).toWrite()['custom_days'],
      45,
    );
  });

  test('dates are written as plain dates, never as timestamps', () {
    expect(
      _build(cycle: BillingCycle.monthly).toWrite()['first_charge_date'],
      '2026-01-31',
    );
  });

  test('daysUntilCharge ignores the time of day', () {
    final SubscriptionModel item = _build(
      cycle: BillingCycle.monthly,
      nextCharge: DateTime(2026, 8, 10),
    );
    // A charge later today is 0 days away, not -1 because it is 23:59 now.
    expect(item.daysUntilCharge(DateTime(2026, 8, 10, 23, 59)), 0);
    expect(item.daysUntilCharge(DateTime(2026, 8, 7, 6)), 3);
    expect(item.daysUntilCharge(DateTime(2026, 8, 12)), -2);
  });

  test('charge labels go relative when close and absolute when not', () {
    final DateTime date = DateTime(2026, 9, 12);
    expect(MoneyHelper.chargeLabel(date, 0), 'Hoy');
    expect(MoneyHelper.chargeLabel(date, 1), 'Mañana');
    expect(MoneyHelper.chargeLabel(date, 3), 'En 3 días');
    // Past 14 days a countdown reads worse than the date itself.
    expect(MoneyHelper.chargeLabel(date, 94), MoneyHelper.shortDate(date));
    expect(MoneyHelper.chargeLabel(date, -2), startsWith('Venció'));
  });
}

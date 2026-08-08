import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/data/models/cards/card_total_model.dart';

void main() {
  test('the view returns numeric as a string and counts as an int', () {
    final CardTotalModel total = CardTotalModel.fromJson({
      'card_id': 'uuid',
      'alias': 'BBVA Oro',
      'color': '#494ECF',
      'subscription_count': 3,
      'monthly_total': '648.75',
      'next_charge_date': '2026-08-15',
    });
    expect(total.monthlyTotal, 648.75);
    expect(total.subscriptionCount, 3);
    expect(total.nextChargeDate, DateTime(2026, 8, 15));
  });

  test('a card with nothing charged to it reads as zero, not as null', () {
    // The view left-joins, so an unused card still returns a row with
    // coalesce(sum, 0) and a null next charge.
    final CardTotalModel total = CardTotalModel.fromJson({
      'card_id': 'uuid',
      'alias': 'Nómina',
      'color': '#0CA3BE',
      'subscription_count': 0,
      'monthly_total': 0,
      'next_charge_date': null,
    });
    expect(total.monthlyTotal, 0);
    expect(total.nextChargeDate, isNull);
  });
}

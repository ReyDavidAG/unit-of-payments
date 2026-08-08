import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/data/models/cards/card_model.dart';

void main() {
  test('every swatch survives the storage round trip', () {
    // The picker writes hexOf(...) and the tile reads swatchFromHex(...).
    // If those two ever disagree, every card silently turns blue.
    for (final Color swatch in AppColors.cardSwatches.values) {
      expect(AppColors.swatchFromHex(AppColors.hexOf(swatch)), swatch);
    }
  });

  test('an unknown brand falls back instead of throwing', () {
    expect(CardBrand.fromValue('visa'), CardBrand.visa);
    // A value added to the Postgres enum later must not crash an older build.
    expect(CardBrand.fromValue('discover'), CardBrand.other);
    expect(CardBrand.fromValue(null), CardBrand.other);
  });

  test('toInsert never sends id or user_id', () {
    const CardModel card = CardModel(
      id: 'some-uuid',
      alias: 'BBVA Oro',
      brand: CardBrand.visa,
      color: '#4B84E2',
      last4: '1234',
      cutoffDay: 15,
    );
    final Map<String, dynamic> row = card.toInsert();

    // user_id comes from auth.uid() and is what the RLS policies check;
    // sending it from the client is exactly what they refuse.
    expect(row.containsKey('user_id'), isFalse);
    expect(row.containsKey('id'), isFalse);
    expect(row['brand'], 'visa');
    expect(row['cutoff_day'], 15);
  });

  test('fromJson reads the row the database actually returns', () {
    final CardModel card = CardModel.fromJson({
      'id': 'uuid',
      'alias': 'Santander',
      'brand': 'amex',
      'color': '#0F9B89',
      'last4': null,
      'cutoff_day': null,
      'archived': false,
    });
    expect(card.alias, 'Santander');
    expect(card.brand, CardBrand.amex);
    expect(card.last4, isNull);
  });
}

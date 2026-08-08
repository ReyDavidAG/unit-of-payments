import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/core/helpers/card_brand_helper.dart';
import 'package:unit_of_payments/data/models/cards/card_model.dart';

void main() {
  group('CardBrandHelper.detect', () {
    test('reads the network written in the alias', () {
      expect(CardBrandHelper.detect('BBVA Visa'), CardBrand.visa);
      expect(
        CardBrandHelper.detect('Santander Mastercard'),
        CardBrand.mastercard,
      );
      expect(CardBrandHelper.detect('Amex Platinum'), CardBrand.amex);
      expect(CardBrandHelper.detect('American Express Gold'), CardBrand.amex);
    });

    test('recognises single-network products', () {
      expect(CardBrandHelper.detect('Nu'), CardBrand.mastercard);
      expect(CardBrandHelper.detect('Klar'), CardBrand.mastercard);
      expect(CardBrandHelper.detect('Stori'), CardBrand.mastercard);
      expect(CardBrandHelper.detect('RappiCard'), CardBrand.visa);
      expect(CardBrandHelper.detect('Hey Banco'), CardBrand.visa);
      expect(CardBrandHelper.detect('Costco Citibanamex'), CardBrand.visa);
    });

    test('suggests Visa for BBVA, whose consumer lineup runs on it', () {
      expect(CardBrandHelper.detect('BBVA'), CardBrand.visa);
      expect(CardBrandHelper.detect('BBVA Oro'), CardBrand.visa);
      expect(CardBrandHelper.detect('Bancomer'), CardBrand.visa);
    });

    test('reads Mercado Pago as its credit product, which is Visa', () {
      expect(CardBrandHelper.detect('Mercado Pago'), CardBrand.visa);
      expect(CardBrandHelper.detect('MercadoPago'), CardBrand.visa);
    });

    test('stays quiet on issuers with a genuinely split lineup', () {
      for (final String alias in [
        'Banorte',
        'Santander Free',
        'HSBC 2Now',
        'Citibanamex',
        'Scotiabank',
        'Vexi',
      ]) {
        expect(CardBrandHelper.detect(alias), isNull, reason: alias);
      }
    });

    test('Platinum alone is not Amex — plenty of banks name a card that', () {
      expect(CardBrandHelper.detect('Platinum'), isNull);
      expect(CardBrandHelper.detect('Santander Platinum'), isNull);
    });

    test('matches whole words only', () {
      expect(CardBrandHelper.detect('Nuevo'), isNull);
      expect(CardBrandHelper.detect('Numerario'), isNull);
      expect(CardBrandHelper.detect('McDonalds'), isNull);
    });

    test('a written network outranks the issuer it sits next to', () {
      expect(CardBrandHelper.detect('BBVA (MC)'), CardBrand.mastercard);
      expect(CardBrandHelper.detect('BBVA Mastercard'), CardBrand.mastercard);
      expect(CardBrandHelper.detect('Nu Visa'), CardBrand.visa);
    });

    test('ignores case, padding and punctuation', () {
      expect(CardBrandHelper.detect('  AMEX  '), CardBrand.amex);
      expect(CardBrandHelper.detect('master-card'), CardBrand.mastercard);
      expect(CardBrandHelper.detect('bbva/oro'), CardBrand.visa);
    });

    test('the longest matching name wins', () {
      expect(CardBrandHelper.detect('Visa American Express'), CardBrand.amex);
    });

    test('an empty alias has no opinion', () {
      expect(CardBrandHelper.detect(''), isNull);
      expect(CardBrandHelper.detect('   '), isNull);
      expect(CardBrandHelper.detect('---'), isNull);
    });
  });
}

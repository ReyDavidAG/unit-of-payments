import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unit_of_payments/core/helpers/money_helper.dart';
import 'package:unit_of_payments/data/models/profile/profile_model.dart';
import 'package:unit_of_payments/data/services/notifications/local_notification_service.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));
  tearDown(() => MoneyHelper.configure(SupportedCurrency.mxn));

  test('a missing profile column falls back rather than throwing', () {
    // An account created before the signup trigger existed has no row, and a
    // row written by an older build may not carry every column.
    final ProfileModel profile = ProfileModel.fromJson({'id': 'uuid'});
    expect(profile.currency, 'MXN');
    expect(profile.timezone, ProfileModel.defaultTimezone);
  });

  test('an unknown currency code falls back to the default', () {
    expect(SupportedCurrency.fromCode('USD'), SupportedCurrency.usd);
    expect(SupportedCurrency.fromCode('JPY'), SupportedCurrency.mxn);
    expect(SupportedCurrency.fromCode(null), SupportedCurrency.mxn);
  });

  test('the currency changes the symbol everywhere at once', () {
    MoneyHelper.configure(SupportedCurrency.mxn);
    expect(MoneyHelper.amount(219), contains(r'$'));

    MoneyHelper.configure(SupportedCurrency.eur);
    expect(MoneyHelper.amount(219), contains('€'));
    expect(MoneyHelper.currency, SupportedCurrency.eur);
  });

  test('an unknown timezone falls back instead of crashing the scheduler', () {
    LocalNotificationService.configureTimezone('America/Cancun');
    expect(LocalNotificationService.timezone, 'America/Cancun');

    // A zone name that the tz database does not know must not take down
    // scheduling: reminders would stop for every subscription.
    LocalNotificationService.configureTimezone('Mars/Olympus_Mons');
    expect(LocalNotificationService.timezone, ProfileModel.defaultTimezone);
  });

  test('toUpdate never sends the id back', () {
    const ProfileModel profile = ProfileModel(
      id: 'uuid',
      currency: 'USD',
      timezone: 'America/Tijuana',
      displayName: 'David',
    );
    // id is the primary key and the RLS predicate; it is matched on, not set.
    expect(profile.toUpdate().containsKey('id'), isFalse);
    expect(profile.toUpdate()['timezone'], 'America/Tijuana');
  });
}

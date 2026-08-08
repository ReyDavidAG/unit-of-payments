import 'package:intl/intl.dart';

import '../../data/models/profile/profile_model.dart';

/// Money and date formatting. One place, so the app cannot drift into three
/// different ways of writing the same amount.
///
/// The currency is set once from the profile, the same way `Intl.defaultLocale`
/// is. Threading it through every widget that prints a number would be a lot of
/// plumbing for a value that changes about once in an account's life.
class MoneyHelper {
  const MoneyHelper._();

  static SupportedCurrency _currency = SupportedCurrency.mxn;
  static NumberFormat _format = _formatFor(SupportedCurrency.mxn);

  static SupportedCurrency get currency => _currency;

  static void configure(SupportedCurrency currency) {
    if (currency == _currency) {
      return;
    }
    _currency = currency;
    _format = _formatFor(currency);
  }

  static NumberFormat _formatFor(SupportedCurrency currency) =>
      NumberFormat.currency(
        locale: 'es_MX',
        symbol: currency.symbol,
        decimalDigits: 2,
      );

  static String amount(double value) => _format.format(value);

  static final DateFormat _shortDate = DateFormat('d MMM', 'es_MX');
  static final DateFormat _longDate = DateFormat('d MMMM y', 'es_MX');

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String longDate(DateTime date) => _longDate.format(date);

  /// Relative when close, absolute when not — a date three months out reads
  /// worse as "en 94 días" than as "12 sep".
  static String chargeLabel(DateTime date, int daysUntil) =>
      switch (daysUntil) {
        < 0 => 'Venció el ${shortDate(date)}',
        0 => 'Hoy',
        1 => 'Mañana',
        <= 14 => 'En $daysUntil días',
        _ => shortDate(date),
      };
}

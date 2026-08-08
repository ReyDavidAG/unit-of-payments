import 'package:intl/intl.dart';

/// Money and date formatting for es-MX. One place, so the app cannot drift
/// into three different ways of writing the same amount.
class MoneyHelper {
  const MoneyHelper._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  static String amount(double value) => _currency.format(value);

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

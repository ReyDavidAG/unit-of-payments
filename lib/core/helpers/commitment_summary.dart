import '../../data/models/subscriptions/subscription_model.dart';
import 'money_helper.dart';

/// Derives the two derived strings the form shows without ever being typed:
/// the installment breakdown ("12 pagos de $1,666.50") and the live commitment
/// preview ("$1,666.50 al mes · desde el 14 ago").
class CommitmentSummary {
  const CommitmentSummary._();

  /// Shown only when both numbers are real — never a placeholder figure.
  /// When the division leaves cents on the table the line says what the
  /// payments actually sum to.
  static String? breakdown({required double? total, required int? count}) {
    if (total == null || total <= 0 || count == null || count < 2) {
      return null;
    }
    final double monthly = MoneyHelper.installmentAmount(total, count);
    final String line = '$count pagos de ${MoneyHelper.amount(monthly)}';
    return (monthly * count - total).abs() < 0.005
        ? line
        : '$line · suman ${MoneyHelper.amount(monthly * count)}';
  }

  /// The commitment the user is about to confirm. Hidden until the amount is
  /// a real number — never a "—/mes" placeholder that asks the user to trust
  /// a future state of the form.
  static String? preview({
    required double? amount,
    required BillingCycle cycle,
    required String customDays,
    required DateTime firstCharge,
    required bool isInstallment,
    required int? installmentCount,
  }) {
    if (amount == null || amount <= 0) {
      return null;
    }
    final String start = MoneyHelper.shortDate(firstCharge);
    if (isInstallment) {
      if (installmentCount == null) {
        return null;
      }
      return '${MoneyHelper.amount(amount)} al mes · $installmentCount pagos · desde $start';
    }
    final String cadence = switch (cycle) {
      BillingCycle.weekly => 'cada semana',
      BillingCycle.monthly => 'cada mes',
      BillingCycle.yearly => 'cada año',
      BillingCycle.custom => 'cada ${int.tryParse(customDays) ?? '?'} días',
    };
    return '${MoneyHelper.amount(amount)} $cadence · desde $start';
  }
}

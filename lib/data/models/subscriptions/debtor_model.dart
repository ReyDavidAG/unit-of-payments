/// A row of `v_debtors`: one person who repays charges on the user's cards,
/// with what they still owe. Grouped in Postgres by the free-text `owed_by`,
/// so the name is whatever the user typed.
class DebtorModel {
  const DebtorModel({
    required this.name,
    required this.planCount,
    required this.monthlyAmount,
    required this.outstanding,
    this.nextChargeDate,
  });

  factory DebtorModel.fromJson(Map<String, dynamic> json) => DebtorModel(
    name: json['owed_by'] as String,
    planCount: json['plan_count'] as int? ?? 0,
    monthlyAmount: _toDouble(json['monthly_amount']),
    outstanding: _toDouble(json['outstanding']),
    nextChargeDate: json['next_charge_date'] == null
        ? null
        : DateTime.parse(json['next_charge_date'] as String),
  );

  final String name;
  final int planCount;
  final double monthlyAmount;

  /// Only installment debt has an end, so this is zero for someone who just
  /// splits an open-ended subscription.
  final double outstanding;
  final DateTime? nextChargeDate;

  bool get hasEnd => outstanding > 0;

  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
}

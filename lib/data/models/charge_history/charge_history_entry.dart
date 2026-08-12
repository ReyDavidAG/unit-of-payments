/// One row of [public.v_charge_history]: a past charge date for a
/// subscription. Read-only — there is no notion of "I paid this on time"
/// in this app, the entry is purely informational.
class ChargeHistoryEntry {
  const ChargeHistoryEntry({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.amount,
    required this.chargeDate,
    this.cardAlias,
    this.cardColor,
  });

  factory ChargeHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ChargeHistoryEntry(
        subscriptionId: json['subscription_id'] as String,
        subscriptionName: json['subscription_name'] as String,
        amount: _toDouble(json['amount']),
        chargeDate: DateTime.parse(json['charge_date'] as String),
        cardAlias: json['card_alias'] as String?,
        cardColor: json['card_color'] as String?,
      );

  final String subscriptionId;
  final String subscriptionName;
  final double amount;
  final DateTime chargeDate;
  final String? cardAlias;
  final String? cardColor;

  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
}

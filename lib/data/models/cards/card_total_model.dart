import 'card_model.dart';

/// A row of `v_card_totals`: what one card alias costs per month. Every field
/// is computed by Postgres, so nothing here is writable.
class CardTotalModel {
  const CardTotalModel({
    required this.alias,
    required this.color,
    required this.brand,
    required this.subscriptionCount,
    required this.monthlyTotal,
    this.cardId,
    this.nextChargeDate,
    this.installmentCount = 0,
    this.monthlyOwedByOthers = 0,
    this.outstandingTotal = 0,
  });

  factory CardTotalModel.fromJson(Map<String, dynamic> json) => CardTotalModel(
    cardId: json['card_id'] as String?,
    alias: json['alias'] as String,
    color: json['color'] as String? ?? '',
    brand: CardBrand.fromValue(json['brand'] as String?),
    subscriptionCount: json['subscription_count'] as int? ?? 0,
    monthlyTotal: _toDouble(json['monthly_total']),
    installmentCount: json['installment_count'] as int? ?? 0,
    monthlyOwedByOthers: _toDouble(json['monthly_owed_by_others']),
    outstandingTotal: _toDouble(json['outstanding_total']),
    nextChargeDate: json['next_charge_date'] == null
        ? null
        : DateTime.parse(json['next_charge_date'] as String),
  );

  final String? cardId;
  final String alias;
  final String color;
  final CardBrand brand;
  final int subscriptionCount;
  final double monthlyTotal;
  final DateTime? nextChargeDate;
  final int installmentCount;

  /// The slice of the monthly total someone else repays.
  final double monthlyOwedByOthers;

  /// Installment debt still to be charged to this card.
  final double outstandingTotal;

  /// Postgres returns numeric as a string so JSON cannot round it.
  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
}

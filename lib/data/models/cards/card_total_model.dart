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
  });

  factory CardTotalModel.fromJson(Map<String, dynamic> json) => CardTotalModel(
    cardId: json['card_id'] as String?,
    alias: json['alias'] as String,
    color: json['color'] as String? ?? '',
    brand: CardBrand.fromValue(json['brand'] as String?),
    subscriptionCount: json['subscription_count'] as int? ?? 0,
    monthlyTotal: _toDouble(json['monthly_total']),
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

  /// Postgres returns numeric as a string so JSON cannot round it.
  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
}

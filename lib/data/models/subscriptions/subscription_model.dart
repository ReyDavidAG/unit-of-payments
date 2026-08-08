import '../cards/card_model.dart';

/// A recurring charge. Read from `v_subscriptions`, which adds the computed
/// [nextChargeDate] and [monthlyAmount]; written to the `subscriptions` table.
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.firstChargeDate,
    this.cardId,
    this.customDays,
    this.endsOn,
    this.reminderDaysBefore = 1,
    this.category,
    this.notes,
    this.cardAlias,
    this.cardBrand,
    this.cardColor,
    this.nextChargeDate,
    this.monthlyAmount,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: _toDouble(json['amount']),
        cycle: BillingCycle.fromValue(json['cycle'] as String?),
        firstChargeDate: DateTime.parse(json['first_charge_date'] as String),
        cardId: json['card_id'] as String?,
        customDays: json['custom_days'] as int?,
        endsOn: _toDate(json['ends_on']),
        reminderDaysBefore: json['reminder_days_before'] as int? ?? 1,
        category: json['category'] as String?,
        notes: json['notes'] as String?,
        cardAlias: json['card_alias'] as String?,
        cardBrand: CardBrand.fromValue(json['card_brand'] as String?),
        cardColor: json['card_color'] as String?,
        nextChargeDate: _toDate(json['next_charge_date']),
        monthlyAmount: json['monthly_amount'] == null
            ? null
            : _toDouble(json['monthly_amount']),
      );

  final String id;
  final String name;
  final double amount;
  final BillingCycle cycle;
  final DateTime firstChargeDate;
  final String? cardId;
  final int? customDays;
  final DateTime? endsOn;
  final int reminderDaysBefore;
  final String? category;
  final String? notes;

  // Joined and computed by the view. Never written back.
  final String? cardAlias;
  final CardBrand? cardBrand;
  final String? cardColor;
  final DateTime? nextChargeDate;
  final double? monthlyAmount;

  /// Postgres returns numeric as a string to avoid losing precision in JSON.
  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static String _toIsoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Only the writable columns. The view's computed fields and user_id are
  /// the database's business.
  Map<String, dynamic> toWrite() => {
    'name': name,
    'amount': amount,
    'cycle': cycle.value,
    'custom_days': cycle == BillingCycle.custom ? customDays : null,
    'first_charge_date': _toIsoDate(firstChargeDate),
    'ends_on': endsOn == null ? null : _toIsoDate(endsOn!),
    'reminder_days_before': reminderDaysBefore,
    'card_id': cardId,
    'category': category,
    'notes': notes,
  };

  /// Days until the next charge. Negative means it already passed today.
  int? daysUntilCharge(DateTime today) => nextChargeDate == null
      ? null
      : DateTime(
          nextChargeDate!.year,
          nextChargeDate!.month,
          nextChargeDate!.day,
        ).difference(DateTime(today.year, today.month, today.day)).inDays;
}

enum BillingCycle {
  weekly('weekly', 'Semanal'),
  monthly('monthly', 'Mensual'),
  yearly('yearly', 'Anual'),
  custom('custom', 'Personalizado');

  const BillingCycle(this.value, this.label);

  final String value;
  final String label;

  static BillingCycle fromValue(String? value) => values.firstWhere(
    (cycle) => cycle.value == value,
    orElse: () => BillingCycle.monthly,
  );
}

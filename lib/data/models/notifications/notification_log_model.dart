/// One scheduled reminder. The (subscription, charge_date) pair is unique in
/// the database, which is what makes rescheduling on every launch idempotent.
class NotificationLogModel {
  const NotificationLogModel({
    required this.subscriptionId,
    required this.chargeDate,
    required this.scheduledFor,
    required this.amount,
    required this.title,
    this.id,
    this.deliveredAt,
    this.openedAt,
  });

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) =>
      NotificationLogModel(
        id: json['id'] as String?,
        subscriptionId: json['subscription_id'] as String,
        chargeDate: DateTime.parse(json['charge_date'] as String),
        scheduledFor: DateTime.parse(json['scheduled_for'] as String),
        amount: _toDouble(json['amount']),
        title: json['title'] as String,
        deliveredAt: _toDate(json['delivered_at']),
        openedAt: _toDate(json['opened_at']),
      );

  final String? id;
  final String subscriptionId;
  final DateTime chargeDate;
  final DateTime scheduledFor;
  final double amount;
  final String title;
  final DateTime? deliveredAt;
  final DateTime? openedAt;

  Map<String, dynamic> toInsert() => {
    'subscription_id': subscriptionId,
    'charge_date':
        '${chargeDate.year.toString().padLeft(4, '0')}-'
        '${chargeDate.month.toString().padLeft(2, '0')}-'
        '${chargeDate.day.toString().padLeft(2, '0')}',
    'scheduled_for': scheduledFor.toUtc().toIso8601String(),
    'amount': amount,
    'title': title,
  };

  /// A local notification fires with the app closed, so delivery is inferred
  /// on the next launch rather than reported at fire time.
  bool get isDue =>
      deliveredAt == null && scheduledFor.isBefore(DateTime.now());

  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();
}

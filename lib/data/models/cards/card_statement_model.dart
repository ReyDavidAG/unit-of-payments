/// A row of `v_card_statement`: the open statement on one card. Every field is
/// computed by Postgres from the cutoff and due days, so nothing here is
/// writable and none of the date maths is repeated in Dart.
class CardStatementModel {
  const CardStatementModel({
    required this.cardId,
    required this.alias,
    required this.opensAfter,
    required this.closesOn,
    required this.totalDue,
    required this.owedByOthers,
    required this.yours,
    required this.lineCount,
    this.color,
    this.dueOn,
  });

  factory CardStatementModel.fromJson(Map<String, dynamic> json) =>
      CardStatementModel(
        cardId: json['card_id'] as String,
        alias: json['alias'] as String,
        color: json['color'] as String?,
        opensAfter: DateTime.parse(json['opens_after'] as String),
        closesOn: DateTime.parse(json['closes_on'] as String),
        dueOn: json['due_on'] == null
            ? null
            : DateTime.parse(json['due_on'] as String),
        totalDue: _toDouble(json['total_due']),
        owedByOthers: _toDouble(json['owed_by_others']),
        yours: _toDouble(json['yours']),
        lineCount: json['line_count'] as int? ?? 0,
      );

  final String cardId;
  final String alias;
  final String? color;

  /// The window is exclusive at the start: charges land after this date.
  final DateTime opensAfter;
  final DateTime closesOn;

  /// Null until the card has a payment due day. Without it there is a total
  /// but no deadline to warn about.
  final DateTime? dueOn;

  final double totalDue;
  final double owedByOthers;

  /// What is left after the reimbursements — the number that is actually yours.
  final double yours;
  final int lineCount;

  bool get hasCharges => lineCount > 0;
  bool get isShared => owedByOthers > 0;

  /// Days until the deadline. Negative means it already passed.
  int? daysUntilDue(DateTime today) => dueOn == null
      ? null
      : DateTime(
          dueOn!.year,
          dueOn!.month,
          dueOn!.day,
        ).difference(DateTime(today.year, today.month, today.day)).inDays;

  static double _toDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
}

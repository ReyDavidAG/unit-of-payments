/// A card alias. Never holds a PAN, a CVV or an expiry date: [last4] is the
/// only figure stored, and the database rejects anything longer.
class CardModel {
  const CardModel({
    required this.id,
    required this.alias,
    required this.brand,
    required this.color,
    this.last4,
    this.cutoffDay,
    this.paymentDueDay,
    this.archived = false,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id: json['id'] as String,
    alias: json['alias'] as String,
    brand: CardBrand.fromValue(json['brand'] as String?),
    color: json['color'] as String,
    last4: json['last4'] as String?,
    cutoffDay: json['cutoff_day'] as int?,
    paymentDueDay: json['payment_due_day'] as int?,
    archived: json['archived'] as bool? ?? false,
  );

  final String id;
  final String alias;
  final CardBrand brand;
  final String color;
  final String? last4;
  final int? cutoffDay;

  /// The deadline, not the cutoff. Missing it costs interest and the
  /// interest-free months; the cutoff only decides which statement a charge
  /// lands on.
  final int? paymentDueDay;
  final bool archived;

  /// Omits id and user_id: the database fills both, and a client-supplied
  /// user_id is exactly what the RLS policies refuse.
  Map<String, dynamic> toInsert() => {
    'alias': alias,
    'brand': brand.value,
    'color': color,
    'last4': last4,
    'cutoff_day': cutoffDay,
    'payment_due_day': paymentDueDay,
  };

  CardModel copyWith({
    String? alias,
    CardBrand? brand,
    String? color,
    String? last4,
    int? cutoffDay,
    int? paymentDueDay,
    bool? archived,
    bool clearLast4 = false,
    bool clearCutoffDay = false,
  }) => CardModel(
    id: id,
    alias: alias ?? this.alias,
    brand: brand ?? this.brand,
    color: color ?? this.color,
    last4: clearLast4 ? null : (last4 ?? this.last4),
    cutoffDay: clearCutoffDay ? null : (cutoffDay ?? this.cutoffDay),
    paymentDueDay: paymentDueDay ?? this.paymentDueDay,
    archived: archived ?? this.archived,
  );
}

enum CardBrand {
  visa('visa', 'Visa'),
  mastercard('mastercard', 'Mastercard'),
  amex('amex', 'American Express'),
  other('other', 'Otra');

  const CardBrand(this.value, this.label);

  final String value;
  final String label;

  /// Falls back instead of throwing: a brand added to the enum later must not
  /// crash a list built by an older build of the app.
  static CardBrand fromValue(String? value) => values.firstWhere(
    (brand) => brand.value == value,
    orElse: () => CardBrand.other,
  );
}

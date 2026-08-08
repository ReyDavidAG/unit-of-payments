/// Row of `profiles`. Created by the signup trigger, never inserted by the
/// client — only updated.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.currency,
    required this.timezone,
    this.displayName,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    currency: json['currency'] as String? ?? 'MXN',
    timezone: json['timezone'] as String? ?? defaultTimezone,
    displayName: json['display_name'] as String?,
  );

  static const String defaultTimezone = 'America/Mexico_City';

  final String id;
  final String currency;
  final String timezone;
  final String? displayName;

  Map<String, dynamic> toUpdate() => {
    'display_name': displayName,
    'currency': currency,
    'timezone': timezone,
  };

  ProfileModel copyWith({
    String? currency,
    String? timezone,
    String? displayName,
  }) => ProfileModel(
    id: id,
    currency: currency ?? this.currency,
    timezone: timezone ?? this.timezone,
    displayName: displayName ?? this.displayName,
  );
}

/// The currencies the app formats. One per profile — there is no conversion,
/// so mixing them inside one account would produce a meaningless total.
enum SupportedCurrency {
  mxn('MXN', r'$', 'Peso mexicano'),
  usd('USD', r'US$', 'Dólar'),
  eur('EUR', '€', 'Euro');

  const SupportedCurrency(this.code, this.symbol, this.label);

  final String code;
  final String symbol;
  final String label;

  static SupportedCurrency fromCode(String? code) => values.firstWhere(
    (currency) => currency.code == code,
    orElse: () => SupportedCurrency.mxn,
  );
}

/// Zones offered in the picker. Not the full IANA list: reminders only need
/// the zone the person actually lives in, and Mexico has six.
const List<({String id, String label})> supportedTimezones = [
  (id: 'America/Mexico_City', label: 'Centro (Ciudad de México)'),
  (id: 'America/Cancun', label: 'Sureste (Cancún)'),
  (id: 'America/Monterrey', label: 'Centro (Monterrey)'),
  (id: 'America/Chihuahua', label: 'Pacífico (Chihuahua)'),
  (id: 'America/Mazatlan', label: 'Pacífico (Mazatlán)'),
  (id: 'America/Hermosillo', label: 'Noroeste (Hermosillo)'),
  (id: 'America/Tijuana', label: 'Noroeste (Tijuana)'),
  (id: 'America/New_York', label: 'Este de EE. UU.'),
  (id: 'America/Los_Angeles', label: 'Oeste de EE. UU.'),
  (id: 'Europe/Madrid', label: 'España'),
];

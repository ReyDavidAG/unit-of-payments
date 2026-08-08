import '../../data/models/cards/card_model.dart';

/// Guesses the payment network from the alias the user types.
///
/// The stored last4 is no help here: the network lives in the BIN, the first
/// digits, which is the one part of the number this app deliberately never
/// holds.
class CardBrandHelper {
  const CardBrandHelper._();

  /// The network spelled out. Checked first, because a user who wrote
  /// "BBVA MC" told us the answer and no inference may outrank that.
  static const Map<String, CardBrand> _networkWords = {
    'visa': CardBrand.visa,
    'mastercard': CardBrand.mastercard,
    'master card': CardBrand.mastercard,
    'mc': CardBrand.mastercard,
    'amex': CardBrand.amex,
    'american express': CardBrand.amex,
    'americanexpress': CardBrand.amex,
    'centurion': CardBrand.amex,
  };

  /// Issuers and products that point at one network clearly enough to
  /// preselect it. The bar is "dominant", not "exclusive", because the form
  /// only ever suggests: the guess is labelled as a guess and one tap replaces
  /// it.
  ///
  /// What stays out are the issuers with a genuinely split lineup — Banorte,
  /// Santander, Banamex, HSBC, Scotiabank, Inbursa — and Vexi (Amex or
  /// Carnet). There, a guess would be a coin flip.
  static const Map<String, CardBrand> _issuerNames = {
    // BBVA México is the loosest case here: Azul, Oro, Platinum and Infinite
    // all run on Visa, but the bank does issue Mastercard too.
    'bbva': CardBrand.visa,
    'bancomer': CardBrand.visa,
    // Mercado Pago splits by product: credit is Visa, debit is Mastercard.
    // A card in this app carries a cutoff day, so it is the credit one.
    'mercado pago': CardBrand.visa,
    'mercadopago': CardBrand.visa,
    'rappi': CardBrand.visa,
    'rappicard': CardBrand.visa,
    'hey banco': CardBrand.visa,
    'heybanco': CardBrand.visa,
    'costco': CardBrand.visa,
    'nu': CardBrand.mastercard,
    'nubank': CardBrand.mastercard,
    'klar': CardBrand.mastercard,
    'stori': CardBrand.mastercard,
  };

  /// Null means "no opinion", which is not the same as [CardBrand.other] —
  /// the caller decides what to do with silence.
  static CardBrand? detect(String alias) {
    final String haystack = _normalize(alias);
    return _longestMatch(haystack, _networkWords) ??
        _longestMatch(haystack, _issuerNames);
  }

  /// Longest key wins, so "american express" beats "amex" on an alias that
  /// happens to hold both.
  static CardBrand? _longestMatch(
    String haystack,
    Map<String, CardBrand> names,
  ) {
    String longest = '';
    CardBrand? found;
    for (final MapEntry<String, CardBrand> entry in names.entries) {
      if (entry.key.length > longest.length &&
          haystack.contains(' ${entry.key} ')) {
        longest = entry.key;
        found = entry.value;
      }
    }
    return found;
  }

  /// Padded with spaces so a key only ever matches a whole word: `nu` must not
  /// fire on `Nuevo`.
  static String _normalize(String alias) =>
      ' ${alias.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim()} ';
}

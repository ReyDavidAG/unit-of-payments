import 'card_model.dart';

/// Maps a [CardBrand] to the bundled WebP that renders as the card visual
/// everywhere a card is referenced: tile, dashboard total, brand picker.
///
/// Brand colours used to live here too. They were the only raw hex values in
/// the app outside the palette, and they were painting the one thing that has
/// to stay readable — the swatch now does that job in every list.
class CardAssets {
  const CardAssets._();

  static String webp(CardBrand brand) => 'lib/assets/cards/${brand.value}.webp';
}

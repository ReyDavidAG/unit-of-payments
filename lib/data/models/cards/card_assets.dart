import 'package:flutter/material.dart';

import 'card_model.dart';

/// Maps a [CardBrand] to the bundled WebP that renders as the card visual
/// everywhere a card is referenced: tile, dashboard total, brand picker.
///
/// `accent` is the brand's signature colour, used where a flat fill is
/// required (the 3 px subscription bar, mostly). Keeping it here so the
/// brand identity stays in one place.
class CardAssets {
  const CardAssets._();

  static String webp(CardBrand brand) => 'lib/assets/cards/${brand.value}.webp';

  static Color accent(CardBrand brand) => switch (brand) {
    CardBrand.visa => const Color(0xFF1A1F71),
    CardBrand.mastercard => const Color(0xFFEB001B),
    CardBrand.amex => const Color(0xFF006FCF),
    CardBrand.other => const Color(0xFFC19A3F),
  };
}

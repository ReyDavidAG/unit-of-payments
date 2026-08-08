/// 4pt scale and radii. A widget that types a raw number is a bug.
class AppSpacing {
  const AppSpacing._();

  static const double xs3 = 2;
  static const double xs2 = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xl2 = 64;
  static const double xl3 = 96;

  // Rhythm must be uneven: equal padding everywhere reads as a template.
  static const double screenPadding = md;
  static const double cardPadding = lg;
  static const double listGap = sm;
  static const double sectionGap = xl;

  static const double radiusInput = 8;
  static const double radiusCard = 12;
  static const double radiusPill = 999;

  /// The one width a card's swatch is ever drawn at: the left bar on every
  /// card-bearing row, and the dot that stands in for it inside a chip.
  static const double swatchBar = 6;
}

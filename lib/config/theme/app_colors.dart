import 'package:flutter/material.dart';

/// Coral palette. OKLCH values and measured contrast live in DESIGN.md.
/// Anchor hue 40, accent hue 32: every neutral carries the warm tint on purpose.
class AppColors {
  const AppColors._();

  // Light
  static const Color paper = Color(0xFFFAF3F1);
  static const Color surface = Color(0xFFF3EBE8);
  static const Color surface2 = Color(0xFFE9DFDB);
  static const Color rule = Color(0xFFDBD2CF);
  static const Color neutral = Color(0xFF817875);
  static const Color muted = Color(0xFF59504D);
  static const Color ink = Color(0xFF1C1411);
  static const Color accent = Color(0xFFD9553F);
  static const Color accentInk = Color(0xFF721E10);
  static const Color focus = Color(0xFFC8331A);
  static const Color danger = Color(0xFFBD1F3D);

  // Dark. Same hue, only lightness and chroma move.
  static const Color paperDark = Color(0xFF100908);
  static const Color surfaceDark = Color(0xFF18110E);
  static const Color surface2Dark = Color(0xFF211816);
  static const Color ruleDark = Color(0xFF362E2B);
  static const Color neutralDark = Color(0xFF8D8481);
  static const Color mutedDark = Color(0xFFB7AFAC);
  static const Color inkDark = Color(0xFFF0E9E7);
  static const Color accentDark = Color(0xFFEF816B);
  static const Color accentInkDark = Color(0xFFFBC1B5);
  static const Color focusDark = Color(0xFFFB836D);
  static const Color dangerDark = Color(0xFFE3636C);

  /// The only colours a card alias may take. Six, not eight: the eight-hue
  /// set at constant lightness collapsed under colour-vision deficiency
  /// (amber vs olive read as the same colour). These alternate lightness as
  /// well as hue, and pass the categorical checks against both papers.
  /// Hues 20-45 stay reserved for the accent.
  static const Map<String, Color> cardSwatches = {
    'amber': Color(0xFFD57700),
    'olive': Color(0xFF686800),
    'green': Color(0xFF227405),
    'cyan': Color(0xFF0CA3BE),
    'indigo': Color(0xFF494ECF),
    'pink': Color(0xFFDC58B7),
  };

  static const Color defaultSwatch = Color(0xFF494ECF);

  /// The storage format for `cards.color`. Uppercase `#RRGGBB`, which is what
  /// the database CHECK constraint expects.
  static String hexOf(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Falls back instead of throwing: a colour from an older row must not crash
  /// a list. Unknown hex values render as the default swatch.
  static Color swatchFromHex(String? hex) {
    if (hex == null || hex.length != 7) {
      return defaultSwatch;
    }
    final int? value = int.tryParse(hex.substring(1), radix: 16);
    if (value == null) {
      return defaultSwatch;
    }
    final Color parsed = Color(0xFF000000 | value);
    return cardSwatches.values.contains(parsed) ? parsed : defaultSwatch;
  }
}

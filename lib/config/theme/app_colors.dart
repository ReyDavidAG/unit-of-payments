import 'package:flutter/material.dart';

/// Coral palette. OKLCH values and measured contrast live in DESIGN.md.
/// Anchor hue 40, accent hue 32: every neutral carries the warm tint on purpose.
class AppColors {
  const AppColors._();

  // Light — Hum palette: warm cream paper, deep warm-black ink, single
  // terracotta accent that carries buttons, focus rings and tab indicators
  // in one chromatic identity. Hex values chosen to match the warm, baked
  // bread-crust tone of the Hallmark Hum example.
  static const Color paper = Color(0xFFF8F4ED);
  static const Color surface = Color(0xFFF1EBE2);
  static const Color surface2 = Color(0xFFE9DDCF);
  static const Color rule = Color(0xFFDDD2C2);
  static const Color neutral = Color(0xFF8A7E72);
  static const Color muted = Color(0xFF6B6157);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFB8763B);
  static const Color accentInk = Color(0xFF6B3818);
  static const Color focus = Color(0xFFB8763B);
  static const Color danger = Color(0xFFBD1F3D);

  // Primary button fill — same terracotta as the accent. One identity,
  // not a separate "primary" colour that competes with it. Reads as
  // decided and chromatic on the warm cream paper.
  static const Color primary = Color(0xFFB8763B);
  static const Color onPrimary = paper;

  // Tab-indicator colours — distinct chromatic identity per destination.
  // Resumen uses the same blue in both modes so the active tab reads
  // the same regardless of theme. Tarjetas uses the cascade's
  // aubergine so the active tab borrows from the brand mark. Suscripciones
  // and Avisos reuse the semantic success and critical hues.
  static const Color tabBlue = Color(0xFF4A8AAC); // Resumen, both modes
  static const Color tabPurple = Color(0xFF5B2C6F); // Tarjetas, light
  static const Color tabPurpleDark = Color(0xFF7B3D9E); // Tarjetas, dark

  // Semantic palette — used sparingly inside the app to communicate
  // state: charge timing, sync status, urgency. Four hues inspired by
  // the Hallmark Bubble example (green / blue / amber / pink), each
  // carrying a distinct semantic so the colour itself is the message.
  static const Color success = Color(0xFF5DBA76);
  static const Color info = Color(0xFF3D7FE8);
  static const Color warning = Color(0xFFE0A938);
  static const Color critical = Color(0xFFF26B82);

  // Dark. Wayfare's Manifesto-dark palette: warm anchor at hue 60, bleed-red
  // accent at 25. Chroma is clamped to what sRGB can hold — the source is CSS
  // oklch, which the browser gamut-maps and Flutter cannot.
  static const Color paperDark = Color(0xFF0A0704);
  static const Color surfaceDark = Color(0xFF16100C);
  static const Color surface2Dark = Color(0xFF241E19);
  static const Color ruleDark = Color(0xFF2D2823);
  static const Color neutralDark = Color(0xFF8C857D);
  static const Color mutedDark = Color(0xFFC2BDB5);
  static const Color inkDark = Color(0xFFF5F1EA);
  static const Color accentDark = Color(0xFFFE4145);
  static const Color accentInkDark = Color(0xFFFDA19A);
  static const Color focusDark = Color(0xFFF9A216);
  // Magenta, not red: the accent is now red, and a destructive action in a
  // second red is a destructive action nobody can tell apart from a marker.
  static const Color dangerDark = Color(0xFFEA0C9B);

  // Primary button fill in dark mode: same hue as light, lifted enough
  // lightness to clear 4.5:1 against paperDark. A single chromatic
  // identity across modes, not a black/white flip.
  static const Color primaryDark = Color(0xFF4A8AAC);
  static const Color onPrimaryDark = paperDark;

  // Semantic palette in dark mode — same hues, lifted lightness so they
  // pass contrast on the dark paper. Each one is the visual signal of
  // its semantic role.
  static const Color successDark = Color(0xFF7BC96F);
  static const Color infoDark = Color(0xFF6BA0F5);
  static const Color warningDark = Color(0xFFF5C842);
  static const Color criticalDark = Color(0xFFF77890);

  /// Days until a charge or a deadline, mapped to the semantic palette. Null
  /// means "no tint" — the default muted copy. Escalates with proximity.
  static Color? urgency(int days, {required bool isDark}) {
    if (days <= 3) return isDark ? criticalDark : critical;
    if (days <= 6) return isDark ? warningDark : warning;
    if (days <= 13) return isDark ? successDark : success;
    return null;
  }

  /// The only colours a card alias may take. Six base swatches, plus two
  /// added per request: morado (Nu) and amarillo (Mercado Pago). The base
  /// six alternate lightness to pass CVD checks; the two additions sit
  /// at the heavier-lightness slots so the pattern still reads.
  /// Hues 20-45 stay reserved for the accent.
  static const Map<String, Color> cardSwatches = {
    'amber': Color(0xFFD57700),
    'olive': Color(0xFF686800),
    'green': Color(0xFF227405),
    'cyan': Color(0xFF0CA3BE),
    'indigo': Color(0xFF494ECF),
    'pink': Color(0xFFDC58B7),
    'morado': Color(0xFF7B2D9E),
    'amarillo': Color(0xFFD9A52A),
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

/// Brightness-aware semantic palette. Each getter returns the dark variant
/// in dark mode and the light variant otherwise, so chips and field borders
/// keep the same hue family on either side of the theme switch.
extension SemanticPalette on ThemeData {
  Color get info =>
      brightness == Brightness.dark ? AppColors.infoDark : AppColors.info;
  Color get warning =>
      brightness == Brightness.dark ? AppColors.warningDark : AppColors.warning;
  Color get success =>
      brightness == Brightness.dark ? AppColors.successDark : AppColors.success;
  Color get critical => brightness == Brightness.dark
      ? AppColors.criticalDark
      : AppColors.critical;
}

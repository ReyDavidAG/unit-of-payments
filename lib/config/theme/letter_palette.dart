import 'package:flutter/material.dart';

/// A 26-entry palette: one saturated colour per Latin letter. The AppBar
/// profile button and the profile screen's identity avatar both pull the
/// border colour from here, keyed by the first letter of the user's email.
///
/// Why per-letter: a flat single colour makes every account look identical;
/// a per-letter palette gives each account a stable identity that survives
/// across sessions without ever asking the user to pick one.
///
/// Falls back to the first entry on empty / non-letter input rather than
/// throwing — a brand-new session before the email has loaded still paints.
const Map<String, Color> letterPalette = {
  'A': Color(0xFFD57700),
  'B': Color(0xFF1A1F71),
  'C': Color(0xFFE57373),
  'D': Color(0xFF6A1B9A),
  'E': Color(0xFF2E7D32),
  'F': Color(0xFF388E3C),
  'G': Color(0xFFFFB300),
  'H': Color(0xFFD84315),
  'I': Color(0xFF494ECF),
  'J': Color(0xFF00A896),
  'K': Color(0xFFBDB76B),
  'L': Color(0xFFB39DDB),
  'M': Color(0xFFC2185B),
  'N': Color(0xFF1565C0),
  'O': Color(0xFF689F38),
  'P': Color(0xFF8E24AA),
  'Q': Color(0xFF607D8B),
  'R': Color(0xFFE91E63),
  'S': Color(0xFF1976D2),
  'T': Color(0xFF00897B),
  'U': Color(0xFF3F51B5),
  'V': Color(0xFF7B1FA2),
  'W': Color(0xFF880E4F),
  'X': Color(0xFFFBC02D),
  'Y': Color(0xFFD9A52A),
  'Z': Color(0xFF455A64),
};

Color letterPaletteColor(String letter) {
  if (letter.isEmpty) {
    return letterPalette.values.first;
  }
  final String key = letter.substring(0, 1).toUpperCase();
  return letterPalette[key] ?? letterPalette.values.first;
}

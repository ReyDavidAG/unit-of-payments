import 'package:flutter/material.dart';

/// Geist for everything, Geist Mono for one role only: monetary figures.
/// Major third scale from a 16 body. Headings are 700 so the gap against the
/// 400 body reads as a decision rather than a default.
class AppTypography {
  const AppTypography._();

  static const String sans = 'Geist';
  static const String mono = 'GeistMono';

  /// Money must line up down a column, so figures are always tabular.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    displayLarge: TextStyle(
      fontFamily: sans,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.08,
      letterSpacing: -0.8,
      color: ink,
    ),
    headlineLarge: TextStyle(
      fontFamily: sans,
      fontSize: 31,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.62,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontFamily: sans,
      fontSize: 25,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.25,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontFamily: sans,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.2,
      color: ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: sans,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ink,
    ),
    bodySmall: TextStyle(
      fontFamily: sans,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: muted,
    ),
    labelLarge: TextStyle(
      fontFamily: sans,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: ink,
    ),
    labelSmall: TextStyle(
      fontFamily: sans,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 1.1,
      color: muted,
    ),
  );

  /// The one number on the dashboard.
  static TextStyle displayAmount(Color color) => TextStyle(
    fontFamily: mono,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 1.08,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
    color: color,
  );

  /// Every amount in a list.
  static TextStyle amount(Color color) => TextStyle(
    fontFamily: mono,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFeatures: _tabular,
    color: color,
  );

  /// Card last4 and other short figure runs.
  static TextStyle figure(Color color) => TextStyle(
    fontFamily: mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFeatures: _tabular,
    color: color,
  );
}

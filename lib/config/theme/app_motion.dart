import 'package:flutter/animation.dart';

/// Three durations, three curves. Budget is two moving things per screen.
class AppMotion {
  const AppMotion._();

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration long = Duration(milliseconds: 420);

  /// Reduced-motion replacement for any spatial transition.
  static const Duration reduced = Duration(milliseconds: 150);

  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeIn = Cubic(0.7, 0, 0.84, 0);
  static const Curve easeInOut = Cubic(0.65, 0, 0.35, 1);

  /// Exits run at 75% of the enter.
  static Duration exit(Duration enter) =>
      Duration(microseconds: (enter.inMicroseconds * 0.75).round());
}

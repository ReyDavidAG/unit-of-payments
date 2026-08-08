import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_motion.dart';

/// Fade-down entry for a hero element (the dashboard total, an auth headline).
/// Honours `MediaQuery.disableAnimations` by collapsing to identity.
class AnimatedHero extends StatelessWidget {
  const AnimatedHero({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return FadeInDown(duration: AppMotion.long, child: child);
  }
}

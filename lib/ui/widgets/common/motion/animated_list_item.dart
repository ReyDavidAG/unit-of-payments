import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_motion.dart';

/// Staggered fade-up entry for a list item. The delay caps at index 4 so a
/// 100-item list doesn't take two seconds to settle — after the fifth item
/// everything appears together.
/// Honours `MediaQuery.disableAnimations` by collapsing to identity.
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  // Cap at the fifth slot; clamp keeps later items from feeling delayed.
  static const int _staggerCap = 4;
  static const int _staggerStepMs = 40;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final clamped = index.clamp(0, _staggerCap);
    return FadeInUp(
      duration: AppMotion.short,
      delay: Duration(milliseconds: _staggerStepMs * clamped),
      child: child,
    );
  }
}

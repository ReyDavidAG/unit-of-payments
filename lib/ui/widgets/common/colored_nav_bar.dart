import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// Bottom navigation where each tab carries its own chromatic identity,
/// drawn from the semantic palette. A standard NavigationBar paints every
/// selected destination the same primary colour; here, each tab is
/// distinctly coloured when active so the user can tell at a glance which
/// one they're on without reading the label.
///
/// The colour mapping is fixed:
///   0  Resumen       — primary (teal)
///   1  Suscripciones — success (green)
///   2  Tarjetas      — info (blue)
///   3  Avisos        — warning (amber)
///
/// Dark mode keeps the same hues lifted to clear 4.5:1 against paperDark.
class ColoredNavBar extends StatelessWidget {
  const ColoredNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color unselectedColor = isDark
        ? AppColors.mutedDark
        : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.xl3,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavDestination(
                    item: items[i],
                    selected: i == currentIndex,
                    color: _colorFor(i, isDark),
                    unselectedColor: unselectedColor,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab index → semantic colour. Centralised so the mapping is the
  /// only place that knows which tab is which colour.
  static Color _colorFor(int index, bool isDark) {
    if (isDark) {
      return switch (index) {
        0 => AppColors.primaryDark,
        1 => AppColors.successDark,
        2 => AppColors.infoDark,
        _ => AppColors.warningDark,
      };
    }
    return switch (index) {
      0 => AppColors.primary,
      1 => AppColors.success,
      2 => AppColors.info,
      _ => AppColors.warning,
    };
  }
}

class NavBarItem {
  const NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.selected,
    required this.color,
    required this.unselectedColor,
    required this.onTap,
  });

  final NavBarItem item;
  final bool selected;
  final Color color;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = selected ? color : unselectedColor;
    return InkWell(
      onTap: onTap,
      child: Semantics(
        label: item.label,
        selected: selected,
        button: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 32,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 24,
                color: tint,
              ),
            ),
            const SizedBox(height: AppSpacing.xs2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tint,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

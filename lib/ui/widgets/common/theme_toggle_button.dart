import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/theme_mode_enum.dart';
import '../../../data/providers/theme/theme_provider.dart';

/// Two-state theme toggle (light ↔ dark). Renders the icon for the state
/// the app is currently NOT in, so the tap lands on the next state. Same
/// widget works in the auth screens (cycling without System) and in the
/// tab AppBars (always picking the explicit opposite of the current mode).
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode current = ref.watch(themeProvider);
    final bool isDark = current == AppThemeMode.dark;
    final IconData icon = isDark
        ? Icons.light_mode_outlined
        : Icons.dark_mode_outlined;
    final String label = isDark
        ? 'Cambiar a modo claro'
        : 'Cambiar a modo oscuro';

    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      onPressed: () {
        ref
            .read(themeProvider.notifier)
            .set(isDark ? AppThemeMode.light : AppThemeMode.dark);
      },
    );
  }
}

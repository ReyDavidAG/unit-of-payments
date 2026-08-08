import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/config/theme/theme_mode_enum.dart';
import 'package:unit_of_payments/data/providers/theme/theme_provider.dart';

void main() {
  test('an unreadable stored value falls back to system', () {
    // A mode written by a future build must not stop an older one starting.
    expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
    expect(AppThemeMode.fromName('midnight'), AppThemeMode.system);
    expect(AppThemeMode.fromName(null), AppThemeMode.system);
  });

  test('the choice survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final ProviderContainer first = ProviderContainer();
    addTearDown(first.dispose);

    expect(await first.read(themeProvider.future), AppThemeMode.system);
    await first.read(themeProvider.notifier).set(AppThemeMode.dark);

    // A fresh container is what a cold start looks like.
    final ProviderContainer restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    expect(await restarted.read(themeProvider.future), AppThemeMode.dark);
  });

  test('dark mode is its own palette, not an inverted light one', () {
    // Same token, different value in each mode: flipping lightness would give
    // a dark theme the light theme's hue, which is the tell.
    expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.paperDark);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.paper);
    expect(AppColors.accentDark, isNot(AppColors.accent));
  });

  test('destructive stays distinguishable from the accent in dark', () {
    // The dark accent is red; a destructive action in a second red would be
    // unreadable as a distinct thing.
    expect(AppColors.dangerDark, isNot(AppColors.accentDark));
    expect(AppTheme.dark.colorScheme.error, AppColors.dangerDark);
    expect(AppTheme.dark.colorScheme.secondary, AppColors.accentDark);
  });

  test('every mode maps to a Flutter ThemeMode', () {
    expect(AppThemeMode.system.flutterMode, ThemeMode.system);
    expect(AppThemeMode.light.flutterMode, ThemeMode.light);
    expect(AppThemeMode.dark.flutterMode, ThemeMode.dark);
  });
}

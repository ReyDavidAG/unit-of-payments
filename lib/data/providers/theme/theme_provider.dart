import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme/theme_mode_enum.dart';

/// Theme preference, stored on the device.
///
/// Not in `profiles`: the theme has to apply on the sign-in screen, before
/// there is a session to read a row with, and it must survive with no network.
/// Not in secure storage either — it is a preference, not a secret, and a
/// keychain round trip for five characters is work nobody asked for.
///
/// Synchronous on purpose: `main()` reads the persisted value before `runApp`
/// and injects it via [themeProvider.overrideWith]. A first-frame fallback to
/// `system` would flash the wrong theme for a frame before the disk read
/// resolved — visible on hot restart, jarring on cold start.
class ThemeNotifier extends Notifier<AppThemeMode> {
  ThemeNotifier({this.initialMode = AppThemeMode.system});

  final AppThemeMode initialMode;

  static const String _key = 'app_theme_mode';

  /// Synchronously loadable factory used by `main()` so the first frame is
  /// painted in the persisted theme, not in `system`.
  static Future<AppThemeMode> loadInitial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppThemeMode.fromName(prefs.getString(_key));
  }

  @override
  AppThemeMode build() => initialMode;

  Future<void> set(AppThemeMode mode) async {
    // Applied before the write: the theme should flip the instant it is
    // tapped, not after a disk round trip.
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final NotifierProvider<ThemeNotifier, AppThemeMode> themeProvider =
    NotifierProvider<ThemeNotifier, AppThemeMode>(() => ThemeNotifier());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme/theme_mode_enum.dart';

/// Theme preference, stored on the device.
///
/// Not in `profiles`: the theme has to apply on the sign-in screen, before
/// there is a session to read a row with, and it must survive with no network.
/// Not in secure storage either — it is a preference, not a secret, and a
/// keychain round trip for five characters is work nobody asked for.
class ThemeNotifier extends AsyncNotifier<AppThemeMode> {
  static const String _key = 'app_theme_mode';

  @override
  Future<AppThemeMode> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppThemeMode.fromName(prefs.getString(_key));
  }

  Future<void> set(AppThemeMode mode) async {
    // Applied before the write: the theme should flip the instant it is
    // tapped, not after a disk round trip.
    state = AsyncData(mode);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final AsyncNotifierProvider<ThemeNotifier, AppThemeMode> themeProvider =
    AsyncNotifierProvider<ThemeNotifier, AppThemeMode>(ThemeNotifier.new);

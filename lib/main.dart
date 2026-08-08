import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'config/router/app_router.dart';
import 'config/theme/theme_mode_enum.dart';
import 'config/theme/app_theme.dart';
import 'data/providers/theme/theme_provider.dart';
import 'data/services/supabase/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Number symbols ship with intl, date symbols do not: without this every
  // DateFormat('d MMM', 'es_MX') throws on first use.
  await initializeDateFormatting('es_MX');
  Intl.defaultLocale = 'es_MX';
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defaults to system while the stored value loads, so the first frame is
    // never the wrong theme flashing before the right one.
    final AppThemeMode mode =
        ref.watch(themeProvider).value ?? AppThemeMode.system;

    return MaterialApp.router(
      title: 'Unit of Payments',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode.flutterMode,
      routerConfig: AppRouter.router,
      // Without this, Material's own strings (date pickers, text selection
      // menus) render in English no matter what our copy says.
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

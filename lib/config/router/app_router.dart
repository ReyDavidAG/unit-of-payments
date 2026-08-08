import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/supabase/supabase_service.dart';
import '../../ui/screens/auth/sign_in_screen.dart';
import '../../ui/screens/auth/sign_up_screen.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/shell/app_shell_screen.dart';

/// Routes and the session guard. The redirect is the only place that decides
/// whether a screen is reachable.
///
/// Tab navigation uses a single `/shell` route (PageView inside) instead of
/// `StatefulShellRoute.indexedStack`. The four tab paths redirect there so
/// `context.goNamed(...)` for the old tab paths still works. The selected
/// tab lives in a Riverpod provider so the shell can read it on rebuild
/// without a new PageController being instantiated.
class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: DashboardScreen.routePath,
    refreshListenable: _AuthNotifier(),
    routes: [
      GoRoute(
        path: SignInScreen.routePath,
        name: SignInScreen.routeName,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: SignUpScreen.routePath,
        name: SignUpScreen.routeName,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/shell',
        name: 'shell',
        builder: (context, state) => const AppShellScreen(),
      ),
    ],
    redirect: (context, state) {
      final bool signedIn = SupabaseService.isSignedIn;
      final bool onAuthScreen =
          state.matchedLocation == SignInScreen.routePath ||
          state.matchedLocation == SignUpScreen.routePath;

      if (!signedIn && !onAuthScreen) {
        return SignInScreen.routePath;
      }
      if (signedIn && onAuthScreen) {
        return DashboardScreen.routePath;
      }
      return null;
    },
  );
}

/// Re-runs the redirect whenever the session changes, so signing out from any
/// screen bounces to sign-in without that screen knowing about routing.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    _subscription = SupabaseService.authChanges.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

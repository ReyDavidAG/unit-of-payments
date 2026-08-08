import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/supabase/supabase_service.dart';
import '../../ui/screens/auth/sign_in_screen.dart';
import '../../ui/screens/auth/sign_up_screen.dart';
import '../../ui/screens/cards/cards_screen.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/error/error_screen.dart';
import '../../ui/screens/notifications/notification_history_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/shell/app_shell_screen.dart';
import '../../ui/screens/subscriptions/subscriptions_screen.dart';

/// Routes and the session guard. The redirect is the only place that decides
/// whether a screen is reachable.
///
/// Tab navigation uses a single `/shell` route (PageView inside). The four
/// tab paths and names are kept as aliases that redirect to `/shell` so any
/// `context.goNamed(SubscriptionsScreen.routeName)` call still works without
/// re-instantiating the shell — the redirect resolves to the same page
/// the shell was already mounted on.
class AppRouter {
  const AppRouter._();

  static const String shellPath = '/shell';

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
      // Single shell route. The body is a PageView with the four tabs
      // as children. Tab index lives in shellIndexProvider; the PageView
      // keeps all children mounted.
      GoRoute(
        path: shellPath,
        name: 'shell',
        builder: (context, state) => const AppShellScreen(),
      ),
      // Aliases for the four tab paths: any goNamed to these names
      // (and any direct navigation to /subscriptions, /cards, /avisos)
      // lands on /shell without re-instantiating it.
      GoRoute(
        path: DashboardScreen.routePath,
        name: DashboardScreen.routeName,
        redirect: (context, state) => shellPath,
      ),
      GoRoute(
        path: SubscriptionsScreen.routePath,
        name: SubscriptionsScreen.routeName,
        redirect: (context, state) => shellPath,
      ),
      GoRoute(
        path: CardsScreen.routePath,
        name: CardsScreen.routeName,
        redirect: (context, state) => shellPath,
      ),
      GoRoute(
        path: NotificationHistoryScreen.routePath,
        name: NotificationHistoryScreen.routeName,
        redirect: (context, state) => shellPath,
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
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

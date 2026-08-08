import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/supabase/supabase_service.dart';
import '../../ui/screens/auth/sign_in_screen.dart';
import '../../ui/screens/auth/sign_up_screen.dart';
import '../../ui/screens/cards/cards_screen.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/notifications/notification_history_screen.dart';
import '../../ui/screens/shell/app_shell_screen.dart';
import '../../ui/screens/subscriptions/subscriptions_screen.dart';

/// Routes and the session guard. The redirect is the only place that decides
/// whether a screen is reachable.
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
      // One navigator per branch, so each tab keeps its own scroll position.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DashboardScreen.routePath,
                name: DashboardScreen.routeName,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SubscriptionsScreen.routePath,
                name: SubscriptionsScreen.routeName,
                builder: (context, state) => const SubscriptionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CardsScreen.routePath,
                name: CardsScreen.routeName,
                builder: (context, state) => const CardsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NotificationHistoryScreen.routePath,
                name: NotificationHistoryScreen.routeName,
                builder: (context, state) => const NotificationHistoryScreen(),
              ),
            ],
          ),
        ],
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

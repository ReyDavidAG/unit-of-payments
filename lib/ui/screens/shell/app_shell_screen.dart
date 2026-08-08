import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers/notifications/notifications_provider.dart';
import '../../../data/services/notifications/local_notification_service.dart';

/// Holds the bottom navigation. go_router keeps one navigator per branch, so
/// each tab remembers its own scroll position and open sheets.
class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Asked after sign-in rather than on first launch: a permission prompt
    // before the user has seen anything is a permission prompt that gets
    // denied.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => LocalNotificationService.requestPermission(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Rebuilt on resume too: a phone can sit closed for weeks, and the 30-day
  /// window it was last scheduled with will have moved past.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationSyncProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched here, where the shell is always mounted, so scheduling never
    // depends on the user opening the Avisos tab.
    ref.watch(notificationSyncProvider);

    return Scaffold(
      // GestureDetector on the body lets the user swipe horizontally between
      // tabs without losing the indexedStack benefit of go_router — each
      // branch stays mounted, scroll positions are preserved.
      body: _SwipeNavigation(
        shell: widget.navigationShell,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        // initialLocation returns to a tab's root when it is already selected.
        onDestinationSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Suscripciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Tarjetas',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Avisos',
          ),
        ],
      ),
    );
  }
}

/// Horizontal swipe between tabs. Threshold is velocity-based (not
/// distance-based) so a quick flick always commits and a slow drag is
/// ignored — the latter is reserved for horizontal scrollables inside
/// each tab. Direction maps to next/previous tab; edges clamp.
class _SwipeNavigation extends StatelessWidget {
  const _SwipeNavigation({required this.shell, required this.child});

  final StatefulNavigationShell shell;
  final Widget child;

  static const double _velocityThreshold = 350; // px/s
  static const int _lastBranch = 3; // four destinations: 0..3

  void _onSwipe(double velocity) {
    final int current = shell.currentIndex;
    if (velocity > _velocityThreshold) {
      shell.goBranch((current - 1).clamp(0, _lastBranch));
    } else if (velocity < -_velocityThreshold) {
      shell.goBranch((current + 1).clamp(0, _lastBranch));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) => _onSwipe(details.primaryVelocity ?? 0),
      child: child,
    );
  }
}

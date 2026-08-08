import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_motion.dart';
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
      body: _BranchSlider(shell: widget.navigationShell),
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

/// Shell body wrapped in two motions: a horizontal-drag velocity trigger
/// (flick left/right to switch tab) and an AnimatedSwitcher with a
/// direction-aware slide. The Stack layoutBuilder keeps the outgoing and
/// incoming tab on screen at the same time so the transition reads as
/// one screen gluing into the next — the closest we can get to a
/// PageView's drag-follows-finger without abandoning the StatefulShell
/// model (each branch keeps its own Navigator and scroll position).
class _BranchSlider extends StatefulWidget {
  const _BranchSlider({required this.shell});

  final StatefulNavigationShell shell;

  static const double _velocityThreshold = 350; // px/s
  static const int _lastBranch = 3; // four destinations: 0..3

  @override
  State<_BranchSlider> createState() => _BranchSliderState();
}

class _BranchSliderState extends State<_BranchSlider> {
  int _previousIndex = 0;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.shell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant _BranchSlider old) {
    super.didUpdateWidget(old);
    final int current = widget.shell.currentIndex;
    if (current != _previousIndex) {
      setState(() {
        _forward = current > _previousIndex;
        _previousIndex = current;
      });
    }
  }

  void _onSwipe(double velocity) {
    final int current = widget.shell.currentIndex;
    if (velocity > _BranchSlider._velocityThreshold) {
      widget.shell.goBranch((current - 1).clamp(0, _BranchSlider._lastBranch));
    } else if (velocity < -_BranchSlider._velocityThreshold) {
      widget.shell.goBranch((current + 1).clamp(0, _BranchSlider._lastBranch));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) => _onSwipe(details.primaryVelocity ?? 0),
      child: _SlideDirection(
        forward: _forward,
        child: AnimatedSwitcher(
          duration: AppMotion.long,
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeIn,
          // Stack keeps both the outgoing and incoming tab on screen so
          // the outgoing can finish sliding out while the incoming slides
          // in. Without this only one is visible and the transition reads
          // as a hard cross.
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[...previousChildren, ?currentChild],
          ),
          transitionBuilder: (child, animation) {
            final bool forward = _SlideDirection.of(context);
            final bool isExiting = animation.status == AnimationStatus.reverse;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: isExiting
                      ? Offset.zero
                      : Offset(forward ? 0.3 : -0.3, 0),
                  end: isExiting
                      ? Offset(forward ? -0.3 : 0.3, 0)
                      : Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(widget.shell.currentIndex),
            child: widget.shell,
          ),
        ),
      ),
    );
  }
}

/// Provides the current slide direction to the [AnimatedSwitcher]'s
/// transitionBuilder, which otherwise has no way to know whether the new
/// tab came from the left or the right of the previous one.
class _SlideDirection extends InheritedWidget {
  const _SlideDirection({required this.forward, required super.child});

  final bool forward;

  static bool of(BuildContext context) {
    final _SlideDirection? scope = context
        .dependOnInheritedWidgetOfExactType<_SlideDirection>();
    return scope?.forward ?? true;
  }

  @override
  bool updateShouldNotify(_SlideDirection old) => old.forward != forward;
}

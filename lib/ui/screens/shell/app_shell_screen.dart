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
/// (flick left/right to switch tab) and a Transform+Opacity slide driven
/// by the previous-vs-current index.
///
/// Why not AnimatedSwitcher with a keyed subtree: the StatefulNavigationShell
/// carries its own GlobalKey set by go_router. Wrapping it in a
/// KeyedSubtree with a changing key made Flutter move the shell between
/// parents within the same frame and trip the duplicate-GlobalKey
/// assertion. Keeping the shell as a single, identity-stable child and
/// animating it with Transform+Opacity sidesteps that and still reads
/// as a fluid slide between tabs.
class _BranchSlider extends StatefulWidget {
  const _BranchSlider({required this.shell});

  final StatefulNavigationShell shell;

  static const double _velocityThreshold = 350; // px/s
  static const int _lastBranch = 3; // four destinations: 0..3

  @override
  State<_BranchSlider> createState() => _BranchSliderState();
}

class _BranchSliderState extends State<_BranchSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _previousIndex;
  late bool _forward;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.shell.currentIndex;
    _forward = true;
    _controller = AnimationController(vsync: this, duration: AppMotion.long)
      ..addStatusListener((status) {
        // Snap to rest so the Transform doesn't keep the widget off-axis
        // when the animation completes.
        if (status == AnimationStatus.completed) {
          setState(() {}); // rebuild at t=1, where the builder returns child
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BranchSlider old) {
    super.didUpdateWidget(old);
    final int current = widget.shell.currentIndex;
    if (current != _previousIndex) {
      _forward = current > _previousIndex;
      _previousIndex = current;
      _controller.forward(from: 0);
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
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.shell,
        builder: (context, child) {
          final double t = _controller.value;
          // t == 1 → no transform, no opacity wrapper, identity layout.
          if (t == 1.0 || t == 0.0) return child!;
          final double beginOffset = _forward ? 0.3 : -0.3;
          final double currentOffset = beginOffset * (1 - t);
          return Transform.translate(
            offset: Offset(currentOffset, 0),
            child: Opacity(opacity: t, child: child),
          );
        },
      ),
    );
  }
}

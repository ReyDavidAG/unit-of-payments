import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_motion.dart';
import '../../../data/providers/notifications/notifications_provider.dart';
import '../../../data/providers/shell_index_provider.dart';
import '../../../data/services/notifications/local_notification_service.dart';
import '../../widgets/common/colored_nav_bar.dart';
import '../cards/cards_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../notifications/notification_history_screen.dart';
import '../subscriptions/subscriptions_screen.dart';

/// Authenticated home: the bottom navigation lives here and the body is a
/// PageView that holds the four tab screens. Drag follows the finger (the
/// PageView default), velocity flicks snap, and the bottom indicator
/// animates to the next icon automatically when the PageView settles.
///
/// The selected tab is owned by [shellIndexProvider]; the PageController
/// stays in sync by listening to it on build and animating when external
/// updates arrive (e.g., from the bottom nav).
class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(shellIndexProvider));
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => LocalNotificationService.requestPermission(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationSyncProvider);
    }
  }

  void _onTabTapped(int index) {
    if (index == ref.read(shellIndexProvider)) {
      return;
    }
    ref.read(shellIndexProvider.notifier).state = index;
    _pageController.animateToPage(
      index,
      duration: AppMotion.long,
      curve: AppMotion.easeOut,
    );
  }

  void _onPageChanged(int index) {
    if (index == ref.read(shellIndexProvider)) {
      return;
    }
    ref.read(shellIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationSyncProvider);
    final int currentIndex = ref.watch(shellIndexProvider);

    // PopScope on the shell: pressing the system back while inside the
    // authenticated shell asks before quitting the app. The dialog is
    // shown via the shell's own context so it lives above any open
    // sheet on a tab.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmExit(context);
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const ClampingScrollPhysics(),
          children: const [
            DashboardScreen(),
            SubscriptionsScreen(),
            CardsScreen(),
            NotificationHistoryScreen(),
          ],
        ),
        bottomNavigationBar: ColoredNavBar(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
          items: const [
            NavBarItem(
              icon: Icons.pie_chart_outline,
              selectedIcon: Icons.pie_chart,
              label: 'Resumen',
            ),
            NavBarItem(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              label: 'Suscripciones',
            ),
            NavBarItem(
              icon: Icons.credit_card_outlined,
              selectedIcon: Icons.credit_card,
              label: 'Tarjetas',
            ),
            NavBarItem(
              icon: Icons.notifications_none,
              selectedIcon: Icons.notifications,
              label: 'Avisos',
            ),
          ],
        ),
      ),
    );
  }

  /// Confirms the user wants to quit before letting the system pop the
  /// shell route and exit the app. /shell is at the top of the stack,
  /// so the only way out is [SystemNavigator.pop].
  Future<void> _confirmExit(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de Vence?'),
        content: const Text(
          'Estás a punto de cerrar la app. Tus datos quedan guardados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // SystemNavigator.pop is the only way to exit on Android without
      // a router pop. Guarded against re-entry with the dialog context.
      SystemNavigator.pop();
    }
  }
}

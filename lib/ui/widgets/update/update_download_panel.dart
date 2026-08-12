import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_motion.dart';
import '../../../config/theme/app_spacing.dart';

/// Small overlay that shows while a flexible update is downloading. Sits
/// right above the bottom nav bar so the user can keep browsing the app
/// while the APK pulls in the background. Removes itself the first time
/// [InstallStatus.downloaded] arrives; a 5-minute watchdog removes it if
/// the stream never reports success.
///
/// Informational only — no tap target, no close button.
class UpdateDownloadPanel {
  static bool _visible = false;

  static void show(BuildContext context) {
    if (_visible) return;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _visible = true;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _DownloadPanel(
        onDismissed: () {
          entry.remove();
          _visible = false;
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _DownloadPanel extends StatefulWidget {
  const _DownloadPanel({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  State<_DownloadPanel> createState() => _DownloadPanelState();
}

class _DownloadPanelState extends State<_DownloadPanel>
    with TickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: AppMotion.short,
  );
  // Indeterminate progress sweep. Repeats until the panel closes itself.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();
  // Watchdog in case the stream never emits. Without it a stale panel would
  // stay glued to the bottom of the screen forever.
  Timer? _watchdog;

  StreamSubscription<InstallStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    _slide.forward();
    _subscription = _installStream().listen((InstallStatus status) {
      if (status == InstallStatus.downloaded) {
        _dismiss();
      } else if (status == InstallStatus.failed ||
          status == InstallStatus.canceled) {
        _dismiss();
      }
    });
    _watchdog = Timer(const Duration(minutes: 5), _dismiss);
  }

  Stream<InstallStatus> _installStream() =>
      // The plugin is already wired through AppUpdateService. Routing the
      // stream through a function instead of importing the plugin here
      // keeps this widget focused on presentation.
      InAppUpdate.installUpdateListener;

  Future<void> _dismiss() async {
    if (!mounted) return;
    _watchdog?.cancel();
    await _subscription?.cancel();
    await _slide.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _subscription?.cancel();
    _slide.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    // ColoredNavBar height = AppSpacing.xl2 (64) + system bottom inset.
    final double navBarHeight = AppSpacing.xl2 + bottomInset;

    final CurvedAnimation curved = CurvedAnimation(
      parent: _slide,
      curve: AppMotion.easeOut,
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: navBarHeight,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            shape: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  _iconBadge(theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descargando actualización',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs3),
                        Text(
                          'Se instalará cuando termine',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _progressBar(theme.colorScheme.primary, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(Color accent) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.14),
      ),
      child: Icon(Icons.system_update, size: 20, color: accent),
    );
  }

  Widget _progressBar(Color accent, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs3),
      child: SizedBox(
        height: 4,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            const double segment = 0.42;
            return Stack(
              children: [
                Container(color: theme.colorScheme.surfaceContainerHigh),
                AnimatedBuilder(
                  animation: _sweep,
                  builder: (_, _) {
                    final double left =
                        (_sweep.value * (1 + segment) - segment) * w;
                    return Positioned(
                      left: left,
                      width: w * segment,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: accent),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

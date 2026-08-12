import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../../data/models/update/app_update_state.dart';
import '../../../data/providers/update/app_update_provider.dart';
import 'update_bottom_sheet.dart';
import 'update_download_panel.dart';

/// Wraps the entire app and drives the three-step in-app update flow.
/// Mounted once, via `MaterialApp.router(builder: ...)`, so the update check
/// runs on every cold start regardless of auth state. Does nothing on iOS.
///
/// Step 1 — bottom sheet with "Actualizar ahora" / "Después"
/// Step 2 — progress panel above the bottom nav
/// Step 3 — bottom sheet with "Instalar ahora" only, not dismissible
class AppUpdateWrapper extends ConsumerStatefulWidget {
  const AppUpdateWrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends ConsumerState<AppUpdateWrapper> {
  bool _sheetVisible = false;
  StreamSubscription<InstallStatus>? _installSub;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUpdateProvider.notifier).checkForUpdate();
    });
  }

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return widget.child;
    }

    ref.listen<AppUpdateState>(appUpdateProvider, (
      AppUpdateState? previous,
      AppUpdateState next,
    ) {
      _onStateChanged(previous, next);
    });

    return widget.child;
  }

  void _onStateChanged(AppUpdateState? previous, AppUpdateState next) {
    if (!mounted) return;

    if (next.status == UpdateStatus.downloading &&
        previous?.status != UpdateStatus.downloading) {
      UpdateDownloadPanel.show(context);
      _subscribeInstallStatus();
      return;
    }

    if (next.status == UpdateStatus.readyToInstall &&
        previous?.status != UpdateStatus.readyToInstall) {
      _showInstallSheet();
      return;
    }

    if (next.status == UpdateStatus.updateAvailable &&
        previous?.status != UpdateStatus.updateAvailable) {
      _showUpdateSheet();
      return;
    }
  }

  /// Bridges the install status stream into provider state. The panel listens
  /// to the same stream independently for its own dismissal; this subscription
  /// exists solely to flip the state machine so the wrapper can show the
  /// install sheet at the right moment.
  void _subscribeInstallStatus() {
    _installSub?.cancel();
    _installSub = InAppUpdate.installUpdateListener.listen((InstallStatus s) {
      if (s == InstallStatus.downloaded) {
        ref.read(appUpdateProvider.notifier).markReadyToInstall();
      } else if (s == InstallStatus.failed || s == InstallStatus.canceled) {
        // Bounce back to the update sheet so the user can retry.
        ref.read(appUpdateProvider.notifier).checkForUpdate();
      }
    });
  }

  void _showUpdateSheet() {
    if (_sheetVisible) return;
    final AppUpdateState state = ref.read(appUpdateProvider);
    final String? notes = state.releaseNotes;
    final String body = notes == null || notes.trim().isEmpty
        ? 'Una nueva versión está disponible con mejoras y correcciones.'
        : 'Qué hay de nuevo:\n$notes';

    _sheetVisible = true;
    UpdateBottomSheet.show(
      context,
      title: 'Hay una nueva versión de Vence',
      body: body,
      actionLabel: 'Actualizar ahora',
      isDismissible: !state.forceUpdate,
      onDismiss: state.forceUpdate
          ? null
          : () async {
              Navigator.of(context).pop();
              await ref
                  .read(appUpdateProvider.notifier)
                  .dismissForThisVersion();
            },
      onAction: () async {
        // Clear the guard synchronously: a fast download can fire
        // `downloaded` before sheet 1 finishes its dismiss animation, and
        // the `whenComplete` below would otherwise let the install sheet
        // be skipped because `_sheetVisible` is still true.
        _sheetVisible = false;
        Navigator.of(context).pop();
        await ref.read(appUpdateProvider.notifier).startUpdate();
      },
    ).whenComplete(() => _sheetVisible = false);
  }

  void _showInstallSheet() {
    if (_sheetVisible) return;
    _sheetVisible = true;
    UpdateBottomSheet.show(
      context,
      title: 'Listo para instalar',
      body:
          'La nueva versión ya está descargada. Instálala para seguir '
          'usando Vence.',
      actionLabel: 'Instalar ahora',
      isDismissible: false,
      onAction: () async {
        Navigator.of(context).pop();
        await ref.read(appUpdateProvider.notifier).completeUpdate();
      },
    ).whenComplete(() => _sheetVisible = false);
  }
}

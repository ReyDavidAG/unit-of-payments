import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/update/app_update_state.dart';
import '../../services/update/app_update_service.dart';

/// Drives the three-step in-app update flow. The wrapper subscribes to
/// status changes and shows the matching sheet or panel; the notifier
/// itself stays out of the widget tree.
final NotifierProvider<AppUpdateNotifier, AppUpdateState> appUpdateProvider =
    NotifierProvider<AppUpdateNotifier, AppUpdateState>(AppUpdateNotifier.new);

class AppUpdateNotifier extends Notifier<AppUpdateState> {
  static const String _dismissedKey = 'update.dismissedVersion';

  @override
  AppUpdateState build() => const AppUpdateState();

  /// Kicks off a single check. Called once from the wrapper on the first
  /// frame after the shell mounts. Idempotent in practice: a second call
  /// just re-reads state and re-emits.
  Future<void> checkForUpdate() async {
    final AppUpdateInfo? playInfo =
        await AppUpdateService.checkPlayStoreUpdate();
    if (playInfo == null) return;
    if (playInfo.updateAvailability != UpdateAvailability.updateAvailable) {
      return;
    }

    final RemoteUpdateConfig? config =
        await AppUpdateService.fetchRemoteConfig();
    final String? installed = await AppUpdateService.installedVersion();

    final bool force = config?.forceUpdate ?? false;
    final int? latestCode = playInfo.availableVersionCode;

    if (!force && latestCode != null && await _wasDismissedFor(latestCode)) {
      return;
    }

    // Emit regardless of which paths Play Core allows. The action handler
    // picks flexible vs immediate at tap time.
    state = state.copyWith(
      status: UpdateStatus.updateAvailable,
      releaseNotes: config?.releaseNotes,
      forceUpdate: force,
      flexibleAllowed: playInfo.flexibleUpdateAllowed,
      immediateAllowed: playInfo.immediateUpdateAllowed,
      latestVersion: latestCode?.toString(),
      installedVersion: installed,
    );
  }

  /// Starts the update flow when the user taps "Actualizar ahora". Picks
  /// flexible when available (background download, our three-step flow);
  /// falls back to immediate when Play Core only allows that path.
  Future<void> startUpdate() async {
    if (state.flexibleAllowed) {
      state = state.copyWith(status: UpdateStatus.downloading);
      try {
        await AppUpdateService.startFlexibleUpdate();
        // Optimistic transition: some OEM skins swallow the `downloaded`
        // event, in which case the install status stream never fires. If
        // it does fire later, `markReadyToInstall` is idempotent.
        state = state.copyWith(status: UpdateStatus.readyToInstall);
      } on Object catch (_) {
        // Bounce back so the user can retry instead of being stuck in
        // `downloading`.
        state = state.copyWith(
          status: UpdateStatus.updateAvailable,
          releaseNotes: 'No se pudo iniciar la descarga. Inténtalo de nuevo.',
        );
        rethrow;
      }
    } else if (state.immediateAllowed) {
      try {
        await AppUpdateService.performImmediateUpdate();
      } on Object catch (_) {
        // The OS will have already restarted or shown an error; nothing
        // useful to do client-side.
      }
    }
  }

  /// Called by the wrapper when `installStatusStream` reports `downloaded`.
  /// Idempotent with the optimistic transition in [startUpdate].
  Future<void> markReadyToInstall() async {
    if (state.status != UpdateStatus.downloading) return;
    state = state.copyWith(status: UpdateStatus.readyToInstall);
  }

  /// Triggers the OS install dialog. The app is restarted by the OS, so
  /// there is no state to update after this resolves.
  Future<void> completeUpdate() async {
    await AppUpdateService.completeFlexibleUpdate();
  }

  /// Called by the wrapper when the user taps "Después". Persisted so the
  /// sheet does not reappear on every frame; cleared once the user installs
  /// a newer version (the next check will be against a higher version code).
  Future<void> dismissForThisVersion() async {
    final String? latest = state.latestVersion;
    if (latest == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, latest);
  }

  Future<bool> _wasDismissedFor(int latestVersionCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedKey) == latestVersionCode.toString();
  }
}

/// Hooks the install status stream from `in_app_update` into the notifier.
/// Returns the same stream so the wrapper can show the panel while the
/// download is in progress; both consumers see the same events.
Stream<InstallStatus> installStatusStream() =>
    AppUpdateService.installStatusStream();

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
    if (!playInfo.flexibleUpdateAllowed) {
      // Without a flexible path the wrapper has nothing to drive. The Edge
      // Function can force the issue, but we never start an immediate update
      // out of our own UI — that would hand the screen to Play's dialog and
      // kill our three-step flow.
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

    state = state.copyWith(
      status: UpdateStatus.updateAvailable,
      releaseNotes: config?.releaseNotes,
      forceUpdate: force,
      latestVersion: latestCode?.toString(),
      installedVersion: installed,
    );
  }

  /// Called by the wrapper when the user taps "Actualizar ahora". The actual
  /// download runs in the background; the wrapper listens to the install
  /// status stream and removes its panel when the APK is on disk.
  Future<void> startFlexibleUpdate() async {
    state = state.copyWith(status: UpdateStatus.downloading);
    await AppUpdateService.startFlexibleUpdate();
  }

  /// Called by the wrapper when `installStatusStream` reports `downloaded`.
  Future<void> markReadyToInstall() async {
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

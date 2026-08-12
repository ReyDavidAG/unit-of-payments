/// Update lifecycle states. The provider moves through these; the wrapper
/// listens and surfaces the matching UI.
enum UpdateStatus { idle, updateAvailable, downloading, readyToInstall, error }

/// Snapshot of the in-app update flow at a point in time. Built from two
/// independent signals — Play Store (via `in_app_update`) and the Edge
/// Function config — combined here so the UI has a single thing to render.
class AppUpdateState {
  const AppUpdateState({
    this.status = UpdateStatus.idle,
    this.releaseNotes,
    this.forceUpdate = false,
    this.latestVersion,
    this.installedVersion,
  });

  final UpdateStatus status;
  final String? releaseNotes;
  final bool forceUpdate;
  final String? latestVersion;
  final String? installedVersion;

  AppUpdateState copyWith({
    UpdateStatus? status,
    String? releaseNotes,
    bool? forceUpdate,
    String? latestVersion,
    String? installedVersion,
  }) => AppUpdateState(
    status: status ?? this.status,
    releaseNotes: releaseNotes ?? this.releaseNotes,
    forceUpdate: forceUpdate ?? this.forceUpdate,
    latestVersion: latestVersion ?? this.latestVersion,
    installedVersion: installedVersion ?? this.installedVersion,
  );
}

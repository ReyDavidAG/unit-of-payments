/// The version of the running build, sourced from `package_info_plus` which
/// reads the version embedded by the Flutter toolchain at build time
/// (Android `versionName` / `versionCode`, iOS `CFBundleShortVersionString`
/// / `CFBundleVersion`). Always derived from `version:` in `pubspec.yaml`,
/// never typed by hand.
class AppVersion {
  const AppVersion({required this.name, required this.build});

  final String name;
  final int build;

  String get label => 'v$name build $build';
}

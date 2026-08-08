/// The shipped version, shown on the sign-in screen and in Perfil so a tester
/// can name what they are looking at.
///
/// Copied from `version:` in pubspec.yaml rather than read from it: Dart has no
/// way to read the manifest at runtime, and the package that does exists only
/// to answer this one question. `app_version_test.dart` reads pubspec.yaml and
/// fails when the two drift, which is the part that actually needed solving.
class AppVersion {
  const AppVersion._();

  static const String name = '1.0.0';
  static const int build = 1;

  static const String label = 'v$name build $build';
}

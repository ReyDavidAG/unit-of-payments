/// Compile-time configuration, supplied by `--dart-define-from-file=.env`.
///
/// Baked into the binary rather than bundled as a readable asset, which is what
/// a runtime .env loader would do. No dependency either: this is SDK-native.
class Environment {
  const Environment._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Feature flag for the in-app update Edge Function. When empty, the update
  /// flow is disabled (no sheet, no panel). The function itself is named
  /// `app-version-android`; the URL is included here only so internal builds
  /// can opt out without rebuilding the Dart code.
  static const String appVersionFunctionUrl = String.fromEnvironment(
    'APP_VERSION_FUNCTION_URL',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Fails at startup with something readable, instead of an empty-string URL
  /// surfacing as a confusing error on the first request.
  static void assertConfigured() {
    if (isConfigured) {
      return;
    }
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
      'Copy .env.example to .env, then run with --dart-define-from-file=.env',
    );
  }
}

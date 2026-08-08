/// Compile-time configuration, supplied by `--dart-define-from-file=.env`.
///
/// Baked into the binary rather than bundled as a readable asset, which is what
/// a runtime .env loader would do. No dependency either: this is SDK-native.
class Environment {
  const Environment._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Fails at startup with something readable, instead of an empty-string URL
  /// surfacing as a confusing error on the first request.
  static void assertConfigured() {
    if (isConfigured) {
      return;
    }
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
      'Copy .env.example to .env, then run with --dart-define-from-file=.env',
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/environment.dart';

/// Thin wrapper over the Supabase client. No repository layer on top: the
/// client already is the data client.
class SupabaseService {
  const SupabaseService._();

  static Future<void> initialize() async {
    Environment.assertConfigured();
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      publishableKey: Environment.supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static Session? get session => auth.currentSession;

  static bool get isSignedIn => session != null;

  /// Emits on sign-in, sign-out and token refresh. The router listens to this.
  static Stream<AuthState> get authChanges => auth.onAuthStateChange;

  static Future<void> signIn({
    required String email,
    required String password,
  }) => auth.signInWithPassword(email: email, password: password);

  /// Returns without a session when email confirmation is on, which is the
  /// Supabase default. The caller has to tell the user to check their inbox.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => auth.signUp(email: email, password: password);

  static Future<void> signOut() => auth.signOut();

  /// Supabase returns machine-readable codes; the UI needs a sentence.
  /// Anything unmapped falls through to the server message rather than a
  /// generic string that hides what actually happened.
  static String describeError(Object error) {
    if (error is AuthException) {
      return switch (error.code) {
        'invalid_credentials' => 'Wrong email or password.',
        'email_not_confirmed' => 'Confirm your email before signing in.',
        'user_already_exists' ||
        'email_exists' => 'That email already has an account.',
        'weak_password' => 'Password is too weak. Use at least 6 characters.',
        'over_email_send_rate_limit' => 'Too many attempts. Try again shortly.',
        _ => error.message,
      };
    }
    return 'Something went wrong. Check your connection and try again.';
  }
}

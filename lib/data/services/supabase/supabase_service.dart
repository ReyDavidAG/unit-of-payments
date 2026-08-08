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

  static Future<UserResponse> updatePassword(String password) =>
      auth.updateUser(UserAttributes(password: password));

  /// Sends the reset link. Always resolves, even for an address with no
  /// account: telling the caller which emails are registered would turn this
  /// into an account-enumeration endpoint.
  static Future<void> sendPasswordReset(String email) =>
      auth.resetPasswordForEmail(email);

  /// Supabase returns machine-readable codes; the UI needs a sentence.
  /// Anything unmapped falls through to the server message rather than a
  /// generic string that hides what actually happened.
  static String describeError(Object error) {
    if (error is AuthException) {
      return switch (error.code) {
        'invalid_credentials' => 'Correo o contraseña incorrectos.',
        'email_not_confirmed' => 'Confirma tu correo antes de iniciar sesión.',
        'user_already_exists' ||
        'email_exists' => 'Ese correo ya tiene una cuenta.',
        'same_password' => 'Esa ya es tu contraseña actual.',
        'weak_password' =>
          'La contraseña es muy débil. Usa al menos 6 caracteres.',
        'over_email_send_rate_limit' =>
          'Demasiados intentos. Espera un momento.',
        _ => error.message,
      };
    }
    return 'Algo salió mal. Revisa tu conexión e inténtalo de nuevo.';
  }
}

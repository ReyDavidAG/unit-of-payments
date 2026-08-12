import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/data/services/supabase/supabase_service.dart';
import 'package:unit_of_payments/ui/widgets/auth/auth_form_widget.dart';

Widget _host(
  Future<void> Function(String, String) onSubmit, {
  AuthMode mode = AuthMode.signIn,
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: AuthFormWidget(mode: mode, onSubmit: onSubmit),
  ),
);

void main() {
  testWidgets('empty inputs are blocked before reaching the network', (
    tester,
  ) async {
    bool submitted = false;
    await tester.pumpWidget(_host((_, _) async => submitted = true));

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Escribe tu correo.'), findsOneWidget);
    // Sign-in must not tell the user the password is too short — that
    // leaks the format. Only the empty field is flagged.
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(find.textContaining('Mínimo'), findsNothing);
    expect(submitted, isFalse);
  });

  testWidgets('sign-up rejects passwords shorter than 8 characters', (
    tester,
  ) async {
    await tester.pumpWidget(_host((_, _) async {}, mode: AuthMode.signUp));

    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();

    expect(find.text('Mínimo 8 caracteres.'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows the mapped message', (tester) async {
    await tester.pumpWidget(
      _host(
        (_, _) async =>
            throw const AuthException('bad', code: 'invalid_credentials'),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    // The raw 'bad' from the server must not be what the user reads.
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  test('unknown failures do not leak a raw exception at the user', () {
    expect(
      SupabaseService.describeError(Exception('socket blew up')),
      'Algo salió mal. Revisa tu conexión e inténtalo de nuevo.',
    );
    // A mapped code wins over the server text.
    expect(
      SupabaseService.describeError(
        const AuthException('x', code: 'weak_password'),
      ),
      'La contraseña es muy débil. Usa al menos 6 caracteres.',
    );
  });
}
